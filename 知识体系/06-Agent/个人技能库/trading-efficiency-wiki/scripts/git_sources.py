"""Read pinned source commits from an independent, reusable local Git cache."""
import os
from pathlib import Path
import re
import shutil
import tempfile
from urllib.parse import quote
from sync_common import exclusive_lock, load_json, remote_identity, run

REPOS = ['trade-of-passenger', 'platform_pk', 'trade-model', 'pk_strategy_wiki', 'cp_trade_strategy_wiki']
MODE = 'external-cache-v1'


def source_remote(name):
    if name not in REPOS:
        raise ValueError('Unknown source repository')
    return 'git@git.xiaojukeji.com:bwh_stg/' + name + '.git'


def object_id(value):
    if not re.fullmatch(r'[0-9a-f]{40}|[0-9a-f]{64}', value or ''):
        raise ValueError('Expected a full source commit SHA')
    return value


def source_url(name, commit, path=None):
    base = 'https://code.xiaojukeji.com/bwh_stg/' + name + '/-/'
    return base + ('blob/' + commit + '/' + quote(path, safe='/') if path else 'commit/' + commit)


def cache_root():
    config = load_json(Path(os.environ.get('WIKI_CONFIG', str(Path.home() / '.config/trading-efficiency-wiki/config.json'))), {})
    value = os.environ.get('WIKI_SOURCE_CACHE') or config.get('source_cache') or str(Path.home() / '.cache/trading-efficiency-wiki/sources')
    root = Path(value).expanduser().resolve()
    for location in [config.get('repo'), config.get('mirror')]:
        if location:
            location = Path(location).expanduser().resolve()
            if root == location or location in root.parents:
                raise ValueError('Source cache must be outside the Wiki checkout and query mirror')
    return root


def remote_head(name):
    # Checking a source version does not require cloning its contents.
    rows = run(['git', 'ls-remote', source_remote(name), 'HEAD']).decode().splitlines()
    if len(rows) != 1 or rows[0].split()[-1] != 'HEAD':
        raise RuntimeError('Source HEAD is unavailable: ' + name)
    return object_id(rows[0].split()[0])


def ensure_cache(name, commit):
    remote = source_remote(name)
    object_id(commit)
    root = cache_root()
    root.mkdir(parents=True, exist_ok=True)
    target = root / (name + '.git')
    with exclusive_lock(root / (name + '.lock')):
        if target.is_symlink():
            raise ValueError('Source cache cannot be a symlink')
        if not target.exists():
            temporary = Path(tempfile.mkdtemp(prefix=name + '-', dir=str(root)))
            try:
                run(['git', 'clone', '--bare', remote, temporary], timeout=300)
                os.replace(temporary, target)
            finally:
                if temporary.exists():
                    shutil.rmtree(temporary)
        def g(*args):
            return run(['git', '--git-dir', target, *args]).decode().strip()
        if g('rev-parse', '--is-bare-repository') != 'true' or Path(g('rev-parse', '--absolute-git-dir')).resolve() != target.resolve():
            raise ValueError('Unexpected source cache repository')
        if remote_identity(g('remote', 'get-url', 'origin')) != remote_identity(remote):
            raise ValueError('Unexpected source cache remote')
        try:
            g('cat-file', '-e', commit + '^{commit}')
        except RuntimeError:
            run(['git', '--git-dir', target, 'fetch', 'origin', '+refs/heads/*:refs/heads/*'], timeout=300)
            g('cat-file', '-e', commit + '^{commit}')
    return target


def changed_files(repo, before, after, name):
    object_id(after)
    if before:
        object_id(before)
        raw = run(['git', '--git-dir', repo, 'diff', '--name-status', '--no-renames', '-z', before, after]).decode().split('\0')
        pairs = zip(raw[0::2], raw[1::2])
    else:
        paths = run(['git', '--git-dir', repo, 'ls-tree', '-r', '--name-only', '-z', after]).decode().split('\0')
        pairs = [('A', path) for path in paths if path]
    return [{'status': status, 'path': path, 'source_url': source_url(name, before if status == 'D' else after, path)}
            for status, path in pairs if status and path]


def summary_pages(root, name, commit):
    if not commit:
        return []
    return sorted(str(p.relative_to(root)) for p in (Path(root) / 'wiki').rglob('*.md')
                  if 'bwh_stg/' + name in p.read_text() and commit in p.read_text())


def read_code(name, commit, *, file=None, search=None, diff_from=None, limit=12, max_chars=20000):
    repo = ensure_cache(name, commit)
    result = {'repository': 'bwh_stg/' + name, 'commit': commit, 'cache': str(repo),
              'source_url': source_url(name, commit)}
    if file is not None:
        path = Path(file)
        if path.is_absolute() or '..' in path.parts or not file:
            raise ValueError('Expected a source-relative file path')
        data = run(['git', '--git-dir', repo, 'show', commit + ':' + file])
        if b'\0' in data:
            raise ValueError('Binary source; inspect the original file with an appropriate reader')
        text = data.decode('utf8')
        result.update(file=file, source_url=source_url(name, commit, file), content=text[:max_chars], truncated=len(text) > max_chars)
    elif diff_from is not None:
        object_id(diff_from)
        ensure_cache(name, diff_from)
        text = run(['git', '--git-dir', repo, 'diff', '--no-ext-diff', '--no-textconv', diff_from, commit]).decode('utf8', 'replace')
        result.update(diff_from=diff_from, content=text[:max_chars], truncated=len(text) > max_chars)
    elif search is not None:
        if not search:
            raise ValueError('Search text cannot be empty')
        try:
            text = run(['git', '--git-dir', repo, 'grep', '-n', '-I', '-i', '-F', '-e', search, commit, '--']).decode('utf8')
        except RuntimeError as e:
            if str(e) != 'command_failed':
                raise
            text = ''
        matches = []
        for row in text.splitlines():
            path, line, content = row[len(commit) + 1:].split(':', 2)
            matches.append({'file': path, 'line': int(line), 'text': content[:500], 'source_url': source_url(name, commit, path)})
        result.update(matches=matches[:limit], truncated=len(matches) > limit)
    else:
        raise ValueError('Choose a file, search text, or comparison commit')
    return result
