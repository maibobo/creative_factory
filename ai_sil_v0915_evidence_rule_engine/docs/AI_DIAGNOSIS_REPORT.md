# AI Diagnosis and Report Contract

## Separation of responsibilities

- **Rule engine:** owns functional PASS/FAIL and plan/matrix verdicts.
- **LLM:** explains already-observed evidence and recommends follow-up checks.
- **Report exporter:** packages the plan, execution evidence, diagnosis, build output, UART output, and agent events.

The LLM must not override deterministic verdicts.

## Grounded evidence

The diagnostic request contains only host-produced facts:

- requirement and target pin
- controlled SIL fault for each case
- expected and observed functional verdict
- HIGH / LOW readback values
- GPIO mode/write/read call counts
- HAL mode and pull values
- error count and failed rules

The injected SIL fault is labelled as a controlled stimulus, not proof of a physical root cause.

## Report bundle

`Export HTML Report` creates a timestamped folder under `ai_sil_reports` in the RT-Thread project. `report.html` is self-contained and uses no external assets.
