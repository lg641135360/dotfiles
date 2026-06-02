# Neovim 偏好

> 当前 Neovim 版本: 0.12

## 原生化迁移（0.12）
- 第一阶段最大限度保留现有体验，只清理重复/过时配置；启动、补全、搜索、文件树、诊断和 LSP 快捷键不回退即算成功。
- 替换 `blink.cmp`、`snacks.nvim`、`neo-tree`、`bufferline`、`lualine` 或从 `lazy.nvim` 迁移到 `vim.pack` 前必须单独确认。
- 后续迁移允许核心体验插件或插件管理器替换进入候选，强边界是不能破坏肌肉记忆键位和主要体验。
- `vim.pack`/插件管理器迁移切片优先只产出 PRD 与测试规格，不直接替换 `lazy.nvim`。

## 主题
- 使用 Catppuccin Mocha（`catppuccin/nvim`，`flavour = "mocha"`，非透明背景）。
- 不再保留 onedark 作为 active theme 或 lockfile 条目。

## LSP
- `vim.lsp.config()` / `vim.lsp.enable()` 是唯一 LSP server 启用权威。
- 移除裸 `gr` + `nowait`；references 入口迁到默认语义 `grr`。
- 保留 `<leader>rn`、`<leader>ca`、`K` 等已有入口。
- rename 使用 Neovim 原生 LSP rename（`grn` 与 LSP buffer-local `<leader>rn`），不再保留 `inc-rename.nvim`。
- 非 LSP buffer 不需要全局 `<leader>rn` rename 兜底。
- LSP 重启使用 0.12 原生 `:lsp restart ...`，不新增 `:LspRestart` 别名。
- Mason 非 headless 启动后自动补齐 `mason-tool-installer` 工具；headless 测试/脚本/smoke 跳过自动安装。

## 诊断
- 使用 0.12 原生 `vim.diagnostic.config()` 的 inline `virtual_text`（`virt_text_pos = "inline"`）。
- signs 关闭、float rounded、source `if_many`。
- 不再保留额外诊断显示插件。

## 快捷键
- 注释使用内置 `gc/gcc`；`Comment.nvim` 不覆盖这组快捷键。
- TOML/YAML/JSONC 等本身可注释配置文件应支持 `gcc`；标准 `.json` 不强制启用注释。
- 行移动/复制：普通模式只处理当前行，visual 选区处理整块多行；不新增插件、不改无关快捷键、尽量不污染寄存器。
- 位置历史导航：VSCode 风格 `Alt+Left`/`Alt+Right` 映射到 Vim jumplist 后退/前进。
- 保存：保留 `<leader>w`，增加 `<C-s>` 在普通/插入/可视模式快速保存。
- 关闭文件：`<leader>q` 表示 `:bdelete` 关闭当前 buffer，不是 `:q` 关闭窗口；真正退出使用 `:qa`/`:qall`。
- `<leader>q` 未保存时用 Snacks 浮动警告提示保存与强制关闭方式；保留 `:bdelete` 原生命令错误文本。
- 空 buffer 场景：若当前 buffer 是未命名、未修改的空 buffer，`<leader>q` 可直接退出 Neovim。
- 交互式 `:q`/`:quit` 也应优先走安全 buffer close 语义（复用 `:bdelete` 包装）。

## 搜索
- 保留 Snacks picker/ripgrep 主线。
- `<leader>fg` 全项目 grep、`<leader>fD` 当前文件目录 grep、`<leader>fd` 指定目录 grep。
- `<leader>fG` 引导式高级 grep：先选 regex/fixed string/whole word，再输入 include/exclude globs，最后可选补充 rg 参数。
- `<leader>ff` 默认包含隐藏文件/目录，不默认包含 gitignore ignored 项。

## 文件树
- Neo-tree 左侧 sidebar，宽度使用整数列数（当前 `width = 40`），不用小数比例。
- 保留 `<leader>e` 入口、follow current file、Git status、hidden/gitignored 可见性。
- Neo-tree 原生替换 POC 结论：当前 netrw 路线不能同时满足 follow current file 与 Git status parity，保留 Neo-tree。

## UI 体验
- Noice 窄配置只提供 `cmdline_popup`，不接管 notify、普通 messages、LSP hover 或 signature。
- Snacks notifier 警告弹窗保留 8 秒、使用更宽/可换行弹窗，保留 `<leader>nh` 查看 history。
- 浮动命令行窗口（`:`/`/`/`?`）属于保留肌肉记忆。

## CMake/clangd
- 轻量内置命令：`:CMakeUserPresetInit` → `CMakeUserPresets.json`，`:CMakeConfigure [preset]` → `build/compile_commands.json`。
- `:CMakeConfigure` 在已有 `CMakeUserPresets.json` 时优先使用存在的 configure preset。
- 远端 clangd 通过 `~/.local/bin/clangd` 软链暴露给 PATH；不把机器特定路径写进共享配置。

## 测试与 headless
- Headless 测试/脚本运行跳过 Mason tool installer 自动安装。
- `mason-lspconfig.nvim` 已不再作为 LSP 启用桥接；保留 `mason.nvim`/`mason-tool-installer.nvim` 作为工具链入口。

## nvim-autopairs
- native pairs 替代结论：可在基础 pairs、空 pair 删除、skip closing、括号内回车和 `blink.cmp` 兼容全部有测试护栏时删除。
- 后续保持 `lua/config/autopairs.lua` 为单文件最小 helper。

## AeroSpace 对齐
- macOS AeroSpace 与 Linux AwesomeWM 的 `Mod+q` 统一为"关闭当前聚焦窗口"。
- AeroSpace 中 `Mod` 使用 `alt`/Option，默认 `close`；最后一个窗口时 `close --quit-if-last-window`。
