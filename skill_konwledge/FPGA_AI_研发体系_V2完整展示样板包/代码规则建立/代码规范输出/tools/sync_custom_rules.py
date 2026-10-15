#!/usr/bin/env python3
"""Validate and synchronize user-defined RTL rules into Markdown documents."""

import argparse
import json
import sys
from pathlib import Path
from typing import Any, Callable, Dict, List, Set, Tuple


ROOT = Path(__file__).resolve().parents[1]
CONFIG_PATH = ROOT / "config" / "custom_rules.json"
BEGIN = "<!-- BEGIN GENERATED: {name} -->"
END = "<!-- END GENERATED: {name} -->"


def load_config() -> Dict[str, Any]:
    try:
        data = json.loads(CONFIG_PATH.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as exc:
        raise ValueError(f"cannot read {CONFIG_PATH}: {exc}") from exc

    if not isinstance(data, dict) or not isinstance(data.get("rules"), list):
        raise ValueError("config must contain a rules array")

    required = {
        "id",
        "title",
        "severity",
        "scope",
        "statement",
        "rationale",
        "definitions",
        "exceptions",
        "exception_requirements",
        "good_example",
        "bad_example",
        "review_hint",
    }
    seen: Set[str] = set()
    for index, rule in enumerate(data["rules"]):
        if not isinstance(rule, dict):
            raise ValueError(f"rules[{index}] must be an object")
        missing = sorted(required - set(rule))
        if missing:
            raise ValueError(f"rules[{index}] missing fields: {', '.join(missing)}")
        rule_id = rule["id"]
        if not isinstance(rule_id, str) or not rule_id.startswith("CUSTOM-RTL-"):
            raise ValueError(f"rules[{index}].id has invalid format")
        if rule_id in seen:
            raise ValueError(f"duplicate rule id: {rule_id}")
        seen.add(rule_id)
        if rule["severity"] not in {"M1", "M2", "R"}:
            raise ValueError(f"{rule_id} has invalid severity")
        for field in ("definitions", "exceptions", "exception_requirements"):
            if not isinstance(rule[field], list):
                raise ValueError(f"{rule_id}.{field} must be an array")
    return data


def bullet_lines(values: List[str], empty_text: str) -> List[str]:
    if not values:
        return [f"- {empty_text}"]
    return [f"- {value}" for value in values]


def render_summary(data: Dict[str, Any]) -> str:
    lines = [
        "| 编号 | 级别 | 标题 | 强制要求 |",
        "|---|---|---|---|",
    ]
    for rule in data["rules"]:
        statement = str(rule["statement"]).replace("|", "\\|").replace("\n", " ")
        lines.append(
            f"| `{rule['id']}` | {rule['severity']} | {rule['title']} | {statement} |"
        )
    lines.extend(
        [
            "",
            f"规则优先级：{data['precedence']}",
            "",
            f"生成源：`config/custom_rules.json`，规则版本 `{data['document_version']}`，更新时间 `{data['last_updated']}`。",
        ]
    )
    return "\n".join(lines)


def render_detail(data: Dict[str, Any]) -> str:
    lines: List[str] = []
    for rule in data["rules"]:
        lines.extend(
            [
                f"## {rule['id']}：{rule['title']} [{rule['severity']}]",
                "",
                f"**适用范围：** {rule['scope']}",
                "",
                f"**规则：** {rule['statement']}",
                "",
                f"**理由：** {rule['rationale']}",
                "",
                "**定义：**",
                "",
                *bullet_lines(rule["definitions"], "无补充定义。"),
                "",
                "**允许的例外：**",
                "",
                *bullet_lines(rule["exceptions"], "不允许例外。"),
                "",
                "**例外成立的附加条件：**",
                "",
                *bullet_lines(rule["exception_requirements"], "不适用。"),
                "",
                "**符合示例：**",
                "",
                "```verilog",
                rule["good_example"],
                "```",
                "",
                "**不符合示例：**",
                "",
                "```verilog",
                rule["bad_example"],
                "```",
                "",
                f"**评审提示：** {rule['review_hint']}",
                "",
            ]
        )
    return "\n".join(lines).rstrip()


def render_checklist(data: Dict[str, Any]) -> str:
    lines = [
        "| 完成 | 编号 | 级别 | 检查项 | 证据/豁免单 |",
        "|---|---|---|---|---|",
    ]
    for rule in data["rules"]:
        hint = str(rule["review_hint"]).replace("|", "\\|")
        lines.append(f"| [ ] | `{rule['id']}` | {rule['severity']} | {hint} |  |")
    lines.extend(
        [
            "",
            "> M1 问题必须修复后才能合入；M2 问题应修复，确需保留时必须关联书面豁免；R 为推荐改进。",
        ]
    )
    return "\n".join(lines)


TARGETS = (  # type: Tuple[Tuple[Path, str, Callable[[Dict[str, Any]], str]], ...]
    (ROOT / "01_ASIC_Verilog_RTL代码规范.md", "CUSTOM_RULES_SUMMARY", render_summary),
    (ROOT / "03_用户自定义规则.md", "CUSTOM_RULES_DETAIL", render_detail),
    (ROOT / "04_代码评审检查表.md", "CUSTOM_RULES_CHECKLIST", render_checklist),
)


def replace_block(text: str, name: str, body: str, path: Path) -> str:
    begin = BEGIN.format(name=name)
    end = END.format(name=name)
    if text.count(begin) != 1 or text.count(end) != 1:
        raise ValueError(f"{path}: expected exactly one marker pair for {name}")
    start = text.index(begin)
    finish = text.index(end, start) + len(end)
    block = f"{begin}\n{body.rstrip()}\n{end}"
    return text[:start] + block + text[finish:]


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Synchronize custom RTL rules into controlled Markdown blocks."
    )
    mode = parser.add_mutually_exclusive_group(required=True)
    mode.add_argument("--check", action="store_true", help="fail if generated blocks are stale")
    mode.add_argument("--write", action="store_true", help="update generated blocks")
    args = parser.parse_args()

    try:
        data = load_config()
        stale = []  # type: List[Path]
        for path, name, renderer in TARGETS:
            current = path.read_text(encoding="utf-8")
            expected = replace_block(current, name, renderer(data), path)
            if expected == current:
                print(f"OK       {name}")
                continue
            stale.append(path)
            if args.write:
                path.write_text(expected, encoding="utf-8")
                print(f"UPDATED  {name}")
            else:
                print(f"STALE    {name}")
        if stale and args.check:
            print("Run tools/sync_custom_rules.py --write to update controlled blocks.")
            return 1
        return 0
    except (OSError, ValueError) as exc:
        print(f"ERROR: {exc}", file=sys.stderr)
        return 2


if __name__ == "__main__":
    raise SystemExit(main())
