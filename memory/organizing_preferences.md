# Organizing Preferences

> 通用/跨模块偏好与环境经验。本文件不定义通用硬约束；通用强制规则以 `AGENTS.md` 为准。模块特定偏好请参见对应分类文件：
> `awesome.md` / `nvim.md` / `tmux.md` / `rofi.md` / `alacritty.md` / `desktop.md` / `git.md`

## 通用工作流
- 当用户要求把当前桌面配置改动提交到 GitHub 时，通常优先先复跑轻量回归测试，并确认仓库文件与 live `~/.config` 已同步，再执行提交和推送。
- 对 `install.sh` 里的 `redshift` 处理，通常保留缺失检查即可；缺失时只提示用户手动安装，不要在安装脚本里自动执行提权安装。

## 记录语言
- 默认偏好是 `memory/` 和 `logs/trace.md` 的新增记录统一使用中文，除非明确被要求保留英文。
- 当用户要求统一记录语言时，优先把现有 `logs/trace.md` 历史记录一并回写成中文，而不是只约束后续新增内容。

## 持久化文件读取
- 读取 `logs/trace.md` 或其它持久化文件时，默认优先按当前问题做关键词/相近主题的局部检索，避免每次全量加载带来额外耗时。
- 只有用户明确要求完整历史、任务确实依赖全局时间线，或局部检索证据不足时，才扩大读取范围。

## 系统环境
- 在 Ubuntu aarch64 上，X11-sensitive 桌面工具通常优先使用系统二进制（尤其是 `redshift`）。
- 当 Linuxbrew 包遮蔽工作系统二进制且不需要时，通常优先删除包，而不是加防御逻辑。
- Window manager helper 脚本（`~/.config/scripts/*`）通常保持始终安装并保留可执行位，即使 runtime backend 未安装。
- 对通过 `npm install -g` 安装到 `/usr/local/nodejs` 前缀的 CLI，在共享 zsh PATH 中追加 `/usr/local/nodejs/bin`。
- 对通过 `npm install -g` 安装到用户级 `/home/rikoo/.npm-global` 前缀的 CLI，在共享 zsh PATH 中追加 `$HOME/.npm-global/bin`。

## 仓库管理
- `.omx/` 属于本地 OMX 运行状态目录；按当前仓库惯例，通常放入 `.gitignore`，不进入远端仓库。
- Codex CLI 配置基线：模型 `gpt-5.5`，hook feature `[features].hooks = true`；若启用 `child_agents_md`，保留 `suppress_unstable_features_warning = true`。
- Codex CLI 0.130.0 GPT-5.5：用 `model_catalog_json` 指向本地 catalog override，固定 `context_window`/`max_context_window`/`auto_compact_token_limit`。
