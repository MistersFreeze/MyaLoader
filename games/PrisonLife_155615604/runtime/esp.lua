local COLOR_ESP_HIDDEN = Color3.fromRGB(255, 90, 140)
local COLOR_ESP_VISIBLE = Color3.fromRGB(90, 220, 130)

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

local function esp_refresh()
	esp_clear()
	if not esp_on then
		return
	end
	-- Per-part highlights (not Adornee = Model): full transparency / invisibility on the rig
	-- does not cull the overlay the way a model-level Highlight often does.
	for _, plr in ipairs(Players:GetPlayers()) do
		if plr ~= lp and plr.Character and not is_esp_skip(plr) and esp_target_within_max_range(plr) then
			local char = plr.Character
			local list = {}
			for _, part in ipairs(collect_body_parts(char)) do
				local hl = Instance.new("Highlight")
				hl.Name = "MyaUniESP"
				hl.Adornee = part
				hl.FillColor = COLOR_ESP_HIDDEN
				hl.OutlineColor = Color3.fromRGB(255, 255, 255)
				hl.FillTransparency = 0.55
				hl.OutlineTransparency = 0.3
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

local function update_esp_visibility_colors()
	if not esp_on or not esp_visibility_colors_on or not camera then
		return
	end
	local camPos = camera.CFrame.Position
	for plr, list in pairs(highlights) do
		if type(list) == "table" and plr ~= lp and plr.Parent and not is_esp_skip(plr) and esp_target_within_max_range(plr) then
			local char = plr.Character
			if char then
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
