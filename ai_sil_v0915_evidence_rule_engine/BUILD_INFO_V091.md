# Build Info — v0.9.1 Operator Controls + Real Pipeline State

- Base: v0.9 Modern Workbench
- Target: Windows x64
- Go: go1.23.2 linux/amd64
- `GOOS=windows GOARCH=amd64 go vet main.go`: passed
- GUI binary: Windows GUI subsystem
- Debug binary: Windows console subsystem

## Main executables

- `AI_SIL_Test_Workbench_v0.9.1.exe`
- `AI_SIL_Test_Workbench_v0.9.1_debug.exe`

## Changes from v0.9

1. Restored high-frequency engineering controls to the main project strip:
   - Project Analyze
   - Build
   - Start QEMU
   - Stop QEMU
   - Environment Check
   - Run Test remains the primary action
2. Renamed workflow stage 2 from `测试能力准备` to `能力检查`.
3. Capability stage is now driven by the requested TestPlan capability:
   - `READY` -> check mark
   - auto-extendable -> half/extendable state
   - unsupported -> warning / MISSING
4. Build stage distinguishes:
   - active build
   - firmware ready
   - failed build
   - skipped (`本次无需重新构建`)
5. QEMU stage no longer completes merely because the process was spawned:
   - process running -> active
   - RT-Thread/MSH ready -> complete
   - SIL runtime ready -> complete
6. Execute and Diagnosis stages are no longer triggered by generic capability-routing text.
7. Existing GPIO / Capability Builder / AI Planner / Rule Engine / Report business logic is preserved.
