#!/usr/bin/env python3
"""Query paper-module handoff records with deterministic Chinese term matching."""

from __future__ import annotations

import argparse
import json
import re
from pathlib import Path
from typing import Any


CONCEPTS = {
    "离线评估": ["离线评估", "离线策略评估", "双重稳健", "价值估计", "行为支持", "propensity", "离线回放", "策略归因"],
    "用户状态": ["用户状态", "用户历史", "用户画像", "状态构造", "状态表示", "历史行为", "embedding", "潜向量", "序列状态"],
    "用户模拟": ["用户模拟", "仿真", "模拟器", "请求生成", "反馈生成", "闭环仿真"],
    "价格响应": ["价格响应", "用户选择", "接受", "拒绝", "放弃概率", "支付意愿", "mnl"],
    "延迟反馈": ["延迟反馈", "延迟结果", "延迟转化", "轨迹后验", "标签补全", "样本年龄"],
    "预算控制": ["预算", "预算控制", "预算节奏", "pacing", "mpc", "拉格朗日", "剩余预算"],
    "优惠探索": ["优惠", "券", "折扣", "增量效果", "冷启动", "探索", "uplift"],
    "反事实": ["反事实", "因果", "处理效果", "双重稳健", "propensity"],
}

GENERAL_TERMS = [
    "用户", "状态", "模拟", "仿真", "请求", "价格", "报价", "优惠", "券", "预算",
    "离线", "评估", "延迟", "反馈", "取消", "完单", "复购", "响应", "选择",
    "冷启动", "探索", "反事实", "等待", "收益", "归因", "表示", "序列",
]

FIELD_WEIGHTS = {
    "模块名称": 8,
    "目标系统模块": 8,
    "应用位置": 6,
    "解决问题": 5,
    "一句话重点": 4,
    "输入": 3,
    "输出": 3,
    "最小可接入单元": 3,
    "数据前置条件": 3,
    "处理": 2,
    "耦合依赖": 2,
    "不适用条件": 1,
}


def flatten(value: Any) -> str:
    if value is None:
        return ""
    if isinstance(value, dict):
        return " ".join(f"{key} {flatten(item)}" for key, item in value.items())
    if isinstance(value, list):
        return " ".join(flatten(item) for item in value)
    return str(value)


def query_terms(query: str) -> list[str]:
    lowered = query.lower()
    terms: set[str] = set()
    for concept, expansions in CONCEPTS.items():
        if concept.lower() in lowered or any(term.lower() in lowered for term in expansions):
            terms.update(term.lower() for term in expansions)
    terms.update(term.lower() for term in GENERAL_TERMS if term.lower() in lowered)
    terms.update(re.findall(r"[a-zA-Z][a-zA-Z0-9_+-]{1,}", lowered))
    if not terms:
        terms.update(part for part in re.split(r"[\s，。？！、；：,.?!;:]+", lowered) if len(part) >= 2)
    return sorted(terms, key=lambda item: (-len(item), item))


def score_record(record: dict[str, Any], terms: list[str]) -> tuple[int, list[str]]:
    score = 0
    matched: list[str] = []
    for field, weight in FIELD_WEIGHTS.items():
        text = flatten(record.get(field)).lower()
        hits = [term for term in terms if term in text]
        if hits:
            score += weight * len(set(hits))
            matched.append(f"{field}:{'/'.join(sorted(set(hits), key=len, reverse=True)[:3])}")
    return score, matched


def load_records(project: Path) -> list[dict[str, Any]]:
    path = project / "research_map" / "paper_modules.jsonl"
    if not path.exists():
        raise SystemExit(f"未找到模块协议：{path}")
    records = []
    for number, line in enumerate(path.read_text(encoding="utf-8").splitlines(), start=1):
        if not line.strip():
            continue
        try:
            records.append(json.loads(line))
        except json.JSONDecodeError as error:
            raise SystemExit(f"{path}:{number} 不是有效 JSON：{error}") from error
    return records


def main() -> None:
    parser = argparse.ArgumentParser(description="查询论文模块中间协议")
    parser.add_argument("query", help="自然语言问题，例如：离线评估可以采用什么方法")
    parser.add_argument("--project", default=".", help="长期项目根目录")
    parser.add_argument("--target", help="只返回指定目标系统模块")
    parser.add_argument("--integration", help="只返回指定接入方式")
    parser.add_argument("--limit", type=int, default=8, help="最多返回多少条")
    parser.add_argument("--json", action="store_true", help="输出完整 JSON 数组")
    args = parser.parse_args()

    project = Path(args.project).expanduser().resolve()
    terms = query_terms(args.query)
    ranked = []
    for record in load_records(project):
        if args.target and args.target not in flatten(record.get("目标系统模块")):
            continue
        if args.integration and args.integration != record.get("接入方式"):
            continue
        score, matched = score_record(record, terms)
        if score > 0:
            ranked.append((score, record.get("模块编号", ""), matched, record))

    ranked.sort(key=lambda item: (-item[0], item[1]))
    selected = ranked[: max(args.limit, 0)]
    if args.json:
        print(json.dumps([item[3] for item in selected], ensure_ascii=False, indent=2))
        return

    if not selected:
        print("没有找到匹配模块。可尝试使用用户状态、离线评估、延迟反馈、预算控制等问题词。")
        return

    print(f"找到 {len(selected)} 个匹配模块（查询词：{'、'.join(terms)}）")
    for index, (score, _, matched, record) in enumerate(selected, start=1):
        targets = "、".join(record.get("目标系统模块", [])) or "待映射"
        judgement = record.get("项目接入判断", {})
        scope = judgement.get("改造范围", "待确认")
        print(f"\n{index}. {record.get('论文标题')}｜{record.get('模块名称')}｜匹配分 {score}")
        print(f"   接入：{targets}；{record.get('接入方式', '待确认')}；{scope}")
        print(f"   最小单元：{record.get('最小可接入单元', '待确认')}")
        print(f"   数据要求：{'；'.join(record.get('数据前置条件', [])) or '待确认'}")
        print(f"   命中：{'；'.join(matched)}")


if __name__ == "__main__":
    main()
