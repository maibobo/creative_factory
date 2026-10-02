# v0.9.10 Build Info — Continuous AI Compiler Repair

Key changes:

- Removed fixed `maxAttempts = 3` compiler-repair limit.
- AI SIL Engineer now keeps rebuilding and repairing generated test code until Build PASS or a real stop condition is reached.
- The Stop button now requests cancellation of an active AI SIL Engineer loop.
- Bundle validation can also continue repairing malformed AI bundles until accepted, cancelled, or no progress is made.
- Added no-progress detection when an AI repair returns an unchanged bundle/source while validation/build is still failing.
- Existing project/BSP errors still stop automatic repair instead of letting AI modify unrelated source.
- Added generated-workspace snapshot/rollback so unsuccessful AI experiments do not leave broken `ai_sil_ai_*` files active in the project.
- Smoke Test is still mandatory after Build PASS before the capability becomes READY.

Validation performed:

- `GOOS=windows GOARCH=amd64 go vet main.go`
- Windows x64 GUI build
- Windows x64 debug build
- Mock QEMU console build
