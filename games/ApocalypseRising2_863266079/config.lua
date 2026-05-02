--[[
  Apocalypse Rising 2 — defaults merged with getgenv().MYA_AR2_CONFIG in init.lua
  (also assigned to MYA_UNIVERSAL_CONFIG for the shared universal runtime).
]]
return {
	tracers_on = false,
	-- arrows_esp_distance_on = false, -- stud distance under crosshair arrows (same as universal)
	aim_assist_fov = 140,
	aim_assist_part = "Head",
	aim_speed = 0.35,
	aim_fov_follow_cursor = false,
	trigger_delay = 0.1,
	fov_ring_aim = { r = 230, g = 120, b = 175 },
	-- esp_names_on = true, -- optional; enable distance / health / names in Visuals → ESP after load
}
