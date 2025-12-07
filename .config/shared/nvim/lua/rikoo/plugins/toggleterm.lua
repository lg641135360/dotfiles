-- ~/.config/nvim/lua/rikoo/plugins/toggleterm.lua
-- toggleterm.nvim: 更好的终端集成

return {
  "akinsho/toggleterm.nvim",
  version = "*",
  config = function()
    require("toggleterm").setup({
      size = function(term)
        if term.direction == "horizontal" then
          return 15
        elseif term.direction == "vertical" then
          return vim.o.columns * 0.4
        end
      end,
      open_mapping = [[<C-\>]], -- 快捷键: Ctrl+\
      hide_numbers = true,
      shade_terminals = true,
      shading_factor = 2,
      start_in_insert = true,
      insert_mappings = true,
      terminal_mappings = true,
      persist_size = true,
      persist_mode = true,
      direction = "float", -- 'vertical' | 'horizontal' | 'tab' | 'float'
      close_on_exit = true,
      shell = vim.o.shell,
      auto_scroll = true,
      float_opts = {
        border = "curved",
        winblend = 0,
      },
    })

    -- ===== 终端快捷键 =====
    local keymap = vim.keymap
    keymap.set("n", "<leader>tf", ":ToggleTerm direction=float<CR>", { desc = "浮动终端 (tf)" })
    keymap.set("n", "<leader>th", ":ToggleTerm direction=horizontal<CR>", { desc = "水平终端 (th)" })
    keymap.set("n", "<leader>tv", ":ToggleTerm direction=vertical<CR>", { desc = "垂直终端 (tv)" })
    keymap.set("n", "<leader>tt", ":ToggleTerm<CR>", { desc = "切换终端 (tt)" })
    -- 在所有模式下都能用的终端切换（更可靠）
    keymap.set({ "n", "t" }, "<C-t>", "<cmd>ToggleTerm<CR>", { desc = "切换终端 (Ctrl+t)" })

    -- 在终端模式下按 ESC 退出
    function _G.set_terminal_keymaps()
      local opts = { buffer = 0 }
      vim.keymap.set("t", "<esc>", [[<C-\><C-n>]], opts)
      vim.keymap.set("t", "jk", [[<C-\><C-n>]], opts)
      vim.keymap.set("t", "<C-h>", [[<Cmd>wincmd h<CR>]], opts)
      vim.keymap.set("t", "<C-j>", [[<Cmd>wincmd j<CR>]], opts)
      vim.keymap.set("t", "<C-k>", [[<Cmd>wincmd k<CR>]], opts)
      vim.keymap.set("t", "<C-l>", [[<Cmd>wincmd l<CR>]], opts)
    end

    vim.cmd("autocmd! TermOpen term://* lua set_terminal_keymaps()")
  end,
}
