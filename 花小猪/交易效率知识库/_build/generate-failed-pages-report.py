from collections import Counter
from pathlib import Path
import json

root = Path(__file__).resolve().parents[1]
ledger = json.loads((root / "_build/downloads.json").read_text())
failed = []
for key, item in ledger["records"].items():
    if item.get("status") != "failed":
        continue
    occurrence = (item.get("occurrences") or [{}])[0]
    failed.append({
        "key": key,
        "title": occurrence.get("title") or "（无标题）",
        "url": occurrence.get("url") or "",
        "error": item.get("error") or "unknown",
        "attempts": item.get("attempts") or 0,
    })

counts = Counter(x["error"] for x in failed)
lines = [
    "# Cooper 正文失败页面清单",
    "",
    f"共 {len(failed)} 个失败记录。该清单仅用于人工确认；未自动重试，也未绕过安全权限。",
    "",
    "## 失败原因汇总",
    "",
    "| 原因 | 数量 |",
    "| --- | ---: |",
]
for error, count in sorted(counts.items(), key=lambda x: (-x[1], x[0])):
    lines.append(f"| `{error}` | {count} |")
lines += ["", "## 页面明细", "", "| # | 页面 | 稳定 ID | 原因 | 尝试次数 |", "| ---: | --- | --- | --- | ---: |"]
for index, item in enumerate(sorted(failed, key=lambda x: (x["error"], x["title"], x["key"])), 1):
    title = item["title"].replace("|", "\\|").replace("\n", " ")
    label = f"[{title}]({item['url']})" if item["url"] else title
    lines.append(f"| {index} | {label} | `{item['key']}` | `{item['error']}` | {item['attempts']} |")
lines += [
    "",
    "## 处理建议",
    "",
    "- `empty_body`：页面可能为空、只有目录/附件或正文接口未返回内容，建议先人工打开核实。",
    "- 权限或安全拒读：由页面 owner/管理员授权后再增量重试；禁止绕过。",
    "- 其他接口错误：确认页面仍存在且可访问后，再按稳定 ID 单独重试。",
]
(root / "_build/failed-pages-report.md").write_text("\n".join(lines) + "\n")
print(json.dumps({"failed": len(failed), "reasons": counts}, ensure_ascii=False, default=dict))
