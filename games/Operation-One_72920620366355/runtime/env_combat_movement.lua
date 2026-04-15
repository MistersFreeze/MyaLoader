

-- -------------------- Astro-style runtime setup (mirrors shared_runtime:applyToEnv) --------------------
do
    local env = (type(getgenv) == "function" and getgenv()) or _G
    env.dbg = env.dbg or (type(debug) == "table" and debug) or { info = function() return nil end }
    env.sstack = env.sstack or (type(setstack) == "function" and setstack) or (env.dbg and env.dbg.setstack) or function() end
    env.gstack = env.gstack or (type(getstack) == "function" and getstack) or (env.dbg and env.dbg.getstack) or function() return 0 end
end

warn("[Mya] Runtime: dbg=" .. type(dbg) .. " dbg.info=" .. type(dbg and dbg.info) .. " sstack=" .. type(sstack) .. " gstack=" .. type(gstack) .. " hookfn=" .. type(hookfunction) .. " clonefn=" .. type(clonefunction) .. " newcc=" .. type(newcclosure))

-- -------------------- Visibility check --------------------
local vis_params = RaycastParams.new()
vis_params.FilterType = Enum.RaycastFilterType.Exclude
vis_params.RespectCanCollide = true

local function check_visibility(cam_pos, target_pos, target_char)
    local dir    = target_pos - cam_pos
    local ignore = { camera }
    if local_player.Character then table.insert(ignore, local_player.Character) end
    if viewmodels              then table.insert(ignore, viewmodels)             end
    if target_char             then table.insert(ignore, target_char)            end
    vis_params.FilterDescendantsInstances = ignore
    for _ = 1, 8 do
        local hit = workspace:Raycast(cam_pos, dir, vis_params)
        if not hit then return true end
        local p = hit.Instance
        if p.Transparency > 0.2 or not p.CanCollide or p.Name == "HumanoidRootPart" then
            table.insert(ignore, p)
            vis_params.FilterDescendantsInstances = ignore
        else
            return false
        end
    end
    return false
end

-- ==================== MOVEMENT SYSTEMS ====================

local _fly_bv       = nil
local _fly_conn     = nil
local _jb_cooldown  = false
local _jb_conn      = nil

local function get_root()
    local char = local_player.Character
    return char and char:FindFirstChild("HumanoidRootPart")
end

local function get_humanoid()
    local char = local_player.Character
    return char and char:FindFirstChildWhichIsA("Humanoid")
end

-- ---- Fly ----
local function start_fly()
    local root = get_root()
    if not root then return end
    local hum = get_humanoid()
    if hum then hum.PlatformStand = true end

    if _fly_bv then pcall(function() _fly_bv:Destroy() end) end
    local bv = Instance.new("BodyVelocity")
    bv.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
    bv.Velocity = Vector3.zero
    bv.Parent   = root
    _fly_bv = bv

    if _fly_conn then _fly_conn:Disconnect() end
    _fly_conn = runservice.RenderStepped:Connect(function()
        if not fly_enabled or unloaded then return end
        local r = get_root()
        if not r or not _fly_bv or not _fly_bv.Parent then return end

        local cam = camera.CFrame
        local dir = Vector3.zero
        if uis:IsKeyDown(Enum.KeyCode.W) then dir = dir + cam.LookVector end
        if uis:IsKeyDown(Enum.KeyCode.S) then dir = dir - cam.LookVector end
        if uis:IsKeyDown(Enum.KeyCode.D) then dir = dir + cam.RightVector end
        if uis:IsKeyDown(Enum.KeyCode.A) then dir = dir - cam.RightVector end
        if uis:IsKeyDown(Enum.KeyCode.Space)        then dir = dir + Vector3.new(0,1,0) end
        if uis:IsKeyDown(Enum.KeyCode.LeftControl)  then dir = dir - Vector3.new(0,1,0) end

        if dir.Magnitude > 0 then
            _fly_bv.Velocity = dir.Unit * fly_speed
        else
            _fly_bv.Velocity = Vector3.zero
        end
    end)
    connections[#connections+1] = _fly_conn
end

local function stop_fly()
    if _fly_conn then _fly_conn:Disconnect(); _fly_conn = nil end
    if _fly_bv then pcall(function() _fly_bv:Destroy() end); _fly_bv = nil end
    local hum = get_humanoid()
    if hum then hum.PlatformStand = false end
end

local old_toggle_fly = _G.toggle_fly
_G.toggle_fly = function()
    fly_enabled = not fly_enabled
    if fly_enabled then start_fly() else stop_fly() end
    if _G.set_fly then _G.set_fly(fly_enabled) end
end

-- ---- Jump Boost ----
if _jb_conn then _jb_conn:Disconnect() end
_jb_conn = uis.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    if input.KeyCode ~= Enum.KeyCode.Space then return end
    if not jump_boost or unloaded or _jb_cooldown then return end

    local root = get_root()
    local hum  = get_humanoid()
    if not root or not hum then return end
    if fly_enabled then return end

    local floor = hum.FloorMaterial
    if floor == Enum.Material.Air then return end

    _jb_cooldown = true
    root.AssemblyLinearVelocity = Vector3.new(
        root.AssemblyLinearVelocity.X,
        jump_power,
        root.AssemblyLinearVelocity.Z
    )
    task.delay(0.5, function() _jb_cooldown = false end)
end)
connections[#connections+1] = _jb_conn

-- UI loads from gui.lua (Mya hub init); sync runs after GUI builds _G.set_* hooks.
_G.MYA_OP1_RUN_UI_SYNC = function()
	task.defer(function()
		if _G.set_boxes then _G.set_boxes(boxes) end
		if _G.set_skeletons then _G.set_skeletons(skeletons) end
		if _G.set_tracers then _G.set_tracers(tracers) end
		if _G.set_healthbars then _G.set_healthbars(healthbars) end
		if _G.set_names then _G.set_names(names) end
		if _G.set_gadgets then _G.set_gadgets(gadgets) end
		if _G.set_team_check then _G.set_team_check(team_check) end
		if _G.set_fullbright then _G.set_fullbright(fullbright) end
		if _G.set_aim_assist then _G.set_aim_assist(aim_assist) end
		if _G.set_show_fov then _G.set_show_fov(show_fov_circle) end
		if _G.set_aim_fov then _G.set_aim_fov(aim_fov) end
		if _G.set_aim_speed then _G.set_aim_speed(aim_speed) end
		if _G.set_vis_check then _G.set_vis_check(vis_check) end
		if _G.set_chams then _G.set_chams(chams) end
		if _G.set_fly then _G.set_fly(fly_enabled) end
		if _G.set_jump_boost then _G.set_jump_boost(jump_boost) end
		if _G.set_fly_speed then _G.set_fly_speed(fly_speed) end
		if _G.set_jump_power then _G.set_jump_power(jump_power) end
	end)
end
