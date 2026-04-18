--[[
  Mya Universal — default config (merged with getgenv().MYA_UNIVERSAL_CONFIG in init.lua).
  Keys are optional; omitted keys use defaults below.
]]
return {
	-- Aim assist (team check only affects aim FOV target + triggerbot pick)
	-- aim_team_check_on = false,
	aim_assist_fov = 140,
	aim_assist_part = "Head",
	aim_speed = 0.35,
	aim_fov_follow_cursor = false,
	-- keep_on_target_on = false, -- aim + silent aim: keep lock until target leaves FOV
	-- Silent aim (workspace Raycast redirect; same idea as silent aim 2)
	-- silent_aim_fov = 100,
	-- silent_aim_fov_follow_cursor = false,
	-- silent_aim_require_bind = false,
	-- silent_aim_part = "HumanoidRootPart",
	-- silent_aim_vis_check_on = true,
	-- silent_aim_team_check_on = true,
	-- silent_aim_bind = "UserInputType.MouseButton2",
	-- fov_ring_silent = { r = 160, g = 120, b = 220 },
	-- Triggerbot (FOV for target pick is fixed at 5)
	trigger_delay = 0.1,
	-- Movement (optional keybinds: KeyCode.F etc.; omit or Unknown = no bind)
	-- fly_bind = "KeyCode.F",
	-- walk_mod_bind = "KeyCode.G",
	-- noclip_bind = "KeyCode.H",
	fly_speed = 50,
	walk_speed = 16,
	jump_power = 50,
	-- FOV ring Drawing colors (RGB 0–255)
	fov_ring_aim = { r = 230, g = 120, b = 175 },
	-- ESP: names above players; distance text below character (Visuals → ESP).
	-- esp_team_check_on = false, -- hide teammates from ESP / bars / distance text
	esp_names_on = false,
	-- esp_visibility_colors_on = false, -- per-part green/pink LOS (optional)
	-- Misc → weapon mods (generic; effectiveness varies by game).
	no_recoil_on = false,
	no_spread_on = false,
}
