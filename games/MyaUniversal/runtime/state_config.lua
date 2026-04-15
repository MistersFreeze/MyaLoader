local D = _G.MYA_UNIVERSAL_CONFIG or {}
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
local aim_on = false
local aim_bind = Enum.UserInputType.MouseButton2
local aim_assist_fov = num("aim_assist_fov", 140, 40, 400)
local aim_speed = num("aim_speed", 0.35, 0.05, 1)
local aim_remainder_x, aim_remainder_y = 0, 0
-- true = FOV circle & target pick use mouse position; false = screen center (FPS / static).
local aim_fov_follow_cursor = D.aim_fov_follow_cursor == true

local team_check_on = false
local vis_check_on = false

local triggerbot_on = false
local trigger_bind = Enum.KeyCode.E
local trigger_fov = num("trigger_fov", 30, 5, 120)
local trigger_delay = num("trigger_delay", 0.1, 0.03, 0.5)
local trigger_next = 0

local healthbars_on = false
local esp_distance_on = false
local esp_names_on = D.esp_names_on == true
local show_aim_fov_circle = false

local fly_on = false
local fly_speed = num("fly_speed", 50, 5, 200)
local noclip_on = false
local noclip_saved = {}

local walk_target = num("walk_speed", 16, 0, 200)
local jump_target = num("jump_power", 50, 0, 200)
local walk_mod_on = false
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

local color_fov_aim = col("fov_ring_aim", 230, 120, 175)

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
