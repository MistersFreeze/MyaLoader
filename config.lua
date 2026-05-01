--[[
  Hosted as raw Lua alongside other Mya files.
  BASE_URL is supplied at runtime by the loader/hub; paths here are suffixes only.
]]

return {
	BRAND = "Mya",
	VERSION = "Loader",

	-- Hub: when true (default), automatically loads the game module for the current PlaceId if registered (no "Load game module" click). Set false to load manually. Override: getgenv().MYA_AUTOLOAD_GAME_MODULE.
	AUTOLOAD_GAME_MODULE = false,
	-- Hub: when true, if the current place has no registered module, automatically launches Mya Universal. Default false. Override: getgenv().MYA_AUTOLOAD_MYA_UNIVERSAL_WHEN_UNSUPPORTED.
	AUTOLOAD_MYA_UNIVERSAL_WHEN_UNSUPPORTED = false,

	-- Anonymous analytics (no username/userId/display name).
	-- Sent fields: event type, placeId, module path, random session id, timestamp.
	ANON_ANALYTICS_ENABLED = true,
	ANON_ANALYTICS_WEBHOOK_URL = "https://discord.com/api/webhooks/1499828225688211496/RaFU1-h6aAB_Fqm8SPoYn41APjiWSHbNiG5VAnFNnANp0iylydLITJQ1cSUR1vJDQVlt",

	-- PlaceId -> path under your host root (must match real files: use games/.../init.lua for folders).
	-- Example: "games/MyGame_123/init.lua" or "games/example.lua"
	SUPPORTED_GAMES = {
		[11729688377] = "games/BoogaBooga_11729688377/init.lua",
		[70845479499574] = "games/BiteByNight_70845479499574/init.lua",
		[7353845952] = "games/ProjectDelta_7353845952/init.lua",
		[7336302630] = "games/ProjectDelta_7353845952/init.lua",
		[72920620366355] = "games/Operation-One_72920620366355/init.lua",
		[110400717151509] = "games/Neighbors_110400717151509/init.lua",
		[12699642568] = "games/Neighbors_110400717151509/init.lua",
		[18667984660] = "games/FlexYourFPS_18667984660/init.lua",
		[112399855119586] = "games/MicUp_15546218972/init.lua",
		[15546218972] = "games/MicUp_15546218972/init.lua",
		[155615604] = "games/PrisonLife_155615604/init.lua",
		[93978595733734] = "games/ViolenceDistrict_93978595733734/init.lua",
		[11574110446] = "games/DesolateValley_11574110446/init.lua",
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
