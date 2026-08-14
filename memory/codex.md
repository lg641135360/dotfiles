# Codex CLI 配置基线

> Codex CLI 的工具配置规格与版本特化经验。通用强制规则以 `AGENTS.md` 为准，通用工作流与环境偏好见 `memory/organizing_preferences.md`。

## 基线
- 模型 `gpt-5.5`，hook feature `[features].hooks = true`；若启用 `child_agents_md`，保留 `suppress_unstable_features_warning = true`。

## 0.130.0 GPT-5.5
- 用 `model_catalog_json` 指向本地 catalog override，固定 `context_window` / `max_context_window` / `auto_compact_token_limit`。
