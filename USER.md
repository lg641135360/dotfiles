# User Profile

> This file describes the user you serve. Update it as you learn more.

## Name

rikoo

## Preferences

- 使用中文记录 memory/ 和 logs/trace.md 的新增内容。当要求统一记录语言时，优先把现有 `logs/trace.md` 历史一并回写成中文，不只约束后续内容。
- 测试驱动开发（TDD）：改动前先补/更新测试。
- TypeScript 优先于 Python（Python 运行偏慢）。
- 读取持久化文件（memory/、logs/trace.md）时默认按关键词/主题局部检索，避免全量加载；只有用户明确要求完整历史或局部检索证据不足时才扩大范围。
- 修改快捷键、UI、启动入口等可感知行为时必须同步 README。

## Timezone

Asia/Shanghai (UTC+8)

## Context

- 维护 dotfiles 仓库，包含 Awesome WM / tmux / Neovim / Alacritty / rofi / zsh 等桌面配置。
- 主力机：Ubuntu aarch64（NVIDIA 桌面），外接 Dell P2722H 显示器。
- 使用 Awesome WM 作为窗口管理器，Alacritty 为默认终端，tmux 为终端复用器，Neovim 为主力编辑器。
- 配置采用分层结构：`.config/shared/` 共享配置，平台差异通过 `.config/linux/` 和 `.config/macos/` 区分。
- 偏好轻量、可回退、可验证的改动风格。
