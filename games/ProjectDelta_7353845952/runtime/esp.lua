local COLOR_ESP_HIDDEN = Color3.fromRGB(255, 90, 140)
local COLOR_ESP_VISIBLE = Color3.fromRGB(90, 220, 130)

-- Only R6/R15 (and common) avatar parts — welded map/foliage under Character is excluded.
local BODY_NAME_KEYS = {
	head = true,
	humanoidrootpart = true,
	torso = true,
	uppertorso = true,
	lowertorso = true,
	leftarm = true,
	rightarm = true,
	leftleg = true,
	rightleg = true,
	leftupperarm = true,
	leftlowerarm = true,
	lefthand = true,
	rightupperarm = true,
	rightlowerarm = true,
	righthand = true,
	leftupperleg = true,
	leftlowerleg = true,
	leftfoot = true,
	rightupperleg = true,
	rightlowerleg = true,
	rightfoot = true,
}

local function normalized_part_name(name)
	return (name:gsub("%s+", "")):lower()
end

local function is_allowed_character_body_part(char, p)
	if not p:IsA("BasePart") or not p:IsDescendantOf(char) then
		return false
	end
	local tool = p:FindFirstAncestorOfClass("Tool")
	if tool and tool:IsDescendantOf(char) then
		return false
	end
	if p.Name == "Handle" then
		local acc = p:FindFirstAncestorOfClass("Accessory")
		if acc and acc:IsDescendantOf(char) then
			return true
		end
	end
	return BODY_NAME_KEYS[normalized_part_name(p.Name)] == true
end

local function is_under_terrain(inst)
	local p = inst
	while p do
		if p:IsA("Terrain") then
			return true
		end
		p = p.Parent
	end
	return false
end

-- Skip glitched / non-character rigs so we don't highlight random world geometry.
local function looks_like_valid_player_character(char, plr)
	if not char or not char:IsA("Model") then
		return false
	end
	if plr and Players:GetPlayerFromCharacter(char) ~= plr then
		return false
	end
	if is_under_terrain(char) then
		return false
	end
	local hum = char:FindFirstChildWhichIsA("Humanoid")
	if not hum then
		return false
	end
	local rt = hum.RigType
	if rt ~= Enum.HumanoidRigType.R15 and rt ~= Enum.HumanoidRigType.R6 and rt ~= Enum.HumanoidRigType.Custom then
		return false
	end
	local head = char:FindFirstChild("Head")
	local hrp = char:FindFirstChild("HumanoidRootPart")
	local torso = char:FindFirstChild("Torso") or char:FindFirstChild("UpperTorso")
	if not head and not hrp and not torso then
		return false
	end
	local ok, ext = pcall(function()
		return char:GetExtentsSize()
	end)
	if ok and ext then
		if ext.Magnitude > 135 or ext.X > 72 or ext.Z > 72 or ext.Y > 118 then
			return false
		end
	end
	local bp = 0
	for _, d in ipairs(char:GetDescendants()) do
		if d:IsA("BasePart") and is_allowed_character_body_part(char, d) then
			bp = bp + 1
			if bp > 40 then
				return false
			end
		end
	end
	if bp < 3 then
		return false
	end
	return true
end

function esp_is_valid_enemy_character(plr, char)
	if not plr or not char or plr == lp or is_esp_teammate(plr) then
		return false
	end
	return looks_like_valid_player_character(char, plr)
end

local function esp_clear()
	for _, list in pairs(highlights) do
		if type(list) == "table" then
			for _, h in ipairs(list) do
				pcall(function()
					h:Destroy()
				end)
			end
		else
			pcall(function()
				list:Destroy()
			end)
		end
	end
	highlights = {}
end

local function collect_body_parts(char)
	local parts = {}
	for _, p in ipairs(char:GetDescendants()) do
		if is_allowed_character_body_part(char, p) then
			table.insert(parts, p)
		end
	end
	return parts
end

local function esp_refresh()
	esp_clear()
	if not esp_on then
		return
	end
	for _, plr in ipairs(Players:GetPlayers()) do
		if plr ~= lp and plr.Character and not is_esp_teammate(plr) then
			local char = plr.Character
			if looks_like_valid_player_character(char, plr) then
				local list = {}
				local bodyparts = collect_body_parts(char)
				for _, part in ipairs(bodyparts) do
					local hl = Instance.new("Highlight")
					hl.Name = "MyaUniESP"
					hl.Adornee = part
					hl.FillColor = COLOR_ESP_HIDDEN
					hl.OutlineColor = Color3.fromRGB(255, 255, 255)
					hl.FillTransparency = 0.55
					hl.OutlineTransparency = 1
					hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
					hl.Parent = esp_gui
					table.insert(list, hl)
				end
				if #list > 0 then
					highlights[plr] = list
				end
			end
		end
	end
end

-- Rebuild highlights if they were never created (streaming) or broke (parts recreated / ragdoll).
local last_repair_scan_t = 0
local last_repair_refresh_t = 0
local REPAIR_SCAN_INTERVAL = 0.22
local REPAIR_REFRESH_COOLDOWN = 0.4

function maybe_repair_esp_highlights()
	if not esp_on then
		return
	end
	local now = os.clock()
	if now - last_repair_scan_t < REPAIR_SCAN_INTERVAL then
		return
	end
	last_repair_scan_t = now
	for _, plr in ipairs(Players:GetPlayers()) do
		if plr ~= lp and not is_esp_teammate(plr) then
			local char = plr.Character
			if char and looks_like_valid_player_character(char, plr) then
				local list = highlights[plr]
				local need = false
				if not list or type(list) ~= "table" or #list == 0 then
					need = true
				else
					for i = 1, #list do
						local hl = list[i]
						if not hl or hl.Parent == nil then
							need = true
							break
						end
						local ad = hl.Adornee
						if not ad or ad.Parent == nil or not ad:IsDescendantOf(char) then
							need = true
							break
						end
					end
				end
				if need then
					if now - last_repair_refresh_t >= REPAIR_REFRESH_COOLDOWN then
						last_repair_refresh_t = now
						esp_refresh()
					end
					return
				end
			end
		end
	end
end

local vis_color_frame = 0
local function update_esp_visibility_colors()
	if not esp_on or not esp_visibility_colors_on or not camera then
		return
	end
	-- Per-part raycasts are the hottest path; update every other frame (~50% less work).
	vis_color_frame = vis_color_frame + 1
	if vis_color_frame % 2 == 0 then
		return
	end
	local camPos = camera.CFrame.Position
	for plr, list in pairs(highlights) do
		if type(list) == "table" and plr ~= lp and plr.Parent and not is_esp_teammate(plr) then
			local char = plr.Character
			if char and looks_like_valid_player_character(char, plr) then
				for _, hl in ipairs(list) do
					local ad = hl.Adornee
					if ad and ad:IsA("BasePart") then
						local vis = ray_visible_to_character(camPos, char, ad.Position)
						hl.FillColor = vis and COLOR_ESP_VISIBLE or COLOR_ESP_HIDDEN
					end
				end
			end
		end
	end
end
