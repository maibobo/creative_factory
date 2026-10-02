# AI SIL Test Workbench v0.9.8.1

## Fix: Test requirement input accidentally triggered AI SIL Engineer

### Root cause
v0.9.8 assigned the same Win32 control ID (`1032`) to both:
- `idAISILEngineer`
- `idPrompt` (the test requirement EDIT control)

Typing in an EDIT control generates multiple `WM_COMMAND` notifications such as `EN_UPDATE` and `EN_CHANGE`. Non-`EN_CHANGE` notifications could fall through to the button dispatch switch and were therefore interpreted as an AI SIL Engineer button click.

### Changes
- `idPrompt` now uses an independent control ID (`1101`).
- Added a duplicate-control-ID validation check during development.
- `WM_COMMAND` now consumes all notifications from the requirement EDIT control.
- Push-button actions are dispatched only when the notification is `BN_CLICKED`.
- No AI SIL Engineer, TestPlan, GPIO, QEMU, Build, or Rule Engine behavior was otherwise changed.

## Validation
- No duplicate numeric command/control IDs in the declared ID block.
- `GOOS=windows GOARCH=amd64 go vet main.go`: PASS.
- Windows x64 GUI build: PASS.
- Windows x64 debug build: PASS.
- Mock QEMU build: PASS.
