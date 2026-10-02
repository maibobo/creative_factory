# AI SIL Test Workbench v0.9.8.2

## Fix: AI SIL Code Bundle schema recovery before Build

This release fixes the v0.9.8.1 failure where an AI-generated capability bundle could be rejected before Build with errors such as:

```text
AI generated bundle rejected by validator:
generated bundle driver "" does not match requested driver "gpio"
```

### Root cause
For chat-style providers, JSON mode guarantees valid JSON but does not necessarily guarantee that every required top-level field is present. A model could therefore omit host-known metadata such as `driver` while still returning valid JSON.

### Changes
- The validated TestPlan is now authoritative for `driver` and `capability`.
- If `version`, `driver`, or `capability` is omitted, Workbench safely restores only those already-known host fields before validation.
- A non-empty conflicting value is never overwritten. For example, requested `gpio` + returned `adc` is still rejected.
- The generation prompt now explicitly requires all top-level bundle keys:
  - `version`
  - `driver`
  - `capability`
  - `summary`
  - `test_command`
  - `smoke_command`
  - `scenarios`
  - `files`
- If the first bundle still fails validation, Workbench performs one bounded **pre-Build Bundle Repair** AI call.
- Bundle Repair happens before any generated file is materialized, so the project remains untouched during schema recovery.
- Compiler-driven repair remains a separate loop and still runs only after validated code has been materialized and Build fails.
- Build repair responses also receive safe host-metadata restoration for omitted fields.

### Safety behavior
- Empty/missing host-known metadata may be restored.
- Explicit semantic conflicts are rejected.
- Original project sources/config are still not automatically modified by AI.
- Generated files remain restricted to `applications/ai_sil_ai_*.c/.h`.
- Existing build-repair limit remains 3 attempts.

## Validation
- No duplicate Win32 command/control IDs.
- `GOOS=windows GOARCH=amd64 go vet main.go`: PASS.
- Windows x64 GUI build: PASS.
- Windows x64 debug build: PASS.
- Mock QEMU build: PASS.
