-- ~/.config/nvim/lua/rikoo/plugins/treesitter.lua
-- nvim-treesitter: 语法高亮、智能缩进、代码折叠
-- 支持: C, C++, Rust, Python, Markdown, JSON, YAML 等

return {
  "nvim-treesitter/nvim-treesitter",
  build = ":TSUpdate",
  config = function()
    require("nvim-treesitter.configs").setup({
      ensure_installed = {
        "c", "cpp", "rust", "python",       -- 主要编程语言
        "lua", "vim", "vimdoc", "query",    -- Neovim 相关
        "markdown", "markdown_inline",      -- Markdown 文档
        "json", "yaml", "toml", "bash"      -- 配置文件
      },
      highlight = { enable = true },
      indent = { enable = true },
      incremental_selection = {
        enable = true,
        keymaps = {
          init_selection = "<CR>",       -- 开始选择
          node_incremental = "<CR>",     -- 扩大选择
          node_decremental = "<BS>",     -- 缩小选择
        },
      },
    })

    -- ===== 代码折叠设置 (基于 Treesitter) =====
    -- 原生命令:
    --   zc -> 关闭折叠
    --   zo -> 打开折叠
    --   zM -> 关闭所有折叠
    --   zR -> 打开所有折叠
    -- 默认: 所有折叠打开 (foldlevel=99)
    vim.o.foldmethod = "expr"
    vim.o.foldexpr = "nvim_treesitter#foldexpr()"
    vim.o.foldlevel = 20  -- 降低默认折叠层级，提升性能
    vim.o.foldenable = false  -- 打开文件时不自动折叠，提升大文件性能

    -- ===== 折叠快捷键 =====
    vim.keymap.set("n", "<leader>z",  "za", { desc = "切换折叠 (z)" })
    vim.keymap.set("n", "<leader>zo", "zo", { desc = "打开折叠 (zo)" })
    vim.keymap.set("n", "<leader>zc", "zc", { desc = "关闭折叠 (zc)" })
    vim.keymap.set("n", "<leader>zR", "zR", { desc = "打开所有折叠 (zR)" })
    vim.keymap.set("n", "<leader>zM", "zM", { desc = "关闭所有折叠 (zM)" })
  end,
}