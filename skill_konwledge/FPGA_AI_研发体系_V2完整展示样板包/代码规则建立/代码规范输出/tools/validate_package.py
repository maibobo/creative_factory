#!/usr/bin/env python3
"""Run portable structural checks for the coding-standard package."""

import io
import json
import re
import subprocess
import sys
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
ERRORS = []


def fail(message):
    ERRORS.append(message)
    print("FAIL     " + message)


def ok(message):
    print("OK       " + message)


def load_json(relative_path):
    path = ROOT / relative_path
    try:
        with io.open(str(path), "r", encoding="utf-8") as stream:
            data = json.load(stream)
        ok(relative_path + " JSON")
        return data
    except (OSError, ValueError) as exc:
        fail(relative_path + " JSON: " + str(exc))
        return None


def strip_comments(text):
    text = re.sub(r"/\*.*?\*/", "", text, flags=re.DOTALL)
    return re.sub(r"//[^\n]*", "", text)


def check_sync_tool():
    result = subprocess.call(
        [sys.executable, str(ROOT / "tools" / "sync_custom_rules.py"), "--check"],
        cwd=str(ROOT),
    )
    if result != 0:
        fail("generated custom-rule blocks are stale")
    else:
        ok("generated custom-rule blocks")


def check_custom_rules(data):
    if data is None:
        return
    rules = data.get("rules", [])
    ids = [rule.get("id") for rule in rules if isinstance(rule, dict)]
    if len(ids) != len(set(ids)):
        fail("custom rule IDs are not unique")
    else:
        ok("custom rule IDs unique")

    expected = {
        "CUSTOM-RTL-001",
        "CUSTOM-RTL-002",
        "CUSTOM-RTL-003",
        "CUSTOM-RTL-004",
    }
    if set(ids) != expected:
        fail("custom rule ID set differs from the four published rules")
    else:
        ok("custom rule ID set")

    for document, label in (
        ("01_ASIC_Verilog_RTL代码规范.md", "RTL_STANDARD"),
        ("03_用户自定义规则.md", "CUSTOM_RULES_DOC"),
        ("04_代码评审检查表.md", "REVIEW_CHECKLIST"),
    ):
        text = (ROOT / document).read_text(encoding="utf-8")
        missing = sorted(rule_id for rule_id in expected if rule_id not in text)
        if missing:
            fail(label + " missing " + ",".join(missing))
        else:
            ok(label + " custom-rule references")


def check_approved_cells(data):
    if data is None:
        return
    expected = {
        "reset_sync",
        "bit_sync",
        "sync_fifo",
        "async_fifo",
        "dmux",
        "icg",
        "memory_macro",
        "arithmetic_ip",
    }
    cells = data.get("cells", [])
    categories = [cell.get("category") for cell in cells if isinstance(cell, dict)]
    if set(categories) != expected or len(categories) != len(expected):
        fail("approved cell categories are missing or duplicated")
    else:
        ok("approved cell category registry")

    valid_status = set(data.get("status_values", []))
    for cell in cells:
        if cell.get("status") not in valid_status:
            fail("invalid approved-cell status: " + str(cell.get("category")))


def check_markdown_links():
    pattern = re.compile(r"\[[^\]]+\]\(([^)]+)\)")
    missing = []
    for path in ROOT.rglob("*.md"):
        text = path.read_text(encoding="utf-8")
        for match in pattern.finditer(text):
            target = match.group(1).strip()
            if target.startswith(("http://", "https://", "mailto:", "#")):
                continue
            target = target.split("#", 1)[0]
            resolved = (path.parent / target).resolve()
            if not resolved.exists():
                missing.append("{} -> {}".format(path.relative_to(ROOT), target))
    if missing:
        for item in missing:
            fail("missing local link: " + item)
    else:
        ok("Markdown local links")


def check_rule_id_uniqueness():
    for document, label in (
        ("01_ASIC_Verilog_RTL代码规范.md", "RTL_STANDARD"),
        ("02_SystemVerilog_UVM验证代码规范.md", "SV_UVM_STANDARD"),
    ):
        text = (ROOT / document).read_text(encoding="utf-8")
        ids = re.findall(
            r"^\|\s*`((?:RTL|SV|UVM)-[A-Z]+-\d{3})`\s*\|",
            text,
            flags=re.MULTILINE,
        )
        duplicates = sorted(rule_id for rule_id in set(ids) if ids.count(rule_id) > 1)
        if duplicates:
            fail(label + " duplicate rule definitions: " + ",".join(duplicates))
        else:
            ok(label + " rule IDs unique")


def check_rtl_sources():
    forbidden = re.compile(r"\b(?:logic|always_ff|always_comb|typedef|interface|class)\b")
    declaration_assignment = re.compile(r"\bwire\b[^;\n]*=")
    problems = []
    for path in (ROOT / "examples").rglob("*.v"):
        code = strip_comments(path.read_text(encoding="utf-8"))
        if forbidden.search(code):
            problems.append(str(path.relative_to(ROOT)) + " uses SystemVerilog RTL syntax")
        if declaration_assignment.search(code):
            problems.append(str(path.relative_to(ROOT)) + " assigns wire in declaration")
    if problems:
        for problem in problems:
            fail(problem)
    else:
        ok("Verilog examples use the selected RTL subset")


def check_uvm_sources():
    forbidden_patterns = {
        "uvm_do macro": re.compile(r"`uvm_do"),
        "default_sequence": re.compile(r"\bdefault_sequence\b"),
        "display call": re.compile(r"\$display\s*\("),
        "finish call": re.compile(r"\$finish\s*\("),
        "unbounded config wildcard": re.compile(
            r"uvm_config_db[^;]*::(?:set|get)\s*\([^;]*[\"']\*[\"']",
            re.DOTALL,
        ),
    }
    problems = []
    source_root = ROOT / "examples" / "sv_uvm_minimal" / "src"
    for path in source_root.iterdir():
        if path.suffix not in {".sv", ".svh", ".v"}:
            continue
        code = strip_comments(path.read_text(encoding="utf-8"))
        for name, pattern in forbidden_patterns.items():
            if pattern.search(code):
                problems.append("{}: {}".format(path.name, name))
    if problems:
        for problem in problems:
            fail(problem)
    else:
        ok("UVM example prohibited-pattern scan")


def check_filelist():
    root = ROOT / "examples" / "sv_uvm_minimal"
    entries = []
    for line in (root / "filelist.f").read_text(encoding="utf-8").splitlines():
        line = line.strip()
        if not line or line.startswith("+"):
            continue
        entries.append(line)
    missing = [entry for entry in entries if not (root / entry).exists()]
    if missing:
        for entry in missing:
            fail("filelist entry missing: " + entry)
    else:
        ok("UVM filelist entries")


def main():
    custom_rules = load_json("config/custom_rules.json")
    approved_cells = load_json("config/approved_cells.json")
    check_sync_tool()
    check_custom_rules(custom_rules)
    check_approved_cells(approved_cells)
    check_markdown_links()
    check_rule_id_uniqueness()
    check_rtl_sources()
    check_uvm_sources()
    check_filelist()

    if ERRORS:
        print("RESULT   FAIL ({} issue(s))".format(len(ERRORS)))
        return 1
    print("RESULT   PASS")
    return 0


if __name__ == "__main__":
    sys.exit(main())
