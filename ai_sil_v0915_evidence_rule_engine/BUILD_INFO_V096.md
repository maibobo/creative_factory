# AI SIL Test Workbench v0.9.6 — Reliable SIL Protocol

This release keeps the v0.9.5 UI and test semantics, and fixes intermittent GPIO input TIMEOUTs caused by host/RT-Thread command synchronization.

## Reliability changes

- Replaced fixed 100/120 ms sleeps in AI TestPlan execution with ACK-driven ordering.
- `sil_reset` must now receive `@SIL,RESET,GPIO,OK` before the case proceeds.
- Fault injection must receive the matching `@SIL,FAULT,gpio,<fault>` ACK before the test command is sent.
- The result waiter no longer silently discards a non-matching GPIO result.
- Kind / pin / fault mismatches are surfaced as `PROTOCOL_MISMATCH` instead of misleading `TIMEOUT`.
- A true `TIMEOUT` now means RESET and FAULT synchronization succeeded, but no matching `@SIL,RESULT` arrived in the result window.
- Protocol parsing now recognizes `@SIL,...` even when an MSH prompt is on the same physical line, e.g. `msh >@SIL,RESET,GPIO,OK`.
- Protocol errors are preserved in execution snapshots, AI-diagnosis evidence payloads, the matrix detail view, and HTML reports.

## Intended INPUT_NORMAL sequence

```text
sil_reset
  -> @SIL,RESET,GPIO,OK
sil_gpio_fault_none
  -> @SIL,FAULT,gpio,none
ai_test_gpio_input PB.0
  -> @SIL,CASE,GPIO_INPUT_001,...
  -> @SIL,RESULT,GPIO_INPUT,PB.0,...,none,...
```

No fixed sleep is used between RESET, FAULT and test execution in the AI TestPlan path.

## Build verification

- GOOS=windows GOARCH=amd64
- `go vet main.go`: PASS
- GUI executable: `AI_SIL_Test_Workbench_v0.9.6.exe`
- Debug executable: `AI_SIL_Test_Workbench_v0.9.6_debug.exe`
- Mock executable rebuilt: `Mock_QEMU_Console.exe`
