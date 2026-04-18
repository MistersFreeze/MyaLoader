--[[
  Paste this entire file into your executor, OR fetch it with loadstring(game:HttpGet(url)).

  After LocalPlayer exists, the loader waits for game.Loaded (and up to ~15s for a non-zero PlaceId)
  before fetching config/hub so the hub mounts the correct game module in-experience.

  Base URL (where config.lua, hub.lua, games/… live):
  - Edit BASE_URL below, OR
  - Set before running: getgenv().MYA_BASE_URL = "https://…/" or "http://127.0.0.1:8080/"

  Local folder over HTTP (no GitHub): from the repo root run:
    python -m http.server 8080
  Then in the executor:
    getgenv().MYA_BASE_URL = "http://127.0.0.1:8080/"
    loadstring(game:HttpGet("http://127.0.0.1:8080/loader.lua", true))()
]]

local BASE_URL = "https://raw.githubusercontent.com/MistersFreeze/MyaLoader/main/"
-- Optional override (e.g. set by loader_jnkie.lua before loading this file).
if typeof(getgenv) == "function" and typeof(getgenv().MYA_BASE_URL) == "string" and #getgenv().MYA_BASE_URL > 0 then
	local u = getgenv().MYA_BASE_URL
	if string.sub(u, -1) ~= "/" then
		u = u .. "/"
	end
	BASE_URL = u
end

local Players = game:GetService("Players")
local localPlayer = Players.LocalPlayer or Players.PlayerAdded:Wait()

--- Wait until Roblox has finished loading the place so PlaceId / HttpGet behave reliably before the hub runs.
local function waitForGameReady()
	if not game:IsLoaded() then
		game.Loaded:Wait()
	end
	-- Joining can briefly report PlaceId 0; wait (Studio may keep 0 — cap wait).
	local deadline = os.clock() + 15
	while game.PlaceId == 0 and os.clock() < deadline do
		task.wait(0.05)
	end
end

local function loaderUiParent()
	if typeof(gethui) == "function" then
		return gethui()
	end
	local ok, cg = pcall(function()
		return game:GetService("CoreGui")
	end)
	if ok and cg then
		return cg
	end
	return localPlayer:WaitForChild("PlayerGui")
end

local function configureLoaderGui(gui)
	gui.IgnoreGuiInset = true
	gui.DisplayOrder = 2147483647
	pcall(function()
		gui.ScreenInsets = Enum.ScreenInsets.None
	end)
end

local function showError(message)
	local existing = localPlayer.PlayerGui:FindFirstChild("MyaLoaderError")
	if existing then
		existing:Destroy()
	end
	local gui = Instance.new("ScreenGui")
	gui.Name = "MyaLoaderError"
	gui.ResetOnSpawn = false
	gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	gui.Parent = loaderUiParent()
	configureLoaderGui(gui)

	local frame = Instance.new("Frame")
	frame.AnchorPoint = Vector2.new(0.5, 0.5)
	frame.Position = UDim2.fromScale(0.5, 0.5)
	frame.Size = UDim2.fromOffset(440, 140)
	frame.BackgroundColor3 = Color3.fromRGB(28, 18, 26)
	frame.Parent = gui
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, 10)
	c.Parent = frame
	local s = Instance.new("UIStroke")
	s.Color = Color3.fromRGB(200, 100, 140)
	s.Parent = frame

	local t = Instance.new("TextLabel")
	t.BackgroundTransparency = 1
	t.Size = UDim2.new(1, -24, 0, 0)
	t.Position = UDim2.new(0, 12, 0, 12)
	t.Font = Enum.Font.GothamMedium
	t.TextSize = 14
	t.TextColor3 = Color3.fromRGB(255, 150, 175)
	t.TextWrapped = true
	t.AutomaticSize = Enum.AutomaticSize.Y
	t.TextXAlignment = Enum.TextXAlignment.Left
	t.TextYAlignment = Enum.TextYAlignment.Top
	t.Text = "[Mya] " .. message
	t.Parent = frame
end

local function boot()
	if typeof(loadstring) ~= "function" then
		error("loadstring is not available in this environment.")
	end

	waitForGameReady()
	-- Let the engine render a frame after long waits (reduces injection hitches).
	task.wait()

	local function get(url)
		return game:HttpGet(url, true)
	end

	local configSrc = get(BASE_URL .. "config.lua")
	task.wait()
	local configChunk = loadstring(configSrc, "@config.lua")
	if typeof(configChunk) ~= "function" then
		error("config.lua failed to compile.")
	end
	local config = configChunk()
	if typeof(config) ~= "table" then
		error("config.lua must return a table.")
	end
	task.wait()

	local okBoot, errBoot = pcall(function()
		local hubSrc = get(BASE_URL .. "hub.lua")
		task.wait()
		local hubChunk = loadstring(hubSrc, "@hub.lua")
		if typeof(hubChunk) ~= "function" then
			error("hub.lua failed to compile.")
		end
		-- hub.lua returns function(BASE_URL, config); first call runs the chunk.
		local hubMain = hubChunk()
		task.wait()
		if typeof(hubMain) ~= "function" then
			error("hub.lua must return a function (return function(BASE_URL, config) ... end).")
		end

		task.wait()
		hubMain(BASE_URL, config)
	end)

	if not okBoot then
		error(errBoot, 0)
	end
end

local ok, err = pcall(boot)
if not ok then
	showError(tostring(err))
end
