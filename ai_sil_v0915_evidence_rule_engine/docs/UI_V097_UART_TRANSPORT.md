# v0.9.7 UART / MSH Transport Reliability

v0.9.7 does not change the visible TestPlan workflow. It hardens the transport between the Workbench and RT-Thread running in real QEMU.

## Why

A complete MSH command previously entered QEMU through the TCP-backed serial character device in one burst. In some runs the STM32 UART / guest receive path could lose characters, producing an echo such as:

```text
msh >ai_test_gpio_iut PB.0
```

instead of:

```text
msh >ai_test_gpio_input PB.0
```

The shell then correctly reported `command not found`, but the host used to observe only the absence of `@SIL,RESULT` and could report a misleading timeout.

## New behavior

Real QEMU:

```text
Host command
  -> paced UART bytes (2 ms/byte)
  -> MSH echo verification
     -> exact: continue
     -> mismatch: retry once at 5 ms/byte
     -> second mismatch: COMMAND_ECHO_MISMATCH
  -> SIL ACK / CASE / RESULT protocol
```

Mock_QEMU remains line-based because it is connected through a process pipe and intentionally does not echo stdin.
