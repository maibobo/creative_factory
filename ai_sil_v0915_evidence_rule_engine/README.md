# AI SIL Test Workbench v0.9.15

Windows native Go/Win32 workbench for RT-Thread/QEMU driver SIL testing.

## v0.9.15: generated firmware collects evidence; the host owns the functional verdict

For `gpio_toggle_pattern`, the AI-generated C harness no longer emits a functional `PASS` or `FAIL`. It emits raw `@SIL,EVIDENCE` records and one `@SIL,EVIDENCE_SUMMARY`. The Windows Workbench applies the immutable host rule profile `gpio_toggle_pattern_v1` and computes the observed functional verdict itself.

The host checks the requested toggle count, HIGH/LOW order, requested values, readback equality, final LOW state, and runtime error count. A generated `GEN_RESULT` self-verdict is rejected for this capability.

Existing pre-v0.9.15 READY `gpio_toggle_pattern` revisions are intentionally not reused because they do not have the host evidence rule profile. The next requirement run generates a new revision automatically.

The v0.9.14 baseline-aware recovery remains: if host-evaluated generated evidence FAILs while the deterministic built-in `ai_test_gpio` baseline PASSes on the same pin, the generated revision becomes `INVALID_HARNESS` and Workbench automatically generates the next revision rather than reporting a DUT failure.

## Lifecycle

`Requirement -> TestPlan -> capability routing -> CodeGen -> Validator -> Build -> QEMU Probe -> raw Evidence -> Host Rule Engine -> Expected comparison -> Report`

For a bad generated harness:

`READY rN -> evidence/protocol contradiction -> INVALID_HARNESS -> rN+1 -> Build -> Probe -> Evidence -> Host Rule Engine`

## Build isolation

Only `applications/ai_sil_ai_*.c/.h` are live generated build sources. `.ai_sil` contains manifest metadata, `.snapshot` history and failure evidence.

## Main files

- `AI_SIL_Test_Workbench_v0.9.15.exe` — Windows GUI build
- `AI_SIL_Test_Workbench_v0.9.15_debug.exe` — console/debug build
- `Mock_QEMU_Console.exe` — mock target
- `agent_src/main.go` — Workbench source
- `BUILD_INFO_V0915.md` — release/change notes
- `docs/EVIDENCE_RULE_ENGINE_V0915.md` — protocol and rule semantics
