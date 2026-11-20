#!/usr/bin/env python3
"""Validate the long-running paper-module handoff protocol without extra packages."""

from __future__ import annotations

import argparse
import json
import re
from collections import Counter
from pathlib import Path
from typing import Any


REQUIRED_FIELDS = {
    "协议版本",
    "模块编号",
    "论文编号",
    "论文标题",
    "模块名称",
    "解决问题",
    "一句话重点",
    "输入",
    "处理",
    "输出",
    "应用位置",
    "证据",
    "目标系统模块",
    "接入方式",
    "最小可接入单元",
    "离线训练内容",
    "在线更新内容",
    "耦合依赖",
    "数据前置条件",
    "不适用条件",
    "项目接入判断",
    "代码入口",
}

INTEGRATION_TYPES = {
    "直接替换",
    "前置增强",
    "后置校正",
    "训练约束",
    "评估组件",
    "耦合模块组",
    "整链路替代",
}

MATCH_LEVELS = {"直接", "邻接", "较弱"}
CHANGE_SCOPES = {"局部", "多模块", "整链路"}
DATA_READINESS = {"已有", "可加工", "缺失", "待项目确认"}


def load_jsonl(path: Path) -> list[tuple[int, dict[str, Any]]]:
    rows = []
    for line_number, line in enumerate(path.read_text(encoding="utf-8").splitlines(), start=1):
        if not line.strip():
            continue
        try:
            value = json.loads(line)
        except json.JSONDecodeError as error:
            raise SystemExit(f"{path}:{line_number} JSON 错误：{error}") from error
        if not isinstance(value, dict):
            raise SystemExit(f"{path}:{line_number} 必须是 JSON 对象")
        rows.append((line_number, value))
    return rows


def contract_targets(path: Path) -> set[str]:
    text = path.read_text(encoding="utf-8")
    targets = set(re.findall(r'^\s+中文名称:\s*"([^"]+)"\s*$', text, flags=re.MULTILINE))
    if not targets:
        raise SystemExit(f"{path} 中没有找到系统模块中文名称")
    return targets


def main() -> None:
    parser = argparse.ArgumentParser(description="校验论文模块中间协议")
    parser.add_argument("--project", default=".", help="长期项目根目录")
    args = parser.parse_args()

    project = Path(args.project).expanduser().resolve()
    modules_path = project / "research_map" / "paper_modules.jsonl"
    contract_path = project / "research_map" / "system_contract.yaml"
    if not modules_path.exists():
        raise SystemExit(f"缺少 {modules_path}")
    if not contract_path.exists():
        raise SystemExit(f"缺少 {contract_path}")

    targets = contract_targets(contract_path)
    rows = load_jsonl(modules_path)
    errors = []
    seen = set()
    integration_counts: Counter[str] = Counter()
    target_counts: Counter[str] = Counter()

    for line_number, record in rows:
        prefix = f"{modules_path}:{line_number}"
        missing = sorted(REQUIRED_FIELDS - record.keys())
        if missing:
            errors.append(f"{prefix} 缺少字段：{', '.join(missing)}")
        module_id = record.get("模块编号")
        if module_id in seen:
            errors.append(f"{prefix} 模块编号重复：{module_id}")
        seen.add(module_id)

        integration = record.get("接入方式")
        if integration not in INTEGRATION_TYPES:
            errors.append(f"{prefix} 非法接入方式：{integration}")
        else:
            integration_counts[integration] += 1

        module_targets = record.get("目标系统模块")
        if not isinstance(module_targets, list) or not module_targets:
            errors.append(f"{prefix} 目标系统模块必须是非空数组")
        else:
            unknown = sorted(set(module_targets) - targets)
            if unknown:
                errors.append(f"{prefix} 引用了契约中不存在的模块：{', '.join(unknown)}")
            target_counts.update(module_targets)

        judgement = record.get("项目接入判断")
        if not isinstance(judgement, dict):
            errors.append(f"{prefix} 项目接入判断必须是对象")
        else:
            if judgement.get("问题匹配") not in MATCH_LEVELS:
                errors.append(f"{prefix} 非法问题匹配：{judgement.get('问题匹配')}")
            if judgement.get("改造范围") not in CHANGE_SCOPES:
                errors.append(f"{prefix} 非法改造范围：{judgement.get('改造范围')}")
            if judgement.get("数据准备") not in DATA_READINESS:
                errors.append(f"{prefix} 非法数据准备值：{judgement.get('数据准备')}")

    if errors:
        raise SystemExit("协议校验失败：\n- " + "\n- ".join(errors))

    print(f"协议校验通过：{len(rows)} 个唯一模块，{len(targets)} 个系统接口。")
    print("接入方式：" + "，".join(f"{key} {value}" for key, value in sorted(integration_counts.items())))
    print("系统接口覆盖：" + "，".join(f"{key} {value}" for key, value in sorted(target_counts.items())))


if __name__ == "__main__":
    main()
