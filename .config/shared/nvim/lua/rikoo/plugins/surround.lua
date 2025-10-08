-- ~/.config/nvim/lua/rikoo/plugins/surround.lua
-- nvim-surround: add/change/delete surrounding characters
-- Examples:
--   ysiw"  -> add " around word
--   cs"'   -> change " to '
--   ds"    -> delete surrounding "
--   visual mode: select text + S) -> surround with ()

return {
  "kylechui/nvim-surround",
  version = "*", -- use latest stable
  event = "VeryLazy", -- load when needed
  config = function()
    require("nvim-surround").setup({})
  end,
}

