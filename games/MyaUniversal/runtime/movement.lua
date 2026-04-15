local noclip_char_added_conn = nil
local noclip_descendant_conn = nil

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

local function stop_noclip()
	if noclip_conn then
		pcall(function()
			noclip_conn:Disconnect()
		end)
		noclip_conn = nil
	end
	if noclip_char_added_conn then
		pcall(function()
			noclip_char_added_conn:Disconnect()
		end)
		noclip_char_added_conn = nil
	end
	if noclip_descendant_conn then
		pcall(function()
			noclip_descendant_conn:Disconnect()
		end)
		noclip_descendant_conn = nil
	end
	for part, was in pairs(noclip_saved) do
		if part.Parent and part:IsA("BasePart") then
			pcall(function()
				part.CanCollide = was
			end)
		end
	end
	noclip_saved = {}
end

local function apply_noclip_character(c)
	if not c then
		return
	end
	for _, p in ipairs(c:GetDescendants()) do
		if p:IsA("BasePart") then
			if noclip_saved[p] == nil then
				noclip_saved[p] = p.CanCollide
			end
			p.CanCollide = false
		end
	end
end

local function start_noclip()
	stop_noclip()
	local function step()
		if not noclip_on or not _G.MYA_UNIVERSAL_LOADED then
			return
		end
		apply_noclip_character(lp.Character)
	end
	local postSim = RunService.PostSimulation
	if postSim then
		noclip_conn = postSim:Connect(step)
	else
		noclip_conn = RunService.Heartbeat:Connect(step)
	end
	table.insert(connections, noclip_conn)

	local function hook_descendants(c)
		if noclip_descendant_conn then
			pcall(function()
				noclip_descendant_conn:Disconnect()
			end)
			noclip_descendant_conn = nil
		end
		if not c then
			return
		end
		noclip_descendant_conn = c.DescendantAdded:Connect(function(o)
			if noclip_on and o:IsA("BasePart") then
				if noclip_saved[o] == nil then
					noclip_saved[o] = o.CanCollide
				end
				o.CanCollide = false
			end
		end)
	end

	hook_descendants(lp.Character)
	noclip_char_added_conn = lp.CharacterAdded:Connect(function(c)
		task.defer(function()
			if not noclip_on then
				return
			end
			noclip_saved = {}
			hook_descendants(c)
			apply_noclip_character(c)
		end)
	end)
	table.insert(connections, noclip_char_added_conn)

	if lp.Character then
		apply_noclip_character(lp.Character)
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
				pcall(function()
					h:Destroy()
				end)
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
