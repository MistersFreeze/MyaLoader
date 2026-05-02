--[[
  Apocalypse Rising 2 — runtime loader.
  Concatenates Mya Universal fragments from games/MyaUniversal/ then AR2 runtime/tracers.lua.
]]
return function(env)
	local repoBase = env.repoBase
	if type(repoBase) ~= "string" or #repoBase == 0 then
		error("MyaAR2: repoBase missing — init must pass repoBase alongside base")
	end
	local combatSrc = env.fetch(repoBase .. "lib/mya_combat_helpers.lua")
	if type(combatSrc) ~= "string" or #combatSrc == 0 then
		error("MyaAR2: missing lib/mya_combat_helpers.lua")
	end
	local combatFn, cErr = loadstring(combatSrc, "@lib/mya_combat_helpers")
	if typeof(combatFn) ~= "function" then
		error("MyaAR2: lib/mya_combat_helpers compile failed: " .. tostring(cErr))
	end
	_G.MYA_COMBAT_HELPERS = combatFn()

	local univ = repoBase .. "games/MyaUniversal/"
	local orderPre = {
		"runtime/guard_services.lua",
		"runtime/state_config.lua",
		"runtime/targeting.lua",
		"runtime/esp.lua",
		"runtime/esp_distance.lua",
		"runtime/health_bars.lua",
		"runtime/esp_arrows.lua",
		"runtime/fov_rings.lua",
		"runtime/aim_assist.lua",
		"runtime/silent_aim.lua",
		"runtime/triggerbot.lua",
		"runtime/weapon_mods.lua",
	}
	local orderPost = {
		"runtime/render_hooks.lua",
		"runtime/exports.lua",
	}
	local buf = {
		"local Combat = _G.MYA_COMBAT_HELPERS\n",
	}
	for i = 1, #orderPre do
		local rel = orderPre[i]
		local src = env.fetch(univ .. rel)
		if type(src) ~= "string" or #src == 0 then
			error("MyaAR2: missing or empty universal fragment: " .. rel)
		end
		buf[#buf + 1] = src
	end
	local stubSrc = env.fetch(env.base .. "runtime/movement_ar2_stub.lua")
	if type(stubSrc) ~= "string" or #stubSrc == 0 then
		error("MyaAR2: missing runtime/movement_ar2_stub.lua")
	end
	buf[#buf + 1] = stubSrc
	for i = 1, #orderPost do
		local rel = orderPost[i]
		local src = env.fetch(univ .. rel)
		if type(src) ~= "string" or #src == 0 then
			error("MyaAR2: missing or empty universal fragment: " .. rel)
		end
		buf[#buf + 1] = src
	end
	local trSrc = env.fetch(env.base .. "runtime/tracers.lua")
	if type(trSrc) ~= "string" or #trSrc == 0 then
		error("MyaAR2: missing runtime/tracers.lua")
	end
	buf[#buf + 1] = trSrc

	local fn, cerr = loadstring(table.concat(buf, "\n"), "@ApocalypseRising2/runtime_bundle")
	if typeof(fn) ~= "function" then
		error("MyaAR2: runtime bundle compile failed: " .. tostring(cerr))
	end
	fn()
	_G.MYA_COMBAT_HELPERS = nil
end
