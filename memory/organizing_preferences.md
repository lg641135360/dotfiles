# Organizing Preferences

> 通用/跨模块偏好与环境经验。本文件不定义通用硬约束；通用强制规则以 `AGENTS.md` 为准。模块特定偏好请参见对应分类文件：
> `awesome.md` / `nvim.md` / `tmux.md` / `rofi.md` / `alacritty.md` / `desktop.md` / `git.md`

## 通用工作流
- 当用户要求把当前桌面配置改动提交到 GitHub 时，通常优先先复跑轻量回归测试，并确认仓库文件与 live `~/.config` 已同步，再执行提交和推送。

## 系统环境
- 桌面环境相关的系统二进制优先级、包遮蔽处理和 helper 脚本策略见 `desktop.md` 的"其它"部分，此处不再重复。
- 对通过 `npm install -g` 安装到 `/usr/local/nodejs` 前缀的 CLI，在共享 zsh PATH 中追加 `/usr/local/nodejs/bin`。
- 对通过 `npm install -g` 安装到用户级 `/home/rikoo/.npm-global` 前缀的 CLI，在共享 zsh PATH 中追加 `$HOME/.npm-global/bin`。

## 仓库管理
- `.omx/` 属于本地 OMX 运行状态目录；按当前仓库惯例，通常放入 `.gitignore`，不进入远端仓库。
- Codex CLI 配置基线：模型 `gpt-5.5`，hook feature `[features].hooks = true`；若启用 `child_agents_md`，保留 `suppress_unstable_features_warning = true`。
- Codex CLI 0.130.0 GPT-5.5：用 `model_catalog_json` 指向本地 catalog override，固定 `context_window`/`max_context_window`/`auto_compact_token_limit`。
