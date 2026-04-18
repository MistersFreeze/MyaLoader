--[[
  LOCAL DEV LOADER — no GitHub push. Uses readfile() + MYA_LOCAL_ROOT.

  Waits for game.Loaded (and briefly for a non-zero PlaceId) before loading config/hub, same idea as loader.lua.

  HOW TO RUN (pick one)
  ─────────────────────
  A) One-liner — repo path in a text file (good for teams; path not in script):
     1. Copy mya_local_root.example.txt → mya_local_root.txt
     2. Edit the single line to your Mya clone path (forward slashes, trailing slash).
     3. Put mya_local_root.txt in the executor workspace folder (same place readfile looks).
     4. Run:
        loadstring(readfile("loader_local.lua"), "@loader_local.lua")()

  B) Set path in the executor before loading (no txt file):
        getgenv().MYA_LOCAL_ROOT = "C:/Dev/Mya/"
        loadstring(readfile("loader_local.lua"), "@loader_local.lua")()

  C) Serve the repo with Python (no GitHub): from the Mya folder run:
        python -m http.server 8080
     Then use loader.lua (HttpGet) instead of this file:
        getgenv().MYA_BASE_URL = "http://127.0.0.1:8080/"
        loadstring(game:HttpGet("http://127.0.0.1:8080/loader.lua", true))()

  Requirements: readfile, loadstring, getgenv (optional but recommended).
]]

if typeof(readfile) ~= "function" then
	error("[Mya local] readfile() is required (executor filesystem API).")
end
if typeof(loadstring) ~= "function" then
	error("[Mya local] loadstring is required.")
end

local function normalizeRoot(r)
	local s = r:gsub("\\", "/")
	if string.sub(s, -1) ~= "/" then
		s = s .. "/"
	end
	return s
end

local function resolveLocalRoot()
	if typeof(getgenv) == "function" then
		local g = getgenv()
		if typeof(g.MYA_LOCAL_ROOT) == "string" and #g.MYA_LOCAL_ROOT > 0 then
			return normalizeRoot(g.MYA_LOCAL_ROOT)
		end
	end
	local ok, line = pcall(readfile, "mya_local_root.txt")
	if ok and typeof(line) == "string" then
		line = line:gsub("^%s+", ""):gsub("%s+$", "")
		if #line > 0 then
			return normalizeRoot(line)
		end
	end
	error(
		"Set getgenv().MYA_LOCAL_ROOT = 'C:/path/to/Mya/' before running, "
			.. "or create mya_local_root.txt (one line: path to repo, trailing slash). "
			.. "See mya_local_root.example.txt."
	)
end

local ROOT = resolveLocalRoot()

if typeof(getgenv) == "function" then
	getgenv().MYA_LOCAL_ROOT = ROOT
	getgenv().MYA_BASE_URL = ROOT
end

local function readFromRoot(relativePath)
	relativePath = relativePath:gsub("^/", "")
	local full = ROOT .. relativePath
	local variants = {
		full,
		full:gsub("/", "\\"),
		(ROOT .. relativePath):gsub("\\", "/"),
	}
	for _, p in ipairs(variants) do
		local ok, src = pcall(readfile, p)
		if ok and typeof(src) == "string" and #src > 0 then
			return src
		end
	end
	error("[Mya local] Cannot read: " .. full .. " (check MYA_LOCAL_ROOT / mya_local_root.txt).")
end

local Players = game:GetService("Players")
local localPlayer = Players.LocalPlayer or Players.PlayerAdded:Wait()

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
	Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 10)
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
	t.Text = "[Mya local] " .. message
	t.Parent = frame
end

local function waitForGameReady()
	if not game:IsLoaded() then
		game.Loaded:Wait()
	end
	local deadline = os.clock() + 15
	while game.PlaceId == 0 and os.clock() < deadline do
		task.wait(0.05)
	end
end

local function boot()
	waitForGameReady()

	local configSrc = readFromRoot("config.lua")
	local configChunk = loadstring(configSrc, "@config.lua")
	if typeof(configChunk) ~= "function" then
		error("config.lua failed to compile.")
	end
	local config = configChunk()
	if typeof(config) ~= "table" then
		error("config.lua must return a table.")
	end

	local okBoot, errBoot = pcall(function()
		local hubSrc = readFromRoot("hub.lua")
		local hubChunk = loadstring(hubSrc, "@hub.lua")
		if typeof(hubChunk) ~= "function" then
			error("hub.lua failed to compile.")
		end
		local hubMain = hubChunk()
		if typeof(hubMain) ~= "function" then
			error("hub.lua must return a function.")
		end

		hubMain(ROOT, config)
	end)

	if not okBoot then
		error(errBoot, 0)
	end
end

local ok, err = pcall(boot)
if not ok then
	showError(tostring(err))
end
