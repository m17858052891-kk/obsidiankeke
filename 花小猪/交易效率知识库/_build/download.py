#!/usr/bin/env python3
"""Checkpointed text-only Cooper fetch. Source text is never executed."""
import argparse
import concurrent.futures
import collections
import datetime
import fcntl
import hashlib
import json
import os
from pathlib import Path
import re
import subprocess

BUILD = Path(__file__).resolve().parent
BASE = BUILD.parent
WRAPPER = '/Users/didi/.SmartWork/skills/smartwork-cli/smartwork-shared/assets/dws-unix.sh'
BODY_TYPES = {'DK_PAGE', 'SHIMO2_WORD', 'SHIMO_WORD', 'COOPER_DOC', 'NEWDOC', 'DOC'}
DEPARTMENT_ROOTS = {'proposals', 'lr26', 'lr25'}
EXCLUDE = re.compile(r'绩效|薪酬|晋升|招聘|面试|人力盘点|人员盘点|人事|团建|述职|个人总结')

def now():
    return datetime.datetime.now(datetime.timezone.utc).isoformat()

def atomic_json(path, value):
    tmp = path.with_suffix(path.suffix + '.tmp')
    tmp.write_text(json.dumps(value, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')
    os.replace(tmp, path)

def sha(data):
    return hashlib.sha256(data).hexdigest()

def fetch(record, timeout):
    result = {'attempted_at': now(), 'attempts': record.get('attempts', 0) + 1}
    try:
        process = subprocess.run(['bash', WRAPPER, '--output', 'json', 'doc', 'fetch', record['id'], '--app', record['app']],
                                 capture_output=True, timeout=timeout)
        if process.returncode:
            error_text = process.stderr.decode('utf-8', errors='replace')
            if '内容安全管控' in error_text or 'PendingApprove' in error_text:
                feedback = re.search(r'反馈\s*ID[：:]\s*(\d+)', error_text)
                result.update(status='failed', error='security_approval_required', exit_code=process.returncode,
                              no_auto_retry=True, detail='Content security control denied read; approval required. Sensitive matching examples omitted.',
                              feedback_id=feedback.group(1) if feedback else None)
                return result
            result.update(status='failed', error='nonzero_exit', exit_code=process.returncode,
                          detail=error_text[:1200])
            return result
        value = json.loads(process.stdout.decode('utf-8'))
        if value.get('ok') is not True:
            result.update(status='failed', error='ok_false', detail=value.get('error'))
            return result
        body = value.get('data')
        if not isinstance(body, str):
            result.update(status='failed', error='unexpected_body_type', detail=type(body).__name__)
            return result
        if not re.sub(r'<!--.*?-->', '', body, flags=re.S).strip():
            result.update(status='failed', error='empty_body')
            return result
        data = body.encode('utf-8')
        path = BASE / record['file']
        path.parent.mkdir(parents=True, exist_ok=True)
        # Exclusive creation preserves raw snapshots even after interrupted ledger writes.
        if path.exists():
            if path.read_bytes() != data:
                result.update(status='failed', error='existing_snapshot_differs', detail='Raw file preserved; manual version reconciliation required')
                return result
        else:
            with path.open('xb') as output:
                output.write(data)
        result.update(status='success', sha256=sha(data), bytes=len(data), fetched_at=now(), error=None,
                      images_unparsed=len(re.findall(r'!\[[^\]]*\]\([^)]*\)|<img\b', body, re.I)),
                      image_policy='text_only_unparsed', attachments_parsed=False)
        return result
    except subprocess.TimeoutExpired:
        return dict(result, status='failed', error='timeout')
    except (ValueError, OSError) as error:
        return dict(result, status='failed', error=type(error).__name__, detail=str(error)[:1200])

def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--roots', nargs='+', default=['platform', 'efficiency', 'planning'])
    parser.add_argument('--limit', type=int, default=100)
    parser.add_argument('--workers', type=int, default=3)
    parser.add_argument('--timeout', type=int, default=90)
    parser.add_argument('--retry-failed', action='store_true', help='Include prior fetch failures; defaults to fetching new pending items only')
    parser.add_argument('--register-only', action='store_true', help='Register the current manifest snapshot without fetching bodies')
    args = parser.parse_args()
    if not 1 <= args.limit <= 100 or not 1 <= args.workers <= 3:
        parser.error('limit must be 1..100 and workers 1..3')
    with (BUILD / 'download.lock').open('a') as lock:
        fcntl.flock(lock, fcntl.LOCK_EX | fcntl.LOCK_NB)
        ledger_path = BUILD / 'downloads.json'
        ledger = json.loads(ledger_path.read_text()) if ledger_path.exists() else {'schema_version': 1, 'records': {}, 'batches': []}
        records = ledger['records']
        groups = {}
        manifests = {}
        department_decisions = {}
        for decision in ['excluded', 'uncertain', 'selected']:
            selection_path = BUILD / 'cooper' / ('department-' + decision + '.json')
            if selection_path.exists():
                selection_items = json.loads(selection_path.read_text())
                if not isinstance(selection_items, list):
                    raise ValueError('Department selection file must contain an array: ' + str(selection_path))
                for selected_node in selection_items:
                    selected_app = selected_node.get('app') or ('cooper' if selected_node['kind'] == 'space' else 'knowledge')
                    department_decisions[selected_app + ':' + str(selected_node['id'])] = {
                        'decision': decision, 'reason': selected_node.get('relevance_reason', ''), 'file': str(selection_path.relative_to(BASE))}
        promoted_path = BUILD / 'cooper' / 'department-promoted.json'
        if promoted_path.exists():
            promoted_items = json.loads(promoted_path.read_text())
            if not isinstance(promoted_items, list):
                raise ValueError('Department promoted selection file must contain an array: ' + str(promoted_path))
            for promoted_node in promoted_items:
                promoted_app = promoted_node.get('app', 'knowledge')
                department_decisions[promoted_app + ':' + str(promoted_node['id'])] = {
                    'decision': 'selected',
                    'reason': promoted_node.get('reason', 'Promoted for body review'),
                    'file': str(promoted_path.relative_to(BASE)),
                }
        direction_keys = set()
        for direction_root in ['internal', 'platform', 'efficiency', 'planning']:
            direction_path = BUILD / 'cooper' / (direction_root + '.json')
            if direction_path.exists():
                for direction_node in json.loads(direction_path.read_text())['nodes']:
                    evidence = '/'.join(direction_node.get('path') or [direction_node.get('title', '')])
                    if direction_node.get('type') in BODY_TYPES and not EXCLUDE.search(evidence):
                        direction_app = direction_node.get('app') or ('cooper' if direction_node['kind'] == 'space' else 'knowledge')
                        direction_keys.add(direction_app + ':' + str(direction_node['id']))
        for root in args.roots:
            manifest = json.loads((BUILD / 'cooper' / (root + '.json')).read_text())
            pending_dirs = manifest.get('pending_directories', [])
            manifests[root] = {'status': manifest.get('status'), 'nodes': len(manifest['nodes']), 'pending_directories': len(pending_dirs) if isinstance(pending_dirs, list) else pending_dirs}
            groups[root] = []
            nodes = list(manifest['nodes'])
            root_spec = manifest.get('root', [])
            if isinstance(root_spec, list) and len(root_spec) == 4 and root_spec[1] == 'knowledge':
                _, _, container, root_id = root_spec
                if not any(str(n['id']) == str(root_id) for n in nodes):
                    nodes.insert(0, {'root': root, 'kind': 'knowledge', 'container_id': str(container), 'id': str(root_id),
                                     'title': root + ' root (source title not yet resolved)', 'type': 'DK_PAGE', 'path': [],
                                     'is_root_body': True, 'url': 'https://cooper.didichuxing.com/knowledge/' + str(container) + '/' + str(root_id)})
            for node in nodes:
                app = node.get('app') or ('cooper' if node['kind'] == 'space' else 'knowledge')
                key = app + ':' + str(node['id'])
                record = records.setdefault(key, {'id': str(node['id']), 'app': app, 'file': 'raw/cooper/' + app + '-' + str(node['id']) + '.md', 'status': 'pending', 'occurrences': []})
                occurrence = {k: node.get(k) for k in ['root', 'container_id', 'title', 'type', 'path', 'url']}
                if occurrence not in record['occurrences']:
                    record['occurrences'].append(occurrence)
                if node.get('is_root_body'):
                    record['is_root_body'] = True
                if record['status'] == 'success':
                    path = BASE / record['file']
                    if not path.exists() or sha(path.read_bytes()) != record['sha256']:
                        record.update(status='failed', error='local_integrity_mismatch')
                    else:
                        continue
                kind = node.get('type', '')
                evidence = '/'.join(node.get('path') or [node.get('title', '')])
                if kind == 'DIR':
                    if record['status'] not in {'pending', 'failed'}:
                        continue
                    record.update(status='directory', reason='Traversal handled by inventory; not a body document')
                    continue
                if kind not in BODY_TYPES:
                    record.update(status='unsupported', reason='Not a known doc-fetch body type', resource_type=kind)
                    continue
                if EXCLUDE.search(evidence):
                    record.update(status='excluded', reason='Unrelated personnel/performance content', selection_evidence=evidence)
                    continue
                if root in DEPARTMENT_ROOTS:
                    decision = department_decisions.get(key, {'decision': 'uncertain', 'reason': 'Not classified in department selection manifests; manual review required'})
                    record['department_selection'] = decision
                    if decision['decision'] != 'selected' and key not in direction_keys:
                        record.update(status='excluded' if decision['decision'] == 'excluded' else 'pending_selection',
                                      reason=decision['reason'], selection_evidence=evidence)
                        continue
                if record.get('error') == 'local_integrity_mismatch':
                    continue
                if record.get('no_auto_retry'):
                    continue
                if record['status'] == 'failed' and not args.retry_failed:
                    continue
                if record['status'] == 'failed' and record.get('attempts', 0) >= 3:
                    continue
                record.update(status='pending', selection_evidence=evidence)
                groups[root].append(key)
        if args.register_only:
            ledger['summary'] = dict(collections.Counter(record['status'] for record in records.values()))
            registration = {'registered_at': now(), 'roots': args.roots, 'manifest_snapshots': manifests, 'summary': ledger['summary']}
            ledger.setdefault('registrations', []).append(registration)
            ledger['updated_at'] = now()
            atomic_json(ledger_path, ledger)
            print(json.dumps({'registration': registration, 'fetches': 0}, ensure_ascii=False))
            return
        def priority(key):
            evidence = ' '.join('/'.join(o.get('path') or [o.get('title', '')]) for o in records[key]['occurrences'])
            recent = bool(re.search(r'2026|26年|26Q[1-4]|26H[12]|LR26', evidence, re.I))
            core = bool(re.search(r'模型|价值统一|\bPK\b|CAA|DO[ _-]*价值', evidence, re.I))
            historical = bool(re.search(r'202[0-5]|2[0-5]年|LR25', evidence, re.I)) and not recent
            return (-int(records[key].get('is_root_body', False)), int(records[key].get('attempts', 0) > 0), -int(recent), -int(core), int(historical), key)
        for root in args.roots:
            groups[root].sort(key=priority)
        # Round-robin roots so a large subtree cannot starve the other sources.
        queue = []
        seen = set()
        while any(groups.values()) and len(queue) < args.limit:
            for root in args.roots:
                if groups[root]:
                    key = groups[root].pop(0)
                    if key not in seen:
                        queue.append(key)
                        seen.add(key)
                        if len(queue) == args.limit:
                            break
        batch = {'started_at': now(), 'roots': args.roots, 'manifest_snapshots': manifests, 'selected': len(queue), 'selected_keys': queue, 'retry_failed': args.retry_failed, 'limit': args.limit}
        ledger['batches'].append(batch)
        ledger['updated_at'] = now()
        atomic_json(ledger_path, ledger)
        with concurrent.futures.ThreadPoolExecutor(max_workers=args.workers) as pool:
            futures = {pool.submit(fetch, records[key].copy(), args.timeout): key for key in queue}
            for future in concurrent.futures.as_completed(futures):
                key = futures[future]
                records[key].update(future.result())
                ledger['updated_at'] = now()
                atomic_json(ledger_path, ledger)
                print(json.dumps({'key': key, 'status': records[key]['status'], 'error': records[key].get('error')}, ensure_ascii=False), flush=True)
        batch.update(finished_at=now(), results=dict(collections.Counter(records[key]['status'] for key in queue)))
        ledger['summary'] = dict(collections.Counter(record['status'] for record in records.values()))
        ledger['updated_at'] = now()
        atomic_json(ledger_path, ledger)
        print(json.dumps({'batch': batch, 'summary': ledger['summary']}, ensure_ascii=False), flush=True)

if __name__ == '__main__':
    main()
