local api = {}

local function set_flag(key, value)
	settings[key] = (value == true)
end

function api.start()
	if runtime_conn then
		return
	end
	runtime_conn = RunService.RenderStepped:Connect(runtime_step)
	refresh_noclip_cam()
	refresh_speed()
	if settings.fly then
		start_fly()
	end
	if settings.noclip then
		start_noclip()
	end
end

function api.stop()
	if runtime_conn then
		runtime_conn:Disconnect()
		runtime_conn = nil
	end
	for _, plr in ipairs(Players:GetPlayers()) do
		cleanup_visuals_for_player(plr)
	end
	for key in pairs(trader_highlights) do
		cleanup_trader_visual(key)
	end
	hide_all_visuals()
	stop_fly()
	stop_noclip()
	restore_speed()
	settings.noclip_cam = false
	refresh_noclip_cam()
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

function api.get_trader_esp()
	return settings.trader_esp
end
function api.set_trader_esp(v)
	settings.trader_esp = (v == true)
end
function api.get_trader_tracers()
	return settings.trader_tracers
end
function api.set_trader_tracers(v)
	settings.trader_tracers = (v == true)
end
function api.set_team_mode(v)
	set_flag("team_mode", v)
end

function api.get_noclip()
	return settings.noclip
end
function api.set_noclip(v)
	settings.noclip = (v == true)
	if settings.noclip then
		start_noclip()
	else
		stop_noclip()
	end
end
function api.get_noclip_bind()
	return settings.noclip_bind
end
function api.set_noclip_bind(v)
	if typeof(v) == "EnumItem" and (v.EnumType == Enum.KeyCode or v.EnumType == Enum.UserInputType) then
		settings.noclip_bind = v
	end
end

function api.get_speed()
	return settings.speed
end
function api.set_speed(v)
	settings.speed = (v == true)
	refresh_speed()
end
function api.get_speed_bind()
	return settings.speed_bind
end
function api.set_speed_bind(v)
	if typeof(v) == "EnumItem" and (v.EnumType == Enum.KeyCode or v.EnumType == Enum.UserInputType) then
		settings.speed_bind = v
	end
end
function api.get_speed_value()
	return settings.speed_value
end
function api.set_speed_value(v)
	local n = tonumber(v)
	if n then
		settings.speed_value = math.clamp(n, 0, 200)
		refresh_speed()
	end
end

function api.get_fly()
	return settings.fly
end
function api.set_fly(v)
	settings.fly = (v == true)
	if settings.fly then
		start_fly()
	else
		stop_fly()
	end
end
function api.get_fly_bind()
	return settings.fly_bind
end
function api.set_fly_bind(v)
	if typeof(v) == "EnumItem" and (v.EnumType == Enum.KeyCode or v.EnumType == Enum.UserInputType) then
		settings.fly_bind = v
	end
end
function api.get_fly_speed()
	return settings.fly_speed
end
function api.set_fly_speed(v)
	local n = tonumber(v)
	if n then
		settings.fly_speed = math.clamp(n, 5, 500)
	end
end

function api.get_noclip_cam()
	return settings.noclip_cam
end
function api.set_noclip_cam(v)
	settings.noclip_cam = (v == true)
	refresh_noclip_cam()
end

function api.get_water_walker()
	return settings.water_walker
end
function api.set_water_walker(v)
	settings.water_walker = (v == true)
end

_G.MYA_BOOGA = api

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

_G.get_config = function()
	return {
		player_esp = settings.player_esp,
		tracers = settings.tracers,
		health_bar = settings.health_bar,
		distance = settings.distance,
		usernames = settings.usernames,
		team_mode = settings.team_mode,
		trader_esp = settings.trader_esp,
		trader_tracers = settings.trader_tracers,
		noclip = settings.noclip,
		noclip_bind = enum_to_str(settings.noclip_bind),
		speed = settings.speed,
		speed_bind = enum_to_str(settings.speed_bind),
		speed_value = settings.speed_value,
		fly = settings.fly,
		fly_bind = enum_to_str(settings.fly_bind),
		fly_speed = settings.fly_speed,
		noclip_cam = settings.noclip_cam,
		water_walker = settings.water_walker,
	}
end

_G.apply_config = function(cfg)
	if type(cfg) ~= "table" then
		return
	end
	if cfg.player_esp ~= nil then api.set_player_esp(cfg.player_esp) end
	if cfg.tracers ~= nil then api.set_tracers(cfg.tracers) end
	if cfg.health_bar ~= nil then api.set_health_bar(cfg.health_bar) end
	if cfg.distance ~= nil then api.set_distance(cfg.distance) end
	if cfg.usernames ~= nil then api.set_usernames(cfg.usernames) end
	if cfg.team_mode ~= nil then api.set_team_mode(cfg.team_mode) end
	if cfg.trader_esp ~= nil then api.set_trader_esp(cfg.trader_esp) end
	if cfg.trader_tracers ~= nil then api.set_trader_tracers(cfg.trader_tracers) end
	if cfg.noclip ~= nil then api.set_noclip(cfg.noclip) end
	if cfg.noclip_bind ~= nil then
		local b = str_to_enum(cfg.noclip_bind)
		if b then api.set_noclip_bind(b) end
	end
	if cfg.speed ~= nil then api.set_speed(cfg.speed) end
	if cfg.speed_bind ~= nil then
		local b = str_to_enum(cfg.speed_bind)
		if b then api.set_speed_bind(b) end
	end
	if cfg.speed_value ~= nil then api.set_speed_value(cfg.speed_value) end
	if cfg.fly ~= nil then api.set_fly(cfg.fly) end
	if cfg.fly_bind ~= nil then
		local b = str_to_enum(cfg.fly_bind)
		if b then api.set_fly_bind(b) end
	end
	if cfg.fly_speed ~= nil then api.set_fly_speed(cfg.fly_speed) end
	if cfg.noclip_cam ~= nil then api.set_noclip_cam(cfg.noclip_cam) end
	if cfg.water_walker ~= nil then api.set_water_walker(cfg.water_walker) end
	if typeof(_G.MYA_BOOGA_SYNC_UI) == "function" then
		_G.MYA_BOOGA_SYNC_UI()
	end
end

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
	_G.get_config = nil
	_G.apply_config = nil
	_G.mya_booga_ui = nil
	_G.mya_booga_notif_ui = nil
end
