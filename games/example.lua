--[[
  Minimal example game module. Add your PlaceId -> "games/example.lua" in config.lua to test.
]]

local M = {}

function M.mount(ctx: { [string]: any })
	local theme = ctx.theme
	local UI = ctx.uiFactory(theme)

	UI.label(ctx.panel, "Example module", 16, false)
	UI.label(ctx.panel, "If you see this, multi-game loading works for this PlaceId.", 14, true)

	local toggled = false
	UI.primaryButton(ctx.panel, "Toggle demo", function()
		toggled = not toggled
		ctx.notify(toggled and "Demo: on" or "Demo: off")
	end)
end

function M.unmount() end

return M
