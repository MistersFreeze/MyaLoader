--[[
  Mya Universal — any PlaceId. ESP, aim assist, fly, noclip, walk/jump.
  Hub launches this from the Universal tab (not via config PlaceId).
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
	local base = repoBase .. "games/MyaUniversal/"

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
				error("MyaUniversal: readfile failed: " .. u)
			end
		end
		return game:HttpGet(u, true)
	end
	_G.MYA_FETCH = fetch

	local cfgSrc = fetch(base .. "config.lua")
	local cfgFn = loadstring(cfgSrc, "@MyaUniversal/config")
	if typeof(cfgFn) ~= "function" then
		error("MyaUniversal: config compile failed")
	end
	local defaults = cfgFn()
	local genv = typeof(getgenv) == "function" and getgenv() or nil
	local userCfg = genv and genv.MYA_UNIVERSAL_CONFIG
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
	local runLoader = loadstring(runSrc, "@MyaUniversal/runtime")
	if typeof(runLoader) ~= "function" then
		error("MyaUniversal: runtime compile failed")
	end
	local runBundle = runLoader()
	if typeof(runBundle) ~= "function" then
		error("MyaUniversal: runtime.lua must return function(env)")
	end
	runBundle({ base = base, fetch = fetch })
	if typeof(_G.MYA_UNIVERSAL) ~= "table" then
		error("MyaUniversal: runtime did not initialize MYA_UNIVERSAL (runtime error or bad load order)")
	end

	local guiSrc = fetch(base .. "gui.lua")
	local guiFn = loadstring(guiSrc, "@MyaUniversal/gui")
	if typeof(guiFn) ~= "function" then
		error("MyaUniversal: gui compile failed")
	end
	guiFn()

	if typeof(_G.MYA_UNIVERSAL_SYNC_UI) == "function" then
		_G.MYA_UNIVERSAL_SYNC_UI()
	end

	if ctx.notify then
		ctx.notify("Mya Universal ready")
	end
end

function M.unmount()
	if typeof(_G.unload_mya_universal) == "function" then
		pcall(_G.unload_mya_universal)
	end
end

return M
