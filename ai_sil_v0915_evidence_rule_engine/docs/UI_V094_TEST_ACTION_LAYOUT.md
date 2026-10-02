# UI v0.9.4 — Test Action Layout

The test action is no longer a global upper-right command. It is colocated with the natural-language requirement because both `Plan Preview` and `Run` operate on that requirement.

Visible hierarchy:

```text
Engineering Resources
  Project / Firmware / QEMU

Engineering Controls
  Analyze / Build / Start QEMU / Stop / Preflight

Pipeline Status
  Engineering Prep -> Build -> QEMU -> Execute -> Result

Test Requirement
  requirement editor
  AI provider/model
  [Plan only] [Plan+Run / Run current plan]
```

Action labels are state-aware:

```text
No plan:
  仅生成测试计划 | AI规划并运行

Current valid plan:
  重新生成计划 | 运行当前计划

Requirement changed:
  warning: 当前 TestPlan 基于旧需求
```

The backend test semantics, GPIO SIL capability flow, QEMU control, Build flow, rule engine, and AI diagnosis are unchanged.
