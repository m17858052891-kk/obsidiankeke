#!/usr/bin/env python3
"""Machine-bound Wiki client. Python 3.9+, Git; no current-directory assumptions."""
import argparse
from datetime import datetime, timedelta, timezone
import io
import json
import os
from pathlib import Path
import shutil
import sys
import tarfile
import tempfile
from sync_common import REMOTE, atomic_json, digest, exclusive_lock, git, load_json, run, verify_repository, validate_body
import git_sources

CONFIG=Path(os.environ.get('WIKI_CONFIG',str(Path.home()/'.config/trading-efficiency-wiki/config.json'))).expanduser()

def get_config():
    c=load_json(CONFIG,None)
    if c is None:raise RuntimeError('Run init first. Default clone: ~/.local/share/trading-efficiency-wiki/repo')
    verify_repository(c['repo']);return c

def mirror(c, adopt=False):
    if not c.get('mirror'):return
    root=Path(c['repo']);target=Path(c['mirror']).expanduser().resolve()
    if target==root or root in target.parents or target in root.parents:raise RuntimeError('Mirror and checkout must be separate')
    target_existed=target.is_dir();target.mkdir(parents=True,exist_ok=True)
    manifest_path=CONFIG.parent/'mirror-state.json';previous=load_json(manifest_path,{})
    if previous.get('target') and previous['target']!=str(target):raise RuntimeError('Mirror target changed; initialize a separate config')
    old=previous.get('files',{});new={};writes=[];backups=[]
    if adopt and previous:raise RuntimeError('adopt-existing is only for initial mirror binding')
    # Read only the last fetched published commit. No uncommitted maintainer files leak into the mirror.
    commit=git(root,'rev-parse','origin/master')
    if previous.get('commit')==commit and target_existed:return
    with tarfile.open(fileobj=io.BytesIO(run(['git','-C',root,'archive','--format=tar',commit],timeout=300))) as archive:
        for member in archive:
            if not member.isfile():continue
            rel=Path(member.name)
            if rel.is_absolute() or '..' in rel.parts:raise RuntimeError('Unsafe archive path')
            dest=target/rel
            if dest.is_symlink() or target not in dest.resolve().parents:raise RuntimeError('Unsafe mirror path')
            data=archive.extractfile(member).read();h=digest(data);new[str(rel)]=h
            if dest.exists():
                current=digest(dest.read_bytes())
                if current==h:continue
                if old.get(str(rel))!=current:
                    if not adopt:raise RuntimeError('Local mirror changed: '+str(dest))
                    backups.append((str(rel),dest.read_bytes()))
            writes.append((dest,data))
    deletes=[]
    for rel,h in old.items():
        dest=target/rel
        if rel not in new and dest.exists():
            if dest.is_symlink() or target not in dest.resolve().parents or digest(dest.read_bytes())!=h:raise RuntimeError('Local mirror changed: '+str(dest))
            deletes.append(dest)
    if backups:
        backup=CONFIG.parent/('mirror-backup-'+datetime.now().strftime('%Y%m%dT%H%M%S'))
        for rel,data in backups:
            path=backup/rel;path.parent.mkdir(parents=True,exist_ok=True)
            with path.open('xb') as output:output.write(data)
        atomic_json(backup/'backup-manifest.json',{'target':str(target),'files':[r for r,_ in backups]})
        print(json.dumps({'mirror_backup':str(backup),'files':len(backups)},ensure_ascii=False))
    for dest,data in writes:
        dest.parent.mkdir(parents=True,exist_ok=True)
        handle,temp=tempfile.mkstemp(prefix='.wiki-',dir=str(dest.parent))
        try:
            with os.fdopen(handle,'wb') as out:out.write(data);out.flush();os.fsync(out.fileno())
            os.replace(temp,dest)
        finally:
            if os.path.exists(temp):os.unlink(temp)
    for dest in deletes:dest.unlink()
    atomic_json(manifest_path,{'target':str(target),'commit':commit,'files':new})

def init(args):
    root=Path(args.repo).expanduser().resolve()
    if not root.exists():
        root.parent.mkdir(parents=True,exist_ok=True);run(['git','clone','--branch','master',REMOTE,str(root)],timeout=300)
    verify_repository(root)
    if git(root,'branch','--show-current')!='master':raise RuntimeError('Expected master checkout')
    c={'schema_version':1,'repo':str(root),'mirror':str(Path(args.mirror).expanduser().resolve()) if args.mirror else None,'branch':'master','remote':REMOTE}
    old=load_json(CONFIG,{})
    if old and (old.get('repo')!=c['repo'] or old.get('mirror')!=c['mirror']):raise RuntimeError('An existing config binds a different path; use WIKI_CONFIG for a separate installation')
    mirror(c,adopt=args.adopt_existing);atomic_json(CONFIG,{**old,**c})
    print(json.dumps({'config':str(CONFIG),'repo':str(root),'query_path':c.get('mirror') or str(root)},ensure_ascii=False))

def refresh(force=False):
    c=get_config();root=Path(c['repo']);today=datetime.now(timezone(timedelta(hours=8))).date().isoformat()
    lock=Path(git(root,'rev-parse','--absolute-git-dir'))/'wiki-sync/maintenance.lock'
    with exclusive_lock(lock):
        if not force and c.get('last_check_attempt_day',c.get('last_successful_check_day'))==today:
            mirror(c);return c
        if git(root,'status','--porcelain'):raise RuntimeError('Checkout has local changes; automatic refresh stopped')
        if git(root,'branch','--show-current')!='master':raise RuntimeError('Checkout is not on master')
        c['last_check_attempt_day']=today
        try:
            git(root,'fetch','origin','master')
            # Reject unpublished local commits, even when ff-only would say "already up to date".
            run(['git','-C',root,'merge-base','--is-ancestor','HEAD','origin/master'])
            git(root,'merge','--ff-only','origin/master')
            mirror(c)
        except Exception as e:
            c['last_sync_error']=str(e);atomic_json(CONFIG,c);raise
        c.update(last_successful_check_day=today,last_published_commit=git(root,'rev-parse','origin/master'))
        c.pop('last_sync_error',None)
        atomic_json(CONFIG,c);return c

def query(args):
    warning=None
    try:c=refresh()
    except Exception as e:c=get_config();warning='Remote sync failed; using cached local data: '+str(e)
    warning=warning or c.get('last_sync_error')
    base=Path(c.get('mirror') or c['repo']);state=load_json(base/'_build/incremental.json',{})
    result={'query_path':str(base),'last_remote_check':c.get('last_successful_check_day'),'source_scan':state.get('last_archive_run'),'warning':warning,'matches':[]}
    terms=[t.casefold() for t in args.terms]
    # Titles and Wiki take priority; raw remains available for new, unsynthesized evidence.
    candidates=list((base/'wiki').rglob('*.md'))
    latest=set()
    for key,r in state.get('records',{}).items():
        if not r.get('file'):continue
        if state.get('failures',{}).get(key,{}).get('error')=='ValueError: export_error':
            try:validate_body((base/r['file']).read_text())
            except (ValueError,OSError):continue
        latest.add(r['file'])
    metadata={r['file']:' '.join([r.get('title',''),*[o.get('title','') for o in r.get('occurrences',[])]]) for r in state.get('records',{}).values() if r.get('file')}
    candidates += [base/f for f in sorted(latest)]
    candidates += [p for p in (base/'raw/git').rglob('*.md') if 'bwh_stg' not in p.relative_to(base/'raw/git').parts]
    if not latest and not state.get('records') and not state.get('git'):
        candidates+=list((base/'raw').rglob('*.md'))
    candidates.sort(key=lambda p:(not any(t in (p.name+' '+metadata.get(str(p.relative_to(base)), '')).casefold() for t in terms), 'raw' in p.relative_to(base).parts))
    seen=set()
    for path in candidates:
        if path in seen or not path.is_file():continue
        seen.add(path)
        text=path.read_text(encoding='utf8',errors='replace')
        title=metadata.get(str(path.relative_to(base)),'')
        if all(t in (path.name+'\n'+title+'\n'+text).casefold() for t in terms):
            lines=[{'line':n,'text':line[:300]} for n,line in enumerate(text.splitlines(),1) if any(t in line.casefold() for t in terms)][:6]
            result['matches'].append({'file':str(path),'title':title or path.stem,'snippets':lines})
            if len(result['matches'])>=args.limit:break
    print(json.dumps(result,ensure_ascii=False,indent=2))

def code(args):
    warning=None
    try:c=refresh()
    except Exception as e:c=get_config();warning='Wiki sync failed; using cached summary checkpoint: '+str(e)
    base=Path(c.get('mirror') or c['repo'])
    state=load_json(base/'_build/incremental.json',{})
    record=state.get('git',{}).get(args.repo,{})
    reviewed=record.get('reviewed_commit') or record.get('synthesized_commit')
    if not reviewed and record.get('wiki_status')!='pending':reviewed=record.get('commit')
    commit=args.commit or (git_sources.remote_head(args.repo) if args.latest else reviewed)
    if not commit:raise RuntimeError('No reviewed source commit; specify --commit or --latest explicitly')
    result=git_sources.read_code(args.repo,commit,file=args.file,search=args.search,diff_from=args.diff_from,
                                 limit=args.limit,max_chars=args.max_chars)
    result.update(basis='requested_commit' if args.commit else 'latest_source' if args.latest else 'wiki_summary',
                  summary_commit=reviewed,warning=warning,source_scan=state.get('last_archive_run'))
    print(json.dumps(result,ensure_ascii=False,indent=2))

def main():
    p=argparse.ArgumentParser(description=__doc__);sub=p.add_subparsers(dest='command',required=True)
    s=sub.add_parser('init');s.add_argument('--repo',default=str(Path.home()/'.local/share/trading-efficiency-wiki/repo'));s.add_argument('--mirror');s.add_argument('--adopt-existing',action='store_true',help='First binding only: back up conflicting mirror files before adoption')
    sub.add_parser('refresh');sub.add_parser('status')
    s=sub.add_parser('query');s.add_argument('terms',nargs='+');s.add_argument('--limit',type=int,default=12)
    s=sub.add_parser('code');s.add_argument('repo',choices=git_sources.REPOS)
    mode=s.add_mutually_exclusive_group(required=True);mode.add_argument('--file');mode.add_argument('--search');mode.add_argument('--diff-from')
    version=s.add_mutually_exclusive_group();version.add_argument('--commit');version.add_argument('--latest',action='store_true')
    s.add_argument('--limit',type=int,default=12);s.add_argument('--max-chars',type=int,default=20000)
    s=sub.add_parser('maintain');s.add_argument('args',nargs=argparse.REMAINDER)
    a=p.parse_args()
    if a.command=='init':init(a)
    elif a.command=='query':query(a)
    elif a.command=='code':
        if not 1<=a.limit<=200 or not 1<=a.max_chars<=200000:p.error('Invalid code output limit')
        code(a)
    elif a.command=='refresh':print(json.dumps(refresh(True),ensure_ascii=False))
    elif a.command=='status':
        c=get_config();state=load_json(Path(c['repo'])/'_build/incremental.json',{})
        print(json.dumps({'config':c,'source_scan':state.get('last_archive_run'),'failures':len(state.get('failures',{})),
                          'pending_synthesis':sum(r.get('wiki_status')=='pending' for group in ['records','git'] for r in state.get(group,{}).values())},ensure_ascii=False,indent=2))
    else:
        c=get_config();root=Path(c['repo']);script=root/'_build/wiki_sync.py'
        if not script.is_file():raise RuntimeError('Repository has no weekly maintenance scripts; refresh first')
        if not (root/'_build/git_sources.py').is_file():
            raise RuntimeError('Repository maintenance scripts need the source-cache update; refresh a published compatible revision first')
        import subprocess
        sys.exit(subprocess.call([sys.executable,str(script),*a.args],cwd=str(root)))

if __name__=='__main__':
    try:main()
    except Exception as e:print(json.dumps({'error':str(e)},ensure_ascii=False),file=sys.stderr);sys.exit(1)
