--[[
  Project Delta — combat, player ESP, world ESP, configs. No movement tab.
  Same module for PlaceIds 7353845952 and 7336302630 (see root config SUPPORTED_GAMES).
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
	local base = repoBase .. "games/ProjectDelta_7353845952/"

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
				error("MyaProjectDelta: readfile failed: " .. u)
			end
		end
		return game:HttpGet(u, true)
	end
	_G.MYA_FETCH = fetch

	local cfgSrc = fetch(base .. "config.lua")
	local cfgFn = loadstring(cfgSrc, "@MyaProjectDelta/config")
	if typeof(cfgFn) ~= "function" then
		error("MyaProjectDelta: config compile failed")
	end
	local defaults = cfgFn()
	local genv = typeof(getgenv) == "function" and getgenv() or nil
	local userCfg = genv and genv.MYA_PROJECT_DELTA_CONFIG
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
	_G.MYA_PROJECT_DELTA_CONFIG = merged

	local runSrc = fetch(base .. "runtime.lua")
	local runLoader = loadstring(runSrc, "@MyaProjectDelta/runtime")
	if typeof(runLoader) ~= "function" then
		error("MyaProjectDelta: runtime compile failed")
	end
	local runBundle = runLoader()
	if typeof(runBundle) ~= "function" then
		error("MyaProjectDelta: runtime.lua must return function(env)")
	end
	runBundle({ base = base, fetch = fetch, repoBase = repoBase })
	if typeof(_G.MYA_PROJECT_DELTA) ~= "table" then
		error("MyaProjectDelta: runtime did not initialize MYA_PROJECT_DELTA (runtime error or bad load order)")
	end

	local guiSrc = fetch(base .. "gui.lua")
	local guiFn = loadstring(guiSrc, "@MyaProjectDelta/gui")
	if typeof(guiFn) ~= "function" then
		error("MyaProjectDelta: gui compile failed")
	end
	guiFn()

	if typeof(_G.MYA_PROJECT_DELTA_SYNC_UI) == "function" then
		_G.MYA_PROJECT_DELTA_SYNC_UI()
	end

	if ctx.notify then
		ctx.notify("Project Delta ready")
	end
end

function M.unmount()
	if typeof(_G.unload_mya_project_delta) == "function" then
		pcall(_G.unload_mya_project_delta)
	end
end

return M
