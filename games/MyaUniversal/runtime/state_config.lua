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

local silent_on = false
local silent_fov = num("silent_fov", 140, 40, 400)
local cached_silent_aim_world = nil
local silent_max_origin_dist = num("silent_max_origin_dist", 180, 20, 500)
local silent_min_look_dot = num("silent_min_look_dot", 0.35, 0, 1)
-- Only redirect Workspace:Raycast calls that pass RaycastParams (avoids hijacking 2-arg utility traces / UI).
local silent_require_raycast_params = D.silent_require_raycast_params ~= false
-- Max bullet distance (direction.Magnitude); longer traces are left alone (sky checks, debug, etc.).
local silent_max_ray_distance = num("silent_max_ray_distance", 8192, 32, 100000)
local SILENT_PART_OK = { Head = true, HumanoidRootPart = true, UpperTorso = true, LowerTorso = true }
local silent_aim_part = "Head"
do
	local raw = D.silent_aim_part
	if type(raw) == "string" then
		local p = raw:gsub("^%s+", ""):gsub("%s+$", "")
		if SILENT_PART_OK[p] then
			silent_aim_part = p
		end
	end
end

local team_check_on = false
local vis_check_on = false

local triggerbot_on = false
local trigger_bind = Enum.KeyCode.E
local trigger_fov = num("trigger_fov", 30, 5, 120)
local trigger_delay = num("trigger_delay", 0.1, 0.03, 0.5)
local trigger_next = 0

local healthbars_on = false
local esp_distance_on = false
local show_aim_fov_circle = false
local show_silent_fov_circle = false

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
local fov_circle_aim, fov_circle_silent = nil, nil
local old_workspace_raycast = nil
local old_namecall = nil

local color_fov_aim = col("fov_ring_aim", 230, 120, 175)
local color_fov_silent = col("fov_ring_silent", 120, 200, 255)

local vis_params = RaycastParams.new()
vis_params.FilterType = Enum.RaycastFilterType.Blacklist
vis_params.IgnoreWater = true

local silent_ray_bypass = false

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
