# Git 偏好

## 编辑器
- 默认编辑器固定为 `nvim`（`core.editor = nvim`）。

## Alias
- 优先把 oh-my-zsh git 插件未提供且跨 shell 有价值的命令放进 `.config/shared/git/config`。
- 当前用 `git subs` 查看 `submodule status`。
- README 中的 OMZ alias 必须按实际插件名（如 `grs`/`grst`）记录，避免写入不存在的短别名。

## Submodule
- 修改子模块内容时，提交前考虑是否同步该子模块自己的 README/使用文档；即使无需修改也应在验证/总结中说明。
