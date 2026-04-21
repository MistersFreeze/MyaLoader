local RunService = game:GetService("RunService")

local saved_colors = {}
local last_vehicle_model = nil
local rainbow_car_conn = nil

local function wipe_saved()
	for k in pairs(saved_colors) do
		saved_colors[k] = nil
	end
end

local function restore_rainbow_car_colors()
	for part, col in pairs(saved_colors) do
		if typeof(part) == "Instance" and part.Parent and part:IsA("BasePart") then
			pcall(function()
				part.Color = col
			end)
		end
	end
	wipe_saved()
	last_vehicle_model = nil
end

local function get_seated_vehicle_model()
	local char = lp.Character
	if not char then
		return nil
	end
	local hum = char:FindFirstChildWhichIsA("Humanoid")
	if not hum then
		return nil
	end
	local seat = hum.SeatPart
	if not seat or not seat:IsA("VehicleSeat") then
		return nil
	end
	return seat:FindFirstAncestorWhichIsA("Model")
end

local function rainbow_car_step()
	if not rainbow_car_on or not _G.MYA_UNIVERSAL_LOADED then
		return
	end
	local model = get_seated_vehicle_model()
	if model ~= last_vehicle_model then
		restore_rainbow_car_colors()
		last_vehicle_model = model
	end
	if not model then
		return
	end
	local hue = (os.clock() * 0.25) % 1
	local color = Color3.fromHSV(hue, 0.92, 1)
	for _, d in ipairs(model:GetDescendants()) do
		if d:IsA("BasePart") then
			if saved_colors[d] == nil then
				saved_colors[d] = d.Color
			end
			pcall(function()
				d.Color = color
			end)
		end
	end
end

function stop_rainbow_car()
	restore_rainbow_car_colors()
	if rainbow_car_conn then
		pcall(function()
			rainbow_car_conn:Disconnect()
		end)
		rainbow_car_conn = nil
	end
end

function start_rainbow_car()
	if rainbow_car_conn then
		return
	end
	last_vehicle_model = nil
	wipe_saved()
	rainbow_car_conn = RunService.Heartbeat:Connect(rainbow_car_step)
	table.insert(connections, rainbow_car_conn)
end
