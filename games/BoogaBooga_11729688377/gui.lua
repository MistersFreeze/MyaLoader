--[[ Mya · Booga Booga ]]
local P = _G.MYA_BOOGA
if not P then
	error("[MyaBooga] Load runtime.lua first")
end

local gethui_support = gethui ~= nil
local cloneref_fn = type(cloneref) == "function" and cloneref or function(x)
	return x
end
local uis = cloneref_fn(game:GetService("UserInputService"))
local ts = game:GetService("TweenService")

local function rand_str(len)
	local chars = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
	local r = {}
	for i = 1, len do
		local j = math.random(1, #chars)
		r[i] = chars:sub(j, j)
	end
	return table.concat(r)
end

local fetch = _G.MYA_FETCH
local repoBase = _G.MYA_REPO_BASE
if typeof(fetch) ~= "function" or typeof(repoBase) ~= "string" or #repoBase == 0 then
	error("[MyaBooga] MYA_FETCH / MYA_REPO_BASE missing")
end
local libSrc = fetch(repoBase .. "lib/mya_game_ui.lua")
local libFn = loadstring(libSrc, "@lib/mya_game_ui")
if typeof(libFn) ~= "function" then
	error("[MyaBooga] lib/mya_game_ui.lua failed to compile")
end
local MyaUI = libFn()
local THEME, C = MyaUI.defaultTheme()

local ui = Instance.new("ScreenGui")
ui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ui.Name = rand_str(6)
ui.IgnoreGuiInset = true
ui.DisplayOrder = 10
ui.ResetOnSpawn = false
ui.Parent = gethui_support and gethui() or game:GetService("CoreGui")
_G.mya_booga_ui = ui

local notify, notif_ui = MyaUI.createNotifyStack({
	C = C,
	THEME = THEME,
	ts = ts,
	gethui_support = gethui_support,
})
_G.mya_booga_notif_ui = notif_ui

local shell = MyaUI.createHubShell({
	ui = ui,
	THEME = THEME,
	C = C,
	ts = ts,
	uis = uis,
	titleText = "Mya  ·  Booga Booga",
	tabNames = { "Visuals", "Settings" },
	subPages = {
		Visuals = { "Player ESP" },
	},
	statusDefault = "Ready · Delete toggles menu",
	discordInvite = "https://discord.gg/YeyepQG6K9",
})

local switch_tab = shell.switch_tab
local make_page = shell.make_page
local tab_containers = shell.tab_containers
local visuals_player_esp = shell.all_sub_pages["Visuals"]["Player ESP"]

local settings_page = make_page()
settings_page.Parent = tab_containers["Settings"]
settings_page.Visible = true

local function section_label(parent, text, order)
	local lbl = Instance.new("TextLabel")
	lbl.LayoutOrder = order
	lbl.Font = Enum.Font.GothamBold
	lbl.Text = "  " .. text:upper()
	lbl.TextColor3 = C.accent
	lbl.TextSize = 10
	lbl.BackgroundTransparency = 1
	lbl.Size = UDim2.new(1, 0, 0, 22)
	lbl.TextXAlignment = Enum.TextXAlignment.Left
	lbl.Parent = parent
end

local function make_row(parent, order, h)
	h = h or 34
	local row = Instance.new("Frame")
	row.LayoutOrder = order
	row.BackgroundColor3 = C.panel
	row.BorderSizePixel = 0
	row.Size = UDim2.new(1, 0, 0, h)
	row.Parent = parent
	Instance.new("UICorner", row).CornerRadius = UDim.new(0, THEME.cornerSm + 3)
	row.MouseEnter:Connect(function()
		row.BackgroundColor3 = C.row_hover
	end)
	row.MouseLeave:Connect(function()
		row.BackgroundColor3 = C.panel
	end)
	return row
end

local function make_toggle_row(parent, label, order, get_fn, set_fn)
	local row = make_row(parent, order)
	local state = get_fn()
	local lbl = Instance.new("TextLabel")
	lbl.Font = Enum.Font.Gotham
	lbl.Text = label
	lbl.TextColor3 = C.text
	lbl.TextSize = 13
	lbl.BackgroundTransparency = 1
	lbl.Position = UDim2.fromOffset(14, 0)
	lbl.Size = UDim2.new(1, -56, 1, 0)
	lbl.TextXAlignment = Enum.TextXAlignment.Left
	lbl.Parent = row
	local pill = Instance.new("Frame")
	pill.BackgroundColor3 = state and C.tog_on or C.tog_off
	pill.BorderSizePixel = 0
	pill.Position = UDim2.new(1, -46, 0.5, -9)
	pill.Size = UDim2.fromOffset(36, 18)
	Instance.new("UICorner", pill).CornerRadius = UDim.new(1, 0)
	pill.Parent = row
	local knob = Instance.new("Frame")
	knob.BackgroundColor3 = Color3.new(1, 1, 1)
	knob.BorderSizePixel = 0
	knob.Size = UDim2.fromOffset(12, 12)
	knob.Position = state and UDim2.fromOffset(21, 3) or UDim2.fromOffset(3, 3)
	Instance.new("UICorner", knob).CornerRadius = UDim.new(1, 0)
	knob.Parent = pill
	local function refresh()
		state = get_fn()
		pill.BackgroundColor3 = state and C.tog_on or C.tog_off
		knob.Position = state and UDim2.fromOffset(21, 3) or UDim2.fromOffset(3, 3)
	end
	local hit = Instance.new("TextButton")
	hit.BackgroundTransparency = 1
	hit.Size = UDim2.fromScale(1, 1)
	hit.Text = ""
	hit.Parent = row
	hit.MouseButton1Click:Connect(function()
		set_fn(not get_fn())
		refresh()
	end)
	return refresh
end

local function make_button_row(parent, order, text, callback)
	local row = make_row(parent, order, 42)
	local btn = Instance.new("TextButton")
	btn.Size = UDim2.new(1, -28, 0, 30)
	btn.Position = UDim2.fromOffset(14, 6)
	btn.BackgroundColor3 = C.accent
	btn.TextColor3 = Color3.fromRGB(28, 14, 22)
	btn.Font = Enum.Font.GothamBold
	btn.TextSize = 13
	btn.Text = text
	btn.AutoButtonColor = false
	btn.Parent = row
	Instance.new("UICorner", btn).CornerRadius = UDim.new(0, THEME.cornerSm + 2)
	btn.MouseButton1Click:Connect(callback)
end

local o = 0
local function next_order()
	o += 1
	return o
end

section_label(visuals_player_esp, "Visuals", next_order())
local r_esp = make_toggle_row(visuals_player_esp, "Player ESP", next_order(), P.get_player_esp, P.set_player_esp)
local r_tracers = make_toggle_row(visuals_player_esp, "Tracers", next_order(), P.get_tracers, P.set_tracers)
local r_health = make_toggle_row(visuals_player_esp, "Health bar", next_order(), P.get_health_bar, P.set_health_bar)
local r_distance = make_toggle_row(visuals_player_esp, "Distance", next_order(), P.get_distance, P.set_distance)
local r_names = make_toggle_row(visuals_player_esp, "Usernames", next_order(), P.get_usernames, P.set_usernames)
local r_team_mode = make_toggle_row(visuals_player_esp, "Team mode", next_order(), P.get_team_mode, P.set_team_mode)

o = 0
section_label(settings_page, "Script", next_order())
local hint = make_row(settings_page, next_order(), 42)
local hint_txt = Instance.new("TextLabel")
hint_txt.BackgroundTransparency = 1
hint_txt.Size = UDim2.new(1, -28, 1, 0)
hint_txt.Position = UDim2.fromOffset(14, 0)
hint_txt.Font = Enum.Font.Gotham
hint_txt.TextSize = 12
hint_txt.TextColor3 = C.dim
hint_txt.TextXAlignment = Enum.TextXAlignment.Left
hint_txt.TextWrapped = true
hint_txt.Text = "Delete toggles menu"
hint_txt.Parent = hint

make_button_row(settings_page, next_order(), "Unload", function()
	if typeof(_G.unload_mya_booga) == "function" then
		_G.unload_mya_booga()
	end
end)

P.start()

_G.MYA_BOOGA_SYNC_UI = function()
	r_esp()
	r_tracers()
	r_health()
	r_distance()
	r_names()
	r_team_mode()
end

local menu_key = Enum.KeyCode.Delete
uis.InputBegan:Connect(function(input, gp)
	if gp then
		return
	end
	if input.KeyCode == menu_key then
		ui.Enabled = not ui.Enabled
	end
end)

switch_tab("Visuals")
notify("Mya", "Booga Booga ready", 3)
