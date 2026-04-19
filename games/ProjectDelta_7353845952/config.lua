--[[
  Project Delta — default config (merged with getgenv().MYA_PROJECT_DELTA_CONFIG in init.lua).
]]
return {
	-- aim_assist_npcs_on = true, -- aim assist + triggerbot FOV pick include NPCs (Humanoid, not players)
	aim_assist_fov = 140,
	aim_assist_part = "Head",
	aim_speed = 0.35,
	aim_fov_follow_cursor = false,
	trigger_delay = 0.1,
	fov_ring_aim = { r = 230, g = 120, b = 175 },
	esp_names_on = false,
	no_recoil_on = false,
	no_spread_on = false,
	crate_esp_max_dist = 220,
	corpse_esp_max_dist = 650,
	world_esp_other_max = 1200,
}
