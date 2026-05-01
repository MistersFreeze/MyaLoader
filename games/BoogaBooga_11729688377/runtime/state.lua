local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local lp = Players.LocalPlayer or Players.PlayerAdded:Wait()
local camera = Workspace.CurrentCamera
Workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
	camera = Workspace.CurrentCamera
end)

local drawing_ok = typeof(Drawing) == "table" and typeof(Drawing.new) == "function"
local fire_prompt_ok = typeof(fireproximityprompt) == "function"

local settings = {
	player_esp = true,
	tracers = true,
	health_bar = true,
	distance = true,
	usernames = true,
	team_mode = false,
	trader_esp = false,
	trader_tracers = false,
	noclip = false,
	speed = false,
	fly = false,
	noclip_cam = false,
	water_walker = false,
	speed_value = 20,
	fly_speed = 70,
	noclip_bind = Enum.KeyCode.Unknown,
	speed_bind = Enum.KeyCode.Unknown,
	fly_bind = Enum.KeyCode.Unknown,
}

local highlights = {}
local tracers = {}
local health_outline = {}
local health_fill = {}
local distance_text = {}
local username_text = {}
local trader_highlights = {}
local trader_tracers = {}
local tracked_traders = {}

local runtime_conn = nil
local aux_connections = {}
local highlights_folder = Instance.new("Folder")
highlights_folder.Name = "MyaBoogaESP"
highlights_folder.Parent = CoreGui

local speed_orig = nil
local fly_conn = nil
local fly_bv = nil
local noclip_parts = {}
local noclip_char_added_conn = nil
local noclip_desc_added_conn = nil
local noclip_desc_removing_conn = nil
local camera_mode_original = nil
local player_visual_frame = 0

local function is_alive_character(char)
	if not char then
		return nil, nil, nil
	end
	local hum = char:FindFirstChildOfClass("Humanoid")
	local hrp = char:FindFirstChild("HumanoidRootPart")
	local head = char:FindFirstChild("Head")
	if not hum or hum.Health <= 0 or not hrp or not head then
		return nil, nil, nil
	end
	return hum, hrp, head
end

local function get_hum()
	local char = lp.Character
	return char and char:FindFirstChildOfClass("Humanoid")
end

local function get_root()
	local char = lp.Character
	return char and char:FindFirstChild("HumanoidRootPart")
end

local function cleanup_drawing(dict, plr)
	local d = dict[plr]
	if d then
		pcall(function()
			d.Visible = false
			d:Remove()
		end)
		dict[plr] = nil
	end
end

local function hide_drawing(dict, plr)
	local d = dict[plr]
	if d then
		d.Visible = false
	end
end

local function cleanup_visuals_for_player(plr)
	local h = highlights[plr]
	if h then
		pcall(function()
			h:Destroy()
		end)
		highlights[plr] = nil
	end
	cleanup_drawing(tracers, plr)
	cleanup_drawing(health_outline, plr)
	cleanup_drawing(health_fill, plr)
	cleanup_drawing(distance_text, plr)
	cleanup_drawing(username_text, plr)
end

local function cleanup_trader_visual(key)
	local h = trader_highlights[key]
	if h then
		pcall(function()
			h:Destroy()
		end)
		trader_highlights[key] = nil
	end
	local l = trader_tracers[key]
	if l then
		pcall(function()
			l.Visible = false
			l:Remove()
		end)
		trader_tracers[key] = nil
	end
end

local function hide_trader_visual(key)
	local h = trader_highlights[key]
	if h then
		h.Enabled = false
	end
	local l = trader_tracers[key]
	if l then
		l.Visible = false
	end
end

local function hide_visuals_for_player(plr)
	local h = highlights[plr]
	if h then
		h.Enabled = false
	end
	hide_drawing(tracers, plr)
	hide_drawing(health_outline, plr)
	hide_drawing(health_fill, plr)
	hide_drawing(distance_text, plr)
	hide_drawing(username_text, plr)
end

local function for_each_visual_player(fn)
	for plr in pairs(highlights) do
		fn(plr)
	end
	for plr in pairs(tracers) do
		fn(plr)
	end
	for plr in pairs(health_outline) do
		fn(plr)
	end
	for plr in pairs(health_fill) do
		fn(plr)
	end
	for plr in pairs(distance_text) do
		fn(plr)
	end
	for plr in pairs(username_text) do
		fn(plr)
	end
end

local function hide_all_visuals()
	for_each_visual_player(function(plr)
		hide_visuals_for_player(plr)
	end)
end

local function cleanup_stale_visuals()
	for_each_visual_player(function(plr)
		if plr == lp or plr.Parent ~= Players then
			cleanup_visuals_for_player(plr)
		end
	end)
end

local function cleanup_stale_trader_visuals()
	for key in pairs(trader_highlights) do
		if not key or not key.Parent or not key:IsDescendantOf(Workspace) then
			cleanup_trader_visual(key)
		end
	end
	for key in pairs(trader_tracers) do
		if not key or not key.Parent or not key:IsDescendantOf(Workspace) then
			cleanup_trader_visual(key)
		end
	end
end

local function ensure_line(dict, plr, color, thickness, transparency)
	if not drawing_ok then
		return nil
	end
	local line = dict[plr]
	if line then
		return line
	end
	line = Drawing.new("Line")
	line.Visible = false
	line.Color = color
	line.Thickness = thickness
	line.Transparency = transparency
	dict[plr] = line
	return line
end

local function ensure_text(dict, plr, color, size)
	if not drawing_ok then
		return nil
	end
	local txt = dict[plr]
	if txt then
		return txt
	end
	txt = Drawing.new("Text")
	txt.Visible = false
	txt.Size = size
	txt.Center = true
	txt.Outline = true
	txt.Color = color
	txt.Transparency = 1
	dict[plr] = txt
	return txt
end

local function get_player_esp_color(plr)
	if settings.team_mode then
		local tc = plr.TeamColor
		if tc then
			return tc.Color
		end
	end
	return Color3.fromRGB(255, 95, 170)
end

local function is_wandering_trader(inst)
	if not inst or not inst:IsA("Model") then
		return false
	end
	local n = string.lower(inst.Name)
	if n:find("wandering trader", 1, true) == nil and n:find("trader", 1, true) == nil then
		return false
	end
	if not inst:FindFirstChildOfClass("Humanoid") then
		return false
	end
	if lp.Character and inst:IsDescendantOf(lp.Character) then
		return false
	end
	return true
end

local function track_trader(inst)
	if is_wandering_trader(inst) then
		tracked_traders[inst] = true
	end
end

local function untrack_trader(inst)
	if tracked_traders[inst] then
		tracked_traders[inst] = nil
	end
end

local function is_input_match(input, bind)
	if typeof(bind) ~= "EnumItem" then
		return false
	end
	if bind.EnumType == Enum.KeyCode then
		return input.UserInputType == Enum.UserInputType.Keyboard and input.KeyCode == bind
	end
	if bind.EnumType == Enum.UserInputType then
		return input.UserInputType == bind
	end
	return false
end

local function refresh_speed()
	local hum = get_hum()
	if not hum then
		return
	end
	if speed_orig == nil then
		speed_orig = hum.WalkSpeed
	end
	if settings.speed then
		hum.WalkSpeed = settings.speed_value
	else
		hum.WalkSpeed = speed_orig
	end
end

local function restore_speed()
	local hum = get_hum()
	if hum and speed_orig ~= nil then
		hum.WalkSpeed = speed_orig
	end
	speed_orig = nil
end

local function stop_fly()
	if fly_conn then
		fly_conn:Disconnect()
		fly_conn = nil
	end
	if fly_bv then
		pcall(function()
			fly_bv:Destroy()
		end)
		fly_bv = nil
	end
	local hum = get_hum()
	if hum then
		hum.PlatformStand = false
	end
end

local function start_fly()
	stop_fly()
	local root = get_root()
	local hum = get_hum()
	if not root or not hum then
		return
	end
	hum.PlatformStand = true
	fly_bv = Instance.new("BodyVelocity")
	fly_bv.MaxForce = Vector3.new(500000, 500000, 500000)
	fly_bv.Velocity = Vector3.zero
	fly_bv.Parent = root
	fly_conn = RunService.RenderStepped:Connect(function()
		if not settings.fly then
			return
		end
		root = get_root()
		if not root or not fly_bv or fly_bv.Parent ~= root or not camera then
			return
		end
		local cf = camera.CFrame
		local dir = Vector3.zero
		if UserInputService:IsKeyDown(Enum.KeyCode.W) then
			dir += cf.LookVector
		end
		if UserInputService:IsKeyDown(Enum.KeyCode.S) then
			dir -= cf.LookVector
		end
		if UserInputService:IsKeyDown(Enum.KeyCode.D) then
			dir += cf.RightVector
		end
		if UserInputService:IsKeyDown(Enum.KeyCode.A) then
			dir -= cf.RightVector
		end
		if UserInputService:IsKeyDown(Enum.KeyCode.Space) then
			dir += Vector3.new(0, 1, 0)
		end
		if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) or UserInputService:IsKeyDown(Enum.KeyCode.C) then
			dir -= Vector3.new(0, 1, 0)
		end
		fly_bv.Velocity = dir.Magnitude > 0 and dir.Unit * settings.fly_speed or Vector3.zero
	end)
	table.insert(aux_connections, fly_conn)
end

local function noclip_register_part(p)
	if not p:IsA("BasePart") or noclip_parts[p] then
		return
	end
	noclip_parts[p] = {
		CanCollide = p.CanCollide,
		CanQuery = p.CanQuery,
		CanTouch = p.CanTouch,
	}
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
end

local function noclip_unregister_part(p)
	local saved = noclip_parts[p]
	if not saved then
		return
	end
	noclip_parts[p] = nil
	if p.Parent then
		pcall(function()
			p.CanCollide = saved.CanCollide
			p.CanQuery = saved.CanQuery
			p.CanTouch = saved.CanTouch
		end)
	end
end

local function noclip_restore_all_parts()
	for part, saved in pairs(noclip_parts) do
		if part and part:IsA("BasePart") and part.Parent then
			pcall(function()
				part.CanCollide = saved.CanCollide
				part.CanQuery = saved.CanQuery
				part.CanTouch = saved.CanTouch
			end)
		end
		noclip_parts[part] = nil
	end
end

local function noclip_disconnect_desc_hooks()
	if noclip_desc_added_conn then
		noclip_desc_added_conn:Disconnect()
		noclip_desc_added_conn = nil
	end
	if noclip_desc_removing_conn then
		noclip_desc_removing_conn:Disconnect()
		noclip_desc_removing_conn = nil
	end
end

local function noclip_seed_character(c)
	if not c then
		return
	end
	for _, d in ipairs(c:GetDescendants()) do
		noclip_register_part(d)
	end
end

local function noclip_hook_character(c)
	noclip_disconnect_desc_hooks()
	if not c then
		return
	end
	noclip_desc_added_conn = c.DescendantAdded:Connect(function(o)
		if settings.noclip and o:IsA("BasePart") then
			noclip_register_part(o)
		end
	end)
	noclip_desc_removing_conn = c.DescendantRemoving:Connect(function(o)
		if o:IsA("BasePart") then
			noclip_unregister_part(o)
		end
	end)
	table.insert(aux_connections, noclip_desc_added_conn)
	table.insert(aux_connections, noclip_desc_removing_conn)
end

local function stop_noclip()
	if noclip_char_added_conn then
		noclip_char_added_conn:Disconnect()
		noclip_char_added_conn = nil
	end
	noclip_disconnect_desc_hooks()
	noclip_restore_all_parts()
end

local function start_noclip()
	stop_noclip()
	local c = lp.Character
	if c then
		noclip_seed_character(c)
		noclip_hook_character(c)
	end
	noclip_char_added_conn = lp.CharacterAdded:Connect(function(newChar)
		task.defer(function()
			if settings.noclip then
				noclip_restore_all_parts()
				noclip_seed_character(newChar)
				noclip_hook_character(newChar)
			end
		end)
	end)
	table.insert(aux_connections, noclip_char_added_conn)
end

local function step_noclip()
	if not settings.noclip then
		return
	end
	local stale = {}
	for p in pairs(noclip_parts) do
		if p and p.Parent and p:IsA("BasePart") then
			p.CanCollide = false
			p.CanQuery = false
			p.CanTouch = false
		else
			table.insert(stale, p)
		end
	end
	for i = 1, #stale do
		noclip_parts[stale[i]] = nil
	end
end

local function refresh_noclip_cam()
	if settings.noclip_cam then
		if camera_mode_original == nil then
			camera_mode_original = lp.DevCameraOcclusionMode
		end
		lp.DevCameraOcclusionMode = Enum.DevCameraOcclusionMode.Invisicam
	else
		if camera_mode_original ~= nil then
			lp.DevCameraOcclusionMode = camera_mode_original
		end
	end
end

local function step_water_walker()
	if not settings.water_walker then
		return
	end
	local hum = get_hum()
	local root = get_root()
	if not hum or not root then
		return
	end
	if hum:GetState() ~= Enum.HumanoidStateType.Swimming then
		return
	end
	local move = hum.MoveDirection
	if move.Magnitude <= 0 then
		return
	end
	local flat = Vector3.new(move.X, 0, move.Z)
	if flat.Magnitude <= 0 then
		return
	end
	local target = settings.speed and settings.speed_value or 16
	local vel = root.AssemblyLinearVelocity
	root.AssemblyLinearVelocity = Vector3.new(flat.Unit.X * target, vel.Y, flat.Unit.Z * target)
end

table.insert(aux_connections, Players.PlayerRemoving:Connect(function(plr)
	cleanup_visuals_for_player(plr)
end))

for _, inst in ipairs(Workspace:GetDescendants()) do
	track_trader(inst)
end
table.insert(aux_connections, Workspace.DescendantAdded:Connect(function(inst)
	track_trader(inst)
end))
table.insert(aux_connections, Workspace.DescendantRemoving:Connect(function(inst)
	untrack_trader(inst)
	cleanup_trader_visual(inst)
end))

table.insert(aux_connections, lp.CharacterAdded:Connect(function()
	task.defer(function()
		restore_speed()
		refresh_speed()
		if settings.fly then
			start_fly()
		end
		if settings.noclip then
			start_noclip()
		end
	end)
end))

table.insert(aux_connections, UserInputService.InputBegan:Connect(function(input, gp)
	if gp then
		return
	end
	if is_input_match(input, settings.noclip_bind) then
		settings.noclip = not settings.noclip
		if settings.noclip then
			start_noclip()
		else
			stop_noclip()
		end
		if typeof(_G.MYA_BOOGA_SYNC_UI) == "function" then
			_G.MYA_BOOGA_SYNC_UI()
		end
		return
	end
	if is_input_match(input, settings.speed_bind) then
		settings.speed = not settings.speed
		refresh_speed()
		if typeof(_G.MYA_BOOGA_SYNC_UI) == "function" then
			_G.MYA_BOOGA_SYNC_UI()
		end
		return
	end
	if is_input_match(input, settings.fly_bind) then
		settings.fly = not settings.fly
		if settings.fly then
			start_fly()
		else
			stop_fly()
		end
		if typeof(_G.MYA_BOOGA_SYNC_UI) == "function" then
			_G.MYA_BOOGA_SYNC_UI()
		end
		return
	end
end))
