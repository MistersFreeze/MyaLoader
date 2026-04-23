-- ——— Targeting (spy camera / TP) ———
local SPY_RS_NAME = "MyaNeighborsSpyCam"
local spy_input_conn = nil
local spy_target_player = nil
local spy_yaw = 0
local spy_pitch = 0
local spy_dist = 18
local spy_sens = 0.0025
local spy_rmb_orbit_lock = false

local function resolve_target_query(q)
	if typeof(q) ~= "string" then
		return nil
	end
	q = q:lower():gsub("^%s+", ""):gsub("%s+$", "")
	if #q == 0 then
		return nil
	end
	for _, plr in ipairs(players:GetPlayers()) do
		if plr.Name:lower() == q or plr.DisplayName:lower() == q then
			return plr
		end
	end
	for _, plr in ipairs(players:GetPlayers()) do
		if string.find(plr.Name:lower(), q, 1, true) or string.find(plr.DisplayName:lower(), q, 1, true) then
			return plr
		end
	end
	return nil
end

local function stop_spy_camera()
	pcall(function()
		run_service:UnbindFromRenderStep(SPY_RS_NAME)
	end)
	if spy_input_conn then
		pcall(function()
			spy_input_conn:Disconnect()
		end)
		spy_input_conn = nil
	end
	if spy_rmb_orbit_lock then
		spy_rmb_orbit_lock = false
		pcall(function()
			uis.MouseBehavior = Enum.MouseBehavior.Default
		end)
	end
	spy_target_player = nil
	local cam = workspace.CurrentCamera
	if cam then
		cam.CameraType = Enum.CameraType.Custom
		local hum = get_local_humanoid()
		if hum then
			cam.CameraSubject = hum
		end
	end
end

-- Orbit + free look (Scriptable). CameraSubject stays LOCAL humanoid so aim/hitbox stay consistent.
-- Raycast ignores the target's character so their mesh does not block the view.
local function start_spy_camera(target)
	if not target or target == player then
		return false, "Pick another player"
	end
	stop_spy_camera()
	local char = target.Character
	if not char then
		return false, "No character"
	end
	local hrp = char:FindFirstChild("HumanoidRootPart")
	if not hrp then
		return false, "No HRP"
	end
	local cam = workspace.CurrentCamera
	if not cam then
		return false, "No camera"
	end
	local localHum = get_local_humanoid()
	if localHum then
		cam.CameraSubject = localHum
	end
	spy_target_player = target
	spy_dist = 18
	local back = -hrp.CFrame.LookVector
	local dir0 = back.Unit
	spy_yaw = math.atan2(dir0.X, dir0.Z)
	spy_pitch = math.asin(_math.clamp(dir0.Y, -0.999, 0.999))

	cam.CameraType = Enum.CameraType.Scriptable

	-- Wheel only here; orbit uses RMB + LockCenter + GetMouseDelta in the render step (vanilla-style).
	spy_input_conn = uis.InputChanged:Connect(function(input)
		if not spy_target_player then
			return
		end
		if input.UserInputType == Enum.UserInputType.MouseWheel then
			spy_dist = _math.clamp(spy_dist - input.Position.Z * 2.5, 4, 90)
		end
	end)

	run_service:BindToRenderStep(SPY_RS_NAME, Enum.RenderPriority.Camera.Value, function()
		if not spy_target_player or not spy_target_player.Parent then
			stop_spy_camera()
			return
		end
		local ch = spy_target_player.Character
		if not ch then
			stop_spy_camera()
			return
		end
		local h = ch:FindFirstChild("HumanoidRootPart")
		if not h then
			stop_spy_camera()
			return
		end

		local rmb = uis:IsMouseButtonPressed(Enum.UserInputType.MouseButton2)
		if rmb then
			if not spy_rmb_orbit_lock then
				spy_rmb_orbit_lock = true
				uis.MouseBehavior = Enum.MouseBehavior.LockCenter
			end
			local d = uis:GetMouseDelta()
			if d.Magnitude > 0 then
				spy_yaw = spy_yaw - d.X * spy_sens
				spy_pitch = spy_pitch - d.Y * spy_sens
				local pitchMax = math.rad(89)
				spy_pitch = _math.clamp(spy_pitch, -pitchMax, pitchMax)
			end
		elseif spy_rmb_orbit_lock then
			spy_rmb_orbit_lock = false
			uis.MouseBehavior = Enum.MouseBehavior.Default
		end

		local focus = h.Position + Vector3.new(0, 1.5, 0)
		local cp = math.cos(spy_pitch)
		local dir = Vector3.new(cp * math.sin(spy_yaw), math.sin(spy_pitch), cp * math.cos(spy_yaw))
		local wantPos = focus - dir * spy_dist

		local rp = RaycastParams.new()
		rp.FilterType = Enum.RaycastFilterType.Blacklist
		local ignore = { ch }
		if player.Character then
			table.insert(ignore, player.Character)
		end
		rp.FilterDescendantsInstances = ignore
		rp.IgnoreWater = true
		local seg = wantPos - focus
		local segLen = seg.Magnitude
		if segLen > 0.05 then
			local hit = workspace:Raycast(focus, seg, rp)
			if hit then
				local safe = hit.Distance - 0.75
				if safe < 1 then
					safe = 1
				end
				local minOrbit = math.min(spy_dist, 6)
				if safe >= minOrbit then
					wantPos = focus - dir * _math.min(safe, spy_dist)
				end
			end
		end

		cam.CFrame = CFrame.lookAt(wantPos, focus)
	end)
	return true
end

local function reset_camera_to_local()
	stop_spy_camera()
	local cam = workspace.CurrentCamera
	local hum = get_local_humanoid()
	if not cam or not hum then
		return false
	end
	cam.CameraType = Enum.CameraType.Custom
	cam.CameraSubject = hum
	return true
end

local function teleport_to_target(target)
	local me = get_local_root()
	local them = target.Character and target.Character:FindFirstChild("HumanoidRootPart")
	if not me or not them then
		return false, "Missing character"
	end
	me.CFrame = them.CFrame * CFrame.new(0, 0, 4)
	return true
end

