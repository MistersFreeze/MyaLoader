local function unload_mya_project_delta()
	_G.MYA_PROJECT_DELTA_LOADED = false
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
	pcall(clear_esp_view_angle)
	pcall(stop_fly)
	pcall(stop_noclip)
	pcall(restore_movement)
	pcall(world_esp_unload)
	pcall(restore_remove_rain)
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
		pcall(function()
			if _G.remove_name_draw then
				_G.remove_name_draw(plr)
			end
		end)
	end
	_G.remove_distance_draw = nil
	_G.remove_name_draw = nil
	pcall(function()
		local n = _G.mya_project_delta_notif_ui
		if n and n.Parent then
			n:Destroy()
		end
	end)
	_G.mya_project_delta_notif_ui = nil
	_G.mya_notify = nil
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
		local ui = _G.mya_project_delta_ui
		if ui and ui.Parent then
			ui:Destroy()
		end
	end)
	_G.mya_project_delta_ui = nil
	_G.MYA_PROJECT_DELTA_SYNC_UI = nil
	_G.get_config = nil
	_G.apply_config = nil
	_G.unload_mya_project_delta = nil
	_G.MYA_PROJECT_DELTA = nil
	_G.MYA_SILENT_AIM_HOOK_OK = nil
end

_G.MYA_PROJECT_DELTA = {
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
	get_aim_fov_follow_cursor = function()
		return aim_fov_follow_cursor
	end,
	set_aim_fov_follow_cursor = function(v)
		aim_fov_follow_cursor = not not v
	end,
	get_keep_on_target = function()
		return keep_on_target_on
	end,
	set_keep_on_target = function(v)
		keep_on_target_on = not not v
		if not keep_on_target_on then
			aim_lock_char = nil
		end
	end,
	get_aim_assist_npcs = function()
		return aim_assist_npcs_on
	end,
	set_aim_assist_npcs = function(v)
		aim_assist_npcs_on = not not v
		if typeof(schedule_npc_aim_cache_refresh) == "function" then
			schedule_npc_aim_cache_refresh()
		end
	end,
	get_aim_assist_part = function()
		return aim_assist_part
	end,
	set_aim_assist_part = function(v)
		if type(v) == "string" and Combat.HIT_PART_NAMES[v] then
			aim_assist_part = v
			if typeof(schedule_npc_aim_cache_refresh) == "function" then
				schedule_npc_aim_cache_refresh()
			end
		end
	end,
	get_aim_team_check = function()
		return aim_team_check_on
	end,
	set_aim_team_check = function(v)
		aim_team_check_on = not not v
	end,
	get_esp_team_check = function()
		return esp_team_check_on
	end,
	set_esp_team_check = function(v)
		esp_team_check_on = not not v
		esp_refresh()
	end,
	-- Backward compat: old single "team check" mapped to aim-only getters/setters.
	get_team_check = function()
		return aim_team_check_on
	end,
	set_team_check = function(v)
		aim_team_check_on = not not v
	end,
	get_vis_check = function()
		return vis_check_on
	end,
	set_vis_check = function(v)
		vis_check_on = not not v
	end,
	get_no_recoil = function()
		return no_recoil_on
	end,
	set_no_recoil = function(v)
		no_recoil_on = not not v
	end,
	get_no_spread = function()
		return no_spread_on
	end,
	set_no_spread = function(v)
		no_spread_on = not not v
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
		return 5
	end,
	set_trigger_fov = function(_v)
		trigger_fov = 5
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
	get_silent_aim = function()
		return silent_aim_on
	end,
	set_silent_aim = function(v)
		silent_aim_on = not not v
	end,
	get_silent_aim_bind = function()
		return silent_aim_bind
	end,
	set_silent_aim_bind = function(v)
		if typeof(v) == "EnumItem" then
			silent_aim_bind = v
		end
	end,
	get_silent_aim_fov = function()
		return silent_aim_fov
	end,
	set_silent_aim_fov = function(v)
		local n = tonumber(v)
		if n then
			silent_aim_fov = math.clamp(n, 20, 400)
		end
	end,
	get_silent_aim_fov_follow_cursor = function()
		return silent_aim_fov_follow_cursor
	end,
	set_silent_aim_fov_follow_cursor = function(v)
		silent_aim_fov_follow_cursor = not not v
	end,
	get_silent_aim_require_bind = function()
		return silent_aim_require_bind
	end,
	set_silent_aim_require_bind = function(v)
		silent_aim_require_bind = not not v
	end,
	get_silent_aim_part = function()
		return silent_aim_part
	end,
	set_silent_aim_part = function(v)
		if type(v) == "string" and Combat.HIT_PART_NAMES[v] then
			silent_aim_part = v
		end
	end,
	get_show_silent_aim_fov_circle = function()
		return show_silent_aim_fov_circle
	end,
	set_show_silent_aim_fov_circle = function(v)
		show_silent_aim_fov_circle = not not v
	end,
	get_silent_aim_vis_check = function()
		return silent_aim_vis_check_on
	end,
	set_silent_aim_vis_check = function(v)
		silent_aim_vis_check_on = not not v
	end,
	get_silent_aim_team_check = function()
		return silent_aim_team_check_on
	end,
	set_silent_aim_team_check = function(v)
		silent_aim_team_check_on = not not v
	end,
	get_esp = function()
		return esp_on
	end,
	set_esp = function(v)
		esp_on = not not v
		esp_refresh()
	end,
	get_esp_visibility_colors = function()
		return esp_visibility_colors_on
	end,
	set_esp_visibility_colors = function(v)
		esp_visibility_colors_on = not not v
		esp_refresh()
	end,
	get_esp_view_angle = function()
		return esp_view_angle_on
	end,
	set_esp_view_angle = function(v)
		esp_view_angle_on = not not v
		if not esp_view_angle_on then
			pcall(clear_esp_view_angle)
		end
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
	get_esp_names = function()
		return esp_names_on
	end,
	set_esp_names = function(v)
		esp_names_on = not not v
	end,
	get_npc_esp = function()
		return npc_esp_on
	end,
	set_npc_esp = function(v)
		npc_esp_on = not not v
		invalidate_world_pool()
	end,
	get_crate_esp = function()
		return crate_esp_on
	end,
	set_crate_esp = function(v)
		crate_esp_on = not not v
		invalidate_world_pool()
	end,
	get_crate_esp_max_dist = function()
		return crate_esp_max_dist
	end,
	set_crate_esp_max_dist = function(v)
		local n = tonumber(v)
		if n then
			crate_esp_max_dist = math.clamp(n, 20, 2000)
		end
	end,
	get_world_esp_max_dist = function()
		return world_esp_other_max
	end,
	set_world_esp_max_dist = function(v)
		local n = tonumber(v)
		if n then
			world_esp_other_max = math.clamp(n, 100, 8000)
		end
	end,
	get_corpse_esp = function()
		return corpse_esp_on
	end,
	set_corpse_esp = function(v)
		corpse_esp_on = not not v
		invalidate_world_pool()
	end,
	get_corpse_esp_max_dist = function()
		return corpse_esp_max_dist
	end,
	set_corpse_esp_max_dist = function(v)
		local n = tonumber(v)
		if n then
			corpse_esp_max_dist = math.clamp(n, 50, 8000)
		end
	end,
	get_vehicle_esp = function()
		return vehicle_esp_on
	end,
	set_vehicle_esp = function(v)
		vehicle_esp_on = not not v
		invalidate_world_pool()
	end,
	get_fullbright = function()
		return fullbright_on
	end,
	set_fullbright = function(v)
		fullbright_on = not not v
	end,
	get_remove_rain = function()
		return remove_rain_on
	end,
	set_remove_rain = function(v)
		remove_rain_on = not not v
		if remove_rain_on then
			pcall(sync_remove_rain)
		else
			pcall(restore_remove_rain)
		end
	end,
	get_landmine_esp = function()
		return landmine_esp_on
	end,
	set_landmine_esp = function(v)
		landmine_esp_on = not not v
		invalidate_world_pool()
	end,
	get_extraction_esp = function()
		return extraction_esp_on
	end,
	set_extraction_esp = function(v)
		extraction_esp_on = not not v
		invalidate_world_pool()
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

local U = _G.MYA_PROJECT_DELTA

_G.get_config = function()
	return {
		aim_on = aim_on,
		aim_bind = enum_to_str(aim_bind),
		aim_assist_fov = aim_assist_fov,
		aim_speed = aim_speed,
		aim_fov_follow_cursor = aim_fov_follow_cursor,
		keep_on_target_on = keep_on_target_on,
		aim_assist_npcs_on = aim_assist_npcs_on,
		aim_assist_part = aim_assist_part,
		aim_team_check_on = aim_team_check_on,
		esp_team_check_on = esp_team_check_on,
		vis_check_on = vis_check_on,
		no_recoil_on = no_recoil_on,
		no_spread_on = no_spread_on,
		triggerbot_on = triggerbot_on,
		trigger_bind = enum_to_str(trigger_bind),
		trigger_fov = 5,
		trigger_delay = trigger_delay,
		show_aim_fov_circle = show_aim_fov_circle,
		silent_aim_on = silent_aim_on,
		silent_aim_bind = enum_to_str(silent_aim_bind),
		silent_aim_fov = silent_aim_fov,
		silent_aim_fov_follow_cursor = silent_aim_fov_follow_cursor,
		silent_aim_require_bind = silent_aim_require_bind,
		silent_aim_part = silent_aim_part,
		silent_aim_vis_check_on = silent_aim_vis_check_on,
		silent_aim_team_check_on = silent_aim_team_check_on,
		show_silent_aim_fov_circle = show_silent_aim_fov_circle,
		esp_on = esp_on,
		esp_visibility_colors_on = esp_visibility_colors_on,
		esp_view_angle_on = esp_view_angle_on,
		healthbars_on = healthbars_on,
		esp_distance_on = esp_distance_on,
		esp_names_on = esp_names_on,
		npc_esp_on = npc_esp_on,
		crate_esp_on = crate_esp_on,
		crate_esp_max_dist = crate_esp_max_dist,
		world_esp_other_max = world_esp_other_max,
		corpse_esp_max_dist = corpse_esp_max_dist,
		corpse_esp_on = corpse_esp_on,
		vehicle_esp_on = vehicle_esp_on,
		fullbright_on = fullbright_on,
		remove_rain_on = remove_rain_on,
		landmine_esp_on = landmine_esp_on,
		extraction_esp_on = extraction_esp_on,
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
	if cfg.aim_fov_follow_cursor ~= nil then
		U.set_aim_fov_follow_cursor(cfg.aim_fov_follow_cursor)
	end
	if cfg.keep_on_target_on ~= nil then
		U.set_keep_on_target(cfg.keep_on_target_on)
	end
	if cfg.aim_assist_npcs_on ~= nil then
		U.set_aim_assist_npcs(cfg.aim_assist_npcs_on)
	end
	if cfg.aim_assist_part ~= nil then
		U.set_aim_assist_part(cfg.aim_assist_part)
	end
	if cfg.aim_team_check_on ~= nil then
		U.set_aim_team_check(cfg.aim_team_check_on)
	elseif cfg.team_check_on ~= nil then
		U.set_aim_team_check(cfg.team_check_on)
	end
	if cfg.esp_team_check_on ~= nil then
		U.set_esp_team_check(cfg.esp_team_check_on)
	elseif cfg.team_check_on ~= nil then
		U.set_esp_team_check(cfg.team_check_on)
	end
	if cfg.vis_check_on ~= nil then
		U.set_vis_check(cfg.vis_check_on)
	end
	if cfg.no_recoil_on ~= nil then
		U.set_no_recoil(cfg.no_recoil_on)
	end
	if cfg.no_spread_on ~= nil then
		U.set_no_spread(cfg.no_spread_on)
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
	if cfg.trigger_delay ~= nil then
		U.set_trigger_delay(cfg.trigger_delay)
	end
	if cfg.show_aim_fov_circle ~= nil then
		U.set_show_aim_fov_circle(cfg.show_aim_fov_circle)
	end
	if cfg.silent_aim_on ~= nil then
		U.set_silent_aim(cfg.silent_aim_on)
	end
	if cfg.silent_aim_bind ~= nil then
		local b = str_to_enum(cfg.silent_aim_bind)
		if b then
			U.set_silent_aim_bind(b)
		end
	end
	if cfg.silent_aim_fov ~= nil then
		U.set_silent_aim_fov(cfg.silent_aim_fov)
	end
	if cfg.silent_aim_fov_follow_cursor ~= nil then
		U.set_silent_aim_fov_follow_cursor(cfg.silent_aim_fov_follow_cursor)
	end
	if cfg.silent_aim_require_bind ~= nil then
		U.set_silent_aim_require_bind(cfg.silent_aim_require_bind)
	end
	if cfg.silent_aim_part ~= nil then
		U.set_silent_aim_part(cfg.silent_aim_part)
	end
	if cfg.silent_aim_vis_check_on ~= nil then
		U.set_silent_aim_vis_check(cfg.silent_aim_vis_check_on)
	end
	if cfg.silent_aim_team_check_on ~= nil then
		U.set_silent_aim_team_check(cfg.silent_aim_team_check_on)
	end
	if cfg.show_silent_aim_fov_circle ~= nil then
		U.set_show_silent_aim_fov_circle(cfg.show_silent_aim_fov_circle)
	end
	if cfg.esp_on ~= nil then
		U.set_esp(cfg.esp_on)
	end
	if cfg.esp_visibility_colors_on ~= nil then
		U.set_esp_visibility_colors(cfg.esp_visibility_colors_on)
	end
	if cfg.esp_view_angle_on ~= nil then
		U.set_esp_view_angle(cfg.esp_view_angle_on)
	end
	if cfg.healthbars_on ~= nil then
		U.set_healthbars(cfg.healthbars_on)
	end
	if cfg.esp_distance_on ~= nil then
		U.set_esp_distance(cfg.esp_distance_on)
	end
	if cfg.esp_names_on ~= nil then
		U.set_esp_names(cfg.esp_names_on)
	end
	if cfg.npc_esp_on ~= nil then
		U.set_npc_esp(cfg.npc_esp_on)
	end
	if cfg.crate_esp_on ~= nil then
		U.set_crate_esp(cfg.crate_esp_on)
	end
	if cfg.crate_esp_max_dist ~= nil then
		U.set_crate_esp_max_dist(cfg.crate_esp_max_dist)
	end
	if cfg.world_esp_other_max ~= nil then
		U.set_world_esp_max_dist(cfg.world_esp_other_max)
	end
	if cfg.corpse_esp_on ~= nil then
		U.set_corpse_esp(cfg.corpse_esp_on)
	end
	if cfg.corpse_esp_max_dist ~= nil then
		U.set_corpse_esp_max_dist(cfg.corpse_esp_max_dist)
	end
	if cfg.vehicle_esp_on ~= nil then
		U.set_vehicle_esp(cfg.vehicle_esp_on)
	end
	if cfg.fullbright_on ~= nil then
		U.set_fullbright(cfg.fullbright_on)
	end
	if cfg.remove_rain_on ~= nil then
		U.set_remove_rain(cfg.remove_rain_on)
	end
	if cfg.landmine_esp_on ~= nil then
		U.set_landmine_esp(cfg.landmine_esp_on)
	end
	if cfg.extraction_esp_on ~= nil then
		U.set_extraction_esp(cfg.extraction_esp_on)
	end
	if typeof(_G.MYA_PROJECT_DELTA_SYNC_UI) == "function" then
		_G.MYA_PROJECT_DELTA_SYNC_UI()
	end
end

_G.unload_mya_project_delta = unload_mya_project_delta
_G.MYA_PROJECT_DELTA_LOADED = true
