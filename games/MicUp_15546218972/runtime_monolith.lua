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

local midi_smpte_us_per_tick = nil

local function calculate_realtime_position(ticks, ticks_per_beat, tempo_changes)
	if midi_smpte_us_per_tick and midi_smpte_us_per_tick > 0 then
		return ticks * midi_smpte_us_per_tick / 1000000
	end
	if not ticks_per_beat or ticks_per_beat <= 0 then
		ticks_per_beat = 480
	end
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
    local ticks_per_beat = 480
    midi_smpte_us_per_tick = nil
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
            local div_raw = string.unpack(">H", buffer, 13)
            if bit32.band(div_raw, 0x8000) ~= 0 then
                local tpf = bit32.band(div_raw, 0xFF)
                if tpf == 0 then
                    tpf = 1
                end
                local fps_byte = bit32.band(bit32.rshift(div_raw, 8), 0x7F)
                local fps = fps_byte
                if fps == 29 then
                    fps = 29.97
                elseif fps == 0 then
                    fps = 25
                end
                midi_smpte_us_per_tick = 1000000 / (fps * tpf)
                ticks_per_beat = 480
            else
                ticks_per_beat = div_raw > 0 and div_raw or 480
            end
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
            last_status_byte = nil
        elseif status == 0xF0 or status == 0xF7 then
            local syx_len, lb = read_var_int(buffer, offset)
            if not syx_len or lb == 0 then
                break
            end
            offset = offset + lb + syx_len
            last_status_byte = nil
        elseif bit32.band(status, 0xF0) == 0xF0 and status < 0xF8 then
            local skip = 0
            if status == 0xF1 or status == 0xF3 then
                skip = 1
            elseif status == 0xF2 then
                skip = 2
            elseif status == 0xF6 then
                skip = 0
            else
                skip = 1
            end
            offset = offset + skip
            last_status_byte = nil
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
        
        if not ok then
            ui_setter("❌ " .. tostring(parsed))
            is_loading = false
            return
        end
        if not parsed then
            ui_setter("❌ Invalid MIDI (empty or not SMF)")
            is_loading = false
            return
        end

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

-- Corner (MicUp): game Profile Tags UI caps selection using require(ReplicatedStorage.Assets.Data.Tags).MaxTags.
-- Bump it client-side so the stock prompt allows more than 8. Server may still reject on UpdateProfileTags.
task.spawn(function()
	local okPath, tagsMod = pcall(function()
		return game:GetService("ReplicatedStorage"):WaitForChild("Assets", 30):WaitForChild("Data", 30):WaitForChild(
			"Tags",
			30
		)
	end)
	if not okPath or not tagsMod or not tagsMod:IsA("ModuleScript") then
		return
	end
	local ok, m = pcall(require, tagsMod)
	if ok and type(m) == "table" and type(m.MaxTags) == "number" then
		m.MaxTags = 255
	end
end)

-- ——— Visuals (ESP + nametags) ———
local visuals_esp = false
local visuals_nametags = false
local visuals_conns = {}
local visuals_periodic_conn = nil
local visuals_char_tracked = {}

local function visuals_collect_body_parts(char)
	local parts = {}
	for _, p in ipairs(char:GetDescendants()) do
		if p:IsA("BasePart") then
			local tool = p:FindFirstAncestorOfClass("Tool")
			if tool and tool:IsDescendantOf(char) then
				-- skip held tools
			else
				table.insert(parts, p)
			end
		end
	end
	return parts
end

local function visuals_clear_char_track(plr)
	local t = visuals_char_tracked[plr]
	if t and t.descConn then
		pcall(function()
			t.descConn:Disconnect()
		end)
	end
	visuals_char_tracked[plr] = nil
end

local function visuals_strip(char)
	if not char then
		return
	end
	local h = char:FindFirstChild("MyaESP")
	if h then
		h:Destroy()
	end
	local head = char:FindFirstChild("Head")
	if head then
		local b = head:FindFirstChild("MyaNametag")
		if b then
			b:Destroy()
		end
	end
end

local function visuals_track_character(plr, char)
	local existing = visuals_char_tracked[plr]
	if existing and existing.char == char and existing.descConn then
		return
	end
	visuals_clear_char_track(plr)
	if not char or not char.Parent or not visuals_esp then
		return
	end
	local pending = false
	local descConn = char.DescendantAdded:Connect(function(inst)
		if not visuals_esp or plr.Character ~= char then
			return
		end
		if inst:IsA("BasePart") or inst:IsA("Accessory") then
			if pending then
				return
			end
			pending = true
			_task.delay(0.45, function()
				pending = false
				if visuals_esp and plr.Character == char and char.Parent then
					pcall(function()
						visuals_apply(plr, char)
					end)
				end
			end)
		end
	end)
	visuals_char_tracked[plr] = { char = char, descConn = descConn }
end

local function visuals_apply(plr, char)
	if not char then
		return
	end
	visuals_strip(char)
	local show_esp = visuals_esp and plr ~= player
	if show_esp then
		local folder = Instance.new("Folder")
		folder.Name = "MyaESP"
		folder.Parent = char
		local fill = Color3.fromRGB(255, 90, 140)
		local outline = Color3.fromRGB(255, 255, 255)
		for _, part in ipairs(visuals_collect_body_parts(char)) do
			local hl = Instance.new("Highlight")
			hl.Name = "MyaESPPart"
			hl.Adornee = part
			hl.Parent = folder
			hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
			hl.FillColor = fill
			hl.OutlineColor = outline
			hl.FillTransparency = 0.55
			hl.OutlineTransparency = 0.3
		end
	end
	if visuals_nametags then
		local head = char:FindFirstChild("Head") or char:WaitForChild("Head", 8)
		if head then
			local bb = Instance.new("BillboardGui")
			bb.Name = "MyaNametag"
			bb.Adornee = head
			bb.AlwaysOnTop = true
			bb.Size = UDim2.fromOffset(200, 26)
			bb.StudsOffset = Vector3.new(0, 2.35, 0)
			bb.Parent = head
			local tl = Instance.new("TextLabel")
			tl.Size = UDim2.fromScale(1, 1)
			tl.BackgroundTransparency = 1
			tl.Text = (plr.DisplayName ~= "" and plr.DisplayName) or plr.Name
			tl.TextColor3 = Color3.fromRGB(255, 235, 245)
			tl.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
			tl.TextStrokeTransparency = 0.45
			tl.Font = Enum.Font.GothamBold
			tl.TextSize = 14
			tl.Parent = bb
		end
	end
end

local function visuals_refresh_all()
	if not visuals_esp then
		for plr in pairs(visuals_char_tracked) do
			visuals_clear_char_track(plr)
		end
	end
	for _, plr in ipairs(players:GetPlayers()) do
		if plr.Character then
			pcall(function()
				visuals_apply(plr, plr.Character)
			end)
			if visuals_esp then
				visuals_track_character(plr, plr.Character)
			end
		end
	end
end

local function visuals_schedule_char_apply(plr, char)
	_task.defer(function()
		pcall(function()
			char:WaitForChild("Humanoid", 15)
			char:WaitForChild("HumanoidRootPart", 15)
		end)
		if plr.Character == char and char.Parent then
			pcall(function()
				visuals_apply(plr, char)
			end)
		end
		if visuals_esp then
			visuals_track_character(plr, char)
		end
	end)
	_task.delay(0.55, function()
		if visuals_esp and plr.Character == char and char.Parent then
			pcall(function()
				visuals_apply(plr, char)
			end)
			visuals_track_character(plr, char)
		end
	end)
	_task.delay(1.8, function()
		if visuals_esp and plr.Character == char and char.Parent then
			pcall(function()
				visuals_apply(plr, char)
			end)
			visuals_track_character(plr, char)
		end
	end)
end

local function visuals_hook_player(plr)
	local c = plr.CharacterAdded:Connect(function(char)
		visuals_schedule_char_apply(plr, char)
	end)
	table.insert(visuals_conns, c)
	if plr.Character then
		visuals_schedule_char_apply(plr, plr.Character)
	end
end

local function visuals_init()
	for _, c in ipairs(visuals_conns) do
		pcall(function()
			c:Disconnect()
		end)
	end
	visuals_conns = {}
	if visuals_periodic_conn then
		pcall(function()
			visuals_periodic_conn:Disconnect()
		end)
		visuals_periodic_conn = nil
	end
	for plr in pairs(visuals_char_tracked) do
		visuals_clear_char_track(plr)
	end

	local acc = 0
	visuals_periodic_conn = run_service.Heartbeat:Connect(function(dt)
		if not visuals_esp then
			return
		end
		acc = acc + dt
		if acc >= 3.5 then
			acc = 0
			pcall(visuals_refresh_all)
		end
	end)
	table.insert(visuals_conns, visuals_periodic_conn)

	table.insert(
		visuals_conns,
		players.PlayerAdded:Connect(function(plr)
			visuals_hook_player(plr)
		end)
	)
	table.insert(
		visuals_conns,
		players.PlayerRemoving:Connect(function(plr)
			visuals_clear_char_track(plr)
		end)
	)
	for _, plr in ipairs(players:GetPlayers()) do
		visuals_hook_player(plr)
	end
end

local function visuals_unload()
	for _, c in ipairs(visuals_conns) do
		pcall(function()
			c:Disconnect()
		end)
	end
	visuals_conns = {}
	visuals_periodic_conn = nil
	for plr in pairs(visuals_char_tracked) do
		visuals_clear_char_track(plr)
	end
	for _, plr in ipairs(players:GetPlayers()) do
		if plr.Character then
			visuals_strip(plr.Character)
		end
	end
end

-- ——— Movement (fly + noclip) ———
local workspace = Services.Workspace
local move_fly = false
local move_fly_speed = 500
local move_noclip = false
local anti_ragdoll_enabled = false
local anti_ragdoll_hb = nil
local anti_ragdoll_char_conn = nil
local _fly_bv = nil
local _fly_conn = nil
local _noclip_step = nil
local _move_char_conn = nil
-- Original collision flags per part; restoring all parts to CanCollide=true broke hitboxes (accessories, etc.).
local noclip_saved_collide = {}
local move_walk = 16
local move_jump = 50
local move_ws_orig = nil
local move_jp_orig = nil

local function get_local_root()
	local c = player.Character
	return c and c:FindFirstChild("HumanoidRootPart")
end

local function get_local_humanoid()
	local c = player.Character
	return c and c:FindFirstChildWhichIsA("Humanoid")
end

local function refresh_movement_stats()
	local hum = get_local_humanoid()
	if not hum then
		return
	end
	if move_ws_orig == nil then
		move_ws_orig = hum.WalkSpeed
	end
	if move_jp_orig == nil then
		move_jp_orig = hum.JumpPower
	end
	hum.WalkSpeed = move_walk
	hum.JumpPower = move_jump
end

local function restore_movement_stats()
	local hum = get_local_humanoid()
	if hum then
		if move_ws_orig ~= nil then
			hum.WalkSpeed = move_ws_orig
		end
		if move_jp_orig ~= nil then
			hum.JumpPower = move_jp_orig
		end
	end
	move_ws_orig = nil
	move_jp_orig = nil
end

local function restore_ragdoll_state_enabled(hum)
	if not hum then
		return
	end
	pcall(function()
		hum:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, true)
	end)
end

local function apply_anti_ragdoll_humanoid(hum)
	if not hum or not anti_ragdoll_enabled then
		return
	end
	pcall(function()
		hum:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, false)
	end)
end

local function stop_anti_ragdoll_connections()
	if anti_ragdoll_hb then
		pcall(function()
			anti_ragdoll_hb:Disconnect()
		end)
		anti_ragdoll_hb = nil
	end
	if anti_ragdoll_char_conn then
		pcall(function()
			anti_ragdoll_char_conn:Disconnect()
		end)
		anti_ragdoll_char_conn = nil
	end
end

local function anti_ragdoll_heartbeat()
	if not anti_ragdoll_enabled or move_fly then
		return
	end
	local hum = get_local_humanoid()
	if not hum then
		return
	end
	local st = hum:GetState()
	if st == Enum.HumanoidStateType.Ragdoll or st == Enum.HumanoidStateType.Physics then
		pcall(function()
			hum:ChangeState(Enum.HumanoidStateType.GettingUp)
		end)
	elseif st == Enum.HumanoidStateType.FallingDown then
		pcall(function()
			hum:ChangeState(Enum.HumanoidStateType.Running)
		end)
	end
end

local function start_anti_ragdoll_internal()
	stop_anti_ragdoll_connections()
	if not anti_ragdoll_enabled then
		return
	end
	apply_anti_ragdoll_humanoid(get_local_humanoid())
	anti_ragdoll_hb = run_service.Heartbeat:Connect(anti_ragdoll_heartbeat)
	anti_ragdoll_char_conn = player.CharacterAdded:Connect(function()
		_task.wait(0.1)
		apply_anti_ragdoll_humanoid(get_local_humanoid())
	end)
end

local function stop_fly_internal()
	if _fly_conn then
		pcall(function()
			_fly_conn:Disconnect()
		end)
		_fly_conn = nil
	end
	if _fly_bv then
		pcall(function()
			_fly_bv:Destroy()
		end)
		_fly_bv = nil
	end
	local hum = get_local_humanoid()
	if hum then
		hum.PlatformStand = false
	end
end

local function start_fly_internal()
	stop_fly_internal()
	local root = get_local_root()
	local hum = get_local_humanoid()
	if not root or not hum then
		return
	end
	hum.PlatformStand = true
	local bv = Instance.new("BodyVelocity")
	bv.MaxForce = Vector3.new(500000, 500000, 500000)
	bv.Velocity = Vector3.zero
	bv.Parent = root
	_fly_bv = bv
	_fly_conn = run_service.RenderStepped:Connect(function()
		if not move_fly then
			return
		end
		root = get_local_root()
		if not root or not _fly_bv or _fly_bv.Parent ~= root then
			return
		end
		local cam = workspace.CurrentCamera
		if not cam then
			return
		end
		local cf = cam.CFrame
		local dir = Vector3.zero
		if uis:IsKeyDown(Enum.KeyCode.W) then
			dir = dir + cf.LookVector
		end
		if uis:IsKeyDown(Enum.KeyCode.S) then
			dir = dir - cf.LookVector
		end
		if uis:IsKeyDown(Enum.KeyCode.D) then
			dir = dir + cf.RightVector
		end
		if uis:IsKeyDown(Enum.KeyCode.A) then
			dir = dir - cf.RightVector
		end
		if uis:IsKeyDown(Enum.KeyCode.Space) then
			dir = dir + Vector3.new(0, 1, 0)
		end
		if uis:IsKeyDown(Enum.KeyCode.LeftControl) or uis:IsKeyDown(Enum.KeyCode.C) then
			dir = dir - Vector3.new(0, 1, 0)
		end
		if dir.Magnitude > 0 then
			_fly_bv.Velocity = dir.Unit * move_fly_speed
		else
			_fly_bv.Velocity = Vector3.zero
		end
	end)
end

local function stop_noclip_internal()
	if _noclip_step then
		pcall(function()
			_noclip_step:Disconnect()
		end)
		_noclip_step = nil
	end
	for part, wasCollide in pairs(noclip_saved_collide) do
		if part.Parent and part:IsA("BasePart") then
			pcall(function()
				part.CanCollide = wasCollide
			end)
		end
	end
	noclip_saved_collide = {}
end

local function start_noclip_internal()
	stop_noclip_internal()
	_noclip_step = run_service.Stepped:Connect(function()
		if not move_noclip then
			return
		end
		local char = player.Character
		if not char then
			return
		end
		for _, p in ipairs(char:GetDescendants()) do
			if p:IsA("BasePart") then
				if noclip_saved_collide[p] == nil then
					noclip_saved_collide[p] = p.CanCollide
				end
				p.CanCollide = false
			end
		end
	end)
end

local function movement_unload()
	move_fly = false
	move_noclip = false
	restore_movement_stats()
	restore_ragdoll_state_enabled(get_local_humanoid())
	stop_anti_ragdoll_connections()
	anti_ragdoll_enabled = false
	stop_fly_internal()
	stop_noclip_internal()
	if _move_char_conn then
		pcall(function()
			_move_char_conn:Disconnect()
		end)
		_move_char_conn = nil
	end
end

local function movement_init()
	if _move_char_conn then
		return
	end
	_move_char_conn = player.CharacterAdded:Connect(function()
		_task.wait(0.2)
		move_ws_orig = nil
		move_jp_orig = nil
		refresh_movement_stats()
		if move_fly then
			start_fly_internal()
		end
	end)
	_task.defer(function()
		local h = get_local_humanoid()
		if h then
			move_walk = h.WalkSpeed
			move_jump = h.JumpPower
		end
	end)
end

-- ——— Targeting (spy camera / TP) ———
local SPY_RS_NAME = "MyaNeighborsSpyCam"
local spy_input_conn = nil
local spy_target_player = nil
local spy_yaw = 0
local spy_pitch = 0
local spy_dist = 18
local spy_sens = 0.0025
local spy_rmb_orbit_lock = false

local function resolve_target_query(q)
	if typeof(q) ~= "string" then
		return nil
	end
	q = q:lower():gsub("^%s+", ""):gsub("%s+$", "")
	if #q == 0 then
		return nil
	end
	for _, plr in ipairs(players:GetPlayers()) do
		if plr.Name:lower() == q or plr.DisplayName:lower() == q then
			return plr
		end
	end
	for _, plr in ipairs(players:GetPlayers()) do
		if string.find(plr.Name:lower(), q, 1, true) or string.find(plr.DisplayName:lower(), q, 1, true) then
			return plr
		end
	end
	return nil
end

local function stop_spy_camera()
	pcall(function()
		run_service:UnbindFromRenderStep(SPY_RS_NAME)
	end)
	if spy_input_conn then
		pcall(function()
			spy_input_conn:Disconnect()
		end)
		spy_input_conn = nil
	end
	if spy_rmb_orbit_lock then
		spy_rmb_orbit_lock = false
		pcall(function()
			uis.MouseBehavior = Enum.MouseBehavior.Default
		end)
	end
	spy_target_player = nil
	local cam = workspace.CurrentCamera
	if cam then
		cam.CameraType = Enum.CameraType.Custom
		local hum = get_local_humanoid()
		if hum then
			cam.CameraSubject = hum
		end
	end
end

-- Orbit + free look (Scriptable). CameraSubject stays LOCAL humanoid so aim/hitbox stay consistent.
-- Raycast ignores the target's character so their mesh does not block the view.
local function start_spy_camera(target)
	if not target or target == player then
		return false, "Pick another player"
	end
	stop_spy_camera()
	local char = target.Character
	if not char then
		return false, "No character"
	end
	local hrp = char:FindFirstChild("HumanoidRootPart")
	if not hrp then
		return false, "No HRP"
	end
	local cam = workspace.CurrentCamera
	if not cam then
		return false, "No camera"
	end
	local localHum = get_local_humanoid()
	if localHum then
		cam.CameraSubject = localHum
	end
	spy_target_player = target
	spy_dist = 18
	local back = -hrp.CFrame.LookVector
	local dir0 = back.Unit
	spy_yaw = math.atan2(dir0.X, dir0.Z)
	spy_pitch = math.asin(_math.clamp(dir0.Y, -0.999, 0.999))

	cam.CameraType = Enum.CameraType.Scriptable

	spy_input_conn = uis.InputChanged:Connect(function(input)
		if not spy_target_player then
			return
		end
		if input.UserInputType == Enum.UserInputType.MouseWheel then
			spy_dist = _math.clamp(spy_dist - input.Position.Z * 2.5, 4, 90)
		end
	end)

	run_service:BindToRenderStep(SPY_RS_NAME, Enum.RenderPriority.Camera.Value, function()
		if not spy_target_player or not spy_target_player.Parent then
			stop_spy_camera()
			return
		end
		local ch = spy_target_player.Character
		if not ch then
			stop_spy_camera()
			return
		end
		local h = ch:FindFirstChild("HumanoidRootPart")
		if not h then
			stop_spy_camera()
			return
		end

		local rmb = uis:IsMouseButtonPressed(Enum.UserInputType.MouseButton2)
		if rmb then
			if not spy_rmb_orbit_lock then
				spy_rmb_orbit_lock = true
				uis.MouseBehavior = Enum.MouseBehavior.LockCenter
			end
			local d = uis:GetMouseDelta()
			if d.Magnitude > 0 then
				spy_yaw = spy_yaw - d.X * spy_sens
				spy_pitch = spy_pitch - d.Y * spy_sens
				local pitchMax = math.rad(89)
				spy_pitch = _math.clamp(spy_pitch, -pitchMax, pitchMax)
			end
		elseif spy_rmb_orbit_lock then
			spy_rmb_orbit_lock = false
			uis.MouseBehavior = Enum.MouseBehavior.Default
		end

		local focus = h.Position + Vector3.new(0, 1.5, 0)
		local cp = math.cos(spy_pitch)
		local dir = Vector3.new(cp * math.sin(spy_yaw), math.sin(spy_pitch), cp * math.cos(spy_yaw))
		local wantPos = focus - dir * spy_dist

		local rp = RaycastParams.new()
		rp.FilterType = Enum.RaycastFilterType.Blacklist
		local ignore = { ch }
		if player.Character then
			table.insert(ignore, player.Character)
		end
		rp.FilterDescendantsInstances = ignore
		rp.IgnoreWater = true
		local seg = wantPos - focus
		local segLen = seg.Magnitude
		if segLen > 0.05 then
			local hit = workspace:Raycast(focus, seg, rp)
			if hit then
				local safe = hit.Distance - 0.75
				if safe < 1 then
					safe = 1
				end
				local minOrbit = math.min(spy_dist, 6)
				if safe >= minOrbit then
					wantPos = focus - dir * _math.min(safe, spy_dist)
				end
			end
		end

		cam.CFrame = CFrame.lookAt(wantPos, focus)
	end)
	return true
end

local function reset_camera_to_local()
	stop_spy_camera()
	local cam = workspace.CurrentCamera
	local hum = get_local_humanoid()
	if not cam or not hum then
		return false
	end
	cam.CameraType = Enum.CameraType.Custom
	cam.CameraSubject = hum
	return true
end

local function teleport_to_target(target)
	local me = get_local_root()
	local them = target.Character and target.Character:FindFirstChild("HumanoidRootPart")
	if not me or not them then
		return false, "Missing character"
	end
	me.CFrame = them.CFrame * CFrame.new(0, 0, 4)
	return true
end

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
		move_fly_speed = _math.clamp(tonumber(v) or 500, 5, 500)
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
