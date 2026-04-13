--[[
  Hosted as raw Lua alongside other Mya files.
  BASE_URL is supplied at runtime by the loader/hub; paths here are suffixes only.
]]

return {
	BRAND = "Mya",
	VERSION = "1.0.0",

	-- PlaceId -> script path relative to your hosted repo root (same folder as config.lua).
	-- Replace keys with real PlaceIds from the experience you support.
	-- Example: [game.PlaceId while testing] = "games/example.lua"
	SUPPORTED_GAMES = {
		-- [1234567890123] = "games/example.lua",
	},

	THEME = {
		bg = Color3.fromRGB(26, 27, 38),
		bgElevated = Color3.fromRGB(34, 36, 48),
		surface = Color3.fromRGB(42, 44, 58),
		border = Color3.fromRGB(58, 62, 78),
		text = Color3.fromRGB(230, 232, 242),
		textMuted = Color3.fromRGB(150, 156, 178),
		accent = Color3.fromRGB(122, 162, 247),
		danger = Color3.fromRGB(242, 110, 110),
		corner = 10,
		padding = 14,
	},
}
