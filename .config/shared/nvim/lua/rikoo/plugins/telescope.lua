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
        prompt_prefix = " 🔍 ",
        selection_caret = " ➜ ",
        entry_prefix = "   ",
        sorting_strategy = "ascending",
        layout_strategy = "horizontal",
        layout_config = {
          horizontal = {
            prompt_position = "top",
            preview_width = 0.55,
            results_width = 0.8,
          },
          width = 0.87,
          height = 0.80,
          preview_cutoff = 120,
        },
        borderchars = { "─", "│", "─", "│", "┌", "┐", "┘", "└" },
        mappings = {
          i = {
            ["<C-k>"] = actions.move_selection_previous,
            ["<C-j>"] = actions.move_selection_next,
            ["<C-q>"] = actions.send_selected_to_qflist + actions.open_qflist,
          },
        },
      },
      pickers = {
        find_files = {
          hidden = true,     -- 显示隐藏文件
          find_command = { "fd", "--type", "f", "--hidden", "--exclude", ".git" },
        },
      },
    })

    telescope.load_extension("fzf")

    -- 快捷键
    local keymap = vim.keymap
    keymap.set("n", "<leader>ff", "<cmd>Telescope find_files<cr>", { desc = "查找文件 (ff)" })
    keymap.set("n", "<leader>fr", "<cmd>Telescope oldfiles<cr>", { desc = "最近文件 (fr)" })
    keymap.set("n", "<leader>fs", "<cmd>Telescope live_grep<cr>", { desc = "全局搜索 (fs)" })
    keymap.set("n", "<leader>fc", "<cmd>Telescope grep_string<cr>", { desc = "搜索当前词 (fc)" })
    keymap.set("n", "<leader>fk", "<cmd>Telescope keymaps<cr>", { desc = "查找快捷键 (fk)" })
  end,
}

