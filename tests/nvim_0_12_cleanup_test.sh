#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
NVIM="$ROOT/.config/shared/nvim"
out_file="$(mktemp)"
data_home="$(mktemp -d)"
state_home="$(mktemp -d)"
cache_home="$(mktemp -d)"
keymap_check="$(mktemp)"
quit_command_check="$(mktemp)"
line_edit_check="$(mktemp)"
lsp_check="$(mktemp)"
ui_check="$(mktemp)"
active_spec_check="$(mktemp)"
diagnostics_check="$(mktemp)"
theme_check="$(mktemp)"
statusline_check="$(mktemp)"
tabline_check="$(mktemp)"
cmake_check="$(mktemp)"
neo_tree_parity_check="$(mktemp)"
autopairs_check="$(mktemp)"
lock_file="$NVIM/lazy-lock.json"
lock_backup="$(mktemp)"

cp "$lock_file" "$lock_backup"

cleanup() {
  cp "$lock_backup" "$lock_file"
  rm -rf "$out_file" "$data_home" "$state_home" "$cache_home" "$keymap_check" "$quit_command_check" "$line_edit_check" "$lsp_check" "$ui_check" "$active_spec_check" "$diagnostics_check" "$theme_check" "$statusline_check" "$tabline_check" "$cmake_check" "$neo_tree_parity_check" "$autopairs_check"
  rm -f "$lock_backup"
}
trap cleanup EXIT

mkdir -p "$data_home/nvim"
if [[ -d "$HOME/.local/share/nvim/lazy" ]]; then
  ln -s "$HOME/.local/share/nvim/lazy" "$data_home/nvim/lazy"
fi
if [[ -d "$HOME/.local/share/nvim/mason" ]]; then
  ln -s "$HOME/.local/share/nvim/mason" "$data_home/nvim/mason"
fi
if [[ -f "$HOME/.cache/nvim/mason-registry-update" ]]; then
  mkdir -p "$cache_home/nvim"
  cp "$HOME/.cache/nvim/mason-registry-update" "$cache_home/nvim/mason-registry-update"
fi

cat >"$keymap_check" <<'LUA'
local function describe(mode, lhs)
  local mapping = vim.fn.maparg(lhs, mode, false, true)
  local mapped = mapping.lhs ~= nil and mapping.lhs ~= ""
  print(
    ("KEYMAP_INVENTORY mode=%s lhs=%s mapped=%s rhs=%s callback=%s desc=%s nowait=%s sid=%s"):format(
      mode,
      lhs,
      tostring(mapped),
      tostring(mapping.rhs),
      tostring(mapping.callback ~= nil),
      tostring(mapping.desc),
      tostring(mapping.nowait),
      tostring(mapping.sid)
    )
  )
  return mapping, mapped
end

local function require_mapped(mode, lhs)
  local mapping, mapped = describe(mode, lhs)
  if not mapped then
    error(("missing %s mode mapping for %s"):format(mode, lhs))
  end
  return mapping
end

local function require_rhs_contains(mode, lhs, text)
  local mapping = require_mapped(mode, lhs)
  local rhs = tostring(mapping.rhs or "")
  if not rhs:find(text, 1, true) then
    error(("%s in %s mode should contain %s, got %s"):format(lhs, mode, text, rhs))
  end
end

local function require_callback(mode, lhs)
  local mapping = require_mapped(mode, lhs)
  if type(mapping.callback) ~= "function" then
    error(("%s in %s mode should be a callback mapping"):format(lhs, mode))
  end
  return mapping
end

local function require_desc_contains(mode, lhs, text)
  local mapping = require_mapped(mode, lhs)
  local desc = tostring(mapping.desc or "")
  if not desc:find(text, 1, true) then
    error(("%s in %s mode should have desc containing %s, got %s"):format(lhs, mode, text, desc))
  end
end

for _, lhs in ipairs({ "gr", "grn", "gra", "grr", "gri", "grt", "grx", "gO" }) do
  local mapping = vim.fn.maparg(lhs, "n", false, true)
  print(
    ("KEYMAP %s lhs=%s rhs=%s callback=%s nowait=%s sid=%s"):format(
      lhs,
      tostring(mapping.lhs),
      tostring(mapping.rhs),
      tostring(mapping.callback ~= nil),
      tostring(mapping.nowait),
      tostring(mapping.sid)
    )
  )
end

for _, lhs in ipairs({
  "<leader><PageDown>",
  "<leader><PageUp>",
  "<A-Left>",
  "<A-Right>",
  "<leader>c",
  "<leader><Left>",
  "<leader><Down>",
  "<leader><Up>",
  "<leader><Right>",
  "<leader>w",
  "<C-s>",
  "<leader>q",
  "<C-a>",
  "<C-c>",
  "<C-x>",
  "<C-v>",
  "vv",
  "vc",
  "vl",
  "<leader>e",
  "<leader>ft",
  "<leader>ff",
  "<leader>fg",
  "<leader>xx",
  "<leader>o",
}) do
  require_mapped("n", lhs)
end

for i = 1, 9 do
  require_callback("n", "<leader>" .. i)
  require_desc_contains("n", "<leader>" .. i, "Go to buffer " .. i)
end

for _, lhs in ipairs({ "<C-c>", "<C-x>", "<C-v>", "<Tab>", "<S-Tab>", "<C-s>" }) do
  require_mapped("v", lhs)
end

require_mapped("i", "<C-s>")
require_rhs_contains("n", "<C-s>", "write")
require_rhs_contains("i", "<C-s>", "write")
require_rhs_contains("v", "<C-s>", "write")
require_desc_contains("n", "<C-s>", "Save file")
require_desc_contains("i", "<C-s>", "Save file")
require_desc_contains("v", "<C-s>", "Save file")

require_callback("n", "<leader><PageDown>")
require_desc_contains("n", "<leader><PageDown>", "Next buffer")
require_callback("n", "<leader><PageUp>")
require_desc_contains("n", "<leader><PageUp>", "Previous buffer")
require_callback("n", "<A-Left>")
require_desc_contains("n", "<A-Left>", "Jump back")
require_callback("n", "<A-Right>")
require_desc_contains("n", "<A-Right>", "Jump forward")
require_rhs_contains("n", "<leader>c", "bdelete")
require_callback("n", "<leader>q")
require_desc_contains("n", "<leader>q", "Close current buffer")
require_callback("n", "<leader>tb")
require_desc_contains("n", "<leader>tb", "native tabline")
require_rhs_contains("n", "<leader>e", "Neotree toggle")
require_callback("n", "<leader>ft")
require_callback("n", "<leader>ff")
require_desc_contains("n", "<leader>ff", "Find Files")
require_callback("n", "<leader>fg")
require_desc_contains("n", "<leader>fg", "Find Grep")
require_callback("n", "<leader>xx")
require_desc_contains("n", "<leader>xx", "Diagnostics quickfix")
require_callback("n", "<leader>o")
require_desc_contains("n", "<leader>o", "Document symbols")

print("KEYMAP_INVENTORY_OK=true")
LUA

cat >"$quit_command_check" <<'LUA'
local function command_exists(name)
  return vim.fn.exists(":" .. name)
end

local function assert_equal(actual, expected, label)
  if actual ~= expected then
    error(("%s: expected %s, got %s"):format(label, expected, actual))
  end
end

assert_equal(command_exists("BufferClose"), 2, "BufferClose user command")

local abbrev_q = vim.fn.execute("cnoreabbrev q")
local abbrev_quit = vim.fn.execute("cnoreabbrev quit")
print("COMMAND_Q_ABBREV=" .. abbrev_q:gsub("\n", " "))
print("COMMAND_QUIT_ABBREV=" .. abbrev_quit:gsub("\n", " "))
if not abbrev_q:find("*", 1, true) or not abbrev_q:find("BufferClose", 1, true) then
  error(":q should be an exact command-line abbreviation to BufferClose")
end
if not abbrev_quit:find("*", 1, true) or not abbrev_quit:find("BufferClose", 1, true) then
  error(":quit should be an exact command-line abbreviation to BufferClose")
end

local tmp = vim.fn.tempname()
vim.fn.writefile({ "safe quit command" }, tmp)
vim.cmd.edit(vim.fn.fnameescape(tmp))

local initial_buf = vim.api.nvim_get_current_buf()
local initial_name = vim.api.nvim_buf_get_name(initial_buf)
local keys = vim.api.nvim_replace_termcodes(":q<CR>", true, false, true)
vim.api.nvim_feedkeys(keys, "xt", false)

print("COMMAND_Q_STILL_RUNNING=true")
print("COMMAND_Q_INITIAL_NAME=" .. initial_name)
print("COMMAND_Q_CURRENT_NAME=" .. vim.api.nvim_buf_get_name(0))
print("COMMAND_Q_BUFFER_CHANGED=" .. tostring(vim.api.nvim_get_current_buf() ~= initial_buf))
print("COMMAND_Q_INITIAL_BUFLISTED=" .. tostring(vim.fn.buflisted(initial_buf)))
vim.fn.delete(tmp)
LUA

cat >"$line_edit_check" <<'LUA'
local function assert_equal(actual, expected, label)
  if actual ~= expected then
    error(("%s: expected %s, got %s"):format(label, expected, actual))
  end
end

local function assert_lines(expected, label)
  local actual = vim.api.nvim_buf_get_lines(0, 0, -1, false)
  assert_equal(table.concat(actual, "\n"), table.concat(expected, "\n"), label)
end

local function assert_cursor(line, label)
  assert_equal(vim.api.nvim_win_get_cursor(0)[1], line, label)
end

local function assert_register(label)
  assert_equal(vim.fn.getreg('"'), "keep-register", label)
end

local function escape()
  vim.cmd("normal! " .. vim.api.nvim_replace_termcodes("<Esc>", true, false, true))
end

local function setup_buffer(lines, cursor_line)
  escape()
  vim.api.nvim_buf_set_lines(0, 0, -1, false, lines)
  vim.api.nvim_win_set_cursor(0, { cursor_line, 0 })
  vim.fn.setreg('"', "keep-register")
end

local function select_lines(start_line, end_line)
  escape()
  vim.api.nvim_win_set_cursor(0, { start_line, 0 })
  vim.cmd("normal! V")
  vim.api.nvim_win_set_cursor(0, { end_line, 0 })
end

local function callback(mode, lhs)
  local mapping = vim.fn.maparg(lhs, mode, false, true)
  print(("LINE_KEYMAP mode=%s lhs=%s callback=%s"):format(mode, lhs, tostring(mapping.callback ~= nil)))
  if type(mapping.callback) ~= "function" then
    error(("missing callback mapping for %s in %s mode"):format(lhs, mode))
  end
  return mapping.callback
end

local n_up = callback("n", "<A-Up>")
local n_down = callback("n", "<A-Down>")
local n_jump_back = callback("n", "<A-Left>")
local n_jump_forward = callback("n", "<A-Right>")
local n_copy_up = callback("n", "<S-A-Up>")
local n_copy_down = callback("n", "<S-A-Down>")
local x_up = callback("x", "<A-Up>")
local x_down = callback("x", "<A-Down>")
local x_copy_up = callback("x", "<S-A-Up>")
local x_copy_down = callback("x", "<S-A-Down>")

setup_buffer({ "one", "two", "three" }, 2)
n_up()
assert_lines({ "two", "one", "three" }, "normal Alt-Up should move current line up")
assert_cursor(1, "normal Alt-Up should follow moved line")
assert_register("normal Alt-Up should not touch unnamed register")

setup_buffer({ "one", "two", "three" }, 2)
n_down()
assert_lines({ "one", "three", "two" }, "normal Alt-Down should move current line down")
assert_cursor(3, "normal Alt-Down should follow moved line")
assert_register("normal Alt-Down should not touch unnamed register")

setup_buffer({ "one", "two", "three", "four", "five", "six", "seven", "eight", "nine", "ten" }, 1)
vim.cmd.normal({ bang = true, args = { "G" } })
assert_cursor(10, "normal G should seed a jumplist entry for Alt-Left")
n_jump_back()
assert_cursor(1, "normal Alt-Left should jump back through the jumplist")
n_jump_forward()
assert_cursor(10, "normal Alt-Right should jump forward through the jumplist")
assert_register("normal Alt-Left/Right should not touch unnamed register")

setup_buffer({ "one", "two", "three" }, 2)
n_copy_up()
assert_lines({ "one", "two", "two", "three" }, "normal Shift-Alt-Up should duplicate current line above original")
assert_cursor(2, "normal Shift-Alt-Up should place cursor on copied line")
assert_register("normal Shift-Alt-Up should not touch unnamed register")

setup_buffer({ "one", "two", "three" }, 2)
n_copy_down()
assert_lines({ "one", "two", "two", "three" }, "normal Shift-Alt-Down should duplicate current line below original")
assert_cursor(3, "normal Shift-Alt-Down should place cursor on copied line")
assert_register("normal Shift-Alt-Down should not touch unnamed register")

setup_buffer({ "one", "two" }, 1)
n_up()
assert_lines({ "one", "two" }, "normal Alt-Up should be a no-op at first line")
assert_cursor(1, "normal Alt-Up boundary should keep cursor")
assert_register("normal Alt-Up boundary should not touch unnamed register")

setup_buffer({ "one", "two" }, 2)
n_down()
assert_lines({ "one", "two" }, "normal Alt-Down should be a no-op at last line")
assert_cursor(2, "normal Alt-Down boundary should keep cursor")
assert_register("normal Alt-Down boundary should not touch unnamed register")

setup_buffer({ "one", "two", "three", "four" }, 1)
select_lines(2, 3)
x_up()
assert_lines({ "two", "three", "one", "four" }, "visual Alt-Up should move selected lines up")
assert_cursor(1, "visual Alt-Up should follow moved block")
assert_register("visual Alt-Up should not touch unnamed register")

setup_buffer({ "one", "two", "three", "four" }, 1)
select_lines(1, 2)
x_down()
assert_lines({ "three", "one", "two", "four" }, "visual Alt-Down should move selected lines down")
assert_cursor(2, "visual Alt-Down should follow moved block")
assert_register("visual Alt-Down should not touch unnamed register")

setup_buffer({ "one", "two", "three", "four" }, 1)
select_lines(2, 3)
x_copy_up()
assert_lines({ "one", "two", "three", "two", "three", "four" }, "visual Shift-Alt-Up should duplicate selected lines above original")
assert_cursor(2, "visual Shift-Alt-Up should place cursor on copied block")
assert_register("visual Shift-Alt-Up should not touch unnamed register")

setup_buffer({ "one", "two", "three", "four" }, 1)
select_lines(2, 3)
x_copy_down()
assert_lines({ "one", "two", "three", "two", "three", "four" }, "visual Shift-Alt-Down should duplicate selected lines below original")
assert_cursor(4, "visual Shift-Alt-Down should place cursor on copied block")
assert_register("visual Shift-Alt-Down should not touch unnamed register")
LUA


cat >"$cmake_check" <<'LUA'
local commands = {
  CMakeUserPresetInit = vim.fn.exists(":CMakeUserPresetInit"),
  CMakeConfigure = vim.fn.exists(":CMakeConfigure"),
}
for name, exists in pairs(commands) do
  print(("CMAKE_COMMAND %s=%s"):format(name, tostring(exists)))
end

local function write(path, lines)
  vim.fn.mkdir(vim.fn.fnamemodify(path, ":h"), "p")
  vim.fn.writefile(lines, path)
end

local temp_root = vim.fn.tempname()
local fake_bin = vim.fs.joinpath(temp_root, "bin")
local fake_cmake = vim.fs.joinpath(fake_bin, "cmake")
local cmake_log = vim.fs.joinpath(temp_root, "cmake.log")
vim.fn.mkdir(fake_bin, "p")
write(vim.fs.joinpath(temp_root, "CMakeLists.txt"), { "cmake_minimum_required(VERSION 3.20)", "project(nvim_cmake_test)" })
write(vim.fs.joinpath(temp_root, "CMakeUserPresets.json"), {
  "{",
  '  "version": 3,',
  '  "configurePresets": [',
  '    { "name": "linux-base", "generator": "Ninja", "binaryDir": "${sourceDir}/build" }',
  "  ],",
  '  "buildPresets": [',
  '    { "name": "linux-build", "configurePreset": "linux-base" }',
  "  ]",
  "}",
})
write(fake_cmake, {
  "#!/bin/sh",
  ("printf 'cwd=%%s\\nargs=%%s\\n' \"$PWD\" \"$*\" > %q"):format(cmake_log),
  "exit 0",
})
vim.fn.setfperm(fake_cmake, "rwxr-xr-x")

vim.env.PATH = fake_bin .. ":" .. vim.env.PATH
vim.cmd.cd(vim.fn.fnameescape(temp_root))
vim.cmd.enew()

vim.cmd.CMakeConfigure()
vim.wait(1000, function()
  return vim.uv.fs_stat(cmake_log) ~= nil
end, 20)
local default_log = table.concat(vim.fn.readfile(cmake_log), "\n")
print("CMAKE_DEFAULT_PRESET_LOG=" .. default_log:gsub("\n", " "))

vim.fn.delete(cmake_log)
vim.cmd.CMakeConfigure("linux-build")
vim.wait(1000, function()
  return vim.uv.fs_stat(cmake_log) ~= nil
end, 20)
local build_log = table.concat(vim.fn.readfile(cmake_log), "\n")
print("CMAKE_BUILD_PRESET_LOG=" .. build_log:gsub("\n", " "))

local completion = table.concat(vim.fn.getcompletion("CMakeConfigure ", "cmdline"), ",")
print("CMAKE_PRESET_COMPLETION=" .. completion)
LUA

cat >"$lsp_check" <<'LUA'
vim.api.nvim_exec_autocmds("BufReadPre", { modeline = false })

local servers = { "lua_ls", "clangd", "pyright", "ts_ls" }
for _, name in ipairs(servers) do
  local config = vim.lsp.config[name]
  print(
    ("LSP_CONFIG %s enabled=%s has_config=%s"):format(
      name,
      tostring(vim.lsp.is_enabled(name)),
      tostring(config ~= nil)
    )
  )
end

local capabilities = vim.lsp.config.lua_ls and vim.lsp.config.lua_ls.capabilities
local completion_item = capabilities
  and capabilities.textDocument
  and capabilities.textDocument.completion
  and capabilities.textDocument.completion.completionItem
print("LSP_CAP_SNIPPET=" .. tostring(completion_item and completion_item.snippetSupport))

local lua_ls = vim.lsp.config.lua_ls
print(
  "LSP_LUA_CHECK_THIRD_PARTY="
    .. tostring(
      lua_ls
        and lua_ls.settings
        and lua_ls.settings.Lua
        and lua_ls.settings.Lua.workspace
        and lua_ls.settings.Lua.workspace.checkThirdParty
    )
)

local lua_settings = lua_ls and lua_ls.settings and lua_ls.settings.Lua or {}
print("LSP_LUA_RUNTIME=" .. tostring(lua_settings.runtime and lua_settings.runtime.version))

local has_vim_global = false
local globals = lua_settings.diagnostics and lua_settings.diagnostics.globals or {}
for _, global in ipairs(globals) do
  if global == "vim" then
    has_vim_global = true
  end
end
print("LSP_LUA_GLOBAL_VIM=" .. tostring(has_vim_global))

local library_count = 0
local has_vimruntime = false
local library = lua_settings.workspace and lua_settings.workspace.library or {}
for _, path in pairs(library) do
  library_count = library_count + 1
  if path == vim.env.VIMRUNTIME then
    has_vimruntime = true
  end
end
print("LSP_LUA_LIBRARY_COUNT=" .. tostring(library_count))
print("LSP_LUA_LIBRARY_VIMRUNTIME=" .. tostring(has_vimruntime))

local clangd_cmd = vim.lsp.config.clangd and table.concat(vim.lsp.config.clangd.cmd or {}, " ") or ""
print("LSP_CLANGD_CMD=" .. clangd_cmd)
print("LSP_NATIVE_COMMAND=" .. tostring(vim.fn.exists(":lsp")))
local ok_bare_lsp = pcall(vim.cmd, "lsp")
print("LSP_BARE_COMMAND_OK=" .. tostring(ok_bare_lsp))

local pyright = vim.lsp.config.pyright
print(
  "LSP_PYRIGHT_TYPECHECK="
    .. tostring(
      pyright
        and pyright.settings
        and pyright.settings.python
        and pyright.settings.python.analysis
        and pyright.settings.python.analysis.typeCheckingMode
    )
)
LUA

cat >"$ui_check" <<'LUA'
local diagnostic = vim.diagnostic.config()
local float = diagnostic.float or {}
local virtual_text = diagnostic.virtual_text or {}

print("UI_WINBORDER=" .. vim.o.winborder)
print("UI_PUMBORDER=" .. vim.o.pumborder)
print("UI_DIAGNOSTIC_SIGNS=" .. tostring(diagnostic.signs))
print("UI_DIAGNOSTIC_FLOAT_BORDER=" .. tostring(float.border))
print("UI_DIAGNOSTIC_FLOAT_SOURCE=" .. tostring(float.source))
print("UI_DIAGNOSTIC_VIRTUAL_TEXT=" .. type(diagnostic.virtual_text))
print("UI_DIAGNOSTIC_VTEXT_POS=" .. tostring(virtual_text.virt_text_pos))
print("UI_DIAGNOSTIC_VTEXT_SOURCE=" .. tostring(virtual_text.source))
print("UI_DIAGNOSTIC_VLINES=" .. tostring(diagnostic.virtual_lines))
print("UI_DIAGNOSTIC_SEVERITY_SORT=" .. tostring(diagnostic.severity_sort))
LUA

cat >"$active_spec_check" <<'LUA'
local plugins = require("lazy.core.config").plugins or {}
local snacks = plugins["snacks.nvim"] or {}
local snacks_opts = type(snacks.opts) == "table" and snacks.opts or {}
local dashboard = type(snacks_opts.dashboard) == "table" and snacks_opts.dashboard or {}
local notifier = type(snacks_opts.notifier) == "table" and snacks_opts.notifier or {}
local notifier_width = type(notifier.width) == "table" and notifier.width or {}
local notifier_height = type(notifier.height) == "table" and notifier.height or {}
local styles = type(snacks_opts.styles) == "table" and snacks_opts.styles or {}
local notification_style = type(styles.notification) == "table" and styles.notification or {}
local notification_wo = type(notification_style.wo) == "table" and notification_style.wo or {}
local notification_history_style = type(styles.notification_history) == "table" and styles.notification_history or {}
local noice = plugins["noice.nvim"] or {}
local noice_opts = type(noice.opts) == "table" and noice.opts or {}
local noice_cmdline = type(noice_opts.cmdline) == "table" and noice_opts.cmdline or {}
local noice_messages = type(noice_opts.messages) == "table" and noice_opts.messages or {}
local noice_notify = type(noice_opts.notify) == "table" and noice_opts.notify or {}
local noice_lsp = type(noice_opts.lsp) == "table" and noice_opts.lsp or {}
local noice_hover = type(noice_lsp.hover) == "table" and noice_lsp.hover or {}
local noice_signature = type(noice_lsp.signature) == "table" and noice_lsp.signature or {}
print("SNACKS_DASHBOARD_ENABLED=" .. tostring(dashboard.enabled))
print("SNACKS_NOTIFIER_TIMEOUT=" .. tostring(notifier.timeout))
print("SNACKS_NOTIFIER_WIDTH_MIN=" .. tostring(notifier_width.min))
print("SNACKS_NOTIFIER_WIDTH_MAX=" .. tostring(notifier_width.max))
print("SNACKS_NOTIFIER_HEIGHT_MAX=" .. tostring(notifier_height.max))
print("SNACKS_NOTIFICATION_WRAP=" .. tostring(notification_wo.wrap))
print("SNACKS_NOTIFICATION_HISTORY_WIDTH=" .. tostring(notification_history_style.width))
print("SNACKS_NOTIFICATION_HISTORY_HEIGHT=" .. tostring(notification_history_style.height))
print("NOICE_CMDLINE_ENABLED=" .. tostring(noice_cmdline.enabled))
print("NOICE_CMDLINE_VIEW=" .. tostring(noice_cmdline.view))
print("NOICE_MESSAGES_ENABLED=" .. tostring(noice_messages.enabled))
print("NOICE_NOTIFY_ENABLED=" .. tostring(noice_notify.enabled))
print("NOICE_LSP_HOVER_ENABLED=" .. tostring(noice_hover.enabled))
print("NOICE_LSP_SIGNATURE_ENABLED=" .. tostring(noice_signature.enabled))
for _, name in ipairs({
  "Comment.nvim",
  "fidget.nvim",
  "lspsaga.nvim",
  "trouble.nvim",
  "noice.nvim",
  "aerial.nvim",
  "neoscroll.nvim",
  "header.nvim",
  "nvim-colorizer.lua",
  "nvim-treesitter",
  "nvim-treesitter-textobjects",
  "bufferline.nvim",
  "lspkind-nvim",
  "blink.cmp",
  "snacks.nvim",
  "nui.nvim",
  "mason-lspconfig.nvim",
  "lualine.nvim",
  "nvim-dap",
  "nvim-dap-ui",
  "nvim-nio",
  "smear-cursor.nvim",
  "catppuccin",
  "onedark.nvim",
  "neo-tree.nvim",
  "plenary.nvim",
  "nvim-web-devicons",
  "nvim-autopairs",
}) do
  print(("ACTIVE_PLUGIN %s=%s"):format(name, tostring(plugins[name] ~= nil)))
end
LUA

cat >"$neo_tree_parity_check" <<'LUA'
local plugins = require("lazy.core.config").plugins or {}
local mapping = vim.fn.maparg("<leader>e", "n", false, true)
print("NEOTREE_ACTIVE=" .. tostring(plugins["neo-tree.nvim"] ~= nil))
print("NEOTREE_COMMAND_EXISTS=" .. tostring(vim.fn.exists(":Neotree")))
print("NEOTREE_KEYMAP_LHS=" .. tostring(mapping.lhs))
print("NEOTREE_KEYMAP_RHS=" .. tostring(mapping.rhs))
print("NETRW_DISABLED=" .. tostring(vim.g.loaded_netrw == 1 and vim.g.loaded_netrwPlugin == 1))
LUA

cat >"$autopairs_check" <<'LUA'
local function termcodes(keys)
  return vim.api.nvim_replace_termcodes(keys, true, false, true)
end

local function feed(keys)
  vim.api.nvim_feedkeys(termcodes(keys), "xt", false)
  vim.cmd("redraw")
end

local plugins = require("lazy.core.config").plugins or {}
vim.cmd("enew!")
vim.api.nvim_buf_set_lines(0, 0, -1, false, { "" })
vim.api.nvim_win_set_cursor(0, { 1, 0 })
feed("i(x")
local line = vim.api.nvim_get_current_line()
local cr_mapping = vim.fn.maparg("<CR>", "i", false, true)
local tab_mapping = vim.fn.maparg("<Tab>", "i", false, true)
local stab_mapping = vim.fn.maparg("<S-Tab>", "i", false, true)
print("AUTOPAIRS_ACTIVE=" .. tostring(plugins["nvim-autopairs"] ~= nil))
print("AUTOPAIRS_NATIVE_BASIC=" .. tostring(line == "(x)"))
print("AUTOPAIRS_CR_DESC=" .. tostring(cr_mapping.desc))
print("AUTOPAIRS_TAB_DESC=" .. tostring(tab_mapping.desc))
print("AUTOPAIRS_STAB_DESC=" .. tostring(stab_mapping.desc))
LUA

cat >"$diagnostics_check" <<'LUA'
local mapping = vim.fn.maparg("<leader>xx", "n", false, true)
print("KEYMAP_LEADER_XX_LHS=" .. tostring(mapping.lhs))
print("KEYMAP_LEADER_XX_RHS=" .. tostring(mapping.rhs))
print("KEYMAP_LEADER_XX_DESC=" .. tostring(mapping.desc))
print("KEYMAP_LEADER_XX_CALLBACK=" .. tostring(mapping.callback ~= nil))
print("TROUBLE_COMMAND_EXISTS=" .. tostring(vim.fn.exists(":Trouble")))

if type(mapping.callback) ~= "function" then
  error("<leader>xx should be a native diagnostics callback")
end

local ns = vim.api.nvim_create_namespace("nvim_0_12_trouble_replacement_test")
vim.diagnostic.set(ns, 0, {
  {
    lnum = 0,
    col = 0,
    severity = vim.diagnostic.severity.WARN,
    message = "native quickfix diagnostic",
    source = "nvim-test",
  },
})

mapping.callback()
local qf = vim.fn.getqflist()
print("DIAGNOSTICS_QF_COUNT=" .. tostring(#qf))
print("DIAGNOSTICS_QF_TEXT=" .. tostring(qf[1] and qf[1].text or ""))
LUA


cat >"$tabline_check" <<'LUA'
vim.api.nvim_buf_set_name(0, "native-tabline-a.lua")
vim.cmd("enew")
vim.api.nvim_buf_set_name(0, "native-tabline-b.lua")
_G.nvim_native_buffer_goto(1)
local first = vim.api.nvim_buf_get_name(0)
_G.nvim_native_buffer_cycle(1)
local cycled = vim.api.nvim_buf_get_name(0)
local rendered = _G.nvim_native_tabline()
print("TABLINE_SHOW=" .. tostring(vim.o.showtabline))
print("TABLINE_EXPR=" .. tostring(vim.o.tabline))
print("TABLINE_GOTO_FIRST=" .. tostring(first:find("native%-tabline%-a%.lua") ~= nil))
print("TABLINE_CYCLE_CHANGED=" .. tostring(cycled ~= first))
print("TABLINE_HAS_ORDINAL=" .. tostring(rendered:find("1:", 1, true) ~= nil))
print("TABLINE_HAS_SELECTED=" .. tostring(rendered:find("%#TabLineSel#", 1, true) ~= nil))
print("TABLINE_HAS_FILE=" .. tostring(rendered:find("native-tabline", 1, true) ~= nil))
LUA

cat >"$theme_check" <<'LUA'
local plugins = require("lazy.core.config").plugins or {}
print("COLORSCHEME=" .. tostring(vim.g.colors_name))
print("THEME_CATPPUCCIN_ACTIVE=" .. tostring(plugins["catppuccin"] ~= nil))
print("THEME_ONEDARK_ACTIVE=" .. tostring(plugins["onedark.nvim"] ~= nil))
LUA

cat >"$statusline_check" <<'LUA'
vim.bo.filetype = "lua"
local ns = vim.api.nvim_create_namespace("nvim_0_12_statusline_test")
vim.diagnostic.set(ns, 0, {
  {
    lnum = 0,
    col = 0,
    severity = vim.diagnostic.severity.ERROR,
    message = "statusline diagnostic",
    source = "nvim-test",
  },
})
local rendered = _G.nvim_native_statusline()
print("STATUSLINE_LASTSTATUS=" .. tostring(vim.o.laststatus))
print("STATUSLINE_EXPR=" .. tostring(vim.o.statusline))
print("STATUSLINE_RENDER=" .. rendered)
print("STATUSLINE_HAS_MODE=" .. tostring(rendered:find("NORMAL", 1, true) ~= nil))
print("STATUSLINE_HAS_FILE=" .. tostring(rendered:find("%t", 1, true) ~= nil))
print("STATUSLINE_HAS_DIAG=" .. tostring(rendered:find("E:1", 1, true) ~= nil))
print("STATUSLINE_HAS_FILETYPE=" .. tostring(rendered:find("lua", 1, true) ~= nil))
print("STATUSLINE_HAS_POSITION=" .. tostring(rendered:find("%p%% %l:%c", 1, true) ~= nil))
LUA

require_pattern() {
  local pattern="$1"
  local file="$2"
  local message="$3"

  if ! rg -q -- "$pattern" "$file"; then
    echo "$message"
    exit 1
  fi
}

reject_pattern() {
  local pattern="$1"
  local file="$2"
  local message="$3"

  if rg -q -- "$pattern" "$file"; then
    echo "$message"
    exit 1
  fi
}

extract_snacks_keymap_block() {
  local lhs="$1"
  local desc="$2"
  local file="$3"

  awk -v lhs="\"${lhs}\"" -v desc="desc = \"${desc}\"" '
    index($0, lhs) { in_block = 1 }
    in_block { print }
    in_block && index($0, desc) { found = 1; exit }
    END { if (!found) exit 1 }
  ' "$file"
}

require_block_pattern() {
  local block="$1"
  local pattern="$2"
  local message="$3"

  if ! printf '%s\n' "$block" | rg -q -- "$pattern"; then
    echo "$message"
    printf '%s\n' "$block"
    exit 1
  fi
}

reject_block_pattern() {
  local block="$1"
  local pattern="$2"
  local message="$3"

  if printf '%s\n' "$block" | rg -q -- "$pattern"; then
    echo "$message"
    printf '%s\n' "$block"
    exit 1
  fi
}

assert_clean_nvim_output() {
  if rg -n "Error in command line|Error detected while processing|stack traceback|EPERM|E5113|module .* not found" "$out_file"; then
    cat "$out_file"
    exit 1
  fi
}

run_nvim_luafile() {
  local script="$1"
  local label="$2"

  : >"$out_file"
  set +e
  XDG_CONFIG_HOME="$ROOT/.config/shared" \
    XDG_DATA_HOME="$data_home" \
    XDG_STATE_HOME="$state_home" \
    XDG_CACHE_HOME="$cache_home" \
    nvim --headless -i NONE -u "$NVIM/init.lua" \
      --cmd 'set noswapfile' \
      "+luafile $script" \
      '+qa!' >"$out_file" 2>&1
  local rc=$?
  set -e

  if [[ "$rc" -ne 0 ]]; then
    echo "$label failed"
    cat "$out_file"
    exit 1
  fi
  assert_clean_nvim_output
}

require_pattern 'saghen/blink.cmp' "$NVIM/lua/plugins/blink-cmp.lua" "blink.cmp must remain"
require_pattern '"<Tab>"' "$NVIM/lua/plugins/blink-cmp.lua" "blink.cmp should keep Tab completion/snippet behavior"
require_pattern '"<S-Tab>"' "$NVIM/lua/plugins/blink-cmp.lua" "blink.cmp should keep Shift-Tab completion/snippet behavior"
require_pattern '"<CR>"\] = \{ "accept", "fallback" \}' "$NVIM/lua/plugins/blink-cmp.lua" "blink.cmp should keep Enter accept/fallback behavior"
require_pattern 'rafamadriz/friendly-snippets' "$NVIM/lua/plugins/blink-cmp.lua" "friendly-snippets should remain active for snippets"
require_pattern 'L3MON4D3/LuaSnip' "$NVIM/lua/plugins/blink-cmp.lua" "LuaSnip should remain active for snippets"
require_pattern 'require\("config.autopairs"\)\.setup\(\)' "$NVIM/init.lua" "init.lua should load the native pairs helper"
require_pattern 'local open_to_close = \{' "$NVIM/lua/config/autopairs.lua" "native pairs helper should keep an explicit pair matrix"
require_pattern 'blink\.is_visible\(\)' "$NVIM/lua/config/autopairs.lua" "native pairs helper should defer visible-menu Enter to blink"
require_pattern 'blink\.accept\(\)' "$NVIM/lua/config/autopairs.lua" "native pairs helper should accept visible blink completion instead of inserting pair newline"
reject_pattern 'windwp/nvim-autopairs|nvim%-autopairs|nvim-autopairs' "$NVIM/lua/plugins" "nvim-autopairs plugin spec should be removed after native pairs replacement"
reject_pattern '"nvim-autopairs"' "$NVIM/lazy-lock.json" "nvim-autopairs should not remain in lazy-lock after native pairs replacement"
require_pattern 'native pairs helper' "$NVIM/README.md" "README should document the native pairs helper"
reject_pattern 'Editing.*nvim-autopairs|nvim-autopairs.*Editing' "$NVIM/README.md" "README Editing row should not list nvim-autopairs as active"
reject_pattern 'onsails/lspkind-nvim|require\("lspkind"\)' "$NVIM/lua/plugins" "lspkind-nvim should be removed after inline completion icon cleanup"
reject_pattern '"lspkind-nvim"' "$NVIM/lazy-lock.json" "lspkind-nvim should not remain in lazy-lock after inline completion icon cleanup"
require_pattern 'local kind_icons = \{' "$NVIM/lua/plugins/blink-cmp.lua" "blink-cmp should define local completion kind icons after lspkind removal"
require_pattern 'kind_icons\[ctx\.kind\]' "$NVIM/lua/plugins/blink-cmp.lua" "blink-cmp should use the local kind icon map"
require_pattern 'nvim-web-devicons' "$NVIM/lua/plugins/blink-cmp.lua" "blink-cmp should keep devicons for path completion icons"
require_pattern 'folke/snacks.nvim' "$NVIM/lua/plugins/snacks.lua" "snacks.nvim must remain"
ff_files_block="$(extract_snacks_keymap_block '<leader>ff' 'Find Files' "$NVIM/lua/plugins/snacks.lua")" || {
  echo "<leader>ff Find Files keymap block should exist in snacks.lua"
  exit 1
}
require_block_pattern "$ff_files_block" 'Snacks\.picker\.files' "<leader>ff should call Snacks.picker.files"
require_block_pattern "$ff_files_block" 'hidden = true' "<leader>ff files picker should include hidden files/directories by default"
require_block_pattern "$ff_files_block" 'ignored = false' "<leader>ff files picker should keep ignored/gitignored files disabled by default"
reject_block_pattern "$ff_files_block" 'ignored = true' "<leader>ff files picker must not enable ignored/gitignored files by default"
reject_pattern 'grep_with_ripgrep_args|grep_in_directory|grep_current_file_directory|<leader>fG|<leader>fd|<leader>fD' "$NVIM/lua/plugins/snacks.lua" "advanced grep helpers should not be active until reintroduced deliberately"
require_pattern 'dashboard = \{ enabled = false \}' "$NVIM/lua/plugins/snacks.lua" "snacks dashboard should be disabled for native startup"
require_pattern 'timeout = 8000' "$NVIM/lua/plugins/snacks.lua" "snacks notifier should keep warnings visible long enough to read"
require_pattern 'width = \{ min = 50, max = 0\.7 \}' "$NVIM/lua/plugins/snacks.lua" "snacks notifier should use a wider notification window"
require_pattern 'notification = \{' "$NVIM/lua/plugins/snacks.lua" "snacks notification style should be customized"
require_pattern 'wrap = true' "$NVIM/lua/plugins/snacks.lua" "snacks notifications should wrap long warning text"
require_pattern 'notification_history = \{' "$NVIM/lua/plugins/snacks.lua" "snacks notification history style should be customized"
require_pattern 'nvim-neo-tree/neo-tree.nvim' "$NVIM/lua/plugins/neo-tree.lua" "neo-tree.nvim must remain"
require_pattern 'enable_git_status = true' "$NVIM/lua/plugins/neo-tree.lua" "neo-tree should keep Git status visible after native parity POC"
require_pattern 'follow_current_file = \{' "$NVIM/lua/plugins/neo-tree.lua" "neo-tree should keep follow_current_file configured"
require_pattern 'enabled = true, -- 自动展开并聚焦当前文件' "$NVIM/lua/plugins/neo-tree.lua" "neo-tree should keep current-file follow enabled"
require_pattern 'visible = true' "$NVIM/lua/plugins/neo-tree.lua" "neo-tree should keep hidden file visibility enabled"
require_pattern 'hide_dotfiles = false' "$NVIM/lua/plugins/neo-tree.lua" "neo-tree should keep dotfiles visible"
require_pattern 'hide_gitignored = false' "$NVIM/lua/plugins/neo-tree.lua" "neo-tree should keep gitignored files visible"
require_pattern 'position = "left"' "$NVIM/lua/plugins/neo-tree.lua" "neo-tree should keep the left sidebar position"
require_pattern 'width = 40' "$NVIM/lua/plugins/neo-tree.lua" "neo-tree sidebar width should be an integer column count"
reject_pattern 'width = 0\.[0-9]+' "$NVIM/lua/plugins/neo-tree.lua" "neo-tree sidebar width must not be fractional because nvim_win_set_width requires an integer"
require_pattern 'vim\.g\.loaded_netrw = 1' "$NVIM/lua/config/options.lua" "netrw should stay disabled while Neo-tree remains the file-tree provider"
require_pattern 'vim\.g\.loaded_netrwPlugin = 1' "$NVIM/lua/config/options.lua" "netrwPlugin should stay disabled while Neo-tree remains the file-tree provider"
require_pattern 'nvim-treesitter/nvim-treesitter' "$NVIM/lua/plugins/ui.lua" "nvim-treesitter core should remain for syntax highlighting"
reject_pattern 'nvim-treesitter/nvim-treesitter-textobjects|nvim-treesitter-textobjects' "$NVIM/lua/plugins" "nvim-treesitter-textobjects should be removed because no textobjects are configured"
reject_pattern '"nvim-treesitter-textobjects"' "$NVIM/lazy-lock.json" "nvim-treesitter-textobjects should not remain in lazy-lock after cleanup"
require_pattern '"nvim-treesitter"' "$NVIM/lazy-lock.json" "nvim-treesitter core should remain pinned"
reject_pattern 'akinsho/bufferline.nvim|BufferLine' "$NVIM/lua/plugins" "bufferline.nvim should be removed after native tabline replacement"
reject_pattern '"bufferline.nvim"' "$NVIM/lazy-lock.json" "bufferline.nvim should not remain in lazy-lock after native tabline replacement"
require_pattern '_G\.nvim_native_tabline' "$NVIM/lua/config/options.lua" "native tabline function should be defined in options.lua"
require_pattern 'vim\.opt\.tabline = "%!v:lua\.nvim_native_tabline\(\)"' "$NVIM/lua/config/options.lua" "tabline should use native Lua tabline expression"
require_pattern 'vim\.opt\.showtabline = 2' "$NVIM/lua/config/options.lua" "native tabline should stay visible by default"
require_pattern 'nvim_native_buffer_goto' "$NVIM/lua/config/keymaps.lua" "buffer ordinal keymaps should use native buffer goto helper"
require_pattern 'nvim_native_buffer_cycle' "$NVIM/lua/config/keymaps.lua" "buffer cycle keymaps should use native buffer cycle helper"
reject_pattern 'BufferLine' "$NVIM/lua/config/keymaps.lua" "keymaps should not call BufferLine after native tabline replacement"
reject_pattern 'stevearc/aerial.nvim|AerialToggle|require\("aerial"\)' "$NVIM/lua/plugins" "aerial.nvim should be removed after native document symbols replacement"
reject_pattern 'karb94/neoscroll.nvim|require\("neoscroll"\)' "$NVIM/lua/plugins" "neoscroll.nvim should be removed after native scrolling replacement"
reject_pattern 'attilarepka/header.nvim' "$NVIM/lua/plugins" "header.nvim should be removed after header automation cleanup"
reject_pattern 'catgoose/nvim-colorizer.lua' "$NVIM/lua/plugins" "nvim-colorizer.lua should be removed after color preview cleanup"
reject_pattern '"aerial.nvim"' "$NVIM/lazy-lock.json" "aerial.nvim should not remain in lazy-lock after native document symbols replacement"
reject_pattern '"neoscroll.nvim"' "$NVIM/lazy-lock.json" "neoscroll.nvim should not remain in lazy-lock after native scrolling replacement"
reject_pattern '"header.nvim"' "$NVIM/lazy-lock.json" "header.nvim should not remain in lazy-lock after header automation cleanup"
reject_pattern '"nvim-colorizer.lua"' "$NVIM/lazy-lock.json" "nvim-colorizer.lua should not remain in lazy-lock after color preview cleanup"
require_pattern 'vim\.lsp\.buf\.document_symbol' "$NVIM/lua/config/keymaps.lua" "<leader>o should use native LSP document symbols"
reject_pattern 'nvim-lualine/lualine.nvim|require\(\"lualine|lualine\.setup' "$NVIM/lua/plugins" "lualine.nvim should be removed after native statusline replacement"
reject_pattern '"lualine.nvim"' "$NVIM/lazy-lock.json" "lualine.nvim should not remain in lazy-lock after native statusline replacement"
require_pattern '_G\.nvim_native_statusline' "$NVIM/lua/config/options.lua" "native statusline function should be defined in options.lua"
require_pattern 'vim\.opt\.statusline = "%!v:lua\.nvim_native_statusline\(\)"' "$NVIM/lua/config/options.lua" "statusline should use native Lua statusline expression"
require_pattern 'vim\.opt\.laststatus = 3' "$NVIM/lua/config/options.lua" "native statusline should keep global laststatus=3"
require_pattern '"nvim-web-devicons"' "$NVIM/lazy-lock.json" "nvim-web-devicons should remain pinned for neo-tree and avante"
require_pattern 'folke/noice.nvim' "$NVIM/lua/plugins/noice.lua" "noice.nvim should provide the preferred floating command-line popup"
require_pattern 'view = "cmdline_popup"' "$NVIM/lua/plugins/noice.lua" "Noice should use the cmdline popup view for ':'"
require_pattern 'messages = \{ enabled = false \}' "$NVIM/lua/plugins/noice.lua" "Noice should not take over regular messages"
require_pattern 'notify = \{ enabled = false \}' "$NVIM/lua/plugins/noice.lua" "Snacks should remain the notification UI instead of Noice"
require_pattern 'hover = \{ enabled = false \}' "$NVIM/lua/plugins/noice.lua" "Noice should not take over LSP hover"
require_pattern 'signature = \{ enabled = false \}' "$NVIM/lua/plugins/noice.lua" "Noice should not take over LSP signature help"
require_pattern '"noice.nvim"' "$NVIM/lazy-lock.json" "noice.nvim should be pinned for the floating command-line popup"
require_pattern '"nui.nvim"' "$NVIM/lazy-lock.json" "nui.nvim should remain pinned because neo-tree and avante still depend on it"
require_pattern 'MunifTanjim/nui.nvim' "$NVIM/lua/plugins/neo-tree.lua" "neo-tree should continue to declare nui.nvim dependency"
require_pattern 'MunifTanjim/nui.nvim' "$NVIM/lua/plugins/avante.lua" "avante should continue to declare nui.nvim dependency"
require_pattern 'nvim-tree/nvim-web-devicons' "$NVIM/lua/plugins/neo-tree.lua" "neo-tree should continue to declare nvim-web-devicons dependency"
require_pattern 'nvim-tree/nvim-web-devicons' "$NVIM/lua/plugins/avante.lua" "avante should continue to declare nvim-web-devicons dependency"
if [[ ! -e "$NVIM/lua/plugins/noice.lua" ]]; then
  echo "noice.lua should exist for the preferred floating command-line popup"
  exit 1
fi
if [[ -e "$NVIM/lua/plugins/inline-diagno.lua" ]]; then
  echo "tiny-inline-diagnostic plugin spec should be removed"
  exit 1
fi
if [[ -e "$NVIM/lua/plugins/renamer.lua" ]]; then
  echo "inc-rename plugin spec should be removed"
  exit 1
fi

reject_pattern 'tiny-inline-diagnostic|tiny%-inline%-diagnostic|tiny_inline' "$NVIM/lua/plugins" "tiny-inline-diagnostic references should not remain in plugin specs"
reject_pattern 'tiny-inline-diagnostic\.nvim' "$NVIM/lazy-lock.json" "tiny-inline-diagnostic should not remain in lazy-lock after plugin removal"
reject_pattern 'inc-rename\.nvim|inc_rename|IncRename' "$NVIM/lua/plugins" "inc-rename references should not remain in plugin specs"
reject_pattern 'inc-rename\.nvim' "$NVIM/lazy-lock.json" "inc-rename should not remain in lazy-lock after plugin removal"
reject_pattern '"Comment.nvim"' "$NVIM/lazy-lock.json" "Comment.nvim should not remain in lazy-lock after removal"
reject_pattern '"fidget.nvim"' "$NVIM/lazy-lock.json" "fidget.nvim should not remain as an unexplained lock-only plugin"
reject_pattern '"lspsaga.nvim"' "$NVIM/lazy-lock.json" "lspsaga.nvim should not remain as an unexplained lock-only plugin"
reject_pattern '"trouble.nvim"' "$NVIM/lazy-lock.json" "trouble.nvim should not remain in lazy-lock after native diagnostics quickfix replacement"
reject_pattern 'folke/trouble.nvim|cmd = "Trouble"' "$NVIM/lua/plugins" "Trouble plugin spec should be removed after native diagnostics quickfix replacement"
reject_pattern ':Trouble diagnostics toggle|Trouble diagnostics' "$NVIM/lua/config/keymaps.lua" "<leader>xx should not call Trouble after native diagnostics quickfix replacement"
require_pattern 'vim\.diagnostic\.setqflist' "$NVIM/lua/config/keymaps.lua" "<leader>xx should use native vim.diagnostic.setqflist"
require_pattern '<C-s>' "$NVIM/lua/config/keymaps.lua" "Ctrl-S should be mapped as a quick save key"
require_pattern '<cmd>write<CR>' "$NVIM/lua/config/keymaps.lua" "Ctrl-S should save through a mode-safe write command"
require_pattern 'local function close_current_buffer' "$NVIM/lua/config/keymaps.lua" "<leader>q should use a wrapper to protect modified buffers"
require_pattern 'local function is_empty_unnamed_buffer' "$NVIM/lua/config/keymaps.lua" "<leader>q should detect empty unnamed buffers"
require_pattern 'vim\.cmd\.quit' "$NVIM/lua/config/keymaps.lua" "<leader>q should quit Neovim from an empty unnamed buffer"
require_pattern 'pcall\(vim\.cmd\.bdelete\)' "$NVIM/lua/config/keymaps.lua" "<leader>q wrapper should preserve bdelete errors"
require_pattern 'vim\.notify\(tostring\(err\), vim\.log\.levels\.WARN\)' "$NVIM/lua/config/keymaps.lua" "<leader>q wrapper should forward original bdelete errors to floating notifications"
require_pattern 'vim\.cmd\.bdelete' "$NVIM/lua/config/keymaps.lua" "<leader>q wrapper should close saved buffers with bdelete"
require_pattern 'nvim_create_user_command\("BufferClose"' "$NVIM/lua/config/keymaps.lua" "BufferClose command should reuse the safe buffer close wrapper"
require_pattern 'cnoreabbrev <expr> q .*BufferClose' "$NVIM/lua/config/keymaps.lua" ":q should be routed to BufferClose when typed exactly"
require_pattern 'cnoreabbrev <expr> quit .*BufferClose' "$NVIM/lua/config/keymaps.lua" ":quit should be routed to BufferClose when typed exactly"
reject_pattern '当前文件有未保存修改|已取消关闭|强制关闭并放弃修改|未保存修改' "$NVIM/lua/config/keymaps.lua" "<leader>q should not use custom unsaved-buffer wording"
reject_pattern '<leader>q.*:q<CR>|:q<CR>.*<leader>q' "$NVIM/lua/config/keymaps.lua" "<leader>q should not use :q because it can quit Neovim when closing the last window"
if [[ -e "$NVIM/lua/plugins/trouble.lua" ]]; then
  echo "trouble.lua should be removed after native diagnostics quickfix replacement"
  exit 1
fi
require_pattern 'require\("config.cmake"\)\.setup\(\)' "$NVIM/init.lua" "init.lua should register lightweight CMake commands"
require_pattern 'nvim_create_user_command\("CMakeUserPresetInit"' "$NVIM/lua/config/cmake.lua" "CMakeUserPresetInit command should exist"
require_pattern 'nvim_create_user_command\("CMakeConfigure"' "$NVIM/lua/config/cmake.lua" "CMakeConfigure command should exist"
require_pattern 'CMakeUserPresets.json' "$NVIM/lua/config/cmake.lua" "CMake helper should generate CMakeUserPresets.json"
require_pattern '"cmake", "--preset"' "$NVIM/lua/config/cmake.lua" "CMakeConfigure should use presets when CMakeUserPresets.json exists"
require_pattern 'resolve_configure_preset' "$NVIM/lua/config/cmake.lua" "CMakeConfigure should resolve an existing configure preset instead of hardcoding nvim-debug"
require_pattern 'configurePresets' "$NVIM/lua/config/cmake.lua" "CMakeConfigure should read configurePresets from CMakeUserPresets.json"
require_pattern 'buildPresets' "$NVIM/lua/config/cmake.lua" "CMakeConfigure should understand build presets that point at a configurePreset"
require_pattern '"cmake", "-S", root, "-B", build_dir\(root\)' "$NVIM/lua/config/cmake.lua" "CMakeConfigure should fallback to cmake -S root -B build"
require_pattern 'compile_commands.json' "$NVIM/lua/config/cmake.lua" "CMake helper should document clangd compile database output"
require_pattern ':lsp restart clangd' "$NVIM/lua/config/cmake.lua" "CMake helper should mention Neovim 0.12 native clangd restart"
require_pattern 'vim.lsp.get_clients\(\{bufnr=0\}\)' "$NVIM/lua/config/cmake.lua" "CMake helper should explain how to inspect current-buffer active clients"
require_pattern 'folke/lazy.nvim.git' "$NVIM/lua/config/lazy.lua" "lazy.nvim must remain the plugin manager"
reject_pattern 'vim\.pack\.add' "$NVIM/lua/config/lazy.lua" "vim.pack must not manage plugins in phase one"

if [[ -e "$NVIM/lazyvim.json" ]]; then
  echo "obsolete lazyvim.json should be removed"
  exit 1
fi

reject_pattern 'LazyVim|lazyvim_' "$NVIM/lua/config/options.lua" "options.lua should not reference LazyVim defaults"
reject_pattern 'LazyVim|lazyvim_' "$NVIM/lua/config/keymaps.lua" "keymaps.lua should not reference LazyVim defaults"
reject_pattern 'LazyVim|lazyvim_' "$NVIM/lua/config/autocmds.lua" "autocmds.lua should not reference LazyVim defaults"
reject_pattern 'LazyVim|lazyvim\.plugins|add LazyVim' "$NVIM/lua/config/lazy.lua" "lazy.lua should not keep LazyVim import comments"
reject_pattern 'lazyvim\.json|LazyVim' "$NVIM/README.md" "README should not describe LazyVim residue"
require_pattern 'vim\.opt\.winborder = "rounded"' "$NVIM/lua/config/options.lua" "winborder should be configured through Neovim 0.12 option defaults"
require_pattern 'vim\.opt\.pumborder = "rounded"' "$NVIM/lua/config/options.lua" "pumborder should be configured through Neovim 0.12 option defaults"
require_pattern 'float = \{' "$NVIM/lua/config/options.lua" "diagnostic float config should be explicit"
require_pattern 'border = "rounded"' "$NVIM/lua/config/options.lua" "diagnostic floating windows should use the rounded border default"
require_pattern 'source = "if_many"' "$NVIM/lua/config/options.lua" "diagnostic floating windows should show source only when useful"
require_pattern 'virtual_text = \{' "$NVIM/lua/config/options.lua" "native diagnostic virtual_text should replace tiny-inline-diagnostic"
require_pattern 'virt_text_pos = "inline"' "$NVIM/lua/config/options.lua" "native diagnostic virtual_text should render inline"
require_pattern 'virtual_lines = false' "$NVIM/lua/config/options.lua" "native diagnostic virtual_lines should stay disabled to avoid shifting code"
require_pattern 'severity_sort = true' "$NVIM/lua/config/options.lua" "diagnostics should sort higher severity first"

require_pattern '<leader>rn' "$NVIM/lua/plugins/lsp.lua" "LSP rename alias must remain"
require_pattern '<leader>ca' "$NVIM/lua/plugins/lsp.lua" "LSP code action alias must remain"
require_pattern 'map\("K"' "$NVIM/lua/plugins/lsp.lua" "LSP hover alias must remain"
require_pattern 'vim\.api\.nvim_create_autocmd\("LspAttach"' "$NVIM/lua/plugins/lsp.lua" "LSP aliases should be attached through LspAttach"
require_pattern "vim\\.lsp\\.config\\([\"']\\*[\"']" "$NVIM/lua/plugins/lsp.lua" "LSP defaults should use vim.lsp.config('*', ...)"
require_pattern 'vim\.lsp\.config\("lua_ls"' "$NVIM/lua/plugins/lsp.lua" "lua_ls should use vim.lsp.config"
require_pattern 'vim\.lsp\.config\("clangd"' "$NVIM/lua/plugins/lsp.lua" "clangd should use vim.lsp.config"
require_pattern 'vim\.lsp\.config\("pyright"' "$NVIM/lua/plugins/lsp.lua" "pyright should use vim.lsp.config"
require_pattern 'vim\.lsp\.config\("ts_ls"' "$NVIM/lua/plugins/lsp.lua" "ts_ls should use vim.lsp.config"
require_pattern 'vim\.lsp\.enable' "$NVIM/lua/plugins/lsp.lua" "LSP servers should be enabled with vim.lsp.enable"
reject_pattern 'nvim_create_user_command\("LspRestart"' "$NVIM/lua/plugins/lsp.lua" "Neovim 0.12 native :lsp restart should be used instead of a custom LspRestart alias"
reject_pattern 'require\("lspconfig"\)' "$NVIM/lua/plugins/lsp.lua" "lspconfig framework require should not remain in the LSP migration path"
reject_pattern 'lspconfig\.(lua_ls|clangd|pyright|ts_ls)\.setup' "$NVIM/lua/plugins/lsp.lua" "server setup should not use lspconfig.SERVER.setup"
reject_pattern 'lspconfig\.util\.default_config' "$NVIM/lua/plugins/lsp.lua" "LSP defaults should not mutate lspconfig.util.default_config"
reject_pattern 'folke/neodev\.nvim' "$NVIM/lua/plugins/lsp.lua" "neodev.nvim should not remain after native LSP config migration"
require_pattern 'blink\.get_lsp_capabilities' "$NVIM/lua/plugins/lsp.lua" "blink capabilities must remain in LSP defaults"
require_pattern 'williamboman/mason\.nvim' "$NVIM/lua/plugins/lsp.lua" "LSP path must keep mason.nvim dependency"
reject_pattern 'williamboman/mason-lspconfig\.nvim|require\("mason-lspconfig"\)|mason_lspconfig|automatic_enable' "$NVIM/lua/plugins/lsp.lua" "mason-lspconfig should be removed once vim.lsp.enable is the only LSP enable authority"
reject_pattern '"mason-lspconfig.nvim"' "$NVIM/lazy-lock.json" "mason-lspconfig.nvim should not remain in lazy-lock after native LSP enable owns startup"
require_pattern 'completion = \{ callSnippet = "Replace" \}' "$NVIM/lua/plugins/lsp.lua" "lua_ls completion settings must remain"
require_pattern 'runtime = \{ version = "LuaJIT" \}' "$NVIM/lua/plugins/lsp.lua" "lua_ls should explicitly use the Neovim LuaJIT runtime"
require_pattern 'diagnostics = \{ globals = \{ "vim" \} \}' "$NVIM/lua/plugins/lsp.lua" "lua_ls should explicitly accept the vim global without neodev"
require_pattern 'checkThirdParty = false' "$NVIM/lua/plugins/lsp.lua" "lua_ls workspace checkThirdParty setting must remain"
require_pattern 'library = vim\.api\.nvim_get_runtime_file\("", true\)' "$NVIM/lua/plugins/lsp.lua" "lua_ls should explicitly expose Neovim runtime files without neodev"
require_pattern 'telemetry = \{ enable = false \}' "$NVIM/lua/plugins/lsp.lua" "lua_ls telemetry settings must remain"
require_pattern '--compile-commands-dir=build' "$NVIM/lua/plugins/lsp.lua" "clangd compile commands flag must remain"
require_pattern '--clang-tidy' "$NVIM/lua/plugins/lsp.lua" "clangd clang-tidy flag must remain"
require_pattern 'CMakeLists.txt' "$NVIM/lua/plugins/lsp.lua" "clangd should use CMakeLists.txt as a root marker for non-git CMake projects"
require_pattern 'CMakePresets.json' "$NVIM/lua/plugins/lsp.lua" "clangd should use CMakePresets.json as a root marker for preset-driven CMake projects"
require_pattern 'CMakeUserPresets.json' "$NVIM/lua/plugins/lsp.lua" "clangd should use CMakeUserPresets.json as a root marker for local preset-driven CMake projects"
require_pattern 'typeCheckingMode = "basic"' "$NVIM/lua/plugins/lsp.lua" "pyright type checking setting must remain"
require_pattern 'diagnosticMode = "workspace"' "$NVIM/lua/plugins/lsp.lua" "pyright diagnostic mode setting must remain"
require_pattern 'run_on_start = not is_headless\(\)' "$NVIM/lua/plugins/mason.lua" "Mason tools should auto-install outside headless runs"
reject_pattern '"clangd"' "$NVIM/lua/plugins/mason.lua" "clangd language server should come from PATH instead of Mason auto-install on constrained remote hosts"
require_pattern '"clang-format"' "$NVIM/lua/plugins/mason.lua" "Mason tool installer should keep clang-format for C/C++ formatting"
require_pattern 'start_delay = 3000' "$NVIM/lua/plugins/mason.lua" "Mason tools auto-install should be delayed after startup"
reject_pattern 'cmd = .*MasonToolsInstall' "$NVIM/lua/plugins/mason.lua" "mason-tool-installer should not be command-gated"
reject_pattern '"gr"' "$NVIM/lua/plugins/snacks.lua" "bare gr mapping should be removed to avoid gr* prefix conflicts"
require_pattern '"grr"' "$NVIM/lua/plugins/snacks.lua" "Snacks references mapping should move to Neovim 0.12 grr"
require_pattern 'Snacks\.picker\.lsp_references' "$NVIM/lua/plugins/snacks.lua" "Snacks references picker should stay available on grr"
reject_pattern 'nowait = true' "$NVIM/lua/plugins/snacks.lua" "LSP gr* mappings should not rely on nowait after grr migration"
reject_pattern 'nowait' "$NVIM/README.md" "README should no longer document the old gr nowait boundary"
reject_pattern '当前 `gr` 仍' "$NVIM/README.md" "README should not say bare gr still owns references"
require_pattern '`grr`' "$NVIM/README.md" "README should document grr references"
require_pattern '`grn`' "$NVIM/README.md" "README should document Neovim 0.12 LSP defaults"
require_pattern '<leader>rn' "$NVIM/README.md" "README should document rename mapping boundary"
reject_pattern 'IncRename|inc-rename' "$NVIM/README.md" "README should not describe removed inc-rename behavior"
require_pattern 'LSP buffer-local rename' "$NVIM/README.md" "README should document that <leader>rn is now LSP buffer-local"
require_pattern 'vim\.lsp\.config\(\)' "$NVIM/README.md" "README should document Neovim 0.12 LSP config shape"
require_pattern 'vim\.lsp\.enable\(\)' "$NVIM/README.md" "README should document Neovim 0.12 LSP enable shape"
require_pattern ':lsp restart clangd' "$NVIM/README.md" "README should document the Neovim 0.12 native LSP restart command"
require_pattern 'vim.lsp.get_clients\(\{bufnr=0\}\)' "$NVIM/README.md" "README should document a real current-buffer LSP client inspection command"
require_pattern 'no active clients named clangd' "$NVIM/README.md" "README should explain why clangd restart can fail when no client is active"
require_pattern 'vim.lsp.is_enabled\("clangd"\)' "$NVIM/README.md" "README should document checking whether clangd config is enabled"
require_pattern 'vim.fn.executable\("clangd"\)' "$NVIM/README.md" "README should document checking whether clangd is executable"
require_pattern 'PATH.*clangd|clangd.*PATH' "$NVIM/README.md" "README should document that clangd must be visible through Neovim PATH"
require_pattern 'wh_fabric_build' "$NVIM/README.md" "README should document the verified wh_fabric_build clangd path workaround"
require_pattern '~/.local/bin/clangd.*软链|软链.*~/.local/bin/clangd' "$NVIM/README.md" "README should document ~/.local/bin/clangd as the stable symlink entry for new environments"
require_pattern 'mkdir -p ~/.local/bin' "$NVIM/README.md" "README should show creating ~/.local/bin before linking clangd"
require_pattern 'ln -sf /path/to/clangd/bin/clangd ~/.local/bin/clangd' "$NVIM/README.md" "README should show the clangd symlink command"
require_pattern 'command -v clangd' "$NVIM/README.md" "README should show verifying clangd on PATH after linking"
require_pattern 'vim.fn.exepath\("clangd"\)' "$NVIM/README.md" "README should show verifying clangd from Neovim after linking"
require_pattern '不要把.*/usr/local/musa/bin.*共享 dotfiles|/usr/local/musa/bin.*不要.*共享 dotfiles' "$NVIM/README.md" "README should discourage hardcoding machine-specific clangd paths in shared dotfiles"
reject_pattern ':LspRestart' "$NVIM/README.md" "README should not document a custom LspRestart alias when native :lsp restart exists"
require_pattern '`winborder`' "$NVIM/README.md" "README should document Neovim 0.12 winborder default"
require_pattern '`pumborder`' "$NVIM/README.md" "README should document Neovim 0.12 pumborder default"
require_pattern 'Noice.*cmdline_popup|cmdline_popup.*Noice|浮动命令行' "$NVIM/README.md" "README should document Noice as the floating command-line provider"
require_pattern 'snacks\.nvim.*notifier.*input|Notifier.*input' "$NVIM/README.md" "README should keep snacks notifier/input coverage documented alongside narrow Noice cmdline usage"
require_pattern 'Notifier.*8 秒|8 秒.*Notifier|notification history' "$NVIM/README.md" "README should document readable longer Snacks notifications and history"
require_pattern '<C-s>.*保存|保存.*<C-s>' "$NVIM/README.md" "README should document Ctrl-S quick save"
require_pattern '<leader>q.*不退出 Neovim|不退出 Neovim.*<leader>q|:bdelete' "$NVIM/README.md" "README should document that <leader>q closes buffers instead of quitting Neovim"
require_pattern ':q.*关闭当前文件 buffer|关闭当前文件 buffer.*:q' "$NVIM/README.md" "README should document that :q closes the current buffer in this config"
require_pattern '原生命令错误文本.*Snacks 浮动通知|Snacks 浮动通知.*原生命令错误文本' "$NVIM/README.md" "README should document that original bdelete errors are forwarded to floating notifications"
require_pattern '空 buffer.*退出 Neovim|退出 Neovim.*空 buffer' "$NVIM/README.md" "README should document that <leader>q quits from an empty unnamed buffer"
require_pattern 'Dashboard 不启用|原生空 buffer|native startup' "$NVIM/README.md" "README should document native startup after disabling snacks dashboard"
reject_pattern 'tiny-inline-diagnostic|tiny_inline|tiny%-inline%-diagnostic' "$NVIM/README.md" "README should not describe removed tiny-inline-diagnostic behavior"
require_pattern 'virt_text_pos = "inline"' "$NVIM/README.md" "README should document native inline diagnostic virtual text"
require_pattern '<A-Up>' "$NVIM/README.md" "README should document Alt-Up line movement"
require_pattern '<A-Left>.*<A-Right>|<A-Right>.*<A-Left>' "$NVIM/README.md" "README should document Alt-Left/Right navigation history"
require_pattern '<S-A-Down>' "$NVIM/README.md" "README should document Shift-Alt-Down line duplication"
require_pattern 'Alacritty Linux / macOS profile' "$NVIM/README.md" "README should document terminal profile support for Alt direction keys"
require_pattern '<leader>tb' "$NVIM/README.md" "README should document the native tabline toggle"
require_pattern '原生.*tabline|tabline.*原生' "$NVIM/README.md" "README should document the native tabline replacement"
reject_pattern 'UI / Picker.*bufferline\.nvim|`bufferline.nvim`|BufferLine' "$NVIM/README.md" "README should not list bufferline.nvim as active after native tabline replacement"
require_pattern '<leader>xx.*quickfix|quickfix.*<leader>xx' "$NVIM/README.md" "README should document native quickfix diagnostics for <leader>xx"
require_pattern '<leader>o.*document symbols|document symbols.*<leader>o' "$NVIM/README.md" "README should document native document symbols for <leader>o"
require_pattern 'Outline.*gO|gO.*Outline' "$NVIM/README.md" "README should document native gO outline support"
reject_pattern 'Editing.*neoscroll\.nvim|`neoscroll.nvim`' "$NVIM/README.md" "README should not list neoscroll.nvim as active after native scrolling replacement"
require_pattern '原生.*scroll|scroll.*原生|滚动.*原生|原生.*滚动' "$NVIM/README.md" "README should document native scrolling after removing neoscroll"
reject_pattern '`header.nvim`|header\.nvim' "$NVIM/README.md" "README should not list header.nvim as active after header automation cleanup"
require_pattern '自动文件头.*不.*启用|不.*启用.*自动文件头|header.*不.*启用' "$NVIM/README.md" "README should document that automatic header insertion is not active by default"
reject_pattern '`nvim-colorizer.lua`|nvim-colorizer\.lua' "$NVIM/README.md" "README should not list nvim-colorizer.lua as active after color preview cleanup"
require_pattern '颜色预览.*不.*启用|不.*启用.*颜色预览|color preview.*not active' "$NVIM/README.md" "README should document that color preview is not active by default"
reject_pattern 'Outline.*aerial\.nvim|`aerial.nvim`|Aerial' "$NVIM/README.md" "README should not list aerial.nvim as active after native symbols replacement"
require_pattern '原生 `statusline`|statusline.*laststatus=3' "$NVIM/README.md" "README should document the native statusline replacement"
reject_pattern 'UI / Picker.*lualine\.nvim|`lualine.nvim`' "$NVIM/README.md" "README should not list lualine.nvim as active after native statusline replacement"
reject_pattern 'Trouble diagnostics|folke/trouble.nvim|:Trouble' "$NVIM/README.md" "README should not document Trouble after native diagnostics quickfix replacement"
require_pattern '<leader>ff' "$NVIM/README.md" "README should document snacks file picker keymaps"
require_pattern '<leader>ff.*隐藏文件|隐藏文件.*<leader>ff|hidden.*<leader>ff|<leader>ff.*hidden' "$NVIM/README.md" "README should document that <leader>ff includes hidden files/directories"
require_pattern 'ignored.*不.*默认|不.*默认.*ignored|gitignored.*不.*默认|不.*默认.*gitignored' "$NVIM/README.md" "README should document that <leader>ff does not include ignored/gitignored files by default"
require_pattern '<A-h>.*hidden|hidden.*<A-h>|<A-h>.*隐藏|隐藏.*<A-h>' "$NVIM/README.md" "README should document the Snacks hidden toggle"
require_pattern '<A-i>.*ignored|ignored.*<A-i>|<A-i>.*忽略|忽略.*<A-i>' "$NVIM/README.md" "README should document the Snacks ignored toggle"
reject_pattern '<leader>fG|<leader>fd|<leader>fD' "$NVIM/README.md" "advanced grep keymaps should stay backlog-only for now"
reject_pattern '`lspkind.nvim`|lspkind\.nvim' "$NVIM/README.md" "README should not list lspkind.nvim as active after inline icon cleanup"
require_pattern 'kind icons.*本地映射|本地映射.*kind icons' "$NVIM/README.md" "README should document local completion kind icons"
reject_pattern '`nvim-treesitter-textobjects`|nvim-treesitter-textobjects' "$NVIM/README.md" "README should not list treesitter textobjects as an active plugin after cleanup"
require_pattern 'Syntax[[:space:]]+\| `nvim-treesitter`' "$NVIM/README.md" "README should list nvim-treesitter as the syntax provider"
require_pattern '语法高亮.*/.*缩进由 Treesitter 本体负责|Treesitter 本体负责' "$NVIM/README.md" "README should document that Treesitter core owns syntax and indent"
require_pattern '<leader>th' "$NVIM/README.md" "README should document inlay hint toggle"
require_pattern 'mason-tool-installer\.nvim' "$NVIM/README.md" "README should document Mason tool installer behavior"
reject_pattern '`mason-lspconfig.nvim`|mason-lspconfig\.nvim' "$NVIM/README.md" "README should not list mason-lspconfig by exact plugin name after removing the LSP bridge"
require_pattern 'LSP.*vim\.lsp\.enable\(\).*唯一启用|唯一启用.*vim\.lsp\.enable\(\)' "$NVIM/README.md" "README should document that native vim.lsp.enable is the LSP enable authority"
require_pattern 'Mason LSP 桥接插件已移除|不再通过 Mason LSP 桥接插件桥接' "$NVIM/README.md" "README should document that the Mason LSP bridge was removed"
require_pattern 'CMakeUserPresetInit' "$NVIM/README.md" "README should document CMakeUserPresetInit"
require_pattern 'CMakeConfigure' "$NVIM/README.md" "README should document CMakeConfigure"
require_pattern 'compile_commands\.json' "$NVIM/README.md" "README should document compile_commands.json generation for clangd"
require_pattern '第一个 `configurePresets\\[\\]\\.name`|linux-base' "$NVIM/README.md" "README should document CMakeConfigure auto-selects an existing configure preset"
require_pattern 'build preset.*configurePreset|configurePreset.*build preset' "$NVIM/README.md" "README should document build preset to configurePreset resolution"
require_pattern 'headless 测试' "$NVIM/README.md" "README should document headless runs skip automatic tool installation"
require_pattern 'conform\.nvim' "$NVIM/README.md" "README should document conform formatting"
require_pattern 'neo-tree.*整数宽度|整数宽度.*neo-tree|width.*40' "$NVIM/README.md" "README should document the integer neo-tree sidebar width"
require_pattern 'Neo-tree.*保留|保留.*Neo-tree' "$NVIM/README.md" "README should document the Neo-tree retention decision"
require_pattern 'follow current file' "$NVIM/README.md" "README should document follow-current-file as part of the Neo-tree parity reason"
require_pattern 'Git status' "$NVIM/README.md" "README should document Git status as part of the Neo-tree parity reason"
require_pattern 'hidden.*/.*gitignored|隐藏.*/.*gitignored' "$NVIM/README.md" "README should document hidden/gitignored visibility as part of the Neo-tree parity reason"
require_pattern 'DAP 当前未启用' "$NVIM/README.md" "README should document that DAP is currently disabled"
reject_pattern 'lua/plugins/dap\.lua|调试插件占位' "$NVIM/README.md" "README should not document removed DAP placeholder files"
reject_pattern '\| Debug[[:space:]]+\| `nvim-dap`' "$NVIM/README.md" "README should not list nvim-dap as an active plugin"
reject_pattern 'mfussenegger/nvim-dap|rcarriga/nvim-dap-ui|nvim-neotest/nvim-nio|dapui|cortex_debug' "$NVIM/lua/plugins" "DAP plugins must remain absent after disabled stub cleanup"
reject_pattern 'sphamba/smear-cursor.nvim|smear-cursor|smear_cursor' "$NVIM/lua/plugins" "smear-cursor must remain absent after disabled stub cleanup"
if [[ -e "$NVIM/lua/plugins/dap.lua" ]]; then
  echo "dap.lua disabled placeholder should be removed"
  exit 1
fi
if [[ -e "$NVIM/lua/plugins/cursor.lua" ]]; then
  echo "cursor.lua disabled placeholder should be removed"
  exit 1
fi

require_pattern 'local active_theme = "catppuccin-mocha"' "$NVIM/lua/plugins/theme.lua" "active theme should be Catppuccin Mocha"
require_pattern 'catppuccin/nvim' "$NVIM/lua/plugins/theme.lua" "Catppuccin plugin should be active"
require_pattern 'name = "catppuccin"' "$NVIM/lua/plugins/theme.lua" "Catppuccin lock/spec name should stay stable"
require_pattern 'priority = 1000' "$NVIM/lua/plugins/theme.lua" "Catppuccin should keep startup priority"
require_pattern 'flavour = "mocha"' "$NVIM/lua/plugins/theme.lua" "Catppuccin should use the mocha flavour"
require_pattern 'transparent_background = false' "$NVIM/lua/plugins/theme.lua" "Catppuccin should keep a non-transparent background"
reject_pattern 'navarasu/onedark.nvim' "$NVIM/lua/plugins/theme.lua" "onedark should not remain in active theme config after switching to Catppuccin Mocha"
require_pattern '"catppuccin"' "$NVIM/lazy-lock.json" "Catppuccin should be pinned in lazy-lock"
reject_pattern '"onedark.nvim"' "$NVIM/lazy-lock.json" "onedark should not remain as a stale theme lock entry"
require_pattern 'Catppuccin Mocha|catppuccin.*Mocha' "$NVIM/README.md" "README should document the active Catppuccin Mocha theme"

if rg -q 'lazy = false' "$NVIM/lua/config/lazy.lua"; then
  reject_pattern 'Fast startup.*按需加载|全面按需加载|all plugins lazy-loaded' "$NVIM/README.md" "README should not claim broad lazy loading while defaults.lazy=false"
  require_pattern '核心 UX.*eager|稳定日常 UX' "$NVIM/README.md" "README should describe eager core UX plugin loading accurately"
fi

set +e
XDG_CONFIG_HOME="$ROOT/.config/shared" \
  XDG_DATA_HOME="$data_home" \
  XDG_STATE_HOME="$state_home" \
  XDG_CACHE_HOME="$cache_home" \
  nvim --headless -i NONE -u "$NVIM/init.lua" \
    --cmd 'set noswapfile' \
    '+lua print("nvim-cleanup-ok")' \
    '+qa!' >"$out_file" 2>&1
startup_rc=$?
set -e

if [[ "$startup_rc" -ne 0 ]]; then
  cat "$out_file"
  exit 1
fi
assert_clean_nvim_output

run_nvim_luafile "$active_spec_check" "active spec inventory"

require_pattern 'ACTIVE_PLUGIN Comment.nvim=false' "$out_file" "Comment.nvim should not be an active spec"
require_pattern 'ACTIVE_PLUGIN fidget.nvim=false' "$out_file" "fidget.nvim should not be an active spec"
require_pattern 'ACTIVE_PLUGIN lspsaga.nvim=false' "$out_file" "lspsaga.nvim should not be an active spec"
require_pattern 'ACTIVE_PLUGIN trouble.nvim=false' "$out_file" "Trouble should not remain active after native diagnostics quickfix replacement"
require_pattern 'ACTIVE_PLUGIN noice.nvim=true' "$out_file" "Noice should remain active for the preferred floating command-line popup"
require_pattern 'ACTIVE_PLUGIN aerial.nvim=false' "$out_file" "Aerial should not remain active after native document symbols replacement"
require_pattern 'ACTIVE_PLUGIN neoscroll.nvim=false' "$out_file" "neoscroll.nvim should not remain active after native scrolling replacement"
require_pattern 'ACTIVE_PLUGIN header.nvim=false' "$out_file" "header.nvim should not remain active after header automation cleanup"
require_pattern 'ACTIVE_PLUGIN nvim-colorizer.lua=false' "$out_file" "nvim-colorizer.lua should not remain active after color preview cleanup"
require_pattern 'ACTIVE_PLUGIN nvim-treesitter=true' "$out_file" "nvim-treesitter should remain active for syntax highlighting"
require_pattern 'ACTIVE_PLUGIN nvim-treesitter-textobjects=false' "$out_file" "nvim-treesitter-textobjects should not remain active after cleanup"
require_pattern 'ACTIVE_PLUGIN bufferline.nvim=false' "$out_file" "bufferline.nvim should not remain active after native tabline replacement"
require_pattern 'ACTIVE_PLUGIN lspkind-nvim=false' "$out_file" "lspkind-nvim should not remain active after inline completion icon cleanup"
require_pattern 'ACTIVE_PLUGIN blink.cmp=true' "$out_file" "blink.cmp should remain active after lspkind removal"
require_pattern 'ACTIVE_PLUGIN lualine.nvim=false' "$out_file" "lualine should not remain active after native statusline replacement"
require_pattern 'ACTIVE_PLUGIN snacks.nvim=true' "$out_file" "snacks.nvim should remain active for picker/notifier/input coverage"
require_pattern 'SNACKS_DASHBOARD_ENABLED=false' "$out_file" "snacks dashboard should be disabled at runtime"
require_pattern 'SNACKS_NOTIFIER_TIMEOUT=8000' "$out_file" "snacks notifier timeout should be longer at runtime"
require_pattern 'SNACKS_NOTIFIER_WIDTH_MIN=50' "$out_file" "snacks notifier should have a wider minimum width at runtime"
require_pattern 'SNACKS_NOTIFIER_WIDTH_MAX=0.7' "$out_file" "snacks notifier should have a wider maximum width at runtime"
require_pattern 'SNACKS_NOTIFIER_HEIGHT_MAX=0.8' "$out_file" "snacks notifier should allow taller warnings at runtime"
require_pattern 'SNACKS_NOTIFICATION_WRAP=true' "$out_file" "snacks notifications should wrap long text at runtime"
require_pattern 'SNACKS_NOTIFICATION_HISTORY_WIDTH=0.8' "$out_file" "snacks notification history should use a wide window at runtime"
require_pattern 'SNACKS_NOTIFICATION_HISTORY_HEIGHT=0.8' "$out_file" "snacks notification history should use a tall window at runtime"
require_pattern 'NOICE_CMDLINE_ENABLED=true' "$out_file" "Noice cmdline should be enabled at runtime"
require_pattern 'NOICE_CMDLINE_VIEW=cmdline_popup' "$out_file" "Noice should restore the floating ':' command-line popup"
require_pattern 'NOICE_MESSAGES_ENABLED=false' "$out_file" "Noice should not take over regular messages"
require_pattern 'NOICE_NOTIFY_ENABLED=false' "$out_file" "Noice notifications should stay disabled"
require_pattern 'NOICE_LSP_HOVER_ENABLED=false' "$out_file" "Noice should not take over LSP hover"
require_pattern 'NOICE_LSP_SIGNATURE_ENABLED=false' "$out_file" "Noice should not take over LSP signature help"
require_pattern 'ACTIVE_PLUGIN nui.nvim=true' "$out_file" "nui.nvim should remain active as a dependency of neo-tree/avante"
require_pattern 'ACTIVE_PLUGIN mason-lspconfig.nvim=false' "$out_file" "mason-lspconfig should not remain active after native LSP enable owns startup"
require_pattern 'ACTIVE_PLUGIN neo-tree.nvim=true' "$out_file" "neo-tree should remain active after native parity POC"
require_pattern 'ACTIVE_PLUGIN plenary.nvim=true' "$out_file" "plenary should remain active as a Neo-tree/Avante dependency"
require_pattern 'ACTIVE_PLUGIN nvim-web-devicons=true' "$out_file" "nvim-web-devicons should remain active for Neo-tree/Avante/blink path icons"
require_pattern 'ACTIVE_PLUGIN nvim-autopairs=false' "$out_file" "nvim-autopairs should not remain active after native pairs replacement"
require_pattern 'ACTIVE_PLUGIN nvim-dap=false' "$out_file" "nvim-dap should remain disabled"
require_pattern 'ACTIVE_PLUGIN nvim-dap-ui=false' "$out_file" "nvim-dap-ui should remain disabled"
require_pattern 'ACTIVE_PLUGIN nvim-nio=false' "$out_file" "nvim-nio should not be pulled in by disabled DAP"
require_pattern 'ACTIVE_PLUGIN smear-cursor.nvim=false' "$out_file" "smear-cursor should remain disabled"
require_pattern 'ACTIVE_PLUGIN catppuccin=true' "$out_file" "Catppuccin should be the active theme spec"
require_pattern 'ACTIVE_PLUGIN onedark.nvim=false' "$out_file" "onedark should not remain active after switching to Catppuccin Mocha"

run_nvim_luafile "$neo_tree_parity_check" "neo-tree retention runtime check"

require_pattern 'NEOTREE_ACTIVE=true' "$out_file" "neo-tree should remain an active lazy spec"
require_pattern 'NEOTREE_COMMAND_EXISTS=2' "$out_file" ":Neotree command should remain available"
require_pattern 'NEOTREE_KEYMAP_LHS=<(leader|Space)>e' "$out_file" "<leader>e should remain mapped"
require_pattern 'NEOTREE_KEYMAP_RHS=.*Neotree toggle' "$out_file" "<leader>e should keep toggling Neo-tree"
require_pattern 'NETRW_DISABLED=true' "$out_file" "netrw should remain disabled while Neo-tree is retained"

run_nvim_luafile "$autopairs_check" "native pairs runtime check"

require_pattern 'AUTOPAIRS_ACTIVE=false' "$out_file" "nvim-autopairs should no longer be an active lazy spec"
require_pattern 'AUTOPAIRS_NATIVE_BASIC=true' "$out_file" "native pairs helper should insert and keep basic pairs around the cursor"
require_pattern 'AUTOPAIRS_CR_DESC=Native pairs: newline inside empty pair' "$out_file" "native pairs helper should own Enter in insert mode"
reject_pattern 'AUTOPAIRS_TAB_DESC=Native pairs' "$out_file" "native pairs helper should not own Tab"
reject_pattern 'AUTOPAIRS_STAB_DESC=Native pairs' "$out_file" "native pairs helper should not own Shift-Tab"

run_nvim_luafile "$diagnostics_check" "native diagnostics runtime check"

require_pattern 'KEYMAP_LEADER_XX_LHS=<(leader|Space)>xx' "$out_file" "<leader>xx should remain mapped"
require_pattern 'KEYMAP_LEADER_XX_CALLBACK=true' "$out_file" "<leader>xx should be a callback mapping for native diagnostics quickfix"
require_pattern 'KEYMAP_LEADER_XX_DESC=.*Diagnostics quickfix' "$out_file" "<leader>xx should describe native diagnostics quickfix behavior"
require_pattern 'TROUBLE_COMMAND_EXISTS=0' "$out_file" "Trouble command should not exist after native diagnostics quickfix replacement"
require_pattern 'DIAGNOSTICS_QF_COUNT=[1-9]' "$out_file" "<leader>xx callback should populate the quickfix list from diagnostics"
require_pattern 'DIAGNOSTICS_QF_TEXT=.*native quickfix diagnostic' "$out_file" "quickfix diagnostics should include the injected diagnostic text"

run_nvim_luafile "$theme_check" "theme runtime check"

require_pattern 'COLORSCHEME=catppuccin-mocha' "$out_file" "active colorscheme should be Catppuccin Mocha"
require_pattern 'THEME_CATPPUCCIN_ACTIVE=true' "$out_file" "Catppuccin plugin should remain active at runtime"
require_pattern 'THEME_ONEDARK_ACTIVE=false' "$out_file" "onedark plugin should not remain active at runtime"

run_nvim_luafile "$tabline_check" "native tabline runtime check"

require_pattern 'TABLINE_SHOW=2' "$out_file" "native tabline should keep showtabline=2"
require_pattern 'TABLINE_EXPR=%!v:lua.nvim_native_tabline()' "$out_file" "tabline should use native Lua expression"
require_pattern 'TABLINE_GOTO_FIRST=true' "$out_file" "native buffer goto should select ordinal buffers"
require_pattern 'TABLINE_CYCLE_CHANGED=true' "$out_file" "native buffer cycle should move between buffers"
require_pattern 'TABLINE_HAS_ORDINAL=true' "$out_file" "native tabline should render ordinal labels"
require_pattern 'TABLINE_HAS_SELECTED=true' "$out_file" "native tabline should render selected highlight"
require_pattern 'TABLINE_HAS_FILE=true' "$out_file" "native tabline should render file names"

run_nvim_luafile "$statusline_check" "native statusline runtime check"

require_pattern 'STATUSLINE_LASTSTATUS=3' "$out_file" "native statusline should keep global laststatus=3"
require_pattern 'STATUSLINE_EXPR=%!v:lua.nvim_native_statusline()' "$out_file" "statusline should use the native Lua expression"
require_pattern 'STATUSLINE_HAS_MODE=true' "$out_file" "statusline should render the current mode"
require_pattern 'STATUSLINE_HAS_FILE=true' "$out_file" "statusline should include the file token"
require_pattern 'STATUSLINE_HAS_DIAG=true' "$out_file" "statusline should include diagnostic counts"
require_pattern 'STATUSLINE_HAS_FILETYPE=true' "$out_file" "statusline should include filetype"
require_pattern 'STATUSLINE_HAS_POSITION=true' "$out_file" "statusline should include position tokens"

run_nvim_luafile "$keymap_check" "keymap runtime inventory"

require_pattern 'KEYMAP gr lhs=nil .*nowait=nil' "$out_file" "bare gr should not be mapped at runtime"
reject_pattern 'KEYMAP gr .*nowait=1' "$out_file" "bare gr should not use nowait at runtime"
require_pattern 'KEYMAP grr lhs=grr .*callback=true' "$out_file" "grr should invoke the references picker callback"
require_pattern 'KEYMAP_INVENTORY_OK=true' "$out_file" "runtime keymap inventory should pass semantic checks"
for lhs in grn gra grr gri grt grx gO; do
  require_pattern "KEYMAP $lhs " "$out_file" "runtime keymap output should include $lhs"
done

run_nvim_luafile "$quit_command_check" "safe :q command behavior"

require_pattern 'COMMAND_Q_ABBREV=.*\*.*BufferClose' "$out_file" ":q should expand to BufferClose interactively"
require_pattern 'COMMAND_QUIT_ABBREV=.*\*.*BufferClose' "$out_file" ":quit should expand to BufferClose interactively"
require_pattern 'COMMAND_Q_STILL_RUNNING=true' "$out_file" ":q should not exit the headless Neovim process before checks run"
require_pattern 'COMMAND_Q_BUFFER_CHANGED=true' "$out_file" ":q should close the current file buffer instead of quitting the process"
require_pattern 'COMMAND_Q_INITIAL_BUFLISTED=0' "$out_file" ":q should remove the original file buffer from the listed buffer set"

run_nvim_luafile "$line_edit_check" "line edit runtime behavior"

for lhs in '<A-Up>' '<A-Down>' '<S-A-Up>' '<S-A-Down>' '<A-Left>' '<A-Right>'; do
  require_pattern "LINE_KEYMAP mode=n lhs=$lhs callback=true" "$out_file" "$lhs should exist in normal mode"
done

for lhs in '<A-Up>' '<A-Down>' '<S-A-Up>' '<S-A-Down>'; do
  require_pattern "LINE_KEYMAP mode=x lhs=$lhs callback=true" "$out_file" "$lhs should exist in visual mode"
done

run_nvim_luafile "$cmake_check" "CMake command runtime check"

require_pattern 'CMAKE_COMMAND CMakeUserPresetInit=2' "$out_file" "CMakeUserPresetInit should be registered at runtime"
require_pattern 'CMAKE_COMMAND CMakeConfigure=2' "$out_file" "CMakeConfigure should be registered at runtime"
require_pattern 'CMAKE_DEFAULT_PRESET_LOG=.*args=--preset linux-base' "$out_file" "CMakeConfigure without args should use the first configure preset when nvim-debug is absent"
require_pattern 'CMAKE_BUILD_PRESET_LOG=.*args=--preset linux-base' "$out_file" "CMakeConfigure should resolve a build preset to its configurePreset"
require_pattern 'CMAKE_PRESET_COMPLETION=.*linux-base' "$out_file" "CMakeConfigure completion should include configure presets"
require_pattern 'CMAKE_PRESET_COMPLETION=.*linux-build' "$out_file" "CMakeConfigure completion should include build presets that can resolve to configurePreset"

run_nvim_luafile "$lsp_check" "LSP runtime check"

for server in lua_ls clangd pyright ts_ls; do
  require_pattern "LSP_CONFIG $server enabled=true has_config=true" "$out_file" "$server should be enabled through vim.lsp.enable"
done
require_pattern 'LSP_CAP_SNIPPET=true' "$out_file" "blink capabilities should reach vim.lsp.config defaults"
require_pattern 'LSP_LUA_CHECK_THIRD_PARTY=false' "$out_file" "lua_ls workspace setting should survive migration"
require_pattern 'LSP_LUA_RUNTIME=LuaJIT' "$out_file" "lua_ls should use LuaJIT runtime settings"
require_pattern 'LSP_LUA_GLOBAL_VIM=true' "$out_file" "lua_ls should know the vim global without neodev"
require_pattern 'LSP_LUA_LIBRARY_COUNT=[1-9]' "$out_file" "lua_ls should expose at least one runtime library path"
require_pattern 'LSP_LUA_LIBRARY_VIMRUNTIME=true' "$out_file" "lua_ls runtime library should include VIMRUNTIME"
require_pattern 'LSP_CLANGD_CMD=.*--clang-tidy' "$out_file" "clangd command flags should survive migration"
require_pattern 'LSP_NATIVE_COMMAND=2' "$out_file" "Neovim native :lsp command should be available at runtime"
require_pattern 'LSP_BARE_COMMAND_OK=false' "$out_file" "Bare :lsp should stay documented as requiring a subcommand"
require_pattern 'LSP_PYRIGHT_TYPECHECK=basic' "$out_file" "pyright analysis settings should survive migration"

run_nvim_luafile "$ui_check" "UI runtime check"

require_pattern 'UI_WINBORDER=rounded' "$out_file" "winborder should be rounded at runtime"
require_pattern 'UI_PUMBORDER=rounded' "$out_file" "pumborder should be rounded at runtime"
require_pattern 'UI_DIAGNOSTIC_SIGNS=false' "$out_file" "diagnostic signs should stay disabled"
require_pattern 'UI_DIAGNOSTIC_FLOAT_BORDER=rounded' "$out_file" "diagnostic float border should be rounded at runtime"
require_pattern 'UI_DIAGNOSTIC_FLOAT_SOURCE=if_many' "$out_file" "diagnostic float source should be if_many at runtime"
require_pattern 'UI_DIAGNOSTIC_VIRTUAL_TEXT=table' "$out_file" "diagnostic virtual_text should be enabled with native options at runtime"
require_pattern 'UI_DIAGNOSTIC_VTEXT_POS=inline' "$out_file" "diagnostic virtual_text should render inline at runtime"
require_pattern 'UI_DIAGNOSTIC_VTEXT_SOURCE=if_many' "$out_file" "diagnostic virtual_text source should be if_many at runtime"
require_pattern 'UI_DIAGNOSTIC_VLINES=false' "$out_file" "diagnostic virtual_lines should be disabled at runtime"
require_pattern 'UI_DIAGNOSTIC_SEVERITY_SORT=true' "$out_file" "diagnostics should sort by severity at runtime"
