--[[
  Mya Universal — default config (merged with getgenv().MYA_UNIVERSAL_CONFIG in init.lua).
  Keys are optional; omitted keys use defaults below.
]]
return {
	-- Aim assist
	aim_assist_fov = 140,
	aim_speed = 0.35,
	-- Silent aim
	silent_fov = 140,
	silent_max_origin_dist = 180,
	silent_min_look_dot = 0.35,
	-- true = only hook 3-arg Workspace:Raycast (RaycastParams). Safer for games with lots of 2-arg traces.
	silent_require_raycast_params = true,
	-- Ignore raycasts longer than this (direction.Magnitude).
	silent_max_ray_distance = 8192,
	-- "Head" | "HumanoidRootPart" | "UpperTorso" | "LowerTorso" — use HRP/UpperTorso if headshots break game UI.
	silent_aim_part = "Head",
	-- Triggerbot
	trigger_fov = 30,
	trigger_delay = 0.1,
	-- Movement
	fly_speed = 50,
	walk_speed = 16,
	jump_power = 50,
	-- FOV ring Drawing colors (RGB 0–255)
	fov_ring_aim = { r = 230, g = 120, b = 175 },
	fov_ring_silent = { r = 120, g = 200, b = 255 },
}
