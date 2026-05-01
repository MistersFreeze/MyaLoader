--[[ Prison Life — rose / plum GUI ]]
local P = _G.MYA_UNIVERSAL
if not P then
	error("[PrisonLife] Load runtime.lua first")
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

-- Shared shell + theme from `lib/mya_game_ui.lua` (repo root). Init sets MYA_FETCH + MYA_REPO_BASE.
local fetch = _G.MYA_FETCH
local repoBase = _G.MYA_REPO_BASE
if typeof(fetch) ~= "function" or typeof(repoBase) ~= "string" or #repoBase == 0 then
	error("[PrisonLife] MYA_FETCH / MYA_REPO_BASE missing — mount via hub with ctx.baseUrl, or set init globals.")
end
local libSrc = fetch(repoBase .. "lib/mya_game_ui.lua")
if typeof(libSrc) ~= "string" or #libSrc == 0 then
	error("[PrisonLife] Could not load lib/mya_game_ui.lua from repo base: " .. repoBase)
end
local libFn = loadstring(libSrc, "@lib/mya_game_ui")
if typeof(libFn) ~= "function" then
	error("[PrisonLife] lib/mya_game_ui.lua failed to compile")
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
_G.mya_universal_ui = ui

local notify, notif_ui = MyaUI.createNotifyStack({
	C = C,
	THEME = THEME,
	ts = ts,
	gethui_support = gethui_support,
})
_G.mya_universal_notif_ui = notif_ui
_G.mya_notify = notify

local shell = MyaUI.createHubShell({
	ui = ui,
	THEME = THEME,
	C = C,
	ts = ts,
	uis = uis,
	titleText = "Mya  ·  Prison Life",
	tabNames = { "Combat", "Visuals", "Movement", "Configs", "Settings" },
	subPages = {
		Combat = { "Aim assist", "Silent aim", "Triggerbot" },
		Visuals = { "ESP", "World" },
		Movement = { "Flight", "Car flight", "Walk & jump", "Noclip" },
	},
	statusDefault = "Ready · Delete toggles this menu",
	discordInvite = "https://discord.gg/YeyepQG6K9",
})

local main = shell.main
local switch_tab = shell.switch_tab
local sub_bar = shell.sub_bar
local content = shell.content
local tab_buttons = shell.tab_buttons
local tab_containers = shell.tab_containers
local all_sub_buttons = shell.all_sub_buttons
local all_sub_pages = shell.all_sub_pages
local make_page = shell.make_page

local combat_aim = all_sub_pages["Combat"]["Aim assist"]
local combat_silent = all_sub_pages["Combat"]["Silent aim"]
local combat_trigger = all_sub_pages["Combat"]["Triggerbot"]
local visuals_esp = all_sub_pages["Visuals"]["ESP"]
local visuals_world = all_sub_pages["Visuals"]["World"]
local movement_fly = all_sub_pages["Movement"]["Flight"]
local movement_car_fly = all_sub_pages["Movement"]["Car flight"]
local movement_walk = all_sub_pages["Movement"]["Walk & jump"]
local movement_noclip = all_sub_pages["Movement"]["Noclip"]

local settings_page = make_page()
settings_page.Visible = true
settings_page.Parent = tab_containers["Settings"]

-- Configs: list scrolls above a footer pinned to the bottom of the window.
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

section_label(list_scroller, "Config manager", 0)

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

local HITPART_OPTIONS = { "HumanoidRootPart", "Head", "UpperTorso", "LowerTorso", "Torso" }

local function make_hitpart_dropdown(parent, order, get_fn, set_fn)
	local wrap = Instance.new("Frame")
	wrap.LayoutOrder = order
	wrap.BackgroundTransparency = 1
	wrap.Size = UDim2.new(1, 0, 0, 0)
	wrap.AutomaticSize = Enum.AutomaticSize.Y
	wrap.Parent = parent
	local wrap_layout = Instance.new("UIListLayout", wrap)
	wrap_layout.SortOrder = Enum.SortOrder.LayoutOrder
	wrap_layout.Padding = UDim.new(0, 4)

	local row = make_row(wrap, 1, 34)
	local lbl = Instance.new("TextLabel")
	lbl.Font = Enum.Font.Gotham
	lbl.Text = "Hit part"
	lbl.TextColor3 = C.text
	lbl.TextSize = 12
	lbl.BackgroundTransparency = 1
	lbl.Position = UDim2.fromOffset(14, 8)
	lbl.Size = UDim2.new(0.45, 0, 0, 18)
	lbl.TextXAlignment = Enum.TextXAlignment.Left
	lbl.Parent = row

	local mainBtn = Instance.new("TextButton")
	mainBtn.AutoButtonColor = false
	mainBtn.BackgroundColor3 = C.tab_off
	mainBtn.Font = Enum.Font.GothamSemibold
	mainBtn.TextSize = 11
	mainBtn.TextColor3 = C.accent
	mainBtn.Size = UDim2.new(0.5, -20, 0, 24)
	mainBtn.Position = UDim2.new(0.48, 0, 0.5, -12)
	mainBtn.Parent = row
	Instance.new("UICorner", mainBtn).CornerRadius = UDim.new(0, THEME.cornerSm)

	local listWrap = Instance.new("Frame")
	listWrap.LayoutOrder = 2
	listWrap.BackgroundColor3 = C.panel
	listWrap.BorderSizePixel = 0
	listWrap.Size = UDim2.new(1, -24, 0, 0)
	listWrap.Visible = false
	listWrap.AutomaticSize = Enum.AutomaticSize.Y
	listWrap.ZIndex = 5
	listWrap.Parent = wrap
	Instance.new("UICorner", listWrap).CornerRadius = UDim.new(0, THEME.cornerSm)
	Instance.new("UIListLayout", listWrap).Padding = UDim.new(0, 2)
	local pad = Instance.new("UIPadding", listWrap)
	pad.PaddingLeft = UDim.new(0, 6)
	pad.PaddingRight = UDim.new(0, 6)
	pad.PaddingTop = UDim.new(0, 6)
	pad.PaddingBottom = UDim.new(0, 6)

	local function refresh()
		mainBtn.Text = get_fn() .. "  ▼"
	end

	for i, name in ipairs(HITPART_OPTIONS) do
		local opt = Instance.new("TextButton")
		opt.LayoutOrder = i
		opt.Size = UDim2.new(1, 0, 0, 26)
		opt.BackgroundColor3 = C.tab_off
		opt.Text = name
		opt.Font = Enum.Font.Gotham
		opt.TextSize = 11
		opt.TextColor3 = C.text
		opt.AutoButtonColor = false
		opt.ZIndex = 6
		Instance.new("UICorner", opt).CornerRadius = UDim.new(0, THEME.cornerSm)
		opt.Parent = listWrap
		opt.MouseButton1Click:Connect(function()
			set_fn(name)
			refresh()
			listWrap.Visible = false
		end)
	end

	mainBtn.MouseButton1Click:Connect(function()
		listWrap.Visible = not listWrap.Visible
	end)
	refresh()
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
local ref_keep_on_target = make_toggle_row(combat_aim, "Keep on target", next_order(), P.get_keep_on_target, P.set_keep_on_target)
section_label(combat_aim, "Targeting", next_order())
local refresh_aim_hitpart = make_hitpart_dropdown(combat_aim, next_order(), P.get_aim_assist_part, P.set_aim_assist_part)
local ref_vis = make_toggle_row(combat_aim, "Visibility check", next_order(), P.get_vis_check, P.set_vis_check)
local ref_team = make_toggle_row(combat_aim, "Team check", next_order(), P.get_aim_team_check, P.set_aim_team_check)
local ref_aim_prisoner = make_toggle_row(
	combat_aim,
	"Prisoner check",
	next_order(),
	P.get_aim_prisoner_check,
	P.set_aim_prisoner_check
)

lo = 0
section_label(combat_silent, "Silent aim", next_order())
local ref_silent_toggle = make_toggle_row(combat_silent, "Silent aim", next_order(), P.get_silent_aim, P.set_silent_aim)
local ref_silent_bind = make_keybind_row(combat_silent, "Silent aim bind", next_order(), P.get_silent_aim_bind, P.set_silent_aim_bind)
local ref_silent_require_bind = make_toggle_row(
	combat_silent,
	"Only while bind held",
	next_order(),
	P.get_silent_aim_require_bind,
	P.set_silent_aim_require_bind
)
local set_silent_fov_slider = make_slider(combat_silent, "Silent aim FOV", next_order(), 20, 400, P.get_silent_aim_fov(), "%.0f", function(v)
	P.set_silent_aim_fov(v)
end)
local ref_silent_fov_follow = make_toggle_row(
	combat_silent,
	"FOV follows cursor",
	next_order(),
	P.get_silent_aim_fov_follow_cursor,
	P.set_silent_aim_fov_follow_cursor
)
local ref_show_silent_fov = make_toggle_row(
	combat_silent,
	"Show silent FOV ring",
	next_order(),
	P.get_show_silent_aim_fov_circle,
	P.set_show_silent_aim_fov_circle
)
local ref_silent_vis = make_toggle_row(
	combat_silent,
	"Visibility check",
	next_order(),
	P.get_silent_aim_vis_check,
	P.set_silent_aim_vis_check
)
local ref_silent_team = make_toggle_row(
	combat_silent,
	"Team check",
	next_order(),
	P.get_silent_aim_team_check,
	P.set_silent_aim_team_check
)
local ref_silent_prisoner = make_toggle_row(
	combat_silent,
	"Prisoner check",
	next_order(),
	P.get_silent_prisoner_check,
	P.set_silent_prisoner_check
)
local refresh_silent_hitpart = make_hitpart_dropdown(combat_silent, next_order(), P.get_silent_aim_part, P.set_silent_aim_part)

lo = 0
section_label(combat_trigger, "Triggerbot", next_order())
local ref_trigger_toggle = make_toggle_row(combat_trigger, "Triggerbot", next_order(), P.get_triggerbot, P.set_triggerbot)
local ref_trigger_bind = make_keybind_row(combat_trigger, "Triggerbot bind", next_order(), P.get_trigger_bind, P.set_trigger_bind)
local set_trigger_delay_slider = make_slider(combat_trigger, "Trigger delay", next_order(), 0.03, 0.5, P.get_trigger_delay(), "%.2f", function(v)
	P.set_trigger_delay(v)
end)

lo = 0
section_label(visuals_esp, "ESP", next_order())
local ref_esp = make_toggle_row(visuals_esp, "ESP highlights", next_order(), P.get_esp, P.set_esp)
local ref_esp_team = make_toggle_row(visuals_esp, "Team check", next_order(), P.get_esp_team_check, P.set_esp_team_check)
local ref_esp_prisoner = make_toggle_row(
	visuals_esp,
	"Prisoner check",
	next_order(),
	P.get_esp_prisoner_check,
	P.set_esp_prisoner_check
)
local ref_esp_vis_colors = make_toggle_row(
	visuals_esp,
	"Body visibility",
	next_order(),
	P.get_esp_visibility_colors,
	P.set_esp_visibility_colors
)
local ref_health = make_toggle_row(visuals_esp, "Health bars", next_order(), P.get_healthbars, P.set_healthbars)
local ref_esp_dist = make_toggle_row(visuals_esp, "Distance text", next_order(), P.get_esp_distance, P.set_esp_distance)
local ref_esp_names = make_toggle_row(visuals_esp, "Player names", next_order(), P.get_esp_names, P.set_esp_names)

lo = 0
section_label(visuals_world, "World", next_order())
local ref_rainbow_car = make_toggle_row(visuals_world, "Rainbow car", next_order(), P.get_rainbow_car, P.set_rainbow_car)

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
local ref_fly
local ref_car_fly
ref_fly = make_toggle_row(movement_fly, "Fly", next_order(), P.get_fly, function(v)
	P.set_fly(v)
	if ref_car_fly then
		ref_car_fly()
	end
end)
local set_fly_speed_slider = make_slider(movement_fly, "Fly speed", next_order(), 5, 500, P.get_fly_speed(), "%.0f", function(v)
	P.set_fly_speed(v)
end)
local ref_fly_bind = make_keybind_row(movement_fly, "Fly bind", next_order(), P.get_fly_bind, P.set_fly_bind)

lo = 0
section_label(movement_car_fly, "Car flight", next_order())
ref_car_fly = make_toggle_row(
	movement_car_fly,
	"Car flight (vehicle only)",
	next_order(),
	P.get_car_fly,
	function(v)
		P.set_car_fly(v)
		if ref_fly then
			ref_fly()
		end
	end
)
local set_car_fly_speed_slider = make_slider(movement_car_fly, "Car flight speed", next_order(), 5, 500, P.get_car_fly_speed(), "%.0f", function(v)
	P.set_car_fly_speed(v)
end)
local ref_car_fly_bind = make_keybind_row(movement_car_fly, "Car flight bind", next_order(), P.get_car_fly_bind, P.set_car_fly_bind)

lo = 0
section_label(movement_walk, "Walk & jump", next_order())
local ref_walk_mod = make_toggle_row(movement_walk, "Walk speed override", next_order(), P.get_walk_mod, P.set_walk_mod)
local ref_walk_mod_bind = make_keybind_row(movement_walk, "Walk speed bind", next_order(), P.get_walk_mod_bind, P.set_walk_mod_bind)
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
local ref_noclip_bind = make_keybind_row(movement_noclip, "Noclip bind", next_order(), P.get_noclip_bind, P.set_noclip_bind)

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
hint.Text = "Delete toggles this menu. Drag the title bar to move. Click a bind, then press a key or mouse button."
hint.Parent = hint_row

local unload_row = make_row(settings_page, next_order(), 44)
local unload_btn = Instance.new("TextButton")
unload_btn.Size = UDim2.new(1, -28, 0, 32)
unload_btn.Position = UDim2.fromOffset(14, 6)
unload_btn.BackgroundColor3 = THEME.danger:Lerp(THEME.bg, 0.52)
unload_btn.TextColor3 = C.text
unload_btn.Font = Enum.Font.GothamBold
unload_btn.TextSize = 13
unload_btn.Text = "Unload Mya Universal"
unload_btn.AutoButtonColor = false
unload_btn.Parent = unload_row
Instance.new("UICorner", unload_btn).CornerRadius = UDim.new(0, THEME.corner)
unload_btn.MouseButton1Click:Connect(function()
	if typeof(_G.unload_mya_universal) == "function" then
		_G.unload_mya_universal()
	end
end)

local function input_matches_movement_bind(input, bind)
	if typeof(bind) ~= "EnumItem" then
		return false
	end
	if bind.EnumType == Enum.KeyCode then
		if bind == Enum.KeyCode.Unknown then
			return false
		end
		return input.UserInputType == Enum.UserInputType.Keyboard and input.KeyCode == bind
	end
	if bind.EnumType == Enum.UserInputType then
		return input.UserInputType == bind
	end
	return false
end

local menu_key = Enum.KeyCode.Delete
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
		return
	end
	if input_matches_movement_bind(input, P.get_fly_bind()) then
		P.set_fly(not P.get_fly())
		ref_fly()
		ref_car_fly()
		return
	end
	if input_matches_movement_bind(input, P.get_car_fly_bind()) then
		P.set_car_fly(not P.get_car_fly())
		ref_car_fly()
		ref_fly()
		return
	end
	if input_matches_movement_bind(input, P.get_walk_mod_bind()) then
		P.set_walk_mod(not P.get_walk_mod())
		ref_walk_mod()
		return
	end
	if input_matches_movement_bind(input, P.get_noclip_bind()) then
		P.set_noclip(not P.get_noclip())
		ref_nc()
		return
	end
end)

switch_tab("Combat")

task.defer(function()
	set_aim_fov_slider(P.get_aim_fov())
	set_aim_speed_slider(P.get_aim_speed())
	set_silent_fov_slider(P.get_silent_aim_fov())
	set_trigger_delay_slider(P.get_trigger_delay())
	set_fly_speed_slider(P.get_fly_speed())
	set_car_fly_speed_slider(P.get_car_fly_speed())
	set_walk_slider(P.get_walk())
	set_jump_slider(P.get_jump())
end)

function _G.MYA_UNIVERSAL_SYNC_UI()
	ref_esp()
	ref_esp_team()
	ref_esp_prisoner()
	ref_esp_vis_colors()
	ref_health()
	ref_esp_dist()
	ref_esp_names()
	ref_rainbow_car()
	ref_aim_toggle()
	ref_aim_bind()
	ref_vis()
	ref_team()
	ref_aim_prisoner()
	ref_show_aim_fov()
	ref_aim_fov_follow()
	ref_keep_on_target()
	refresh_aim_hitpart()
	ref_silent_toggle()
	ref_silent_bind()
	ref_silent_require_bind()
	ref_silent_fov_follow()
	ref_show_silent_fov()
	ref_silent_vis()
	ref_silent_team()
	ref_silent_prisoner()
	refresh_silent_hitpart()
	ref_fly()
	ref_fly_bind()
	ref_car_fly()
	ref_car_fly_bind()
	ref_walk_mod()
	ref_walk_mod_bind()
	ref_jump_mod()
	ref_nc()
	ref_noclip_bind()
	ref_trigger_toggle()
	ref_trigger_bind()
	set_aim_fov_slider(P.get_aim_fov())
	set_aim_speed_slider(P.get_aim_speed())
	set_silent_fov_slider(P.get_silent_aim_fov())
	set_trigger_delay_slider(P.get_trigger_delay())
	set_fly_speed_slider(P.get_fly_speed())
	set_car_fly_speed_slider(P.get_car_fly_speed())
	set_walk_slider(P.get_walk())
	set_jump_slider(P.get_jump())
end
