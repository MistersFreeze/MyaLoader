--[[
  JUNKIE (jnkie.com) entry — paste into Dashboard → Lua Scripts → Original Code.

  IMPORTANT — Junkie runs BEFORE this file’s body:
  - If your script is KEYED, set JUNKIE_LICENSE_KEY below to your UUID. Junkie checks SCRIPT_KEY
    (and often HWID) immediately — do NOT rely on the in-game key box for Junkie’s own check.
  - Error "Invalid key … reset HWID" → key is wrong/expired, or HWID mismatch. In Junkie dashboard:
    open the key → Reset HWID / generate a new key for this PC.
  - JUNKIE_SERVICE / JUNKIE_IDENTIFIER must match your Lua Script on Junkie exactly (not "Mya"/"12345"
    unless that is what your dashboard shows).

  Running ONLY the raw CDN URL (no this file): execute TWO lines in order in your executor:
    getgenv().SCRIPT_KEY = "your-uuid-here"
    loadstring(game:HttpGet("https://api.jnkie.com/.../download", true))()

  Dev key without committing it to Git: set TRY_LOAD_KEY_FROM_FILE = true and put your UUID alone
  in mya_junkie_key.txt next to this script (executor readfile). That file is gitignored.

  Docs: https://docs.jnkie.com/roblox-sdk/external-loader
]]

--------------------------------------------------------------------------------
-- Option A: paste key here (leave "" when pushing to a public repo).
-- Option B: TRY_LOAD_KEY_FROM_FILE + mya_junkie_key.txt (one line, your UUID only).
--------------------------------------------------------------------------------
local JUNKIE_LICENSE_KEY = ""

-- If true and JUNKIE_LICENSE_KEY is empty, tries readfile("mya_junkie_key.txt") (Synapse etc.).
local TRY_LOAD_KEY_FROM_FILE = true
local JUNKIE_KEY_FILE = "mya_junkie_key.txt"

if TRY_LOAD_KEY_FROM_FILE and JUNKIE_LICENSE_KEY == "" and typeof(readfile) == "function" then
	local ok, contents = pcall(function()
		return readfile(JUNKIE_KEY_FILE)
	end)
	if ok and typeof(contents) == "string" and #contents > 0 then
		local trimmed = contents:gsub("^%s+", ""):gsub("%s+$", "")
		if #trimmed >= 8 then
			JUNKIE_LICENSE_KEY = trimmed
		end
	end
end

--------------------------------------------------------------------------------
local MYA_BASE_URL = "https://raw.githubusercontent.com/MistersFreeze/MyaLoader/main/"

--------------------------------------------------------------------------------
-- Must match your Junkie dashboard → Lua Script → service / identifier (copy from there).
--------------------------------------------------------------------------------
local USE_JUNKIE_VALIDATION = true
local JUNKIE_SERVICE = "Mya"
local JUNKIE_IDENTIFIER = "22735"
local JUNKIE_PROVIDER = "Mixed"

--------------------------------------------------------------------------------
-- Key gate: only used when JUNKIE_LICENSE_KEY is empty and you want users to type a key.
-- For Junkie’s own validation, prefer JUNKIE_LICENSE_KEY above (in-game UI runs too late for Junkie CDN).
--------------------------------------------------------------------------------

local SHOW_KEY_UI = false

-- If USE_JUNKIE_VALIDATION is false: set a non-empty string for a simple shared password.
local CUSTOM_SECRET = ""

-- First line Junkie sees: real key, KEYLESS for keyless products, or nothing.
if typeof(getgenv) == "function" then
	if JUNKIE_LICENSE_KEY ~= "" then
		getgenv().SCRIPT_KEY = JUNKIE_LICENSE_KEY
	else
		getgenv().SCRIPT_KEY = "KEYLESS"
	end
end

--------------------------------------------------------------------------------

local Players = game:GetService("Players")

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
	local lp = Players.LocalPlayer or Players.PlayerAdded:Wait()
	return lp:WaitForChild("PlayerGui")
end

local function configureLoaderGui(gui)
	gui.IgnoreGuiInset = true
	gui.DisplayOrder = 2147483647
	pcall(function()
		gui.ScreenInsets = Enum.ScreenInsets.None
	end)
end

local function get(url: string)
	return game:HttpGet(url, true)
end

local function runMyaLoader()
	if typeof(getgenv) ~= "function" then
		error("getgenv is not available.")
	end
	if typeof(loadstring) ~= "function" then
		error("loadstring is not available.")
	end

	getgenv().MYA_BASE_URL = MYA_BASE_URL

	local src = get(MYA_BASE_URL .. "loader.lua")
	local chunk = loadstring(src, "@loader.lua")
	if typeof(chunk) ~= "function" then
		error("loader.lua failed to compile.")
	end
	chunk()
end

local function tryValidateKey(key: string): (boolean, string)
	local trimmed = key:gsub("^%s+", ""):gsub("%s+$", "")
	if #trimmed == 0 then
		return false, "Enter your key."
	end

	if USE_JUNKIE_VALIDATION then
		local ok, JunkieOrErr = pcall(function()
			return loadstring(get("https://jnkie.com/sdk/library.lua"), "@junkie_sdk")()
		end)
		if not ok then
			return false, "Could not load Junkie SDK: " .. tostring(JunkieOrErr)
		end
		local Junkie = JunkieOrErr
		Junkie.service = JUNKIE_SERVICE
		Junkie.identifier = JUNKIE_IDENTIFIER
		Junkie.provider = JUNKIE_PROVIDER

		local v = Junkie.check_key(trimmed)
		if v and v.valid then
			return true, trimmed
		end
		local err = (v and (v.message or v.error)) or "Invalid key"
		return false, tostring(err)
	end

	if CUSTOM_SECRET ~= "" and trimmed ~= CUSTOM_SECRET then
		return false, "Wrong key."
	end

	return true, trimmed
end

local function showKeyGate()
	local lp = Players.LocalPlayer or Players.PlayerAdded:Wait()
	local pg = lp:WaitForChild("PlayerGui")

	local existing = pg:FindFirstChild("MyaKeyGate")
	if existing then
		existing:Destroy()
	end

	local gui = Instance.new("ScreenGui")
	gui.Name = "MyaKeyGate"
	gui.ResetOnSpawn = false
	gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	gui.Parent = loaderUiParent()
	configureLoaderGui(gui)

	local root = Instance.new("Frame")
	root.Name = "Panel"
	root.AnchorPoint = Vector2.new(0.5, 0.5)
	root.Position = UDim2.fromScale(0.5, 0.5)
	root.Size = UDim2.fromOffset(400, 220)
	root.BackgroundColor3 = Color3.fromRGB(28, 18, 26)
	root.Parent = gui

	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, 12)
	c.Parent = root

	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.fromRGB(200, 100, 140)
	stroke.Parent = root

	local pad = Instance.new("UIPadding")
	pad.PaddingLeft = UDim.new(0, 18)
	pad.PaddingRight = UDim.new(0, 18)
	pad.PaddingTop = UDim.new(0, 16)
	pad.PaddingBottom = UDim.new(0, 16)
	pad.Parent = root

	local title = Instance.new("TextLabel")
	title.BackgroundTransparency = 1
	title.Size = UDim2.new(1, 0, 0, 28)
	title.Font = Enum.Font.GothamBold
	title.TextSize = 18
	title.TextColor3 = Color3.fromRGB(255, 228, 238)
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.Text = "Mya · Enter key"
	title.Parent = root

	local hint = Instance.new("TextLabel")
	hint.BackgroundTransparency = 1
	hint.Position = UDim2.new(0, 0, 0, 32)
	hint.Size = UDim2.new(1, 0, 0, 36)
	hint.Font = Enum.Font.GothamMedium
	hint.TextSize = 13
	hint.TextColor3 = Color3.fromRGB(200, 160, 182)
	hint.TextWrapped = true
	hint.TextXAlignment = Enum.TextXAlignment.Left
	hint.TextYAlignment = Enum.TextYAlignment.Top
	hint.Text = "Paste your key below. Wrong keys show here — you are not kicked."
	hint.Parent = root

	local box = Instance.new("TextBox")
	box.Name = "KeyBox"
	box.Position = UDim2.new(0, 0, 0, 78)
	box.Size = UDim2.new(1, 0, 0, 40)
	box.BackgroundColor3 = Color3.fromRGB(38, 24, 34)
	box.ClearTextOnFocus = false
	box.Font = Enum.Font.GothamMedium
	box.TextSize = 14
	box.TextColor3 = Color3.fromRGB(255, 228, 238)
	box.Text = ""
	box.PlaceholderText = "Your access key"
	box.PlaceholderColor3 = Color3.fromRGB(140, 110, 128)
	box.Parent = root

	local boxCorner = Instance.new("UICorner")
	boxCorner.CornerRadius = UDim.new(0, 8)
	boxCorner.Parent = box

	local errLabel = Instance.new("TextLabel")
	errLabel.Name = "Error"
	errLabel.BackgroundTransparency = 1
	errLabel.Position = UDim2.new(0, 0, 0, 124)
	errLabel.Size = UDim2.new(1, 0, 0, 32)
	errLabel.Font = Enum.Font.GothamMedium
	errLabel.TextSize = 12
	errLabel.TextColor3 = Color3.fromRGB(255, 150, 175)
	errLabel.TextWrapped = true
	errLabel.TextXAlignment = Enum.TextXAlignment.Left
	errLabel.TextYAlignment = Enum.TextYAlignment.Top
	errLabel.Text = ""
	errLabel.Parent = root

	local row = Instance.new("Frame")
	row.BackgroundTransparency = 1
	row.Position = UDim2.new(0, 0, 1, -40)
	row.Size = UDim2.new(1, 0, 0, 36)
	row.AnchorPoint = Vector2.new(0, 1)
	row.Parent = root

	local loadBtn = Instance.new("TextButton")
	loadBtn.Name = "Load"
	loadBtn.Size = UDim2.new(0.48, -6, 1, 0)
	loadBtn.BackgroundColor3 = Color3.fromRGB(240, 130, 175)
	loadBtn.Text = "Load Mya"
	loadBtn.Font = Enum.Font.GothamBold
	loadBtn.TextSize = 14
	loadBtn.TextColor3 = Color3.fromRGB(40, 18, 32)
	loadBtn.AutoButtonColor = true
	loadBtn.Parent = row

	local lb = Instance.new("UICorner")
	lb.CornerRadius = UDim.new(0, 8)
	lb.Parent = loadBtn

	local closeBtn = Instance.new("TextButton")
	closeBtn.Name = "Close"
	closeBtn.Position = UDim2.new(1, 0, 0, 0)
	closeBtn.AnchorPoint = Vector2.new(1, 0)
	closeBtn.Size = UDim2.new(0.48, -6, 1, 0)
	closeBtn.BackgroundColor3 = Color3.fromRGB(48, 30, 42)
	closeBtn.Text = "Close"
	closeBtn.Font = Enum.Font.GothamMedium
	closeBtn.TextSize = 14
	closeBtn.TextColor3 = Color3.fromRGB(255, 220, 232)
	closeBtn.AutoButtonColor = true
	closeBtn.Parent = row

	local cb = Instance.new("UICorner")
	cb.CornerRadius = UDim.new(0, 8)
	cb.Parent = closeBtn

	local function onSubmit()
		errLabel.Text = ""
		local ok, resOrKey = tryValidateKey(box.Text)
		if not ok then
			errLabel.Text = resOrKey
			return
		end

		if typeof(getgenv) == "function" then
			getgenv().SCRIPT_KEY = resOrKey
		end

		gui:Destroy()

		local runOk, runErr = pcall(runMyaLoader)
		if not runOk then
			warn("[Mya] " .. tostring(runErr))
			local errGui = Instance.new("ScreenGui")
			errGui.Name = "MyaLoadError"
			errGui.ResetOnSpawn = false
			errGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
			errGui.Parent = loaderUiParent()
			configureLoaderGui(errGui)
			local f = Instance.new("Frame")
			f.Size = UDim2.fromOffset(380, 100)
			f.Position = UDim2.fromScale(0.5, 0.5)
			f.AnchorPoint = Vector2.new(0.5, 0.5)
			f.BackgroundColor3 = Color3.fromRGB(28, 18, 26)
			f.Parent = errGui
			Instance.new("UICorner", f).CornerRadius = UDim.new(0, 10)
			local t = Instance.new("TextLabel")
			t.Size = UDim2.new(1, -20, 1, -20)
			t.Position = UDim2.new(0, 10, 0, 10)
			t.BackgroundTransparency = 1
			t.TextWrapped = true
			t.Font = Enum.Font.GothamMedium
			t.TextSize = 13
			t.TextColor3 = Color3.fromRGB(255, 150, 175)
			t.Text = tostring(runErr)
			t.Parent = f
		end
	end

	loadBtn.MouseButton1Click:Connect(onSubmit)

	box.FocusLost:Connect(function(enter: boolean)
		if enter then
			onSubmit()
		end
	end)

	closeBtn.MouseButton1Click:Connect(function()
		gui:Destroy()
	end)
end

if SHOW_KEY_UI then
	showKeyGate()
else
	local ok, err = pcall(runMyaLoader)
	if not ok then
		warn("[Mya] " .. tostring(err))
	end
end
