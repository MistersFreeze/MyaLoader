--[[
  Prison Life (PlaceId 155615604) — runtime bundle + in-game GUI.
  Registered in config SUPPORTED_GAMES; hub Games tab loads this folder.
]]

local M = {}

local function normalizeBase(url)
	if not url or #url == 0 then
		return ""
	end
	if string.sub(url, -1) ~= "/" then
		return url .. "/"
	end
	return url
end

function M.mount(ctx)
	local repoBase = normalizeBase(ctx.baseUrl or "")
	_G.MYA_REPO_BASE = repoBase
	local base = repoBase .. "games/PrisonLife_155615604/"

	local function fetch(u)
		local g = typeof(getgenv) == "function" and getgenv()
		local root = g and g.MYA_LOCAL_ROOT
		if root and typeof(readfile) == "function" then
			local nr = (root:gsub("\\", "/"))
			if string.sub(nr, -1) ~= "/" then
				nr = nr .. "/"
			end
			local nu = (u:gsub("\\", "/"))
			if string.sub(nu, 1, #nr) == nr then
				for _, p in ipairs({ u, u:gsub("/", "\\") }) do
					local ok, body = pcall(readfile, p)
					if ok and typeof(body) == "string" then
						return body
					end
				end
				error("PrisonLife: readfile failed: " .. u)
			end
		end
		return game:HttpGet(u, true)
	end
	_G.MYA_FETCH = fetch

	local cfgSrc = fetch(base .. "config.lua")
	local cfgFn = loadstring(cfgSrc, "@PrisonLife/config")
	if typeof(cfgFn) ~= "function" then
		error("PrisonLife: config compile failed")
	end
	local defaults = cfgFn()
	local genv = typeof(getgenv) == "function" and getgenv() or nil
	local userCfg = genv and (genv.MYA_PRISON_LIFE_CONFIG or genv.MYA_UNIVERSAL_CONFIG)
	local merged = {}
	if type(defaults) == "table" then
		for k, v in pairs(defaults) do
			merged[k] = v
		end
	end
	if type(userCfg) == "table" then
		for k, v in pairs(userCfg) do
			merged[k] = v
		end
	end
	_G.MYA_UNIVERSAL_CONFIG = merged

	local runSrc = fetch(base .. "runtime.lua")
	local runLoader = loadstring(runSrc, "@PrisonLife/runtime")
	if typeof(runLoader) ~= "function" then
		error("PrisonLife: runtime compile failed")
	end
	local runBundle = runLoader()
	if typeof(runBundle) ~= "function" then
		error("PrisonLife: runtime.lua must return function(env)")
	end
	runBundle({ base = base, fetch = fetch, repoBase = repoBase })
	if typeof(_G.MYA_UNIVERSAL) ~= "table" then
		error("PrisonLife: runtime did not initialize MYA_UNIVERSAL (runtime error or bad load order)")
	end

	local guiSrc = fetch(base .. "gui.lua")
	local guiFn = loadstring(guiSrc, "@PrisonLife/gui")
	if typeof(guiFn) ~= "function" then
		error("PrisonLife: gui compile failed")
	end
	guiFn()

	if typeof(_G.MYA_UNIVERSAL_SYNC_UI) == "function" then
		_G.MYA_UNIVERSAL_SYNC_UI()
	end

	if ctx.notify then
		ctx.notify("Prison Life ready")
	end
end

function M.unmount()
	if typeof(_G.unload_mya_universal) == "function" then
		pcall(_G.unload_mya_universal)
	end
end

return M
