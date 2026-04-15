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
}

local ui = Instance.new("ScreenGui")
ui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ui.Name = rand_str(6)
ui.IgnoreGuiInset = true
ui.DisplayOrder = 10
ui.ResetOnSpawn = false
ui.Parent = gethui_support and gethui() or game:GetService("CoreGui")
_G.mya_universal_ui = ui

local WIN_W, WIN_H = 360, 560
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

local TAB_NAMES = { "Combat", "Visuals", "Movement" }
local tab_bar = Instance.new("Frame")
tab_bar.BackgroundColor3 = C.header
tab_bar.BorderSizePixel = 0
tab_bar.Position = UDim2.fromOffset(4, 40)
tab_bar.Size = UDim2.new(1, -4, 0, 30)
tab_bar.Parent = main
Instance.new("UIListLayout", tab_bar).FillDirection = Enum.FillDirection.Horizontal

local tab_buttons = {}
local tab_containers = {}
local active_tab = nil

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
	up.Parent = page
	return page
end

for _, name in ipairs(TAB_NAMES) do
	local c = Instance.new("Frame")
	c.Name = name
	c.BackgroundTransparency = 1
	c.Size = UDim2.fromScale(1, 1)
	c.Visible = false
	c.Parent = content
	tab_containers[name] = c

	local page = make_page()
	page.Parent = c
end

local function switch_tab(name)
	active_tab = name
	for n, cont in pairs(tab_containers) do
		cont.Visible = (n == name)
	end
	for n, b in pairs(tab_buttons) do
		b.BackgroundColor3 = (n == name) and C.tab_on or C.tab_off
		b.TextColor3 = (n == name) and Color3.fromRGB(45, 18, 32) or C.dim
	end
end

for i, name in ipairs(TAB_NAMES) do
	local b = Instance.new("TextButton")
	b.AutoButtonColor = false
	b.Text = name
	b.Font = Enum.Font.GothamSemibold
	b.TextSize = 11
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

local combat_page = tab_containers["Combat"]:FindFirstChildWhichIsA("ScrollingFrame")
local visuals_page = tab_containers["Visuals"]:FindFirstChildWhichIsA("ScrollingFrame")
local movement_page = tab_containers["Movement"]:FindFirstChildWhichIsA("ScrollingFrame")

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

local lo = 0
local function next_order()
	lo = lo + 1
	return lo
end

section_label(combat_page, "Aim assist", next_order())
local ref_aim_toggle = make_toggle_row(combat_page, "Aim assist (hold RMB)", next_order(), P.get_aim, P.set_aim)
local set_aim_fov_slider = make_slider(combat_page, "Aim assist FOV (px)", next_order(), 40, 400, P.get_aim_fov(), "%.0f", function(v)
	P.set_aim_fov(v)
end)
local set_aim_speed_slider = make_slider(combat_page, "Aim strength", next_order(), 0.05, 1, P.get_aim_speed(), "%.2f", function(v)
	P.set_aim_speed(v)
end)

section_label(combat_page, "Silent aim", next_order())
local ref_silent_toggle = make_toggle_row(combat_page, "Silent aim (ray hook)", next_order(), P.get_silent, P.set_silent)
local set_silent_fov_slider = make_slider(combat_page, "Silent aim FOV (px)", next_order(), 40, 400, P.get_silent_fov(), "%.0f", function(v)
	P.set_silent_fov(v)
end)

section_label(combat_page, "FOV display", next_order())
local ref_show_aim_fov = make_toggle_row(combat_page, "Show aim assist FOV ring", next_order(), P.get_show_aim_fov_circle, P.set_show_aim_fov_circle)
local ref_show_silent_fov = make_toggle_row(combat_page, "Show silent FOV ring", next_order(), P.get_show_silent_fov_circle, P.set_show_silent_fov_circle)

lo = 0
section_label(visuals_page, "Players", next_order())
local ref_esp = make_toggle_row(visuals_page, "ESP highlights", next_order(), P.get_esp, P.set_esp)
local ref_health = make_toggle_row(visuals_page, "Health bars", next_order(), P.get_healthbars, P.set_healthbars)

lo = 0
section_label(movement_page, "Character", next_order())
local ref_fly = make_toggle_row(movement_page, "Fly", next_order(), P.get_fly, P.set_fly)
local set_fly_speed_slider = make_slider(movement_page, "Fly speed", next_order(), 5, 200, P.get_fly_speed(), "%.0f", function(v)
	P.set_fly_speed(v)
end)
local ref_nc = make_toggle_row(movement_page, "Noclip", next_order(), P.get_noclip, P.set_noclip)
local set_walk_slider = make_slider(movement_page, "Walk speed", next_order(), 0, 200, P.get_walk(), "%.0f", function(v)
	P.set_walk(v)
end)
local set_jump_slider = make_slider(movement_page, "Jump power", next_order(), 0, 200, P.get_jump(), "%.0f", function(v)
	P.set_jump(v)
end)

local hint_row = make_row(movement_page, next_order(), 40)
local hint = Instance.new("TextLabel")
hint.BackgroundTransparency = 1
hint.Size = UDim2.new(1, -28, 1, 0)
hint.Position = UDim2.fromOffset(14, 0)
hint.Font = Enum.Font.Gotham
hint.TextSize = 11
hint.TextColor3 = C.dim
hint.TextXAlignment = Enum.TextXAlignment.Left
hint.TextWrapped = true
hint.Text = "Insert · toggle menu  ·  Drag header to move  ·  Silent aim needs executor hook support"
hint.Parent = hint_row

local close = Instance.new("TextButton")
close.Size = UDim2.new(1, -24, 0, 34)
close.Position = UDim2.new(0, 12, 1, -44)
close.BackgroundColor3 = Color3.fromRGB(80, 50, 60)
close.TextColor3 = C.text
close.Font = Enum.Font.GothamBold
close.TextSize = 13
close.Text = "Unload Mya Universal"
close.AutoButtonColor = false
close.Parent = main
Instance.new("UICorner", close).CornerRadius = UDim.new(0, 6)
close.MouseButton1Click:Connect(function()
	if typeof(_G.unload_mya_universal) == "function" then
		_G.unload_mya_universal()
	end
end)

local menu_key = Enum.KeyCode.Insert
uis.InputBegan:Connect(function(input, gp)
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
	set_silent_fov_slider(P.get_silent_fov())
	set_fly_speed_slider(P.get_fly_speed())
	set_walk_slider(P.get_walk())
	set_jump_slider(P.get_jump())
end)

function _G.MYA_UNIVERSAL_SYNC_UI()
	ref_esp()
	ref_health()
	ref_aim_toggle()
	ref_silent_toggle()
	ref_show_aim_fov()
	ref_show_silent_fov()
	ref_fly()
	ref_nc()
	set_aim_fov_slider(P.get_aim_fov())
	set_aim_speed_slider(P.get_aim_speed())
	set_silent_fov_slider(P.get_silent_fov())
	set_fly_speed_slider(P.get_fly_speed())
	set_walk_slider(P.get_walk())
	set_jump_slider(P.get_jump())
end
