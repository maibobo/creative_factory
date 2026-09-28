#!/usr/bin/env python3
"""Vivado/XSim parallel regression launcher.

This script is intentionally compatible with Python 3.6.
"""

import argparse
import concurrent.futures
import datetime as _dt
import json
import os
import random
import re
import shutil
import subprocess
import sys
import time
from collections import namedtuple
from pathlib import Path


Job = namedtuple("Job", "index testcase iteration repeat seed wave attempt")
Result = namedtuple(
    "Result",
    (
        "job run_status test_status fail_stage first_error wave_status wdb_size "
        "elapsed sim_log wdb stdout_log stderr_log returncode work_project_xpr "
        "work_loop_root work_retained extra_log_dir selected_vcd wavedrom_json "
        "wavedrom_svg wave_summary"
    ),
)

RUN_PASS = "PASS"
RUN_FAIL = "FAIL"
RUN_ARTIFACT_FAIL = "ARTIFACT_FAIL"

TEST_PASS = "PASS"
TEST_FAIL = "FAIL"
TEST_UNKNOWN = "UNKNOWN"

FAIL_NONE = "NONE"
FAIL_COMPILE = "COMPILE_FAIL"
FAIL_ELAB = "ELAB_FAIL"
FAIL_SIM_SETUP = "SIM_SETUP_FAIL"
FAIL_SIM_RUN = "SIM_RUN_FAIL"
FAIL_TEST = "TEST_FAIL"
FAIL_COMPARE = "COMPARE_FAIL"
FAIL_ASSERT = "ASSERT_FAIL"
FAIL_TIMEOUT = "TIMEOUT_FAIL"
FAIL_TOOL = "TOOL_FAIL"
FAIL_ARTIFACT = "ARTIFACT_FAIL"
FAIL_UNKNOWN = "UNKNOWN_FAIL"

FAIL_STAGE_NAMES = [
    FAIL_COMPILE,
    FAIL_ELAB,
    FAIL_SIM_SETUP,
    FAIL_SIM_RUN,
    FAIL_TEST,
    FAIL_COMPARE,
    FAIL_ASSERT,
    FAIL_TIMEOUT,
    FAIL_TOOL,
    FAIL_ARTIFACT,
    FAIL_UNKNOWN,
]

RETRYABLE_INFRA_STAGES = set([FAIL_COMPILE, FAIL_ELAB, FAIL_SIM_SETUP, FAIL_TOOL])

WAVE_NOT_REQUESTED = "NOT_REQUESTED"
WAVE_GENERATED = "GENERATED"
WAVE_MISSING = "MISSING"
WAVE_EMPTY = "EMPTY"
WAVE_COPY_FAILED = "COPY_FAILED"


def active_lines(path):
    if not path.exists():
        raise FileNotFoundError("list file not found: {}".format(path))
    lines = []
    for raw in path.read_text(encoding="utf-8").splitlines():
        active = raw.split("#", 1)[0].strip()
        if active:
            lines.append(active)
    return lines


def read_registered_tests(loop_root):
    tc_list = loop_root / "new" / "tc" / "tc_list"
    tests = active_lines(tc_list)
    if not tests:
        raise RuntimeError("tc_list is empty: {}".format(tc_list))
    return tests


def parse_regress_list(path, valid_tests):
    entries = []
    for line in active_lines(path):
        fields = line.split()
        if len(fields) != 3:
            raise ValueError("invalid regress_list line '{}'; expected: testcase repeat wave".format(line))
        testcase, repeat_text, wave_text = fields
        if testcase not in valid_tests:
            raise ValueError("testcase '{}' is not registered in tc_list".format(testcase))
        repeat = int(repeat_text)
        wave = int(wave_text)
        if repeat < 1:
            raise ValueError("repeat must be positive: {}".format(line))
        if wave not in (0, 1):
            raise ValueError("wave must be 0 or 1: {}".format(line))
        entries.append((testcase, repeat, wave))
    if not entries:
        raise ValueError("regress_list contains no runnable entries: {}".format(path))
    return entries


def unique_seed(used):
    while True:
        value = random.randint(1, 999999)
        if value not in used:
            used.add(value)
            return "{:06d}".format(value)


def build_jobs(args, valid_tests):
    used = set()
    jobs = []

    if args.testcase:
        if args.testcase not in valid_tests:
            raise ValueError("testcase '{}' is not registered in tc_list".format(args.testcase))
        if args.seed and args.repeat != 1:
            raise ValueError("--seed can only be used with --repeat 1")
        first_seed = args.seed or unique_seed(used)
        jobs.append(Job(1, args.testcase, 1, args.repeat, first_seed, args.wave, 1))
        for iteration in range(2, args.repeat + 1):
            jobs.append(Job(iteration, args.testcase, iteration, args.repeat, unique_seed(used), args.wave, 1))
        return jobs

    entries = parse_regress_list(args.regress_list, valid_tests)
    index = 1
    for testcase, repeat, wave in entries:
        for iteration in range(1, repeat + 1):
            jobs.append(Job(index, testcase, iteration, repeat, unique_seed(used), wave, 1))
            index += 1
    return jobs


def make_run_id():
    now = _dt.datetime.now()
    return now.strftime("%Y%m%d_%H%M%S_%f")[:-3] + "_{}".format(os.getpid())


def work_project_path(project_xpr, work_run_root, job):
    job_dir = "j{:03d}_{}_a{}".format(job.index, job.seed, job.attempt)
    return work_run_root / job_dir / project_xpr.parent.name / project_xpr.name


def log_stem_for_job(job):
    return "{}_{}_a{}".format(job.testcase, job.seed, job.attempt)


def selected_vcd_path_for(run_dir, job):
    return run_dir / "{}_selected.vcd".format(log_stem_for_job(job))


def wavedrom_json_path_for(run_dir, job):
    return run_dir / "{}_wavedrom.json".format(log_stem_for_job(job))


def wavedrom_svg_path_for(run_dir, job):
    return run_dir / "{}_wavedrom.svg".format(log_stem_for_job(job))


def wave_summary_path_for(run_dir, job):
    return run_dir / "{}_wave_summary.md".format(log_stem_for_job(job))


def hierarchy_path_for(run_dir, job):
    return run_dir / "{}_hierarchy.txt".format(log_stem_for_job(job))


def signal_check_path_for(run_dir, job):
    return run_dir / "{}_signal_check.txt".format(log_stem_for_job(job))


def has_waveform_request(args):
    return args.vcd_mode == "selected" or args.dump_hierarchy or args.gen_wavedrom


def parse_time_ns(value, default_unit="ns"):
    if value is None:
        return None
    text = str(value).strip()
    if not text:
        return None
    match = re.match(r"^([0-9]+)([a-zA-Z]*)$", text.replace(" ", ""))
    if not match:
        raise ValueError("invalid time value: {}".format(value))
    number = int(match.group(1))
    unit = (match.group(2) or default_unit).lower()
    factors = {
        "fs": 0.000001,
        "ps": 0.001,
        "ns": 1.0,
        "us": 1000.0,
        "ms": 1000000.0,
        "s": 1000000000.0,
    }
    if unit not in factors:
        raise ValueError("unsupported time unit in {}: {}".format(value, unit))
    return int(round(number * factors[unit]))


def format_time_ns(value):
    return "{}ns".format(max(0, int(value)))


def find_anchor_window(sim_log, anchor, pre, post):
    text = read_text_if_exists(sim_log)
    if not anchor:
        return None, None, None
    pre_ns = parse_time_ns(pre or "0ns")
    post_ns = parse_time_ns(post or "0ns")
    for line in text.splitlines():
        if anchor not in line:
            continue
        match = re.search(r"(?:\[TIME=|time=)([0-9]+)([a-zA-Z]*)", line)
        if not match:
            continue
        anchor_ns = parse_time_ns(match.group(1) + (match.group(2) or "ns"))
        return anchor_ns, format_time_ns(anchor_ns - pre_ns), format_time_ns(anchor_ns + post_ns)
    raise RuntimeError("anchor '{}' with TIME/time field not found in {}".format(anchor, sim_log))


def vcd_timescale_multiplier_to_ns(unit_text):
    text = unit_text.strip().lower()
    match = re.match(r"^([0-9]+)\s*([a-z]+)$", text)
    if not match:
        return 1.0
    number = int(match.group(1))
    unit = match.group(2)
    factors = {
        "fs": 0.000001,
        "ps": 0.001,
        "ns": 1.0,
        "us": 1000.0,
        "ms": 1000000.0,
        "s": 1000000000.0,
    }
    return number * factors.get(unit, 1.0)


def read_vcd(vcd_path):
    scopes = []
    symbols = {}
    times = []
    changes = {}
    current_time = 0
    in_header = True
    timescale_ns = 1.0

    for raw in vcd_path.read_text(encoding="utf-8", errors="ignore").splitlines():
        line = raw.strip()
        if not line:
            continue
        if line.startswith("$timescale"):
            value = line.replace("$timescale", "").replace("$end", "").strip()
            timescale_ns = vcd_timescale_multiplier_to_ns(value)
            continue
        if line.startswith("$scope"):
            parts = line.split()
            if len(parts) >= 3:
                scopes.append(parts[2])
            continue
        if line.startswith("$upscope"):
            if scopes:
                scopes.pop()
            continue
        if line.startswith("$var"):
            parts = line.split()
            if len(parts) >= 5:
                width = int(parts[2])
                symbol = parts[3]
                name = parts[4]
                full_path = "/" + "/".join(scopes + [name])
                symbols[symbol] = {"name": name, "path": full_path, "width": width}
                changes[symbol] = []
            continue
        if line.startswith("$enddefinitions"):
            in_header = False
            continue
        if in_header:
            continue
        if line.startswith("#"):
            try:
                current_time = int(round(int(line[1:]) * timescale_ns))
            except ValueError:
                current_time = 0
            times.append(current_time)
            continue
        if line[0] in "01xXzZ" and len(line) > 1:
            symbol = line[1:]
            value = line[0].lower()
            if symbol in changes:
                changes[symbol].append((current_time, value))
            continue
        if line[0] in "bBrR":
            parts = line.split()
            if len(parts) >= 2:
                value = parts[0][1:].lower()
                symbol = parts[1]
                if symbol in changes:
                    changes[symbol].append((current_time, value))
            continue

    return symbols, changes


def short_signal_name(path):
    text = str(path).strip()
    if not text:
        return text
    leaf = text.rstrip("/").split("/")[-1]
    return leaf or text


def signal_aliases_from_file(path):
    aliases = {}
    if not path or not path.exists():
        return aliases
    for raw in path.read_text(encoding="utf-8", errors="ignore").splitlines():
        active = raw.split("#", 1)[0].strip()
        if not active or "*" in active or active.startswith("-recursive"):
            continue
        aliases[active] = short_signal_name(active)
    return aliases


def value_at(changes, time_point, default="x"):
    value = default
    for change_time, change_value in changes:
        if change_time > time_point:
            break
        value = change_value
    return value


def build_wavedrom_from_vcd(vcd_path, signal_file, out_json, out_svg, out_summary, title, anchor_text=None):
    symbols, changes = read_vcd(vcd_path)
    if not symbols:
        raise RuntimeError("VCD contains no signals: {}".format(vcd_path))

    aliases = signal_aliases_from_file(signal_file)
    ordered_symbols = []
    for symbol, meta in sorted(symbols.items(), key=lambda item: item[1]["path"]):
        ordered_symbols.append((symbol, meta))
    if len(ordered_symbols) > 24:
        ordered_symbols = ordered_symbols[:24]

    all_times = sorted(set(t for symbol, _meta in ordered_symbols for t, _value in changes.get(symbol, [])))
    if not all_times:
        all_times = [0]
    if len(all_times) > 160:
        step = max(1, len(all_times) // 160)
        all_times = all_times[::step]

    signal_entries = []
    summary_lines = [
        "# {}".format(title),
        "",
        "- VCD: `{}`".format(vcd_path),
    ]
    if anchor_text:
        summary_lines.append("- Anchor: `{}`".format(anchor_text))
    summary_lines.append("- Signals rendered: {}".format(len(ordered_symbols)))
    summary_lines.append("")

    for symbol, meta in ordered_symbols:
        path = meta["path"]
        name = aliases.get(path, short_signal_name(path))
        width = meta["width"]
        seq = [value_at(changes.get(symbol, []), t) for t in all_times]
        if width <= 1:
            wave = ""
            previous = None
            for value in seq:
                value = value if value in ("0", "1") else "x"
                wave += value if value != previous else "."
                previous = value
            signal_entries.append({"name": name, "wave": wave})
        else:
            wave = ""
            data = []
            previous = None
            for value in seq:
                if value != previous:
                    wave += "="
                    try:
                        data.append(hex(int(value.replace("x", "0").replace("z", "0"), 2)))
                    except ValueError:
                        data.append(value)
                else:
                    wave += "."
                previous = value
            signal_entries.append({"name": name, "wave": wave, "data": data})
        summary_lines.append("- `{}` from `{}`".format(name, path))

    payload = {
        "head": {"text": title},
        "signal": signal_entries,
    }
    out_json.write_text(json.dumps(payload, indent=2, sort_keys=False) + "\n", encoding="utf-8")
    write_simple_wave_svg(out_svg, title, signal_entries)
    out_summary.write_text("\n".join(summary_lines) + "\n", encoding="utf-8")


def write_simple_wave_svg(path, title, signal_entries):
    row_h = 28
    name_w = 220
    cell_w = 10
    max_wave = max([len(item.get("wave", "")) for item in signal_entries] + [1])
    width = name_w + max_wave * cell_w + 40
    height = 48 + len(signal_entries) * row_h
    lines = [
        '<svg xmlns="http://www.w3.org/2000/svg" width="{0}" height="{1}" viewBox="0 0 {0} {1}">'.format(width, height),
        '<rect width="100%" height="100%" fill="#ffffff"/>',
        '<text x="16" y="26" font-family="Arial, sans-serif" font-size="16" font-weight="700">{}</text>'.format(escape_xml(title)),
    ]
    y = 52
    for entry in signal_entries:
        name = escape_xml(entry.get("name", "sig"))
        wave = entry.get("wave", "")
        lines.append('<text x="16" y="{}" font-family="Consolas, monospace" font-size="12">{}</text>'.format(y, name))
        x = name_w
        last_y = None
        for char in wave:
            if char == "." and last_y is not None:
                level_y = last_y
            elif char == "1":
                level_y = y - 12
            elif char == "0":
                level_y = y + 2
            elif char == "=":
                level_y = y - 5
            else:
                level_y = y - 5
            if last_y is not None and level_y != last_y:
                lines.append('<line x1="{0}" y1="{1}" x2="{0}" y2="{2}" stroke="#777"/>'.format(x, last_y, level_y))
            lines.append('<line x1="{0}" y1="{1}" x2="{2}" y2="{1}" stroke="#0f766e" stroke-width="2"/>'.format(x, level_y, x + cell_w, level_y))
            if char == "=":
                lines.append('<circle cx="{}" cy="{}" r="2" fill="#0f766e"/>'.format(x + 2, level_y))
            last_y = level_y
            x += cell_w
        y += row_h
    lines.append("</svg>")
    path.write_text("\n".join(lines) + "\n", encoding="utf-8")


def escape_xml(value):
    return str(value).replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;").replace('"', "&quot;")


def path_length_hint(exc, work_root):
    text = str(exc)
    lower = text.lower()
    if "winerror 206" in text.lower() or "filename or extension is too long" in lower or "file name is too long" in lower:
        return (
            text
            + "\n\nPATH_LENGTH_HINT: Windows path is too long. Use a shorter work root, for example:\n"
            + "  --work-root C:\\vrw\n"
            + "Current work root: {}\n".format(work_root)
        )
    return text


def copy_project_for_job(project_xpr, loop_root, work_run_root, job):
    project_root = project_xpr.parent
    dst_root = work_project_path(project_xpr, work_run_root, job).parent
    dst_root.parent.mkdir(parents=True, exist_ok=True)

    project_stem = project_xpr.stem
    keep_names = [
        project_xpr.name,
        "tb_simple_behav.wcfg",
        "{}.srcs".format(project_stem),
        "{}.gen".format(project_stem),
        "{}.ip_user_files".format(project_stem),
        "{}.cache".format(project_stem),
    ]
    ignore = shutil.ignore_patterns("logs", "*.jou", "*.log", "*.backup.*", "*.rar", ".Xil")
    dst_root.mkdir(parents=True, exist_ok=True)
    for name in keep_names:
        src = project_root / name
        dst = dst_root / name
        if not src.exists():
            continue
        if src.is_dir():
            if dst.exists():
                shutil.rmtree(str(dst))
            shutil.copytree(str(src), str(dst), ignore=ignore)
        else:
            shutil.copy2(str(src), str(dst))

    dst_xpr = dst_root / project_xpr.name
    if not dst_xpr.exists():
        raise FileNotFoundError("copied project xpr not found: {}".format(dst_xpr))

    old_root_fwd = project_root.as_posix()
    new_root_fwd = dst_root.as_posix()
    text = dst_xpr.read_text(encoding="utf-8", errors="ignore")
    text = text.replace(old_root_fwd, new_root_fwd)
    text = text.replace(str(project_root), str(dst_root))
    dst_xpr.write_text(text, encoding="utf-8")

    rel_loop = loop_root.relative_to(project_root)
    return dst_xpr, dst_root / rel_loop


def read_text_if_exists(path):
    if path and path.exists():
        return path.read_text(encoding="utf-8", errors="ignore")
    return ""


def contains_any(text, patterns):
    return any(pattern in text for pattern in patterns)


def final_status_for(result):
    if result.run_status == RUN_PASS:
        return RUN_PASS
    if result.run_status == RUN_ARTIFACT_FAIL:
        return FAIL_ARTIFACT
    return result.fail_stage or FAIL_UNKNOWN


def fail_kind_for_stage(stage):
    if not stage or stage == FAIL_NONE:
        return "PASS"
    if stage.endswith("_FAIL"):
        return stage[:-5]
    return stage


def fail_kind_for_result(result):
    return fail_kind_for_stage(final_status_for(result))


def is_retryable_infra(result):
    return result.run_status == RUN_FAIL and result.fail_stage in RETRYABLE_INFRA_STAGES


def safe_filename(text):
    cleaned = []
    for char in str(text):
        if char.isalnum() or char in "._-":
            cleaned.append(char)
        else:
            cleaned.append("_")
    value = "".join(cleaned).strip("._")
    return value[:160] if value else "log"


def should_copy_generated_log(path):
    name = path.name.lower()
    important_names = set([
        "vivado.log",
        "vivado.jou",
        "xvlog.log",
        "xelab.log",
        "xsim.log",
        "compile.log",
        "elaborate.log",
        "simulate.log",
    ])
    if name in important_names:
        return True
    if path.suffix.lower() not in (".log", ".jou"):
        return False
    parts = [part.lower() for part in path.parts]
    return "xsim" in parts or "sim_1" in parts or "behav" in parts


def copy_generated_logs(work_xpr, run_dir, job):
    if not work_xpr or not work_xpr.parent.exists():
        return None

    project_root = work_xpr.parent
    search_roots = [project_root, project_root / "{}.sim".format(work_xpr.stem)]
    dest_dir = run_dir / "vivado_logs" / log_stem_for_job(job)
    copied = 0
    seen = set()

    for root in search_roots:
        if not root.exists():
            continue
        for pattern in ("*.log", "*.jou"):
            for path in root.rglob(pattern):
                try:
                    resolved = str(path.resolve())
                except OSError:
                    resolved = str(path)
                if resolved in seen or not should_copy_generated_log(path):
                    continue
                seen.add(resolved)
                try:
                    rel = path.relative_to(project_root)
                except ValueError:
                    rel = path.name
                dest_dir.mkdir(parents=True, exist_ok=True)
                shutil.copy2(str(path), str(dest_dir / safe_filename(rel)))
                copied += 1

    return dest_dir if copied else None


def clip_text(value, width):
    text = safe_field(value)
    if len(text) <= width:
        return text
    if width <= 3:
        return text[:width]
    return text[: width - 3] + "..."


def format_kv_pairs(pairs):
    key_width = max(len(safe_field(key)) for key, _value in pairs)
    return ["{} : {}".format(safe_field(key).ljust(key_width), safe_field(value)) for key, value in pairs]


def format_table(headers, rows, max_widths=None, right_align=None):
    max_widths = max_widths or {}
    right_align = set(right_align or [])
    text_rows = [[safe_field(item) for item in row] for row in rows]
    widths = []
    for index, header in enumerate(headers):
        width = len(header)
        for row in text_rows:
            if index < len(row):
                width = max(width, len(row[index]))
        width = min(width, max_widths.get(header, width))
        widths.append(width)

    def fmt(row):
        clipped = []
        for index, value in enumerate(row):
            text = clip_text(value, widths[index])
            if headers[index] in right_align:
                clipped.append(text.rjust(widths[index]))
            else:
                clipped.append(text.ljust(widths[index]))
        return " | ".join(clipped)

    lines = [fmt(headers), "-+-".join("-" * width for width in widths)]
    for row in text_rows:
        padded = row + [""] * (len(headers) - len(row))
        lines.append(fmt(padded))
    return lines


def display_run_path(path, run_dir):
    if not path:
        return "-"
    path = Path(path)
    try:
        return str(path.relative_to(run_dir))
    except ValueError:
        return str(path)


def display_path_from(path, root):
    if not path:
        return "-"
    path = Path(path)
    try:
        return str(path.relative_to(root))
    except ValueError:
        return str(path)


def first_matching_line(paths):
    patterns = [
        "ERROR:",
        "Error:",
        "CRITICAL WARNING:",
        "TEST_FAIL",
        "[COMPARE]",
        "first mismatch",
        "mismatch",
        "ASSERT",
        "assert",
        "TB_TIMEOUT",
        "Simulation timeout",
        "UVM_ERROR",
        "UVM_FATAL",
        "WAVE_RESULT=FAIL",
        "WAVE_MISSING",
        "WAVE_COPY_FAILED",
        "SELECTED_VCD_RESULT=FAIL",
        "selected VCD missing",
        "WaveDrom generation failed",
        "Failed to open file to read",
        "can not find channel named",
        "called Tcl_Close",
        "simulation command failed",
        "simulation log was not generated",
    ]
    for path in paths:
        if not path or not path.exists():
            continue
        try:
            for line in path.read_text(encoding="utf-8", errors="ignore").splitlines():
                for pattern in patterns:
                    if pattern in line:
                        return " ".join(line.strip().split())
        except OSError as exc:
            return "log_read_error: {}".format(exc)
    return "-"


def classify_fail_stage(first_error, stdout_text, stderr_text, sim_text, returncode):
    text = " ".join([first_error, stdout_text[-4000:], stderr_text[-4000:], sim_text[-4000:]]).lower()
    if "xvlog" in text or "xvlog.log" in text or "compile step" in text or "[vrfc" in text:
        return FAIL_COMPILE
    if "xelab" in text or "elaborat" in text:
        return FAIL_ELAB
    if "xsim.ini" in text and "failed to open file to read" in text:
        return FAIL_SIM_SETUP
    if "launch_simulation" in text or "sim_work_dir" in text or "failed to open file to read" in text:
        return FAIL_SIM_SETUP
    if contains_any(text, ["tb_timeout", "simulation timeout", " timeout"]):
        return FAIL_TIMEOUT
    if contains_any(text, ["uvm_error", "uvm_fatal", "assertion", "assert failed", "assert_fail"]):
        return FAIL_ASSERT
    if contains_any(text, ["[compare]", "first mismatch", "mismatch", "compare mismatch"]):
        return FAIL_COMPARE
    if "test_fail" in text:
        return FAIL_TEST
    if "simulation log was not generated" in text:
        return FAIL_SIM_SETUP
    if "simulation command failed" in text or "run all" in text:
        return FAIL_SIM_RUN
    if returncode != 0:
        return FAIL_TOOL
    return FAIL_UNKNOWN


def wave_status_for(job, wdb_path, stdout_text):
    if job.wave == 0:
        return WAVE_NOT_REQUESTED, None, 0
    if wdb_path.exists():
        if not wdb_path.is_file():
            return WAVE_MISSING, None, 0
        size = wdb_path.stat().st_size
        if size > 0:
            return WAVE_GENERATED, wdb_path, size
        return WAVE_EMPTY, wdb_path, 0
    if "WAVE_COPY_FAILED" in stdout_text or "WAVE_STATUS=COPY_FAILED" in stdout_text:
        return WAVE_COPY_FAILED, None, 0
    return WAVE_MISSING, None, 0


def make_result(job, run_status, test_status, fail_stage, first_error, wave_status, wdb_size,
                elapsed, sim_log, wdb, stdout_log, stderr_log, returncode,
                work_xpr, work_loop, work_retained, extra_log_dir,
                selected_vcd=None, wavedrom_json=None, wavedrom_svg=None, wave_summary=None):
    return Result(
        job,
        run_status,
        test_status,
        fail_stage,
        first_error,
        wave_status,
        wdb_size,
        elapsed,
        sim_log,
        wdb,
        stdout_log,
        stderr_log,
        returncode,
        work_xpr,
        work_loop,
        work_retained,
        extra_log_dir,
        selected_vcd,
        wavedrom_json,
        wavedrom_svg,
        wave_summary,
    )


def run_vivado_tcl(args, script_dir, tc, seed, wave, verbose, run_dir, work_xpr, work_loop,
                   output_stem, stdout_log, stderr_log, vcd_mode=None, vcd_start=None, vcd_stop=None):
    tcl_script = script_dir / "run_regression.tcl"
    actual_vcd_mode = vcd_mode if vcd_mode is not None else args.vcd_mode
    cmd = [
        args.vivado,
        "-mode",
        "batch",
        "-notrace",
        "-source",
        str(tcl_script),
        "-tclargs",
        tc,
        seed,
        str(wave),
        str(verbose),
        str(run_dir),
        str(work_xpr),
        str(work_loop),
        output_stem,
        actual_vcd_mode,
        str(args.vcd_signals or ""),
        vcd_start if vcd_start is not None else (args.vcd_start or ""),
        vcd_stop if vcd_stop is not None else (args.vcd_stop or ""),
        "1" if args.dump_hierarchy or actual_vcd_mode == "selected" else "0",
    ]
    with stdout_log.open("w", encoding="utf-8", errors="replace") as stdout_f, stderr_log.open(
        "w", encoding="utf-8", errors="replace"
    ) as stderr_f:
        stdout_f.write("TCL_SCRIPT={}\n".format(tcl_script))
        process = subprocess.run(
            cmd,
            cwd=str(work_xpr.parent),
            stdout=stdout_f,
            stderr=stderr_f,
            universal_newlines=True,
        )
    return process.returncode


def run_one_job(job, args, script_dir, project_xpr, loop_root, run_dir, work_run_root):
    tc = job.testcase
    seed = job.seed
    log_stem = log_stem_for_job(job)
    stdout_log = run_dir / "{}_vivado.log".format(log_stem)
    stderr_log = run_dir / "{}_vivado.err.log".format(log_stem)
    sim_log = run_dir / "{}_simulate.log".format(log_stem)
    wdb_path = run_dir / "{}_behav.wdb".format(log_stem)
    selected_vcd_path = selected_vcd_path_for(run_dir, job)
    wavedrom_json = wavedrom_json_path_for(run_dir, job)
    wavedrom_svg = wavedrom_svg_path_for(run_dir, job)
    wave_summary = wave_summary_path_for(run_dir, job)
    work_xpr = project_xpr
    work_loop = loop_root
    work_job_root = None
    extra_log_dir = None

    start = time.perf_counter()
    try:
        if args.shared_project:
            work_xpr = project_xpr
            work_loop = loop_root
        else:
            work_xpr, work_loop = copy_project_for_job(project_xpr, loop_root, work_run_root, job)
            work_job_root = work_xpr.parent.parent

        vcd_start = args.vcd_start
        vcd_stop = args.vcd_stop
        if args.vcd_anchor:
            anchor_stem = "{}_anchor".format(log_stem)
            anchor_stdout = run_dir / "{}_vivado.log".format(anchor_stem)
            anchor_stderr = run_dir / "{}_vivado.err.log".format(anchor_stem)
            anchor_sim_log = run_dir / "{}_simulate.log".format(anchor_stem)
            anchor_returncode = run_vivado_tcl(
                args, script_dir, tc, seed, 0, args.verbose, run_dir,
                work_xpr, work_loop, anchor_stem, anchor_stdout, anchor_stderr,
                vcd_mode="none", vcd_start="", vcd_stop=""
            )
            if anchor_returncode != 0:
                stdout_log = anchor_stdout
                stderr_log = anchor_stderr
                sim_log = anchor_sim_log
                returncode = anchor_returncode
            else:
                _anchor_ns, vcd_start, vcd_stop = find_anchor_window(
                    anchor_sim_log, args.vcd_anchor, args.vcd_pre, args.vcd_post
                )
                returncode = run_vivado_tcl(
                    args, script_dir, tc, seed, job.wave, args.verbose, run_dir,
                    work_xpr, work_loop, log_stem, stdout_log, stderr_log,
                    vcd_start=vcd_start, vcd_stop=vcd_stop
                )
        else:
            returncode = run_vivado_tcl(
                args, script_dir, tc, seed, job.wave, args.verbose, run_dir,
                work_xpr, work_loop, log_stem, stdout_log, stderr_log,
                vcd_start=vcd_start, vcd_stop=vcd_stop
            )
    except Exception as exc:
        elapsed = time.perf_counter() - start
        stderr_log.write_text(path_length_hint(exc, args.work_root) + "\n", encoding="utf-8")
        first_error = first_matching_line([stderr_log, stdout_log, sim_log])
        if not args.shared_project and work_job_root is not None:
            extra_log_dir = copy_generated_logs(work_xpr, run_dir, job)
        work_retained = str(work_job_root) if work_job_root and work_job_root.exists() else "-"
        return make_result(
            job, RUN_FAIL, TEST_UNKNOWN, FAIL_TOOL, first_error, WAVE_MISSING if job.wave else WAVE_NOT_REQUESTED,
            0, elapsed, sim_log, None, stdout_log, stderr_log, -1, work_xpr, work_loop, work_retained,
            extra_log_dir, selected_vcd_path if selected_vcd_path.exists() else None,
            wavedrom_json if wavedrom_json.exists() else None,
            wavedrom_svg if wavedrom_svg.exists() else None,
            wave_summary if wave_summary.exists() else None
        )

    elapsed = time.perf_counter() - start
    stdout_text = read_text_if_exists(stdout_log)
    stderr_text = read_text_if_exists(stderr_log)
    sim_text = read_text_if_exists(sim_log)

    functional_pass = (
        "REGRESSION_PASS testcase={}".format(tc) in stdout_text
        or "TEST_PASS: {}".format(tc) in stdout_text
        or "TEST_PASS: {}".format(tc) in sim_text
    )
    test_status = TEST_PASS if functional_pass else TEST_FAIL
    wave_status, wdb, wdb_size = wave_status_for(job, wdb_path, stdout_text)
    wave_ok = job.wave == 0 or wave_status == WAVE_GENERATED
    waveform_error = None
    selected_vcd = selected_vcd_path if selected_vcd_path.exists() else None
    generated_json = wavedrom_json if wavedrom_json.exists() else None
    generated_svg = wavedrom_svg if wavedrom_svg.exists() else None
    generated_summary = wave_summary if wave_summary.exists() else None

    if args.vcd_mode == "selected":
        if not selected_vcd or selected_vcd.stat().st_size <= 0:
            waveform_error = "selected VCD missing or empty expected {}".format(selected_vcd_path)
        elif args.gen_wavedrom and functional_pass:
            try:
                build_wavedrom_from_vcd(
                    selected_vcd_path,
                    args.vcd_signals,
                    wavedrom_json,
                    wavedrom_svg,
                    wave_summary,
                    "{} seed={} attempt={}".format(tc, seed, job.attempt),
                    args.vcd_anchor,
                )
                generated_json = wavedrom_json
                generated_svg = wavedrom_svg
                generated_summary = wave_summary
            except Exception as exc:
                waveform_error = "WaveDrom generation failed: {}".format(exc)
    elif args.gen_wavedrom:
        waveform_error = "--gen-wavedrom requires --vcd-mode selected"

    if functional_pass and wave_ok and not waveform_error:
        run_status = RUN_PASS
        fail_stage = FAIL_NONE
    elif functional_pass and (not wave_ok or waveform_error):
        run_status = RUN_ARTIFACT_FAIL
        fail_stage = FAIL_ARTIFACT
    else:
        run_status = RUN_FAIL
        first_for_stage = first_matching_line([stderr_log, stdout_log, sim_log])
        fail_stage = classify_fail_stage(first_for_stage, stdout_text, stderr_text, sim_text, returncode)

    first_error = first_matching_line([stderr_log, stdout_log, sim_log])
    if first_error == "-" and run_status == RUN_ARTIFACT_FAIL:
        if waveform_error:
            first_error = waveform_error
        else:
            first_error = "wave artifact {} expected {}".format(wave_status, wdb_path)

    if not args.shared_project:
        extra_log_dir = copy_generated_logs(work_xpr, run_dir, job)

    delete_work = (
        not args.shared_project
        and not args.keep_work
        and run_status == RUN_PASS
        and work_job_root is not None
    )
    if delete_work:
        try:
            shutil.rmtree(str(work_job_root))
        except OSError:
            pass

    if (not args.shared_project) and work_job_root is not None and work_job_root.exists():
        work_retained = str(work_job_root)
    elif args.keep_work and work_job_root is not None:
        work_retained = str(work_job_root)
    else:
        work_retained = "-"

    return make_result(
        job, run_status, test_status, fail_stage, first_error, wave_status, wdb_size,
        elapsed, sim_log, wdb, stdout_log, stderr_log, returncode, work_xpr, work_loop, work_retained,
        extra_log_dir, selected_vcd, generated_json, generated_svg, generated_summary
    )


def safe_field(value):
    text = str(value) if value is not None else "-"
    return " ".join(text.split())


def write_reports(results, all_attempts, run_dir, args):
    regress_log = run_dir / "regress_log.log"
    regress_tsv = run_dir / "regress_log.tsv"
    regress_rpt = run_dir / "regress_rpt.log"
    failed_replay = run_dir / "failed_replay.ps1"
    failed_regress_list = run_dir / "failed_regress_list"

    attempts_by_index = {}
    for result in all_attempts:
        attempts_by_index.setdefault(result.job.index, []).append(result)
    for values in attempts_by_index.values():
        values.sort(key=lambda item: item.job.attempt)
    max_attempt_by_index = dict((index, values[-1].job.attempt) for index, values in attempts_by_index.items())
    max_attempts = args.retry_infra + 1

    human_header = [
        "STATUS", "KIND", "TEST", "TC", "ITER", "SEED", "ATT", "W", "WAVE_ST",
        "SEC", "FIRST_ERROR", "LOG",
    ]
    human_rows = []
    for result in sorted(all_attempts, key=lambda item: (item.job.index, item.job.attempt)):
        human_rows.append([
            final_status_for(result),
            fail_kind_for_result(result),
            result.test_status,
            result.job.testcase,
            result.job.iteration,
            result.job.seed,
            "{}/{}".format(result.job.attempt, max_attempts),
            result.job.wave,
            result.wave_status,
            "{:.3f}".format(result.elapsed),
            result.first_error,
            result.stdout_log.name,
        ])
    log_lines = format_table(
        human_header,
        human_rows,
        {
            "STATUS": 16,
            "KIND": 10,
            "TC": 26,
            "WAVE_ST": 13,
            "FIRST_ERROR": 80,
            "LOG": 36,
        },
        right_align={"ITER", "SEED", "ATT", "W", "SEC"},
    )
    regress_log.write_text("\n".join(log_lines) + "\n", encoding="utf-8")

    tsv_header = [
        "FINAL_STATUS", "RUN_STATUS", "TEST_STATUS", "FAIL_KIND", "FAIL_STAGE",
        "TESTCASE", "ITERATION", "REPEAT", "SEED", "WAVE", "ATTEMPT",
        "MAX_ATTEMPTS", "RETRIED", "WAVE_STATUS", "WDB_SIZE", "ELAPSED_S",
        "RETURN_CODE", "FIRST_ERROR", "SIM_LOG", "WDB", "SELECTED_VCD",
        "WAVEDROM_JSON", "WAVEDROM_SVG", "WAVE_SUMMARY", "STDOUT", "STDERR",
        "EXTRA_LOG_DIR", "WORK_PROJECT", "WORK_LOOP_ROOT", "WORK_RETAINED",
    ]
    tsv_lines = ["\t".join(tsv_header)]
    for result in sorted(all_attempts, key=lambda item: (item.job.index, item.job.attempt)):
        retried = "YES" if max_attempt_by_index.get(result.job.index, 1) > 1 else "NO"
        row = [
            final_status_for(result),
            result.run_status,
            result.test_status,
            fail_kind_for_result(result),
            result.fail_stage,
            result.job.testcase,
            result.job.iteration,
            result.job.repeat,
            result.job.seed,
            result.job.wave,
            result.job.attempt,
            max_attempts,
            retried,
            result.wave_status,
            result.wdb_size,
            "{:.3f}".format(result.elapsed),
            result.returncode,
            result.first_error,
            result.sim_log,
            result.wdb if result.wdb else "-",
            result.selected_vcd if result.selected_vcd else "-",
            result.wavedrom_json if result.wavedrom_json else "-",
            result.wavedrom_svg if result.wavedrom_svg else "-",
            result.wave_summary if result.wave_summary else "-",
            result.stdout_log,
            result.stderr_log,
            result.extra_log_dir if result.extra_log_dir else "-",
            result.work_project_xpr,
            result.work_loop_root,
            result.work_retained,
        ]
        tsv_lines.append("\t".join(safe_field(item) for item in row))
    regress_tsv.write_text("\n".join(tsv_lines) + "\n", encoding="utf-8")

    total = len(results)
    run_pass = sum(1 for item in results if item.run_status == RUN_PASS)
    final_fail = total - run_pass
    wave_requested = sum(1 for item in results if item.job.wave == 1)
    wave_generated = sum(1 for item in results if item.wave_status == WAVE_GENERATED)
    wave_missing = sum(1 for item in results if item.wave_status == WAVE_MISSING)
    wave_empty = sum(1 for item in results if item.wave_status == WAVE_EMPTY)
    wave_copy_failed = sum(1 for item in results if item.wave_status == WAVE_COPY_FAILED)
    selected_vcd_generated = sum(1 for item in results if item.selected_vcd)
    wavedrom_generated = sum(1 for item in results if item.wavedrom_json and item.wavedrom_svg)
    retried_final = [item for item in results if max_attempt_by_index.get(item.job.index, 1) > 1]
    retry_pass = sum(1 for item in retried_final if item.run_status == RUN_PASS)
    retry_fail = len(retried_final) - retry_pass

    rpt_lines = format_kv_pairs([
        ("REGRESSION_TIME", _dt.datetime.now().strftime("%Y%m%d_%H%M%S")),
        ("RUN_DIR", run_dir),
        ("WORK_ROOT", args.work_root),
        ("VERBOSE", args.verbose),
        ("MAX_PARALLEL", args.max_parallel),
        ("RETRY_INFRA", args.retry_infra),
        ("SHARED_PROJECT", args.shared_project),
    ])
    rpt_lines += ["", "OVERALL"]
    overall_rows = [
        ["TOTAL", total],
        ["PASS", run_pass],
        ["FINAL_FAIL", final_fail],
        ["RETRIED_JOBS", len(retried_final)],
        ["RETRY_PASS", retry_pass],
        ["RETRY_FAIL", retry_fail],
        ["WAVE_REQUESTED", wave_requested],
        ["WAVE_GENERATED", wave_generated],
        ["WAVE_MISSING", wave_missing],
        ["WAVE_EMPTY", wave_empty],
        ["WAVE_COPY_FAILED", wave_copy_failed],
        ["SELECTED_VCD_GENERATED", selected_vcd_generated],
        ["WAVEDROM_GENERATED", wavedrom_generated],
    ]
    for stage in FAIL_STAGE_NAMES:
        overall_rows.append([stage, sum(1 for item in results if final_status_for(item) == stage)])
    rpt_lines += format_table(["ITEM", "COUNT"], overall_rows, right_align={"COUNT"})

    rpt_lines += ["", "BY_TESTCASE"]
    by_tc = {}
    for result in results:
        by_tc.setdefault(result.job.testcase, []).append(result)
    tc_header = [
        "TESTCASE", "TOTAL", "PASS", "FAIL", "COMPILE", "ELAB", "SIM_SETUP",
        "SIM_RUN", "TEST", "COMPARE", "ASSERT", "TIMEOUT", "TOOL", "ARTIFACT",
        "RETRIED", "RETRY_PASS",
    ]
    stage_columns = [
        ("COMPILE", FAIL_COMPILE),
        ("ELAB", FAIL_ELAB),
        ("SIM_SETUP", FAIL_SIM_SETUP),
        ("SIM_RUN", FAIL_SIM_RUN),
        ("TEST", FAIL_TEST),
        ("COMPARE", FAIL_COMPARE),
        ("ASSERT", FAIL_ASSERT),
        ("TIMEOUT", FAIL_TIMEOUT),
        ("TOOL", FAIL_TOOL),
        ("ARTIFACT", FAIL_ARTIFACT),
    ]
    tc_rows = []
    for testcase in sorted(by_tc):
        group = by_tc[testcase]
        pass_count = sum(1 for item in group if item.run_status == RUN_PASS)
        retried_count = sum(1 for item in group if max_attempt_by_index.get(item.job.index, 1) > 1)
        retry_pass_count = sum(
            1 for item in group
            if max_attempt_by_index.get(item.job.index, 1) > 1 and item.run_status == RUN_PASS
        )
        row = [testcase, len(group), pass_count, len(group) - pass_count]
        for _name, stage in stage_columns:
            row.append(sum(1 for item in group if final_status_for(item) == stage))
        row += [retried_count, retry_pass_count]
        tc_rows.append(row)
    rpt_lines += format_table(
        tc_header,
        tc_rows,
        {"TESTCASE": 28},
        right_align=set(tc_header) - set(["TESTCASE"]),
    )

    abnormal = [item for item in results if item.run_status != RUN_PASS]
    if abnormal:
        rpt_lines += ["", "ABNORMAL_JOBS"]
        abnormal_header = [
            "STATUS", "KIND", "TESTCASE", "SEED", "ATT", "WAVE", "FIRST_ERROR",
            "VIVADO_LOG", "EXTRA_LOGS", "WORK_RETAINED",
        ]
        abnormal_rows = []
        for item in abnormal:
            abnormal_rows.append([
                final_status_for(item),
                fail_kind_for_result(item),
                item.job.testcase,
                item.job.seed,
                "{}/{}".format(item.job.attempt, max_attempts),
                item.wave_status,
                item.first_error,
                item.stdout_log.name,
                display_run_path(item.extra_log_dir, run_dir) if item.extra_log_dir else "-",
                display_path_from(item.work_retained, args.work_root) if item.work_retained != "-" else "-",
            ])
        rpt_lines += format_table(
            abnormal_header,
            abnormal_rows,
            {
                "TESTCASE": 26,
                "FIRST_ERROR": 80,
                "VIVADO_LOG": 36,
                "EXTRA_LOGS": 38,
                "WORK_RETAINED": 52,
            },
            right_align={"SEED", "ATT"},
        )
        rpt_lines.append("Full paths are preserved in regress_log.tsv.")

    if retried_final:
        rpt_lines += ["", "RETRY_SUMMARY"]
        retry_header = ["TESTCASE", "SEED", "ATTEMPTS", "FINAL_STATUS", "HISTORY"]
        retry_rows = []
        for item in sorted(retried_final, key=lambda value: (value.job.index, value.job.seed)):
            history = " > ".join(
                "a{}:{}".format(attempt.job.attempt, final_status_for(attempt))
                for attempt in attempts_by_index[item.job.index]
            )
            retry_rows.append([
                item.job.testcase,
                item.job.seed,
                max_attempt_by_index[item.job.index],
                final_status_for(item),
                history,
            ])
        rpt_lines += format_table(
            retry_header,
            retry_rows,
            {"TESTCASE": 28, "FINAL_STATUS": 16, "HISTORY": 96},
            right_align={"SEED", "ATTEMPTS"},
        )

    rpt_lines += [
        "",
        "LEGEND",
        "{}: testcase passed, but requested output artifact such as WDB is missing, empty, or copy failed; this is not DUT data logic failure.".format(FAIL_ARTIFACT),
        "{}: launch_simulation/xsim.ini/simulation work directory setup failed before testcase logic ran.".format(FAIL_SIM_SETUP),
        "{}: testcase reached its own fail path but no narrower compare/assert/timeout marker was found.".format(FAIL_TEST),
        "regress_log.log is a shortened aligned view; regress_log.tsv keeps complete machine-readable fields and full paths, including selected VCD and WaveDrom outputs.",
    ]
    regress_rpt.write_text("\n".join(rpt_lines) + "\n", encoding="utf-8")

    replay_lines = [
        "# Failed or artifact-failed testcase replay commands.",
        "# Single-seed commands keep the original seed/wave/verbose and disable retry.",
        "",
    ]
    wave_replay_options = []
    if args.vcd_mode != "none":
        wave_replay_options += [
            "  --vcd-mode {} `".format(args.vcd_mode),
            "  --vcd-signals \"{}\" `".format(args.vcd_signals),
        ]
    if args.vcd_start:
        wave_replay_options.append("  --vcd-start {} `".format(args.vcd_start))
    if args.vcd_stop:
        wave_replay_options.append("  --vcd-stop {} `".format(args.vcd_stop))
    if args.vcd_anchor:
        wave_replay_options.append("  --vcd-anchor \"{}\" `".format(args.vcd_anchor))
    if args.vcd_pre:
        wave_replay_options.append("  --vcd-pre {} `".format(args.vcd_pre))
    if args.vcd_post:
        wave_replay_options.append("  --vcd-post {} `".format(args.vcd_post))
    if args.dump_hierarchy:
        wave_replay_options.append("  --dump-hierarchy 1 `")
    if args.gen_wavedrom:
        wave_replay_options.append("  --gen-wavedrom 1 `")

    failed_list_lines = ["# testcase repeat wave"]
    for item in abnormal:
        replay_run_dir = run_dir / "replay_{}_{}".format(safe_filename(item.job.testcase), item.job.seed)
        replay_lines += [
            "python .\\run_regression_parallel.py `",
            "  --testcase {} `".format(item.job.testcase),
            "  --seed {} `".format(item.job.seed),
            "  --wave {} `".format(item.job.wave),
            "  --verbose {} `".format(args.verbose),
            "  --max-parallel 1 `",
            "  --retry-infra 0 `",
            "  --run-dir \"{}\" `".format(replay_run_dir),
            "  --vivado \"{}\" `".format(args.vivado),
            "  --project-xpr \"{}\" `".format(args.project_xpr),
            "  --loop-root \"{}\" `".format(args.loop_root),
        ]
        replay_lines += wave_replay_options
        replay_lines += [
            "  --work-root \"{}\"".format(args.work_root),
            "",
        ]
        failed_list_lines.append("{} 1 {}".format(item.job.testcase, item.job.wave))

    if abnormal:
        failed_regress_list.write_text("\n".join(failed_list_lines) + "\n", encoding="utf-8")
        replay_lines += [
            "# Batch rerun only failed/artifact-failed testcase names with new random seeds:",
            "python .\\run_regression_parallel.py `",
            "  --regress-list \"{}\" `".format(failed_regress_list),
            "  --verbose {} `".format(args.verbose),
            "  --max-parallel {} `".format(args.max_parallel),
            "  --retry-infra {} `".format(args.retry_infra),
            "  --run-dir \"{}\" `".format(run_dir / "rerun_failed"),
            "  --vivado \"{}\" `".format(args.vivado),
            "  --project-xpr \"{}\" `".format(args.project_xpr),
            "  --loop-root \"{}\" `".format(args.loop_root),
        ]
        replay_lines += wave_replay_options
        replay_lines += [
            "  --work-root \"{}\"".format(args.work_root),
            "",
        ]
    elif failed_regress_list.exists():
        failed_regress_list.unlink()
    failed_replay.write_text("\n".join(replay_lines), encoding="utf-8")


def parse_args(argv):
    script_dir = Path(__file__).resolve().parent
    default_loop = script_dir.parent
    default_project = default_loop.parent.parent / "fdma_aurora_brg.xpr"
    default_run_dir = Path("C:/project/vivado_regress/run")
    default_work_root = Path("C:/project/vivado_regress")
    default_vivado = r"C:\Xilinx\Vivado\2020.2\bin\vivado.bat"
    parser = argparse.ArgumentParser(description="Run fdma_aurora_brg Vivado/XSim regression in parallel.")
    mode = parser.add_mutually_exclusive_group()
    mode.add_argument("--testcase", help="single testcase name, for example tc_brg_tx_fifo_waterline")
    mode.add_argument("--regress-list", type=Path, default=script_dir / "regress_list", help="regress_list path")
    parser.add_argument("--repeat", type=int, default=1, help="single-testcase repeat count")
    parser.add_argument("--wave", type=int, choices=(0, 1), default=0, help="single-testcase wave switch")
    parser.add_argument("--seed", help="single-testcase replay seed, six decimal digits")
    parser.add_argument("--verbose", type=int, choices=(0, 1, 2), default=0, help="0=summary, 1=plan/frame, 2=handshake")
    parser.add_argument("--max-parallel", type=int, default=0, help="0 means run all expanded jobs in parallel")
    parser.add_argument("--retry-infra", type=int, default=2, help="retry infra/tool failures this many times with the same seed")
    parser.add_argument("--run-dir", type=Path, default=default_run_dir, help="output directory for logs, reports and copied WDB files")
    parser.add_argument("--work-root", type=Path, default=default_work_root, help="root directory for per-job Vivado project copies")
    parser.add_argument("--vivado", default=default_vivado, help="vivado.bat path or command name")
    parser.add_argument("--project-xpr", type=Path, default=default_project, help="Vivado project .xpr")
    parser.add_argument("--loop-root", type=Path, default=default_loop, help="sources_1 - loop_validate directory")
    parser.add_argument("--shared-project", action="store_true", help="do not copy project per job; only safe for serial/debug use")
    parser.add_argument("--keep-work", action="store_true", help="keep copied per-job Vivado work directories")
    parser.add_argument("--vcd-mode", choices=("none", "selected"), default="none", help="none=no selected VCD, selected=dump signals from --vcd-signals")
    parser.add_argument("--vcd-signals", type=Path, help="text file with one XSim object path or wildcard per line")
    parser.add_argument("--vcd-start", help="optional selected VCD start time, e.g. 1000ns")
    parser.add_argument("--vcd-stop", help="optional selected VCD stop time, e.g. 2000ns")
    parser.add_argument("--vcd-anchor", help="log anchor, for example [MON][TX_FIFO_WR]; runs an anchor pass then dumps the computed window")
    parser.add_argument("--vcd-pre", default="0ns", help="time before --vcd-anchor, e.g. 200ns")
    parser.add_argument("--vcd-post", default="0ns", help="time after --vcd-anchor, e.g. 400ns")
    parser.add_argument("--dump-hierarchy", type=int, choices=(0, 1), default=0, help="write hierarchy and signal check reports")
    parser.add_argument("--gen-wavedrom", type=int, choices=(0, 1), default=0, help="generate WaveDrom JSON plus a simple SVG/summary from selected VCD")
    parser.add_argument("--dry-run", action="store_true", help="print expanded jobs without launching Vivado")
    args = parser.parse_args(argv)

    if args.repeat < 1:
        parser.error("--repeat must be positive")
    if args.seed and (not args.seed.isdigit() or len(args.seed) != 6 or args.seed == "000000"):
        parser.error("--seed must be six decimal digits in 000001..999999")
    if args.max_parallel < 0:
        parser.error("--max-parallel must be >= 0")
    if args.retry_infra < 0:
        parser.error("--retry-infra must be >= 0")
    if args.vcd_mode == "selected" and not args.vcd_signals:
        parser.error("--vcd-mode selected requires --vcd-signals")
    if args.vcd_mode == "none" and (args.vcd_start or args.vcd_stop or args.vcd_anchor):
        parser.error("--vcd-start/--vcd-stop/--vcd-anchor require --vcd-mode selected")
    if args.gen_wavedrom and args.vcd_mode != "selected":
        parser.error("--gen-wavedrom 1 requires --vcd-mode selected")
    if args.vcd_anchor and (args.vcd_start or args.vcd_stop):
        parser.error("--vcd-anchor cannot be combined with manual --vcd-start/--vcd-stop")
    parse_time_ns(args.vcd_pre or "0ns")
    parse_time_ns(args.vcd_post or "0ns")
    if args.vcd_start:
        parse_time_ns(args.vcd_start)
    if args.vcd_stop:
        parse_time_ns(args.vcd_stop)
    return args


def print_result(result):
    job = result.job
    if result.run_status == RUN_PASS:
        if job.wave == 1:
            print("[PASS] #{:03d} {} seed={} attempt={} wave=1 wdb={} wdb_size={}".format(
                job.index, job.testcase, job.seed, job.attempt, result.wdb, result.wdb_size
            ))
        else:
            print("[PASS] #{:03d} {} seed={} attempt={} wave=0 wdb=NOT_REQUESTED".format(
                job.index, job.testcase, job.seed, job.attempt
            ))
    elif result.run_status == RUN_ARTIFACT_FAIL:
        print("[{}][{}][{}] testcase={} seed={} attempt={}".format(
            final_status_for(result), fail_kind_for_result(result), result.wave_status,
            job.testcase, job.seed, job.attempt
        ))
        expected = result.wdb if result.wdb else result.sim_log.parent / "{}_behav.wdb".format(log_stem_for_job(job))
        print("  expected={}".format(expected))
        print("  vivado_log={}".format(result.stdout_log))
        if result.extra_log_dir:
            print("  extra_logs={}".format(result.extra_log_dir))
        print("  work_project={}".format(result.work_project_xpr))
        if result.work_retained != "-":
            print("  WORK_RETAINED={}".format(result.work_retained))
    else:
        print("[{}][{}] #{:03d} {} seed={} attempt={} first_error={}".format(
            final_status_for(result), fail_kind_for_result(result), job.index,
            job.testcase, job.seed, job.attempt, result.first_error
        ))
        print("  vivado_log={}".format(result.stdout_log))
        if result.extra_log_dir:
            print("  extra_logs={}".format(result.extra_log_dir))
        if result.work_retained != "-":
            print("  WORK_RETAINED={}".format(result.work_retained))


def make_exception_result(job, exc, args, run_dir, project_xpr, loop_root, work_root):
    log_stem = log_stem_for_job(job)
    stdout_log = run_dir / "{}_vivado.log".format(log_stem)
    stderr_log = run_dir / "{}_vivado.err.log".format(log_stem)
    sim_log = run_dir / "{}_simulate.log".format(log_stem)
    stderr_log.write_text(path_length_hint(exc, work_root) + "\n", encoding="utf-8")
    first_error = first_matching_line([stderr_log, stdout_log, sim_log])
    return make_result(
        job,
        RUN_FAIL,
        TEST_UNKNOWN,
        FAIL_TOOL,
        first_error,
        WAVE_MISSING if job.wave else WAVE_NOT_REQUESTED,
        0,
        0.0,
        sim_log,
        None,
        stdout_log,
        stderr_log,
        -1,
        project_xpr,
        loop_root,
        "-",
        None,
    )


def cleanup_retried_work(all_attempts, final_results, args, work_run_root):
    if args.shared_project or args.keep_work:
        return all_attempts

    final_pass_indices = set(item.job.index for item in final_results if item.run_status == RUN_PASS)
    if not final_pass_indices:
        return all_attempts

    updated = []
    work_root_text = os.path.normcase(str(work_run_root.resolve()))
    for result in all_attempts:
        if result.job.index not in final_pass_indices or result.work_retained == "-":
            updated.append(result)
            continue
        retained = Path(result.work_retained)
        if not retained.exists():
            updated.append(result._replace(work_retained="CLEANED_AFTER_RETRY"))
            continue
        try:
            retained_text = os.path.normcase(str(retained.resolve()))
            common = os.path.normcase(os.path.commonpath([work_root_text, retained_text]))
            if common == work_root_text:
                shutil.rmtree(str(retained))
                updated.append(result._replace(work_retained="CLEANED_AFTER_RETRY"))
            else:
                updated.append(result)
        except (OSError, ValueError):
            updated.append(result)
    return updated


def main(argv):
    args = parse_args(argv)
    script_dir = Path(__file__).resolve().parent
    project_xpr = args.project_xpr.resolve()
    loop_root = args.loop_root.resolve()
    work_root = args.work_root.resolve()
    args.project_xpr = project_xpr
    args.loop_root = loop_root
    args.work_root = work_root
    if args.vcd_signals:
        args.vcd_signals = args.vcd_signals.resolve()
        if not args.vcd_signals.exists():
            raise FileNotFoundError("selected VCD signal file not found: {}".format(args.vcd_signals))

    if not project_xpr.exists():
        raise FileNotFoundError("Vivado project not found: {}".format(project_xpr))
    if not loop_root.exists():
        raise FileNotFoundError("loop root not found: {}".format(loop_root))

    valid_tests = set(read_registered_tests(loop_root))
    jobs = build_jobs(args, valid_tests)
    if not jobs:
        raise RuntimeError("no runnable jobs")

    timestamp = _dt.datetime.now().strftime("%Y%m%d_%H%M%S")
    run_id = make_run_id()
    run_dir = args.run_dir.resolve()
    work_run_root = work_root / run_id
    if not args.dry_run:
        run_dir.mkdir(parents=True, exist_ok=True)
        if not args.shared_project:
            work_run_root.mkdir(parents=True, exist_ok=True)

    parallel = len(jobs) if args.max_parallel == 0 else min(args.max_parallel, len(jobs))
    print("RUN_DIR={}".format(run_dir))
    print("WORK_ROOT={}".format(work_root))
    print("WORK_RUN_ROOT={}".format(work_run_root))
    print("JOBS={} MAX_PARALLEL={} VERBOSE={} RETRY_INFRA={}".format(
        len(jobs), parallel, args.verbose, args.retry_infra
    ))
    print("PROJECT_XPR={}".format(project_xpr))
    print("LOOP_ROOT={}".format(loop_root))
    print("VCD_MODE={}".format(args.vcd_mode))
    if args.vcd_signals:
        print("VCD_SIGNALS={}".format(args.vcd_signals))
    if args.vcd_anchor:
        print("VCD_ANCHOR={} PRE={} POST={}".format(args.vcd_anchor, args.vcd_pre, args.vcd_post))
    elif args.vcd_start or args.vcd_stop:
        print("VCD_WINDOW={}..{}".format(args.vcd_start or "0", args.vcd_stop or "end"))
    if args.dump_hierarchy:
        print("DUMP_HIERARCHY=1")
    if args.gen_wavedrom:
        print("GEN_WAVEDROM=1")
    if not args.shared_project:
        print("PROJECT_COPY=per-job independent copy")

    for job in jobs:
        print("[JOB ] #{:03d} {} iter={}/{} seed={} attempt={} wave={}".format(
            job.index, job.testcase, job.iteration, job.repeat, job.seed, job.attempt, job.wave
        ))
        if not args.shared_project:
            print("       work_project={}".format(work_project_path(project_xpr, work_run_root, job)))
    if args.dry_run:
        return 0

    final_by_index = {}
    all_attempts = []
    with concurrent.futures.ThreadPoolExecutor(max_workers=parallel) as executor:
        future_map = {
            executor.submit(run_one_job, job, args, script_dir, project_xpr, loop_root, run_dir, work_run_root): job
            for job in jobs
        }
        for future in concurrent.futures.as_completed(future_map):
            job = future_map[future]
            try:
                result = future.result()
            except Exception as exc:
                result = make_exception_result(job, exc, args, run_dir, project_xpr, loop_root, work_root)
            final_by_index[job.index] = result
            all_attempts.append(result)
            print_result(result)

    pending = [
        item for item in sorted(final_by_index.values(), key=lambda value: value.job.index)
        if is_retryable_infra(item)
    ]
    for attempt in range(2, args.retry_infra + 2):
        if not pending:
            break
        next_pending = []
        print("[RETRY] attempt {}/{} retrying {} infra failure(s) serially".format(
            attempt, args.retry_infra + 1, len(pending)
        ))
        for previous in pending:
            retry_job = previous.job._replace(attempt=attempt)
            try:
                result = run_one_job(retry_job, args, script_dir, project_xpr, loop_root, run_dir, work_run_root)
            except Exception as exc:
                result = make_exception_result(retry_job, exc, args, run_dir, project_xpr, loop_root, work_root)
            final_by_index[retry_job.index] = result
            all_attempts.append(result)
            print_result(result)
            if attempt < args.retry_infra + 1 and is_retryable_infra(result):
                next_pending.append(result)
        pending = next_pending

    results = [final_by_index[index] for index in sorted(final_by_index)]
    all_attempts = cleanup_retried_work(all_attempts, results, args, work_run_root)
    write_reports(results, all_attempts, run_dir, args)
    try:
        if not args.shared_project and not args.keep_work:
            work_run_root.rmdir()
    except OSError:
        pass

    abnormal = sum(1 for item in results if item.run_status != RUN_PASS)
    print("Run log : {}".format(run_dir / "regress_log.log"))
    print("TSV log : {}".format(run_dir / "regress_log.tsv"))
    print("Summary : {}".format(run_dir / "regress_rpt.log"))
    print("Replay  : {}".format(run_dir / "failed_replay.ps1"))
    return 1 if abnormal else 0


if __name__ == "__main__":
    try:
        raise SystemExit(main(sys.argv[1:]))
    except Exception as exc:
        print("ERROR: {}".format(exc), file=sys.stderr)
        raise SystemExit(2)
