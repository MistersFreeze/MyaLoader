--[[
  Mya · Neighbors — MIDI piano engine (logic from piano.txt / OnionPlayer).
  GUI lives in gui.lua. Sends keys via VirtualInputManager (Roblox piano / similar).
]]
assert(isfolder and makefolder, "Unable to create folder")
local _xpcall, _pcall, _task, _math = xpcall, pcall, task, math
if not isfolder("MIDIow") then
	makefolder("MIDIow")
end

if _G.MYA_NEIGHBORS_LOADED then
	return
end
_G.MYA_NEIGHBORS_LOADED = true

local function missing(t, f, fallback)
    if type(f) == t then return f end
    return fallback
end

local cloneref = missing("function", cloneref, function(...) return ... end)
local Services = setmetatable({}, {
    __index = function(self, name)
        self[name] = cloneref(game:GetService(name))
        return self[name]
    end
})

local oldgame = game
local game = workspace.Parent
local run_service = Services.RunService
local vim = Services.VirtualInputManager
local uis = Services.UserInputService
local players = Services.Players
local player = players.LocalPlayer

local ProtectGui = protectgui or (syn and syn.protect_gui) or function() end
local GUIParent = gethui and gethui() or player.PlayerGui

local key_map = {
    [21] = {keycode = Enum.KeyCode.One, ctrl = true},
    [22] = {keycode = Enum.KeyCode.Two, ctrl = true},
    [23] = {keycode = Enum.KeyCode.Three, ctrl = true},
    [24] = {keycode = Enum.KeyCode.Four, ctrl = true},
    [25] = {keycode = Enum.KeyCode.Five, ctrl = true},
    [26] = {keycode = Enum.KeyCode.Six, ctrl = true},
    [27] = {keycode = Enum.KeyCode.Seven, ctrl = true},
    [28] = {keycode = Enum.KeyCode.Eight, ctrl = true},
    [29] = {keycode = Enum.KeyCode.Nine, ctrl = true},
    [30] = {keycode = Enum.KeyCode.Zero, ctrl = true},
    [31] = {keycode = Enum.KeyCode.Q, ctrl = true},
    [32] = {keycode = Enum.KeyCode.W, ctrl = true},
    [33] = {keycode = Enum.KeyCode.E, ctrl = true},
    [34] = {keycode = Enum.KeyCode.R, ctrl = true},
    [35] = {keycode = Enum.KeyCode.T, ctrl = true},
    [36] = {keycode = Enum.KeyCode.One, shift = false}, [37] = {keycode = Enum.KeyCode.One, shift = true},
    [38] = {keycode = Enum.KeyCode.Two, shift = false}, [39] = {keycode = Enum.KeyCode.Two, shift = true},
    [40] = {keycode = Enum.KeyCode.Three, shift = false}, [41] = {keycode = Enum.KeyCode.Four, shift = false},
    [42] = {keycode = Enum.KeyCode.Four, shift = true}, [43] = {keycode = Enum.KeyCode.Five, shift = false},
    [44] = {keycode = Enum.KeyCode.Five, shift = true}, [45] = {keycode = Enum.KeyCode.Six, shift = false},
    [46] = {keycode = Enum.KeyCode.Six, shift = true}, [47] = {keycode = Enum.KeyCode.Seven, shift = false},
    [48] = {keycode = Enum.KeyCode.Eight, shift = false}, [49] = {keycode = Enum.KeyCode.Eight, shift = true},
    [50] = {keycode = Enum.KeyCode.Nine, shift = false}, [51] = {keycode = Enum.KeyCode.Nine, shift = true},
    [52] = {keycode = Enum.KeyCode.Zero, shift = false}, [53] = {keycode = Enum.KeyCode.Q, shift = false},
    [54] = {keycode = Enum.KeyCode.Q, shift = true}, [55] = {keycode = Enum.KeyCode.W, shift = false},
    [56] = {keycode = Enum.KeyCode.W, shift = true}, [57] = {keycode = Enum.KeyCode.E, shift = false},
    [58] = {keycode = Enum.KeyCode.E, shift = true}, [59] = {keycode = Enum.KeyCode.R, shift = false},
    [60] = {keycode = Enum.KeyCode.T, shift = false}, [61] = {keycode = Enum.KeyCode.T, shift = true},
    [62] = {keycode = Enum.KeyCode.Y, shift = false}, [63] = {keycode = Enum.KeyCode.Y, shift = true},
    [64] = {keycode = Enum.KeyCode.U, shift = false}, [65] = {keycode = Enum.KeyCode.I, shift = false},
    [66] = {keycode = Enum.KeyCode.I, shift = true}, [67] = {keycode = Enum.KeyCode.O, shift = false},
    [68] = {keycode = Enum.KeyCode.O, shift = true}, [69] = {keycode = Enum.KeyCode.P, shift = false},
    [70] = {keycode = Enum.KeyCode.P, shift = true}, [71] = {keycode = Enum.KeyCode.A, shift = false},
    [72] = {keycode = Enum.KeyCode.S, shift = false}, [73] = {keycode = Enum.KeyCode.S, shift = true},
    [74] = {keycode = Enum.KeyCode.D, shift = false}, [75] = {keycode = Enum.KeyCode.D, shift = true},
    [76] = {keycode = Enum.KeyCode.F, shift = false}, [77] = {keycode = Enum.KeyCode.G, shift = false},
    [78] = {keycode = Enum.KeyCode.G, shift = true}, [79] = {keycode = Enum.KeyCode.H, shift = false},
    [80] = {keycode = Enum.KeyCode.H, shift = true}, [81] = {keycode = Enum.KeyCode.J, shift = false},
    [82] = {keycode = Enum.KeyCode.J, shift = true}, [83] = {keycode = Enum.KeyCode.K, shift = false},
    [84] = {keycode = Enum.KeyCode.L, shift = false}, [85] = {keycode = Enum.KeyCode.L, shift = true},
    [86] = {keycode = Enum.KeyCode.Z, shift = false}, [87] = {keycode = Enum.KeyCode.Z, shift = true},
    [88] = {keycode = Enum.KeyCode.X, shift = false}, [89] = {keycode = Enum.KeyCode.C, shift = false},
    [90] = {keycode = Enum.KeyCode.C, shift = true}, [91] = {keycode = Enum.KeyCode.V, shift = false},
    [92] = {keycode = Enum.KeyCode.V, shift = true}, [93] = {keycode = Enum.KeyCode.B, shift = false},
    [94] = {keycode = Enum.KeyCode.B, shift = true}, [95] = {keycode = Enum.KeyCode.N, shift = false},
    [96] = {keycode = Enum.KeyCode.M, shift = false}, [97] = {keycode = Enum.KeyCode.M, shift = true},
    [98] = {keycode = Enum.KeyCode.U, ctrl = true}, [99] = {keycode = Enum.KeyCode.I, ctrl = true},
    [100] = {keycode = Enum.KeyCode.O, ctrl = true}, [101] = {keycode = Enum.KeyCode.P, ctrl = true},
    [102] = {keycode = Enum.KeyCode.A, ctrl = true}, [103] = {keycode = Enum.KeyCode.S, ctrl = true},
    [104] = {keycode = Enum.KeyCode.D, ctrl = true}, [105] = {keycode = Enum.KeyCode.F, ctrl = true},
    [106] = {keycode = Enum.KeyCode.G, ctrl = true}, [107] = {keycode = Enum.KeyCode.H, ctrl = true},
    [108] = {keycode = Enum.KeyCode.J, ctrl = true}
}

local events = {}
local tempo_events = {}
local current_tempo = 500000
local current_time = 0
local last_tick = 0
local sustain = false
-- Space is also "leave seat" / jump while sitting; MIDI sustain used Space and kicked players off pianos.
local pedal_uses_space = false
local function sustain_pedal_key()
	return pedal_uses_space and Enum.KeyCode.Space or Enum.KeyCode.LeftAlt
end
local key88_enabled = true
local auto_sustain_enabled = true
local no_note_off_enabled = false
local random_note_enabled = false
local deblack_enabled = false
local deblack_level = 65
local deblack_strict = true
local shift = false
local ctrl = false
local active_notes = {}
local note_on_stack = {}
local start_time = 0
local next_event_index = 1
local paused = false
local pause_time = 0
local pause_position = 0
local total_duration = 0
local midi_files = {}
local playback_speed = 1.0
local midi_loaded = false
local is_loading = false
local folder_name = "MIDIow"
if not isfolder(folder_name) then makefolder(folder_name) end

local ignore_played_slider_callback = false
local ignore_speed_slider_callback = false

local on_midi_loaded_callback = nil
local played_slider_set_value = nil
local speed_slider_set_value = nil
local render_conn = nil

local function read_var_int(data, offset)
    local value = 0
    local bytes_read = 0
    while true do
        local byte = string.byte(data, offset + bytes_read)
        if not byte then break end
        bytes_read = bytes_read + 1
        value = bit32.bor(bit32.lshift(value, 7), bit32.band(byte, 0x7F))
        if bit32.band(byte, 0x80) == 0 then break end
    end
    return value, bytes_read
end

local function calculate_realtime_position(ticks, ticks_per_beat, tempo_changes)
    local current_tick = 0
    local current_time_ms = 0
    local current_tempo = 500000
    
    for i = 1, #tempo_changes do
        local tempo_event = tempo_changes[i]
        if tempo_event.tick <= ticks then
            local tick_diff = tempo_event.tick - current_tick
            current_time_ms = current_time_ms + (tick_diff * current_tempo / 1000) / ticks_per_beat
            
            current_tick = tempo_event.tick
            current_tempo = tempo_event.tempo
        else
            break
        end
    end
    
    local remaining_ticks = ticks - current_tick
    current_time_ms = current_time_ms + (remaining_ticks * current_tempo / 1000) / ticks_per_beat
    
    return current_time_ms / 1000
end

local function apply_deblack(parsed_events)
    if not deblack_enabled then
        return parsed_events
    end

    local note_on_times = {}
    local last_note_off = {}
    local keep_indexes = {}
    local n = #parsed_events

    for i = 1, n do
        local note = parsed_events[i]
        
        if not note.abs_time or type(note.abs_time) ~= "number" then
            keep_indexes[i] = true
        elseif note.type == "control" then
            keep_indexes[i] = true
        elseif not note.channel or not note.note then
            keep_indexes[i] = true
        else
            local key = tostring(note.channel) .. ":" .. tostring(note.note)
            
            if note.vel and note.vel > 0 then
                local should_ignore = false

                if deblack_strict then
                    local prev_off = last_note_off[key]
                    if prev_off and prev_off.t and prev_off.v and type(prev_off.t) == "number" then
                        local dt = note.abs_time - prev_off.t
                        local vel_diff = _math.abs(note.vel - prev_off.v)
                        if dt < 0.035 and vel_diff < 7 then
                            should_ignore = true
                        end
                    end
                end

                if not should_ignore then
                    note_on_times[key] = { t = note.abs_time, idx = i, v = note.vel }
                end
            else
                local on_data = note_on_times[key]
                if on_data and on_data.t and on_data.v and type(on_data.t) == "number" then
                    local dt = (note.abs_time - on_data.t) * 1000
                    local vel = on_data.v

                    last_note_off[key] = { t = note.abs_time, v = vel }
                    note_on_times[key] = nil

                    if not (vel <= (deblack_level) and dt < 20) then
                        keep_indexes[on_data.idx] = true
                        keep_indexes[i] = true
                    end
                else
                    keep_indexes[i] = true
                end
            end
        end
    end

    local filtered_events = {}
    local filtered_count = 0
    for i = 1, n do
        if keep_indexes[i] then
            filtered_count = filtered_count + 1
            filtered_events[filtered_count] = parsed_events[i]
        end
    end

    return filtered_events
end

local function parse_midi_improved(data, loading_label)
    local buffer = data
    local offset = 1
    local track_end_offset = 0
    local is_header_parsed = false
    local ticks_per_beat = 0
    local last_status_byte = nil
    local track_time = 0
    local note_on_stack = {}
    local parsed_events = {}
    local tempo_changes = {{tick = 0, tempo = 500000}}
    local event_count = 0
    local last_yield = os.clock()

    while true do
        if os.clock() - last_yield > 0.033 then
            _task.wait()
            last_yield = os.clock()
            if loading_label and loading_label.Parent then
                loading_label.Text = string.format("⏳ Parsing... %d events", event_count)
            end
        end

        if not is_header_parsed then
            if #buffer < 14 then break end
            if string.sub(buffer, 1, 4) ~= 'MThd' then break end
            ticks_per_beat = string.unpack(">H", buffer, 13)
            offset = 15
            is_header_parsed = true
        end

        if offset >= track_end_offset then
            if #buffer - offset + 1 < 8 then break end
            if string.sub(buffer, offset, offset + 3) ~= 'MTrk' then break end
            offset = offset + 4
            local track_length = string.unpack(">I4", buffer, offset)
            offset = offset + 4
            track_end_offset = offset + track_length - 1
            last_status_byte = nil
            track_time = 0
            note_on_stack = {}
        end

        if offset > track_end_offset then break end

        local delta, delta_bytes = read_var_int(buffer, offset)
        offset = offset + delta_bytes
        track_time = track_time + delta

        local status
        local status_byte = string.byte(buffer, offset)
        if not status_byte then break end

        if bit32.band(status_byte, 0x80) ~= 0 then
            last_status_byte = status_byte
            status = status_byte
            offset = offset + 1
        else
            if last_status_byte == nil then break end
            status = last_status_byte
        end

        local command = bit32.band(status, 0xF0)
        local channel = bit32.band(status, 0x0F)

        if command == 0x90 or command == 0x80 then
            local note_number = string.byte(buffer, offset)
            local velocity = string.byte(buffer, offset + 1)
            if not note_number or not velocity then break end
            offset = offset + 2

            local is_on = command == 0x90 and velocity > 0
            local key = tostring(note_number) .. ":" .. tostring(channel)

            if is_on then
                if note_on_stack[key] then
                    local prev = note_on_stack[key]
                    local length_ticks = track_time - prev.on_tick
                    if length_ticks > 0 then
                        local on_time = calculate_realtime_position(prev.on_tick, ticks_per_beat, tempo_changes)
                        local off_time = calculate_realtime_position(track_time, ticks_per_beat, tempo_changes)
                        event_count = event_count + 2
                        parsed_events[event_count - 1] = {
                            type = 'on',
                            note = prev.note_name,
                            vel = prev.velocity,
                            channel = prev.channel,
                            abs_time = on_time,
                            tick = prev.on_tick
                        }
                        parsed_events[event_count] = {
                            type = 'off',
                            note = prev.note_name,
                            channel = prev.channel,
                            abs_time = off_time,
                            tick = track_time
                        }
                    end
                    note_on_stack[key] = nil
                end
                note_on_stack[key] = {
                    on_tick = track_time,
                    velocity = velocity,
                    note_name = note_number,
                    channel = channel
                }
            else
                local prev = note_on_stack[key]
                if prev then
                    local length_ticks = track_time - prev.on_tick
                    if length_ticks > 0 then
                        local on_time = calculate_realtime_position(prev.on_tick, ticks_per_beat, tempo_changes)
                        local off_time = calculate_realtime_position(track_time, ticks_per_beat, tempo_changes)
                        event_count = event_count + 2
                        parsed_events[event_count - 1] = {
                            type = 'on',
                            note = prev.note_name,
                            vel = prev.velocity,
                            channel = prev.channel,
                            abs_time = on_time,
                            tick = prev.on_tick
                        }
                        parsed_events[event_count] = {
                            type = 'off',
                            note = prev.note_name,
                            channel = prev.channel,
                            abs_time = off_time,
                            tick = track_time
                        }
                    end
                    note_on_stack[key] = nil
                end
            end
        elseif command == 0xB0 then
            local controller_type = string.byte(buffer, offset)
            local value = string.byte(buffer, offset + 1)
            if not controller_type or not value then break end
            offset = offset + 2
            
            if controller_type == 64 then
                local control_time = calculate_realtime_position(track_time, ticks_per_beat, tempo_changes)
                event_count = event_count + 1
                parsed_events[event_count] = {
                    type = 'control',
                    vel = value,
                    abs_time = control_time,
                    tick = track_time
                }
            end
        elseif status == 0xFF then
            local meta_type = string.byte(buffer, offset)
            if not meta_type then break end
            offset = offset + 1
            
            local length, length_bytes = read_var_int(buffer, offset)
            offset = offset + length_bytes
            
            if meta_type == 0x51 and length == 3 then
                local b1, b2, b3 = string.byte(buffer, offset, offset + 2)
                if b1 and b2 and b3 then
                    local micro_per_beat = b1 * 65536 + b2 * 256 + b3
                    table.insert(tempo_changes, {tick = track_time, tempo = micro_per_beat})
                end
            end
            offset = offset + length
        else
            local data_len = (command == 0xC0 or command == 0xD0) and 1 or 2
            offset = offset + data_len
        end

        if offset > track_end_offset then
            offset = track_end_offset + 1
        end
    end

    for key, prev in pairs(note_on_stack) do
        local on_time = calculate_realtime_position(prev.on_tick, ticks_per_beat, tempo_changes)
        event_count = event_count + 1
        parsed_events[event_count] = {
            type = 'on',
            note = prev.note_name,
            vel = prev.velocity,
            channel = prev.channel,
            abs_time = on_time,
            tick = prev.on_tick
        }
    end

    if loading_label and loading_label.Parent then
        loading_label.Text = "⏳ Sorting events..."
    end
    _task.wait()
    
    table.sort(parsed_events, function(a, b) return a.abs_time < b.abs_time end)
    
    if loading_label and loading_label.Parent then
        loading_label.Text = "⏳ Applying deblack..."
    end
    _task.wait()
    
    parsed_events = apply_deblack(parsed_events)
    
    return parsed_events, tempo_changes
end

local function release_all_keys()
    for _, k in pairs(active_notes) do
        vim:SendKeyEvent(false, k.keycode, false, game)
    end
    if ctrl then 
        vim:SendKeyEvent(false, Enum.KeyCode.LeftControl, false, game)
        ctrl = false 
    end
    if shift then 
        vim:SendKeyEvent(false, Enum.KeyCode.LeftShift, false, game)
        shift = false 
    end
    if sustain then
        vim:SendKeyEvent(false, sustain_pedal_key(), false, game)
        sustain = false
    end
    active_notes = {}
end

local function get_current_playback_position()
    if paused then
        return pause_position
    else
        return (os.clock() - start_time) * playback_speed
    end
end

local function play_realtime_events()
    if paused then return end
    local elapsed = get_current_playback_position()
    
    while next_event_index <= #events do
        local ev = events[next_event_index]
        local event_time = ev.abs_time
        if ev.type == "off" and random_note_enabled then
            local random_offset = (_math.random(0,15) * 0.01)
            event_time = ev.abs_time - random_offset
            if event_time < 0 then event_time = 0 end
        end
        if ev.type == "on" and random_note_enabled then
            local random_offset = _math.random(0, 5) * 0.01
            event_time = ev.abs_time - random_offset
            if event_time < 0 then event_time = 0 end
        end
        if event_time <= elapsed then
            if ev.type == "on" then
                local k = key_map[ev.note]
                if k then
                    if not key88_enabled and k.ctrl then
                        next_event_index = next_event_index + 1
                        continue
                    end
                    if k.ctrl and not ctrl then vim:SendKeyEvent(true, Enum.KeyCode.LeftControl, false, game); ctrl = true elseif not k.ctrl and ctrl then vim:SendKeyEvent(false, Enum.KeyCode.LeftControl, false, game); ctrl = false end
                    if k.shift and not shift then vim:SendKeyEvent(true, Enum.KeyCode.LeftShift, false, game); shift = true elseif not k.shift and shift then vim:SendKeyEvent(false, Enum.KeyCode.LeftShift, false, game); shift = false end
                    vim:SendKeyEvent(true, k.keycode, false, game)
                    active_notes[ev.note] = k

                    if no_note_off_enabled then
                        vim:SendKeyEvent(false, k.keycode, false, game)
                        active_notes[ev.note] = nil
                    end
                end
            elseif ev.type == "off" then
                if not no_note_off_enabled then
                    local k = active_notes[ev.note]
                    if k then
                        vim:SendKeyEvent(false, k.keycode, false, game)
                        active_notes[ev.note] = nil
                    end
                end
            elseif ev.type == "control" then
                local s = ev.vel >= 64
                local pk = sustain_pedal_key()
                if auto_sustain_enabled then
                    if s ~= sustain then
                        vim:SendKeyEvent(s, pk, false, game)
                        sustain = s
                    end
                else
                    if not sustain then
                        vim:SendKeyEvent(true, pk, false, game)
                        sustain = true
                    end
                end
            end
            next_event_index = next_event_index + 1
        else
            break
        end
    end

    if next_event_index > #events then
        paused = true
        start_time = 0
        next_event_index = 1
        pause_time = 0
        pause_position = 0
        release_all_keys()
    end
end

local function start_playback(parsed_events, tempo_changes)
    events = parsed_events
    tempo_events = tempo_changes or {}
    total_duration = events[#events] and events[#events].abs_time or 0
    start_time = os.clock()
    next_event_index = 1
    pause_position = 0
    release_all_keys()
    paused = false
    midi_loaded = true
end

local function pause_playback()
    if not paused then
        paused = true
        pause_time = os.clock()
        pause_position = (os.clock() - start_time) * playback_speed
        release_all_keys()
    end
end

local function resume_playback()
    if paused then
        start_time = os.clock() - (pause_position / playback_speed)
        paused = false
    end
end

local function stop_playback()
    paused = true
    start_time = 0
    next_event_index = 1
    pause_time = 0
    pause_position = 0
    release_all_keys()
end

local function seek_to_position(ratio)
    local target_time = total_duration * ratio
    pause_position = target_time
    
    next_event_index = 1
    for i = 1, #events do
        if events[i].abs_time > target_time then
            next_event_index = i
            break
        end
    end
    
    if not paused then
        start_time = os.clock() - (target_time / playback_speed)
    end
    
    release_all_keys()
end

local function list_midi_files()
	midi_files = {}
	local seen = {}
	local folders = { "MIDIow", "MIDI" }
	for _, folder in ipairs(folders) do
		local ok, files = _pcall(listfiles, "./" .. folder)
		if ok and files then
			for _, f in ipairs(files) do
				if string.match(f, "%.mid$") or string.match(f, "%.MID$") then
					local name = string.match(f, "[^/\\]+$")
					if name then
						local rel = folder .. "/" .. name
						if not seen[rel] then
							seen[rel] = true
							table.insert(midi_files, rel)
						end
					end
				end
			end
		end
	end
	table.sort(midi_files)
end

local function load_midi_from_data(data, ui_setter)
    if is_loading then return end
    is_loading = true
    ui_setter("⏳ Parsing MIDI...")

    _task.spawn(function()
        events = {}
        tempo_events = {}
        local ok, parsed, tempochg = _pcall(function()
            return parse_midi_improved(data, nil)
        end)
        
        if not ok or not parsed then
            ui_setter("❌ Invalid MIDI or parse error")
            is_loading = false
            return
        end

        parsed = apply_deblack(parsed)

        events = parsed
        tempo_events = tempochg or {}
        total_duration = events[#events] and events[#events].abs_time or 0
        next_event_index = 1
        pause_position = 0
        paused = true
        midi_loaded = true
        is_loading = false

        if on_midi_loaded_callback then
            pcall(on_midi_loaded_callback, total_duration, #events)
        end

        ui_setter("✅ Loaded " .. #events .. " events (" .. string.format("%.3f", total_duration) .. "s)")
    end)
end


local function start_render_loop()
	if render_conn then
		return
	end
	render_conn = run_service.RenderStepped:Connect(function()
		play_realtime_events()
		if played_slider_set_value and midi_loaded and total_duration and total_duration > 0 then
			local elapsed = get_current_playback_position()
			pcall(function()
				ignore_played_slider_callback = true
				played_slider_set_value(elapsed)
				ignore_played_slider_callback = false
			end)
		end
		if speed_slider_set_value then
			pcall(function()
				ignore_speed_slider_callback = true
				speed_slider_set_value(_math.floor(playback_speed * 100))
				ignore_speed_slider_callback = false
			end)
		end
	end)
end

local function stop_render_loop()
	if render_conn then
		render_conn:Disconnect()
		render_conn = nil
	end
end

