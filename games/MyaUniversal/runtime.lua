--[[
  Mya Universal — runtime bundle entry (Operation One style).
  Fragments in runtime/ share one chunk scope; order matters.
]]
return function(env)
	local order = {
		"runtime/01_guard_services.lua",
		"runtime/02_state_config.lua",
		"runtime/03_targeting.lua",
		"runtime/04_esp.lua",
		"runtime/05_health_bars.lua",
		"runtime/06_fov_rings.lua",
		"runtime/07_aim_assist.lua",
		"runtime/08_triggerbot.lua",
		"runtime/09_silent_aim.lua",
		"runtime/10_movement.lua",
		"runtime/11_render_hooks.lua",
		"runtime/12_exports.lua",
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
