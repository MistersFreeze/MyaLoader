-- ——— Visuals (ESP + nametags) ———
local visuals_esp = false
local visuals_nametags = false
local visuals_conns = {}
local visuals_periodic_conn = nil
-- Per-player DescendantAdded for late-streamed body/accessories (cleared on character swap / unload).
local visuals_char_tracked = {} -- [Player]: { char: Model, descConn: RBXScriptConnection }

local function visuals_collect_body_parts(char)
	local parts = {}
	for _, p in ipairs(char:GetDescendants()) do
		if p:IsA("BasePart") then
			local tool = p:FindFirstAncestorOfClass("Tool")
			if tool and tool:IsDescendantOf(char) then
				-- skip held tools
			else
				table.insert(parts, p)
			end
		end
	end
	return parts
end

local function visuals_clear_char_track(plr)
	local t = visuals_char_tracked[plr]
	if t and t.descConn then
		pcall(function()
			t.descConn:Disconnect()
		end)
	end
	visuals_char_tracked[plr] = nil
end

local function visuals_strip(char)
	if not char then
		return
	end
	local h = char:FindFirstChild("MyaESP")
	if h then
		h:Destroy()
	end
	local head = char:FindFirstChild("Head")
	if head then
		local b = head:FindFirstChild("MyaNametag")
		if b then
			b:Destroy()
		end
	end
end

local function visuals_track_character(plr, char)
	local existing = visuals_char_tracked[plr]
	if existing and existing.char == char and existing.descConn then
		return
	end
	visuals_clear_char_track(plr)
	if not char or not char.Parent or not visuals_esp then
		return
	end
	local pending = false
	local descConn = char.DescendantAdded:Connect(function(inst)
		if not visuals_esp or plr.Character ~= char then
			return
		end
		if inst:IsA("BasePart") or inst:IsA("Accessory") then
			if pending then
				return
			end
			pending = true
			_task.delay(0.45, function()
				pending = false
				if visuals_esp and plr.Character == char and char.Parent then
					pcall(function()
						visuals_apply(plr, char)
					end)
				end
			end)
		end
	end)
	visuals_char_tracked[plr] = { char = char, descConn = descConn }
end

local function visuals_apply(plr, char)
	if not char then
		return
	end
	visuals_strip(char)
	local show_esp = visuals_esp and plr ~= player
	if show_esp then
		-- Same pattern as Mya Universal `esp.lua`: one Highlight per body part (skin mesh outline), no model hull or adornments.
		local folder = Instance.new("Folder")
		folder.Name = "MyaESP"
		folder.Parent = char
		local fill = Color3.fromRGB(255, 90, 140)
		local outline = Color3.fromRGB(255, 255, 255)
		for _, part in ipairs(visuals_collect_body_parts(char)) do
			local hl = Instance.new("Highlight")
			hl.Name = "MyaESPPart"
			hl.Adornee = part
			hl.Parent = folder
			hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
			hl.FillColor = fill
			hl.OutlineColor = outline
			hl.FillTransparency = 0.55
			hl.OutlineTransparency = 0.3
		end
	end
	if visuals_nametags then
		local head = char:FindFirstChild("Head") or char:WaitForChild("Head", 8)
		if head then
			local bb = Instance.new("BillboardGui")
			bb.Name = "MyaNametag"
			bb.Adornee = head
			bb.AlwaysOnTop = true
			bb.Size = UDim2.fromOffset(200, 26)
			bb.StudsOffset = Vector3.new(0, 2.35, 0)
			bb.Parent = head
			local tl = Instance.new("TextLabel")
			tl.Size = UDim2.fromScale(1, 1)
			tl.BackgroundTransparency = 1
			tl.Text = (plr.DisplayName ~= "" and plr.DisplayName) or plr.Name
			tl.TextColor3 = Color3.fromRGB(255, 235, 245)
			tl.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
			tl.TextStrokeTransparency = 0.45
			tl.Font = Enum.Font.GothamBold
			tl.TextSize = 14
			tl.Parent = bb
		end
	end
end

local function visuals_refresh_all()
	if not visuals_esp then
		for plr in pairs(visuals_char_tracked) do
			visuals_clear_char_track(plr)
		end
	end
	for _, plr in ipairs(players:GetPlayers()) do
		if plr.Character then
			pcall(function()
				visuals_apply(plr, plr.Character)
			end)
			if visuals_esp then
				visuals_track_character(plr, plr.Character)
			end
		end
	end
end

local function visuals_schedule_char_apply(plr, char)
	_task.defer(function()
		pcall(function()
			char:WaitForChild("Humanoid", 15)
			char:WaitForChild("HumanoidRootPart", 15)
		end)
		if plr.Character == char and char.Parent then
			pcall(function()
				visuals_apply(plr, char)
			end)
		end
		if visuals_esp then
			visuals_track_character(plr, char)
		end
	end)
	_task.delay(0.55, function()
		if visuals_esp and plr.Character == char and char.Parent then
			pcall(function()
				visuals_apply(plr, char)
			end)
			visuals_track_character(plr, char)
		end
	end)
	_task.delay(1.8, function()
		if visuals_esp and plr.Character == char and char.Parent then
			pcall(function()
				visuals_apply(plr, char)
			end)
			visuals_track_character(plr, char)
		end
	end)
end

local function visuals_hook_player(plr)
	local c = plr.CharacterAdded:Connect(function(char)
		visuals_schedule_char_apply(plr, char)
	end)
	table.insert(visuals_conns, c)
	if plr.Character then
		visuals_schedule_char_apply(plr, plr.Character)
	end
end

local function visuals_init()
	for _, c in ipairs(visuals_conns) do
		pcall(function()
			c:Disconnect()
		end)
	end
	visuals_conns = {}
	if visuals_periodic_conn then
		pcall(function()
			visuals_periodic_conn:Disconnect()
		end)
		visuals_periodic_conn = nil
	end
	for plr in pairs(visuals_char_tracked) do
		visuals_clear_char_track(plr)
	end

	local acc = 0
	visuals_periodic_conn = run_service.Heartbeat:Connect(function(dt)
		if not visuals_esp then
			return
		end
		acc = acc + dt
		if acc >= 3.5 then
			acc = 0
			pcall(visuals_refresh_all)
		end
	end)
	table.insert(visuals_conns, visuals_periodic_conn)

	table.insert(
		visuals_conns,
		players.PlayerAdded:Connect(function(plr)
			visuals_hook_player(plr)
		end)
	)
	table.insert(
		visuals_conns,
		players.PlayerRemoving:Connect(function(plr)
			visuals_clear_char_track(plr)
		end)
	)
	for _, plr in ipairs(players:GetPlayers()) do
		visuals_hook_player(plr)
	end
end

local function visuals_unload()
	for _, c in ipairs(visuals_conns) do
		pcall(function()
			c:Disconnect()
		end)
	end
	visuals_conns = {}
	visuals_periodic_conn = nil
	for plr in pairs(visuals_char_tracked) do
		visuals_clear_char_track(plr)
	end
	for _, plr in ipairs(players:GetPlayers()) do
		if plr.Character then
			visuals_strip(plr.Character)
		end
	end
end
