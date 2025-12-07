vim.cmd("let g:netrw_liststyle=3") -- Tree style

local opt = vim.opt

opt.relativenumber = true -- Show relative line numbers
opt.number = true -- Show absolute line number on cursor line (when relative number is on)

-- tabs & indentation
opt.tabstop = 4 -- Number of spaces tabs count for
opt.shiftwidth = 4 -- Size of an indent
opt.expandtab = true -- Use spaces instead of tabs
opt.autoindent = true -- Copy indent from current line when starting new one
opt.smartindent = true -- Smart autoindenting on new line

opt.wrap = false -- Disable line wrap

-- search settings
opt.ignorecase = true -- Ignore case when searching
opt.smartcase = true -- Don't ignore case with capitals
opt.hlsearch = true -- Highlight search results
opt.incsearch = true -- Show search matches as you type

opt.cursorline = true -- Highlight the current cursor line

opt.termguicolors = true -- Enable 24-bit RGB colors
opt.background = "dark" -- Tell neovim to use a dark background
opt.signcolumn = "yes" -- Always show the sign column, otherwise it would shift the text each time

-- backspace
opt.backspace = "indent,eol,start" -- Allow backspace on indent, end of line and insert mode start position

-- clipboard
opt.clipboard:append("unnamedplus") -- Use system clipboard as default register

-- split windows
opt.splitright = true -- Split vertical window to the right
opt.splitbelow = true -- Split horizontal window to the bottom

-- performance & appearance
opt.updatetime = 250 -- Faster completion (default 4000ms)
opt.timeoutlen = 300 -- Faster key sequence completion
opt.scrolloff = 8 -- Keep 8 lines above/below cursor when scrolling
opt.sidescrolloff = 8 -- Keep 8 columns left/right of cursor when scrolling
opt.mouse = "a" -- Enable mouse support
opt.undofile = true -- Persistent undo
opt.swapfile = false -- Disable swap file
opt.backup = false -- Disable backup file
