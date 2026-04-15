--[[
  Operation One — runtime entry.
  Ordered fragments in runtime/ are concatenated into one chunk so locals stay shared
  (same behavior as the old single file). Monolith backup: runtime_monolith.lua
]]
return function(env)
	local order = {
		"runtime/state_visuals_helpers.lua",
		"runtime/globals_config.lua",
		"runtime/env_combat_movement.lua",
		"runtime/gadget_render.lua",
		"runtime/menu_unload_bootstrap.lua",
	}
	local buf = {}
	for i = 1, #order do
		local rel = order[i]
		local src = env.fetch(env.base .. rel)
		if type(src) ~= "string" or #src == 0 then
			error("Operation One: missing or empty fragment: " .. rel)
		end
		buf[#buf + 1] = src
	end
	local fn, cerr = loadstring(table.concat(buf, "\n"), "@Operation-One/runtime_bundle")
	if typeof(fn) ~= "function" then
		error("Operation One: runtime bundle compile failed: " .. tostring(cerr))
	end
	fn()
end
