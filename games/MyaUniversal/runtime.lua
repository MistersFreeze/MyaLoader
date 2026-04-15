--[[ Mya Universal — ESP, aim assist (Op1-style), silent aim, health bars, fly, noclip ]]
if _G.MYA_UNIVERSAL_LOADED then
	return
end
_G.MYA_UNIVERSAL_LOADED = true

local cloneref = (cloneref or function(x)
	return x
end)
local Players = cloneref(game:GetService("Players"))
local RunService = cloneref(game:GetService("RunService"))
local UserInputService = cloneref(game:GetService("UserInputService"))
local Workspace = cloneref(game:GetService("Workspace"))

local lp = Players.LocalPlayer
local camera = Workspace.CurrentCamera
Workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
	camera = Workspace.CurrentCamera
end)

local esp_on = false
local aim_on = false
local aim_assist_fov = 140
local aim_speed = 0.35
local aim_remainder_x, aim_remainder_y = 0, 0

local silent_on = false
local silent_fov = 140

local healthbars_on = false
local show_aim_fov_circle = false
local show_silent_fov_circle = false

local fly_on = false
local fly_speed = 50
local noclip_on = false
local noclip_saved = {}

local walk_target = 16
local jump_target = 50
local ws_orig, jp_orig = nil, nil

local gui_parent = gethui and gethui() or lp:WaitForChild("PlayerGui")
local esp_gui = Instance.new("ScreenGui")
esp_gui.Name = "MyaUniversalESP"
esp_gui.ResetOnSpawn = false
esp_gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
esp_gui.Parent = gui_parent

local highlights = {}
local connections = {}
local fly_bv, fly_conn = nil, nil
local noclip_conn = nil
local render_conn = nil

local drawing_ok = typeof(Drawing) == "table" and typeof(Drawing.new) == "function"
local health_draw = {}
local fov_circle_aim, fov_circle_silent = nil, nil
local old_workspace_raycast = nil

local color_fov_aim = Color3.fromRGB(230, 120, 175)
local color_fov_silent = Color3.fromRGB(120, 200, 255)

if drawing_ok then
	fov_circle_aim = Drawing.new("Circle")
	fov_circle_aim.Visible = false
	fov_circle_aim.Filled = false
	fov_circle_aim.Thickness = 1
	fov_circle_aim.Color = color_fov_aim
	fov_circle_aim.NumSides = 64
	fov_circle_aim.Transparency = 0.5

	fov_circle_silent = Drawing.new("Circle")
	fov_circle_silent.Visible = false
	fov_circle_silent.Filled = false
	fov_circle_silent.Thickness = 1
	fov_circle_silent.Color = color_fov_silent
	fov_circle_silent.NumSides = 64
	fov_circle_silent.Transparency = 0.5
end

local function get_hum()
	local c = lp.Character
	return c and c:FindFirstChildWhichIsA("Humanoid")
end

local function get_root()
	local c = lp.Character
	return c and c:FindFirstChild("HumanoidRootPart")
end

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
	end
	h.WalkSpeed = walk_target
	h.JumpPower = jump_target
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
	end
	ws_orig, jp_orig = nil, nil
end

local function esp_clear()
	for _, h in pairs(highlights) do
		pcall(function()
			h:Destroy()
		end)
	end
	highlights = {}
end

local function esp_refresh()
	esp_clear()
	if not esp_on then
		return
	end
	for _, plr in ipairs(Players:GetPlayers()) do
		if plr ~= lp and plr.Character then
			local hl = Instance.new("Highlight")
			hl.Name = "MyaUniESP"
			hl.Adornee = plr.Character
			hl.FillColor = Color3.fromRGB(255, 90, 140)
			hl.OutlineColor = Color3.fromRGB(255, 255, 255)
			hl.FillTransparency = 0.55
			hl.OutlineTransparency = 0.3
			hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
			hl.Parent = esp_gui
			highlights[plr] = hl
		end
	end
end

local function remove_health_draw(plr)
	local d = health_draw[plr]
	if not d then
		return
	end
	pcall(function()
		d.health_bg:Remove()
	end)
	pcall(function()
		d.health_fill:Remove()
	end)
	health_draw[plr] = nil
end

local function ensure_health_draw(plr)
	if not drawing_ok or health_draw[plr] then
		return
	end
	local bg = Drawing.new("Line")
	bg.Visible = false
	bg.Color = Color3.fromRGB(40, 40, 40)
	bg.Thickness = 3
	bg.Transparency = 0.5
	local fill = Drawing.new("Line")
	fill.Visible = false
	fill.Color = Color3.fromRGB(0, 255, 0)
	fill.Thickness = 2
	fill.Transparency = 1
	health_draw[plr] = { health_bg = bg, health_fill = fill }
end

local function get_health(character)
	local hum = character:FindFirstChildWhichIsA("Humanoid")
	if not hum then
		return nil, nil
	end
	return hum.Health, hum.MaxHealth
end

local function hide_health(plr)
	local d = health_draw[plr]
	if d then
		d.health_bg.Visible = false
		d.health_fill.Visible = false
	end
end

local function update_health_bars()
	if not drawing_ok or not healthbars_on or not camera then
		for plr in pairs(health_draw) do
			hide_health(plr)
		end
		return
	end

	for _, plr in ipairs(Players:GetPlayers()) do
		if plr ~= lp then
			local char = plr.Character
			if not char then
				hide_health(plr)
			else
				local head = char:FindFirstChild("Head")
				local hrp = char:FindFirstChild("HumanoidRootPart")
				if not head or not hrp or not head:IsA("BasePart") or not hrp:IsA("BasePart") then
					hide_health(plr)
				else
					ensure_health_draw(plr)
					local data = health_draw[plr]
					local hp, max_hp = get_health(char)
					if not hp or not max_hp or max_hp <= 0 then
						hide_health(plr)
					else
						local top_vp = camera:WorldToViewportPoint(head.Position + Vector3.new(0, 0.35, 0))
						local bot_vp = camera:WorldToViewportPoint(hrp.Position - Vector3.new(0, 2.5, 0))
						local tz = camera:WorldToViewportPoint(hrp.Position).Z
						if tz > 0 and top_vp.Z > 0 and bot_vp.Z > 0 then
							local by_top = math.min(top_vp.Y, bot_vp.Y)
							local by_bot = math.max(top_vp.Y, bot_vp.Y)
							local bh = by_bot - by_top
							if bh > 1 then
								local vp_left = math.min(top_vp.X, bot_vp.X) - 4
								local bx = vp_left - 4
								local pct = math.clamp(hp / max_hp, 0, 1)
								data.health_bg.From = Vector2.new(bx, by_top)
								data.health_bg.To = Vector2.new(bx, by_bot)
								data.health_bg.Visible = true
								data.health_fill.From = Vector2.new(bx, by_bot - bh * pct)
								data.health_fill.To = Vector2.new(bx, by_bot)
								data.health_fill.Color =
									Color3.fromRGB(math.floor(255 * (1 - pct)), math.floor(255 * pct), 0)
								data.health_fill.Visible = true
							else
								hide_health(plr)
							end
						else
							hide_health(plr)
						end
					end
				end
			end
		end
	end
end

local function update_fov_circles()
	if not drawing_ok or not camera then
		if fov_circle_aim then
			fov_circle_aim.Visible = false
		end
		if fov_circle_silent then
			fov_circle_silent.Visible = false
		end
		return
	end
	local vp = camera.ViewportSize
	local c = Vector2.new(vp.X / 2, vp.Y / 2)
	if show_aim_fov_circle and fov_circle_aim then
		fov_circle_aim.Position = c
		fov_circle_aim.Radius = aim_assist_fov
		fov_circle_aim.Visible = true
	elseif fov_circle_aim then
		fov_circle_aim.Visible = false
	end
	if show_silent_fov_circle and fov_circle_silent then
		fov_circle_silent.Position = c
		fov_circle_silent.Radius = silent_fov
		fov_circle_silent.Visible = true
	elseif fov_circle_silent then
		fov_circle_silent.Visible = false
	end
end

-- Closest enemy head on screen to crosshair within fov_px (pixels).
local function get_best_head_screen(fov_px)
	if not camera then
		return nil
	end
	local vp = camera.ViewportSize
	local center = Vector2.new(vp.X / 2, vp.Y / 2)
	local best_dist = math.huge
	local best_screen = nil

	for _, plr in ipairs(Players:GetPlayers()) do
		if plr ~= lp and plr.Character then
			local head = plr.Character:FindFirstChild("Head")
			if head and head:IsA("BasePart") then
				local pos, on_screen = camera:WorldToViewportPoint(head.Position)
				if on_screen and pos.Z > 0 then
					local sp = Vector2.new(pos.X, pos.Y)
					local d = (sp - center).Magnitude
					if d <= fov_px and d < best_dist then
						best_dist = d
						best_screen = sp
					end
				end
			end
		end
	end
	return best_screen
end

local function get_best_head_world(fov_px)
	if not camera then
		return nil
	end
	local vp = camera.ViewportSize
	local center = Vector2.new(vp.X / 2, vp.Y / 2)
	local best_dist = math.huge
	local best_pos = nil

	for _, plr in ipairs(Players:GetPlayers()) do
		if plr ~= lp and plr.Character then
			local head = plr.Character:FindFirstChild("Head")
			if head and head:IsA("BasePart") then
				local pos, on_screen = camera:WorldToViewportPoint(head.Position)
				if on_screen and pos.Z > 0 then
					local sp = Vector2.new(pos.X, pos.Y)
					local d = (sp - center).Magnitude
					if d <= fov_px and d < best_dist then
						best_dist = d
						best_pos = head.Position
					end
				end
			end
		end
	end
	return best_pos
end

local function aim_step()
	if not aim_on or not camera then
		return
	end
	if not UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) then
		aim_remainder_x, aim_remainder_y = 0, 0
		return
	end

	local best_pos = get_best_head_screen(aim_assist_fov)
	if not best_pos then
		aim_remainder_x, aim_remainder_y = 0, 0
		return
	end

	local vp = camera.ViewportSize
	local center = Vector2.new(vp.X / 2, vp.Y / 2)
	local dx = best_pos.X - center.X
	local dy = best_pos.Y - center.Y

	local actual_speed = math.pow(aim_speed, 3)
	if typeof(mousemoverel) ~= "function" then
		return
	end

	if aim_speed >= 1.0 then
		mousemoverel(dx, dy)
		aim_remainder_x, aim_remainder_y = 0, 0
	else
		aim_remainder_x = aim_remainder_x + (dx * actual_speed)
		aim_remainder_y = aim_remainder_y + (dy * actual_speed)
		local move_x = math.round(aim_remainder_x)
		local move_y = math.round(aim_remainder_y)
		if move_x ~= 0 or move_y ~= 0 then
			mousemoverel(move_x, move_y)
			aim_remainder_x = aim_remainder_x - move_x
			aim_remainder_y = aim_remainder_y - move_y
		end
	end
end

local function should_redirect_ray(origin, direction)
	if not camera or not silent_on or not _G.MYA_UNIVERSAL_LOADED then
		return false
	end
	local mag = direction.Magnitude
	if mag < 4 or mag > 5000 then
		return false
	end
	local camPos = camera.CFrame.Position
	if (origin - camPos).Magnitude > 35 then
		return false
	end
	local look = camera.CFrame.LookVector
	local dunit = direction.Unit
	if dunit:Dot(look) < 0.75 then
		return false
	end
	return true
end

local function install_raycast_hook()
	if old_workspace_raycast ~= nil or typeof(hookfunction) ~= "function" then
		return
	end
	local ray = Workspace.Raycast
	if typeof(ray) ~= "function" then
		return
	end

	local function hooked(self, origin, direction, params)
		if
			should_redirect_ray(origin, direction)
			and typeof(origin) == "Vector3"
			and typeof(direction) == "Vector3"
		then
			local headPos = get_best_head_world(silent_fov)
			if headPos then
				local mag = direction.Magnitude
				direction = (headPos - origin).Unit * mag
			end
		end
		return old_workspace_raycast(self, origin, direction, params)
	end

	local replacement = typeof(newcclosure) == "function" and newcclosure(hooked) or hooked
	local ok, res = pcall(hookfunction, ray, replacement)
	if ok and res then
		old_workspace_raycast = res
	else
		old_workspace_raycast = nil
	end
end

local function uninstall_raycast_hook()
	if old_workspace_raycast ~= nil and typeof(hookfunction) == "function" and Workspace.Raycast then
		pcall(hookfunction, Workspace.Raycast, old_workspace_raycast)
	end
	old_workspace_raycast = nil
end

install_raycast_hook()

local function render_frame()
	if not _G.MYA_UNIVERSAL_LOADED then
		return
	end
	update_fov_circles()
	update_health_bars()
	aim_step()
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
		noclip_conn:Disconnect()
		noclip_conn = nil
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

local function start_noclip()
	stop_noclip()
	noclip_conn = RunService.Stepped:Connect(function()
		if not noclip_on then
			return
		end
		local c = lp.Character
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
	end)
	table.insert(connections, noclip_conn)
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
		end)
	)
end

render_conn = RunService.RenderStepped:Connect(render_frame)
table.insert(connections, render_conn)

hook_players()
lp.CharacterAdded:Connect(function()
	task.wait(0.15)
	ws_orig, jp_orig = nil, nil
	refresh_movement()
	if fly_on then
		start_fly()
	end
end)
task.defer(function()
	local h = get_hum()
	if h then
		walk_target = h.WalkSpeed
		jump_target = h.JumpPower
		refresh_movement()
	end
end)

_G.MYA_UNIVERSAL = {
	set_esp = function(v)
		esp_on = not not v
		esp_refresh()
	end,
	get_esp = function()
		return esp_on
	end,
	set_aim = function(v)
		aim_on = not not v
	end,
	get_aim = function()
		return aim_on
	end,
	set_aim_fov = function(v)
		aim_assist_fov = math.clamp(tonumber(v) or 140, 40, 400)
	end,
	get_aim_fov = function()
		return aim_assist_fov
	end,
	set_aim_speed = function(v)
		aim_speed = math.clamp(tonumber(v) or 0.35, 0.05, 1)
	end,
	get_aim_speed = function()
		return aim_speed
	end,
	set_silent = function(v)
		silent_on = not not v
	end,
	get_silent = function()
		return silent_on
	end,
	set_silent_fov = function(v)
		silent_fov = math.clamp(tonumber(v) or 140, 40, 400)
	end,
	get_silent_fov = function()
		return silent_fov
	end,
	set_healthbars = function(v)
		healthbars_on = not not v
	end,
	get_healthbars = function()
		return healthbars_on
	end,
	set_show_aim_fov_circle = function(v)
		show_aim_fov_circle = not not v
	end,
	get_show_aim_fov_circle = function()
		return show_aim_fov_circle
	end,
	set_show_silent_fov_circle = function(v)
		show_silent_fov_circle = not not v
	end,
	get_show_silent_fov_circle = function()
		return show_silent_fov_circle
	end,
	set_fly = function(v)
		fly_on = not not v
		if fly_on then
			start_fly()
		else
			stop_fly()
		end
	end,
	get_fly = function()
		return fly_on
	end,
	set_fly_speed = function(v)
		fly_speed = math.clamp(tonumber(v) or 50, 5, 200)
	end,
	get_fly_speed = function()
		return fly_speed
	end,
	set_noclip = function(v)
		noclip_on = not not v
		if noclip_on then
			start_noclip()
		else
			stop_noclip()
		end
	end,
	get_noclip = function()
		return noclip_on
	end,
	set_walk = function(v)
		walk_target = math.clamp(tonumber(v) or 16, 0, 200)
		refresh_movement()
	end,
	get_walk = function()
		return get_hum() and get_hum().WalkSpeed or walk_target
	end,
	set_jump = function(v)
		jump_target = math.clamp(tonumber(v) or 50, 0, 200)
		refresh_movement()
	end,
	get_jump = function()
		return get_hum() and get_hum().JumpPower or jump_target
	end,
}

function _G.unload_mya_universal()
	_G.MYA_UNIVERSAL_LOADED = false
	esp_on = false
	aim_on = false
	silent_on = false
	healthbars_on = false
	show_aim_fov_circle = false
	show_silent_fov_circle = false
	fly_on = false
	noclip_on = false
	aim_remainder_x, aim_remainder_y = 0, 0

	esp_clear()
	for plr in pairs(health_draw) do
		remove_health_draw(plr)
	end
	if fov_circle_aim then
		pcall(function()
			fov_circle_aim:Remove()
		end)
		fov_circle_aim = nil
	end
	if fov_circle_silent then
		pcall(function()
			fov_circle_silent:Remove()
		end)
		fov_circle_silent = nil
	end

	uninstall_raycast_hook()
	stop_fly()
	stop_noclip()
	restore_movement()
	for _, c in ipairs(connections) do
		pcall(function()
			c:Disconnect()
		end)
	end
	connections = {}
	if esp_gui then
		pcall(function()
			esp_gui:Destroy()
		end)
	end
	if _G.mya_universal_ui then
		pcall(function()
			_G.mya_universal_ui:Destroy()
		end)
		_G.mya_universal_ui = nil
	end
	_G.MYA_UNIVERSAL = nil
	_G.MYA_UNIVERSAL_SYNC_UI = nil
	_G.unload_mya_universal = nil
end
