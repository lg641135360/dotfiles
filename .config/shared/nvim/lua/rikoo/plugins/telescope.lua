return {
  "nvim-telescope/telescope.nvim",
  branch = "0.1.x",
  dependencies = {
    "nvim-lua/plenary.nvim",
    { "nvim-telescope/telescope-fzf-native.nvim", build = "make" },
    "nvim-tree/nvim-web-devicons",
  },
  config = function()
    local telescope = require("telescope")
    local actions = require("telescope.actions")

    telescope.setup({
      defaults = {
        path_display = { "smart" },
        mappings = {
          i = {
            ["<C-k>"] = actions.move_selection_previous, -- 上一个结果
            ["<C-j>"] = actions.move_selection_next,     -- 下一个结果
            ["<C-q>"] = actions.send_selected_to_qflist, -- 发送到 quickfix
          },
        },
      },
      pickers = {
        find_files = {
          hidden = true,     -- 显示隐藏文件
          no_ignore = true,  -- 不受 .gitignore 限制
          find_command = { "fd", "--type", "f", "--hidden", "--no-ignore", "--exclude", ".git" },
        },
      },
    })

    telescope.load_extension("fzf")

    -- 快捷键
    local keymap = vim.keymap
    keymap.set("n", "<leader>ff", "<cmd>Telescope find_files<cr>", { desc = "查找文件" })
    keymap.set("n", "<leader>fr", "<cmd>Telescope oldfiles<cr>", { desc = "最近文件" })
    keymap.set("n", "<leader>fs", "<cmd>Telescope live_grep<cr>", { desc = "全局搜索字符串" })
    keymap.set("n", "<leader>fc", "<cmd>Telescope grep_string<cr>", { desc = "搜索光标下的词" })
    keymap.set("n", "<leader>fk", "<cmd>Telescope keymaps<cr>", { desc = "查找快捷键" })
  end,
}

