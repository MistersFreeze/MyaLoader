--[[
  Shared helpers for Mya (HttpGet, safe compile/run).
  When getgenv().MYA_LOCAL_ROOT is set to your repo folder (trailing slash), urls under
  that path are read with readfile() instead of HttpGet — for local testing without GitHub.
]]

local Util = {}

local function norm(p: string): string
	return (p:gsub("\\", "/"))
end

local function tryReadfile(path: string): (string?, string?)
	if typeof(readfile) ~= "function" then
		return nil, "readfile unavailable"
	end
	local variants = { path, path:gsub("/", "\\"), norm(path) }
	local seen = {}
	for _, p in ipairs(variants) do
		if not seen[p] then
			seen[p] = true
			local ok, body = pcall(readfile, p)
			if ok and typeof(body) == "string" then
				return body, nil
			end
		end
	end
	return nil, "readfile failed"
end

function Util.httpGet(url: string): (string?, string?)
	local g = typeof(getgenv) == "function" and getgenv()
	local root = g and g.MYA_LOCAL_ROOT
	if root and typeof(root) == "string" and #root > 0 and typeof(readfile) == "function" then
		local nr = norm(root)
		if string.sub(nr, -1) ~= "/" then
			nr = nr .. "/"
		end
		local nu = norm(url)
		if string.sub(nu, 1, #nr) == nr then
			local body, err = tryReadfile(url)
			if body then
				return body, nil
			end
			return nil, err or "Local file read failed"
		end
	end
	local ok, result = pcall(function()
		return game:HttpGet(url, true)
	end)
	if ok then
		return result :: string, nil
	end
	return nil, tostring(result)
end

function Util.loadstringCompile(source: string, chunkName: string?): (any?, string?)
	local name = chunkName or "MyaChunk"
	local ok, fnOrErr = pcall(function()
		return loadstring(source, "@" .. name)
	end)
	if not ok then
		return nil, tostring(fnOrErr)
	end
	local fn = fnOrErr
	if typeof(fn) ~= "function" then
		return nil, "loadstring did not return a function"
	end
	return fn, nil
end

function Util.runChunk(fn: () -> ...any, ...: any): (...any)
	return fn(...)
end

function Util.loadModuleFromUrl(url: string, chunkName: string?): (any?, string?)
	local body, err = Util.httpGet(url)
	if not body then
		return nil, err or "HttpGet failed"
	end
	local fn, cerr = Util.loadstringCompile(body, chunkName)
	if not fn then
		return nil, cerr
	end
	local ok, result = pcall(fn)
	if not ok then
		return nil, tostring(result)
	end
	return result, nil
end

return Util
