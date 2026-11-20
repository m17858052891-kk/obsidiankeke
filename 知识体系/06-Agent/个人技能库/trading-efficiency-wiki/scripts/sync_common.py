"""Shared, deterministic primitives for Wiki synchronization (Python 3.9+)."""
from contextlib import contextmanager
from datetime import datetime, timezone
import hashlib
import json
import os
from pathlib import Path
import re
import subprocess
import tempfile
from urllib.parse import parse_qsl, urlencode, urlsplit, urlunsplit

REMOTE = 'git@git.xiaojukeji.com:bwh_stg/trading-efficiency-wiki.git'
EXPORT_NOTICE = re.compile(r'^\s*<!--\s*请注意：文档内的附件与图片将在.*?-->\s*', re.S)
URL = re.compile(r'https?://[^\s<>"\)\]]+')
SIGNED_KEYS = {'x-amz-signature', 'x-amz-date', 'x-amz-credential',
               'x-amz-expires', 'x-amz-security-token', 'x-amz-signedheaders'}


def now():
    return datetime.now(timezone.utc).isoformat(timespec='seconds')


def digest(data):
    return hashlib.sha256(data).hexdigest()


def canonical_url(match):
    value = match.group(0)
    parts = urlsplit(value)
    query = parse_qsl(parts.query, keep_blank_values=True)
    drop = set(SIGNED_KEYS)
    if parts.hostname and parts.hostname.endswith(('.didichuxing.com', '.didistatic.com', '.xiaojukeji.com')):
        if any(key.lower() == 'sign' for key, _ in query):
            drop.update({'sign', 'expired'})
    kept = [(key, val) for key, val in query if key.lower() not in drop]
    return urlunsplit((parts.scheme, parts.netloc, parts.path, urlencode(kept), parts.fragment))


def canonical_text(body):
    body = EXPORT_NOTICE.sub('', body).replace('\r\n', '\n')
    return URL.sub(canonical_url, body).strip()


def content_hash(body):
    return digest(canonical_text(body).encode('utf-8'))


def validate_body(body):
    if not isinstance(body, str) or not re.sub(r'<!--.*?-->', '', body, flags=re.S).strip():
        raise ValueError('empty_body')
    visible = re.sub(r'<!--.*?-->', '', body, flags=re.S).strip()
    if re.search(r'^(读取内容失败|Failed to fetch (?:markdown )?content|Metis.*(?:错误|不存在)|guid or latestVersion is null from metis response|500 Internal Server Error)', visible, re.I):
        raise ValueError('export_error')
    return body


def validate_revision(previous, current):
    """A flattened export cannot prove that structured source content was deleted."""
    a, b = canonical_text(previous), canonical_text(current)
    old_blocks = len(re.findall(r'(?m)^(?:#{1,6}\s|\|.*\||[-*]\s|>\s?)', a))
    new_blocks = len(re.findall(r'(?m)^(?:#{1,6}\s|\|.*\||[-*]\s|>\s?)', b))
    if (a.count('\n') >= 3 and b.count('\n') < 2) or (old_blocks >= 8 and new_blocks == 0):
        raise ValueError('export_structure_lost; retain previous version pending source verification')
    if len(a) > 2000 and len(b) < 100:
        raise ValueError('export_suspiciously_short; retain previous version pending source verification')
    return current


def atomic_json(path, value):
    path = Path(path)
    path.parent.mkdir(parents=True, exist_ok=True)
    handle, temp = tempfile.mkstemp(prefix=path.name + '.', dir=str(path.parent))
    try:
        with os.fdopen(handle, 'w', encoding='utf-8') as out:
            json.dump(value, out, ensure_ascii=False, indent=2)
            out.write('\n')
            out.flush()
            os.fsync(out.fileno())
        os.replace(temp, path)
    finally:
        if os.path.exists(temp):
            os.unlink(temp)


def save_immutable(path, data):
    path = Path(path)
    path.parent.mkdir(parents=True, exist_ok=True)
    if path.exists():
        if path.read_bytes() != data:
            raise ValueError('immutable_snapshot_differs: ' + str(path))
        return False
    # Exclusive linking publishes complete bytes and cannot overwrite a concurrent writer.
    handle, temp = tempfile.mkstemp(dir=str(path.parent))
    try:
        with os.fdopen(handle, 'wb') as out:
            out.write(data)
            out.flush()
            os.fsync(out.fileno())
        try:
            os.link(temp, path)
        except FileExistsError:
            if path.read_bytes() != data:
                raise ValueError('immutable_snapshot_differs: ' + str(path))
            return False
    finally:
        if os.path.exists(temp):
            os.unlink(temp)
    return True


def run(args, cwd=None, timeout=120):
    env = dict(os.environ)
    env['GIT_TERMINAL_PROMPT'] = '0'
    env.setdefault('GIT_SSH_COMMAND', 'ssh -o BatchMode=yes -o ConnectTimeout=10 -o StrictHostKeyChecking=yes -o UpdateHostKeys=no')
    process = subprocess.run([str(x) for x in args], cwd=cwd, env=env,
                             stdout=subprocess.PIPE, stderr=subprocess.PIPE, timeout=timeout)
    if process.returncode:
        error = process.stderr.decode('utf-8', errors='replace')
        # Gateway errors can include URLs with signed access parameters.
        error = URL.sub(canonical_url, error)
        raise RuntimeError(error[-1200:] or 'command_failed')
    return process.stdout


def git(root, *args):
    return run(['git', '-C', root, *args]).decode('utf-8').strip()


def remote_identity(remote):
    remote = remote.removesuffix('.git').rstrip('/')
    remote = re.sub(r'^git@([^:]+):', r'\1/', remote)
    return re.sub(r'^https?://', '', remote)


def verify_repository(root, remote=REMOTE):
    root = Path(root).resolve()
    top = Path(git(root, 'rev-parse', '--show-toplevel')).resolve()
    if top != root:
        raise ValueError('path_is_inside_another_repository: ' + str(top))
    actual = git(root, 'remote', 'get-url', 'origin')
    if remote_identity(actual) != remote_identity(remote):
        raise ValueError('unexpected_remote: ' + actual)
    push_urls = git(root, 'remote', 'get-url', '--push', '--all', 'origin').splitlines()
    if len(push_urls) != 1 or remote_identity(push_urls[0]) != remote_identity(remote):
        raise ValueError('unexpected_push_remote')
    return root


@contextmanager
def exclusive_lock(path):
    path = Path(path)
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open('a+b') as handle:
        if os.name == 'nt':
            import msvcrt
            handle.seek(0)
            handle.write(b'0')
            handle.flush()
            handle.seek(0)
            msvcrt.locking(handle.fileno(), msvcrt.LK_NBLCK, 1)
        else:
            import fcntl
            fcntl.flock(handle, fcntl.LOCK_EX | fcntl.LOCK_NB)
        yield


def load_json(path, default=None):
    return json.loads(Path(path).read_text()) if Path(path).exists() else default
