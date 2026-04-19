local function is_aim_teammate(plr)
	return Combat.same_team(lp, plr, aim_team_check_on)
end

local function is_esp_teammate(plr)
	return Combat.same_team(lp, plr, esp_team_check_on)
end

-- Unconditional LOS check (used by ESP body visibility colors).
local function ray_visible_to_character(fromPos, targetChar, targetPoint)
	if not targetChar or not camera then
		return false
	end
	update_vis_filter()
	return Combat.los_visible_blacklist(Workspace, fromPos, targetChar, targetPoint, vis_params)
end

-- Refreshed on Heartbeat (deferred) so aim assist does not hitch the render loop.
local npc_aim_cache = {}
local npc_cache_accum = 0
local NPC_AIM_CACHE_INTERVAL = 0.22

local function rebuild_npc_aim_cache()
	local list = {}
	if not aim_assist_npcs_on then
		npc_aim_cache = list
		return
	end
	for _, inst in ipairs(Workspace:GetDescendants()) do
		if inst:IsA("Model") then
			if not Players:GetPlayerFromCharacter(inst) then
				local hum = inst:FindFirstChildWhichIsA("Humanoid")
				if hum and hum.Health > 0 then
					local part = inst:FindFirstChild(aim_assist_part)
					if part and part:IsA("BasePart") then
						list[#list + 1] = inst
					end
				end
			end
		end
	end
	npc_aim_cache = list
end

function schedule_npc_aim_cache_refresh()
	task.defer(rebuild_npc_aim_cache)
end

table.insert(
	connections,
	RunService.Heartbeat:Connect(function(dt)
		if not aim_assist_npcs_on then
			if #npc_aim_cache > 0 then
				npc_aim_cache = {}
			end
			npc_cache_accum = 0
			return
		end
		npc_cache_accum = npc_cache_accum + dt
		if npc_cache_accum >= NPC_AIM_CACHE_INTERVAL then
			npc_cache_accum = 0
			task.defer(rebuild_npc_aim_cache)
		end
	end)
)

local function get_best_target(fov_px, for_aim_lock)
	local use_lock = for_aim_lock and keep_on_target_on
	if not camera then
		return nil, nil, nil
	end
	local anchor = get_fov_screen_anchor(aim_fov_follow_cursor)
	local camPos = camera.CFrame.Position

	if use_lock and aim_lock_char then
		local char = aim_lock_char
		if char.Parent then
			local plr = Players:GetPlayerFromCharacter(char)
			if plr == lp or (plr and is_aim_teammate(plr)) then
				aim_lock_char = nil
			else
				local hum = char:FindFirstChildWhichIsA("Humanoid")
				local part = char:FindFirstChild(aim_assist_part)
				if hum and hum.Health > 0 and part and part:IsA("BasePart") then
					local pos, on_screen = camera:WorldToViewportPoint(part.Position)
					if on_screen and pos.Z > 0 then
						local sp = Vector2.new(pos.X, pos.Y)
						local d = (sp - anchor).Magnitude
						if d <= fov_px then
							if not vis_check_on or ray_visible_to_character(camPos, char, part.Position) then
								return sp, part.Position, char
							end
						end
					end
				end
			end
		end
		aim_lock_char = nil
	end

	local best_dist = math.huge
	local best_screen, best_world, best_char = nil, nil, nil

	for _, plr in ipairs(Players:GetPlayers()) do
		if plr ~= lp and plr.Character and not is_aim_teammate(plr) then
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
						end
					end
				end
			end
		end
	end

	if aim_assist_npcs_on then
		for _, char in ipairs(npc_aim_cache) do
			if char.Parent then
				local hum = char:FindFirstChildWhichIsA("Humanoid")
				local part = char:FindFirstChild(aim_assist_part)
				if hum and hum.Health > 0 and part and part:IsA("BasePart") then
					local pos, on_screen = camera:WorldToViewportPoint(part.Position)
					if on_screen and pos.Z > 0 then
						local sp = Vector2.new(pos.X, pos.Y)
						local d = (sp - anchor).Magnitude
						if d <= fov_px and d < best_dist then
							if vis_check_on and not ray_visible_to_character(camPos, char, part.Position) then
								-- skip occluded
							else
								best_dist = d
								best_screen = sp
								best_world = part.Position
								best_char = char
							end
						end
					end
				end
			end
		end
	end

	if use_lock and best_char then
		aim_lock_char = best_char
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
