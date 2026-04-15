--[[
  Mya Universal — runtime bundle entry (Operation One style).
  Fragments in runtime/ share one chunk scope; order matters.
]]
return function(env)
	local order = {
		"runtime/guard_services.lua",
		"runtime/state_config.lua",
		"runtime/targeting.lua",
		"runtime/esp.lua",
		"runtime/esp_distance.lua",
		"runtime/health_bars.lua",
		"runtime/fov_rings.lua",
		"runtime/aim_assist.lua",
		"runtime/triggerbot.lua",
		"runtime/silent_aim.lua",
		"runtime/movement.lua",
		"runtime/render_hooks.lua",
		"runtime/exports.lua",
	}
	local buf = {}
	for i = 1, #order do
		local rel = order[i]
		local src = env.fetch(env.base .. rel)
		if type(src) ~= "string" or #src == 0 then
			error("MyaUniversal: missing or empty runtime fragment: " .. rel)
		end
		buf[#buf + 1] = src
	end
	local fn, cerr = loadstring(table.concat(buf, "\n"), "@MyaUniversal/runtime_bundle")
	if typeof(fn) ~= "function" then
		error("MyaUniversal: runtime bundle compile failed: " .. tostring(cerr))
	end
	fn()
end
