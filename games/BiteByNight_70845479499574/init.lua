--[[ Bite By Night (70845479499574) ]]

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
				error("Bite By Night: readfile failed: " .. u)
			end
		end
		return game:HttpGet(u, true)
	end

	local repoBase = normalizeBase(ctx.baseUrl)
	_G.MYA_REPO_BASE = repoBase
	_G.MYA_FETCH = fetch

	local runSrc = fetch(base .. "runtime.lua")
	local runChunk = loadstring(runSrc, "@BiteByNight/runtime")
	if typeof(runChunk) ~= "function" then
		error("Bite By Night: runtime.lua failed to compile")
	end
	local runLoader = runChunk()
	if typeof(runLoader) ~= "function" then
		error("Bite By Night: runtime.lua must return a bundle loader")
	end
	runLoader({ base = base, fetch = fetch })

	local guiSrc = fetch(base .. "gui.lua")
	local guiChunk = loadstring(guiSrc, "@BiteByNight/gui")
	if typeof(guiChunk) ~= "function" then
		error("Bite By Night: gui.lua failed to compile")
	end
	guiChunk()

	if typeof(_G.MYA_BITE_SYNC_UI) == "function" then
		_G.MYA_BITE_SYNC_UI()
	end

	ctx.notify("Bite By Night loaded")
end

function M.unmount()
	if typeof(_G.unload_mya_bite) == "function" then
		pcall(_G.unload_mya_bite)
	end
end

return M

