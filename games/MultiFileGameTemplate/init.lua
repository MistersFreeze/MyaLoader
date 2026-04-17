--[[
  COPY THIS FOLDER → games/YourGameName_<PLACEID>/
  Then in config.lua:
    SUPPORTED_GAMES = { [YOUR_PLACE_ID] = "games/YourGameName_<PLACEID>/init.lua" }

  Load order: runtime.lua (logic + _G.MYA_TEMPLATE) → gui.lua (ScreenGui).
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
				error("Mya template: readfile failed: " .. u)
			end
		end
		return game:HttpGet(u, true)
	end

	local runSrc = fetch(base .. "runtime.lua")
	local runChunk = loadstring(runSrc, "@MyGameTemplate/runtime")
	if typeof(runChunk) ~= "function" then
		error("Mya template: runtime.lua failed to compile")
	end
	runChunk()

	local guiSrc = fetch(base .. "gui.lua")
	local guiChunk = loadstring(guiSrc, "@MyGameTemplate/gui")
	if typeof(guiChunk) ~= "function" then
		error("Mya template: gui.lua failed to compile")
	end
	guiChunk()

	if typeof(_G.MYA_TEMPLATE_RUN_GUI_SYNC) == "function" then
		_G.MYA_TEMPLATE_RUN_GUI_SYNC()
	end

	ctx.notify("Mya · template loaded — copy this folder for new games")
end

function M.unmount()
	if typeof(_G.unload_mya) == "function" then
		pcall(_G.unload_mya)
	end
end

return M
