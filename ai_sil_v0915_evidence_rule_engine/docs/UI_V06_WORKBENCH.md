# v0.6 Workbench UI Notes

## Primary operator path

```text
Select / analyze project
  -> enter natural-language requirement
  -> AI 规划并运行
  -> inspect validated TestPlan
  -> inspect deterministic result / evidence
  -> review fault-matrix regression
  -> AI diagnosis / HTML report
```

## Information hierarchy

1. Header: AI / run status.
2. Environment strip: project, firmware, QEMU, SIL/build controls.
3. Run summary: cases, verdict, unexpected results, duration.
4. Main workspace: Requirement / TestPlan / Result.
5. Fault Matrix: batch evidence table-like output.
6. Logs: Build / UART / Agent; MSH stays in advanced-debug territory.

## Backend compatibility

This UI is built directly on the v0.5 `department_title` backend. The existing GPIO real-driver SIL path, capability router/builder, LLM provider adapters, QEMU runner, rule engine, diagnosis and HTML report code are retained.

The dedicated matrix pane is updated by both AI TestPlan execution and the fixed GPIO matrix runner. The summary cards are also updated after a plan or matrix completes.
