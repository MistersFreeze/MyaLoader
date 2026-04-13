--[[
  Shared helpers for Mya (HttpGet, safe compile/run).
]]

local Util = {}

function Util.httpGet(url: string): (string?, string?)
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
