local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local AUTO_ARREST_RANGE = 22
local SYN_CLICK_INTERVAL = 0.28
local auto_arrest_last_syn_click = 0

--- Updated every Heartbeat; consumed by Workspace:Raycast + GetMouseLocation hooks in silent_aim.lua.
closest_auto_arrest_part = nil

local function team_name_lower(team)
	return team and string.lower(team.Name) or ""
end

local function team_is_police(team)
	if not team then
		return false
	end
	local n = team_name_lower(team)
	if n == "" then
		return false
	end
	if string.find(n, "police", 1, true) then
		return true
	end
	if string.find(n, "guard", 1, true) and not string.find(n, "inmate", 1, true) then
		return true
	end
	if string.find(n, "swat", 1, true) or string.find(n, "sheriff", 1, true) then
		return true
	end
	if string.find(n, "cop", 1, true) or string.find(n, "officer", 1, true) then
		return true
	end
	return false
end

--- Only Criminal team (escaped / orange) — not generic inmates.
local function team_is_criminal(team)
	if not team then
		return false
	end
	local n = team_name_lower(team)
	return string.find(n, "criminal", 1, true) ~= nil
end

local function is_handcuff_tool(tool)
	if not tool or not tool:IsA("Tool") then
		return false
	end
	local n = string.lower(tool.Name)
	if string.find(n, "handcuff", 1, true) then
		return true
	end
	if string.find(n, "cuff", 1, true) and not string.find(n, "uncuff", 1, true) then
		return true
	end
	return false
end

local function find_handcuff_tool()
	local function scan(folder)
		if not folder then
			return nil
		end
		for _, c in ipairs(folder:GetChildren()) do
			if is_handcuff_tool(c) then
				return c
			end
		end
		return nil
	end
	local char = lp.Character
	if char then
		local t = scan(char)
		if t then
			return t
		end
	end
	local bp = lp:FindFirstChild("Backpack")
	local t = scan(bp)
	if t then
		return t
	end
	local sg = lp:FindFirstChild("StarterGear")
	return scan(sg)
end

local function wait_equipped(tool, char, maxWait)
	local t0 = os.clock()
	while tool.Parent ~= char and os.clock() - t0 < maxWait do
		task.wait()
	end
	return tool.Parent == char
end

local function ensure_handcuffs_equipped()
	local char = lp.Character
	if not char then
		return false
	end
	local hum = char:FindFirstChildWhichIsA("Humanoid")
	if not hum then
		return false
	end
	local tool = find_handcuff_tool()
	if not tool then
		return false
	end
	if tool.Parent == char then
		return true
	end
	pcall(function()
		hum:EquipTool(tool)
	end)
	return wait_equipped(tool, char, 0.35)
end

--- Same idea as silent_aim_getclosest: screen FOV + optional LOS + Criminal team + range.
local function find_closest_criminal_part_for_silent_aim()
	if not camera then
		return nil
	end
	local anchor = get_fov_screen_anchor(false)
	local fov_px = silent_aim_fov
	local myChar = lp.Character
	local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")
	if not myRoot then
		return nil
	end

	local closestpart = nil
	local closestdistance = math.huge

	for _, player in pairs(Players:GetPlayers()) do
		if player ~= lp and player.Character and team_is_criminal(player.Team) then
			local targetPart = player.Character:FindFirstChild("HumanoidRootPart")
			local humanoid = player.Character:FindFirstChildWhichIsA("Humanoid")
			if targetPart and humanoid and humanoid.Health > 0 then
				if (targetPart.Position - myRoot.Position).Magnitude <= AUTO_ARREST_RANGE then
					local screenpos, onscreen = camera:WorldToViewportPoint(targetPart.Position)
					if onscreen then
						local distance = (Vector2.new(screenpos.X, screenpos.Y) - anchor).Magnitude
						if distance <= fov_px then
							local los_ok = true
							if silent_aim_vis_check_on then
								local ch = lp.Character
								if not ch then
									los_ok = false
								else
									los_ok = Combat.los_visible_exclude(
										camera.CFrame.Position,
										targetPart,
										ch,
										camera,
										Workspace
									)
								end
							end
							if los_ok and distance < closestdistance then
								closestdistance = distance
								closestpart = targetPart
							end
						end
					end
				end
			end
		end
	end
	return closestpart
end

function auto_arrest_get_raycast_redirect_part()
	if not auto_arrest_on then
		return nil
	end
	return closest_auto_arrest_part
end

--- Spoofed screen position for UserInputService:GetMouseLocation / Camera:ViewportPointToRay (criminal HRP).
function auto_arrest_get_mouse_screen_override()
	if not auto_arrest_on then
		return nil
	end
	local part = closest_auto_arrest_part
	if not part or not camera then
		return nil
	end
	local sp, onScreen = camera:WorldToViewportPoint(part.Position)
	if not onScreen then
		return nil
	end
	return Vector2.new(sp.X, sp.Y)
end

local function auto_arrest_try_synthetic_click(part)
	if not auto_arrest_synthetic_click or not part or not camera then
		return
	end
	if typeof(mousemoveabs) ~= "function" or typeof(mouse1click) ~= "function" then
		return
	end
	local t = tick()
	if t - auto_arrest_last_syn_click < SYN_CLICK_INTERVAL then
		return
	end
	auto_arrest_last_syn_click = t
	local sp, onScreen = camera:WorldToViewportPoint(part.Position)
	if not onScreen then
		return
	end
	pcall(function()
		mousemoveabs(sp.X, sp.Y)
		mouse1click()
	end)
end

local auto_arrest_conn = nil

local function auto_arrest_heartbeat()
	closest_auto_arrest_part = nil
	if not auto_arrest_on or not _G.MYA_UNIVERSAL_LOADED then
		return
	end
	if not team_is_police(lp.Team) then
		return
	end
	local part = find_closest_criminal_part_for_silent_aim()
	if not part then
		return
	end
	if not ensure_handcuffs_equipped() then
		return
	end
	closest_auto_arrest_part = part
	auto_arrest_try_synthetic_click(part)
end

function stop_auto_arrest()
	closest_auto_arrest_part = nil
	if auto_arrest_conn then
		pcall(function()
			auto_arrest_conn:Disconnect()
		end)
		auto_arrest_conn = nil
	end
end

function start_auto_arrest()
	if auto_arrest_conn then
		return
	end
	closest_auto_arrest_part = nil
	auto_arrest_conn = RunService.Heartbeat:Connect(auto_arrest_heartbeat)
	table.insert(connections, auto_arrest_conn)
end
