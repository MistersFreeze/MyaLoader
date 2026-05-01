--[[ Mya · Flex Your FPS — hub shell (`lib/mya_game_ui.lua`) ]]

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
	error("[Flex Your FPS] MYA_FETCH / MYA_REPO_BASE missing — mount via hub with ctx.baseUrl.")
end
local libSrc = fetch(repoBase .. "lib/mya_game_ui.lua")
if typeof(libSrc) ~= "string" or #libSrc == 0 then
	error("[Flex Your FPS] Could not load lib/mya_game_ui.lua from repo base: " .. repoBase)
end
local libFn = loadstring(libSrc, "@lib/mya_game_ui")
if typeof(libFn) ~= "function" then
	error("[Flex Your FPS] lib/mya_game_ui.lua failed to compile")
end
local MyaUI = libFn()
local THEME, C = MyaUI.defaultTheme()

local P = _G.MYA_FLEX_FPS
if not P then
	error("[Flex Your FPS] MYA_FLEX_FPS missing — load runtime.lua first")
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
	titleText = "Mya  ·  Flex Your FPS",
	tabNames = { "Flex", "Settings" },
	subPages = {},
	statusDefault = "Ready · Delete toggles menu",
	discordInvite = "https://discord.gg/YeyepQG6K9",
	winW = 440,
	winH = 420,
})

local switch_tab = shell.switch_tab
local tab_containers = shell.tab_containers
local make_page = shell.make_page

local flex_page = make_page()
flex_page.Visible = true
flex_page.Parent = tab_containers["Flex"]
local settings_page = make_page()
settings_page.Parent = tab_containers["Settings"]

local ROW_CORNER = THEME.cornerSm + 3

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
	return refresh
end

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

for _, pg in ipairs({ flex_page, settings_page }) do
	for _, ch in ipairs(pg:GetChildren()) do
		if ch:IsA("UIListLayout") then
			ch.Padding = UDim.new(0, 5)
			break
		end
	end
end

section_label(flex_page, "Display multipliers", 1)
make_toggle_row(flex_page, "Apply flex", 2, P.get_flex_enabled(), function(v)
	P.set_flex_enabled(v)
	notify("Mya", v and "Flex on" or "Flex off", 2)
end)
make_slider(flex_page, "FPS × (1–15)", 3, 1, 15, P.get_fps_mult(), "%.1f", function(v)
	P.set_fps_mult(v)
end)
make_slider(flex_page, "Ping × (0.1–10)", 4, 0.1, 10, P.get_ping_mult(), "%.2f", function(v)
	P.set_ping_mult(v)
end)
make_slider(flex_page, "Resolution × (0.1–10)", 5, 0.1, 10, P.get_res_mult(), "%.2f", function(v)
	P.set_res_mult(v)
end)

section_label(settings_page, "Script", 1)
row_button(settings_page, 2, "Unload", function()
	if typeof(_G.unload_mya) == "function" then
		pcall(_G.unload_mya)
	end
end)
local s_hint = make_row(settings_page, 3, 40)
local sl = Instance.new("TextLabel")
sl.BackgroundTransparency = 1
sl.Size = UDim2.new(1, -28, 1, 0)
sl.Position = UDim2.fromOffset(14, 0)
sl.Font = Enum.Font.Gotham
sl.TextSize = 12
sl.TextColor3 = C.dim
sl.TextXAlignment = Enum.TextXAlignment.Left
sl.TextWrapped = true
sl.Text = "Delete toggles menu"
sl.Parent = s_hint

P.start_flex_runtime()

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
_G.mya_flex_notif_ui = notif_ui

_G.MYA_FLEX_RUN_UI_SYNC = function()
end

switch_tab("Flex")
notify("Mya", "Flex Your FPS · Delete to hide menu", 4)
