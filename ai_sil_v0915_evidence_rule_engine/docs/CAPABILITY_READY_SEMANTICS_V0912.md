# Capability READY vs Functional Test Verdict — v0.9.12

## Principle

Generated test code and the driver-under-test have different lifecycle states and must not share one `FAIL`.

### Infrastructure states

- **BUILD ERROR**: generated harness cannot compile/link. Formal test is `NOT RUN`.
- **CAPABILITY ERROR**: QEMU/RT-Thread cannot start the generated command/protocol path. Formal test is `NOT RUN`.
- **CAPABILITY READY**: harness compiled, command is callable, and `@SIL` protocol is alive.

### Functional states

Only after `CAPABILITY READY` does Workbench execute real Test Cases. The deterministic Rule Engine compares observed functional result against the TestPlan expectation and reports **TEST PASS / TEST FAIL**.

A functional mismatch never causes the generated harness to be rolled back merely to obtain a PASS.

## Protocol boundary

`@SIL,AI_SMOKE,<capability>,...` is a compatibility/readiness protocol. New generated code must use it only to prove infrastructure readiness.

`@SIL,GEN_RESULT,<capability>,<target>,<scenario>,PASS|FAIL,<detail>` carries the functional observation used by the formal test.

For backward compatibility, an old harness may still emit `AI_SMOKE ... FAIL ...` after performing a functional check. v0.9.12 records the detail as a hint but still considers the command/protocol path READY, then runs the formal Test Case.
