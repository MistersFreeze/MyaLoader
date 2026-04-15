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
	local base = normalizeBase(ctx.baseUrl or "") .. "games/MyaUniversal/"

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

	local runSrc = fetch(base .. "runtime.lua")
	local runFn = loadstring(runSrc, "@MyaUniversal/runtime")
	if typeof(runFn) ~= "function" then
		error("MyaUniversal: runtime compile failed")
	end
	runFn()

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
