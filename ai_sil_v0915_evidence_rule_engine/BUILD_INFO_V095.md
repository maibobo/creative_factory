# AI SIL Test Workbench v0.9.5 — UI Polish

This release keeps the v0.9.4 workflow/backend semantics and focuses on visual refinement of the native Win32 workbench.

## Visual changes

- Custom owner-drawn rounded buttons with clear Primary / Secondary / Danger / Active-Tab states.
- Rounded workspace cards for engineering resources, controls, pipeline, KPI, test workbench, matrix and console areas.
- Modernized native Edit/List/Combo controls with Explorer theming, inner margins and rounded clipping.
- Softer design tokens: neutral page background, navy sidebar, blue accent, semantic green/orange/red states.
- Sidebar active navigation item is now rounded and visually lighter.
- Pipeline stages are rendered as semantic state chips/cards instead of plain text only.
- SIL Runtime / AI Planner header states use compact rounded status pills.
- TestPlan view tabs and Console tabs now show a visible active state.
- Result verdict and GPIO capability badges use rounded semantic pills.
- Build/UART/Agent console is now a dark terminal surface with Cascadia Mono when available.
- Existing v0.9.4 Test Action layout and all backend behavior are preserved.

## Build verification

- GOOS=windows GOARCH=amd64
- `go vet main.go`: PASS
- GUI executable: `AI_SIL_Test_Workbench_v0.9.5.exe`
- Debug executable: `AI_SIL_Test_Workbench_v0.9.5_debug.exe`
