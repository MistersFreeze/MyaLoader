--[[ Mya · Desolate Valley — in-game UI (`lib/mya_game_ui.lua`) ]]

local gethui_support = typeof(gethui) == "function"
local cloneref_fn = typeof(cloneref) == "function" and cloneref or function(x)
	return x
end
local uis = cloneref_fn(game:GetService("UserInputService"))
local ts = game:GetService("TweenService")
local Players = game:GetService("Players")

local fetch = _G.MYA_FETCH
local repoBase = _G.MYA_REPO_BASE
if typeof(fetch) ~= "function" or typeof(repoBase) ~= "string" or #repoBase == 0 then
	error("[Desolate Valley] MYA_FETCH / MYA_REPO_BASE missing — mount via hub with ctx.baseUrl.")
end
local libSrc = fetch(repoBase .. "lib/mya_game_ui.lua")
if typeof(libSrc) ~= "string" or #libSrc == 0 then
	error("[Desolate Valley] Could not load lib/mya_game_ui.lua")
end
local libFn = loadstring(libSrc, "@lib/mya_game_ui")
if typeof(libFn) ~= "function" then
	error("[Desolate Valley] lib/mya_game_ui.lua failed to compile")
end
local MyaUI = libFn()
local THEME, C = MyaUI.defaultTheme()

local localPlayer = Players.LocalPlayer or Players.PlayerAdded:Wait()
local playerGui = localPlayer:WaitForChild("PlayerGui")
local State = _G.MYA_DESOLATE
if type(State) ~= "table" then
	error("[Desolate Valley] MYA_DESOLATE state missing (load runtime.lua first)")
end

local function rand_str(len)
	local chars = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
	local r = {}
	for i = 1, len do
		local j = math.random(1, #chars)
		r[i] = chars:sub(j, j)
	end
	return table.concat(r)
end

local ui = Instance.new("ScreenGui")
ui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ui.Name = rand_str(8)
ui.IgnoreGuiInset = true
ui.DisplayOrder = 35
ui.ResetOnSpawn = false
ui.Parent = gethui_support and gethui() or game:GetService("CoreGui")

local notify, notif_ui = MyaUI.createNotifyStack({
	C = C,
	THEME = THEME,
	ts = ts,
	notifParent = playerGui,
	gethui_support = gethui_support,
})

local shell = MyaUI.createHubShell({
	ui = ui,
	THEME = THEME,
	C = C,
	ts = ts,
	uis = uis,
	titleText = "Mya  ·  Desolate Valley",
	tabNames = { "Visuals", "AutoFarm", "Misc", "Settings" },
	subPages = {},
	statusDefault = "Delete toggles menu",
	discordInvite = false,
	winW = 540,
	winH = 400,
})

local switch_tab = shell.switch_tab
local tab_containers = shell.tab_containers
local make_page = shell.make_page

local visuals_page = make_page()
visuals_page.Visible = true
visuals_page.Parent = tab_containers["Visuals"]
local autofarm_page = make_page()
autofarm_page.Parent = tab_containers["AutoFarm"]
local misc_page = make_page()
misc_page.Parent = tab_containers["Misc"]
local settings_page = make_page()
settings_page.Parent = tab_containers["Settings"]

for _, pg in ipairs({ visuals_page, autofarm_page, misc_page, settings_page }) do
	for _, ch in ipairs(pg:GetChildren()) do
		if ch:IsA("UIListLayout") then
			ch.Padding = UDim.new(0, 5)
			break
		end
	end
end

local ROW_CORNER = THEME.cornerSm + 3
local conns = {}

local function track(c)
	if c then
		table.insert(conns, c)
	end
	return c
end

local function section_label(parent, text, order)
	local lbl = Instance.new("TextLabel")
	lbl.LayoutOrder = order
	lbl.Font = Enum.Font.GothamBold
	lbl.Text = "  " .. string.upper(text)
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
	Instance.new("UICorner", row).CornerRadius = UDim.new(0, ROW_CORNER)
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
end

local function make_info_row(parent, order, text)
	local row = make_row(parent, order, 40)
	local lbl = Instance.new("TextLabel")
	lbl.BackgroundTransparency = 1
	lbl.Size = UDim2.new(1, -28, 1, 0)
	lbl.Position = UDim2.fromOffset(14, 0)
	lbl.Font = Enum.Font.Gotham
	lbl.TextSize = 12
	lbl.TextColor3 = C.dim
	lbl.TextXAlignment = Enum.TextXAlignment.Left
	lbl.TextWrapped = true
	lbl.Text = text
	lbl.Parent = row
end

local function row_button(parent, order, text, callback, danger)
	local row = make_row(parent, order, 40)
	local btn = Instance.new("TextButton")
	btn.BackgroundColor3 = danger and THEME.danger or C.accent
	btn.TextColor3 = danger and Color3.fromRGB(255, 245, 248) or Color3.fromRGB(28, 14, 22)
	btn.Font = Enum.Font.GothamBold
	btn.TextSize = 13
	btn.Text = text
	btn.Size = UDim2.new(1, -28, 0, 30)
	btn.Position = UDim2.new(0.5, 0, 0.5, 0)
	btn.AnchorPoint = Vector2.new(0.5, 0.5)
	btn.AutoButtonColor = false
	Instance.new("UICorner", btn).CornerRadius = UDim.new(0, ROW_CORNER)
	btn.Parent = row
	btn.MouseButton1Click:Connect(callback)
end

section_label(visuals_page, "ESP", 1)
make_toggle_row(visuals_page, "Foraging", 2, State.getVisual("foraging"), function(v)
	State.setVisual("foraging", v)
end)
make_toggle_row(visuals_page, "Mining", 3, State.getVisual("mining"), function(v)
	State.setVisual("mining", v)
end)
make_toggle_row(visuals_page, "Enemies", 4, State.getVisual("enemies"), function(v)
	State.setVisual("enemies", v)
end)
make_toggle_row(visuals_page, "Bosses", 5, State.getVisual("bosses"), function(v)
	State.setVisual("bosses", v)
end)
make_toggle_row(visuals_page, "Players", 6, State.getVisual("players"), function(v)
	State.setVisual("players", v)
end)

section_label(autofarm_page, "Skull", 1)
make_toggle_row(autofarm_page, "Skull autofarm", 2, State.getSkullAutofarm(), function(v)
	State.setSkullAutofarm(v)
	notify("Mya", v and "Skull autofarm on" or "Skull autofarm off", 2)
end)
make_info_row(autofarm_page, 3, "Decorative skull props are ignored.")

section_label(misc_page, "Assist", 1)
make_toggle_row(misc_page, "Auto skill check", 2, State.getAutoSkillCheck(), function(v)
	State.setAutoSkillCheck(v)
end)
make_info_row(misc_page, 3, "Skill check key is locked to E.")
make_toggle_row(misc_page, "Auto dodge (A)", 4, State.getAutoDodge(), function(v)
	State.setAutoDodge(v)
end)

section_label(settings_page, "Script", 1)
row_button(
	settings_page,
	2,
	"Unload",
	function()
		if typeof(_G.unload_mya_desolate) == "function" then
			pcall(_G.unload_mya_desolate)
		end
	end,
	true
)
make_info_row(settings_page, 3, "Delete toggles menu")

track(uis.InputBegan:Connect(function(input, processed)
	if processed then
		return
	end
	if input.KeyCode == Enum.KeyCode.Delete then
		ui.Enabled = not ui.Enabled
	end
end))

local function unload_ui_only()
	for _, c in ipairs(conns) do
		pcall(function()
			c:Disconnect()
		end)
	end
	conns = {}
	if notif_ui and notif_ui.Parent then
		notif_ui:Destroy()
	end
	if ui and ui.Parent then
		ui:Destroy()
	end
end

local prevUnload = _G.unload_mya_desolate
_G.unload_mya_desolate = function()
	unload_ui_only()
	if typeof(prevUnload) == "function" then
		pcall(prevUnload)
	end
end

switch_tab("Visuals")
notify("Mya", "Desolate Valley · Delete to hide menu", 4)
