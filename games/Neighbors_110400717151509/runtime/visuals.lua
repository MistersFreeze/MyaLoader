-- ——— Visuals (ESP + nametags) ———
local visuals_esp = false
local visuals_nametags = false
local visuals_conns = {}

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

local function visuals_apply(plr, char)
	if not char then
		return
	end
	visuals_strip(char)
	local show_esp = visuals_esp and plr ~= player
	if show_esp then
		local hl = Instance.new("Highlight")
		hl.Name = "MyaESP"
		hl.Parent = char
		hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
		hl.FillTransparency = 0.55
		hl.OutlineTransparency = 0
		hl.FillColor = Color3.fromRGB(200, 100, 160)
		hl.OutlineColor = Color3.fromRGB(255, 160, 200)
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
	for _, plr in ipairs(players:GetPlayers()) do
		if plr.Character then
			visuals_apply(plr, plr.Character)
		end
	end
end

local function visuals_hook_player(plr)
	local c = plr.CharacterAdded:Connect(function(char)
		_task.defer(function()
			visuals_apply(plr, char)
		end)
	end)
	table.insert(visuals_conns, c)
	if plr.Character then
		_task.defer(function()
			visuals_apply(plr, plr.Character)
		end)
	end
end

local function visuals_init()
	for _, c in ipairs(visuals_conns) do
		pcall(function()
			c:Disconnect()
		end)
	end
	visuals_conns = {}
	table.insert(
		visuals_conns,
		players.PlayerAdded:Connect(function(plr)
			visuals_hook_player(plr)
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
	for _, plr in ipairs(players:GetPlayers()) do
		if plr.Character then
			visuals_strip(plr.Character)
		end
	end
end

