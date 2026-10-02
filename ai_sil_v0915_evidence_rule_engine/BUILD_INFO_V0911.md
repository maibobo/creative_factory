# AI SIL Test Workbench v0.9.11 — Build Isolation

## Purpose
Prevents `.ai_sil` history/backup source copies from being discovered and compiled by RT-Thread Studio Managed Build.

## Build isolation rules
- The only live AI-generated C/H sources are `applications/ai_sil_ai_*.c/.h`.
- `.ai_sil/generated/<capability>/` stores `manifest.json` plus non-buildable `*.snapshot` history only.
- `.ai_sil/backups/.../` stores previous AI source versions as `*.snapshot`, never `.c/.h`.
- Legacy `.c/.h/.cpp/.s` files already under `.ai_sil` are automatically quarantined to `*.snapshot` before Build/AI SIL Engineer.
- Stale `Debug/.ai_sil` Managed Build fragments are removed and the headless workspace is re-imported when legacy source files are quarantined.

## Failure artifacts
On every AI-generated Build failure, Workbench writes diagnostics to:

`<project>/.ai_sil/last_failure/<capability>/`

- `reason.txt`
- `build.log`
- `bundle.json`

The exact path is also written to Agent Events.

## Existing `.ai_sil_backup`
`.ai_sil_backup` is the older reversible `drv_gpio.c.orig` backup used by the deterministic GPIO SIL hook. It is not part of the AI code-generation history and is intentionally left untouched.

## Validation
- `GOOS=windows GOARCH=amd64 go vet main.go` passed.
- Windows GUI x64 build passed.
- Windows debug/console x64 build passed.
- Mock QEMU console x64 build passed.
