-- ——— Movement (fly + noclip) ———
local workspace = Services.Workspace
local move_fly = false
local move_fly_speed = 500
local move_noclip = false
local anti_ragdoll_enabled = false
local anti_ragdoll_hb = nil
local anti_ragdoll_char_conn = nil
local _fly_bv = nil
local _fly_conn = nil
local _noclip_step = nil
local _move_char_conn = nil
-- Original collision flags per part; restoring all parts to CanCollide=true broke hitboxes (accessories, etc.).
local noclip_saved_collide = {}
local move_walk = 16
local move_jump = 50
local move_ws_orig = nil
local move_jp_orig = nil

local function get_local_root()
	local c = player.Character
	return c and c:FindFirstChild("HumanoidRootPart")
end

local function get_local_humanoid()
	local c = player.Character
	return c and c:FindFirstChildWhichIsA("Humanoid")
end

local function refresh_movement_stats()
	local hum = get_local_humanoid()
	if not hum then
		return
	end
	if move_ws_orig == nil then
		move_ws_orig = hum.WalkSpeed
	end
	if move_jp_orig == nil then
		move_jp_orig = hum.JumpPower
	end
	hum.WalkSpeed = move_walk
	hum.JumpPower = move_jump
end

local function restore_movement_stats()
	local hum = get_local_humanoid()
	if hum then
		if move_ws_orig ~= nil then
			hum.WalkSpeed = move_ws_orig
		end
		if move_jp_orig ~= nil then
			hum.JumpPower = move_jp_orig
		end
	end
	move_ws_orig = nil
	move_jp_orig = nil
end

local function restore_ragdoll_state_enabled(hum)
	if not hum then
		return
	end
	pcall(function()
		hum:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, true)
	end)
end

local function apply_anti_ragdoll_humanoid(hum)
	if not hum or not anti_ragdoll_enabled then
		return
	end
	pcall(function()
		hum:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, false)
	end)
end

local function stop_anti_ragdoll_connections()
	if anti_ragdoll_hb then
		pcall(function()
			anti_ragdoll_hb:Disconnect()
		end)
		anti_ragdoll_hb = nil
	end
	if anti_ragdoll_char_conn then
		pcall(function()
			anti_ragdoll_char_conn:Disconnect()
		end)
		anti_ragdoll_char_conn = nil
	end
end

local function anti_ragdoll_heartbeat()
	if not anti_ragdoll_enabled or move_fly then
		return
	end
	local hum = get_local_humanoid()
	if not hum then
		return
	end
	local st = hum:GetState()
	if st == Enum.HumanoidStateType.Ragdoll or st == Enum.HumanoidStateType.Physics then
		pcall(function()
			hum:ChangeState(Enum.HumanoidStateType.GettingUp)
		end)
	elseif st == Enum.HumanoidStateType.FallingDown then
		pcall(function()
			hum:ChangeState(Enum.HumanoidStateType.Running)
		end)
	end
end

local function start_anti_ragdoll_internal()
	stop_anti_ragdoll_connections()
	if not anti_ragdoll_enabled then
		return
	end
	apply_anti_ragdoll_humanoid(get_local_humanoid())
	anti_ragdoll_hb = run_service.Heartbeat:Connect(anti_ragdoll_heartbeat)
	anti_ragdoll_char_conn = player.CharacterAdded:Connect(function()
		_task.wait(0.1)
		apply_anti_ragdoll_humanoid(get_local_humanoid())
	end)
end

local function stop_fly_internal()
	if _fly_conn then
		pcall(function()
			_fly_conn:Disconnect()
		end)
		_fly_conn = nil
	end
	if _fly_bv then
		pcall(function()
			_fly_bv:Destroy()
		end)
		_fly_bv = nil
	end
	local hum = get_local_humanoid()
	if hum then
		hum.PlatformStand = false
	end
end

local function start_fly_internal()
	stop_fly_internal()
	local root = get_local_root()
	local hum = get_local_humanoid()
	if not root or not hum then
		return
	end
	hum.PlatformStand = true
	local bv = Instance.new("BodyVelocity")
	bv.MaxForce = Vector3.new(500000, 500000, 500000)
	bv.Velocity = Vector3.zero
	bv.Parent = root
	_fly_bv = bv
	_fly_conn = run_service.RenderStepped:Connect(function()
		if not move_fly then
			return
		end
		root = get_local_root()
		if not root or not _fly_bv or _fly_bv.Parent ~= root then
			return
		end
		local cam = workspace.CurrentCamera
		if not cam then
			return
		end
		local cf = cam.CFrame
		local dir = Vector3.zero
		if uis:IsKeyDown(Enum.KeyCode.W) then
			dir = dir + cf.LookVector
		end
		if uis:IsKeyDown(Enum.KeyCode.S) then
			dir = dir - cf.LookVector
		end
		if uis:IsKeyDown(Enum.KeyCode.D) then
			dir = dir + cf.RightVector
		end
		if uis:IsKeyDown(Enum.KeyCode.A) then
			dir = dir - cf.RightVector
		end
		if uis:IsKeyDown(Enum.KeyCode.Space) then
			dir = dir + Vector3.new(0, 1, 0)
		end
		if uis:IsKeyDown(Enum.KeyCode.LeftControl) or uis:IsKeyDown(Enum.KeyCode.C) then
			dir = dir - Vector3.new(0, 1, 0)
		end
		if dir.Magnitude > 0 then
			_fly_bv.Velocity = dir.Unit * move_fly_speed
		else
			_fly_bv.Velocity = Vector3.zero
		end
	end)
end

local function stop_noclip_internal()
	if _noclip_step then
		pcall(function()
			_noclip_step:Disconnect()
		end)
		_noclip_step = nil
	end
	for part, wasCollide in pairs(noclip_saved_collide) do
		if part.Parent and part:IsA("BasePart") then
			pcall(function()
				part.CanCollide = wasCollide
			end)
		end
	end
	noclip_saved_collide = {}
end

local function start_noclip_internal()
	stop_noclip_internal()
	_noclip_step = run_service.Stepped:Connect(function()
		if not move_noclip then
			return
		end
		local char = player.Character
		if not char then
			return
		end
		for _, p in ipairs(char:GetDescendants()) do
			if p:IsA("BasePart") then
				if noclip_saved_collide[p] == nil then
					noclip_saved_collide[p] = p.CanCollide
				end
				p.CanCollide = false
			end
		end
	end)
end

local function movement_unload()
	move_fly = false
	move_noclip = false
	restore_movement_stats()
	restore_ragdoll_state_enabled(get_local_humanoid())
	stop_anti_ragdoll_connections()
	anti_ragdoll_enabled = false
	stop_fly_internal()
	stop_noclip_internal()
	if _move_char_conn then
		pcall(function()
			_move_char_conn:Disconnect()
		end)
		_move_char_conn = nil
	end
end

local function movement_init()
	if _move_char_conn then
		return
	end
	_move_char_conn = player.CharacterAdded:Connect(function()
		_task.wait(0.2)
		move_ws_orig = nil
		move_jp_orig = nil
		refresh_movement_stats()
		if move_fly then
			start_fly_internal()
		end
	end)
	_task.defer(function()
		local h = get_local_humanoid()
		if h then
			move_walk = h.WalkSpeed
			move_jump = h.JumpPower
		end
	end)
end

