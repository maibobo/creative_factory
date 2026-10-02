# v0.9.9 Build Info — AI Service Settings

## Main change

AI provider credentials and model selection have been moved out of the Test Requirement card into a dedicated **设置 → AI 服务** window.

## AI Service configuration

The settings window contains:

- Provider: OpenAI / DeepSeek / GLM
- API Endpoint
- API Key (memory-only; never written to config/log files)
- Planner Model
- CodeGen Model
- Repair Model
- Diagnosis Model
- `测试连接并获取模型`

The model fields are editable combo boxes. Provider presets are supplied before connection; when the provider supports a model-list endpoint, Workbench attempts to discover the models visible to the supplied key and populates the selectors.

## Connection verification

`测试连接并获取模型` performs two checks:

1. Attempts model discovery using the configured provider/key.
2. Performs a minimal inference request with the selected Planner model.

If model discovery succeeds, all four selected role model IDs must be present in the returned model list. Connection status is only retained when the saved configuration matches the exact tested configuration.

Changing Provider / Endpoint / API Key / any role model after a successful test invalidates the previous verification and the main workbench returns to `○ 未验证` until tested again.

## Main workbench

The Test Requirement card now shows only a compact summary such as:

```text
AI 服务
GPT / OpenAI · gpt-5.6-luna · ● 已连接      [配置]
```

No API key is displayed on the main workbench.

## Role-specific models

- Planner Model: natural language -> TestPlan
- CodeGen Model: initial AI SIL Harness generation
- Repair Model: Bundle/Compiler repair iterations
- Diagnosis Model: evidence-grounded diagnosis

## Build validation

- `GOOS=windows GOARCH=amd64 go vet main.go`: PASS
- Windows GUI build: PASS
- Windows debug build: PASS
- Main EXE: PE32+ Windows GUI x86-64
- Control-ID duplicate scan: PASS (no duplicate numeric IDs)

Main executable: `AI_SIL_Test_Workbench_v0.9.9.exe`
Debug executable: `AI_SIL_Test_Workbench_v0.9.9_debug.exe`
