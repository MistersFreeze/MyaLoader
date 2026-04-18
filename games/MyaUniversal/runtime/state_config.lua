local D = _G.MYA_UNIVERSAL_CONFIG or {}
local function cfg_bind_enum(k, default)
	local s = D[k]
	if type(s) ~= "string" then
		return default
	end
	local et, en = s:match("^([^.]+)%.(.+)$")
	if not et or not en then
		return default
	end
	local ok, r = pcall(function()
		return Enum[et][en]
	end)
	return ok and r or default
end
local function num(k, def, lo, hi)
	local v = tonumber(D[k])
	if v == nil then
		return def
	end
	return math.clamp(v, lo, hi)
end
local function col(k, r, g, b)
	local t = D[k]
	if type(t) == "table" then
		return Color3.fromRGB(tonumber(t.r) or r, tonumber(t.g) or g, tonumber(t.b) or b)
	end
	return Color3.fromRGB(r, g, b)
end

local esp_on = false
-- Per-part ESP: green = camera LOS to that body part, pink = occluded (Visuals → ESP).
local esp_visibility_colors_on = D.esp_visibility_colors_on == true
local aim_on = false
local aim_bind = Enum.UserInputType.MouseButton2
local aim_assist_fov = num("aim_assist_fov", 140, 40, 400)
local aim_speed = num("aim_speed", 0.35, 0.05, 1)
local aim_remainder_x, aim_remainder_y = 0, 0
-- true = FOV circle & target pick use mouse position; false = screen center (FPS / static).
local aim_fov_follow_cursor = D.aim_fov_follow_cursor == true
-- Aim assist: keep current target until they leave FOV (no switch when another enters FOV).
local keep_on_target_on = D.keep_on_target_on == true
local aim_lock_plr = nil

-- Aim assist / get_best_target (and triggerbot FOV pick) — ignore teammates when on.
local aim_team_check_on = D.aim_team_check_on == true
-- ESP, distance text, health bars — hide teammates when on.
local esp_team_check_on = D.esp_team_check_on == true
-- Legacy single key: if present and per-mode keys omitted, apply to both.
if D.team_check_on == true then
	if D.aim_team_check_on == nil then
		aim_team_check_on = true
	end
	if D.esp_team_check_on == nil then
		esp_team_check_on = true
	end
end
local vis_check_on = false

-- Best-effort weapon tweaks (scans Tool/Character NumberValues; game-dependent).
local no_recoil_on = D.no_recoil_on == true
local no_spread_on = D.no_spread_on == true

local triggerbot_on = false
local trigger_bind = Enum.KeyCode.E
local trigger_fov = 5
local trigger_delay = num("trigger_delay", 0.1, 0.03, 0.5)
local trigger_next = 0

local healthbars_on = false
local esp_distance_on = false
local esp_names_on = D.esp_names_on == true
local show_aim_fov_circle = false

-- Silent aim (workspace.Raycast redirect; executor hook APIs required).
local silent_aim_on = false
local silent_aim_fov = num("silent_aim_fov", 100, 20, 400)
local silent_aim_fov_follow_cursor = D.silent_aim_fov_follow_cursor == true
local silent_aim_require_bind = D.silent_aim_require_bind == true
local silent_aim_bind = cfg_bind_enum("silent_aim_bind", Enum.UserInputType.MouseButton2)
local show_silent_aim_fov_circle = false

local silent_aim_part = Combat.parse_hit_part(D, "silent_aim_part", "HumanoidRootPart")
local aim_assist_part = Combat.parse_hit_part(D, "aim_assist_part", "Head")
-- Silent aim-only targeting (default on)
local silent_aim_vis_check_on = D.silent_aim_vis_check_on ~= false
local silent_aim_team_check_on = D.silent_aim_team_check_on ~= false

local fly_on = false
local fly_speed = num("fly_speed", 50, 5, 500)
local fly_bind = cfg_bind_enum("fly_bind", Enum.KeyCode.Unknown)
local noclip_on = false
local noclip_saved = {}
local noclip_bind = cfg_bind_enum("noclip_bind", Enum.KeyCode.Unknown)

local walk_target = num("walk_speed", 16, 0, 200)
local jump_target = num("jump_power", 50, 0, 200)
local walk_mod_on = false
local walk_mod_bind = cfg_bind_enum("walk_mod_bind", Enum.KeyCode.Unknown)
local jump_mod_on = false
local ws_orig, jp_orig, jh_orig = nil, nil, nil

local gui_parent = gethui and gethui() or lp:WaitForChild("PlayerGui")
local esp_gui = Instance.new("ScreenGui")
esp_gui.Name = "MyaUniversalESP"
esp_gui.ResetOnSpawn = false
esp_gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
esp_gui.Parent = gui_parent

local highlights = {}
local connections = {}
local camera = Workspace.CurrentCamera
table.insert(
	connections,
	Workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
		camera = Workspace.CurrentCamera
	end)
)
local fly_bv, fly_conn = nil, nil
local noclip_conn = nil
local render_conn = nil

local drawing_ok = typeof(Drawing) == "table" and typeof(Drawing.new) == "function"
local health_draw = {}
local fov_circle_aim = nil
local fov_circle_silent = nil

local color_fov_aim = col("fov_ring_aim", 230, 120, 175)
local color_fov_silent = col("fov_ring_silent", 160, 120, 220)

local vis_params = RaycastParams.new()
vis_params.FilterType = Enum.RaycastFilterType.Blacklist
vis_params.IgnoreWater = true

local function update_vis_filter()
	local c = lp.Character
	if c then
		vis_params.FilterDescendantsInstances = { c }
	else
		vis_params.FilterDescendantsInstances = {}
	end
end

update_vis_filter()
table.insert(connections, lp.CharacterAdded:Connect(function()
	task.defer(update_vis_filter)
end))
table.insert(connections, lp.CharacterRemoving:Connect(function()
	task.defer(update_vis_filter)
end))

local function get_hum()
	local c = lp.Character
	return c and c:FindFirstChildWhichIsA("Humanoid")
end

local function get_root()
	local c = lp.Character
	return c and c:FindFirstChild("HumanoidRootPart")
end

local function get_fov_screen_anchor(follow_cursor)
	if not camera then
		return Vector2.zero
	end
	local vp = camera.ViewportSize
	local center = Vector2.new(vp.X / 2, vp.Y / 2)
	if not follow_cursor then
		return center
	end
	if UserInputService.MouseBehavior == Enum.MouseBehavior.LockCenter then
		return center
	end
	return UserInputService:GetMouseLocation()
end
