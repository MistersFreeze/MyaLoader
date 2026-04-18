--[[
  Hosted as raw Lua alongside other Mya files.
  BASE_URL is supplied at runtime by the loader/hub; paths here are suffixes only.
]]

return {
	BRAND = "Mya",
	VERSION = "Loader",

	-- PlaceId -> script path relative to your hosted repo root (same folder as config.lua).
	-- Replace keys with real PlaceIds from the experience you support.
	-- Example: [game.PlaceId while testing] = "games/example.lua"
	SUPPORTED_GAMES = {
		[72920620366355] = "games/Operation-One_72920620366355/init.lua",
		[110400717151509] = "games/Neighbors_110400717151509/init.lua",
		[12699642568] = "games/Neighbors_110400717151509/init.lua",
		[18667984660] = "games/FlexYourFPS_18667984660/init.lua",
	},

	THEME = {
		bg = Color3.fromRGB(28, 18, 26),
		bgElevated = Color3.fromRGB(38, 24, 34),
		surface = Color3.fromRGB(48, 30, 42),
		border = Color3.fromRGB(90, 55, 72),
		text = Color3.fromRGB(255, 228, 238),
		textMuted = Color3.fromRGB(200, 160, 182),
		accent = Color3.fromRGB(240, 130, 175),
		danger = Color3.fromRGB(255, 120, 140),
		corner = 10,
		padding = 14,
	},
}
