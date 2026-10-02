# v0.9.8 AI SIL Engineer

v0.9.8 adds the first constrained AI code-generation loop on top of the existing TestPlan / QEMU / Rule Engine workflow.

## When it appears

The `AI SIL 工程师 · 生成/修复代码` action is shown only when an AI TestPlan routes to `capability_missing`, except `gpio_input_readback`, which continues to use the safer built-in deterministic extension template.

## Closed loop

1. Analyze the selected RT-Thread project and matching `drivers/drv_*.c` source.
2. Send the driver/config context plus the original requirement to the connected AI provider.
3. AI returns a structured code bundle.
4. Workbench validates the bundle and only materializes files named `applications/ai_sil_ai_*.c/.h`.
5. Run a real RT-Thread Studio incremental Build.
6. On a generated-source compile failure, send the real compiler transcript plus the current generated bundle back to the AI for repair.
7. Retry up to 3 Build attempts.
8. If Build succeeds, restart QEMU with the fresh firmware and run the AI-generated smoke command.
9. The capability becomes READY only after `@SIL,AI_SMOKE,<capability>,PASS,...`.
10. Re-plan the original user requirement and execute it through the generated test command.

## Generated protocol contract

Generated code must register a MSH command with an `ai_sil_` prefix and accept:

```text
<test_command> <target> <scenario>
```

Each test invocation must emit:

```text
@SIL,GEN_RESULT,<capability>,<target>,<scenario>,PASS|FAIL,<detail>
```

Smoke verification must emit:

```text
@SIL,AI_SMOKE,<capability>,PASS|FAIL,<detail>
```

The host Rule Engine still owns the final TestPlan PASS/FAIL decision.

## Safety / engineering boundaries

Automatic AI modification is limited to:

```text
applications/ai_sil_ai_*.c
applications/ai_sil_ai_*.h
.ai_sil/generated/<capability>/...
```

The AI engineer does not automatically edit:

```text
main.c
drivers/drv_*.c
rtconfig.h
Kconfig
linker/startup/kernel files
```

Existing generated files are backed up under `.ai_sil/backups/` before replacement.

Automatic repair stops when the build transcript does not point to `ai_sil_ai_*` generated sources. This prevents an unrelated project/BSP error from causing AI to rewrite user code.

## Important limitation

AI code generation cannot guarantee an arbitrary missing capability becomes executable. A Build may succeed while the QEMU machine lacks the required virtual peripheral or the BSP/device registration is disabled. In that case the smoke test must report FAIL and the capability remains non-READY.

Binary-only firmware cannot use AI code generation because new C/H source must be rebuilt into the firmware. AI SIL Engineer therefore requires a source project.
