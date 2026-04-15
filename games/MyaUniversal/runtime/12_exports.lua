local function unload_mya_universal()
	_G.MYA_UNIVERSAL_LOADED = false
	silent_ray_bypass = true
	pcall(uninstall_silent_hooks)
	for i = #connections, 1, -1 do
		local c = connections[i]
		connections[i] = nil
		if c and typeof(c) == "RBXScriptConnection" then
			pcall(function()
				c:Disconnect()
			end)
		end
	end
	pcall(esp_clear)
	pcall(stop_fly)
	pcall(stop_noclip)
	pcall(restore_movement)
	pcall(function()
		esp_gui:Destroy()
	end)
	for plr in pairs(health_draw) do
		pcall(remove_health_draw, plr)
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
	pcall(function()
		local ui = _G.mya_universal_ui
		if ui and ui.Parent then
			ui:Destroy()
		end
	end)
	_G.mya_universal_ui = nil
	_G.MYA_UNIVERSAL_SYNC_UI = nil
	_G.unload_mya_universal = nil
	_G.MYA_UNIVERSAL = nil
end

_G.MYA_UNIVERSAL = {
	get_aim = function()
		return aim_on
	end,
	set_aim = function(v)
		aim_on = not not v
	end,
	get_aim_bind = function()
		return aim_bind
	end,
	set_aim_bind = function(v)
		if typeof(v) == "EnumItem" then
			aim_bind = v
		end
	end,
	get_aim_fov = function()
		return aim_assist_fov
	end,
	set_aim_fov = function(v)
		local n = tonumber(v)
		if n then
			aim_assist_fov = math.clamp(n, 40, 400)
		end
	end,
	get_aim_speed = function()
		return aim_speed
	end,
	set_aim_speed = function(v)
		local n = tonumber(v)
		if n then
			aim_speed = math.clamp(n, 0.05, 1)
		end
	end,
	get_team_check = function()
		return team_check_on
	end,
	set_team_check = function(v)
		team_check_on = not not v
	end,
	get_vis_check = function()
		return vis_check_on
	end,
	set_vis_check = function(v)
		vis_check_on = not not v
	end,
	get_silent = function()
		return silent_on
	end,
	set_silent = function(v)
		silent_on = not not v
	end,
	get_silent_fov = function()
		return silent_fov
	end,
	set_silent_fov = function(v)
		local n = tonumber(v)
		if n then
			silent_fov = math.clamp(n, 40, 400)
		end
	end,
	get_triggerbot = function()
		return triggerbot_on
	end,
	set_triggerbot = function(v)
		triggerbot_on = not not v
	end,
	get_trigger_bind = function()
		return trigger_bind
	end,
	set_trigger_bind = function(v)
		if typeof(v) == "EnumItem" then
			trigger_bind = v
		end
	end,
	get_trigger_fov = function()
		return trigger_fov
	end,
	set_trigger_fov = function(v)
		local n = tonumber(v)
		if n then
			trigger_fov = math.clamp(n, 5, 120)
		end
	end,
	get_trigger_delay = function()
		return trigger_delay
	end,
	set_trigger_delay = function(v)
		local n = tonumber(v)
		if n then
			trigger_delay = math.clamp(n, 0.03, 0.5)
		end
	end,
	get_show_aim_fov_circle = function()
		return show_aim_fov_circle
	end,
	set_show_aim_fov_circle = function(v)
		show_aim_fov_circle = not not v
	end,
	get_show_silent_fov_circle = function()
		return show_silent_fov_circle
	end,
	set_show_silent_fov_circle = function(v)
		show_silent_fov_circle = not not v
	end,
	get_esp = function()
		return esp_on
	end,
	set_esp = function(v)
		esp_on = not not v
		esp_refresh()
	end,
	get_healthbars = function()
		return healthbars_on
	end,
	set_healthbars = function(v)
		healthbars_on = not not v
	end,
	get_fly = function()
		return fly_on
	end,
	set_fly = function(v)
		fly_on = not not v
		if fly_on then
			start_fly()
		else
			stop_fly()
		end
	end,
	get_fly_speed = function()
		return fly_speed
	end,
	set_fly_speed = function(v)
		local n = tonumber(v)
		if n then
			fly_speed = math.clamp(n, 5, 200)
		end
	end,
	get_noclip = function()
		return noclip_on
	end,
	set_noclip = function(v)
		noclip_on = not not v
		if noclip_on then
			start_noclip()
		else
			stop_noclip()
		end
	end,
	get_walk = function()
		return walk_target
	end,
	set_walk = function(v)
		local n = tonumber(v)
		if n then
			walk_target = math.clamp(n, 0, 200)
			refresh_movement()
		end
	end,
	get_jump = function()
		return jump_target
	end,
	set_jump = function(v)
		local n = tonumber(v)
		if n then
			jump_target = math.clamp(n, 0, 200)
			refresh_movement()
		end
	end,
}

_G.unload_mya_universal = unload_mya_universal
_G.MYA_UNIVERSAL_LOADED = true
