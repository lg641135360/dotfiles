vim.cmd("let g:netrw_liststyle=3") -- Tree style

local opt = vim.opt

opt.relativenumber = true -- Show relative line numbers
opt.number = true -- Show absolute line number on cursor line (when relative number is on)

-- tabs & indentation
opt.tabstop = 4 -- Number of spaces tabs count for
opt.shiftwidth = 4 -- Size of an indent
opt.expandtab = true -- Use spaces instead of tabs
opt.autoindent = true -- Copy indent from current line when starting new one

opt.wrap = false -- Disable line wrap

-- search settings
opt.ignorecase = true -- Ignore case when searching
opt.smartcase = true -- Don't ignore case with capitals

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
