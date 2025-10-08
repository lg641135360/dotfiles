-- ~/.config/nvim/lua/rikoo/plugins/indent.lua
-- indent-blankline: show indent guides
-- Helps visualize code structure and nested blocks

return {
  "lukas-reineke/indent-blankline.nvim",
  main = "ibl", -- new API name
  opts = {
    indent = { char = "│" }, -- character for indent line
    scope = { enabled = true }, -- highlight current scope
  },
}

