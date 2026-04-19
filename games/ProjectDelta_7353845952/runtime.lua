--[[
  Project Delta — runtime bundle (PlaceIds 7353845952, 7336302630).
  Fragments in runtime/ share one chunk scope; order matters (same layout as Mya Universal + world_*).
  Prepends lib/mya_combat_helpers.lua as `Combat` (shared targeting/LOS helpers).
]]
return function(env)
	local repoBase = env.repoBase
	if type(repoBase) ~= "string" or #repoBase == 0 then
		error("MyaProjectDelta: repoBase missing — init must pass repoBase alongside base")
	end
	local combatSrc = env.fetch(repoBase .. "lib/mya_combat_helpers.lua")
	if type(combatSrc) ~= "string" or #combatSrc == 0 then
		error("MyaProjectDelta: missing lib/mya_combat_helpers.lua")
	end
	local combatFn, cErr = loadstring(combatSrc, "@lib/mya_combat_helpers")
	if typeof(combatFn) ~= "function" then
		error("MyaProjectDelta: lib/mya_combat_helpers compile failed: " .. tostring(cErr))
	end
	_G.MYA_COMBAT_HELPERS = combatFn()

	local order = {
		"runtime/guard_services.lua",
		"runtime/state_config.lua",
		"runtime/targeting.lua",
		"runtime/esp.lua",
		"runtime/esp_view_angle.lua",
		"runtime/esp_distance.lua",
		"runtime/health_bars.lua",
		"runtime/fov_rings.lua",
		"runtime/aim_assist.lua",
		"runtime/silent_aim.lua",
		"runtime/triggerbot.lua",
		"runtime/weapon_mods.lua",
		"runtime/movement.lua",
		"runtime/world_fullbright.lua",
		"runtime/world_remove_rain.lua",
		"runtime/world_esp_scan.lua",
		"runtime/world_esp_labels.lua",
		"runtime/world_esp_render.lua",
		"runtime/render_hooks.lua",
		"runtime/exports.lua",
	}
	local buf = {
		"local Combat = _G.MYA_COMBAT_HELPERS\n",
	}
	for i = 1, #order do
		local rel = order[i]
		local src = env.fetch(env.base .. rel)
		if type(src) ~= "string" or #src == 0 then
			error("MyaProjectDelta: missing or empty runtime fragment: " .. rel)
		end
		buf[#buf + 1] = src
	end
	local fn, cerr = loadstring(table.concat(buf, "\n"), "@MyaProjectDelta/runtime_bundle")
	if typeof(fn) ~= "function" then
		error("MyaProjectDelta: runtime bundle compile failed: " .. tostring(cerr))
	end
	fn()
	_G.MYA_COMBAT_HELPERS = nil
end
