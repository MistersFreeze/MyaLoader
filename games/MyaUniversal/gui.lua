--[[ Mya Universal — Operation One style UI ]]
local P = _G.MYA_UNIVERSAL
if not P then
	error("[MyaUniversal] Load runtime.lua first")
end

local gethui_support = gethui ~= nil
local cloneref_fn = type(cloneref) == "function" and cloneref or function(x)
	return x
end
local uis = cloneref_fn(game:GetService("UserInputService"))
local http = game:GetService("HttpService")
local ts = game:GetService("TweenService")

local CONFIG_FOLDER = "mya_universal_configs"
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

local C = {
	bg = Color3.fromRGB(14, 16, 20),
	panel = Color3.fromRGB(22, 24, 30),
	header = Color3.fromRGB(18, 20, 26),
	tab_off = Color3.fromRGB(26, 28, 34),
	tab_on = Color3.fromRGB(230, 120, 175),
	accent = Color3.fromRGB(230, 120, 175),
	row_hover = Color3.fromRGB(32, 34, 42),
	tog_off = Color3.fromRGB(48, 50, 58),
	tog_on = Color3.fromRGB(230, 120, 175),
	text = Color3.fromRGB(236, 238, 244),
	dim = Color3.fromRGB(120, 124, 138),
	slid_bg = Color3.fromRGB(38, 40, 48),
	slid_fg = Color3.fromRGB(230, 120, 175),
	input_bg = Color3.fromRGB(28, 30, 38),
	sub_off = Color3.fromRGB(30, 32, 40),
	sub_on = Color3.fromRGB(230, 120, 175),
	red = Color3.fromRGB(220, 80, 80),
	green = Color3.fromRGB(90, 200, 130),
}

local ui = Instance.new("ScreenGui")
ui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ui.Name = rand_str(6)
ui.IgnoreGuiInset = true
ui.DisplayOrder = 10
ui.ResetOnSpawn = false
ui.Parent = gethui_support and gethui() or game:GetService("CoreGui")
_G.mya_universal_ui = ui

local notif_ui = Instance.new("ScreenGui")
notif_ui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
notif_ui.Name = rand_str(6) .. "_N"
notif_ui.IgnoreGuiInset = true
notif_ui.DisplayOrder = 100
notif_ui.Enabled = true
notif_ui.ResetOnSpawn = false
notif_ui.Parent = gethui_support and gethui() or game:GetService("CoreGui")
_G.mya_universal_notif_ui = notif_ui

local notif_top = Instance.new("Frame")
notif_top.BackgroundTransparency = 1
notif_top.Size = UDim2.fromScale(1, 1)
notif_top.Parent = notif_ui

local notif_container = Instance.new("Frame", notif_top)
notif_container.BackgroundTransparency = 1
notif_container.Size = UDim2.fromOffset(260, 400)
notif_container.Position = UDim2.new(1, -270, 1, -420)

local n_layout = Instance.new("UIListLayout", notif_container)
n_layout.FillDirection = Enum.FillDirection.Vertical
n_layout.HorizontalAlignment = Enum.HorizontalAlignment.Right
n_layout.VerticalAlignment = Enum.VerticalAlignment.Bottom
n_layout.Padding = UDim.new(0, 8)

local function notify(title, text, duration)
	duration = duration or 3
	local f = Instance.new("Frame")
	f.BackgroundColor3 = C.panel
	f.Size = UDim2.fromOffset(250, 55)
	f.Position = UDim2.fromOffset(260, 0)
	Instance.new("UICorner", f).CornerRadius = UDim.new(0, 4)
	local str = Instance.new("UIStroke", f)
	str.Color = Color3.fromRGB(40, 40, 55)

	local lbl_t = Instance.new("TextLabel", f)
	lbl_t.BackgroundTransparency = 1
	lbl_t.Position = UDim2.fromOffset(16, 8)
	lbl_t.Size = UDim2.new(1, -24, 0, 16)
	lbl_t.Font = Enum.Font.GothamBold
	lbl_t.Text = title
	lbl_t.TextColor3 = C.accent
	lbl_t.TextSize = 12
	lbl_t.TextXAlignment = Enum.TextXAlignment.Left

	local lbl_d = Instance.new("TextLabel", f)
	lbl_d.BackgroundTransparency = 1
	lbl_d.Position = UDim2.fromOffset(16, 26)
	lbl_d.Size = UDim2.new(1, -24, 0, 16)
	lbl_d.Font = Enum.Font.Gotham
	lbl_d.Text = text
	lbl_d.TextColor3 = C.text
	lbl_d.TextSize = 11
	lbl_d.TextXAlignment = Enum.TextXAlignment.Left
	lbl_d.TextWrapped = true

	local stripe = Instance.new("Frame", f)
	stripe.BackgroundColor3 = C.accent
	stripe.BorderSizePixel = 0
	stripe.Size = UDim2.new(0, 3, 1, 0)
	Instance.new("UICorner", stripe).CornerRadius = UDim.new(0, 4)

	f.Parent = notif_container
	ts:Create(f, TweenInfo.new(0.4, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out), { Position = UDim2.new(0, 0, 0, 0) }):Play()

	task.spawn(function()
		task.wait(duration)
		if not f or not f.Parent then
			return
		end
		local t_out = ts:Create(f, TweenInfo.new(0.4, Enum.EasingStyle.Cubic, Enum.EasingDirection.In), { Position = UDim2.fromOffset(260, 0), BackgroundTransparency = 1 })
		t_out:Play()
		ts:Create(str, TweenInfo.new(0.4), { Transparency = 1 }):Play()
		ts:Create(lbl_t, TweenInfo.new(0.4), { TextTransparency = 1 }):Play()
		ts:Create(lbl_d, TweenInfo.new(0.4), { TextTransparency = 1 }):Play()
		ts:Create(stripe, TweenInfo.new(0.4), { BackgroundTransparency = 1 }):Play()
		t_out.Completed:Wait()
		f:Destroy()
	end)
end
_G.mya_notify = notify

local WIN_W, WIN_H = 360, 580
local main = Instance.new("Frame")
main.Name = "main"
main.BackgroundColor3 = C.bg
main.BorderSizePixel = 0
main.Position = UDim2.new(0.5, 80, 0.5, 0)
main.AnchorPoint = Vector2.new(0.5, 0.5)
main.Size = UDim2.fromOffset(WIN_W, WIN_H)
main.Parent = ui
Instance.new("UICorner", main).CornerRadius = UDim.new(0, 8)

local accentBar = Instance.new("Frame")
accentBar.BackgroundColor3 = C.accent
accentBar.BorderSizePixel = 0
accentBar.Size = UDim2.new(0, 4, 1, 0)
accentBar.Parent = main
Instance.new("UICorner", accentBar).CornerRadius = UDim.new(0, 8)

local header = Instance.new("Frame")
header.BackgroundColor3 = C.header
header.BorderSizePixel = 0
header.Size = UDim2.new(1, -4, 0, 40)
header.Position = UDim2.new(0, 4, 0, 0)
header.Parent = main
Instance.new("UICorner", header).CornerRadius = UDim.new(0, 8)
local hdr_sq = Instance.new("Frame")
hdr_sq.BackgroundColor3 = C.header
hdr_sq.BorderSizePixel = 0
hdr_sq.Position = UDim2.fromOffset(0, 28)
hdr_sq.Size = UDim2.new(1, 0, 0, 14)
hdr_sq.Parent = header

local title_lbl = Instance.new("TextLabel")
title_lbl.Font = Enum.Font.GothamBold
title_lbl.Text = "MYA UNIVERSAL"
title_lbl.TextColor3 = C.text
title_lbl.TextSize = 14
title_lbl.BackgroundTransparency = 1
title_lbl.Position = UDim2.fromOffset(14, 0)
title_lbl.Size = UDim2.new(1, -24, 1, 0)
title_lbl.TextXAlignment = Enum.TextXAlignment.Left
title_lbl.Parent = header

local TAB_NAMES = { "Combat", "Visuals", "Movement", "Configs", "Settings" }
local SUB_PAGES = {
	Combat = { "Aim assist", "Triggerbot" },
	Visuals = { "ESP" },
	Movement = { "Flight", "Walk & jump", "Noclip" },
}

local tab_bar = Instance.new("Frame")
tab_bar.BackgroundColor3 = C.header
tab_bar.BorderSizePixel = 0
tab_bar.Position = UDim2.fromOffset(4, 40)
tab_bar.Size = UDim2.new(1, -4, 0, 30)
tab_bar.Parent = main
Instance.new("UIListLayout", tab_bar).FillDirection = Enum.FillDirection.Horizontal

local sub_bar = Instance.new("Frame")
sub_bar.BackgroundColor3 = C.bg
sub_bar.BorderSizePixel = 0
sub_bar.Position = UDim2.fromOffset(4, 70)
sub_bar.Size = UDim2.new(1, -4, 0, 26)
sub_bar.Visible = false
sub_bar.Parent = main
local _sub_layout = Instance.new("UIListLayout", sub_bar)
_sub_layout.FillDirection = Enum.FillDirection.Horizontal
_sub_layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
_sub_layout.Padding = UDim.new(0, 4)
_sub_layout.VerticalAlignment = Enum.VerticalAlignment.Center

local tab_buttons = {}
local tab_containers = {}
local all_sub_buttons = {}
local all_sub_pages = {}

local content = Instance.new("Frame")
content.BackgroundTransparency = 1
content.BorderSizePixel = 0
content.Position = UDim2.fromOffset(4, 70)
content.Size = UDim2.new(1, -4, 1, -70)
content.ClipsDescendants = true
content.Parent = main

local function make_page()
	local page = Instance.new("ScrollingFrame")
	page.BackgroundTransparency = 1
	page.BorderSizePixel = 0
	page.Size = UDim2.fromScale(1, 1)
	page.CanvasSize = UDim2.fromOffset(0, 0)
	page.AutomaticCanvasSize = Enum.AutomaticSize.Y
	page.ScrollBarThickness = 3
	page.ScrollBarImageColor3 = C.accent
	local ul = Instance.new("UIListLayout")
	ul.SortOrder = Enum.SortOrder.LayoutOrder
	ul.Padding = UDim.new(0, 0)
	ul.Parent = page
	local up = Instance.new("UIPadding")
	up.PaddingTop = UDim.new(0, 6)
	up.PaddingBottom = UDim.new(0, 12)
	up.Parent = page
	return page
end

local function switch_sub(tab_name, sub_name)
	local subs = all_sub_pages[tab_name]
	local btns = all_sub_buttons[tab_name]
	if not subs then
		return
	end
	for n, pg in pairs(subs) do
		pg.Visible = (n == sub_name)
	end
	if btns then
		for n, b in pairs(btns) do
			b.BackgroundColor3 = (n == sub_name) and C.sub_on or C.sub_off
			b.TextColor3 = (n == sub_name) and Color3.fromRGB(45, 18, 32) or C.dim
		end
	end
end

local function switch_tab(name)
	local has_subs = SUB_PAGES[name] ~= nil
	for n, cont in pairs(tab_containers) do
		cont.Visible = (n == name)
	end
	for n, b in pairs(tab_buttons) do
		b.BackgroundColor3 = (n == name) and C.tab_on or C.tab_off
		b.TextColor3 = (n == name) and Color3.fromRGB(45, 18, 32) or C.dim
	end
	sub_bar.Visible = has_subs
	if has_subs then
		content.Position = UDim2.fromOffset(4, 96)
		content.Size = UDim2.new(1, -4, 1, -96)
	else
		content.Position = UDim2.fromOffset(4, 70)
		content.Size = UDim2.new(1, -4, 1, -70)
	end
	for _, c in ipairs(sub_bar:GetChildren()) do
		if c:IsA("TextButton") then
			c:Destroy()
		end
	end
	if has_subs then
		local sub_names = SUB_PAGES[name]
		all_sub_buttons[name] = all_sub_buttons[name] or {}
		for i, sn in ipairs(sub_names) do
			local sb = Instance.new("TextButton")
			sb.LayoutOrder = i
			sb.BackgroundColor3 = C.sub_off
			sb.BorderSizePixel = 0
			sb.Size = UDim2.fromOffset(math.floor((WIN_W - 8 - (#sub_names - 1) * 4) / #sub_names), 20)
			sb.Font = Enum.Font.GothamSemibold
			sb.Text = sn
			sb.TextColor3 = C.dim
			sb.TextSize = 10
			sb.AutoButtonColor = false
			sb.Parent = sub_bar
			Instance.new("UICorner", sb).CornerRadius = UDim.new(0, 8)
			sb.MouseButton1Click:Connect(function()
				switch_sub(name, sn)
			end)
			all_sub_buttons[name][sn] = sb
		end
		switch_sub(name, sub_names[1])
	end
end

for i, name in ipairs(TAB_NAMES) do
	local b = Instance.new("TextButton")
	b.AutoButtonColor = false
	b.Text = name
	b.Font = Enum.Font.GothamSemibold
	b.TextSize = 9
	b.BackgroundColor3 = C.tab_off
	b.TextColor3 = C.dim
	b.BorderSizePixel = 0
	b.Size = UDim2.new(1 / #TAB_NAMES, 0, 1, 0)
	b.LayoutOrder = i
	b.Parent = tab_bar
	tab_buttons[name] = b
	b.MouseButton1Click:Connect(function()
		switch_tab(name)
	end)
end

for _, name in ipairs(TAB_NAMES) do
	local cont = Instance.new("Frame")
	cont.BackgroundTransparency = 1
	cont.Size = UDim2.fromScale(1, 1)
	cont.Visible = false
	cont.Parent = content
	tab_containers[name] = cont
	if SUB_PAGES[name] then
		all_sub_pages[name] = {}
		for _, sn in ipairs(SUB_PAGES[name]) do
			local pg = make_page()
			pg.Visible = false
			pg.Parent = cont
			all_sub_pages[name][sn] = pg
		end
	end
end

local combat_aim = all_sub_pages["Combat"]["Aim assist"]
local combat_trigger = all_sub_pages["Combat"]["Triggerbot"]
local visuals_esp = all_sub_pages["Visuals"]["ESP"]
local movement_fly = all_sub_pages["Movement"]["Flight"]
local movement_walk = all_sub_pages["Movement"]["Walk & jump"]
local movement_noclip = all_sub_pages["Movement"]["Noclip"]

local configs_page = make_page()
configs_page.Visible = true
configs_page.Parent = tab_containers["Configs"]
for _, ch in ipairs(configs_page:GetChildren()) do
	if ch:IsA("UIPadding") then
		ch.PaddingBottom = UDim.new(0, 4)
		break
	end
end

local settings_page = make_page()
settings_page.Visible = true
settings_page.Parent = tab_containers["Settings"]

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
	row.BackgroundColor3 = Color3.fromRGB(20, 20, 26)
	row.BorderSizePixel = 0
	row.Size = UDim2.new(1, 0, 0, h)
	row.Parent = parent
	local sep = Instance.new("Frame")
	sep.BackgroundColor3 = Color3.fromRGB(35, 35, 45)
	sep.BorderSizePixel = 0
	sep.Position = UDim2.new(0, 0, 1, -1)
	sep.Size = UDim2.new(1, 0, 0, 1)
	sep.Parent = row
	row.MouseEnter:Connect(function()
		row.BackgroundColor3 = C.row_hover
	end)
	row.MouseLeave:Connect(function()
		row.BackgroundColor3 = Color3.fromRGB(20, 20, 26)
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
		if bind == Enum.UserInputType.MouseButton1 then
			return "Mouse 1"
		end
		if bind == Enum.UserInputType.MouseButton2 then
			return "Mouse 2"
		end
		if bind == Enum.UserInputType.MouseButton3 then
			return "Mouse 3"
		end
		return bind.Name
	end
	if bind.EnumType == Enum.KeyCode then
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
	Instance.new("UICorner", bb).CornerRadius = UDim.new(0, 4)
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

local lo = 0
local function next_order()
	lo = lo + 1
	return lo
end

lo = 0
section_label(combat_aim, "Aim assist", next_order())
local ref_aim_toggle = make_toggle_row(combat_aim, "Aim assist", next_order(), P.get_aim, P.set_aim)
local ref_aim_bind = make_keybind_row(combat_aim, "Aim assist bind", next_order(), P.get_aim_bind, P.set_aim_bind)
local set_aim_fov_slider = make_slider(combat_aim, "Aim assist FOV", next_order(), 40, 400, P.get_aim_fov(), "%.0f", function(v)
	P.set_aim_fov(v)
end)
local set_aim_speed_slider = make_slider(combat_aim, "Aim strength", next_order(), 0.05, 1, P.get_aim_speed(), "%.2f", function(v)
	P.set_aim_speed(v)
end)
local ref_show_aim_fov = make_toggle_row(combat_aim, "Show aim FOV ring", next_order(), P.get_show_aim_fov_circle, P.set_show_aim_fov_circle)
local ref_aim_fov_follow = make_toggle_row(combat_aim, "FOV follows cursor", next_order(), P.get_aim_fov_follow_cursor, P.set_aim_fov_follow_cursor)
section_label(combat_aim, "Targeting", next_order())
local ref_vis = make_toggle_row(combat_aim, "Visibility check", next_order(), P.get_vis_check, P.set_vis_check)

lo = 0
section_label(combat_trigger, "Triggerbot", next_order())
local ref_trigger_toggle = make_toggle_row(combat_trigger, "Triggerbot", next_order(), P.get_triggerbot, P.set_triggerbot)
local ref_trigger_bind = make_keybind_row(combat_trigger, "Triggerbot bind", next_order(), P.get_trigger_bind, P.set_trigger_bind)
local set_trigger_fov_slider = make_slider(combat_trigger, "Trigger FOV", next_order(), 5, 120, P.get_trigger_fov(), "%.0f", function(v)
	P.set_trigger_fov(v)
end)
local set_trigger_delay_slider = make_slider(combat_trigger, "Trigger delay", next_order(), 0.03, 0.5, P.get_trigger_delay(), "%.2f", function(v)
	P.set_trigger_delay(v)
end)

lo = 0
section_label(visuals_esp, "ESP", next_order())
local ref_esp = make_toggle_row(visuals_esp, "ESP highlights", next_order(), P.get_esp, P.set_esp)
local ref_team = make_toggle_row(visuals_esp, "Team check", next_order(), P.get_team_check, P.set_team_check)
local ref_health = make_toggle_row(visuals_esp, "Health bars", next_order(), P.get_healthbars, P.set_healthbars)
local ref_esp_dist = make_toggle_row(visuals_esp, "Distance text", next_order(), P.get_esp_distance, P.set_esp_distance)
local ref_esp_names = make_toggle_row(visuals_esp, "Player names", next_order(), P.get_esp_names, P.set_esp_names)

lo = 0
section_label(configs_page, "Config manager", next_order())
local list_scroller = Instance.new("ScrollingFrame")
list_scroller.LayoutOrder = next_order()
list_scroller.Size = UDim2.new(1, 0, 0, 160)
list_scroller.BackgroundTransparency = 1
list_scroller.BorderSizePixel = 0
list_scroller.ScrollBarThickness = 3
list_scroller.ScrollBarImageColor3 = C.accent
list_scroller.CanvasSize = UDim2.fromOffset(0, 0)
list_scroller.AutomaticCanvasSize = Enum.AutomaticSize.Y
list_scroller.Parent = configs_page
local list_pad = Instance.new("UIPadding", list_scroller)
list_pad.PaddingLeft = UDim.new(0, 12)
list_pad.PaddingRight = UDim.new(0, 12)
local list_layout = Instance.new("UIListLayout", list_scroller)
list_layout.Padding = UDim.new(0, 6)
list_layout.SortOrder = Enum.SortOrder.LayoutOrder

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
		card.BackgroundColor3 = C.panel
		card.Size = UDim2.new(1, 0, 0, 52)
		card.Parent = list_scroller
		Instance.new("UICorner", card).CornerRadius = UDim.new(0, 6)
		local stroke = Instance.new("UIStroke", card)
		stroke.Color = Color3.fromRGB(40, 40, 55)
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
			btn.BackgroundColor3 = C.bg
			btn.Text = txt
			btn.Font = Enum.Font.GothamBold
			btn.TextSize = 10
			btn.TextColor3 = col
			btn.Size = UDim2.fromOffset(44, 28)
			btn.Parent = btn_row
			Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 4)
			btn.MouseButton1Click:Connect(cb)
			return btn
		end
		local safe_path = CONFIG_FOLDER .. "/" .. name .. ".json"
		mkbtn("LOAD", C.accent, function()
			local ok = pcall(function()
				ensure_config_dir()
				local raw = readfile(safe_path)
				local cfg = http:JSONDecode(raw)
				if typeof(_G.apply_config) == "function" then
					_G.apply_config(cfg)
				end
			end)
			if typeof(_G.mya_notify) == "function" then
				if ok then
					_G.mya_notify("Config", "Loaded: " .. name, 3)
				else
					_G.mya_notify("Config", "Load failed: " .. name, 3)
				end
			end
		end)
		mkbtn("SAVE", C.green, function()
			local ok = pcall(function()
				ensure_config_dir()
				local gc = _G.get_config
				if typeof(gc) == "function" then
					writefile(safe_path, http:JSONEncode(gc()))
					refresh_configs()
				end
			end)
			if typeof(_G.mya_notify) == "function" then
				if ok then
					_G.mya_notify("Config", "Saved: " .. name, 3)
				else
					_G.mya_notify("Config", "Save failed: " .. name, 3)
				end
			end
		end)
		mkbtn("X", C.red, function()
			pcall(delfile, safe_path)
			refresh_configs()
		end)
	end
	if files then
		for _, p in ipairs(files) do
			local n = string.match(p, "([^\\/]+)%.json$")
			if n then
				make_card(n)
			end
		end
	end
end

local cfg_footer = Instance.new("Frame")
cfg_footer.LayoutOrder = next_order()
cfg_footer.BackgroundColor3 = C.panel
cfg_footer.BorderSizePixel = 0
cfg_footer.Size = UDim2.new(1, 0, 0, 40)
cfg_footer.Parent = configs_page
Instance.new("UICorner", cfg_footer).CornerRadius = UDim.new(0, 6)
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
Instance.new("UICorner", create_btn).CornerRadius = UDim.new(0, 4)
create_btn.MouseButton1Click:Connect(function()
	local n = cin.Text:gsub("^%s+", ""):gsub("%s+$", "")
	if n == "" then
		return
	end
	local ok = pcall(function()
		ensure_config_dir()
		local gc = _G.get_config
		if typeof(gc) ~= "function" then
			return
		end
		writefile(CONFIG_FOLDER .. "/" .. n .. ".json", http:JSONEncode(gc()))
	end)
	cin.Text = ""
	refresh_configs()
	if typeof(_G.mya_notify) == "function" then
		if ok then
			_G.mya_notify("Config", "Created: " .. n, 3)
		else
			_G.mya_notify("Config", "Create failed", 3)
		end
	end
end)

refresh_configs()

lo = 0
section_label(movement_fly, "Flight", next_order())
local ref_fly = make_toggle_row(movement_fly, "Fly", next_order(), P.get_fly, P.set_fly)
local set_fly_speed_slider = make_slider(movement_fly, "Fly speed", next_order(), 5, 200, P.get_fly_speed(), "%.0f", function(v)
	P.set_fly_speed(v)
end)

lo = 0
section_label(movement_walk, "Walk & jump", next_order())
local ref_walk_mod = make_toggle_row(movement_walk, "Walk speed override", next_order(), P.get_walk_mod, P.set_walk_mod)
local set_walk_slider = make_slider(movement_walk, "Walk speed", next_order(), 0, 200, P.get_walk(), "%.0f", function(v)
	P.set_walk(v)
end)
local ref_jump_mod = make_toggle_row(movement_walk, "Jump power override", next_order(), P.get_jump_mod, P.set_jump_mod)
local set_jump_slider = make_slider(movement_walk, "Jump power", next_order(), 0, 500, P.get_jump(), "%.0f", function(v)
	P.set_jump(v)
end)

lo = 0
section_label(movement_noclip, "Noclip", next_order())
local ref_nc = make_toggle_row(movement_noclip, "Noclip", next_order(), P.get_noclip, P.set_noclip)

lo = 0
section_label(settings_page, "Menu", next_order())
local hint_row = make_row(settings_page, next_order(), 52)
local hint = Instance.new("TextLabel")
hint.BackgroundTransparency = 1
hint.Size = UDim2.new(1, -28, 1, 0)
hint.Position = UDim2.fromOffset(14, 0)
hint.Font = Enum.Font.Gotham
hint.TextSize = 11
hint.TextColor3 = C.dim
hint.TextXAlignment = Enum.TextXAlignment.Left
hint.TextWrapped = true
hint.Text = "Insert toggles this window. Drag the header to move. Click a bind button, then press a key or mouse button."
hint.Parent = hint_row

local unload_row = make_row(settings_page, next_order(), 44)
local unload_btn = Instance.new("TextButton")
unload_btn.Size = UDim2.new(1, -28, 0, 32)
unload_btn.Position = UDim2.fromOffset(14, 6)
unload_btn.BackgroundColor3 = Color3.fromRGB(80, 50, 60)
unload_btn.TextColor3 = C.text
unload_btn.Font = Enum.Font.GothamBold
unload_btn.TextSize = 13
unload_btn.Text = "Unload Mya Universal"
unload_btn.AutoButtonColor = false
unload_btn.Parent = unload_row
Instance.new("UICorner", unload_btn).CornerRadius = UDim.new(0, 6)
unload_btn.MouseButton1Click:Connect(function()
	if typeof(_G.unload_mya_universal) == "function" then
		_G.unload_mya_universal()
	end
end)

local menu_key = Enum.KeyCode.Insert
uis.InputBegan:Connect(function(input, gp)
	if listening_btn and listening_set and listening_get and listening_armed then
		if input.UserInputType == Enum.UserInputType.Keyboard then
			if input.KeyCode ~= Enum.KeyCode.Unknown then
				listening_set(input.KeyCode)
			end
		elseif
			input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.MouseButton2
			or input.UserInputType == Enum.UserInputType.MouseButton3
		then
			listening_set(input.UserInputType)
		end
		listening_btn.Text = bind_display_name(listening_get())
		listening_btn = nil
		listening_set = nil
		listening_get = nil
		listening_armed = false
		return
	end
	if gp then
		return
	end
	if input.KeyCode == menu_key then
		ui.Enabled = not ui.Enabled
	end
end)

local drag_con = nil
header.InputBegan:Connect(function(inp)
	if inp.UserInputType ~= Enum.UserInputType.MouseButton1 then
		return
	end
	local st, sp = inp.Position, main.Position
	if drag_con then
		drag_con:Disconnect()
	end
	drag_con = uis.InputChanged:Connect(function(i)
		if i.UserInputType == Enum.UserInputType.MouseMovement then
			local d = i.Position - st
			main.Position = UDim2.new(sp.X.Scale, sp.X.Offset + d.X, sp.Y.Scale, sp.Y.Offset + d.Y)
		end
	end)
end)
header.InputEnded:Connect(function(inp)
	if inp.UserInputType == Enum.UserInputType.MouseButton1 and drag_con then
		drag_con:Disconnect()
		drag_con = nil
	end
end)

switch_tab("Combat")

task.defer(function()
	set_aim_fov_slider(P.get_aim_fov())
	set_aim_speed_slider(P.get_aim_speed())
	set_trigger_fov_slider(P.get_trigger_fov())
	set_trigger_delay_slider(P.get_trigger_delay())
	set_fly_speed_slider(P.get_fly_speed())
	set_walk_slider(P.get_walk())
	set_jump_slider(P.get_jump())
end)

function _G.MYA_UNIVERSAL_SYNC_UI()
	ref_esp()
	ref_team()
	ref_health()
	ref_esp_dist()
	ref_esp_names()
	ref_aim_toggle()
	ref_aim_bind()
	ref_vis()
	ref_show_aim_fov()
	ref_aim_fov_follow()
	ref_fly()
	ref_walk_mod()
	ref_jump_mod()
	ref_nc()
	ref_trigger_toggle()
	ref_trigger_bind()
	set_aim_fov_slider(P.get_aim_fov())
	set_aim_speed_slider(P.get_aim_speed())
	set_trigger_fov_slider(P.get_trigger_fov())
	set_trigger_delay_slider(P.get_trigger_delay())
	set_fly_speed_slider(P.get_fly_speed())
	set_walk_slider(P.get_walk())
	set_jump_slider(P.get_jump())
end
