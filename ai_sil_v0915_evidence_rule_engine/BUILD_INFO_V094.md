# Build Info — v0.9.4 Test Action Layout

- Base: v0.9.3 TestPlan / Run Semantics
- Target: Windows x64
- Go: native Go Win32 backend/UI, cross-compiled on Linux
- `GOOS=windows GOARCH=amd64 go vet main.go`: passed
- GUI binary: Windows GUI subsystem
- Debug binary: Windows console subsystem

## Main executables

- `AI_SIL_Test_Workbench_v0.9.4.exe`
- `AI_SIL_Test_Workbench_v0.9.4_debug.exe`

## Changes from v0.9.3

1. Removed the global `运行测试` button from the upper-right engineering control strip.
2. The top area now contains only engineering context/actions: project, firmware, QEMU, project analysis, Build, Start/Stop QEMU, and environment check.
3. Test actions now live together inside the `测试需求` card:
   - no TestPlan: `仅生成测试计划` + `AI规划并运行`;
   - valid current TestPlan: `重新生成计划` + `运行当前计划`;
   - requirement edited after planning: an inline stale-plan warning is shown before execution.
4. The execution semantics from v0.9.3 are unchanged: a valid plan is reused; no plan triggers Plan+Run; changed requirements require explicit operator choice.
5. Capability routing remains automatic and hidden from the operator workflow unless it blocks or extends the current requirement.
