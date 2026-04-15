local function remove_health_draw(plr)
	local d = health_draw[plr]
	if not d then
		return
	end
	pcall(function()
		d.health_bg:Remove()
	end)
	pcall(function()
		d.health_fill:Remove()
	end)
	health_draw[plr] = nil
end

local function ensure_health_draw(plr)
	if not drawing_ok or health_draw[plr] then
		return
	end
	local bg = Drawing.new("Line")
	bg.Visible = false
	bg.Color = Color3.fromRGB(40, 40, 40)
	bg.Thickness = 3
	bg.Transparency = 0.5
	local fill = Drawing.new("Line")
	fill.Visible = false
	fill.Color = Color3.fromRGB(0, 255, 0)
	fill.Thickness = 2
	fill.Transparency = 1
	health_draw[plr] = { health_bg = bg, health_fill = fill }
end

local function get_health(character)
	local hum = character:FindFirstChildWhichIsA("Humanoid")
	if not hum then
		return nil, nil
	end
	return hum.Health, hum.MaxHealth
end

local function hide_health(plr)
	local d = health_draw[plr]
	if d then
		d.health_bg.Visible = false
		d.health_fill.Visible = false
	end
end

local function update_health_bars()
	if not drawing_ok or not healthbars_on or not camera then
		for plr in pairs(health_draw) do
			hide_health(plr)
		end
		return
	end

	for _, plr in ipairs(Players:GetPlayers()) do
		if plr ~= lp and not is_teammate(plr) then
			local char = plr.Character
			if not char then
				hide_health(plr)
			else
				local head = char:FindFirstChild("Head")
				local hrp = char:FindFirstChild("HumanoidRootPart")
				if not head or not hrp or not head:IsA("BasePart") or not hrp:IsA("BasePart") then
					hide_health(plr)
				else
					ensure_health_draw(plr)
					local data = health_draw[plr]
					local hp, max_hp = get_health(char)
					if not hp or not max_hp or max_hp <= 0 then
						hide_health(plr)
					else
						local top_vp = camera:WorldToViewportPoint(head.Position + Vector3.new(0, 0.35, 0))
						local bot_vp = camera:WorldToViewportPoint(hrp.Position - Vector3.new(0, 2.5, 0))
						local tz = camera:WorldToViewportPoint(hrp.Position).Z
						if tz > 0 and top_vp.Z > 0 and bot_vp.Z > 0 then
							local by_top = math.min(top_vp.Y, bot_vp.Y)
							local by_bot = math.max(top_vp.Y, bot_vp.Y)
							local bh = by_bot - by_top
							if bh > 1 then
								local left_edge = math.min(top_vp.X, bot_vp.X)
								local bx = left_edge - 14
								local pct = math.clamp(hp / max_hp, 0, 1)
								data.health_bg.From = Vector2.new(bx, by_top)
								data.health_bg.To = Vector2.new(bx, by_bot)
								data.health_bg.Visible = true
								data.health_fill.From = Vector2.new(bx, by_bot - bh * pct)
								data.health_fill.To = Vector2.new(bx, by_bot)
								data.health_fill.Color =
									Color3.fromRGB(math.floor(255 * (1 - pct)), math.floor(255 * pct), 0)
								data.health_fill.Visible = true
							else
								hide_health(plr)
							end
						else
							hide_health(plr)
						end
					end
				end
			end
		end
	end
end
