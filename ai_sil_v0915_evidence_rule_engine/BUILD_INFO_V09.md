# Build Info — v0.9 Modern Workbench

- Base: v0.8.2 Department Title + v0.8.1 responsive layout
- Target: Windows x64
- Go: go version go1.23.2 linux/amd64
- `go vet main.go`: passed for `GOOS=windows GOARCH=amd64`
- GUI binary: Windows GUI subsystem
- Debug binary: Windows console subsystem
- Backend execution/safety model preserved

## Main executable

`AI_SIL_Test_Workbench_v0.9.exe`

## Debug executable

`AI_SIL_Test_Workbench_v0.9_debug.exe`

## UI baseline

- Department/product title hierarchy
- Compact project/runtime strip
- Six-stage workflow stepper
- KPI summary cards
- Requirement / structured TestPlan / Evidence + Diagnosis three-column workbench
- Semantic fault matrix with separate Case Result
- IDE-style Build/UART/Agent console panel
- Responsive window layout
