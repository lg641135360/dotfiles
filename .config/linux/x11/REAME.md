# X11 配置文件

## 文件说明

| 文件/目录 | 说明 |
|----------|------|
| `xresources/` | Xft DPI、字体颜色等平台特定资源配置 |
| `xsessionrc` | X11 会话启动脚本，设置 IME/剪贴板/光标环境变量 |
| `xsessionrc.d/` | 会话配置模块目录 |
| `xsessionrc.d/cursor.2x` | 高 DPI (Xft.dpi=192) 光标配置，`XCURSOR_SIZE=48` |
| `xsessionrc.d/cursor.1x` | 标准 DPI (Xft.dpi=124) 光标配置，`XCURSOR_SIZE=32` |

## xsessionrc 设计

**问题背景**：Electron 应用（Chrome/VS Code）依赖 `XCURSOR_SIZE` 环境变量设置光标大小，不同平台的 DPI 差异导致需要不同的值。

**解决方案**：模块化设计
- `xsessionrc` 为通用主文件，设置 IME/SDK 相关环境变量
- 末尾条件加载 `~/.xsessionrc.d/cursor` 文件
- `install.sh` 按平台部署对应的 `cursor.2x` 或 `cursor.1x`

```bash
# xsessionrc 中
[ -f "$HOME/.xsessionrc.d/cursor" ] && . "$HOME/.xsessionrc.d/cursor"
```

**平台对应关系**
- `arch_x64` / `ubuntu_aarch64` → 部署 `cursor.2x` (XCURSOR_SIZE=48)
- `ubuntu_amd64` → 部署 `cursor.1x` (XCURSOR_SIZE=32)

### 环境变量说明

| 变量 | 值 | 用途 |
|------|-----|------|
| `GTK_IM_MODULE` | `fcitx` | GTK 应用（GNOME、xfce）输入法 |
| `QT_IM_MODULE` | `fcitx` | Qt 应用（KDE）输入法 |
| `XMODIFIERS` | `@im=fcitx` | 通用 X11 应用输入法 |
| `SDL_IM_MODULE` | `fcitx` | SDL2 游戏/应用输入法 |
| `GLFW_IM_MODULE` | `fcitx` | GLFW 库应用（编辑器、游戏）输入法 |
| `WEBKIT_DISABLE_DMABUF_RENDERER` | `1` | WebKit 硬件加速禁用（兼容性） |
| `XCURSOR_SIZE` | `32` 或 `48` | Electron 应用光标大小（平台特定） |

**依赖**：需要安装 `fcitx` 作为主输入法
```bash
# Arch Linux
sudo pacman -S fcitx fcitx-chinese-addons

# Ubuntu/Debian
sudo apt install fcitx fcitx-googlepinyin fcitx-sunpinyin
```

## 加载流程

```
X11 会话启动
  ↓
Awesome 作为窗口管理器启动
  ↓
~/.xsessionrc 被 X11 自动加载
  ↓
条件加载 ~/.xsessionrc.d/cursor
  ↓
Electron 应用读取 $XCURSOR_SIZE 环境变量
  ↓
光标大小自动适配平台 DPI
```

## Xresources

### 平台特定文件
- `xresources/arch_x64` — Catppuccin Mocha 主题，Xft.dpi=192
- `xresources/ubuntu_aarch64` — One Dark 主题，Xft.dpi=192
- `xresources/ubuntu_x64` — One Dark 主题，Xft.dpi=124

### 配置内容
- `Xft.dpi` — 字体 DPI，影响终端、GTK 应用的字体大小
- `cursorColor` — X11 终端光标颜色
- 主题色彩定义（base0x 调色板）

**注意**：Xresources 文件目前不通过 `install.sh` 自动部署，需要手动或通过其他方式部署到 `~/.Xresources`