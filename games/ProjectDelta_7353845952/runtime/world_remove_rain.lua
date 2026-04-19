-- Mute rain SFX and disable rain particle emitters (name / ancestor heuristics).

local Lighting = game:GetService("Lighting")
local SoundService = game:GetService("SoundService")

local rain_restore = {}
local rain_desc_conn = nil
local rain_last_scan = 0
local RAIN_SCAN_INTERVAL = 2.0

local function name_chain_suggests_rain(inst)
	local p = inst
	for _ = 1, 28 do
		if not p then
			break
		end
		local n = p.Name:lower()
		if
			n:find("rain", 1, true)
			or n:find("precip", 1, true)
			or n:find("downpour", 1, true)
			or n:find("drizzle", 1, true)
			or n:find("rainweather", 1, true)
			or n:find("rain_", 1, true)
			or n:find("rainvfx", 1, true)
		then
			return true
		end
		p = p.Parent
	end
	return false
end

local function try_suppress_rain(inst)
	if rain_restore[inst] or not inst.Parent then
		return
	end
	if not name_chain_suggests_rain(inst) then
		return
	end
	if inst:IsA("ParticleEmitter") then
		rain_restore[inst] = { kind = "pe", enabled = inst.Enabled }
		inst.Enabled = false
	elseif inst:IsA("Sound") then
		rain_restore[inst] = { kind = "snd", volume = inst.Volume, playing = inst.Playing }
		inst.Volume = 0
	elseif inst:IsA("Beam") then
		rain_restore[inst] = { kind = "beam", enabled = inst.Enabled }
		inst.Enabled = false
	end
end

local function scan_root(root)
	if not root then
		return
	end
	local ok, desc = pcall(function()
		return root:GetDescendants()
	end)
	if not ok or type(desc) ~= "table" then
		return
	end
	for i = 1, #desc do
		try_suppress_rain(desc[i])
	end
end

function disconnect_remove_rain_listener()
	if rain_desc_conn then
		pcall(function()
			rain_desc_conn:Disconnect()
		end)
		rain_desc_conn = nil
	end
end

function connect_remove_rain_listener()
	disconnect_remove_rain_listener()
	if not remove_rain_on then
		return
	end
	rain_desc_conn = Workspace.DescendantAdded:Connect(function(inst)
		task.defer(function()
			if remove_rain_on then
				try_suppress_rain(inst)
			end
		end)
	end)
	table.insert(connections, rain_desc_conn)
end

function restore_remove_rain()
	for inst, data in pairs(rain_restore) do
		pcall(function()
			if inst.Parent and data then
				if data.kind == "pe" or data.kind == "beam" then
					inst.Enabled = data.enabled
				elseif data.kind == "snd" then
					inst.Volume = data.volume
				end
			end
		end)
	end
	rain_restore = {}
	disconnect_remove_rain_listener()
	rain_last_scan = 0
end

function sync_remove_rain()
	if not remove_rain_on then
		if next(rain_restore) ~= nil or rain_desc_conn then
			restore_remove_rain()
		end
		return
	end
	local now = os.clock()
	if rain_last_scan ~= 0 and now - rain_last_scan < RAIN_SCAN_INTERVAL then
		return
	end
	rain_last_scan = now
	pcall(function()
		scan_root(Workspace)
	end)
	pcall(function()
		scan_root(Lighting)
	end)
	pcall(function()
		scan_root(SoundService)
	end)
	if not rain_desc_conn then
		connect_remove_rain_listener()
	end
end
