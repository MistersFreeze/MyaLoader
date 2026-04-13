--[[
  JUNKIE (jnkie.com) entry script — paste into Dashboard → Lua Scripts → Original Code,
  or keep this file in your repo and copy the contents when publishing.

  How Junkie differs from GitHub raw:
  - Junkie gives ONE CDN URL per script (not a folder). This file is that script.
  - Mya still needs config.lua, hub.lua, lib/*, games/* from a base URL with stable paths.
    Put MYA_BASE_URL below to any public static host (e.g. raw GitHub, your VPS).

  Docs: https://docs.jnkie.com/roblox-sdk/external-loader
]]

-- Where the rest of Mya lives (must end with / in practice; loader normalizes).
local MYA_BASE_URL = "https://raw.githubusercontent.com/MistersFreeze/MyaLoader/main/"

-- Junkie key system (set from your Junkie dashboard).
local USE_JUNKIE_KEYS = false
local JUNKIE_SERVICE = "YOUR_SERVICE_NAME"
local JUNKIE_IDENTIFIER = "12345"
local JUNKIE_PROVIDER = "Mixed"

local function get(url: string)
	return game:HttpGet(url, true)
end

local function runMyaLoader()
	if typeof(getgenv) ~= "function" then
		error("getgenv is not available.")
	end
	if typeof(loadstring) ~= "function" then
		error("loadstring is not available.")
	end

	getgenv().MYA_BASE_URL = MYA_BASE_URL

	local src = get(MYA_BASE_URL .. "loader.lua")
	local chunk = loadstring(src, "@loader.lua")
	if typeof(chunk) ~= "function" then
		error("loader.lua failed to compile.")
	end
	chunk()
end

local function runWithJunkieKeys()
	local Junkie = loadstring(get("https://jnkie.com/sdk/library.lua"), "@junkie_sdk")()
	Junkie.service = JUNKIE_SERVICE
	Junkie.identifier = JUNKIE_IDENTIFIER
	Junkie.provider = JUNKIE_PROVIDER

	-- If you already set a key (e.g. from your own UI), validate it once.
	local key = getgenv().SCRIPT_KEY
	if typeof(key) == "string" and #key > 0 then
		local v = Junkie.check_key(key)
		if v and v.valid then
			runMyaLoader()
			return
		end
	end

	-- Minimal loop: replace with your own UI / prompt. See Junkie docs.
	local attempts = 0
	while attempts < 10 do
		attempts = attempts + 1
		local link = Junkie.get_key_link()
		if link and setclipboard then
			setclipboard(link)
		end
		-- User must set getgenv().SCRIPT_KEY in your UI, then re-run or call check_key:
		key = getgenv().SCRIPT_KEY
		if typeof(key) == "string" and #key > 0 then
			local v = Junkie.check_key(key)
			if v and v.valid then
				runMyaLoader()
				return
			end
			warn("[Mya/Junkie] " .. tostring(v and v.message or "invalid key"))
		end
		task.wait(1)
	end
	error("Junkie key validation did not complete. Set USE_JUNKIE_KEYS = false to skip, or wire your own UI.")
end

local ok, err = pcall(function()
	if USE_JUNKIE_KEYS then
		runWithJunkieKeys()
	else
		runMyaLoader()
	end
end)

if not ok then
	warn("[Mya] " .. tostring(err))
end
