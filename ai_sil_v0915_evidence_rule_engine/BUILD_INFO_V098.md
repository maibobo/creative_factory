# AI SIL Test Workbench v0.9.8

## Theme
AI SIL Engineer: constrained AI-generated test code + compiler-driven self-repair + QEMU smoke verification.

## New behavior
- Adds `AI SIL 工程师 · 生成/修复代码` for non-built-in `capability_missing` plans.
- Reads project/driver/config context and uses the currently selected GPT / DeepSeek / GLM provider to generate a structured code bundle.
- Generated files are restricted to `applications/ai_sil_ai_*.c/.h`.
- Saves source-of-truth bundle/manifest under `.ai_sil/generated/<capability>/` and backups under `.ai_sil/backups/`.
- Runs real RT-Thread Studio Build.
- Automatically sends the real build transcript back to AI for repair, maximum 3 attempts.
- Stops auto-repair if compiler errors do not reference AI-generated files.
- Build PASS is not enough: QEMU smoke must emit `@SIL,AI_SMOKE,...,PASS` before capability becomes READY.
- READY generated capabilities are exposed to AI Planner with an explicit scenario whitelist and test command.
- Original requirement is automatically re-planned and executed after smoke PASS.
- Generic generated tests use `@SIL,GEN_RESULT,...` and the host still owns final plan verdict.

## Existing paths retained
- Built-in GPIO Output remains unchanged.
- GPIO Input safe extension remains deterministic/template-based and does not use AI code generation.
- v0.9.7 paced UART + MSH echo verification is retained.

## Build validation
- GOOS=windows GOARCH=amd64 `go vet main.go`
- Windows x64 GUI executable built with `-H=windowsgui`
- Windows x64 debug executable built as console subsystem
- Mock QEMU console retained
