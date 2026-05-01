--[[ Mya · Bite By Night ]]
local P = _G.MYA_BITE
if not P then
	error("[MyaBite] Load runtime.lua first")
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
	error("[MyaBite] MYA_FETCH / MYA_REPO_BASE missing")
end
local libSrc = fetch(repoBase .. "lib/mya_game_ui.lua")
local libFn = loadstring(libSrc, "@lib/mya_game_ui")
if typeof(libFn) ~= "function" then
	error("[MyaBite] lib/mya_game_ui.lua failed to compile")
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
_G.mya_bite_ui = ui

local notify, notif_ui = MyaUI.createNotifyStack({
	C = C,
	THEME = THEME,
	ts = ts,
	gethui_support = gethui_support,
})
_G.mya_bite_notif_ui = notif_ui

local shell = MyaUI.createHubShell({
	ui = ui,
	THEME = THEME,
	C = C,
	ts = ts,
	uis = uis,
	titleText = "Mya  ·  Bite By Night",
	tabNames = { "Visuals", "Settings" },
	subPages = {
		Visuals = { "Visuals" },
	},
	statusDefault = "Ready · Delete toggles menu",
	discordInvite = "https://discord.gg/YeyepQG6K9",
})

local switch_tab = shell.switch_tab
local make_page = shell.make_page
local tab_containers = shell.tab_containers
local all_sub_pages = shell.all_sub_pages

local visuals_page = all_sub_pages["Visuals"]["Visuals"]

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
	lo += 1
	return lo
end

section_label(visuals_page, "Visuals", next_order())
local r_survivor = make_toggle_row(visuals_page, "Survivor ESP", next_order(), P.get_survivor_esp, P.set_survivor_esp)
local r_killer = make_toggle_row(visuals_page, "Killer ESP", next_order(), P.get_killer_esp, P.set_killer_esp)
local r_generator = make_toggle_row(visuals_page, "Generator ESP", next_order(), P.get_generator_esp, P.set_generator_esp)
local r_batteries = make_toggle_row(visuals_page, "Batteries ESP", next_order(), P.get_batteries_esp, P.set_batteries_esp)

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
unload_btn.Text = "Unload Bite By Night"
unload_btn.AutoButtonColor = false
unload_btn.Parent = unload_row
Instance.new("UICorner", unload_btn).CornerRadius = UDim.new(0, THEME.corner)
unload_btn.MouseButton1Click:Connect(function()
	if typeof(_G.unload_mya_bite) == "function" then
		_G.unload_mya_bite()
	end
end)

uis.InputBegan:Connect(function(input, gp)
	if gp then
		return
	end
	if input.KeyCode == Enum.KeyCode.Delete then
		ui.Enabled = not ui.Enabled
	end
end)

P.start()

_G.MYA_BITE_SYNC_UI = function()
	r_survivor()
	r_killer()
	r_generator()
	r_batteries()
end

task.defer(function()
	_G.MYA_BITE_SYNC_UI()
end)

switch_tab("Visuals")
notify("Mya", "Bite By Night ready", 3)

