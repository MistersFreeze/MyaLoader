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
	for _, plr in ipairs(Players:GetPlayers()) do
		pcall(function()
			if _G.remove_distance_draw then
				_G.remove_distance_draw(plr)
			end
		end)
	end
	_G.remove_distance_draw = nil
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
	_G.get_config = nil
	_G.apply_config = nil
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
	get_esp_distance = function()
		return esp_distance_on
	end,
	set_esp_distance = function(v)
		esp_distance_on = not not v
	end,
	get_walk_mod = function()
		return walk_mod_on
	end,
	set_walk_mod = function(v)
		walk_mod_on = not not v
		refresh_movement()
	end,
	get_jump_mod = function()
		return jump_mod_on
	end,
	set_jump_mod = function(v)
		jump_mod_on = not not v
		refresh_movement()
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
			if walk_mod_on then
				refresh_movement()
			end
		end
	end,
	get_jump = function()
		return jump_target
	end,
	set_jump = function(v)
		local n = tonumber(v)
		if n then
			jump_target = math.clamp(n, 0, 500)
			if jump_mod_on then
				refresh_movement()
			end
		end
	end,
	get_silent_require_raycast_params = function()
		return silent_require_raycast_params
	end,
	set_silent_require_raycast_params = function(v)
		silent_require_raycast_params = not not v
	end,
	get_silent_max_ray_distance = function()
		return silent_max_ray_distance
	end,
	set_silent_max_ray_distance = function(v)
		local n = tonumber(v)
		if n then
			silent_max_ray_distance = math.clamp(n, 32, 100000)
		end
	end,
	get_silent_aim_part = function()
		return silent_aim_part
	end,
	set_silent_aim_part = function(v)
		if type(v) == "string" then
			local p = v:gsub("^%s+", ""):gsub("%s+$", "")
			if SILENT_PART_OK[p] then
				silent_aim_part = p
			end
		end
	end,
}

local function enum_to_str(e)
	if typeof(e) ~= "EnumItem" then
		return nil
	end
	return tostring(e):gsub("^Enum%.", "")
end

local function str_to_enum(s)
	if type(s) ~= "string" then
		return nil
	end
	local et, en = s:match("^([^.]+)%.(.+)$")
	if not et or not en then
		return nil
	end
	local ok, r = pcall(function()
		return Enum[et][en]
	end)
	return ok and r or nil
end

local U = _G.MYA_UNIVERSAL

_G.get_config = function()
	return {
		aim_on = aim_on,
		aim_bind = enum_to_str(aim_bind),
		aim_assist_fov = aim_assist_fov,
		aim_speed = aim_speed,
		team_check_on = team_check_on,
		vis_check_on = vis_check_on,
		silent_on = silent_on,
		silent_fov = silent_fov,
		triggerbot_on = triggerbot_on,
		trigger_bind = enum_to_str(trigger_bind),
		trigger_fov = trigger_fov,
		trigger_delay = trigger_delay,
		show_aim_fov_circle = show_aim_fov_circle,
		show_silent_fov_circle = show_silent_fov_circle,
		esp_on = esp_on,
		healthbars_on = healthbars_on,
		esp_distance_on = esp_distance_on,
		walk_mod_on = walk_mod_on,
		jump_mod_on = jump_mod_on,
		fly_on = fly_on,
		fly_speed = fly_speed,
		noclip_on = noclip_on,
		walk_speed = walk_target,
		jump_power = jump_target,
		silent_require_raycast_params = silent_require_raycast_params,
		silent_max_ray_distance = silent_max_ray_distance,
		silent_aim_part = silent_aim_part,
	}
end

_G.apply_config = function(cfg)
	if type(cfg) ~= "table" then
		return
	end
	if cfg.aim_on ~= nil then
		U.set_aim(cfg.aim_on)
	end
	if cfg.aim_bind ~= nil then
		local b = str_to_enum(cfg.aim_bind)
		if b then
			U.set_aim_bind(b)
		end
	end
	if cfg.aim_assist_fov ~= nil then
		U.set_aim_fov(cfg.aim_assist_fov)
	end
	if cfg.aim_speed ~= nil then
		U.set_aim_speed(cfg.aim_speed)
	end
	if cfg.team_check_on ~= nil then
		U.set_team_check(cfg.team_check_on)
	end
	if cfg.vis_check_on ~= nil then
		U.set_vis_check(cfg.vis_check_on)
	end
	if cfg.silent_on ~= nil then
		U.set_silent(cfg.silent_on)
	end
	if cfg.silent_fov ~= nil then
		U.set_silent_fov(cfg.silent_fov)
	end
	if cfg.triggerbot_on ~= nil then
		U.set_triggerbot(cfg.triggerbot_on)
	end
	if cfg.trigger_bind ~= nil then
		local b = str_to_enum(cfg.trigger_bind)
		if b then
			U.set_trigger_bind(b)
		end
	end
	if cfg.trigger_fov ~= nil then
		U.set_trigger_fov(cfg.trigger_fov)
	end
	if cfg.trigger_delay ~= nil then
		U.set_trigger_delay(cfg.trigger_delay)
	end
	if cfg.show_aim_fov_circle ~= nil then
		U.set_show_aim_fov_circle(cfg.show_aim_fov_circle)
	end
	if cfg.show_silent_fov_circle ~= nil then
		U.set_show_silent_fov_circle(cfg.show_silent_fov_circle)
	end
	if cfg.esp_on ~= nil then
		U.set_esp(cfg.esp_on)
	end
	if cfg.healthbars_on ~= nil then
		U.set_healthbars(cfg.healthbars_on)
	end
	if cfg.esp_distance_on ~= nil then
		U.set_esp_distance(cfg.esp_distance_on)
	end
	if cfg.walk_mod_on ~= nil then
		U.set_walk_mod(cfg.walk_mod_on)
	end
	if cfg.jump_mod_on ~= nil then
		U.set_jump_mod(cfg.jump_mod_on)
	end
	if cfg.fly_on ~= nil then
		U.set_fly(cfg.fly_on)
	end
	if cfg.fly_speed ~= nil then
		U.set_fly_speed(cfg.fly_speed)
	end
	if cfg.noclip_on ~= nil then
		U.set_noclip(cfg.noclip_on)
	end
	if cfg.walk_speed ~= nil then
		U.set_walk(cfg.walk_speed)
	end
	if cfg.jump_power ~= nil then
		U.set_jump(cfg.jump_power)
	end
	if cfg.silent_require_raycast_params ~= nil then
		U.set_silent_require_raycast_params(cfg.silent_require_raycast_params)
	end
	if cfg.silent_max_ray_distance ~= nil then
		U.set_silent_max_ray_distance(cfg.silent_max_ray_distance)
	end
	if cfg.silent_aim_part ~= nil then
		U.set_silent_aim_part(cfg.silent_aim_part)
	end
	if typeof(_G.MYA_UNIVERSAL_SYNC_UI) == "function" then
		_G.MYA_UNIVERSAL_SYNC_UI()
	end
end

_G.unload_mya_universal = unload_mya_universal
_G.MYA_UNIVERSAL_LOADED = true
