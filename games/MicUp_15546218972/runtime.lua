--[[
  Corner — runtime entry.
  Fragments under runtime/ are concatenated into one chunk (shared locals).
  Backup monolith: runtime_monolith.lua
]]
return function(env)
	local order = {
		"runtime/piano_engine.lua",
		"runtime/profile_tag_limits.lua",
		"runtime/visuals.lua",
		"runtime/movement.lua",
		"runtime/targeting.lua",
		"runtime/exports.lua",
	}
	local buf = {}
	for i = 1, #order do
		local rel = order[i]
		local s = env.fetch(env.base .. rel)
		if type(s) ~= "string" or #s == 0 then
			error("Corner: missing or empty fragment: " .. rel)
		end
		buf[#buf + 1] = s
	end
	local fn, cerr = loadstring(table.concat(buf, "\n"), "@Corner/runtime_bundle")
	if typeof(fn) ~= "function" then
		error("Corner: runtime bundle compile failed: " .. tostring(cerr))
	end
	fn()
end
