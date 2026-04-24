--[[ Violence District — PlaceId 93978595733734 (DbD-style) ]]

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
				error("Violence District: readfile failed: " .. u)
			end
		end
		return game:HttpGet(u, true)
	end

	local repoBase = normalizeBase(ctx.baseUrl)
	_G.MYA_REPO_BASE = repoBase
	_G.MYA_FETCH = fetch

	local guiSrc = fetch(base .. "gui.lua")
	local guiChunk = loadstring(guiSrc, "@ViolenceDistrict/gui")
	if typeof(guiChunk) ~= "function" then
		error("Violence District: gui.lua failed to compile")
	end
	guiChunk()

	if typeof(_G.MYA_VD_RUN_UI_SYNC) == "function" then
		_G.MYA_VD_RUN_UI_SYNC()
	end

	ctx.notify("Violence District module loaded")
end

function M.unmount()
	if typeof(_G.unload_mya_vd) == "function" then
		pcall(_G.unload_mya_vd)
	end
end

return M
