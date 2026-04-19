-- Screen arrows: enemy horizontal facing direction (requires Drawing API).

local view_angle_lines = {}

local function hide_lines(lines)
	for i = 1, #lines do
		lines[i].Visible = false
	end
end

local function ensure_view_lines(plr)
	local t = view_angle_lines[plr]
	if t then
		return t
	end
	if not drawing_ok then
		return nil
	end
	t = {}
	for i = 1, 3 do
		local ln = Drawing.new("Line")
		ln.Visible = false
		ln.Thickness = 2
		ln.Color = Color3.fromRGB(255, 210, 120)
		t[i] = ln
	end
	view_angle_lines[plr] = t
	return t
end

function clear_esp_view_angle()
	for _, lines in pairs(view_angle_lines) do
		for i = 1, #lines do
			pcall(function()
				lines[i]:Remove()
			end)
		end
	end
	view_angle_lines = {}
end

function update_esp_view_angle()
	if not esp_view_angle_on or not drawing_ok or not camera then
		for _, lines in pairs(view_angle_lines) do
			hide_lines(lines)
		end
		return
	end
	if not esp_on then
		for _, lines in pairs(view_angle_lines) do
			hide_lines(lines)
		end
		return
	end

	local seen = {}
	for _, plr in ipairs(Players:GetPlayers()) do
		if plr ~= lp then
			local char = plr.Character
			local hrp = char and char:FindFirstChild("HumanoidRootPart")
			if hrp and hrp:IsA("BasePart") and esp_is_valid_enemy_character(plr, char) then
				seen[plr] = true
				local lines = ensure_view_lines(plr)
				if not lines then
					return
				end
				local look = hrp.CFrame.LookVector
				local flat = Vector3.new(look.X, 0, look.Z)
				if flat.Magnitude < 0.12 then
					flat = look
				else
					flat = flat.Unit
				end
				local origin = hrp.Position + Vector3.new(0, 2.2, 0)
				local tipWorld = origin + flat * 5.5
				local a, onA = camera:WorldToViewportPoint(origin)
				local b, onB = camera:WorldToViewportPoint(tipWorld)
				if onA and onB and a.Z > 0 and b.Z > 0 then
					local from = Vector2.new(a.X, a.Y)
					local to = Vector2.new(b.X, b.Y)
					local delta = to - from
					local len = delta.Magnitude
					if len < 5 then
						hide_lines(lines)
					else
						local u = delta / len
						local perp = Vector2.new(-u.Y, u.X)
						local wingLen = math.min(11, len * 0.38)
						local back = to - u * wingLen
						local w = perp * (wingLen * 0.48)
						lines[1].From = from
						lines[1].To = to
						lines[2].From = to
						lines[2].To = back + w
						lines[3].From = to
						lines[3].To = back - w
						for i = 1, 3 do
							lines[i].Visible = true
						end
					end
				else
					hide_lines(lines)
				end
			end
		end
	end

	for plr, lines in pairs(view_angle_lines) do
		if not seen[plr] then
			hide_lines(lines)
		end
	end

	local in_session = {}
	for _, p in ipairs(Players:GetPlayers()) do
		in_session[p] = true
	end
	for plr, lines in pairs(view_angle_lines) do
		if not in_session[plr] then
			for i = 1, #lines do
				pcall(function()
					lines[i]:Remove()
				end)
			end
			view_angle_lines[plr] = nil
		end
	end
end
