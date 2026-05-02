--[[
  Apocalypse Rising 2 (PlaceIds 863266079, 93911318070665).
  Reuses Mya Universal runtime (ESP, names, distance, health bars, aim assist, silent aim, triggerbot, movement)
  plus AR2-only tracers. Config merges into MYA_UNIVERSAL_CONFIG for the shared bundle.
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
	local base = repoBase .. "games/ApocalypseRising2_863266079/"

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
				error("MyaAR2: readfile failed: " .. u)
			end
		end
		return game:HttpGet(u, true)
	end
	_G.MYA_FETCH = fetch

	local cfgSrc = fetch(base .. "config.lua")
	local cfgFn = loadstring(cfgSrc, "@ApocalypseRising2/config")
	if typeof(cfgFn) ~= "function" then
		error("MyaAR2: config compile failed")
	end
	local defaults = cfgFn()
	local genv = typeof(getgenv) == "function" and getgenv() or nil
	local userCfg = genv and genv.MYA_AR2_CONFIG
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
	_G.MYA_AR2_CONFIG = merged
	_G.MYA_UNIVERSAL_CONFIG = merged

	local runSrc = fetch(base .. "runtime.lua")
	local runLoader = loadstring(runSrc, "@ApocalypseRising2/runtime")
	if typeof(runLoader) ~= "function" then
		error("MyaAR2: runtime compile failed")
	end
	local runBundle = runLoader()
	if typeof(runBundle) ~= "function" then
		error("MyaAR2: runtime.lua must return function(env)")
	end
	runBundle({ base = base, fetch = fetch, repoBase = repoBase })
	if typeof(_G.MYA_UNIVERSAL) ~= "table" then
		error("MyaAR2: runtime did not initialize MYA_UNIVERSAL")
	end

	local guiSrc = fetch(base .. "gui.lua")
	local guiFn = loadstring(guiSrc, "@ApocalypseRising2/gui")
	if typeof(guiFn) ~= "function" then
		error("MyaAR2: gui compile failed")
	end
	guiFn()

	if typeof(_G.MYA_UNIVERSAL_SYNC_UI) == "function" then
		_G.MYA_UNIVERSAL_SYNC_UI()
	end

	if ctx.notify then
		ctx.notify("Apocalypse Rising 2 ready")
	end
end

function M.unmount()
	if typeof(_G.unload_mya_universal) == "function" then
		pcall(_G.unload_mya_universal)
	end
end

return M
