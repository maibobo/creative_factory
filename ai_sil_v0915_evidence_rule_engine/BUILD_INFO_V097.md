# AI SIL Test Workbench v0.9.7 — Reliable QEMU UART Command Transport

This release keeps the v0.9.6 ACK-driven SIL protocol and fixes a lower-level transport failure observed on the real QEMU UART path: an MSH command could occasionally lose characters (for example `ai_test_gpio_input` arriving as `ai_test_gpio_iut`).

## Transport changes

- Real QEMU commands are no longer injected as one TCP burst.
- The QEMU UART path now sends command bytes at a conservative default pace of about **2 ms per byte**.
- Mock_QEMU remains unthrottled because it uses a reliable process pipe rather than the virtual STM32 UART path.
- Workbench parses the RT-Thread MSH command echo, including lines such as `msh >ai_test_gpio_input PB.0`.
- Every automated SIL command on the real QEMU path is echo-verified before its ACK/result is trusted.
- If the first echo differs from the command that was sent, Workbench waits briefly and retries the command once at about **5 ms per byte**.
- If the retry echo is still wrong, execution stops with `COMMAND_ECHO_MISMATCH` instead of later reporting a misleading result timeout.
- If no echo is observed, execution stops with `COMMAND_ECHO_TIMEOUT`; it does not blindly duplicate the command.
- CRLF / LF / CR console output is normalized for protocol parsing.
- `@SIL,...` parsing from v0.9.6 remains supported even when the MSH prompt shares the same physical line.

## Case execution order

For a real QEMU GPIO input case the path is now:

```text
send sil_reset (paced)
  -> verify MSH echo
  -> wait @SIL,RESET,GPIO,OK

send sil_gpio_fault_<mode> (paced)
  -> verify MSH echo
  -> wait matching @SIL,FAULT,gpio,<mode>

send ai_test_gpio_input PB.0 (paced)
  -> verify MSH echo
  -> wait matching @SIL,RESULT
```

If the UART corrupts the final command, for example:

```text
expected: ai_test_gpio_input PB.0
received: ai_test_gpio_iut PB.0
```

Workbench retries once at the slower pacing rate. If the retry succeeds, the case continues normally. If it fails again, the case is recorded as a UART/MSH command transport error rather than a functional GPIO failure.

## Error semantics

- `*_COMMAND_ECHO_MISMATCH` — MSH received different command text even after retry.
- `*_COMMAND_ECHO_TIMEOUT` — command echo was not observed; command is not automatically duplicated.
- `RESET_ACK_TIMEOUT` — reset command echo was valid, but RESET ACK did not arrive.
- `FAULT_ACK_TIMEOUT` — fault command echo was valid, but FAULT ACK did not arrive.
- `RESULT_MISMATCH` — a result arrived for the wrong kind/pin/fault.
- `TIMEOUT` — command transport plus RESET/Fault synchronization succeeded, but no result arrived.

## Build verification

- `GOOS=windows GOARCH=amd64`
- `go vet main.go`: PASS
- GUI executable: `AI_SIL_Test_Workbench_v0.9.7.exe`
- Debug executable: `AI_SIL_Test_Workbench_v0.9.7_debug.exe`
- `Mock_QEMU_Console.exe`: rebuilt
- Echo parser sanity-check covers correct echo, corrupted echo, bare prompt and prompt+`@SIL` cases.
