#!/usr/bin/env python3
"""归档总览中已勾选的论文，并按候选顺序只填补空出的阅读槽。"""
import argparse
from contextlib import contextmanager
from dataclasses import dataclass
from datetime import date, datetime
import fcntl
import hashlib
import json
import os
from pathlib import Path
import re
import stat
import sys
import tempfile
from zoneinfo import ZoneInfo


SLOT = re.compile(
    r"^<!-- 先读槽 ([123]) -->\r?\n(?P<body>.*?)^<!-- 先读槽 \1 结束 -->\r?$",
    re.MULTILINE | re.DOTALL,
)
ITEM = re.compile(r"\A<!-- 先读条目 (\{[^\n]*\}) -->\r?\n")
TASK = re.compile(r"^([ \t]*- )\[([ xX])\][ \t]+", re.MULTILINE)
ENTRY = re.compile(
    r"^<!-- 已读条目 (\{[^\n]*\}) -->\r?\n(?P<body>.*?)^<!-- 已读条目结束 -->\r?$",
    re.MULTILINE | re.DOTALL,
)
EXCERPT = re.compile(
    r"^<!-- 先读摘录 ([0-9a-f]{64}) -->\r?\n(.*?)^<!-- 先读摘录结束 -->\r?$",
    re.MULTILINE | re.DOTALL,
)


class ChangedOnDisk(Exception):
    """An editor or another process changed a file before replacement."""


@dataclass
class Slot:
    span: tuple
    body: str
    paper: dict
    completed: bool
    excerpt: str


def encode(value):
    return json.dumps(value, ensure_ascii=False, separators=(",", ":"))


def digest(text):
    return hashlib.sha256(text.encode("utf-8")).hexdigest()


def paper_key(paper):
    fields = ("id", "version", "canonical_note")
    if any(not isinstance(paper.get(k), str) or not paper[k].strip() for k in fields):
        raise ValueError("条目标识、版本或正文路径缺失。")
    return paper["id"], paper["version"]


def parse_slots(home):
    matches = list(SLOT.finditer(home))
    if [m[1] for m in matches] != ["1", "2", "3"] or home.count("<!-- 先读槽 ") != 6:
        raise ValueError("总览的三个阅读槽标记不完整或次序异常。")
    slots = []
    for match in matches:
        body = match["body"]
        if not body.strip():
            slots.append(Slot(match.span("body"), body, {}, False, ""))
            continue
        meta = ITEM.match(body)
        if not meta:
            raise ValueError(f"第 {match[1]} 槽标识不可识别，已保留原文。")
        info = json.loads(meta[1])
        paper_key(info)
        excerpt = body[meta.end():]
        task = TASK.search(excerpt)
        if not task or excerpt[:task.start()].strip():
            raise ValueError(f"第 {match[1]} 槽的首个复选框不可识别，已保留原文。")
        completed = task[2].lower() == "x"
        # The archive keeps the question, links and all notes, with a plain list bullet.
        excerpt = excerpt[:task.start()] + task[1] + excerpt[task.end():]
        slots.append(Slot(match.span("body"), body, info, completed, excerpt))
    ids = [s.paper["id"] for s in slots if s.paper]
    if len(ids) != len(set(ids)):
        raise ValueError("总览中有重复论文，请核对手写条目。")
    return slots


def archive_index(archive):
    matches = list(ENTRY.finditer(archive))
    if len(matches) != archive.count("<!-- 已读条目 ") or len(matches) != archive.count("<!-- 已读条目结束 -->"):
        raise ValueError("已读页的记录边界不完整。")
    indexed = {paper_key(json.loads(m[1])): m for m in matches}
    if len(indexed) != len(matches):
        raise ValueError("已读页中有重复的论文版本。")
    return indexed


def add_read(archive, slot, today):
    key = paper_key(slot.paper)
    entry = archive_index(archive).get(key)
    excerpt = slot.excerpt
    if not excerpt.endswith("\n"):
        excerpt += "\n"
    fingerprint = digest(excerpt)
    saved = f"<!-- 先读摘录 {fingerprint} -->\n{excerpt}<!-- 先读摘录结束 -->"
    if entry is None:
        info = dict(slot.paper, recorded=today)
        return (archive + ("" if archive.endswith("\n\n") else "\n\n")
                + f"<!-- 已读条目 {encode(info)} -->\n**{today} · {info['version']}**\n\n"
                + saved + "\n<!-- 已读条目结束 -->\n")
    notes = list(EXCERPT.finditer(entry["body"]))
    if any(note[1] == fingerprint for note in notes):
        return archive
    # A retry may observe a newly written home annotation after the first archive write.
    if notes and digest(notes[-1][2]) == notes[-1][1]:
        start, end = notes[-1].span()
        offset = entry.start("body")
        return archive[:offset + start] + saved + archive[offset + end:]
    # Keep independently edited archive notes, appending the changed home snapshot.
    end = entry.end("body")
    return archive[:end] + "\n首页补记\n\n" + saved + "\n" + archive[end:]


def valid_candidates(root):
    logs = root / "_运行记录"
    pool = json.loads((logs / "近期先读候选.json").read_text(encoding="utf-8"))
    papers = json.loads((logs / "state.json").read_text(encoding="utf-8"))["papers"]
    if not isinstance(pool, list):
        raise ValueError("近期先读候选.json 须为数组。")
    by_id = {p["id"]: p for p in papers}
    choices, skipped = [], []
    for candidate in pool:
        if not isinstance(candidate, dict) or not isinstance(candidate.get("id"), str):
            skipped.append("候选格式不完整")
            continue
        paper = by_id.get(candidate.get("id"))
        name = str(candidate.get("id", "无 ID"))
        if not paper or not paper.get("canonical_note") or paper.get("version") != candidate.get("version"):
            skipped.append(f"{name}：缺少已登记正文或版本已变更")
            continue
        path = paper["canonical_note"]
        dest = (root.parent / path).resolve()
        if (not dest.is_relative_to(root.parent) or not path.endswith(".md") or not dest.is_file()
                or candidate.get("canonical_note", path) != path):
            skipped.append(f"{name}：正文路径无效")
            continue
        fields = ("id", "version", "question", "reason", "evidence")
        if any(not isinstance(candidate.get(k), str) or not candidate[k].strip()
               or "\n" in candidate[k] or "\r" in candidate[k] or "<!--" in candidate[k]
               or "-->" in candidate[k] for k in fields):
            skipped.append(f"{name}：精选文字不完整")
            continue
        if any(token in candidate["question"] for token in ("[[", "]]", "|")):
            skipped.append(f"{name}：问题中包含与链接冲突的符号")
            continue
        revision = candidate.get("revision_note", "")
        if not isinstance(revision, str) or any(s in revision for s in ("\r", "\n", "<!--", "-->")):
            skipped.append(f"{name}：版本变化说明格式无效")
            continue
        choices.append(dict(candidate, canonical_note=path))
    return choices, skipped


def render_item(candidate, newline):
    info = {key: candidate[key] for key in ("id", "version", "canonical_note")}
    link = info["canonical_note"][:-3]
    lines = [f"<!-- 先读条目 {encode(info)} -->", "",
             f"- [ ] [[{link}|{candidate['question']}]]",
             "  " + candidate["reason"] + " " + candidate["evidence"]]
    if candidate.get("revision_note"):
        lines.append("  此版变化：" + candidate["revision_note"])
    return newline.join(lines) + newline + newline


def plan(home, archive, choices, today):
    slots = parse_slots(home)
    done = [s for s in slots if s.completed]
    for slot in done:
        archive = add_read(archive, slot, today)
    read = set(archive_index(archive))
    previous = {key[0] for key in read}
    occupied = {s.paper["id"] for s in slots if s.paper and not s.completed}
    candidates = (c for c in choices if c["id"] not in occupied and paper_key(c) not in read
                  and (c["id"] not in previous or c.get("revision_note", "").strip()))
    changes = []
    filled = 0
    newline = "\r\n" if "\r\n" in home else "\n"
    for slot in slots:
        if slot.paper and not slot.completed:
            continue
        new = next(candidates, None)
        body = slot.body if not slot.paper else ""
        if new is not None:
            occupied.add(new["id"])
            filled += 1
            body = render_item(new, newline)
        if body != slot.body:
            changes.append((*slot.span, body))
    for start, end, body in reversed(changes):
        home = home[:start] + body + home[end:]
    return home, archive, len(done), filled


def read(path):
    try:
        return path.read_bytes().decode("utf-8")
    except FileNotFoundError:
        return None


def replace_if_unchanged(path, before, after):
    handle = tempfile.NamedTemporaryFile(mode="wb", prefix=".阅读-", dir=path.parent, delete=False)
    tmp = Path(handle.name)
    try:
        with handle:
            if before is not None:
                os.fchmod(handle.fileno(), stat.S_IMODE(path.stat().st_mode))
            handle.write(after.encode("utf-8"))
            handle.flush()
            os.fsync(handle.fileno())
        if read(path) != before:
            raise ChangedOnDisk
        os.replace(tmp, path)
        directory = os.open(path.parent, os.O_RDONLY)
        try:
            os.fsync(directory)
        finally:
            os.close(directory)
    finally:
        tmp.unlink(missing_ok=True)


@contextmanager
def serialized(directory):
    # All invocations lock the stable directory inode, not a note replaced atomically.
    fd = os.open(directory, os.O_RDONLY)
    try:
        fcntl.flock(fd, fcntl.LOCK_EX)
        yield
    finally:
        os.close(fd)


def refresh(root, today, dry_run=False, archive_only=False):
    root = root.resolve()
    logs = root / "_运行记录"
    home_path = root / "00-总览.md"
    archive_path = logs / "我的已读.md"
    with serialized(logs):
        choices, skipped = ([], []) if archive_only else valid_candidates(root)
        for _ in range(5):
            home, archive = read(home_path), read(archive_path)
            if home is None:
                raise ValueError("找不到 00-总览.md。")
            initial = archive if archive is not None else "# 我的已读\n\n记录日期取自日报读到勾选的当天。\n"
            target_home, target_archive, completed, filled = plan(home, initial, choices, today)
            try:
                if not dry_run:
                    if read(home_path) != home:
                        raise ChangedOnDisk
                    if target_archive != archive:
                        replace_if_unchanged(archive_path, archive, target_archive)
                    if read(archive_path) != target_archive:
                        raise ChangedOnDisk
                    if home != target_home:
                        replace_if_unchanged(home_path, home, target_home)
                return {"已勾": completed, "补入": filled, "预演": dry_run, "跳过候选": skipped}
            except ChangedOnDisk:
                continue
    raise RuntimeError("阅读页持续发生编辑；已保存的归档可在下一次重试时复用。")


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--root", type=Path, default=Path(__file__).resolve().parents[2],
                        help="研究前沿目录（默认从脚本位置确定）")
    parser.add_argument("--date", type=date.fromisoformat,
                        help="覆盖上海记录日期，供离线回放")
    parser.add_argument("--dry-run", "--check", action="store_true", help="仅计算变化")
    parser.add_argument("--archive-only", action="store_true",
                        help="扫描前先归档已勾并腾空原槽，此步骤无需候选池或检索状态")
    args = parser.parse_args()
    today = args.date or datetime.now(ZoneInfo("Asia/Shanghai")).date()
    try:
        print(json.dumps(refresh(args.root, today.isoformat(), args.dry_run, args.archive_only),
                         ensure_ascii=False))
    except (ValueError, KeyError, OSError, RuntimeError) as error:
        sys.exit(f"近期先读：{error}")


if __name__ == "__main__":
    main()
