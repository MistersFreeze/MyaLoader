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
	for key in pairs(survivor_highlights) do
		cleanup_key(survivor_highlights, key)
	end
	for key in pairs(killer_highlights) do
		cleanup_key(killer_highlights, key)
	end
	for key in pairs(generator_highlights) do
		cleanup_key(generator_highlights, key)
	end
	for key in pairs(battery_highlights) do
		cleanup_key(battery_highlights, key)
	end
	if highlights_folder and highlights_folder.Parent then
		highlights_folder:Destroy()
	end
end

function api.get_survivor_esp()
	return settings.survivor_esp
end
function api.set_survivor_esp(v)
	set_flag("survivor_esp", v)
end

function api.get_killer_esp()
	return settings.killer_esp
end
function api.set_killer_esp(v)
	set_flag("killer_esp", v)
end

function api.get_generator_esp()
	return settings.generator_esp
end
function api.set_generator_esp(v)
	set_flag("generator_esp", v)
end

function api.get_batteries_esp()
	return settings.batteries_esp
end
function api.set_batteries_esp(v)
	set_flag("batteries_esp", v)
end

_G.MYA_BITE = api

function _G.unload_mya_bite()
	pcall(function()
		api.stop()
	end)
	local ui = _G.mya_bite_ui
	if typeof(ui) == "Instance" and ui.Parent then
		pcall(function()
			ui:Destroy()
		end)
	end
	local notif_ui = _G.mya_bite_notif_ui
	if typeof(notif_ui) == "Instance" and notif_ui.Parent then
		pcall(function()
			notif_ui:Destroy()
		end)
	end
	_G.MYA_BITE = nil
	_G.MYA_BITE_SYNC_UI = nil
	_G.mya_bite_ui = nil
	_G.mya_bite_notif_ui = nil
end

