# Build Info — v0.9.2 Workspace / Pipeline Simplification

- Base: v0.9.1 Operator Controls + Real Pipeline State
- Target: Windows x64
- Go: $(go version 2>/dev/null || true)
- `GOOS=windows GOARCH=amd64 go vet main.go`: passed
- GUI binary: Windows GUI subsystem
- Debug binary: Windows console subsystem

## Main executables

- `AI_SIL_Test_Workbench_v0.9.2.exe`
- `AI_SIL_Test_Workbench_v0.9.2_debug.exe`

## Changes from v0.9.1

1. Split the crowded top strip into two independent areas:
   - **工程资源**: Project / Firmware / QEMU paths and browse actions.
   - **运行控制**: Project Analyze / Build / Start QEMU / Stop / Environment Check / Run Test.
2. Removed `能力检查` from the visible workflow. Capability routing remains an automatic backend mechanism.
3. Simplified the visible workflow to five stages:
   - 工程准备
   - 构建
   - QEMU 运行
   - 执行测试
   - 结果分析
4. Capability state is folded into `工程准备` only when it affects execution:
   - capability READY -> engineering preparation can complete
   - auto-extendable -> engineering preparation shows extension state
   - unsupported / missing -> engineering preparation shows the blocker
5. A new project analysis resets stale capability status from the previous project/TestPlan.
6. Existing GPIO/SIL/QEMU/AI Planner/Rule Engine/Report functionality is preserved.
