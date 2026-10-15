#!/usr/bin/env python3
"""在独立临时目录验证回归控制行为，不运行FPGA工程。"""
import json
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest


RUNNER = Path(__file__).with_name("run_daily_regression.py")
WORKER = r'''
import argparse
from pathlib import Path
import sys
import time
p = argparse.ArgumentParser()
p.add_argument("--mode")
p.add_argument("--name")
p.add_argument("--seed", default="")
a = p.parse_args()
with Path("order.txt").open("a", encoding="utf-8") as f:
    f.write(a.name + "\n")
print("SEED=" + a.seed, flush=True)
if a.mode == "pass":
    print("TEST_RESULT=PASS")
elif a.mode == "fail":
    print("TEST_RESULT=PASS")
    print("TEST_RESULT=FAIL")
elif a.mode == "compile_soft_fail":
    print("ERROR: compilation failed")
elif a.mode == "env":
    print("REGRESSION_ENV_ERROR: unavailable")
elif a.mode == "exit_fail":
    raise SystemExit(1)
elif a.mode == "sleep":
    time.sleep(10)
else:
    print("completed without a verdict")
'''


class RegressionBehavior(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(prefix="fpga_flow_regression_")
        self.root = Path(self.temp.name).resolve()
        self.assertEqual(self.root.parent, Path(tempfile.gettempdir()).resolve())
        self.assertTrue(self.root.name.startswith("fpga_flow_regression_"))
        self.work = self.root / "project"
        self.work.mkdir()
        (self.work / "worker.py").write_text(WORKER, encoding="utf-8")
        self.cfg = self.root / "config.json"
        self.output = self.root / "runs"

    def tearDown(self):
        # 清理前再次确认目标仅为本测试创建的临时目录。
        target = Path(self.temp.name).resolve()
        self.assertEqual(target, self.root)
        self.assertEqual(target.parent, Path(tempfile.gettempdir()).resolve())
        self.assertTrue(target.name.startswith("fpga_flow_regression_"))
        self.temp.cleanup()

    def case(self, name, mode="pass", seed=None):
        argv = [sys.executable, "-B", "worker.py", "--mode", mode, "--name", name]
        if seed is not None:
            argv += ["--seed", "{seed}"]
        result = {
            "name": name,
            "test_points": ["DEMO.001.001＋本例功能点"],
            "command": argv,
            "timeout_seconds": 5,
            "pass_pattern": r"(?m)^TEST_RESULT=PASS$",
            "fail_pattern": r"(?m)^TEST_RESULT=FAIL$",
        }
        if seed is not None:
            result["seed"] = seed
        return result

    def invoke(self, cases, build=None, config_path=None, selected=None, workdir="project"):
        if config_path is None:
            data = {
                "project_name": "DEMO", "working_directory": workdir,
                "compile_command": build or [], "compile_timeout_seconds": 5,
                "cases": cases,
            }
            self.cfg.write_text(json.dumps(data, ensure_ascii=False), encoding="utf-8")
            config_path = self.cfg
        argv = [
            sys.executable, "-B", "-X", "utf8", str(RUNNER),
            "--config", str(config_path), "--output", str(self.output),
        ]
        if selected:
            argv += ["--case", selected]
        process = subprocess.run(argv, capture_output=True, encoding="utf-8", timeout=30)
        return process

    def latest(self):
        folder = max(self.output.iterdir(), key=lambda p: p.stat().st_mtime_ns)
        return folder, json.loads((folder / "summary.json").read_text(encoding="utf-8"))

    def test_order_fail_continue_and_log_evidence(self):
        process = self.invoke([self.case("first"), self.case("middle", "fail"), self.case("last")])
        self.assertEqual(process.returncode, 1, process.stderr)
        folder, summary = self.latest()
        self.assertEqual(summary["status"], "FAIL")
        self.assertEqual([c["status"] for c in summary["cases"]], ["PASS", "FAIL", "PASS"])
        self.assertEqual((self.work / "order.txt").read_text().splitlines(), ["first", "middle", "last"])
        self.assertTrue((folder / "summary.csv").exists())
        self.assertTrue(all((folder / c["log"]).exists() for c in summary["cases"]))

    def test_missing_tool_stops_remaining(self):
        missing = self.case("missing")
        missing["command"] = [str(self.root / "missing_executable_7329.exe")]
        process = self.invoke([missing, self.case("later")])
        self.assertEqual(process.returncode, 2)
        _, summary = self.latest()
        self.assertEqual([c["status"] for c in summary["cases"]], ["ENV_ERROR", "NOT_RUN"])
        self.assertFalse((self.work / "order.txt").exists())

    def test_runtime_environment_marker_stops_remaining(self):
        process = self.invoke([self.case("license", "env"), self.case("later")])
        self.assertEqual(process.returncode, 2)
        _, summary = self.latest()
        self.assertEqual([c["status"] for c in summary["cases"]], ["ENV_ERROR", "NOT_RUN"])

    def test_compile_failure_stops_all_cases(self):
        for mode in ["exit_fail", "compile_soft_fail", "env"]:
            with self.subTest(mode=mode):
                build = [
                    sys.executable, "-B", "worker.py", "--mode", mode, "--name", "compile",
                ]
                process = self.invoke([self.case("unused")], build=build)
                self.assertEqual(process.returncode, 2)
                _, summary = self.latest()
                self.assertEqual(summary["status"], "BUILD_FAIL")
                self.assertEqual(summary["cases"][0]["status"], "NOT_RUN")

    def test_timeout_then_continue(self):
        slow = self.case("slow", "sleep")
        slow["timeout_seconds"] = 0.3
        process = self.invoke([slow, self.case("later")])
        self.assertEqual(process.returncode, 1)
        _, summary = self.latest()
        self.assertEqual([c["status"] for c in summary["cases"]], ["FAIL", "PASS"])
        self.assertTrue(summary["cases"][0]["timed_out"])

    def test_zero_exit_without_actual_pass_is_fail(self):
        silent = self.case("silent")
        # 命令文本含PASS，但进程输出不含PASS，不能把命令当作执行证据。
        silent["command"] = [
            sys.executable, "-B", "-c", "# TEST_RESULT=PASS\nprint('no verdict')",
        ]
        process = self.invoke([silent, self.case("later")])
        self.assertEqual(process.returncode, 1)
        _, summary = self.latest()
        self.assertEqual([c["status"] for c in summary["cases"]], ["FAIL", "PASS"])

    def test_snapshot_replay_keeps_cwd_seed_and_single_case_scope(self):
        process = self.invoke([self.case("alpha", seed=111), self.case("beta", seed=357)])
        self.assertEqual(process.returncode, 0)
        folder, summary = self.latest()
        snapshot = folder / "config.snapshot.json"
        self.assertEqual(
            json.loads(snapshot.read_text(encoding="utf-8"))["working_directory"], str(self.work)
        )
        # 改动原配置后仍从已保存快照重放原Seed。
        changed = json.loads(self.cfg.read_text(encoding="utf-8"))
        changed["cases"][1]["seed"] = 999
        self.cfg.write_text(json.dumps(changed), encoding="utf-8")
        replay = self.invoke([], config_path=snapshot, selected="beta")
        self.assertEqual(replay.returncode, 0, replay.stderr)
        replay_dir, result = self.latest()
        self.assertEqual(result["scope"], "single_case")
        self.assertEqual([c["name"] for c in result["cases"]], ["beta"])
        self.assertEqual(result["cases"][0]["seed"], 357)
        self.assertIn("SEED=357", (replay_dir / result["cases"][0]["log"]).read_text())

    def test_empty_cases_are_rejected_without_a_pass_run(self):
        process = self.invoke([])
        self.assertEqual(process.returncode, 2)
        self.assertIn("CONFIG_ERROR", process.stderr)
        self.assertFalse(self.output.exists())

    def test_missing_workdir_stops_remaining(self):
        process = self.invoke([self.case("first"), self.case("later")], workdir="missing_dir")
        self.assertEqual(process.returncode, 2)
        _, summary = self.latest()
        self.assertEqual([c["status"] for c in summary["cases"]], ["ENV_ERROR", "NOT_RUN"])

    def test_invalid_pass_pattern_is_rejected(self):
        case = self.case("bad")
        case["pass_pattern"] = ".*"
        process = self.invoke([case])
        self.assertEqual(process.returncode, 2)
        self.assertFalse(self.output.exists())

    def test_optional_compile_command_defaults_to_skip(self):
        data = {"working_directory": "project", "cases": [self.case("first")]}
        self.cfg.write_text(json.dumps(data), encoding="utf-8")
        process = self.invoke([], config_path=self.cfg)
        self.assertEqual(process.returncode, 0)


if __name__ == "__main__":
    unittest.main(verbosity=2)
