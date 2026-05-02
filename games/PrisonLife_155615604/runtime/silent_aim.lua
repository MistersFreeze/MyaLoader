--[[
  Silent aim: __namecall hook + Heartbeat loop (silent aim 2 pattern). LOS/team via Combat (lib/mya_combat_helpers.lua).
]]

local closest_silent_part = nil

local function getdirection(origin, position)
	return (position - origin).Unit
end

local function silent_aim_getclosest()
	local closestpart = nil
	local closestdistance = math.huge
	local fov_px = silent_aim_fov
	local anchor = silent_aim_fov_follow_cursor and UserInputService:GetMouseLocation() or get_fov_screen_anchor(false)

	for _, player in pairs(Players:GetPlayers()) do
		if player ~= lp and player.Character then
			if Combat.same_team(lp, player, silent_aim_team_check_on) then
				continue
			end
			if silent_prisoner_check_on and is_inmate_team(player) then
				continue
			end
			if not esp_target_within_max_range(player) then
				continue
			end
			local targetPart = player.Character:FindFirstChild(silent_aim_part)
			local humanoid = player.Character:FindFirstChildWhichIsA("Humanoid")
			if targetPart and targetPart:IsA("BasePart") and humanoid and humanoid.Health > 0 then
				local screenpos, onscreen = camera:WorldToViewportPoint(targetPart.Position)
				if onscreen then
					local mousepos = anchor
					local distance = (Vector2.new(screenpos.X, screenpos.Y) - mousepos).Magnitude
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
									workspace
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
	return closestpart
end

local function raycast_redirect_ok()
	return typeof(hookmetamethod) == "function"
		and typeof(getnamecallmethod) == "function"
		and typeof(newcclosure) == "function"
end

local silent_aim_hook_installed = false

-- Exact hook shape from silent aim 2.txt (no pcall inside hook, no depth guard, self == workspace).
if raycast_redirect_ok() then
	local ok_hook, _err = pcall(function()
		local oldnamecall
		oldnamecall = hookmetamethod(
			game,
			"__namecall",
			newcclosure(function(...)
				local method, arguments = getnamecallmethod(), { ... }
				local self = arguments[1]
				if self == workspace and not checkcaller() and method == "Raycast" then
					if silent_aim_on then
						if not silent_aim_require_bind or bind_pressed(silent_aim_bind) then
							local hitpart = closest_silent_part
							if hitpart then
								local origin = arguments[2]
								local direction = getdirection(origin, hitpart.Position) * 1000
								arguments[2], arguments[3] = origin, direction
								return oldnamecall(unpack(arguments))
							end
						end
					end
				end
				return oldnamecall(...)
			end)
		)
	end)
	silent_aim_hook_installed = ok_hook
end

-- Exact: runservice.Heartbeat:Connect (silent aim 2.txt)
table.insert(
	connections,
	RunService.Heartbeat:Connect(function()
		if not silent_aim_on then
			closest_silent_part = nil
			return
		end
		if silent_aim_require_bind and not bind_pressed(silent_aim_bind) then
			closest_silent_part = nil
			return
		end
		closest_silent_part = silent_aim_getclosest()
	end)
)

_G.MYA_SILENT_AIM_HOOK_OK = silent_aim_hook_installed
