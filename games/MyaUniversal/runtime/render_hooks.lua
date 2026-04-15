local function render_frame()
	if not _G.MYA_UNIVERSAL_LOADED then
		return
	end
	if silent_on then
		cached_silent_aim_world = select(2, get_silent_aim_world(silent_fov))
	else
		cached_silent_aim_world = nil
	end
	update_fov_circles()
	update_health_bars()
	update_esp_distance()
	aim_step()
	triggerbot_step()
end

render_conn = RunService.RenderStepped:Connect(render_frame)
table.insert(connections, render_conn)

hook_players()
table.insert(connections, lp.CharacterAdded:Connect(function()
	task.wait(0.15)
	ws_orig, jp_orig, jh_orig = nil, nil, nil
	refresh_movement()
	if fly_on then
		start_fly()
	end
end))
task.defer(function()
	local h = get_hum()
	if h then
		walk_target = h.WalkSpeed
		jump_target = h.JumpPower
		refresh_movement()
	end
end)
