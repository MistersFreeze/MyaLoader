local function is_aim_teammate(plr)
	return Combat.same_team(lp, plr, aim_team_check_on)
end

local function is_esp_teammate(plr)
	return Combat.same_team(lp, plr, esp_team_check_on)
end

local Teams = game:GetService("Teams")
local inmatesTeamRef = Teams:FindFirstChild("Inmates")
table.insert(
	connections,
	Teams.ChildAdded:Connect(function(ch)
		if ch.Name == "Inmates" and ch:IsA("Team") then
			inmatesTeamRef = ch
		end
	end)
)

--- Players on the prisoner / inmates team (Teams.Inmates or name contains inmate / prisoner).
local function is_inmate_team(plr)
	if not plr then
		return false
	end
	local t = plr.Team
	if not t then
		return false
	end
	if inmatesTeamRef and t == inmatesTeamRef then
		return true
	end
	local n = string.lower(t.Name)
	if n == "inmates" or n == "inmate" then
		return true
	end
	if string.find(n, "inmate", 1, true) then
		return true
	end
	if string.find(n, "prisoner", 1, true) then
		return true
	end
	return false
end

local function is_aim_skip(plr)
	if is_aim_teammate(plr) then
		return true
	end
	if aim_prisoner_check_on and is_inmate_team(plr) then
		return true
	end
	return false
end

local function is_esp_skip(plr)
	if is_esp_teammate(plr) then
		return true
	end
	if esp_prisoner_check_on and is_inmate_team(plr) then
		return true
	end
	return false
end

-- Unconditional LOS check (used by ESP body visibility colors).
local function ray_visible_to_character(fromPos, targetChar, targetPoint)
	if not targetChar or not camera then
		return false
	end
	update_vis_filter()
	return Combat.los_visible_blacklist(Workspace, fromPos, targetChar, targetPoint, vis_params)
end

local function is_visible_to_camera(fromPos, targetChar, targetPoint)
	if not vis_check_on then
		return true
	end
	return ray_visible_to_character(fromPos, targetChar, targetPoint)
end

local function get_best_target(fov_px, for_aim_lock)
	local use_lock = for_aim_lock and keep_on_target_on
	if not camera then
		return nil, nil, nil
	end
	local anchor = get_fov_screen_anchor(aim_fov_follow_cursor)
	local camPos = camera.CFrame.Position

	if use_lock and aim_lock_plr then
		local plr = aim_lock_plr
		if plr.Parent and plr.Character and not is_aim_skip(plr) and esp_target_within_max_range(plr) then
			local part = plr.Character:FindFirstChild(aim_assist_part)
			if part and part:IsA("BasePart") then
				local pos, on_screen = camera:WorldToViewportPoint(part.Position)
				if on_screen and pos.Z > 0 then
					local sp = Vector2.new(pos.X, pos.Y)
					local d = (sp - anchor).Magnitude
					if d <= fov_px then
						if not vis_check_on or ray_visible_to_character(camPos, plr.Character, part.Position) then
							return sp, part.Position, plr.Character
						end
					end
				end
			end
		end
		aim_lock_plr = nil
	end

	local best_dist = math.huge
	local best_screen, best_world, best_char, best_plr = nil, nil, nil, nil

	for _, plr in ipairs(Players:GetPlayers()) do
		if plr ~= lp and plr.Character and not is_aim_skip(plr) and esp_target_within_max_range(plr) then
			local part = plr.Character:FindFirstChild(aim_assist_part)
			if part and part:IsA("BasePart") then
				local pos, on_screen = camera:WorldToViewportPoint(part.Position)
				if on_screen and pos.Z > 0 then
					local sp = Vector2.new(pos.X, pos.Y)
					local d = (sp - anchor).Magnitude
					if d <= fov_px and d < best_dist then
						if vis_check_on and not ray_visible_to_character(camPos, plr.Character, part.Position) then
							-- skip occluded
						else
							best_dist = d
							best_screen = sp
							best_world = part.Position
							best_char = plr.Character
							best_plr = plr
						end
					end
				end
			end
		end
	end
	if use_lock and best_plr then
		aim_lock_plr = best_plr
	end
	return best_screen, best_world, best_char
end

local function bind_pressed(bind)
	if typeof(bind) ~= "EnumItem" then
		return false
	end
	if bind.EnumType == Enum.UserInputType then
		return UserInputService:IsMouseButtonPressed(bind)
	end
	if bind.EnumType == Enum.KeyCode then
		return UserInputService:IsKeyDown(bind)
	end
	return false
end
