--[[
  Paste this entire file into your executor, OR host it and loadstring(game:HttpGet(url)).
  Set BASE_URL to your raw GitHub (or other static) root where Mya files are hosted.
  Example: https://raw.githubusercontent.com/MistersFreeze/MyaLoader/main/
]]

local BASE_URL = "https://raw.githubusercontent.com/MistersFreeze/MyaLoader/main/"

local Players = game:GetService("Players")
local localPlayer = Players.LocalPlayer or Players.PlayerAdded:Wait()

local function showError(message: string)
	local existing = localPlayer.PlayerGui:FindFirstChild("MyaLoaderError")
	if existing then
		existing:Destroy()
	end
	local gui = Instance.new("ScreenGui")
	gui.Name = "MyaLoaderError"
	gui.ResetOnSpawn = false
	gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	gui.Parent = localPlayer:WaitForChild("PlayerGui")

	local frame = Instance.new("Frame")
	frame.AnchorPoint = Vector2.new(0.5, 0.5)
	frame.Position = UDim2.fromScale(0.5, 0.5)
	frame.Size = UDim2.fromOffset(420, 120)
	frame.BackgroundColor3 = Color3.fromRGB(26, 27, 38)
	frame.Parent = gui
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, 10)
	c.Parent = frame
	local s = Instance.new("UIStroke")
	s.Color = Color3.fromRGB(58, 62, 78)
	s.Parent = frame

	local t = Instance.new("TextLabel")
	t.BackgroundTransparency = 1
	t.Size = UDim2.new(1, -24, 1, -24)
	t.Position = UDim2.new(0, 12, 0, 12)
	t.Font = Enum.Font.GothamMedium
	t.TextSize = 14
	t.TextColor3 = Color3.fromRGB(242, 110, 110)
	t.TextWrapped = true
	t.TextXAlignment = Enum.TextXAlignment.Left
	t.TextYAlignment = Enum.TextYAlignment.Top
	t.Text = "[Mya] " .. message
	t.Parent = frame
end

local function boot()
	if typeof(loadstring) ~= "function" then
		error("loadstring is not available in this environment.")
	end

	local function get(url: string)
		return game:HttpGet(url, true)
	end

	local configSrc = get(BASE_URL .. "config.lua")
	local configChunk = loadstring(configSrc, "@config.lua")
	if typeof(configChunk) ~= "function" then
		error("config.lua failed to compile.")
	end
	local config = configChunk()
	if typeof(config) ~= "table" then
		error("config.lua must return a table.")
	end

	local hubSrc = get(BASE_URL .. "hub.lua")
	local hubChunk = loadstring(hubSrc, "@hub.lua")
	if typeof(hubChunk) ~= "function" then
		error("hub.lua failed to compile.")
	end
	-- hub.lua returns function(BASE_URL, config); first call runs the chunk.
	local hubMain = hubChunk()
	if typeof(hubMain) ~= "function" then
		error("hub.lua must return a function (return function(BASE_URL, config) ... end).")
	end

	hubMain(BASE_URL, config)
end

local ok, err = pcall(boot)
if not ok then
	showError(tostring(err))
end
