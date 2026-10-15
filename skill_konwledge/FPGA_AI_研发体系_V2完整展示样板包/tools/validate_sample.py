"""Read-only validation for the V2 demonstration package. No EDA/network/writes."""
import argparse
import copy
import hashlib
import json
import re
import sys
from pathlib import Path
from urllib.parse import unquote

ROOT = Path(__file__).resolve().parents[1]
EXCLUDED_HASH = "a20bd1e9d3d4526de3c65febb0957202406df2f0533b89e048e26d7d20fabcbf"
JSON_FILES = [
    "objects/object_contract.schema.json", "objects/knowledge_objects.example.json",
    "task_pack/TASK-AUR-001.json", "task_pack/TASK-HO-001.json",
    "eda_gates/gate_catalog.json", "eda_gates/run_manifest.example.json",
    "evaluation/evaluation_matrix.example.json", "feedback/feedback_card.example.json",
    "index/asset_registry.example.json", "index/traceability_matrix.example.json",
    "index/evidence_path_index.local.json", "index/source_baseline.local.json",
]

def walk(value):
    if isinstance(value, dict):
        yield value
        for child in value.values():
            yield from walk(child)
    elif isinstance(value, list):
        for child in value:
            yield from walk(child)

def semantics(bundle):
    errors = []
    def check(ok, message):
        if not ok:
            errors.append(message)
    definitions = {}
    for filename, data in bundle.items():
        if filename.endswith('.schema.json'):
            continue
        for obj in walk(data):
            if "id" in obj:
                ident = obj["id"]
                check(isinstance(ident, str), "non-string ID")
                check(ident not in definitions, "duplicate ID: " + str(ident))
                definitions[ident] = filename
    scalar_refs = {"task_id", "case_id", "decision_id", "requirement_id",
                   "historical_evidence_id", "v2_run_id"}
    list_refs = {"source_ids", "related_ids", "test_ids", "gate_ids",
                 "required_gate_ids", "optional_gate_ids", "run_ids"}
    for filename, data in bundle.items():
        if filename.endswith('.schema.json'):
            continue
        for obj in walk(data):
            for key, val in obj.items():
                if key in scalar_refs and val is not None:
                    check(val in definitions, "dangling reference: " + str(val))
                elif key in list_refs:
                    check(isinstance(val, list), "reference list required: " + key)
                    if isinstance(val, list):
                        for ident in val:
                            check(ident in definitions, "dangling reference: " + str(ident))
    objects = bundle["objects/knowledge_objects.example.json"]["objects"]
    # Interpret the required fields, type enums, string pattern and array types
    # of our small object schema, not the full JSON Schema specification.
    contract = bundle["objects/object_contract.schema.json"]["properties"]["objects"]["items"]
    for obj in objects:
        check(set(contract["required"]) <= set(obj), "missing knowledge-object fields")
        for field, spec in contract["properties"].items():
            if field not in obj:
                continue
            val = obj[field]
            if "enum" in spec:
                check(val in spec["enum"], "invalid enum: " + field)
            if spec.get("type") == "string":
                check(isinstance(val, str) and bool(val), "invalid string: " + field)
            if "pattern" in spec:
                check(bool(re.fullmatch(spec["pattern"], val)), "invalid pattern: " + field)
            if spec.get("type") == "array":
                check(isinstance(val, list) and all(isinstance(x, str) for x in val), "invalid list: " + field)
        if obj["type"] == "approved_output_candidate":
            check(obj["lifecycle"] == "candidate" and obj["approval"]["status"] == "pending", "false output approval")
    expected = ["pre_kb_historical", "pre_kb_historical", "post_kb_asset", "pre_kb_historical",
                "pre_kb_historical", "pre_kb_historical", "post_kb_asset", "planned_holdout"]
    case_objects = sorted((o for o in objects if o["type"] == "case_ref"), key=lambda o:o["id"])
    check([o["causality"] for o in case_objects] == expected, "case causality mismatch")
    for name in ("TASK-AUR-001", "TASK-HO-001"):
        task = bundle["task_pack/" + name + ".json"]
        check(task["execution_status"] == "not_run", "task execution fabricated")
        check(task["results"] is None and task["run_ids"] == [], "task results fabricated")
        check(task["approved_by"] is None and task["approved_at"] is None, "false task signoff")
        check(task["workspace"] is None and task["allowed_write_paths"] == [], "demo grants write paths")
        for d in task["decisions"]:
            check(d["status"] == "open" and d["approved_choice"] is None, "decision auto-approved")
        tests = {t["id"] for t in task["testpoints"]}
        for req in task["requirements"]:
            check(bool(req["test_ids"]) and set(req["test_ids"]) <= tests, "unmapped requirement")
    task = bundle["task_pack/TASK-HO-001.json"]
    check({"DEC-001", "DEC-002"} <= {d["id"] for d in task["decisions"]}, "missing design decision")
    filt = task["corpus_filter"]
    check(filt["status"] == "not_implemented", "filter falsely claimed ready")
    check(EXCLUDED_HASH in filt["exclude_exact_sha256"], "missing leaked-answer hash")
    check("axis_async_fifo.sv" in filt["exclude_names"], "missing excluded name")
    check({"NVMe", "FDMA", "Aurora"} <= set(filt["exclude_project_answers"]), "missing project exclusions")
    check(filt["near_duplicate_review"] == "required_before_run", "missing near-answer review")
    check(len(task["stages"]) >= 8, "end-to-end stages incomplete")
    run = bundle["eda_gates/run_manifest.example.json"]
    check(run["execution_status"] == "not_run", "EDA execution fabricated")
    for field in ("result", "started_at", "finished_at", "command", "exit_code", "testcase",
                  "seed", "transaction_count", "assertion_errors", "scoreboard_mismatches",
                  "code_hash", "human_signoff"):
        check(run[field] is None, "not_run requires null " + field)
    for field in ("milestones", "evidence_files", "gate_results", "attempts"):
        check(run[field] == [], "not_run requires empty " + field)
    ev = bundle["evaluation/evaluation_matrix.example.json"]
    check(ev["execution_status"] == "not_run", "evaluation execution fabricated")
    check(ev["baseline"] is None and ev["comparison_result"] is None, "effect fabricated")
    check([g["group"] for g in ev["groups"]] == ["A", "B", "C"], "missing comparison group")
    for g in ev["groups"]:
        for field in ("results", "elapsed_seconds", "human_active_seconds", "iterations", "unsubstantiated_claims"):
            check(g[field] is None, "measurement fabricated: " + field)
        check(g["run_ids"] == [], "evaluation run fabricated")
    fb = bundle["feedback/feedback_card.example.json"]
    check(fb["lifecycle"] == "candidate" and fb["publication_allowed"] is False, "unreviewed feedback published")
    check(fb["reviewer"] is None and fb["approved_at"] is None, "feedback approval fabricated")
    reg = bundle["index/asset_registry.example.json"]
    check(reg["production_backend"] == "not_implemented", "backend falsely claimed")
    check(reg["eda_execution"] == "not_run" and reg["skill_installation"] == "not_installed", "deployment falsely claimed")
    for ext in reg["external_assets"]:
        check(ext["access"] == "read_only", "external write access")
    idx = bundle["index/evidence_path_index.local.json"]
    check(idx["classification"] == "LOCAL_ONLY_DO_NOT_EXPORT", "index export classification")
    for source in idx["sources"]:
        check(source["access"] == "read_only", "source write access")
        check(bool(re.fullmatch(r"[0-9a-f]{64}", source["sha256"])), "invalid SHA256")
    return errors

def check_files(bundle, check_external=True):
    errors = []
    reg = bundle["index/asset_registry.example.json"]
    expected = {x["path"] for x in reg["files"]}
    found = {p.relative_to(ROOT).as_posix() for p in ROOT.rglob("*") if p.is_file()}
    errors += ["missing file: " + p for p in sorted(expected - found)]
    errors += ["unregistered file: " + p for p in sorted(found - expected)]
    main = (ROOT / reg["main_document"]).resolve()
    if not main.is_file():
        errors.append("main Markdown missing")
    fence = chr(96) * 3
    for path in list(ROOT.rglob("*.md")) + ([main] if main.is_file() else []):
        data = path.read_text(encoding="utf-8")
        if data.count(fence) % 2:
            errors.append("unclosed code fence: " + path.name)
        if len(re.findall(r"^# ", data, re.M)) != 1:
            errors.append("exactly one H1 required: " + path.name)
        outside = re.sub(re.escape(fence) + r".*?" + re.escape(fence), "", data, flags=re.S)
        for link in re.findall(r"\[[^\]]+\]\(([^)]+)\)", outside):
            target = unquote(link.strip("<>").split("#")[0])
            if not target or re.match(r"^[a-z]+://", target, re.I):
                continue
            target = re.sub(r":\d+$", "", target)
            dest = Path(target) if re.match(r"^[A-Za-z]:[/\\]", target) else path.parent / target
            if not dest.exists():
                errors.append("broken Markdown link: " + path.name + " -> " + target)
    for obj in bundle["objects/knowledge_objects.example.json"]["objects"]:
        for key in ("document", "body_ref"):
            if key in obj and not (ROOT / obj[key]).is_file():
                errors.append("missing object document: " + obj[key])
    if check_external:
        idx = bundle["index/evidence_path_index.local.json"]
        for source in idx["sources"]:
            path = Path(source["path"])
            if not path.is_file():
                errors.append("source unavailable: " + source["id"])
            elif hashlib.sha256(path.read_bytes()).hexdigest() != source["sha256"]:
                errors.append("source changed: " + source["id"])
        for ext in reg["external_assets"]:
            if not Path(ext["path"]).exists():
                errors.append("external asset unavailable: " + ext["id"])
        for item in bundle["index/source_baseline.local.json"]["files"]:
            path = Path(item["Path"])
            if not path.is_file() or hashlib.sha256(path.read_bytes()).hexdigest().upper() != item["Hash"].upper():
                errors.append("protected source changed/unavailable: " + str(path))
        cell_path = next(s["path"] for s in idx["sources"] if s["id"] == "SRC-CELLS")
        cells = json.loads(Path(cell_path).read_text(encoding="utf-8"))["cells"]
        if len(cells) != 8 or any(c["status"] != "pending_user_input" for c in cells):
            errors.append("approved cell state changed")
    return errors

def self_test(bundle):
    tests = [
        ("fake_pass", lambda b: b["eda_gates/run_manifest.example.json"].update(result="PASS")),
        ("missing_hash", lambda b: b["task_pack/TASK-HO-001.json"]["corpus_filter"].update(exclude_exact_sha256=[])),
        ("dangling_source", lambda b: b["objects/knowledge_objects.example.json"]["objects"][0].update(source_ids=["SRC-MISSING"])),
        ("auto_approval", lambda b: b["task_pack/TASK-HO-001.json"]["decisions"][0].update(status="approved")),
        ("false_publication", lambda b: b["feedback/feedback_card.example.json"].update(publication_allowed=True)),
        ("false_improvement", lambda b: b["evaluation/evaluation_matrix.example.json"].update(comparison_result=0.30)),
        ("external_write", lambda b: b["index/asset_registry.example.json"]["external_assets"][0].update(access="write")),
    ]
    failures = []
    for name, mutate in tests:
        altered = copy.deepcopy(bundle)
        mutate(altered)
        try:
            caught = bool(semantics(altered))
        except (KeyError, TypeError, ValueError):
            caught = True
        if not caught:
            failures.append("negative check missed: " + name)
    return failures, len(tests)

def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--self-test", action="store_true", help="in-memory negative checks")
    parser.add_argument("--skip-external", action="store_true", help="skip source availability/hash checks")
    args = parser.parse_args()
    errors, bundle = [], {}
    for name in JSON_FILES:
        try:
            bundle[name] = json.loads((ROOT / name).read_text(encoding="utf-8"))
        except (OSError, ValueError) as exc:
            errors.append("cannot load " + name + ": " + str(exc))
    if not errors:
        try:
            errors.extend(semantics(bundle))
            errors.extend(check_files(bundle, not args.skip_external))
            if args.self_test:
                failures, count = self_test(bundle)
                errors.extend(failures)
                print("NEGATIVE_CHECKS=" + str(count))
        except (KeyError, TypeError, ValueError, OSError) as exc:
            errors.append("malformed sample: " + str(exc))
    for err in errors:
        print("ERROR: " + err)
    print("EXTERNAL_CHECKS=" + ("SKIPPED" if args.skip_external else "ENABLED"))
    print("RESULT " + ("FAIL" if errors else "PASS"))
    print("This result checks the sample package, not EDA or engineering signoff.")
    return 1 if errors else 0

if __name__ == "__main__":
    sys.exit(main())
