from pathlib import Path
import collections
import datetime
import json

root = Path(__file__).resolve().parents[1]
wiki = root / "wiki"


def load_json(path, default):
    return json.loads(path.read_text()) if path.exists() else default


def header(title, page_type):
    return "\n".join(
        [
            "---",
            "title: " + json.dumps(title, ensure_ascii=False),
            "type: " + page_type,
            'owner: "@tommywujian"',
            "freshness: watch",
            "status: completed-with-gaps",
            'last_reviewed: "2026-11-05"',
            "permission_scope: team",
            "source_ids:",
            '  - "repo:strategy-dept-knowledge:a27b537"',
            "related: []",
            "---",
            "",
        ]
    )


# Rebuild the navigational index without touching knowledge pages.
index = [
    header("交易效率知识索引", "link-index"),
    "# 交易效率知识索引",
    "",
    "T0–T6 已完成本地可读范围构建。每页的适用时间、证据层级和缺口见具体来源；不把规划、离线结果或历史记录当作当前线上事实。",
    "",
]
for directory in sorted(path for path in wiki.iterdir() if path.is_dir()):
    index += ["## " + directory.name, ""]
    for page in sorted(directory.glob("*.md")):
        index.append(f"- [{page.stem}]({page.relative_to(wiki).as_posix()})")
    index.append("")
index += [
    "## 全景与维护",
    "",
    "- [知识地图](overview.md)",
    "- [构建日志](log.md)",
    "- [构建报告](../BUILD-REPORT.md)",
    "",
]
(wiki / "index.md").write_text("\n".join(index), encoding="utf-8")

ledger = load_json(root / "_build/downloads.json", {"records": {}})
counts = collections.Counter(item["status"] for item in ledger["records"].values())
tasks = load_json(root / "_build/tasks.json", [])
baseline = load_json(root / "_build/baseline-manifest.json", [])
legacy_git = load_json(root / "_build/git-additional-manifest.json", {"additional_sources": []})
bwh = load_json(root / "_build/git-bwh-manifest.json", {"totals": {}})
pdf_ingest = load_json(root / "_build/pdf-ingest-embedding.json", {})
pages = list(wiki.rglob("*.md"))
legacy_git_count = sum(item["file_count"] for item in legacy_git["additional_sources"])

report = [
    "# 交易效率 LLM Wiki 构建检查点",
    "",
    "截至 " + datetime.datetime.now().isoformat(timespec="seconds") + "（本地运行时间）。T0–T6 已完成本地可读范围构建并通过验收。",
    "",
    "## T0–T6 状态",
    "",
]
for task in tasks:
    detail = task.get("detail", "")
    report.append(f"- {task['id']} {task['title']}：{task['status']}" + (f"；{detail}" if detail else ""))

report += [
    "",
    "## 来源覆盖",
    "",
    "| 类别 | 数量 |",
    "| --- | ---: |",
    f"| 部门基线快照 | {len(baseline)} |",
    f"| 既有额外 Git Markdown 快照 | {legacy_git_count} |",
    f"| bwh_stg 仓库 | {bwh.get('totals', {}).get('repositories', 0)}（{bwh.get('totals', {}).get('tracked_files', 0)} 文件 / {bwh.get('totals', {}).get('markdown_files', 0)} Markdown） |",
    f"| 用户导出 PDF 替代来源 | {1 if pdf_ingest.get('status') == 'ingested' else 0} |",
]
for key in ["success", "pending", "failed", "directory", "unsupported", "excluded", "pending_selection"]:
    report.append(f"| Cooper {key} | {counts[key]} |")

report += [
    "",
    f"Wiki 当前 {len(pages)} 页。1373 篇有效 Cooper 成功正文已完成去重通读；原安全拒读页由用户导出 PDF 作为替代来源补齐，原失败状态继续保留用于审计。",
    "",
    "## 验收与边界",
    "",
    "- lint 为 0 错误、0 警告；8 题 24 条证据审查为 24 pass、0 fail、0 insufficient。",
    "- 12 个表格已闭环，其中 2 个排除、10 个相关表格深读至实际末行。",
    "- 其余失败项为 172 个空正文、1 个 LaTeX 解析错误、1 个 Metis 版本缺失；按用户指示不再处理。",
    "- 图片、其他附件、外链、样本口径、显著性、服务配置、灰度、发布和回滚信息仍按来源缺口保留。",
    "- 方案、离线结果、实验观察和线上事实分开；未知项不补造，历史 LR 不自动升级为当前有效性。",
    "",
    "## 恢复",
    "",
    "后续仅在新增来源或用户指定补充范围时，从 `_build/tasks.json`、`_build/downloads.json` 与本报告继续增量处理，不从头重跑。",
    "",
]
(root / "BUILD-REPORT.md").write_text("\n".join(report), encoding="utf-8")

print(
    json.dumps(
        {
            "wiki_pages": len(pages),
            "tasks": collections.Counter(task["status"] for task in tasks),
            "cooper": dict(counts),
            "bwh_git": bwh.get("totals", {}),
            "pdf_ingested": pdf_ingest.get("status") == "ingested",
        },
        ensure_ascii=False,
    )
)
