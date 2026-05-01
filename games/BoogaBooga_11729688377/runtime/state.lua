local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")
local Workspace = game:GetService("Workspace")

local lp = Players.LocalPlayer or Players.PlayerAdded:Wait()
local camera = Workspace.CurrentCamera
Workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
	camera = Workspace.CurrentCamera
end)

local drawing_ok = typeof(Drawing) == "table" and typeof(Drawing.new) == "function"

local settings = {
	player_esp = true,
	tracers = true,
	health_bar = true,
	distance = true,
	usernames = true,
	team_mode = false,
}

local highlights = {}
local tracers = {}
local health_outline = {}
local health_fill = {}
local distance_text = {}
local username_text = {}

local runtime_conn = nil
local aux_connections = {}
local highlights_folder = Instance.new("Folder")
highlights_folder.Name = "MyaBoogaESP"
highlights_folder.Parent = CoreGui

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

table.insert(aux_connections, Players.PlayerRemoving:Connect(function(plr)
	cleanup_visuals_for_player(plr)
end))

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
