--[[ Mya · Violence District — in-game UI (`lib/mya_game_ui.lua`) ]]

local gethui_support = typeof(gethui) == "function"
local cloneref_fn = typeof(cloneref) == "function" and cloneref or function(x)
	return x
end
local uis = cloneref_fn(game:GetService("UserInputService"))
local ts = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local CollectionService = game:GetService("CollectionService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local fetch = _G.MYA_FETCH
local repoBase = _G.MYA_REPO_BASE
if typeof(fetch) ~= "function" or typeof(repoBase) ~= "string" or #repoBase == 0 then
	error("[Violence District] MYA_FETCH / MYA_REPO_BASE missing — mount via hub with ctx.baseUrl.")
end
local libSrc = fetch(repoBase .. "lib/mya_game_ui.lua")
if typeof(libSrc) ~= "string" or #libSrc == 0 then
	error("[Violence District] Could not load lib/mya_game_ui.lua")
end
local libFn = loadstring(libSrc, "@lib/mya_game_ui")
if typeof(libFn) ~= "function" then
	error("[Violence District] lib/mya_game_ui.lua failed to compile")
end
local MyaUI = libFn()
local THEME, C = MyaUI.defaultTheme()

local localPlayer = Players.LocalPlayer or Players.PlayerAdded:Wait()
local playerGui = localPlayer:WaitForChild("PlayerGui")

local function rand_str(len)
	local chars = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
	local r = {}
	for i = 1, len do
		local j = math.random(1, #chars)
		r[i] = chars:sub(j, j)
	end
	return table.concat(r)
end

-- Skill check great zone matches Skillcheck-player / Skillcheck-gen white segment logic.
local function rotation_in_great_zone(lineRot, goalRot)
	local line = lineRot
	local low = 104 + goalRot
	local high = 114 + goalRot
	return low <= line and line <= high
end

local function count_team(teamName)
	local n = 0
	for _, p in Players:GetPlayers() do
		if p.Team and p.Team.Name == teamName then
			n = n + 1
		end
	end
	return n
end

local function all_generators_repaired()
	local tagged = CollectionService:GetTagged("Generator")
	local inMap = 0
	for _, m in tagged do
		if m:IsA("Model") and m:IsDescendantOf(workspace) then
			inMap = inMap + 1
			local rp = m:GetAttribute("RepairProgress")
			if typeof(rp) ~= "number" or rp < 100 then
				return false
			end
		end
	end
	return inMap > 0
end

local function door_instance_considered_open(inst)
	if not inst:IsA("BasePart") then
		return false
	end
	local ln = inst.Name:lower()
	if not ln:find("door") or ln:find("outdoor") then
		return false
	end
	local m = inst:FindFirstAncestorWhichIsA("Model")
	if m then
		for _, attr in ipairs({ "Opened", "Open", "IsOpen", "IsOpened", "DoorOpen" }) do
			local v = m:GetAttribute(attr)
			if v == true or v == 1 then
				return true
			end
		end
	end
	if inst.Transparency >= 0.55 then
		return true
	end
	if inst.CanCollide == false and inst.Transparency > 0.2 then
		return true
	end
	return false
end

local function killer_character_model()
	for _, plr in Players:GetPlayers() do
		if plr ~= localPlayer and plr.Team and plr.Team.Name == "Killer" and plr.Character then
			return plr.Character
		end
	end
	return nil
end

local function generator_fill_color(pct)
	pct = math.clamp(pct, 0, 100) / 100
	local cold = Color3.fromRGB(55, 70, 95)
	local hot = Color3.fromRGB(110, 255, 150)
	return cold:Lerp(hot, pct)
end

local opt = {
	esp_survivors = true,
	esp_killer = true,
	esp_generators = true,
	esp_doors = true,
	esp_trapdoor = true,
	killer_power_hud = true,
	auto_skillcheck = false,
}

local hatch_endgame = false
local last_skill_space = 0
local highlights = {}

local COL = {
	survivor = Color3.fromRGB(255, 105, 185),
	killer = Color3.fromRGB(220, 55, 90),
	exit = Color3.fromRGB(255, 215, 95),
	vault = Color3.fromRGB(95, 185, 255),
	pallet = Color3.fromRGB(255, 155, 70),
	hooked = Color3.fromRGB(255, 90, 55),
	knocked = Color3.fromRGB(255, 200, 70),
	door = Color3.fromRGB(175, 125, 255),
	trapdoor = Color3.fromRGB(80, 255, 195),
}
local conns = {}
local uiDestroyed = false
local acc_esp = 0

local function track(c)
	if c then
		table.insert(conns, c)
	end
	return c
end

local function clear_highlight(inst)
	local h = highlights[inst]
	if h then
		pcall(function()
			h:Destroy()
		end)
		highlights[inst] = nil
	end
end

local function set_highlight(target, color)
	if not target or not target.Parent then
		return
	end
	local h = highlights[target]
	if not h then
		h = Instance.new("Highlight")
		h.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
		h.Parent = target
		highlights[target] = h
	end
	h.FillColor = color
	h.OutlineColor = color
	h.FillTransparency = 0.82
	h.OutlineTransparency = 0.35
end

local gen_folder = Instance.new("Folder")
gen_folder.Name = "MyaVD_GenLabels"

local function clear_gen_labels()
	for _, c in gen_folder:GetChildren() do
		c:Destroy()
	end
end

local function sync_gen_labels()
	clear_gen_labels()
	if not opt.esp_generators or uiDestroyed then
		return
	end
	for _, g in CollectionService:GetTagged("Generator") do
		if g:IsA("Model") and g:IsDescendantOf(workspace) and not g:IsDescendantOf(Players) then
			local rp = g:GetAttribute("RepairProgress")
			local pct = typeof(rp) == "number" and math.clamp(rp, 0, 100) or 0
			local part = g.PrimaryPart or g:FindFirstChildWhichIsA("BasePart", true)
			if part and part:IsA("BasePart") then
				local bb = Instance.new("BillboardGui")
				bb.Name = "GenPct_" .. g:GetDebugId()
				bb.Size = UDim2.fromOffset(52, 22)
				bb.StudsOffset = Vector3.new(0, 3.2, 0)
				bb.AlwaysOnTop = true
				bb.Adornee = part
				bb.Parent = gen_folder
				local tl = Instance.new("TextLabel")
				tl.BackgroundColor3 = Color3.fromRGB(18, 14, 22)
				tl.BackgroundTransparency = 0.2
				tl.Size = UDim2.fromScale(1, 1)
				tl.Font = Enum.Font.GothamBold
				tl.TextSize = 12
				tl.TextColor3 = Color3.fromRGB(255, 248, 252)
				tl.Text = string.format("%d%%", math.floor(pct + 0.5))
				tl.Parent = bb
				Instance.new("UICorner", tl).CornerRadius = UDim.new(0, 6)
			end
		end
	end
end

local function sync_esp()
	if uiDestroyed then
		return
	end

	local wanted = {}
	if opt.esp_survivors then
		for _, plr in Players:GetPlayers() do
			if plr ~= localPlayer and plr.Team and plr.Team.Name == "Survivors" and plr.Character then
				wanted[plr.Character] = COL.survivor
			end
		end
		for _, m in CollectionService:GetTagged("Hooked") do
			if m:IsA("Model") and m:IsDescendantOf(workspace) and m:IsDescendantOf(Players) and m:GetAttribute("IsHooked") then
				wanted[m] = COL.hooked
			end
		end
		for _, m in CollectionService:GetTagged("Knocked") do
			if m:IsA("Model") and m:IsDescendantOf(workspace) and m:IsDescendantOf(Players) then
				if m:FindFirstChild("Humanoid") and m:GetAttribute("IsCarried") ~= true then
					wanted[m] = COL.knocked
				end
			end
		end
	end
	if opt.esp_killer then
		local km = killer_character_model()
		if km then
			wanted[km] = COL.killer
		end
	end

	if opt.esp_generators then
		for _, g in CollectionService:GetTagged("Generator") do
			if g:IsA("Model") and g:IsDescendantOf(workspace) and not g:IsDescendantOf(Players) then
				local rp = g:GetAttribute("RepairProgress")
				local pct = typeof(rp) == "number" and math.clamp(rp, 0, 100) or 0
				wanted[g] = generator_fill_color(pct)
			end
		end
	end

	if opt.esp_doors then
		for _, p in CollectionService:GetTagged("ExitPoint") do
			if p:IsA("BasePart") and not p:IsDescendantOf(Players) then
				wanted[p] = COL.exit
			end
		end
		for _, p in CollectionService:GetTagged("KillerHighlightlever") do
			if p:IsA("Model") then
				wanted[p] = COL.exit
			elseif p:IsA("BasePart") and not p:IsDescendantOf(Players) then
				wanted[p] = COL.exit
			end
		end
		for _, p in CollectionService:GetTagged("VaultPoint") do
			if p:IsA("BasePart") and not p:IsDescendantOf(Players) then
				wanted[p] = COL.vault
			end
		end
		for _, tag in ipairs({ "PalletPoint", "PalletPointSlide" }) do
			for _, p in CollectionService:GetTagged(tag) do
				if p:IsA("BasePart") and not p:IsDescendantOf(Players) then
					wanted[p] = COL.pallet
				end
			end
		end
		if all_generators_repaired() then
			local seen = {}
			local scanned = 0
			for _, d in workspace:GetDescendants() do
				scanned = scanned + 1
				if scanned > 2500 then
					break
				end
				if d:IsA("BasePart") and not d:IsDescendantOf(Players) and door_instance_considered_open(d) then
					local id = d:GetDebugId()
					if not seen[id] then
						seen[id] = true
						wanted[d] = COL.door
					end
				end
			end
		end
	end

	if opt.esp_trapdoor and hatch_endgame and count_team("Survivors") == 1 then
		local added = 0
		for _, d in workspace:GetDescendants() do
			if added >= 24 then
				break
			end
			if not d:IsDescendantOf(Players) then
				local ln = d.Name:lower()
				local isHatchName = ln:find("hatch") or ln:find("trapdoor") or ln:find("basement")
				if isHatchName then
					if d:IsA("Model") then
						wanted[d] = COL.trapdoor
						added = added + 1
					elseif d:IsA("BasePart") then
						local anc = d:FindFirstAncestorWhichIsA("Model")
						local an = anc and anc.Name:lower() or ""
						local ancHatch = an:find("hatch") or an:find("trapdoor") or an:find("basement")
						if not ancHatch then
							wanted[d] = COL.trapdoor
							added = added + 1
						end
					end
				end
			end
		end
	end

	local to_clear = {}
	for inst in pairs(highlights) do
		if not wanted[inst] then
			table.insert(to_clear, inst)
		end
	end
	for _, inst in ipairs(to_clear) do
		clear_highlight(inst)
	end
	for inst, col in pairs(wanted) do
		set_highlight(inst, col)
	end
	sync_gen_labels()
end

local function tick_auto_skillcheck()
	if not opt.auto_skillcheck or uiDestroyed then
		return
	end
	local scg = playerGui:FindFirstChild("SkillCheckPromptGui")
	if not scg then
		return
	end
	local check = scg:FindFirstChild("Check")
	if not check or not check.Visible then
		return
	end
	local line = check:FindFirstChild("Line")
	local goal = check:FindFirstChild("Goal")
	if not line or not goal then
		return
	end
	if not rotation_in_great_zone(line.Rotation, goal.Rotation) then
		return
	end
	local now = os.clock()
	if now - last_skill_space < 0.14 then
		return
	end
	last_skill_space = now
	pcall(function()
		VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.Space, false, game)
		VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.Space, false, game)
	end)
end

local ui = Instance.new("ScreenGui")
ui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ui.Name = rand_str(8)
ui.IgnoreGuiInset = true
ui.DisplayOrder = 35
ui.ResetOnSpawn = false
ui.Parent = gethui_support and gethui() or game:GetService("CoreGui")
gen_folder.Parent = ui

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
	titleText = "Mya  ·  Violence District",
	tabNames = { "Visuals", "Assist", "Settings" },
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
local assist_page = make_page()
assist_page.Parent = tab_containers["Assist"]
local settings_page = make_page()
settings_page.Parent = tab_containers["Settings"]

for _, pg in ipairs({ visuals_page, assist_page, settings_page }) do
	for _, ch in ipairs(pg:GetChildren()) do
		if ch:IsA("UIListLayout") then
			ch.Padding = UDim.new(0, 5)
			break
		end
	end
end

local ROW_CORNER = THEME.cornerSm + 3

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

local killerHudLines = {}
local killerHudFrame = Instance.new("Frame")
killerHudFrame.Name = "MyaKillerPowerHud"
killerHudFrame.AnchorPoint = Vector2.new(1, 0)
killerHudFrame.Position = UDim2.new(1, -14, 0, 48)
killerHudFrame.Size = UDim2.fromOffset(208, 102)
killerHudFrame.BackgroundColor3 = C.panel
killerHudFrame.BackgroundTransparency = 0.12
killerHudFrame.BorderSizePixel = 0
killerHudFrame.Visible = false
killerHudFrame.ZIndex = 8
killerHudFrame.Parent = ui
Instance.new("UICorner", killerHudFrame).CornerRadius = UDim.new(0, ROW_CORNER)
local killerHudTitle = Instance.new("TextLabel")
killerHudTitle.BackgroundTransparency = 1
killerHudTitle.Font = Enum.Font.GothamBold
killerHudTitle.TextSize = 11
killerHudTitle.TextColor3 = C.accent
killerHudTitle.TextXAlignment = Enum.TextXAlignment.Left
killerHudTitle.Text = "Power"
killerHudTitle.Position = UDim2.fromOffset(10, 6)
killerHudTitle.Size = UDim2.new(1, -20, 0, 16)
killerHudTitle.Parent = killerHudFrame
local killerHudBody = Instance.new("TextLabel")
killerHudBody.BackgroundTransparency = 1
killerHudBody.Font = Enum.Font.Gotham
killerHudBody.TextSize = 10
killerHudBody.TextColor3 = C.text
killerHudBody.TextXAlignment = Enum.TextXAlignment.Left
killerHudBody.TextYAlignment = Enum.TextYAlignment.Top
killerHudBody.TextWrapped = true
killerHudBody.Text = ""
killerHudBody.Position = UDim2.fromOffset(8, 26)
killerHudBody.Size = UDim2.new(1, -16, 1, -32)
killerHudBody.Parent = killerHudFrame

local function format_remote_args(...)
	local t = { ... }
	local out = {}
	for i = 1, #t do
		local v = t[i]
		local vt = typeof(v)
		if vt == "table" then
			out[i] = "[tbl]"
		elseif vt == "Instance" then
			out[i] = v.Name
		else
			out[i] = tostring(v)
		end
	end
	return table.concat(out, " ")
end

local function wire_killer_remote_event(re, displayName)
	if not re or not re:IsA("RemoteEvent") then
		return
	end
	track(
		re.OnClientEvent:Connect(function(...)
			local line = displayName .. " " .. format_remote_args(...)
			if #line > 118 then
				line = string.sub(line, 1, 118)
			end
			table.insert(killerHudLines, 1, line)
			while #killerHudLines > 5 do
				table.remove(killerHudLines)
			end
			killerHudBody.Text = table.concat(killerHudLines, "\n")
		end)
	)
end

local function sync_killer_hud_visibility()
	local team = localPlayer.Team
	killerHudFrame.Visible = opt.killer_power_hud and team ~= nil and team.Name == "Killer"
end

track(localPlayer:GetPropertyChangedSignal("Team"):Connect(sync_killer_hud_visibility))

section_label(visuals_page, "ESP", 1)
make_toggle_row(visuals_page, "Survivors", 2, opt.esp_survivors, function(v)
	opt.esp_survivors = v
end)
make_toggle_row(visuals_page, "Killer", 3, opt.esp_killer, function(v)
	opt.esp_killer = v
end)
make_toggle_row(visuals_page, "Generators", 4, opt.esp_generators, function(v)
	opt.esp_generators = v
end)
make_toggle_row(visuals_page, "Exits, vaults, and pallets", 5, opt.esp_doors, function(v)
	opt.esp_doors = v
end)
make_toggle_row(visuals_page, "Trapdoor hint", 6, opt.esp_trapdoor, function(v)
	opt.esp_trapdoor = v
end)
make_toggle_row(visuals_page, "Killer power HUD", 7, opt.killer_power_hud, function(v)
	opt.killer_power_hud = v
	sync_killer_hud_visibility()
end)

section_label(assist_page, "Skill check", 1)
make_toggle_row(assist_page, "Auto great white zone", 2, opt.auto_skillcheck, function(v)
	opt.auto_skillcheck = v
	notify("Mya", v and "Auto skill check on" or "Auto skill check off", 2)
end)

section_label(settings_page, "Script", 1)
row_button(
	settings_page,
	2,
	"Unload",
	function()
		if typeof(_G.unload_mya_vd) == "function" then
			pcall(_G.unload_mya_vd)
		end
	end,
	true
)
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

sync_killer_hud_visibility()

track(
	RunService.Heartbeat:Connect(function(dt)
		if uiDestroyed then
			return
		end
		tick_auto_skillcheck()
		acc_esp = acc_esp + dt
		if acc_esp >= 0.22 then
			acc_esp = 0
			sync_esp()
		end
	end)
)

track(
	uis.InputBegan:Connect(function(input, processed)
		if processed then
			return
		end
		if input.KeyCode == Enum.KeyCode.Delete then
			ui.Enabled = not ui.Enabled
		end
	end)
)

task.defer(function()
	local rem = ReplicatedStorage:FindFirstChild("Remotes")
	if not rem then
		return
	end
	local killersRoot = rem:FindFirstChild("Killers")
	if killersRoot then
		local killerFolder = killersRoot:FindFirstChild("Killer")
		if killerFolder then
			for _, evName in ipairs({ "CooldownEvent", "ActivatePower", "PowerDoneDeactivating", "Deactivate", "IdleRefreshEvent" }) do
				wire_killer_remote_event(killerFolder:FindFirstChild(evName), evName)
			end
		end
	end
	local gen = rem:FindFirstChild("Generator")
	if gen then
		local esc = gen:FindFirstChild("Escapetime")
		if esc and esc:IsA("RemoteEvent") then
			track(
				esc.OnClientEvent:Connect(function()
					if count_team("Survivors") == 1 then
						hatch_endgame = true
						notify("Mya", "Endgame — scanning for hatch", 3)
					end
				end)
			)
		end
	end
	local gameRem = rem:FindFirstChild("Game")
	if gameRem then
		local one = gameRem:FindFirstChild("Oneleft")
		if one and one:IsA("RemoteEvent") then
			track(
				one.OnClientEvent:Connect(function()
					if count_team("Survivors") <= 1 then
						hatch_endgame = true
					end
				end)
			)
		end
	end
end)

local function unload_all()
	if uiDestroyed then
		return
	end
	uiDestroyed = true
	clear_gen_labels()
	for _, c in conns do
		pcall(function()
			c:Disconnect()
		end)
	end
	conns = {}
	local hl_clear = {}
	for inst in pairs(highlights) do
		table.insert(hl_clear, inst)
	end
	for _, inst in ipairs(hl_clear) do
		clear_highlight(inst)
	end
	if notif_ui and notif_ui.Parent then
		notif_ui:Destroy()
	end
	if ui and ui.Parent then
		ui:Destroy()
	end
	_G.unload_mya_vd = nil
	_G.MYA_VD_RUN_UI_SYNC = nil
end

_G.unload_mya_vd = unload_all
_G.MYA_VD_RUN_UI_SYNC = function()
end

switch_tab("Visuals")
notify("Mya", "Violence District · Delete to hide menu", 4)
