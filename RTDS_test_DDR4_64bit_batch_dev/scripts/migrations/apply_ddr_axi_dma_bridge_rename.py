#!/usr/bin/env python3
"""Apply the CONV_DMA -> ddr_axi_dma_bridge source rename locally.

Default mode is a dry run. Pass --apply to rename/update only the RTL source,
the source-file entry in the Vivado .xpr, and the backward-compatible BD
refresh entry point. The BD itself is deliberately updated by Vivado Tcl.
"""
from __future__ import annotations

import argparse
import json
import re
from pathlib import Path
from typing import Dict, Iterable

SCRIPT_DIR = Path(__file__).resolve().parent
DEFAULT_PROJECT_ROOT = SCRIPT_DIR.parent.parent


def replace_identifiers(text: str, mapping: Dict[str, str]) -> str:
    for old, new in sorted(mapping.items(), key=lambda item: len(item[0]), reverse=True):
        text = re.sub(r"(?<![A-Za-z0-9_$])" + re.escape(old) +
                      r"(?![A-Za-z0-9_$])", new, text)
    return text


def strip_line_comments(text: str) -> str:
    return "\n".join(line.split("//", 1)[0] for line in text.splitlines())


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--project-root", type=Path, default=DEFAULT_PROJECT_ROOT)
    parser.add_argument("--apply", action="store_true", help="write changes; otherwise only report")
    args = parser.parse_args()

    root = args.project_root.resolve()
    mapping_path = SCRIPT_DIR / "conv_dma_to_ddr_axi_dma_bridge.mapping.json"
    mapping = json.loads(mapping_path.read_text(encoding="utf-8"))
    old_source = root / mapping["paths"]["old_source"]
    new_source = root / mapping["paths"]["new_source"]
    xpr = root / mapping["paths"]["project_file"]
    refresh_entry = root / mapping["paths"]["refresh_entrypoint"]
    bd_tcl = root / mapping["paths"]["bd_update_tcl"]

    if not xpr.is_file():
        raise FileNotFoundError(f"Vivado project not found: {xpr}")
    if not bd_tcl.is_file():
        raise FileNotFoundError(f"BD update Tcl not found: {bd_tcl}")
    if old_source.exists() and new_source.exists():
        raise RuntimeError("Both old and new RTL files exist; refusing to overwrite either.")
    source = old_source if old_source.exists() else new_source
    if not source.is_file():
        raise FileNotFoundError(f"Neither source exists: {old_source} / {new_source}")

    rtl = source.read_text(encoding="utf-8")
    rtl = replace_identifiers(rtl, mapping.get("identifier_renames", {}))
    rtl = replace_identifiers(rtl, mapping.get("cleanup_identifier_renames", {}))
    for edit in mapping.get("comment_edits", []):
        rtl = rtl.replace(edit["find"], edit["replace"])

    code_only = strip_line_comments(rtl)
    if not re.search(r"\bmodule\s+ddr_axi_dma_bridge\b", code_only):
        raise RuntimeError("Expected module declaration 'ddr_axi_dma_bridge' was not found.")
    if re.search(r"\bmodule\s+CONV_DMA\b", code_only):
        raise RuntimeError("Legacy module declaration remains after mapping.")
    for group_name in ("identifier_renames", "cleanup_identifier_renames"):
        for old_name in mapping.get(group_name, {}):
            if re.search(r"(?<![A-Za-z0-9_$])" + re.escape(old_name) +
                         r"(?![A-Za-z0-9_$])", code_only):
                raise RuntimeError(f"Legacy identifier remains after {group_name}: {old_name}")
    for port in mapping.get("port_mappings", []):
        if not re.search(r"(?<![A-Za-z0-9_$])" + re.escape(port["to"]) +
                         r"(?![A-Za-z0-9_$])", code_only):
            raise RuntimeError(f"Mapped RTL port is missing: {port['to']}")

    xpr_text = xpr.read_text(encoding="utf-8")
    old_ref = mapping["project_reference"]["from"]
    new_ref = mapping["project_reference"]["to"]
    if old_ref in xpr_text:
        xpr_new = xpr_text.replace(old_ref, new_ref)
    elif new_ref in xpr_text:
        xpr_new = xpr_text
    else:
        raise RuntimeError(f"Neither expected RTL reference was found in {xpr}: {old_ref}")

    refresh_text = (
        "# Backward-compatible entry point; the migration is implemented in the dedicated BD Tcl.\n"
        "set _refresh_dir [file dirname [file normalize [info script]]]\n"
        "source [file join $_refresh_dir update_ddr_axi_dma_bridge_bd.tcl]\n"
    )

    planned = [
        f"RTL: {source.relative_to(root)} -> {new_source.relative_to(root)}",
        f"XPR: update source reference {old_ref} -> {new_ref}",
        f"BD refresh entry: replace {refresh_entry.relative_to(root)} with a wrapper to {bd_tcl.relative_to(root)}",
        "BD JSON/generated IP outputs: not edited by this Python script; run the Vivado Tcl after applying."
    ]
    print("DRY RUN" if not args.apply else "APPLY")
    for item in planned:
        print(" - " + item)
    if not args.apply:
        print("No files changed. Re-run with --apply to write the migration.")
        return 0

    new_source.parent.mkdir(parents=True, exist_ok=True)
    new_source.write_text(rtl, encoding="utf-8")
    if source == old_source and old_source.exists():
        old_source.unlink()
    xpr.write_text(xpr_new, encoding="utf-8")
    refresh_entry.write_text(refresh_text, encoding="utf-8")
    print("Applied. Next: run Vivado 2020.2 with scripts/update_ddr_axi_dma_bridge_bd.tcl.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
