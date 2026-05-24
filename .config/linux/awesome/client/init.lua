local rules = require("client.rules")
local decorations = require("client.decorations")

local M = {}

function M.setup(args)
    rules.setup({
        clientkeys = args.clientkeys,
        clientbuttons = args.clientbuttons,
    })
    decorations.setup()
end

return M
