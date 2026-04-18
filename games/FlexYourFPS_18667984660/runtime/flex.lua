--[[ Flex Your FPS And Ping — billboard display + optional render quality ]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local localPlayer = Players.LocalPlayer or Players.PlayerAdded:Wait()

local fps_frames = 0
local fps_last = os.clock()
local fps_measured = 60

local saved_quality_level = nil
local rs_conn = nil
local char_conn = nil
local pr_conn = nil
local flex_connections = {}

local function flex_track_conn(c)
	if c then
		flex_connections[#flex_connections + 1] = c
	end
end

local function flex_disconnect_all()
	for i = #flex_connections, 1, -1 do
		local c = flex_connections[i]
		flex_connections[i] = nil
		if c and c.Disconnect then
			pcall(function()
				c:Disconnect()
			end)
		end
	end
end

local function get_network_ping_ms()
	local ok, v = pcall(function()
		return localPlayer:GetNetworkPing()
	end)
	if not ok or v == nil then
		return 0
	end
	-- Roblox returns round-trip time in seconds; UI expects whole-number ms.
	return v * 1000
end

local function find_fps_gui(char)
	if not char then
		return nil
	end
	local head = char:FindFirstChild("Head")
	if not head then
		return nil
	end
	return head:FindFirstChild("fpsGui")
end

local function find_ping_label(fpsGui)
	if not fpsGui then
		return nil
	end
	local direct = fpsGui:FindFirstChild("Ping")
		or fpsGui:FindFirstChild("PING")
		or fpsGui:FindFirstChild("MS")
		or fpsGui:FindFirstChild("Ms")
	if direct and (direct:IsA("TextLabel") or direct:IsA("TextButton")) then
		return direct
	end
	for _, d in ipairs(fpsGui:GetDescendants()) do
		if d:IsA("TextLabel") or d:IsA("TextButton") then
			local n = string.lower(d.Name)
			if string.find(n, "ping", 1, true) or n == "ms" then
				return d
			end
		end
	end
	return nil
end

-- Match typical “low FPS = red → high FPS = green” billboard styling using displayed FPS.
local function color_for_fps_display(fps)
	fps = math.max(0, fps)
	local t = math.clamp(fps / 280, 0, 1)
	local h = 0.02 + 0.31 * t
	return Color3.fromHSV(h, 0.9, 1)
end

local function apply_fps_visuals(guiObj, fps)
	local c = color_for_fps_display(fps)
	pcall(function()
		guiObj.TextColor3 = c
	end)
	local stroke = guiObj:FindFirstChildOfClass("UIStroke")
	if stroke then
		pcall(function()
			stroke.Color = Color3.new(
				math.clamp(c.R * 0.65, 0, 1),
				math.clamp(c.G * 0.65, 0, 1),
				math.clamp(c.B * 0.65, 0, 1)
			)
		end)
	end
end

local function find_resolution_label(fpsGui)
	if not fpsGui then
		return nil
	end
	for _, d in ipairs(fpsGui:GetDescendants()) do
		if d:IsA("TextLabel") or d:IsA("TextButton") then
			local n = string.lower(d.Name)
			if string.find(n, "res", 1, true) or string.find(n, "display", 1, true) then
				return d
			end
		end
	end
	return fpsGui:FindFirstChild("Resolution") or fpsGui:FindFirstChild("Res")
end

local function apply_render_quality_from_mult(mult)
	mult = math.clamp(tonumber(mult) or 1, 0.1, 10)
	local q = math.clamp(math.floor(1 + (mult - 0.1) / (10 - 0.1) * 20), 1, 21)
	pcall(function()
		settings().Rendering.QualityLevel = q
	end)
end

local function restore_render_quality()
	if saved_quality_level ~= nil then
		pcall(function()
			settings().Rendering.QualityLevel = saved_quality_level
		end)
		saved_quality_level = nil
	end
end

local function step_labels()
	if unloaded or not flex_enabled then
		return
	end
	local char = localPlayer.Character
	local fpsGui = find_fps_gui(char)
	if not fpsGui then
		return
	end
	local fpsLbl = fpsGui:FindFirstChild("FPS")
	if fpsLbl and (fpsLbl:IsA("TextLabel") or fpsLbl:IsA("TextButton")) then
		local m = math.clamp(flex_fps_mult, 1, 15)
		local show = math.max(0, math.floor(fps_measured * m + 0.5))
		fpsLbl.Text = tostring(show)
		apply_fps_visuals(fpsLbl, show)
	end
	local pingLbl = find_ping_label(fpsGui)
	if pingLbl then
		local m = math.clamp(flex_ping_mult, 0.1, 10)
		local base = get_network_ping_ms()
		local show = math.max(0, math.floor(base * m + 0.5))
		pingLbl.Text = tostring(show)
	end
	local resLbl = find_resolution_label(fpsGui)
	local cam = workspace.CurrentCamera
	if resLbl and cam then
		local m = math.clamp(flex_res_mult, 0.1, 10)
		local vs = cam.ViewportSize
		local w = math.max(1, math.floor(vs.X * m + 0.5))
		local h = math.max(1, math.floor(vs.Y * m + 0.5))
		resLbl.Text = w .. "x" .. h
	end
end

local flex_loop_started = false

local function start_flex_loop()
	if flex_loop_started then
		return
	end
	flex_loop_started = true
	flex_disconnect_all()
	local bound = false
	pcall(function()
		RunService:BindToRenderStep("MyaFlexFPSLabels", Enum.RenderPriority.Last.Value, step_labels)
		bound = true
	end)
	if bound then
		rs_conn = {
			Disconnect = function()
				pcall(function()
					RunService:UnbindFromRenderStep("MyaFlexFPSLabels")
				end)
			end,
		}
	else
		rs_conn = RunService.RenderStepped:Connect(step_labels)
	end
	flex_track_conn(rs_conn)

	pr_conn = RunService.PreRender:Connect(function()
		fps_frames = fps_frames + 1
		local t = os.clock()
		if t - fps_last >= 1 then
			fps_measured = fps_frames
			fps_frames = 0
			fps_last = t
		end
	end)
	flex_track_conn(pr_conn)

	char_conn = localPlayer.CharacterAdded:Connect(function()
		task.defer(step_labels)
	end)
	flex_track_conn(char_conn)
end

local function stop_flex_loop()
	flex_loop_started = false
	flex_disconnect_all()
	rs_conn, pr_conn, char_conn = nil, nil, nil
end

local function unload_flex()
	unloaded = true
	flex_enabled = false
	stop_flex_loop()
	restore_render_quality()
	if _G.user_interface then
		pcall(function()
			_G.user_interface:Destroy()
		end)
		_G.user_interface = nil
	end
	_G.MYA_FLEX_FPS = nil
	_G.MYA_FLEX_RUN_UI_SYNC = nil
	_G.unload_mya = nil
end

function start_flex_runtime()
	pcall(function()
		saved_quality_level = settings().Rendering.QualityLevel
	end)
	apply_render_quality_from_mult(flex_res_mult)
	start_flex_loop()
end

_G.MYA_FLEX_FPS = {
	start_flex_runtime = start_flex_runtime,
	set_fps_mult = function(v)
		flex_fps_mult = math.clamp(tonumber(v) or 1, 1, 15)
	end,
	get_fps_mult = function()
		return flex_fps_mult
	end,
	set_ping_mult = function(v)
		flex_ping_mult = math.clamp(tonumber(v) or 1, 0.1, 10)
	end,
	get_ping_mult = function()
		return flex_ping_mult
	end,
	set_res_mult = function(v)
		flex_res_mult = math.clamp(tonumber(v) or 1, 0.1, 10)
		apply_render_quality_from_mult(flex_res_mult)
	end,
	get_res_mult = function()
		return flex_res_mult
	end,
	set_flex_enabled = function(v)
		flex_enabled = not not v
	end,
	get_flex_enabled = function()
		return flex_enabled
	end,
	unload = unload_flex,
}

_G.unload_mya = unload_flex
