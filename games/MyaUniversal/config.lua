--[[
  Mya Universal — default config (merged with getgenv().MYA_UNIVERSAL_CONFIG in init.lua).
  Keys are optional; omitted keys use defaults below.
]]
return {
	-- Aim assist
	aim_assist_fov = 140,
	aim_speed = 0.35,
	aim_fov_follow_cursor = false,
	-- Triggerbot
	trigger_fov = 30,
	trigger_delay = 0.1,
	-- Movement
	fly_speed = 50,
	walk_speed = 16,
	jump_power = 50,
	-- FOV ring Drawing colors (RGB 0–255)
	fov_ring_aim = { r = 230, g = 120, b = 175 },
	-- ESP: Drawing text above players (enable in Visuals → ESP).
	esp_names_on = false,
}
