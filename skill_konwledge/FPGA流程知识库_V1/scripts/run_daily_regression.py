#!/usr/bin/env python3
"""按配置顺序执行项目回归；仿真命令及自检匹配式由项目填写。"""
import argparse
import csv
from datetime import datetime
import json
import math
import os
from pathlib import Path
import re
import signal
import subprocess
import sys
import time
from uuid import uuid4


def now():
    return datetime.now().astimezone().isoformat(timespec="seconds")


def pattern(value, label, required=True):
    if not value:
        if required:
            raise ValueError(label + "不能为空")
        return None
    if not isinstance(value, str):
        raise ValueError(label + "必须是字符串")
    try:
        compiled = re.compile(value)
    except re.error as exc:
        raise ValueError(label + "不是有效正则表达式: " + str(exc)) from exc
    if compiled.search("") is not None:
        raise ValueError(label + "不能匹配空文本")
    return compiled


def command(value, label, allow_empty=False):
    if not isinstance(value, list) or any(
        not isinstance(arg, str) or not arg for arg in value
    ):
        raise ValueError(label + "必须是非空字符串组成的参数列表")
    if not value and not allow_empty:
        raise ValueError(label + "不能为空")
    return value


def timeout(value, label):
    if (
        isinstance(value, bool) or not isinstance(value, (int, float))
        or not math.isfinite(value) or value <= 0
    ):
        raise ValueError(label + "必须是正数秒")
    return float(value)


def read_config(path):
    data = json.loads(path.read_text(encoding="utf-8-sig"))
    if not isinstance(data, dict):
        raise ValueError("配置必须是JSON对象")
    cases = data.get("cases")
    if not isinstance(cases, list) or not cases:
        raise ValueError("cases为空；先按已确认用例填写配置，不执行空回归")
    workdir = data.get("working_directory", ".")
    if not isinstance(workdir, str) or not workdir:
        raise ValueError("working_directory必须是路径字符串")
    data["_cwd"] = (path.parent / workdir).resolve()
    build = command(data.get("compile_command", []), "compile_command", True)
    data["compile_command"] = build
    if build:
        data["_compile_timeout"] = timeout(
            data.get("compile_timeout_seconds"), "compile_timeout_seconds"
        )
    data["_compile_fail"] = pattern(
        data.get("compile_fail_pattern", r"(?im)^\s*(?:ERROR|FATAL)\b"),
        "compile_fail_pattern",
    )
    data["_environment"] = pattern(
        data.get("environment_error_pattern", r"(?im)^\s*REGRESSION_ENV_ERROR\b"),
        "environment_error_pattern",
    )
    names = set()
    for case in cases:
        if not isinstance(case, dict):
            raise ValueError("每个case必须是对象")
        name = case.get("name")
        if not isinstance(name, str) or not name.strip() or name in names:
            raise ValueError("用例名称必须非空且唯一")
        names.add(name)
        points = case.get("test_points")
        if not isinstance(points, list) or not points or any(
            not isinstance(p, str) or not p.strip() for p in points
        ):
            raise ValueError(name + ": test_points需填写测试点反标")
        command(case.get("command"), name + ": command")
        case["_timeout"] = timeout(case.get("timeout_seconds"), name + ": timeout")
        case["_pass"] = pattern(case.get("pass_pattern"), name + ": pass_pattern")
        case["_fail"] = pattern(case.get("fail_pattern"), name + ": fail_pattern")
        case["_environment"] = pattern(
            case.get(
                "environment_error_pattern",
                data.get(
                    "environment_error_pattern", r"(?im)^\s*REGRESSION_ENV_ERROR\b"
                ),
            ),
            name + ": environment_error_pattern",
        )
        seed = case.get("seed")
        if seed is not None and (isinstance(seed, bool) or not isinstance(seed, int)):
            raise ValueError(name + ": seed必须是整数")
        if seed is None and any("{seed}" in arg for arg in case["command"]):
            raise ValueError(name + ": 命令含{seed}但未填写seed")
    return data


def stop_tree(process):
    if process.poll() is not None:
        return
    if os.name == "nt":
        subprocess.run(
            ["taskkill", "/PID", str(process.pid), "/T", "/F"],
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
            creationflags=getattr(subprocess, "CREATE_NO_WINDOW", 0),
            check=False,
        )
    else:
        try:
            os.killpg(process.pid, signal.SIGKILL)
        except ProcessLookupError:
            pass
    if process.poll() is None:
        process.kill()


def execute(argv, cwd, seconds, log):
    start = time.monotonic()
    result = {
        "command": argv,
        "started_at": now(),
        "exit_code": None,
        "duration_seconds": 0.0,
        "timed_out": False,
        "environment_error": "",
        "log": log.name,
    }
    options = {"start_new_session": True} if os.name != "nt" else {
        "creationflags": getattr(subprocess, "CREATE_NO_WINDOW", 0)
        | getattr(subprocess, "CREATE_NEW_PROCESS_GROUP", 0)
    }
    with log.open("wb") as output:
        try:
            process = subprocess.Popen(
                argv, cwd=str(cwd), stdout=output, stderr=subprocess.STDOUT, **options
            )
        except OSError as exc:
            result["environment_error"] = str(exc)
            output.write(("REGRESSION_ENV_ERROR: " + str(exc) + "\n").encode("utf-8"))
        else:
            try:
                result["exit_code"] = process.wait(timeout=seconds)
            except subprocess.TimeoutExpired:
                result["timed_out"] = True
                stop_tree(process)
                result["exit_code"] = process.wait()
            except KeyboardInterrupt:
                stop_tree(process)
                process.wait()
                raise
    result["duration_seconds"] = round(time.monotonic() - start, 3)
    result["finished_at"] = now()
    return result


def write_summary(run, summary):
    (run / "summary.json").write_text(
        json.dumps(summary, ensure_ascii=False, indent=2), encoding="utf-8"
    )
    fields = [
        "order", "name", "test_points", "seed", "status", "reason", "exit_code",
        "duration_seconds", "log",
    ]
    with (run / "summary.csv").open("w", encoding="utf-8-sig", newline="") as output:
        writer = csv.DictWriter(output, fieldnames=fields)
        writer.writeheader()
        for item in summary["cases"]:
            row = {key: item.get(key, "") for key in fields}
            row["test_points"] = "；".join(item["test_points"])
            writer.writerow(row)


def run(config_path, config, output, selected_name=None):
    cases = config["cases"]
    if selected_name is not None:
        cases = [case for case in cases if case["name"] == selected_name]
        if not cases:
            raise ValueError("找不到用例: " + selected_name)
    run_id = datetime.now().astimezone().strftime("%Y%m%d_%H%M%S") + "_" + uuid4().hex[:8]
    run_dir = output / run_id
    run_dir.mkdir(parents=True, exist_ok=False)
    cwd = config["_cwd"]
    # 固化工作目录，配置快照移到结果目录后仍可直接复现。
    snapshot = json.loads(config_path.read_text(encoding="utf-8-sig"))
    snapshot["working_directory"] = str(cwd)
    snapshot["compile_command"] = config["compile_command"]
    (run_dir / "config.snapshot.json").write_text(
        json.dumps(snapshot, ensure_ascii=False, indent=2), encoding="utf-8"
    )
    # 原始日志只含进程输出，命令/正则中的PASS文字不能充当执行证据。
    summary = {
        "run_id": run_id,
        "project_name": config.get("project_name", ""),
        "config_source": str(config_path),
        "working_directory": str(cwd),
        "scope": "single_case" if selected_name else "full",
        "started_at": now(),
        "compile": None,
        "cases": [],
        "status": "RUNNING",
    }
    stopped = False
    exit_status = 0
    if config["compile_command"]:
        build = execute(
            config["compile_command"], cwd, config["_compile_timeout"],
            run_dir / "compile.log",
        )
        build_text = (run_dir / "compile.log").read_text(encoding="utf-8", errors="replace")
        if (
            build["environment_error"] or build["timed_out"]
            or build["exit_code"] != 0 or config["_compile_fail"].search(build_text)
            or config["_environment"].search(build_text)
        ):
            build["status"] = "FAIL"
            summary["status"] = "BUILD_FAIL"
            stopped = True
            exit_status = 2
        else:
            build["status"] = "PASS"
        summary["compile"] = build
    for order, case in enumerate(cases, 1):
        item = {
            "order": order, "name": case["name"], "test_points": case["test_points"],
            "seed": case.get("seed"), "status": "NOT_RUN",
            "reason": "编译或环境异常，停止本轮" if stopped else "",
            "exit_code": None, "duration_seconds": 0.0, "log": "",
        }
        if not stopped:
            argv = [
                arg.replace("{seed}", str(case["seed"])) if "{seed}" in arg else arg
                for arg in case["command"]
            ]
            execution = execute(argv, cwd, case["_timeout"], run_dir / f"case_{order:03d}.log")
            item.update(execution)
            process_text = (run_dir / execution["log"]).read_text(
                encoding="utf-8", errors="replace"
            )
            if execution["environment_error"] or case["_environment"].search(process_text):
                item.update(status="ENV_ERROR", reason="工具或运行环境异常")
                stopped = True
                exit_status = 2
                summary["status"] = "ENV_ERROR"
            elif execution["timed_out"]:
                item.update(status="FAIL", reason="用例超时")
                exit_status = max(exit_status, 1)
            elif execution["exit_code"] != 0:
                item.update(status="FAIL", reason="仿真命令非零退出")
                exit_status = max(exit_status, 1)
            elif case["_fail"].search(process_text):
                item.update(status="FAIL", reason="命中失败匹配式")
                exit_status = max(exit_status, 1)
            elif not case["_pass"].search(process_text):
                item.update(status="FAIL", reason="未获得通过匹配")
                exit_status = max(exit_status, 1)
            else:
                item.update(status="PASS", reason="")
        summary["cases"].append(item)
        write_summary(run_dir, summary)
        print(f"{order:03d} {item['name']}: {item['status']}", flush=True)
    if summary["status"] == "RUNNING":
        summary["status"] = "PASS" if exit_status == 0 else "FAIL"
    summary["finished_at"] = now()
    write_summary(run_dir, summary)
    print("结果目录: " + str(run_dir), flush=True)
    return exit_status


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--config", type=Path, required=True)
    parser.add_argument("--output", type=Path, required=True)
    parser.add_argument("--case", dest="selected_name", help="按用例名称复现单例")
    args = parser.parse_args()
    try:
        path = args.config.resolve()
        config = read_config(path)
        return run(path, config, args.output.resolve(), args.selected_name)
    except (OSError, ValueError, TypeError) as exc:
        print("CONFIG_ERROR: " + str(exc), file=sys.stderr)
        return 2


if __name__ == "__main__":
    raise SystemExit(main())
