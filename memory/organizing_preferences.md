# Organizing Preferences

- On Ubuntu aarch64, X11-sensitive desktop tools should prefer system binaries over Linuxbrew when both exist, especially `redshift`.
- When a Linuxbrew package shadows a working system binary and is not needed elsewhere, prefer removing the package over adding defensive logic to the autostart script.
- For window-manager helper scripts invoked via `~/.config/scripts/*`, prefer always installing the script and preserving its executable bit even when the runtime backend is not yet installed.
- For AwesomeWM network widgets on Ubuntu aarch64, prefer matching predictable interface names for both wired `enp*` and wireless `wlp*` devices.
- For hardware-specific AwesomeWM widgets, prefer runtime detection and complete hiding when the underlying device is absent, rather than showing placeholder values.
- When debugging AwesomeWM behavior, verify both the repo copy and the live `~/.config/awesome` copy, because repo fixes do not affect the running session until they are synced and Awesome is reloaded.
- `memory/` 和 `logs/trace.md` 中的新增记录统一使用中文，除非我明确被要求保留英文。
- 当用户要求统一记录语言时，优先把现有 `logs/trace.md` 历史记录一并回写成中文，而不是只约束后续新增内容。
- 对于这个 dotfiles 仓库中的 AwesomeWM 行为回归，保留 `tests/` 目录下的轻量 shell 测试比删除更合适。
- 对 `install.sh` 里的 `redshift` 处理，保留缺失检查即可；缺失时只提示用户手动安装，不要在安装脚本里自动执行提权安装。
- 对 rofi 配置，优先让 `config.rasi` 只保留行为配置并显式引用 `theme.rasi`；输入框相关布局保持显式 `children`，中文环境下为 `entry`/`element-text`/`textbox` 指定可显示 CJK 的字体，并在 Awesome 拉起 rofi 时显式传递 `LC_CTYPE` 与 fcitx 环境变量。
- 对 rofi 的缩放，优先通过 `em` 这类相对单位让窗口宽度、间距、圆角、图标尺寸跟随字体度量；当前会话若已通过 `Xft.dpi` 控制字体缩放，就不要再额外为 rofi 单独硬编码一套 DPI 倍率。
- 对 `tests/` 目录里预期直接以 `tests/foo.sh` 方式运行的 shell 回归脚本，保持可执行位，避免验证阶段再被权限问题打断。
- 在当前 Ubuntu aarch64 + rofi 1.7.1 环境里，rofi theme 的实数 `em` 距离值不可靠；缩放优先回退到 `px` 距离，并在 `config.rasi` 中固定 `dpi: 1`。
- 当 rofi 在 `LANG/LC_ALL/LC_CTYPE=zh_CN.UTF-8` 与 fcitx 环境下仍无法输入中文时，先视为当前 rofi 版本能力边界，不要继续只靠主题或 Awesome 启动参数盲改。
- 在当前这套 rofi `px + dpi: 1` 配置上，字体默认应比 `12.5` 再小一档；优先使用基础/中文字体 `11.5`、提示粗体 `12`。
- 当用户要求把当前桌面配置改动提交到 GitHub 时，优先先复跑轻量回归测试，并确认仓库文件与 live `~/.config` 已同步，再执行提交和推送。
