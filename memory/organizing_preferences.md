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
