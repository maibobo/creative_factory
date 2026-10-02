# Evidence-Driven Rule Engine v0.9.15

## Responsibility boundary

`AI CodeGen -> evidence collector`

`Host Rule Engine -> functional Observed PASS/FAIL`

`TestPlan Expected + Observed -> Case PASS/FAIL`

`AI Diagnosis -> explanation only`

For `gpio_toggle_pattern`, generated C no longer owns the functional verdict.

## Protocol

Per cycle:

```text
@SIL,EVIDENCE,gpio_toggle_pattern,PB.0,normal,1,HIGH,1,1
@SIL,EVIDENCE,gpio_toggle_pattern,PB.0,normal,1,LOW,0,0
```

After N cycles:

```text
@SIL,EVIDENCE_SUMMARY,gpio_toggle_pattern,PB.0,normal,toggles=10,final=0,errors=0
```

The host rejects protocol-shape violations as Harness errors. A correctly shaped evidence stream can still produce a functional FAIL when observed values differ from requested values.

## Example host PASS

With 10 cycles, all 20 readbacks match, summary reports `toggles=10,final=0,errors=0`:

```text
Host Observed = PASS
TestPlan Expected = PASS
Case = PASS
```

## Example host functional FAIL

```text
@SIL,EVIDENCE,gpio_toggle_pattern,PB.0,normal,2,HIGH,1,0
```

The generated code did not say FAIL. The host rule records:

```text
failed rule: toggle_2_high requested=1 observed=0
Host Observed = FAIL
```

Then the existing baseline-aware logic may run `ai_test_gpio PB.0` to distinguish a bad generated ruler from a foundational GPIO/SIL failure.

## Example Harness protocol failure

If generated firmware emits:

```text
@SIL,GEN_RESULT,gpio_toggle_pattern,PB.0,normal,PASS,...
```

for an evidence-owned revision, the host reports `LEGACY_SELF_VERDICT_REJECTED`, invalidates that Harness revision, and regenerates it. The DUT is not graded from that result.
