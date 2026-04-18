--[[ Flex Your FPS — runtime bundle ]]
return function(env)
	local order = {
		"runtime/state.lua",
		"runtime/flex.lua",
	}
	local buf = {}
	for i = 1, #order do
		local rel = order[i]
		local src = env.fetch(env.base .. rel)
		if type(src) ~= "string" or #src == 0 then
			error("Flex Your FPS: missing or empty fragment: " .. rel)
		end
		buf[#buf + 1] = src
	end
	local fn, cerr = loadstring(table.concat(buf, "\n"), "@FlexYourFPS/runtime_bundle")
	if typeof(fn) ~= "function" then
		error("Flex Your FPS: runtime bundle compile failed: " .. tostring(cerr))
	end
	fn()
end
