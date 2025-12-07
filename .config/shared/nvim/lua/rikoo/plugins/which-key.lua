-- ~/.config/nvim/lua/rikoo/plugins/which-key.lua
-- which-key.nvim: 在弹窗中显示可用的快捷键

return {
  "folke/which-key.nvim",
  event = "VeryLazy", -- 延迟加载
  config = function()
    local wk = require("which-key")
    wk.setup({})

    -- 注册快捷键分组，让提示更清晰
    wk.add({
      { "<leader>f", group = "文件/查找" },  -- Telescope 相关
      { "<leader>e", group = "文件树" },     -- nvim-tree 相关
      { "<leader>z", group = "代码折叠" },   -- 折叠命令
      { "<leader>s", group = "窗口分割" },   -- 窗口管理
      { "<leader>t", group = "终端/标签" },  -- 终端和标签页管理
      { "<leader>g", group = "Git" },        -- Git 操作
    })
  end,
}

