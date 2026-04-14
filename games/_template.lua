--[[
  Single-file game: copy to games/MyGame_1234567890123.lua (name + PlaceId) or use a folder:
    games/MyGame_1234567890123/init.lua
  Register in config.lua:
    SUPPORTED_GAMES = { [PLACE_ID] = "games/MyGame_1234567890123/init.lua" }
  Hub passes ctx.baseUrl and ctx.gameScriptPath for multi-file HttpGet loads.

  Multi-file + custom GUI (tabs, toggles, unload): copy the folder
    games/_MultiFileGameTemplate_0/
  Rename to games/YourGame_<PLACEID>/ and register that init.lua path.
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
