-- Vertical health bars next to the rig (Drawing lines, or ScreenGui frames if Drawing is unavailable).
-- Prison Life is often R6: use Humanoid.RootPart / Torso fallback — not only HumanoidRootPart.

local HEALTHBAR_GAP_PX = 10

local function get_char_root(char)
	if not char then
		return nil
	end
	local hum = char:FindFirstChildWhichIsA("Humanoid")
	if hum and hum.RootPart and hum.RootPart:IsA("BasePart") then
		return hum.RootPart
	end
	local hrp = char:FindFirstChild("HumanoidRootPart")
	if hrp and hrp:IsA("BasePart") then
		return hrp
	end
	local torso = char:FindFirstChild("Torso")
	if torso and torso:IsA("BasePart") then
		return torso
	end
	return nil
end

local function get_char_head(char)
	if not char then
		return nil
	end
	local h = char:FindFirstChild("Head")
	if h and h:IsA("BasePart") then
		return h
	end
	return nil
end

local function get_health(character)
	local hum = character:FindFirstChildWhichIsA("Humanoid")
	if not hum then
		return nil, nil
	end
	local maxHp = hum.MaxHealth
	if type(maxHp) ~= "number" or maxHp ~= maxHp or maxHp <= 0 then
		maxHp = 100
	end
	local hp = hum.Health
	if type(hp) ~= "number" or hp ~= hp then
		return nil, nil
	end
	return hp, maxHp
end

local function remove_health_draw(plr)
	local d = health_draw[plr]
	if not d then
		return
	end
	if d.kind == "gui" then
		pcall(function()
			d.holder:Destroy()
		end)
	else
		pcall(function()
			d.health_bg:Remove()
		end)
		pcall(function()
			d.health_fill:Remove()
		end)
	end
	health_draw[plr] = nil
end

local function ensure_health_draw(plr)
	if health_draw[plr] then
		return
	end
	if drawing_ok then
		local bg = Drawing.new("Line")
		bg.Visible = false
		bg.Color = Color3.fromRGB(40, 40, 40)
		bg.Thickness = 3
		bg.Transparency = 0.5
		local fill = Drawing.new("Line")
		fill.Visible = false
		fill.Color = Color3.fromRGB(0, 255, 0)
		fill.Thickness = 2
		fill.Transparency = 0
		health_draw[plr] = { kind = "drawing", health_bg = bg, health_fill = fill }
		return
	end
	-- Fallback: no executor Drawing API — use frames on esp_gui (same layer as ESP highlights).
	local holder = Instance.new("Frame")
	holder.Name = "MyaHealthBar"
	holder.BackgroundTransparency = 1
	holder.BorderSizePixel = 0
	holder.ZIndex = 25
	holder.Visible = false
	holder.Parent = esp_gui
	local bg = Instance.new("Frame")
	bg.Name = "BarBg"
	bg.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
	bg.BorderSizePixel = 0
	bg.Size = UDim2.fromScale(1, 1)
	bg.Parent = holder
	Instance.new("UICorner", bg).CornerRadius = UDim.new(0, 2)
	local fill = Instance.new("Frame")
	fill.Name = "BarFill"
	fill.AnchorPoint = Vector2.new(0, 1)
	fill.Position = UDim2.fromScale(0, 1)
	fill.Size = UDim2.new(1, 0, 0.5, 0)
	fill.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
	fill.BorderSizePixel = 0
	fill.Parent = holder
	Instance.new("UICorner", fill).CornerRadius = UDim.new(0, 2)
	health_draw[plr] = { kind = "gui", holder = holder, health_bg = bg, health_fill = fill }
end

local function hide_health(plr)
	local d = health_draw[plr]
	if not d then
		return
	end
	if d.kind == "gui" then
		d.holder.Visible = false
	else
		d.health_bg.Visible = false
		d.health_fill.Visible = false
	end
end

local function update_health_bars()
	if not healthbars_on or not camera then
		for plr in pairs(health_draw) do
			hide_health(plr)
		end
		return
	end

	for plr in pairs(health_draw) do
		if plr == lp or not plr.Parent or is_esp_skip(plr) then
			remove_health_draw(plr)
		end
	end

	for _, plr in ipairs(Players:GetPlayers()) do
		if plr ~= lp and not is_esp_skip(plr) and esp_target_within_max_range(plr) then
			local char = plr.Character
			if not char then
				hide_health(plr)
			else
				local head = get_char_head(char)
				local root = get_char_root(char)
				if not root then
					hide_health(plr)
				else
					local topWorld = head and (head.Position + Vector3.new(0, head.Size.Y * 0.35, 0))
						or (root.Position + Vector3.new(0, 2.2, 0))
					local botWorld = root.Position - Vector3.new(0, 2.5, 0)
					local top_vp = camera:WorldToViewportPoint(topWorld)
					local bot_vp = camera:WorldToViewportPoint(botWorld)
					local root_vp = camera:WorldToViewportPoint(root.Position)
					if not (top_vp.Z > 0 and bot_vp.Z > 0 and root_vp.Z > 0) then
						hide_health(plr)
					else
						ensure_health_draw(plr)
						local data = health_draw[plr]
						local hp, max_hp = get_health(char)
						if not hp or not max_hp or max_hp <= 0 then
							hide_health(plr)
						else
							local by_top = math.min(top_vp.Y, bot_vp.Y)
							local by_bot = math.max(top_vp.Y, bot_vp.Y)
							local bh = by_bot - by_top
							if bh > 1 then
								local right_edge = math.max(top_vp.X, bot_vp.X)
								local bx = right_edge + HEALTHBAR_GAP_PX
								local pct = math.clamp(hp / max_hp, 0, 1)
								local fillCol =
									Color3.fromRGB(math.floor(255 * (1 - pct)), math.floor(255 * pct), 0)
								if data.kind == "gui" then
									data.holder.Position = UDim2.fromOffset(math.floor(bx - 2), math.floor(by_top))
									data.holder.Size = UDim2.fromOffset(4, math.floor(bh))
									data.health_fill.Size = UDim2.new(1, 0, pct, 0)
									data.health_fill.BackgroundColor3 = fillCol
									data.holder.Visible = true
								else
									data.health_bg.From = Vector2.new(bx, by_top)
									data.health_bg.To = Vector2.new(bx, by_bot)
									data.health_bg.Visible = true
									data.health_fill.From = Vector2.new(bx, by_bot - bh * pct)
									data.health_fill.To = Vector2.new(bx, by_bot)
									data.health_fill.Color = fillCol
									data.health_fill.Visible = true
								end
							else
								hide_health(plr)
							end
						end
					end
				end
			end
		else
			hide_health(plr)
		end
	end
end
