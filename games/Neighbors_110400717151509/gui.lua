--[[
    Mya · Neighbors — MIDI player UI (`lib/mya_game_ui.lua`)
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

local fetch = _G.MYA_FETCH
local repoBase = _G.MYA_REPO_BASE
if typeof(fetch) ~= "function" or typeof(repoBase) ~= "string" or #repoBase == 0 then
	error("[Neighbors] MYA_FETCH / MYA_REPO_BASE missing — mount via hub with ctx.baseUrl.")
end
local libSrc = fetch(repoBase .. "lib/mya_game_ui.lua")
if typeof(libSrc) ~= "string" or #libSrc == 0 then
	error("[Neighbors] Could not load lib/mya_game_ui.lua from repo base: " .. repoBase)
end
local libFn = loadstring(libSrc, "@lib/mya_game_ui")
if typeof(libFn) ~= "function" then
	error("[Neighbors] lib/mya_game_ui.lua failed to compile")
end
local MyaUI = libFn()
local THEME, C = MyaUI.defaultTheme()

local P = _G.MYA_NEIGHBORS_PIANO
if not P then
	error("[Mya] Neighbors gui: MYA_NEIGHBORS_PIANO missing (load runtime.lua first)")
end

local Players = game:GetService("Players")
local localPlayer = Players.LocalPlayer or Players.PlayerAdded:Wait()
local playerGui = localPlayer:WaitForChild("PlayerGui")

local ui = Instance.new("ScreenGui")
ui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ui.Name = rand_str(6)
ui.IgnoreGuiInset = true
ui.DisplayOrder = 10
ui.ResetOnSpawn = false
ui.Parent = gethui_support and gethui() or game:GetService("CoreGui")

-- Toasts under PlayerGui avoid capability issues after yields when parenting under CoreGui/gethui.
local notify, notif_ui = MyaUI.createNotifyStack({
	C = C,
	THEME = THEME,
	ts = ts,
	notifParent = playerGui,
})

local shell = MyaUI.createHubShell({
	ui = ui,
	THEME = THEME,
	C = C,
	ts = ts,
	uis = uis,
	titleText = "Mya  ·  Neighbors",
	tabNames = { "Piano", "Visuals", "Piano Settings", "Misc", "Settings" },
	subPages = {},
	statusDefault = "Ready · Delete toggles menu",
	discordInvite = "https://discord.gg/YeyepQG6K9",
	winW = 540,
	winH = 400,
})

local switch_tab = shell.switch_tab
local tab_containers = shell.tab_containers
local make_page = shell.make_page

local piano_page = make_page()
piano_page.Visible = true
piano_page.Parent = tab_containers["Piano"]
local visuals_page = make_page()
visuals_page.Visible = true
visuals_page.Parent = tab_containers["Visuals"]
local piano_settings_page = make_page()
piano_settings_page.Visible = true
piano_settings_page.Parent = tab_containers["Piano Settings"]
local misc_page = make_page()
misc_page.Visible = true
misc_page.Parent = tab_containers["Misc"]
local app_settings_page = make_page()
app_settings_page.Visible = true
app_settings_page.Parent = tab_containers["Settings"]

local function loosen_list_padding(scroll)
	for _, ch in ipairs(scroll:GetChildren()) do
		if ch:IsA("UIListLayout") then
			ch.Padding = UDim.new(0, 5)
			return
		end
	end
end
for _, pg in ipairs({ piano_page, visuals_page, piano_settings_page, misc_page, app_settings_page }) do
	loosen_list_padding(pg)
end

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

local ROW_CORNER = THEME.cornerSm + 3

local function make_row(parent, order, h)
	h = h or 34
	local base = C.panel
	local row = Instance.new("Frame")
	row.LayoutOrder = order
	row.BackgroundColor3 = base
	row.BorderSizePixel = 0
	row.Size = UDim2.new(1, 0, 0, h)
	row.ClipsDescendants = true
	row.Parent = parent
	local round = Instance.new("UICorner")
	round.CornerRadius = UDim.new(0, ROW_CORNER)
	round.Parent = row
	local sep = Instance.new("Frame")
	sep.BackgroundColor3 = THEME.border
	sep.BackgroundTransparency = 0.35
	sep.BorderSizePixel = 0
	sep.AnchorPoint = Vector2.new(0.5, 1)
	sep.Position = UDim2.new(0.5, 0, 1, -1)
	sep.Size = UDim2.new(1, -2 * ROW_CORNER, 0, 1)
	sep.Parent = row
	row.MouseEnter:Connect(function()
		row.BackgroundColor3 = C.row_hover
	end)
	row.MouseLeave:Connect(function()
		row.BackgroundColor3 = base
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
Instance.new("UICorner", midi_search_box).CornerRadius = UDim.new(0, ROW_CORNER)
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
Instance.new("UICorner", dd_toggle).CornerRadius = UDim.new(0, ROW_CORNER)
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
Instance.new("UICorner", dd_list).CornerRadius = UDim.new(0, ROW_CORNER)
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
Instance.new("UICorner", url_box).CornerRadius = UDim.new(0, ROW_CORNER)
url_box.Parent = url_row

local function row_button(parent, order, text, callback)
	local row = make_row(parent, order, 40)
	local btn = Instance.new("TextButton")
	btn.BackgroundColor3 = C.accent
	btn.TextColor3 = Color3.fromRGB(28, 14, 22)
	btn.Font = Enum.Font.GothamBold
	btn.TextSize = 13
	btn.Text = text
	btn.Size = UDim2.new(1, -28, 0, 30)
	btn.Position = UDim2.new(0.5, 0, 0.5, 0)
	btn.AnchorPoint = Vector2.new(0.5, 0.5)
	Instance.new("UICorner", btn).CornerRadius = UDim.new(0, ROW_CORNER)
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
		b.BackgroundColor3 = THEME.surface
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
section_label(piano_settings_page, "Playback", 1)
make_toggle_row(piano_settings_page, "DeBlack", 2, P.get_deblack_enabled(), function(v)
	P.set_deblack_enabled(v)
	notify("Mya", v and "DeBlack on" or "DeBlack off", 2)
end)
make_slider(piano_settings_page, "DeBlack level", 3, 0, 127, P.get_deblack_level(), "%d", function(v)
	P.set_deblack_level(math.floor(v))
end)
make_toggle_row(piano_settings_page, "Auto sustain", 4, P.get_auto_sustain(), function(v)
	P.set_auto_sustain(v)
end)
make_toggle_row(piano_settings_page, "Pedal uses Space (may unseat)", 5, P.get_pedal_uses_space(), function(v)
	P.set_pedal_uses_space(v)
	notify("Mya", v and "Sustain → Space" or "Sustain → Left Alt (stay seated)", 2)
end)
make_toggle_row(piano_settings_page, "88 keys (ctrl rows)", 6, P.get_key88(), function(v)
	P.set_key88(v)
end)
make_toggle_row(piano_settings_page, "Force note-off", 7, P.get_force_note_off(), function(v)
	P.set_force_note_off(v)
	if v then
		P.release_all_keys()
	end
end)
make_toggle_row(piano_settings_page, "Humanize timing", 8, P.get_human_player(), function(v)
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
Instance.new("UICorner", target_name_box).CornerRadius = UDim.new(0, ROW_CORNER)
target_name_box.Parent = target_name_row

local function resolve_visual_target()
	return P.resolve_target_query(target_name_box.Text)
end

row_button(visuals_page, 6, "Spy camera", function()
	local t = resolve_visual_target()
	if not t then
		notify("Mya", "Player not found", 2)
		return
	end
	local ok, err = P.start_spy_camera(t)
	notify("Mya", ok and ("Spying " .. t.Name .. " · hold right-click to orbit · wheel zoom") or (err or "Failed"), 2)
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

-- ——— Settings (unload, menu) ———
section_label(app_settings_page, "Script", 1)
row_button(app_settings_page, 2, "Unload", function()
	if _G.unload_mya then
		pcall(_G.unload_mya)
	end
end)
local settings_hint_row = make_row(app_settings_page, 3, 40)
local settings_hint = Instance.new("TextLabel")
settings_hint.BackgroundTransparency = 1
settings_hint.Size = UDim2.new(1, -28, 1, 0)
settings_hint.Position = UDim2.fromOffset(14, 0)
settings_hint.Font = Enum.Font.Gotham
settings_hint.TextSize = 12
settings_hint.TextColor3 = C.dim
settings_hint.TextXAlignment = Enum.TextXAlignment.Left
settings_hint.TextWrapped = true
settings_hint.Text = "Delete toggles this menu · Drag the title bar to move"
settings_hint.Parent = settings_hint_row

-- ——— Misc ———
section_label(misc_page, "Movement", 1)
make_toggle_row(misc_page, "Fly", 2, P.get_fly_enabled(), function(v)
	P.set_fly_enabled(v)
	notify("Mya", v and "Fly on (WASD · Space · Ctrl)" or "Fly off", 2)
end)
make_slider(misc_page, "Fly speed", 3, 5, 200, P.get_fly_speed(), "%d", function(v)
	P.set_fly_speed(v)
end)
make_toggle_row(misc_page, "Noclip", 4, P.get_noclip_enabled(), function(v)
	P.set_noclip_enabled(v)
	notify("Mya", v and "Noclip on" or "Noclip off", 2)
end)
make_toggle_row(misc_page, "Anti ragdoll", 5, P.get_anti_ragdoll_enabled(), function(v)
	P.set_anti_ragdoll_enabled(v)
	notify("Mya", v and "Anti ragdoll on" or "Anti ragdoll off", 2)
end)
local walk_slider_set = make_slider(misc_page, "Walk speed", 6, 0, 200, P.get_walk_speed(), "%.0f", function(v)
	P.set_walk_speed(v)
end)
local jump_slider_set = make_slider(misc_page, "Jump power", 7, 0, 200, P.get_jump_power(), "%.0f", function(v)
	P.set_jump_power(v)
end)
task.defer(function()
	walk_slider_set(P.get_walk_speed())
	jump_slider_set(P.get_jump_power())
end)

P.start_render_loop()

local menu_key = Enum.KeyCode.Delete
uis.InputBegan:Connect(function(input, processed)
	if processed then
		return
	end
	if input.KeyCode == menu_key then
		ui.Enabled = not ui.Enabled
	end
end)

_G.user_interface = ui
_G.mya_neighbors_notif_ui = notif_ui

switch_tab("Piano")
notify("Mya", "Neighbors · Delete to hide menu", 4)
