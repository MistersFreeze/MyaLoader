local function unload_neighbors_piano()
	stop_spy_camera()
	movement_unload()
	visuals_unload()
	stop_render_loop()
	stop_playback()
	release_all_keys()
	events = {}
	tempo_events = {}
	midi_loaded = false
	is_loading = false
	_G.MYA_NEIGHBORS_LOADED = false
	if _G.user_interface then
		pcall(function()
			_G.user_interface:Destroy()
		end)
		_G.user_interface = nil
	end
	if _G.mya_neighbors_notif_ui then
		pcall(function()
			_G.mya_neighbors_notif_ui:Destroy()
		end)
		_G.mya_neighbors_notif_ui = nil
	end
	_G.MYA_NEIGHBORS_PIANO = nil
	_G.MYA_NEIGHBORS_RUN_UI_SYNC = nil
	_G.unload_mya = nil
end

_G.MYA_NEIGHBORS_PIANO = {
	list_midi_files = list_midi_files,
	get_midi_files = function()
		return midi_files
	end,
	load_midi_from_data = load_midi_from_data,
	start_playback_from_loaded = function()
		start_playback(events, tempo_events)
	end,
	pause_playback = pause_playback,
	resume_playback = resume_playback,
	stop_playback = stop_playback,
	seek_ratio = function(ratio)
		seek_to_position(_math.clamp(ratio, 0, 1))
	end,
	get_total_duration = function()
		return total_duration
	end,
	get_current_playback_position = get_current_playback_position,
	is_paused = function()
		return paused
	end,
	is_midi_loaded = function()
		return midi_loaded
	end,
	is_loading = function()
		return is_loading
	end,
	register_sliders = function(played_set, speed_set)
		played_slider_set_value = played_set
		speed_slider_set_value = speed_set
	end,
	set_on_midi_loaded = function(cb)
		on_midi_loaded_callback = cb
	end,
	start_render_loop = start_render_loop,
	stop_render_loop = stop_render_loop,
	unload = unload_neighbors_piano,
	get_deblack_enabled = function()
		return deblack_enabled
	end,
	set_deblack_enabled = function(v)
		deblack_enabled = v
	end,
	get_deblack_level = function()
		return deblack_level
	end,
	set_deblack_level = function(v)
		deblack_level = v
	end,
	get_auto_sustain = function()
		return auto_sustain_enabled
	end,
	set_auto_sustain = function(v)
		auto_sustain_enabled = v
	end,
	get_pedal_uses_space = function()
		return pedal_uses_space
	end,
	set_pedal_uses_space = function(v)
		v = not not v
		if pedal_uses_space ~= v and sustain then
			local old_key = pedal_uses_space and Enum.KeyCode.Space or Enum.KeyCode.LeftAlt
			vim:SendKeyEvent(false, old_key, false, game)
			sustain = false
		end
		pedal_uses_space = v
	end,
	get_key88 = function()
		return key88_enabled
	end,
	set_key88 = function(v)
		key88_enabled = v
	end,
	get_force_note_off = function()
		return no_note_off_enabled
	end,
	set_force_note_off = function(v)
		no_note_off_enabled = v
	end,
	get_human_player = function()
		return random_note_enabled
	end,
	set_human_player = function(v)
		random_note_enabled = v
	end,
	get_playback_speed_percent = function()
		return _math.floor(playback_speed * 100)
	end,
	set_playback_speed_percent = function(p)
		playback_speed = _math.clamp(p / 100, 0.5, 2.0)
	end,
	release_all_keys = release_all_keys,
	get_esp_enabled = function()
		return visuals_esp
	end,
	set_esp_enabled = function(v)
		visuals_esp = not not v
		visuals_refresh_all()
	end,
	get_nametags_enabled = function()
		return visuals_nametags
	end,
	set_nametags_enabled = function(v)
		visuals_nametags = not not v
		visuals_refresh_all()
	end,
	resolve_target_query = resolve_target_query,
	start_spy_camera = start_spy_camera,
	stop_spy_camera = stop_spy_camera,
	reset_camera_to_local = reset_camera_to_local,
	teleport_to_target = teleport_to_target,
	get_fly_enabled = function()
		return move_fly
	end,
	set_fly_enabled = function(v)
		move_fly = not not v
		if move_fly then
			start_fly_internal()
		else
			stop_fly_internal()
		end
	end,
	get_fly_speed = function()
		return move_fly_speed
	end,
	set_fly_speed = function(v)
		move_fly_speed = _math.clamp(tonumber(v) or 50, 5, 200)
	end,
	get_noclip_enabled = function()
		return move_noclip
	end,
	set_noclip_enabled = function(v)
		move_noclip = not not v
		if move_noclip then
			start_noclip_internal()
		else
			stop_noclip_internal()
		end
	end,
	get_anti_ragdoll_enabled = function()
		return anti_ragdoll_enabled
	end,
	set_anti_ragdoll_enabled = function(v)
		v = not not v
		if anti_ragdoll_enabled and not v then
			restore_ragdoll_state_enabled(get_local_humanoid())
		end
		anti_ragdoll_enabled = v
		if v then
			start_anti_ragdoll_internal()
		else
			stop_anti_ragdoll_connections()
		end
	end,
	get_walk_speed = function()
		local h = get_local_humanoid()
		return h and h.WalkSpeed or move_walk
	end,
	set_walk_speed = function(v)
		move_walk = _math.clamp(tonumber(v) or 16, 0, 200)
		refresh_movement_stats()
	end,
	get_jump_power = function()
		local h = get_local_humanoid()
		return h and h.JumpPower or move_jump
	end,
	set_jump_power = function(v)
		move_jump = _math.clamp(tonumber(v) or 50, 0, 200)
		refresh_movement_stats()
	end,
}

_G.unload_mya = unload_neighbors_piano
_G.MYA_NEIGHBORS_RUN_UI_SYNC = function() end

visuals_init()
movement_init()
