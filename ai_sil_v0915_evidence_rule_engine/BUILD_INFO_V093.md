# Build Info — v0.9.3 TestPlan / Run Semantics

- Base: v0.9.2 Workspace / Pipeline Simplification
- Target: Windows x64
- Go: go1.23.2 linux/amd64 (cross compile)
- `GOOS=windows GOARCH=amd64 go vet main.go`: passed
- GUI binary: Windows GUI subsystem
- Debug binary: Windows console subsystem

## Main executables

- `AI_SIL_Test_Workbench_v0.9.3.exe`
- `AI_SIL_Test_Workbench_v0.9.3_debug.exe`

## Changes from v0.9.2

1. `仅生成测试计划` now means preview/plan only. It never executes the plan.
2. `运行测试` now follows these semantics:
   - no current TestPlan -> generate a TestPlan, then execute it;
   - current TestPlan exists and requirement is unchanged -> execute the current TestPlan directly, without another LLM planning call;
   - requirement changed after the TestPlan was generated -> ask the operator whether to regenerate+run, run the current plan, or cancel.
3. The requirement used to generate a TestPlan is stored with that plan, so execution evidence/report metadata cannot silently switch to a newer edited requirement when the operator chooses to run the old plan.
4. Auto-extendable capabilities still work: a current plan that requires GPIO Input can install the capability, Build firmware, re-route the same stored requirement once, and continue execution.
5. Re-analyzing a project invalidates the previous TestPlan, preventing a plan created for another project context from being reused accidentally.
