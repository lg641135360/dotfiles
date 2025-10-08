-- ~/.config/nvim/lua/rikoo/plugins/treesitter.lua
-- nvim-treesitter: syntax highlighting, indentation, folding
-- Supported: C, C++, Rust, Python, Markdown, JSON, YAML, etc.

return {
  "nvim-treesitter/nvim-treesitter",
  build = ":TSUpdate",
  config = function()
    require("nvim-treesitter.configs").setup({
      ensure_installed = {
        "c", "cpp", "rust", "python",       -- main languages
        "lua", "vim", "vimdoc", "query",    -- neovim related
        "markdown", "markdown_inline",      -- markdown
        "json", "yaml", "toml", "bash"      -- common configs
      },
      highlight = { enable = true },
      indent = { enable = true },
      incremental_selection = {
        enable = true,
        keymaps = {
          init_selection = "<CR>",       -- start selection
          node_incremental = "<CR>",     -- expand selection
          node_decremental = "<BS>",     -- shrink selection
        },
      },
    })

    -- ===== Folding settings (Treesitter based) =====
    -- Commands:
    --   zc -> close fold
    --   zo -> open fold
    --   zM -> close all folds
    --   zR -> open all folds
    -- Default: all folds open (foldlevel=99)
    vim.o.foldmethod = "expr"
    vim.o.foldexpr = "nvim_treesitter#foldexpr()"
    vim.o.foldlevel = 99

    -- ===== Folding keymaps =====
    -- <leader>z  -> toggle fold under cursor
    -- <leader>zo -> open fold
    -- <leader>zc -> close fold
    -- <leader>zR -> open all folds
    -- <leader>zM -> close all folds
    vim.keymap.set("n", "<leader>z",  "za", { desc = "Toggle fold" })
    vim.keymap.set("n", "<leader>zo", "zo", { desc = "Open fold" })
    vim.keymap.set("n", "<leader>zc", "zc", { desc = "Close fold" })
    vim.keymap.set("n", "<leader>zR", "zR", { desc = "Open all folds" })
    vim.keymap.set("n", "<leader>zM", "zM", { desc = "Close all folds" })
  end,
}

