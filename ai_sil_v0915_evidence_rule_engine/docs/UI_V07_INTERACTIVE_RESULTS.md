# v0.7 Interactive Result / Matrix UI

This iteration keeps the v0.6 operator-first workbench layout and makes the result/evidence workflow interactive.

## Main changes

1. **Result state card**
   - The right-side result area now has a dedicated READY / RUNNING / PASS / FAIL / TIMEOUT state badge.
   - The headline explains the current case or plan-level outcome.
   - The detail pane remains available for full deterministic evidence and AI diagnosis text.

2. **Interactive regression matrix**
   - The former raw multiline matrix text is replaced by a selectable matrix list.
   - Each completed row shows: Case, Fault, Observed, Expected and Detection.
   - Selecting a row immediately updates the right-side evidence card.

3. **Case-level evidence**
   - GPIO rows expose functional verdict vs expected verdict separately.
   - Injected-fault cases can therefore show `Functional FAIL` while the regression detection result is `PASS`.
   - Driver call counters, HIGH/LOW readback and failed deterministic rules are shown for the selected case.
   - Timeout rows are surfaced explicitly rather than disappearing into a text summary.

4. **Summary state emphasis**
   - Run summary verdict changes visual emphasis for PASS / FAIL / RUNNING.
   - Plan-level result and selected-case result remain separate concepts.

## Safety / execution model unchanged

The LLM still does not execute shell/MSH directly. It produces a constrained TestPlan which is validated by the host and compiled to whitelisted commands. Deterministic rules remain the owner of PASS/FAIL; AI diagnosis only explains completed evidence.

## Current capability baseline

- GPIO output/readback: READY
- GPIO input/readback: auto-extendable
- GPIO none / stuck_low / stuck_high fault matrix: READY
- ADC/SPI/CAN/UART/etc.: not installed in this build
