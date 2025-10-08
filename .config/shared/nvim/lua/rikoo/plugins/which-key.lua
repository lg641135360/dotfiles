-- ~/.config/nvim/lua/rikoo/plugins/which-key.lua
-- which-key.nvim: show available keybindings in a popup

return {
  "folke/which-key.nvim",
  event = "VeryLazy", -- load lazily
  config = function()
    local wk = require("which-key")
    wk.setup({})

    -- Example: register some groups for clarity
    wk.add({
      { "<leader>f", group = "file" },    -- file-related commands
      { "<leader>z", group = "fold" },    -- folding commands
      { "<leader>w", group = "window" },  -- window management
    })
  end,
}

