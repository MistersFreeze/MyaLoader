--[[
    Mya · Neighbors — MIDI player UI (Operation One layout: pink accent, gethui, tabs)
]]
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
	red = Color3.fromRGB(220, 80, 80),
	green = Color3.fromRGB(90, 200, 130),
	slid_bg = Color3.fromRGB(38, 40, 48),
	slid_fg = Color3.fromRGB(230, 120, 175),
	input_bg = Color3.fromRGB(28, 30, 38),
}

local P = _G.MYA_NEIGHBORS_PIANO
if not P then
	error("[Mya] Neighbors gui: MYA_NEIGHBORS_PIANO missing (load runtime.lua first)")
end

local Players = game:GetService("Players")
local localPlayer = Players.LocalPlayer or Players.PlayerAdded:Wait()

local ui = Instance.new("ScreenGui")
ui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ui.Name = rand_str(6)
ui.IgnoreGuiInset = true
ui.DisplayOrder = 10
ui.ResetOnSpawn = false
ui.Parent = gethui_support and gethui() or game:GetService("CoreGui")

-- Toasts under PlayerGui avoid "lacking capability Plugin" after yields (e.g. ApplyDescriptionAsync)
-- when parenting new instances under CoreGui/gethui().
local notif_ui = Instance.new("ScreenGui")
notif_ui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
notif_ui.Name = rand_str(5) .. "_N"
notif_ui.IgnoreGuiInset = true
notif_ui.DisplayOrder = 100
notif_ui.ResetOnSpawn = false
notif_ui.Parent = localPlayer:WaitForChild("PlayerGui")

local notif_container = Instance.new("Frame")
notif_container.BackgroundTransparency = 1
notif_container.Size = UDim2.fromOffset(260, 400)
notif_container.Position = UDim2.new(1, -270, 1, -420)
notif_container.Parent = notif_ui
local n_layout = Instance.new("UIListLayout", notif_container)
n_layout.FillDirection = Enum.FillDirection.Vertical
n_layout.HorizontalAlignment = Enum.HorizontalAlignment.Right
n_layout.VerticalAlignment = Enum.VerticalAlignment.Bottom
n_layout.Padding = UDim.new(0, 8)

local function notify(title, text, duration)
	duration = duration or 3
	task.defer(function()
		if not notif_container.Parent then
			notif_container.Parent = notif_ui
		end
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
		ts:Create(f, TweenInfo.new(0.35, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out), { Position = UDim2.new(0, 0, 0, 0) }):Play()
		task.spawn(function()
			task.wait(duration)
			if not f.Parent then
				return
			end
			ts:Create(f, TweenInfo.new(0.35), { Position = UDim2.fromOffset(260, 0), BackgroundTransparency = 1 }):Play()
			task.wait(0.35)
			f:Destroy()
		end)
	end)
end

local WIN_W, WIN_H = 360, 540
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
title_lbl.Text = "NEIGHBORS · Mya"
title_lbl.TextColor3 = C.text
title_lbl.TextSize = 14
title_lbl.BackgroundTransparency = 1
title_lbl.Position = UDim2.fromOffset(14, 0)
title_lbl.Size = UDim2.new(1, -24, 1, 0)
title_lbl.TextXAlignment = Enum.TextXAlignment.Left
title_lbl.Parent = header

local TAB_NAMES = { "Piano", "Visuals", "Piano Settings", "Misc" }
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
	page.ScrollingDirection = Enum.ScrollingDirection.Y
	page.Visible = true
	page.Parent = content
	local ul = Instance.new("UIListLayout")
	ul.SortOrder = Enum.SortOrder.LayoutOrder
	ul.Padding = UDim.new(0, 0)
	ul.Parent = page
	local up = Instance.new("UIPadding")
	up.PaddingTop = UDim.new(0, 6)
	up.Parent = page
	return page
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
	b.LayoutOrder = i
	b.BackgroundColor3 = C.tab_off
	b.BorderSizePixel = 0
	b.Size = UDim2.new(1 / #TAB_NAMES, 0, 1, 0)
	b.Font = Enum.Font.GothamSemibold
	b.Text = name
	b.TextColor3 = C.dim
	b.TextSize = 9
	b.AutoButtonColor = false
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
end

local piano_page = make_page()
piano_page.Parent = tab_containers["Piano"]
local visuals_page = make_page()
visuals_page.Parent = tab_containers["Visuals"]
local settings_page = make_page()
settings_page.Parent = tab_containers["Piano Settings"]
local misc_page = make_page()
misc_page.Parent = tab_containers["Misc"]
-- Tab visibility is toggled on the container Frame; each ScrollingFrame stays Visible = true so content shows.

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

local function make_toggle_row(parent, label, order, initial_on, on_click)
	local row = make_row(parent, order)
	local state = initial_on
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
		pill.BackgroundColor3 = state and C.tog_on or C.tog_off
		knob.Position = state and UDim2.fromOffset(21, 3) or UDim2.fromOffset(3, 3)
	end
	local hit = Instance.new("TextButton")
	hit.BackgroundTransparency = 1
	hit.Size = UDim2.fromScale(1, 1)
	hit.Text = ""
	hit.Parent = row
	hit.MouseButton1Click:Connect(function()
		state = not state
		refresh()
		on_click(state)
	end)
	return function(new_state)
		state = new_state
		refresh()
	end
end

-- ——— Piano tab ———
section_label(piano_page, "Status", 1)
local status_row = make_row(piano_page, 2, 40)
local status_lbl = Instance.new("TextLabel")
status_lbl.BackgroundTransparency = 1
status_lbl.Position = UDim2.fromOffset(14, 0)
status_lbl.Size = UDim2.new(1, -28, 1, 0)
status_lbl.Font = Enum.Font.Gotham
status_lbl.TextSize = 12
status_lbl.TextColor3 = C.dim
status_lbl.TextXAlignment = Enum.TextXAlignment.Left
status_lbl.TextWrapped = true
status_lbl.Text = "Ready"
status_lbl.Parent = status_row

section_label(piano_page, "MIDI library", 3)
local search_row = make_row(piano_page, 4, 32)
local midi_search_box = Instance.new("TextBox")
midi_search_box.BackgroundColor3 = C.input_bg
midi_search_box.Size = UDim2.new(1, -28, 0, 28)
midi_search_box.Position = UDim2.new(0.5, 0, 0.5, 0)
midi_search_box.AnchorPoint = Vector2.new(0.5, 0.5)
midi_search_box.Font = Enum.Font.Gotham
midi_search_box.TextSize = 12
midi_search_box.TextColor3 = C.text
midi_search_box.PlaceholderText = "Search MIDI files…"
midi_search_box.PlaceholderColor3 = C.dim
midi_search_box.ClearTextOnFocus = false
midi_search_box.Text = ""
Instance.new("UICorner", midi_search_box).CornerRadius = UDim.new(0, 6)
midi_search_box.Parent = search_row

local dd_toggle_row = make_row(piano_page, 5, 36)
local dd_toggle = Instance.new("TextButton")
dd_toggle.Size = UDim2.new(1, -28, 0, 28)
dd_toggle.Position = UDim2.new(0.5, 0, 0.5, 0)
dd_toggle.AnchorPoint = Vector2.new(0.5, 0.5)
dd_toggle.BackgroundColor3 = C.input_bg
dd_toggle.TextColor3 = C.text
dd_toggle.Font = Enum.Font.GothamMedium
dd_toggle.TextSize = 12
dd_toggle.Text = "▼ Select a .mid file…"
dd_toggle.AutoButtonColor = false
Instance.new("UICorner", dd_toggle).CornerRadius = UDim.new(0, 6)
dd_toggle.Parent = dd_toggle_row

local dd_list = Instance.new("ScrollingFrame")
dd_list.BackgroundColor3 = C.panel
dd_list.BorderSizePixel = 0
dd_list.Size = UDim2.new(1, -16, 0, 140)
dd_list.Visible = false
dd_list.ZIndex = 10
dd_list.ScrollBarThickness = 4
dd_list.ScrollBarImageColor3 = C.accent
dd_list.CanvasSize = UDim2.new(0, 0, 0, 0)
dd_list.AutomaticCanvasSize = Enum.AutomaticSize.Y
dd_list.Parent = piano_page
dd_list.LayoutOrder = 6
Instance.new("UICorner", dd_list).CornerRadius = UDim.new(0, 6)
local dd_layout = Instance.new("UIListLayout")
dd_layout.SortOrder = Enum.SortOrder.LayoutOrder
dd_layout.Padding = UDim.new(0, 2)
dd_layout.Parent = dd_list
local dd_pad = Instance.new("UIPadding", dd_list)
dd_pad.PaddingLeft = UDim.new(0, 4)
dd_pad.PaddingRight = UDim.new(0, 4)
dd_pad.PaddingTop = UDim.new(0, 4)
dd_pad.PaddingBottom = UDim.new(0, 4)

section_label(piano_page, "URL or manual path", 7)
local url_row = make_row(piano_page, 8, 36)
local url_box = Instance.new("TextBox")
url_box.BackgroundColor3 = C.input_bg
url_box.BorderSizePixel = 0
url_box.Position = UDim2.fromOffset(14, 4)
url_box.Size = UDim2.new(1, -28, 0, 28)
url_box.Font = Enum.Font.Gotham
url_box.TextSize = 12
url_box.TextColor3 = C.text
url_box.PlaceholderText = "https://… or MIDIow/x.mid · MIDI/y.mid · name.mid"
url_box.PlaceholderColor3 = C.dim
url_box.ClearTextOnFocus = false
url_box.Text = ""
Instance.new("UICorner", url_box).CornerRadius = UDim.new(0, 6)
url_box.Parent = url_row

local function row_button(parent, order, text, callback)
	local row = make_row(parent, order, 40)
	local btn = Instance.new("TextButton")
	btn.BackgroundColor3 = C.accent
	btn.TextColor3 = Color3.fromRGB(30, 18, 24)
	btn.Font = Enum.Font.GothamBold
	btn.TextSize = 13
	btn.Text = text
	btn.Size = UDim2.new(1, -28, 0, 30)
	btn.Position = UDim2.new(0.5, 0, 0.5, 0)
	btn.AnchorPoint = Vector2.new(0.5, 0.5)
	Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)
	btn.Parent = row
	btn.MouseButton1Click:Connect(callback)
end

local function resolveLocalMidiPath(txt)
	local t = txt:gsub("\\", "/"):gsub("^%s+", ""):gsub("%s+$", "")
	if t == "" then
		return nil
	end
	if string.match(t, "^https?://") then
		return nil
	end
	if string.match(t, "^MIDIow/") or string.match(t, "^MIDI/") then
		return "./" .. t
	end
	if not string.find(t, "/", 1, true) then
		local a = "./MIDIow/" .. t
		local b = "./MIDI/" .. t
		if typeof(isfile) == "function" then
			local oka, fa = pcall(isfile, a)
			if oka and fa then
				return a
			end
			local okb, fb = pcall(isfile, b)
			if okb and fb then
				return b
			end
		end
		return a
	end
	return "./" .. t
end

local function tryLoadMidi()
	if P.is_loading() then
		status_lbl.Text = "Already loading…"
		return
	end
	local txt = url_box.Text:gsub("^%s+", ""):gsub("%s+$", "")
	if txt == "" then
		status_lbl.Text = "Choose from list or enter URL / path"
		return
	end
	if string.match(txt, "^https?://") then
		status_lbl.Text = "Downloading…"
		task.spawn(function()
			local ok, body = pcall(function()
				return game:HttpGet(txt, true)
			end)
			if ok and body then
				P.load_midi_from_data(body, function(s)
					status_lbl.Text = s
				end)
			else
				status_lbl.Text = "Download failed"
				notify("Mya", "HttpGet failed", 3)
			end
		end)
		return
	end
	local path = resolveLocalMidiPath(txt)
	if not path then
		status_lbl.Text = "Invalid path"
		return
	end
	if typeof(isfile) == "function" then
		local okf, exists = pcall(isfile, path)
		if okf and not exists then
			status_lbl.Text = "Not found: " .. path
			return
		end
	end
	local ok, data = pcall(readfile, path)
	if ok and data then
		P.load_midi_from_data(data, function(s)
			status_lbl.Text = s
		end)
	else
		status_lbl.Text = "readfile failed: " .. tostring(path)
	end
end

local function rebuildMidiDropdown()
	for _, c in ipairs(dd_list:GetChildren()) do
		if c:IsA("TextButton") then
			c:Destroy()
		end
	end
	P.list_midi_files()
	local files = P.get_midi_files()
	local q = midi_search_box.Text:lower():gsub("^%s+", ""):gsub("%s+$", "")
	local filtered = {}
	for _, rel in ipairs(files) do
		if q == "" or string.find(rel:lower(), q, 1, true) then
			table.insert(filtered, rel)
		end
	end
	for i, rel in ipairs(filtered) do
		local b = Instance.new("TextButton")
		b.Size = UDim2.new(1, -8, 0, 26)
		b.BackgroundColor3 = C.bg
		b.Text = "  " .. rel
		b.Font = Enum.Font.Gotham
		b.TextSize = 11
		b.TextColor3 = C.text
		b.TextXAlignment = Enum.TextXAlignment.Left
		b.AutoButtonColor = false
		b.LayoutOrder = i
		Instance.new("UICorner", b).CornerRadius = UDim.new(0, 4)
		b.Parent = dd_list
		b.MouseButton1Click:Connect(function()
			url_box.Text = rel
			dd_toggle.Text = "▼ " .. rel
			dd_list.Visible = false
			tryLoadMidi()
		end)
	end
end

dd_toggle.MouseButton1Click:Connect(function()
	dd_list.Visible = not dd_list.Visible
	dd_toggle.Text = dd_list.Visible and "▲ Hide MIDI list" or "▼ Select a .mid file…"
end)

midi_search_box:GetPropertyChangedSignal("Text"):Connect(function()
	rebuildMidiDropdown()
end)

P.list_midi_files()
rebuildMidiDropdown()

row_button(piano_page, 9, "Load (URL or file)", function()
	tryLoadMidi()
end)

row_button(piano_page, 10, "Refresh MIDI list", function()
	rebuildMidiDropdown()
	local n = #P.get_midi_files()
	status_lbl.Text = (n > 0) and ("Found " .. n .. " .mid in ./MIDIow and ./MIDI") or "No .mid in ./MIDIow or ./MIDI"
	notify("Mya", status_lbl.Text, 2)
end)

row_button(piano_page, 11, "Play", function()
	if not P.is_midi_loaded() then
		status_lbl.Text = "No MIDI loaded"
		return
	end
	local paused = P.is_paused()
	local pos = P.get_current_playback_position()
	if paused and pos > 0 then
		P.resume_playback()
		status_lbl.Text = "▶ Resumed"
	elseif paused and pos == 0 then
		P.start_playback_from_loaded()
		status_lbl.Text = "▶ Playing"
	else
		status_lbl.Text = "Already playing"
	end
end)

row_button(piano_page, 12, "Pause / Resume", function()
	if P.is_paused() then
		P.resume_playback()
		status_lbl.Text = "▶ Resumed"
	else
		P.pause_playback()
		status_lbl.Text = "⏸ Paused"
	end
end)

row_button(piano_page, 13, "Stop", function()
	P.stop_playback()
	status_lbl.Text = "⏹ Stopped"
end)

local last_played_change = 0
local was_playing_before_played = false
local played_slider_set = make_slider(piano_page, "Position (0–1)", 14, 0, 1, 0, "%.3f", function(ratio)
	if not P.is_midi_loaded() or P.get_total_duration() <= 0 then
		return
	end
	if not P.is_paused() and not was_playing_before_played then
		was_playing_before_played = true
		P.pause_playback()
	end
	last_played_change = os.clock()
	P.seek_ratio(ratio)
	status_lbl.Text = string.format("Seek %.1f%%", ratio * 100)
	task.spawn(function()
		task.wait(0.28)
		if os.clock() - last_played_change >= 0.28 and was_playing_before_played then
			P.resume_playback()
			was_playing_before_played = false
		end
	end)
end)

local last_speed_change = 0
local was_playing_before_speed = false
local speed_slider_set = make_slider(piano_page, "Speed %", 15, 50, 200, P.get_playback_speed_percent(), "%.0f", function(v)
	if not P.is_paused() and not was_playing_before_speed then
		was_playing_before_speed = true
		P.pause_playback()
	end
	last_speed_change = os.clock()
	P.set_playback_speed_percent(v)
	task.spawn(function()
		task.wait(0.28)
		if os.clock() - last_speed_change >= 0.28 and was_playing_before_speed then
			P.resume_playback()
			was_playing_before_speed = false
		end
	end)
end)

P.set_on_midi_loaded(function(total, nEvents)
	played_slider_set(0)
	speed_slider_set(P.get_playback_speed_percent())
	status_lbl.Text = string.format("Loaded %d events · %.2fs", nEvents, total)
	notify("Mya", "MIDI ready", 2)
end)

P.register_sliders(function(elapsed)
	local td = P.get_total_duration()
	if td and td > 0 then
		played_slider_set(elapsed / td)
	end
end, function(percent)
	speed_slider_set(percent)
end)

-- ——— Piano settings ———
section_label(settings_page, "Playback", 1)
make_toggle_row(settings_page, "DeBlack", 2, P.get_deblack_enabled(), function(v)
	P.set_deblack_enabled(v)
	notify("Mya", v and "DeBlack on" or "DeBlack off", 2)
end)
make_slider(settings_page, "DeBlack level", 3, 0, 127, P.get_deblack_level(), "%d", function(v)
	P.set_deblack_level(math.floor(v))
end)
make_toggle_row(settings_page, "Auto sustain", 4, P.get_auto_sustain(), function(v)
	P.set_auto_sustain(v)
end)
make_toggle_row(settings_page, "Pedal uses Space (may unseat)", 5, P.get_pedal_uses_space(), function(v)
	P.set_pedal_uses_space(v)
	notify("Mya", v and "Sustain → Space" or "Sustain → Left Alt (stay seated)", 2)
end)
make_toggle_row(settings_page, "88 keys (ctrl rows)", 6, P.get_key88(), function(v)
	P.set_key88(v)
end)
make_toggle_row(settings_page, "Force note-off", 7, P.get_force_note_off(), function(v)
	P.set_force_note_off(v)
	if v then
		P.release_all_keys()
	end
end)
make_toggle_row(settings_page, "Humanize timing", 8, P.get_human_player(), function(v)
	P.set_human_player(v)
end)

-- ——— Visuals ———
section_label(visuals_page, "Players", 1)
make_toggle_row(visuals_page, "ESP (chams)", 2, P.get_esp_enabled(), function(v)
	P.set_esp_enabled(v)
	notify("Mya", v and "ESP on" or "ESP off", 2)
end)
make_toggle_row(visuals_page, "Nametags", 3, P.get_nametags_enabled(), function(v)
	P.set_nametags_enabled(v)
	notify("Mya", v and "Nametags on" or "Nametags off", 2)
end)

section_label(visuals_page, "Target player", 4)
local target_name_row = make_row(visuals_page, 5, 38)
local target_name_box = Instance.new("TextBox")
target_name_box.BackgroundColor3 = C.input_bg
target_name_box.Size = UDim2.new(1, -28, 0, 28)
target_name_box.Position = UDim2.new(0.5, 0, 0.5, 0)
target_name_box.AnchorPoint = Vector2.new(0.5, 0.5)
target_name_box.Font = Enum.Font.Gotham
target_name_box.TextSize = 12
target_name_box.TextColor3 = C.text
target_name_box.PlaceholderText = "Username or display name…"
target_name_box.PlaceholderColor3 = C.dim
target_name_box.ClearTextOnFocus = false
target_name_box.Text = ""
Instance.new("UICorner", target_name_box).CornerRadius = UDim.new(0, 6)
target_name_box.Parent = target_name_row

local function resolve_visual_target()
	return P.resolve_target_query(target_name_box.Text)
end

row_button(visuals_page, 6, "Spy camera (orbit)", function()
	local t = resolve_visual_target()
	if not t then
		notify("Mya", "Player not found", 2)
		return
	end
	local ok, err = P.start_spy_camera(t)
	notify("Mya", ok and ("Spying " .. t.Name .. " · mouse look · wheel zoom") or (err or "Failed"), 2)
end)
row_button(visuals_page, 7, "Teleport to", function()
	local t = resolve_visual_target()
	if not t then
		notify("Mya", "Player not found", 2)
		return
	end
	local ok, err = P.teleport_to_target(t)
	notify("Mya", ok and "Teleported" or (err or "TP failed"), 2)
end)
row_button(visuals_page, 8, "Stop spy / reset camera", function()
	local ok = P.reset_camera_to_local()
	notify("Mya", ok and "Camera back to you" or "Failed", 2)
end)

-- ——— Misc ———
section_label(misc_page, "Script", 1)
row_button(misc_page, 2, "Unload", function()
	if _G.unload_mya then
		pcall(_G.unload_mya)
	end
end)

section_label(misc_page, "Movement", 3)
make_toggle_row(misc_page, "Fly", 4, P.get_fly_enabled(), function(v)
	P.set_fly_enabled(v)
	notify("Mya", v and "Fly on (WASD · Space · Ctrl)" or "Fly off", 2)
end)
make_slider(misc_page, "Fly speed", 5, 5, 200, P.get_fly_speed(), "%d", function(v)
	P.set_fly_speed(v)
end)
make_toggle_row(misc_page, "Noclip", 6, P.get_noclip_enabled(), function(v)
	P.set_noclip_enabled(v)
	notify("Mya", v and "Noclip on" or "Noclip off", 2)
end)
make_toggle_row(misc_page, "Anti ragdoll", 7, P.get_anti_ragdoll_enabled(), function(v)
	P.set_anti_ragdoll_enabled(v)
	notify("Mya", v and "Anti ragdoll on" or "Anti ragdoll off", 2)
end)
local walk_slider_set = make_slider(misc_page, "Walk speed", 8, 0, 200, P.get_walk_speed(), "%.0f", function(v)
	P.set_walk_speed(v)
end)
local jump_slider_set = make_slider(misc_page, "Jump power", 9, 0, 200, P.get_jump_power(), "%.0f", function(v)
	P.set_jump_power(v)
end)
task.defer(function()
	walk_slider_set(P.get_walk_speed())
	jump_slider_set(P.get_jump_power())
end)

local bind_row = make_row(misc_page, 10, 36)
local bind_lbl = Instance.new("TextLabel")
bind_lbl.BackgroundTransparency = 1
bind_lbl.Size = UDim2.new(1, -28, 1, 0)
bind_lbl.Position = UDim2.fromOffset(14, 0)
bind_lbl.Font = Enum.Font.Gotham
bind_lbl.TextSize = 12
bind_lbl.TextColor3 = C.dim
bind_lbl.TextXAlignment = Enum.TextXAlignment.Left
bind_lbl.Text = "Menu toggle: Insert  ·  Drag header to move"
bind_lbl.Parent = bind_row

P.start_render_loop()

local menu_key = Enum.KeyCode.Insert
uis.InputBegan:Connect(function(input, processed)
	if processed then
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

_G.user_interface = ui
_G.mya_neighbors_notif_ui = notif_ui

switch_tab("Piano")
notify("Mya", "Neighbors · Insert to hide menu", 4)
