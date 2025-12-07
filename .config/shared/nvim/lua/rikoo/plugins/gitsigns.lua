-- ~/.config/nvim/lua/rikoo/plugins/gitsigns.lua
-- gitsigns.nvim: 显示 Git 变更、行内 blame、快速导航

return {
  "lewis6991/gitsigns.nvim",
  event = { "BufReadPre", "BufNewFile" },
  config = function()
    require("gitsigns").setup({
      signs = {
        add          = { text = '▎' },
        change       = { text = '▎' },
        delete       = { text = '' },
        topdelete    = { text = '' },
        changedelete = { text = '▎' },
        untracked    = { text = '┆' },
      },
      signs_staged_enable = false,
      current_line_blame = true, -- 默认开启行内 blame
      current_line_blame_opts = {
        virt_text = true,
        virt_text_pos = "eol", -- 'eol' | 'overlay' | 'right_align'
        delay = 500,
      },
      current_line_blame_formatter = '<author>, <author_time:%Y-%m-%d> - <summary>',
      on_attach = function(bufnr)
        local gs = package.loaded.gitsigns
        local keymap = vim.keymap

        -- ===== 导航快捷键 =====
        keymap.set("n", "]c", function()
          if vim.wo.diff then return "]c" end
          vim.schedule(function() gs.next_hunk() end)
          return "<Ignore>"
        end, { expr = true, buffer = bufnr, desc = "下一个变更 (]c)" })

        keymap.set("n", "[c", function()
          if vim.wo.diff then return "[c" end
          vim.schedule(function() gs.prev_hunk() end)
          return "<Ignore>"
        end, { expr = true, buffer = bufnr, desc = "上一个变更 ([c)" })

        -- ===== Git 操作 (g = git) =====
        keymap.set("n", "<leader>gp", gs.preview_hunk, { buffer = bufnr, desc = "预览变更 (gp)" })
        keymap.set("n", "<leader>gb", gs.toggle_current_line_blame, { buffer = bufnr, desc = "切换 blame (gb)" })
        keymap.set("n", "<leader>gs", gs.stage_hunk, { buffer = bufnr, desc = "暂存变更 (gs)" })
        keymap.set("n", "<leader>gr", gs.reset_hunk, { buffer = bufnr, desc = "重置变更 (gr)" })
        keymap.set("n", "<leader>gu", gs.undo_stage_hunk, { buffer = bufnr, desc = "撤销暂存 (gu)" })
        keymap.set("n", "<leader>gd", gs.diffthis, { buffer = bufnr, desc = "查看 diff (gd)" })
      end,
    })
  end,
}
