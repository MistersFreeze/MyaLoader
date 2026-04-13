--[[
  Operation One (PlaceId 72920620366355)
  Loads runtime.lua (features) then gui.lua (interface) from the same folder on your host.
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
	local path = ctx.gameScriptPath or ""
	local dir = path:match("^(.*)/[^/]+$") or ""
	local base = normalizeBase(ctx.baseUrl) .. dir
	if string.sub(base, -1) ~= "/" then
		base = base .. "/"
	end

	local function httpGet(u)
		return game:HttpGet(u, true)
	end

	local runSrc = httpGet(base .. "runtime.lua")
	local runChunk = loadstring(runSrc, "@Operation-One/runtime")
	if typeof(runChunk) ~= "function" then
		error("Operation One: runtime.lua failed to compile")
	end
	runChunk()

	local guiSrc = httpGet(base .. "gui.lua")
	local guiChunk = loadstring(guiSrc, "@Operation-One/gui")
	if typeof(guiChunk) ~= "function" then
		error("Operation One: gui.lua failed to compile")
	end
	guiChunk()

	if typeof(_G.MYA_OP1_RUN_UI_SYNC) == "function" then
		_G.MYA_OP1_RUN_UI_SYNC()
	end

	ctx.notify("Operation One loaded")
end

function M.unmount()
	if typeof(_G.unload_mya) == "function" then
		pcall(_G.unload_mya)
	end
end

return M
