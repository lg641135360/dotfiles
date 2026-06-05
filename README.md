# dotfiles

个人跨平台配置仓库。安装脚本采用复制部署，不使用 symlink；已有目标会先备份。

## tools

- shared
  - alacritty
  - tmux
  - git
  - nvim（submodule）
  - zsh（部署到 `~/.config/zsh`）
  - ssh
  - Claude Code statusline
- macOS
  - aerospace（window manager）
  - rift（window manager）
  - ssh
  - Homebrew Brewfile / defaults
- linux
  - awesome（window manager）
  - niri（Wayland compositor，parallel trial）
  - Waybar / Mako / Fuzzel（niri status bar / notification / launcher）
  - rofi（launcher）
  - picom（compositor）
  - X11 / Xresources
  - dunst（notification）
  - xmonad / xmobar
  - lock / rofi / Wayland helper scripts

## how to use

```shell
chmod +x install.sh
./install.sh
```

The installer copies configs instead of symlinking them. When `claude` and `jq`
are available, it also installs `.config/shared/cc/statusline.sh` to
`~/.config/cc/statusline.sh` and points `~/.claude/settings.json` at that
command.
