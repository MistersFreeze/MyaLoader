local function update_highlight(plr, char)
	if not settings.player_esp then
		local h = highlights[plr]
		if h then
			h.Enabled = false
		end
		return
	end
	local h = highlights[plr]
	local espColor = get_player_esp_color(plr)
	if not h then
		h = Instance.new("Highlight")
		h.Name = "MyaBoogaPlayerESP"
		h.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
		h.FillColor = espColor
		h.OutlineColor = Color3.fromRGB(255, 255, 255)
		h.FillTransparency = 0.6
		h.OutlineTransparency = 0
		h.Parent = highlights_folder
		highlights[plr] = h
	end
	h.FillColor = espColor
	h.Adornee = char
	h.Enabled = true
end

local function update_tracer(plr, hrp, vp_size)
	if not settings.tracers or not drawing_ok then
		hide_drawing(tracers, plr)
		return
	end
	local pos, on_screen = camera:WorldToViewportPoint(hrp.Position)
	if not on_screen or pos.Z <= 0 then
		hide_drawing(tracers, plr)
		return
	end
	local ln = ensure_line(tracers, plr, Color3.fromRGB(255, 140, 200), 1.5, 1)
	if not ln then
		return
	end
	ln.Color = get_player_esp_color(plr)
	ln.From = Vector2.new(vp_size.X * 0.5, vp_size.Y - 8)
	ln.To = Vector2.new(pos.X, pos.Y)
	ln.Visible = true
end

local function update_health(plr, hum, hrp, head)
	if not settings.health_bar or not drawing_ok then
		hide_drawing(health_outline, plr)
		hide_drawing(health_fill, plr)
		return
	end
	local top, top_ok = camera:WorldToViewportPoint(head.Position + Vector3.new(0, 0.6, 0))
	local bottom, bottom_ok = camera:WorldToViewportPoint(hrp.Position - Vector3.new(0, 2.6, 0))
	if not top_ok or not bottom_ok or top.Z <= 0 or bottom.Z <= 0 then
		hide_drawing(health_outline, plr)
		hide_drawing(health_fill, plr)
		return
	end
	local height = math.max(22, math.abs(bottom.Y - top.Y))
	local x = top.X - 20
	local y1 = top.Y
	local y2 = top.Y + height
	local hp = math.clamp(hum.Health / math.max(1, hum.MaxHealth), 0, 1)

	local outline = ensure_line(health_outline, plr, Color3.fromRGB(20, 20, 20), 3.5, 1)
	local fill = ensure_line(health_fill, plr, Color3.fromRGB(90, 255, 120), 2.2, 1)
	if not outline or not fill then
		return
	end
	fill.Color = Color3.fromRGB(90, 255, 120)
	outline.From = Vector2.new(x, y1)
	outline.To = Vector2.new(x, y2)
	outline.Visible = true
	fill.From = Vector2.new(x, y2)
	fill.To = Vector2.new(x, y2 - (height * hp))
	fill.Visible = true
end

local function update_distance(plr, hrp, my_hrp)
	if not settings.distance or not drawing_ok then
		hide_drawing(distance_text, plr)
		return
	end
	local pos, on_screen = camera:WorldToViewportPoint(hrp.Position - Vector3.new(0, 3.1, 0))
	if not on_screen or pos.Z <= 0 then
		hide_drawing(distance_text, plr)
		return
	end
	local txt = ensure_text(distance_text, plr, Color3.fromRGB(235, 235, 245), 13)
	if not txt then
		return
	end
	txt.Color = get_player_esp_color(plr)
	txt.Position = Vector2.new(pos.X, pos.Y)
	txt.Text = string.format("%.0fm", (my_hrp.Position - hrp.Position).Magnitude)
	txt.Visible = true
end

local function update_username(plr, head)
	if not settings.usernames or not drawing_ok then
		hide_drawing(username_text, plr)
		return
	end
	local pos, on_screen = camera:WorldToViewportPoint(head.Position + Vector3.new(0, 1.8, 0))
	if not on_screen or pos.Z <= 0 then
		hide_drawing(username_text, plr)
		return
	end
	local txt = ensure_text(username_text, plr, Color3.fromRGB(255, 210, 230), 13)
	if not txt then
		return
	end
	txt.Color = get_player_esp_color(plr)
	txt.Position = Vector2.new(pos.X, pos.Y)
	txt.Text = (plr.DisplayName and #plr.DisplayName > 0) and plr.DisplayName or plr.Name
	txt.Visible = true
end

local function update_trader_esp(my_hrp, vp_size)
	if not settings.trader_esp then
		for key in pairs(trader_highlights) do
			hide_trader_visual(key)
		end
		return
	end
	cleanup_stale_trader_visuals()
	local seen = {}
	for inst in pairs(tracked_traders) do
		local adornee = inst.PrimaryPart or inst:FindFirstChildWhichIsA("BasePart", true)
		if adornee then
			seen[inst] = true
			local h = trader_highlights[inst]
			if not h then
				h = Instance.new("Highlight")
				h.Name = "MyaBoogaTraderESP"
				h.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
				h.FillColor = Color3.fromRGB(120, 210, 255)
				h.OutlineColor = Color3.fromRGB(255, 255, 255)
				h.FillTransparency = 0.6
				h.OutlineTransparency = 0
				h.Parent = highlights_folder
				trader_highlights[inst] = h
			end
			h.Adornee = inst
			h.Enabled = true
			if settings.trader_tracers and drawing_ok then
				local p, on_screen = camera:WorldToViewportPoint(adornee.Position)
				if on_screen and p.Z > 0 then
					local ln = trader_tracers[inst]
					if not ln then
						ln = Drawing.new("Line")
						ln.Visible = false
						ln.Color = Color3.fromRGB(120, 210, 255)
						ln.Thickness = 1.5
						ln.Transparency = 1
						ln.From = Vector2.new(vp_size.X * 0.5, vp_size.Y - 8)
						ln.To = Vector2.new(p.X, p.Y)
						trader_tracers[inst] = ln
					end
					local targetTo = Vector2.new(p.X, p.Y)
					ln.From = Vector2.new(vp_size.X * 0.5, vp_size.Y - 8)
					ln.To = ln.To:Lerp(targetTo, 0.45)
					ln.Visible = true
				else
					local ln = trader_tracers[inst]
					if ln then
						ln.Visible = false
					end
				end
			else
				local ln = trader_tracers[inst]
				if ln then
					ln.Visible = false
				end
			end
		end
	end
	for key in pairs(trader_highlights) do
		if not seen[key] then
			hide_trader_visual(key)
		end
	end
	for key in pairs(trader_tracers) do
		if not seen[key] then
			hide_trader_visual(key)
		end
	end
end

local function runtime_step()
	if not camera then
		hide_all_visuals()
		step_noclip()
		refresh_speed()
		refresh_noclip_cam()
		return
	end
	cleanup_stale_visuals()
	step_noclip()
	refresh_speed()
	refresh_noclip_cam()
	step_water_walker()
	local my_char = lp.Character
	local _, my_hrp = is_alive_character(my_char)
	if not my_hrp then
		hide_all_visuals()
		return
	end

	local vp_size = camera.ViewportSize
	update_trader_esp(my_hrp, vp_size)
	player_visual_frame += 1
	if player_visual_frame % 2 == 0 then
		return
	end
	for _, plr in ipairs(Players:GetPlayers()) do
		if plr ~= lp then
			local char = plr.Character
			local hum, hrp, head = is_alive_character(char)
			if not hum then
				hide_visuals_for_player(plr)
			else
				update_highlight(plr, char)
				update_tracer(plr, hrp, vp_size)
				update_health(plr, hum, hrp, head)
				update_distance(plr, hrp, my_hrp)
				update_username(plr, head)
			end
		end
	end
end
