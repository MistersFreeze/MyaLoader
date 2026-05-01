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
local http = game:GetService("HttpService")
local ts = game:GetService("TweenService")

local CONFIG_FOLDER = "mya_booga_configs"
local function ensure_config_dir()
	if not makefolder then
		return
	end
	pcall(function()
		local exists = false
		if isfolder then
			local ok, res = pcall(isfolder, CONFIG_FOLDER)
			if ok and res then
				exists = true
			end
		end
		if not exists then
			makefolder(CONFIG_FOLDER)
		end
	end)
end
ensure_config_dir()

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
_G.mya_notify = notify

local shell = MyaUI.createHubShell({
	ui = ui,
	THEME = THEME,
	C = C,
	ts = ts,
	uis = uis,
	titleText = "Mya  ·  Booga Booga",
	tabNames = { "Visuals", "Movement", "Misc", "Configs", "Settings" },
	subPages = {
		Visuals = { "Player ESP", "Wandering Trader ESP" },
		Movement = { "Movement" },
		Misc = { "Misc" },
	},
	statusDefault = "Ready · Delete toggles menu",
	discordInvite = "https://discord.gg/YeyepQG6K9",
})

local switch_tab = shell.switch_tab
local make_page = shell.make_page
local tab_containers = shell.tab_containers
local all_sub_pages = shell.all_sub_pages

local visuals_player_esp = all_sub_pages["Visuals"]["Player ESP"]
local visuals_trader_esp = all_sub_pages["Visuals"]["Wandering Trader ESP"]
local movement_page = all_sub_pages["Movement"]["Movement"]
local misc_page = all_sub_pages["Misc"]["Misc"]

local settings_page = make_page()
settings_page.Parent = tab_containers["Settings"]
settings_page.Visible = true

local configs_outer = Instance.new("Frame")
configs_outer.BackgroundTransparency = 1
configs_outer.Size = UDim2.fromScale(1, 1)
configs_outer.Parent = tab_containers["Configs"]

local CFG_FOOTER_H = 44
local list_scroller = Instance.new("ScrollingFrame")
list_scroller.BackgroundTransparency = 1
list_scroller.BorderSizePixel = 0
list_scroller.Position = UDim2.new(0, 0, 0, 6)
list_scroller.Size = UDim2.new(1, 0, 1, -(6 + 12 + CFG_FOOTER_H))
list_scroller.CanvasSize = UDim2.fromOffset(0, 0)
list_scroller.AutomaticCanvasSize = Enum.AutomaticSize.Y
list_scroller.ScrollBarThickness = 3
list_scroller.ScrollBarImageColor3 = THEME.border
list_scroller.Parent = configs_outer
local list_pad = Instance.new("UIPadding", list_scroller)
list_pad.PaddingLeft = UDim.new(0, 12)
list_pad.PaddingRight = UDim.new(0, 12)
local list_layout = Instance.new("UIListLayout", list_scroller)
list_layout.Padding = UDim.new(0, 6)
list_layout.SortOrder = Enum.SortOrder.LayoutOrder

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
	local sep = Instance.new("Frame")
	sep.BackgroundColor3 = THEME.border
	sep.BorderSizePixel = 0
	sep.Position = UDim2.new(0, 0, 1, -1)
	sep.Size = UDim2.new(1, 0, 0, 1)
	sep.Parent = row
	row.MouseEnter:Connect(function()
		row.BackgroundColor3 = C.row_hover
	end)
	row.MouseLeave:Connect(function()
		row.BackgroundColor3 = C.panel
	end)
	return row
end

local function make_slider(parent, label, order, min_v, max_v, def, fmt, on_change)
	local row = make_row(parent, order, 48)
	local lbl = Instance.new("TextLabel")
	lbl.Font = Enum.Font.Gotham
	lbl.TextColor3 = C.text
	lbl.TextSize = 12
	lbl.BackgroundTransparency = 1
	lbl.Position = UDim2.fromOffset(14, 4)
	lbl.Size = UDim2.new(1, -28, 0, 16)
	lbl.TextXAlignment = Enum.TextXAlignment.Left
	lbl.Text = label
	lbl.Parent = row
	local val_lbl = Instance.new("TextLabel")
	val_lbl.Font = Enum.Font.GothamSemibold
	val_lbl.TextColor3 = C.accent
	val_lbl.TextSize = 11
	val_lbl.BackgroundTransparency = 1
	val_lbl.Position = UDim2.fromOffset(14, 4)
	val_lbl.Size = UDim2.new(1, -28, 0, 16)
	val_lbl.TextXAlignment = Enum.TextXAlignment.Right
	val_lbl.Parent = row
	local track = Instance.new("Frame")
	track.BackgroundColor3 = C.slid_bg
	track.BorderSizePixel = 0
	track.Position = UDim2.fromOffset(14, 28)
	track.Size = UDim2.new(1, -28, 0, 6)
	Instance.new("UICorner", track).CornerRadius = UDim.new(1, 0)
	track.Parent = row
	local fill = Instance.new("Frame")
	fill.BackgroundColor3 = C.slid_fg
	fill.BorderSizePixel = 0
	fill.Size = UDim2.fromScale(0, 1)
	Instance.new("UICorner", fill).CornerRadius = UDim.new(1, 0)
	fill.Parent = track
	local thumb = Instance.new("Frame")
	thumb.BackgroundColor3 = Color3.new(1, 1, 1)
	thumb.BorderSizePixel = 0
	thumb.Size = UDim2.fromOffset(12, 12)
	thumb.Position = UDim2.new(0, -6, 0.5, -6)
	Instance.new("UICorner", thumb).CornerRadius = UDim.new(1, 0)
	thumb.Parent = track
	local cur = def
	local dragging = false
	local function set_val(v)
		cur = math.clamp(v, min_v, max_v)
		local pct = (cur - min_v) / (max_v - min_v)
		fill.Size = UDim2.fromScale(pct, 1)
		thumb.Position = UDim2.new(pct, -6, 0.5, -6)
		val_lbl.Text = string.format(fmt or "%g", cur)
		if on_change then
			on_change(cur)
		end
	end
	set_val(def)
	local function from_x(x)
		local abs = track.AbsolutePosition
		local sz = track.AbsoluteSize
		set_val(min_v + math.clamp((x - abs.X) / sz.X, 0, 1) * (max_v - min_v))
	end
	track.InputBegan:Connect(function(inp)
		if inp.UserInputType == Enum.UserInputType.MouseButton1 then
			dragging = true
			from_x(inp.Position.X)
		end
	end)
	uis.InputChanged:Connect(function(inp)
		if dragging and inp.UserInputType == Enum.UserInputType.MouseMovement then
			from_x(inp.Position.X)
		end
	end)
	uis.InputEnded:Connect(function(inp)
		if inp.UserInputType == Enum.UserInputType.MouseButton1 then
			dragging = false
		end
	end)
	return set_val
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

local listening_btn = nil
local listening_set = nil
local listening_get = nil
local listening_armed = false

local function bind_display_name(bind)
	if typeof(bind) ~= "EnumItem" then
		return "?"
	end
	if bind.EnumType == Enum.UserInputType then
		if bind == Enum.UserInputType.MouseButton1 then return "Mouse 1" end
		if bind == Enum.UserInputType.MouseButton2 then return "Mouse 2" end
		if bind == Enum.UserInputType.MouseButton3 then return "Mouse 3" end
		return bind.Name
	end
	if bind.EnumType == Enum.KeyCode then
		if bind == Enum.KeyCode.Unknown then
			return "—"
		end
		return bind.Name
	end
	return "?"
end

local function make_keybind_row(parent, label, order, get_fn, set_fn)
	local row = make_row(parent, order)
	local lbl = Instance.new("TextLabel")
	lbl.Font = Enum.Font.Gotham
	lbl.Text = label
	lbl.TextColor3 = C.text
	lbl.TextSize = 13
	lbl.BackgroundTransparency = 1
	lbl.Position = UDim2.fromOffset(14, 0)
	lbl.Size = UDim2.new(0.5, -8, 1, 0)
	lbl.TextXAlignment = Enum.TextXAlignment.Left
	lbl.Parent = row
	local bb = Instance.new("TextButton")
	bb.AutoButtonColor = false
	bb.Font = Enum.Font.GothamSemibold
	bb.TextSize = 11
	bb.TextColor3 = C.text
	bb.BackgroundColor3 = C.input_bg
	bb.Position = UDim2.new(0.52, 0, 0.5, -10)
	bb.Size = UDim2.new(0.44, -14, 0, 22)
	bb.Text = bind_display_name(get_fn())
	Instance.new("UICorner", bb).CornerRadius = UDim.new(0, THEME.cornerSm)
	bb.Parent = row
	local function refresh()
		bb.Text = bind_display_name(get_fn())
	end
	bb.MouseButton1Click:Connect(function()
		if listening_btn and listening_btn ~= bb then
			listening_btn.Text = bind_display_name(listening_get())
		end
		listening_btn = bb
		listening_set = set_fn
		listening_get = get_fn
		listening_armed = false
		bb.Text = "···"
		task.delay(0.18, function()
			if listening_btn == bb then
				listening_armed = true
			end
		end)
	end)
	return refresh
end

local function refresh_configs()
	for _, c in ipairs(list_scroller:GetChildren()) do
		if c:IsA("Frame") then
			c:Destroy()
		end
	end
	local files = {}
	pcall(function()
		ensure_config_dir()
		if listfiles then
			files = listfiles(CONFIG_FOLDER)
		end
	end)
	local function make_card(name)
		local card = Instance.new("Frame")
		card.LayoutOrder = 1
		card.BackgroundColor3 = C.panel
		card.Size = UDim2.new(1, 0, 0, 52)
		card.Parent = list_scroller
		Instance.new("UICorner", card).CornerRadius = UDim.new(0, THEME.corner)
		local stroke = Instance.new("UIStroke", card)
		stroke.Color = THEME.border
		local card_pad = Instance.new("UIPadding", card)
		card_pad.PaddingLeft = UDim.new(0, 12)
		card_pad.PaddingRight = UDim.new(0, 12)
		local lbl = Instance.new("TextLabel")
		lbl.Font = Enum.Font.GothamMedium
		lbl.Text = name
		lbl.TextColor3 = C.text
		lbl.TextSize = 12
		lbl.BackgroundTransparency = 1
		lbl.Size = UDim2.new(0.45, 0, 1, 0)
		lbl.TextXAlignment = Enum.TextXAlignment.Left
		lbl.Parent = card
		local btn_row = Instance.new("Frame")
		btn_row.BackgroundTransparency = 1
		btn_row.Size = UDim2.new(0.55, 0, 1, 0)
		btn_row.Position = UDim2.fromScale(0.45, 0)
		btn_row.Parent = card
		local bl = Instance.new("UIListLayout", btn_row)
		bl.FillDirection = Enum.FillDirection.Horizontal
		bl.HorizontalAlignment = Enum.HorizontalAlignment.Right
		bl.VerticalAlignment = Enum.VerticalAlignment.Center
		bl.Padding = UDim.new(0, 6)
		local function mkbtn(txt, col, cb)
			local btn = Instance.new("TextButton")
			btn.AutoButtonColor = false
			btn.BackgroundColor3 = C.tab_off
			btn.Text = txt
			btn.Font = Enum.Font.GothamBold
			btn.TextSize = 10
			btn.TextColor3 = col
			btn.Size = UDim2.fromOffset(44, 28)
			btn.Parent = btn_row
			Instance.new("UICorner", btn).CornerRadius = UDim.new(0, THEME.cornerSm)
			btn.MouseButton1Click:Connect(cb)
		end
		local safe_path = CONFIG_FOLDER .. "/" .. name .. ".json"
		mkbtn("LOAD", C.accent, function()
			local ok = pcall(function()
				local raw = readfile(safe_path)
				local cfg = http:JSONDecode(raw)
				if typeof(_G.apply_config) == "function" then
					_G.apply_config(cfg)
				end
			end)
			if typeof(_G.mya_notify) == "function" then
				_G.mya_notify("Config", ok and ("Loaded: " .. name) or ("Load failed: " .. name), 3)
			end
		end)
		mkbtn("SAVE", C.green, function()
			local ok = pcall(function()
				local gc = _G.get_config
				if typeof(gc) == "function" then
					writefile(safe_path, http:JSONEncode(gc()))
					refresh_configs()
				end
			end)
			if typeof(_G.mya_notify) == "function" then
				_G.mya_notify("Config", ok and ("Saved: " .. name) or ("Save failed: " .. name), 3)
			end
		end)
		mkbtn("X", C.red, function()
			pcall(delfile, safe_path)
			refresh_configs()
		end)
	end
	for _, p in ipairs(files) do
		local n = string.match(p, "([^\\/]+)%.json$")
		if n then
			make_card(n)
		end
	end
end

local cfg_footer = Instance.new("Frame")
cfg_footer.BackgroundColor3 = C.panel
cfg_footer.BorderSizePixel = 0
cfg_footer.Size = UDim2.new(1, 0, 0, CFG_FOOTER_H)
cfg_footer.AnchorPoint = Vector2.new(0, 1)
cfg_footer.Position = UDim2.new(0, 0, 1, -12)
cfg_footer.Parent = configs_outer
Instance.new("UICorner", cfg_footer).CornerRadius = UDim.new(0, THEME.corner)
local foot_pad = Instance.new("UIPadding", cfg_footer)
foot_pad.PaddingLeft = UDim.new(0, 12)
foot_pad.PaddingRight = UDim.new(0, 12)
local cin = Instance.new("TextBox")
cin.Font = Enum.Font.Gotham
cin.PlaceholderText = "New config name..."
cin.PlaceholderColor3 = C.dim
cin.Text = ""
cin.TextColor3 = C.text
cin.TextSize = 12
cin.BackgroundTransparency = 1
cin.Position = UDim2.fromOffset(0, 0)
cin.Size = UDim2.new(1, -84, 1, 0)
cin.TextXAlignment = Enum.TextXAlignment.Left
cin.Parent = cfg_footer
local create_btn = Instance.new("TextButton")
create_btn.AutoButtonColor = false
create_btn.BackgroundColor3 = C.accent
create_btn.Text = "CREATE"
create_btn.Font = Enum.Font.GothamBold
create_btn.TextSize = 11
create_btn.TextColor3 = Color3.new(1, 1, 1)
create_btn.Size = UDim2.fromOffset(76, 28)
create_btn.AnchorPoint = Vector2.new(1, 0.5)
create_btn.Position = UDim2.new(1, 0, 0.5, 0)
create_btn.Parent = cfg_footer
Instance.new("UICorner", create_btn).CornerRadius = UDim.new(0, THEME.cornerSm)
create_btn.MouseButton1Click:Connect(function()
	local n = cin.Text:gsub("^%s+", ""):gsub("%s+$", "")
	if n == "" then
		return
	end
	local ok = pcall(function()
		local gc = _G.get_config
		if typeof(gc) == "function" then
			writefile(CONFIG_FOLDER .. "/" .. n .. ".json", http:JSONEncode(gc()))
		end
	end)
	cin.Text = ""
	refresh_configs()
	if typeof(_G.mya_notify) == "function" then
		_G.mya_notify("Config", ok and ("Created: " .. n) or "Create failed", 3)
	end
end)
refresh_configs()

local lo = 0
local function next_order()
	lo += 1
	return lo
end

lo = 0
section_label(visuals_player_esp, "Player ESP", next_order())
local r_esp = make_toggle_row(visuals_player_esp, "Player ESP", next_order(), P.get_player_esp, P.set_player_esp)
local r_tracers = make_toggle_row(visuals_player_esp, "Tracers", next_order(), P.get_tracers, P.set_tracers)
local r_health = make_toggle_row(visuals_player_esp, "Health bar", next_order(), P.get_health_bar, P.set_health_bar)
local r_distance = make_toggle_row(visuals_player_esp, "Distance", next_order(), P.get_distance, P.set_distance)
local r_names = make_toggle_row(visuals_player_esp, "Usernames", next_order(), P.get_usernames, P.set_usernames)
local r_team_mode = make_toggle_row(visuals_player_esp, "Team mode", next_order(), P.get_team_mode, P.set_team_mode)

lo = 0
section_label(visuals_trader_esp, "Wandering Trader ESP", next_order())
local r_trader_esp = make_toggle_row(visuals_trader_esp, "Wandering Trader ESP", next_order(), P.get_trader_esp, P.set_trader_esp)
local r_trader_tracers = make_toggle_row(visuals_trader_esp, "Wandering Trader tracers", next_order(), P.get_trader_tracers, P.set_trader_tracers)

lo = 0
section_label(movement_page, "Movement", next_order())
local r_noclip = make_toggle_row(movement_page, "Noclip", next_order(), P.get_noclip, P.set_noclip)
local r_noclip_bind = make_keybind_row(movement_page, "Noclip bind", next_order(), P.get_noclip_bind, P.set_noclip_bind)
local noclip_hint_row = make_row(movement_page, next_order(), 34)
local noclip_hint = Instance.new("TextLabel")
noclip_hint.BackgroundTransparency = 1
noclip_hint.Size = UDim2.new(1, -28, 1, 0)
noclip_hint.Position = UDim2.fromOffset(14, 0)
noclip_hint.Font = Enum.Font.Gotham
noclip_hint.TextSize = 12
noclip_hint.TextColor3 = C.dim
noclip_hint.TextXAlignment = Enum.TextXAlignment.Left
noclip_hint.TextWrapped = true
noclip_hint.Text = "Only works on doors"
noclip_hint.Parent = noclip_hint_row
local movement_spacer = Instance.new("Frame")
movement_spacer.LayoutOrder = next_order()
movement_spacer.BackgroundTransparency = 1
movement_spacer.Size = UDim2.new(1, 0, 0, 10)
movement_spacer.Parent = movement_page
local r_speed = make_toggle_row(movement_page, "Speed", next_order(), P.get_speed, P.set_speed)
local r_speed_bind = make_keybind_row(movement_page, "Speed bind", next_order(), P.get_speed_bind, P.set_speed_bind)
local set_speed_slider = make_slider(movement_page, "Speed value", next_order(), 0, 200, P.get_speed_value(), "%.0f", function(v)
	P.set_speed_value(v)
end)
local movement_spacer_2 = Instance.new("Frame")
movement_spacer_2.LayoutOrder = next_order()
movement_spacer_2.BackgroundTransparency = 1
movement_spacer_2.Size = UDim2.new(1, 0, 0, 10)
movement_spacer_2.Parent = movement_page
local r_fly = make_toggle_row(movement_page, "Fly", next_order(), P.get_fly, P.set_fly)
local r_fly_bind = make_keybind_row(movement_page, "Fly bind", next_order(), P.get_fly_bind, P.set_fly_bind)
local set_fly_slider = make_slider(movement_page, "Fly speed", next_order(), 5, 500, P.get_fly_speed(), "%.0f", function(v)
	P.set_fly_speed(v)
end)

lo = 0
section_label(misc_page, "Misc", next_order())
local r_noclip_cam = make_toggle_row(misc_page, "NoClipCam", next_order(), P.get_noclip_cam, P.set_noclip_cam)
local r_water_walker = make_toggle_row(misc_page, "Water Walker", next_order(), P.get_water_walker, P.set_water_walker)

lo = 0
section_label(settings_page, "Script", next_order())
local hint_row = make_row(settings_page, next_order(), 44)
local hint = Instance.new("TextLabel")
hint.BackgroundTransparency = 1
hint.Size = UDim2.new(1, -28, 1, 0)
hint.Position = UDim2.fromOffset(14, 0)
hint.Font = Enum.Font.Gotham
hint.TextSize = 12
hint.TextColor3 = C.dim
hint.TextXAlignment = Enum.TextXAlignment.Left
hint.TextWrapped = true
hint.Text = "Delete toggles menu"
hint.Parent = hint_row
local unload_row = make_row(settings_page, next_order(), 44)
local unload_btn = Instance.new("TextButton")
unload_btn.Size = UDim2.new(1, -28, 0, 32)
unload_btn.Position = UDim2.fromOffset(14, 6)
unload_btn.BackgroundColor3 = THEME.danger:Lerp(THEME.bg, 0.52)
unload_btn.TextColor3 = C.text
unload_btn.Font = Enum.Font.GothamBold
unload_btn.TextSize = 13
unload_btn.Text = "Unload Booga"
unload_btn.AutoButtonColor = false
unload_btn.Parent = unload_row
Instance.new("UICorner", unload_btn).CornerRadius = UDim.new(0, THEME.corner)
unload_btn.MouseButton1Click:Connect(function()
	if typeof(_G.unload_mya_booga) == "function" then
		_G.unload_mya_booga()
	end
end)

local menu_key = Enum.KeyCode.Delete
uis.InputBegan:Connect(function(input, gp)
	if listening_btn and listening_set and listening_get and listening_armed then
		if input.UserInputType == Enum.UserInputType.Keyboard then
			if input.KeyCode ~= Enum.KeyCode.Unknown then
				listening_set(input.KeyCode)
			end
		elseif input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.MouseButton2 or input.UserInputType == Enum.UserInputType.MouseButton3 then
			listening_set(input.UserInputType)
		end
		listening_btn.Text = bind_display_name(listening_get())
		listening_btn = nil
		listening_set = nil
		listening_get = nil
		listening_armed = false
		if typeof(_G.MYA_BOOGA_SYNC_UI) == "function" then
			_G.MYA_BOOGA_SYNC_UI()
		end
		return
	end
	if gp then
		return
	end
	if input.KeyCode == menu_key then
		ui.Enabled = not ui.Enabled
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
	r_trader_esp()
	r_trader_tracers()
	r_noclip()
	r_noclip_bind()
	r_speed()
	r_speed_bind()
	set_speed_slider(P.get_speed_value())
	r_fly()
	r_fly_bind()
	set_fly_slider(P.get_fly_speed())
	r_noclip_cam()
	r_water_walker()
end

task.defer(function()
	_G.MYA_BOOGA_SYNC_UI()
end)

switch_tab("Visuals")
notify("Mya", "Booga Booga ready", 3)
