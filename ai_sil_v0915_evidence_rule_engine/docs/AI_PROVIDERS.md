# AI provider adapters

The Workbench supports exactly three planner providers in this edition:

| Provider | Endpoint | Default model | Environment key fallback | Output handling |
|---|---|---|---|---|
| GPT / OpenAI | `https://api.openai.com/v1/responses` | `gpt-5.6-luna` | `OPENAI_API_KEY` | Responses API structured JSON Schema |
| DeepSeek | `https://api.deepseek.com/chat/completions` | `deepseek-flash` | `DEEPSEEK_API_KEY` | JSON Output (`json_object`) then semantic validation |
| GLM / Zhipu | `https://open.bigmodel.cn/api/paas/v4/chat/completions` | `glm-5-turbo` | `ZHIPUAI_API_KEY`, `GLM_API_KEY`, or `BIGMODEL_API_KEY` | JSON-only prompt contract then semantic validation |

## Unified contract

All three adapters return the same internal object:

```json
{
  "version": "1.0",
  "driver": "gpio",
  "target": "PB.0",
  "cases": [
    {"id":"GPIO_NORMAL","fault":"none","expected":"PASS","description":"normal write/readback"}
  ]
}
```

The Workbench validates driver, pin, case count, case IDs, supported fault names and expected functional result. Only after validation are plan rows converted to the fixed MSH command whitelist.

## Key handling

Keys entered in the GUI are kept only in process memory and are not written to Workbench logs. When Provider changes, the GUI clears the key field so a key is not accidentally sent to the wrong provider.

## Model handling

The model field is editable. Provider selection only supplies a practical default; it does not hard-code the user to that exact model ID.
