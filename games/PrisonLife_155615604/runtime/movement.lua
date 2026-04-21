local noclip_char_added_conn = nil
local noclip_desc_added_conn = nil
local noclip_desc_removing_conn = nil
-- [BasePart] = { CanCollide, CanQuery, CanTouch } — no GetDescendants() every frame
local noclip_parts = {}

local function refresh_movement()
	local h = get_hum()
	if not h then
		return
	end
	if ws_orig == nil then
		ws_orig = h.WalkSpeed
	end
	if jp_orig == nil then
		jp_orig = h.JumpPower
		jh_orig = h.JumpHeight
	end
	if walk_mod_on then
		h.WalkSpeed = walk_target
	else
		h.WalkSpeed = ws_orig
	end
	if jump_mod_on then
		pcall(function()
			h.UseJumpPower = true
		end)
		h.JumpPower = math.clamp(jump_target, 0, 500)
	else
		h.JumpPower = jp_orig
		if jh_orig ~= nil then
			h.JumpHeight = jh_orig
		end
	end
end

local function restore_movement()
	local h = get_hum()
	if h then
		if ws_orig ~= nil then
			h.WalkSpeed = ws_orig
		end
		if jp_orig ~= nil then
			h.JumpPower = jp_orig
		end
		if jh_orig ~= nil then
			h.JumpHeight = jh_orig
		end
	end
	ws_orig, jp_orig, jh_orig = nil, nil, nil
end

local function stop_fly()
	if fly_conn then
		fly_conn:Disconnect()
		fly_conn = nil
	end
	if fly_bv then
		pcall(function()
			fly_bv:Destroy()
		end)
		fly_bv = nil
	end
	local h = get_hum()
	if h then
		h.PlatformStand = false
	end
end

local function start_fly()
	stop_fly()
	local root = get_root()
	local hum = get_hum()
	if not root or not hum then
		return
	end
	hum.PlatformStand = true
	fly_bv = Instance.new("BodyVelocity")
	fly_bv.MaxForce = Vector3.new(500000, 500000, 500000)
	fly_bv.Velocity = Vector3.zero
	fly_bv.Parent = root
	fly_conn = RunService.RenderStepped:Connect(function()
		if not fly_on or not _G.MYA_UNIVERSAL_LOADED then
			return
		end
		root = get_root()
		if not root or not fly_bv or fly_bv.Parent ~= root then
			return
		end
		local cam = camera
		if not cam then
			return
		end
		local cf = cam.CFrame
		local dir = Vector3.zero
		if UserInputService:IsKeyDown(Enum.KeyCode.W) then
			dir = dir + cf.LookVector
		end
		if UserInputService:IsKeyDown(Enum.KeyCode.S) then
			dir = dir - cf.LookVector
		end
		if UserInputService:IsKeyDown(Enum.KeyCode.D) then
			dir = dir + cf.RightVector
		end
		if UserInputService:IsKeyDown(Enum.KeyCode.A) then
			dir = dir - cf.RightVector
		end
		if UserInputService:IsKeyDown(Enum.KeyCode.Space) then
			dir = dir + Vector3.new(0, 1, 0)
		end
		if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) or UserInputService:IsKeyDown(Enum.KeyCode.C) then
			dir = dir - Vector3.new(0, 1, 0)
		end
		fly_bv.Velocity = dir.Magnitude > 0 and dir.Unit * fly_speed or Vector3.zero
	end)
	table.insert(connections, fly_conn)
end

local function get_vehicle_root_part()
	local hum = get_hum()
	if not hum or not hum.Sit then
		return nil
	end
	local seat = hum.SeatPart
	if not seat or not seat:IsA("BasePart") then
		return nil
	end
	if not (seat:IsA("VehicleSeat") or seat:IsA("Seat")) then
		return nil
	end
	return seat:GetRootPart()
end

local function stop_car_fly()
	if car_fly_conn then
		pcall(function()
			car_fly_conn:Disconnect()
		end)
		car_fly_conn = nil
	end
	if car_fly_bv then
		pcall(function()
			car_fly_bv:Destroy()
		end)
		car_fly_bv = nil
	end
	if car_fly_bav then
		pcall(function()
			car_fly_bav:Destroy()
		end)
		car_fly_bav = nil
	end
end

local function start_car_fly()
	stop_car_fly()
	car_fly_conn = RunService.RenderStepped:Connect(function()
		if not car_fly_on or not _G.MYA_UNIVERSAL_LOADED then
			return
		end
		local root = get_vehicle_root_part()
		if not root then
			if car_fly_bv then
				pcall(function()
					car_fly_bv:Destroy()
				end)
				car_fly_bv = nil
			end
			if car_fly_bav then
				pcall(function()
					car_fly_bav:Destroy()
				end)
				car_fly_bav = nil
			end
			return
		end
		if not car_fly_bv or car_fly_bv.Parent ~= root then
			pcall(function()
				if car_fly_bv then
					car_fly_bv:Destroy()
				end
			end)
			pcall(function()
				if car_fly_bav then
					car_fly_bav:Destroy()
				end
			end)
			car_fly_bv = Instance.new("BodyVelocity")
			car_fly_bv.Name = "MyaCarFlyVel"
			car_fly_bv.MaxForce = Vector3.new(500000, 500000, 500000)
			car_fly_bv.Velocity = Vector3.zero
			car_fly_bv.Parent = root
			car_fly_bav = Instance.new("BodyAngularVelocity")
			car_fly_bav.Name = "MyaCarFlyAng"
			car_fly_bav.MaxTorque = Vector3.new(4000000, 4000000, 4000000)
			car_fly_bav.AngularVelocity = Vector3.zero
			car_fly_bav.Parent = root
		end
		local cam = camera
		if not cam or not car_fly_bv then
			return
		end
		local cf = cam.CFrame
		local dir = Vector3.zero
		if UserInputService:IsKeyDown(Enum.KeyCode.W) then
			dir = dir + cf.LookVector
		end
		if UserInputService:IsKeyDown(Enum.KeyCode.S) then
			dir = dir - cf.LookVector
		end
		if UserInputService:IsKeyDown(Enum.KeyCode.D) then
			dir = dir + cf.RightVector
		end
		if UserInputService:IsKeyDown(Enum.KeyCode.A) then
			dir = dir - cf.RightVector
		end
		if UserInputService:IsKeyDown(Enum.KeyCode.Space) then
			dir = dir + Vector3.new(0, 1, 0)
		end
		if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) or UserInputService:IsKeyDown(Enum.KeyCode.C) then
			dir = dir - Vector3.new(0, 1, 0)
		end
		car_fly_bv.Velocity = dir.Magnitude > 0 and dir.Unit * car_fly_speed or Vector3.zero
		if car_fly_bav then
			car_fly_bav.AngularVelocity = Vector3.zero
		end
		root.AssemblyAngularVelocity = Vector3.zero
	end)
	table.insert(connections, car_fly_conn)
end

local NOCLIP_RENDERSTEP_NAME = "MyaPrisonLifeNoclip"

local function noclip_disconnect_descendant_hooks()
	if noclip_desc_added_conn then
		pcall(function()
			noclip_desc_added_conn:Disconnect()
		end)
		noclip_desc_added_conn = nil
	end
	if noclip_desc_removing_conn then
		pcall(function()
			noclip_desc_removing_conn:Disconnect()
		end)
		noclip_desc_removing_conn = nil
	end
end

local function noclip_restore_all_parts()
	local keys = {}
	for p in pairs(noclip_parts) do
		keys[#keys + 1] = p
	end
	for i = 1, #keys do
		local part = keys[i]
		local saved = noclip_parts[part]
		noclip_parts[part] = nil
		if typeof(saved) == "table" and part:IsA("BasePart") then
			pcall(function()
				if part.Parent then
					part.CanCollide = saved.CanCollide
					part.CanQuery = saved.CanQuery
					part.CanTouch = saved.CanTouch
				end
			end)
		end
	end
end

local function noclip_register_part(p)
	if not p:IsA("BasePart") then
		return
	end
	if noclip_parts[p] ~= nil then
		return
	end
	noclip_parts[p] = {
		CanCollide = p.CanCollide,
		CanQuery = p.CanQuery,
		CanTouch = p.CanTouch,
	}
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
end

local function noclip_unregister_part(p)
	local saved = noclip_parts[p]
	if saved == nil then
		return
	end
	noclip_parts[p] = nil
	if typeof(saved) == "table" and p.Parent then
		pcall(function()
			p.CanCollide = saved.CanCollide
			p.CanQuery = saved.CanQuery
			p.CanTouch = saved.CanTouch
		end)
	end
end

local function noclip_hook_character_descendants(c)
	noclip_disconnect_descendant_hooks()
	if not c then
		return
	end
	noclip_desc_added_conn = c.DescendantAdded:Connect(function(o)
		if not noclip_on or not _G.MYA_UNIVERSAL_LOADED then
			return
		end
		if o:IsA("BasePart") then
			noclip_register_part(o)
		end
	end)
	noclip_desc_removing_conn = c.DescendantRemoving:Connect(function(o)
		if o:IsA("BasePart") then
			noclip_unregister_part(o)
		end
	end)
end

local function noclip_seed_character(c)
	if not c then
		return
	end
	for _, d in ipairs(c:GetDescendants()) do
		noclip_register_part(d)
	end
end

local function noclip_step_force()
	if not noclip_on or not _G.MYA_UNIVERSAL_LOADED then
		return
	end
	if not lp.Character then
		return
	end
	-- Replication often resets collision; re-apply every step (no GetDescendants — O(parts) only).
	local stale = {}
	for part in pairs(noclip_parts) do
		if part.Parent and part:IsA("BasePart") then
			part.CanCollide = false
			part.CanQuery = false
			part.CanTouch = false
		else
			stale[#stale + 1] = part
		end
	end
	for i = 1, #stale do
		noclip_parts[stale[i]] = nil
	end
end

local function stop_noclip()
	if noclip_conn then
		pcall(function()
			noclip_conn:Disconnect()
		end)
		noclip_conn = nil
	end
	pcall(function()
		RunService:UnbindFromRenderStep(NOCLIP_RENDERSTEP_NAME)
	end)
	if noclip_char_added_conn then
		pcall(function()
			noclip_char_added_conn:Disconnect()
		end)
		noclip_char_added_conn = nil
	end
	noclip_disconnect_descendant_hooks()
	noclip_restore_all_parts()
	-- legacy table from older builds (safe if unused)
	for part, was in pairs(noclip_saved) do
		if typeof(was) == "boolean" and part.Parent and part:IsA("BasePart") then
			pcall(function()
				part.CanCollide = was
			end)
		end
	end
	noclip_saved = {}
end

local function start_noclip()
	stop_noclip()
	local okPost, postConn = pcall(function()
		return RunService.PostSimulation:Connect(noclip_step_force)
	end)
	if okPost and postConn then
		noclip_conn = postConn
	else
		noclip_conn = RunService.Heartbeat:Connect(noclip_step_force)
	end
	table.insert(connections, noclip_conn)
	-- Games often reset CanCollide after physics; re-apply at end of frame too.
	pcall(function()
		RunService:BindToRenderStep(NOCLIP_RENDERSTEP_NAME, Enum.RenderPriority.Last, noclip_step_force)
	end)

	local function on_new_character(c)
		task.defer(function()
			if not noclip_on or not _G.MYA_UNIVERSAL_LOADED then
				return
			end
			noclip_restore_all_parts()
			noclip_seed_character(c)
			noclip_hook_character_descendants(c)
		end)
	end

	noclip_char_added_conn = lp.CharacterAdded:Connect(on_new_character)
	table.insert(connections, noclip_char_added_conn)

	local c0 = lp.Character
	if c0 then
		noclip_seed_character(c0)
		noclip_hook_character_descendants(c0)
	end
end

local function hook_other(plr)
	if plr == lp then
		return
	end
	plr.CharacterAdded:Connect(function()
		if esp_on then
			task.defer(esp_refresh)
		end
	end)
end

local function hook_players()
	for _, plr in ipairs(Players:GetPlayers()) do
		hook_other(plr)
	end
	table.insert(
		connections,
		Players.PlayerAdded:Connect(function(plr)
			hook_other(plr)
			task.defer(esp_refresh)
		end)
	)
	table.insert(
		connections,
		Players.PlayerRemoving:Connect(function(plr)
			local h = highlights[plr]
			if h then
				if type(h) == "table" then
					for _, x in ipairs(h) do
						pcall(function()
							x:Destroy()
						end)
					end
				else
					pcall(function()
						h:Destroy()
					end)
				end
				highlights[plr] = nil
			end
			remove_health_draw(plr)
			pcall(function()
				if _G.remove_distance_draw then
					_G.remove_distance_draw(plr)
				end
			end)
			pcall(function()
				if _G.remove_name_draw then
					_G.remove_name_draw(plr)
				end
			end)
		end)
	)
end
