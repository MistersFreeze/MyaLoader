local api = {}

local function set_flag(key, value)
	settings[key] = (value == true)
end

function api.start()
	if runtime_conn then
		return
	end
	runtime_conn = RunService.RenderStepped:Connect(runtime_step)
end

function api.stop()
	if runtime_conn then
		runtime_conn:Disconnect()
		runtime_conn = nil
	end
	for _, plr in ipairs(Players:GetPlayers()) do
		cleanup_visuals_for_player(plr)
	end
	hide_all_visuals()
	for i = 1, #aux_connections do
		local c = aux_connections[i]
		if c then
			pcall(function()
				c:Disconnect()
			end)
		end
	end
	aux_connections = {}
	if highlights_folder and highlights_folder.Parent then
		highlights_folder:Destroy()
	end
end

function api.get_player_esp()
	return settings.player_esp
end
function api.set_player_esp(v)
	set_flag("player_esp", v)
end

function api.get_tracers()
	return settings.tracers
end
function api.set_tracers(v)
	set_flag("tracers", v)
end

function api.get_health_bar()
	return settings.health_bar
end
function api.set_health_bar(v)
	set_flag("health_bar", v)
end

function api.get_distance()
	return settings.distance
end
function api.set_distance(v)
	set_flag("distance", v)
end

function api.get_usernames()
	return settings.usernames
end
function api.set_usernames(v)
	set_flag("usernames", v)
end

function api.get_team_mode()
	return settings.team_mode
end
function api.set_team_mode(v)
	set_flag("team_mode", v)
end

_G.MYA_BOOGA = api

function _G.unload_mya_booga()
	pcall(function()
		api.stop()
	end)
	local ui = _G.mya_booga_ui
	if typeof(ui) == "Instance" and ui.Parent then
		pcall(function()
			ui:Destroy()
		end)
	end
	local notif_ui = _G.mya_booga_notif_ui
	if typeof(notif_ui) == "Instance" and notif_ui.Parent then
		pcall(function()
			notif_ui:Destroy()
		end)
	end
	_G.MYA_BOOGA = nil
	_G.MYA_BOOGA_SYNC_UI = nil
	_G.mya_booga_ui = nil
	_G.mya_booga_notif_ui = nil
end
