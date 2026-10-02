# AI SIL Test Workbench v0.9.15 — Evidence-Driven Rule Engine

## Purpose

v0.9.15 removes the functional PASS/FAIL authority from the generated `gpio_toggle_pattern` C harness.

In v0.9.14 the generated firmware still emitted:

`@SIL,GEN_RESULT,gpio_toggle_pattern,<target>,normal,PASS|FAIL,<detail>`

That meant a generated harness could still self-grade its own functional test. v0.9.15 changes the first generated capability to a host-owned evidence rule profile.

## Host-owned rule profile

For `gpio_toggle_pattern`, the Workbench derives and stores an immutable manifest rule profile:

- `id = gpio_toggle_pattern_v1`
- `evidence_protocol = sil_evidence_v1`
- `toggle_count = <count parsed from the original requirement>`
- `require_readback_match = true`
- `final_level = 0 (LOW)`

The generated firmware cannot change this rule profile.

Existing READY `gpio_toggle_pattern` revisions created before v0.9.15 do not contain this rule profile and are therefore not advertised as READY. The next run routes through AI SIL Engineer and creates a fresh revision with the evidence contract.

## Functional evidence protocol

For each HIGH/LOW cycle the generated harness reports raw observations only:

`@SIL,EVIDENCE,gpio_toggle_pattern,<target>,<scenario>,<step>,HIGH,1,<observed>`

`@SIL,EVIDENCE,gpio_toggle_pattern,<target>,<scenario>,<step>,LOW,0,<observed>`

After all cycles it reports exactly one summary:

`@SIL,EVIDENCE_SUMMARY,gpio_toggle_pattern,<target>,<scenario>,toggles=<count>,final=<observed_final>,errors=<runtime_error_count>`

For this capability the validator rejects functional `@SIL,GEN_RESULT` output. `@SIL,AI_SMOKE` remains an infrastructure-only readiness probe.

## Host Rule Engine

The Workbench independently verifies:

1. exactly `2 * toggle_count` evidence frames are present;
2. frame order is step 1 HIGH, step 1 LOW, ... step N HIGH, step N LOW;
3. requested values are fixed by the host contract (`HIGH=1`, `LOW=0`);
4. every observed value equals the requested value;
5. summary `toggles` equals the host-owned count;
6. summary `final` matches the last LOW observation;
7. final level is LOW (`0`);
8. runtime error count is zero.

Only after those checks does the host compute the functional `Observed = PASS|FAIL`. The TestPlan comparison then computes the Case/Plan result.

The generated firmware does not get to emit a functional PASS/FAIL for `gpio_toggle_pattern`.

## Harness contract recovery

If a generated revision violates the evidence protocol (wrong frame identity/order/requested values, legacy self-verdict, malformed summary identity, etc.), the revision is marked `INVALID_HARNESS` and a fresh revision is generated automatically. No DUT verdict is produced from that protocol violation.

The v0.9.14 deterministic GPIO baseline remains active. If host-evaluated evidence says functional FAIL for an expected-PASS `gpio_toggle_pattern` case while `ai_test_gpio <same pin>` passes, the generated revision is invalidated and regenerated rather than declaring `drv_gpio.c` FAIL.

## Planner hardening

For the host-owned `gpio_toggle_pattern_v1` profile:

- target must be a canonical GPIO pin (`PA.0..PK.15`);
- `normal` scenario must have `Expected = PASS`;
- an older manifest without the host evidence profile is not considered READY.

This prevents the planner from changing the acceptance meaning to make a failing observation look successful.

## Scope

v0.9.15 introduces host-owned evidence evaluation for `gpio_toggle_pattern` first. Other generated capabilities remain on the legacy `GEN_RESULT` observation path until a deterministic host rule profile is implemented for them. This is intentional: unsupported rule semantics are not guessed.

## Validation

- `GO111MODULE=off GOOS=windows GOARCH=amd64 CGO_ENABLED=0 go vet agent_src/main.go` — PASS
- Windows x64 GUI build — PASS
- Windows x64 debug build — PASS
- Mock QEMU console x64 build — PASS
- ZIP integrity test — PASS
