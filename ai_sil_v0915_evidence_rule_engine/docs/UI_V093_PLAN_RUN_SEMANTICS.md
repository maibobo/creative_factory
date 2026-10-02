# v0.9.3 — TestPlan / Run semantics

The two user actions are intentionally different:

```text
仅生成测试计划
  Requirement -> AI Planner -> validated TestPlan -> stop

运行测试
  current TestPlan available and requirement unchanged
      -> execute current TestPlan
  no TestPlan
      -> generate TestPlan -> execute
  requirement changed after plan generation
      -> operator chooses:
         Yes    regenerate from new requirement and run
         No     run the currently displayed plan
         Cancel return without execution
```

A TestPlan stores the requirement snapshot that created it. Rule-engine evidence and exported run metadata use that snapshot when the operator explicitly runs the old plan.

Capability routing is still automatic. If the selected/current plan needs a safe auto-extendable GPIO Input capability, Run may install the capability, Build, re-route the same requirement once, and then execute. Unsupported capabilities remain blocked.
