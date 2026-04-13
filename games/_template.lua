--[[
  Copy this file to games/<yourgame>.lua and register PlaceId in config.lua:
    SUPPORTED_GAMES = { [YOUR_PLACE_ID] = "games/<yourgame>.lua" }
]]

local M = {}

function M.mount(ctx: { [string]: any })
	local theme = ctx.theme
	local UI = ctx.uiFactory(theme)

	UI.label(ctx.panel, "Game module template", 16, false)
	UI.label(ctx.panel, "Implement features here. Use ctx.notify('message') for status.", 14, true)

	UI.button(ctx.panel, "Sample action", function()
		ctx.notify("Sample action clicked")
	end)

	-- Store connections or instances to clean up in unmount:
	M._connections = {}
end

function M.unmount()
	if M._connections then
		for _, c in pairs(M._connections) do
			if typeof(c) == "RBXScriptConnection" then
				c:Disconnect()
			end
		end
		M._connections = nil
	end
end

return M
