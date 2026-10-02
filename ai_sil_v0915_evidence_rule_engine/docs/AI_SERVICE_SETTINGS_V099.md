# AI 服务设置 v0.9.9

v0.9.9 separates AI service configuration from test execution.

## Main UI

The requirement card only displays provider/model/connection summary and a configuration shortcut. TestPlan generation no longer doubles as a connection check.

## Settings flow

```text
设置
  -> AI 服务
      -> Provider
      -> Endpoint
      -> API Key
      -> Planner / CodeGen / Repair / Diagnosis models
      -> 测试连接并获取模型
      -> 保存
```

The API key is memory-only. Non-secret model and endpoint selections currently remain runtime configuration as well; no secret is written to disk.

## Connection states

- `○ 未验证`: configuration has not been tested, or changed since the last successful test.
- `● 已连接`: the exact saved configuration matches a successful connection test.
- `× 连接失败`: authentication, endpoint, model selection, network, or inference validation failed.

## Model discovery

When a provider exposes a compatible `/models` endpoint, Workbench retrieves the model IDs available to the current key and populates editable model selectors. If discovery is unavailable but minimal inference succeeds, the connection may still be used with a manually supplied model ID.
