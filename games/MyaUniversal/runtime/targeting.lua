local function is_teammate(plr)
	if not team_check_on then
		return false
	end
	local t0, t1 = lp.Team, plr.Team
	if not t0 or not t1 then
		return false
	end
	return t0 == t1
end

local function is_visible_to_camera(fromPos, targetChar, targetPoint)
	if not vis_check_on then
		return true
	end
	if not targetChar or not camera then
		return false
	end
	update_vis_filter()
	local dir = targetPoint - fromPos
	local dist = dir.Magnitude
	if dist < 0.05 then
		return true
	end
	local ok, result = pcall(function()
		return Workspace:Raycast(fromPos, dir.Unit * (dist - 0.02), vis_params)
	end)
	if not ok or not result then
		return true
	end
	return result.Instance:IsDescendantOf(targetChar)
end

local function get_best_target(fov_px)
	if not camera then
		return nil, nil, nil
	end
	local anchor = get_fov_screen_anchor(aim_fov_follow_cursor)
	local best_dist = math.huge
	local best_screen, best_world, best_char = nil, nil, nil
	local camPos = camera.CFrame.Position

	for _, plr in ipairs(Players:GetPlayers()) do
		if plr ~= lp and plr.Character and not is_teammate(plr) then
			local head = plr.Character:FindFirstChild("Head")
			if head and head:IsA("BasePart") then
				local pos, on_screen = camera:WorldToViewportPoint(head.Position)
				if on_screen and pos.Z > 0 then
					local sp = Vector2.new(pos.X, pos.Y)
					local d = (sp - anchor).Magnitude
					if d <= fov_px and d < best_dist then
						if vis_check_on and not is_visible_to_camera(camPos, plr.Character, head.Position) then
							-- skip occluded
						else
							best_dist = d
							best_screen = sp
							best_world = head.Position
							best_char = plr.Character
						end
					end
				end
			end
		end
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
