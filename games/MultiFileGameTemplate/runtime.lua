--[[
  Mya multi-file template — logic layer. gui.lua expects _G.MYA_TEMPLATE.
  Replace this file with your game hooks (Remotes, Heartbeat, etc.).
]]

if _G.MYA_TEMPLATE_LOADED then
	return
end
_G.MYA_TEMPLATE_LOADED = true

local T = {
	demo_enabled = false,
	demo_value = 50,
}

local connections = {}
local gui_unload = nil

function T.set_demo_enabled(v)
	T.demo_enabled = not not v
end

function T.get_demo_enabled()
	return T.demo_enabled
end

function T.set_demo_value(v)
	T.demo_value = math.clamp(math.floor(tonumber(v) or 0), 0, 100)
end

function T.get_demo_value()
	return T.demo_value
end

function T.register_gui_unload(fn)
	gui_unload = fn
end

function T.push_connection(c)
	if typeof(c) == "RBXScriptConnection" then
		table.insert(connections, c)
	end
end

local function cleanup()
	for _, c in ipairs(connections) do
		pcall(function()
			c:Disconnect()
		end)
	end
	connections = {}
	if gui_unload then
		pcall(gui_unload)
		gui_unload = nil
	end
end

function T.unload_all()
	cleanup()
	_G.MYA_TEMPLATE_LOADED = nil
	_G.MYA_TEMPLATE = nil
	_G.MYA_TEMPLATE_RUN_GUI_SYNC = nil
	_G.unload_mya = nil
	_G.user_interface = nil
end

_G.MYA_TEMPLATE = T
_G.unload_mya = T.unload_all
