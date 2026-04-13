--[[
  JUNKIE (jnkie.com) entry — paste into Dashboard → Lua Scripts → Original Code.

  Junkie CDN expects getgenv().SCRIPT_KEY early. With a KEYLESS dashboard script, use KEYLESS below.
  SHOW_KEY_UI then lets the user type a key before Mya loads (no Kick — errors stay on the UI).

  Docs: https://docs.jnkie.com/roblox-sdk/external-loader
]]

-- Satisfies Junkie's wrapper when your dashboard script is KEYLESS ("No script key provided").
local JUNKIE_PLACEHOLDER_KEY = "KEYLESS"
if typeof(getgenv) == "function" then
	getgenv().SCRIPT_KEY = JUNKIE_PLACEHOLDER_KEY
end

local MYA_BASE_URL = "https://raw.githubusercontent.com/MistersFreeze/MyaLoader/main/"

--------------------------------------------------------------------------------
-- Key gate (in-game TextBox — does not kick you)
--------------------------------------------------------------------------------

local SHOW_KEY_UI = true

-- true = validate with Junkie.check_key (fill service fields from your Junkie dashboard).
local USE_JUNKIE_VALIDATION = true
local JUNKIE_SERVICE = "Mya"
local JUNKIE_IDENTIFIER = "12345"
local JUNKIE_PROVIDER = "Mixed"

-- If USE_JUNKIE_VALIDATION is false: set a non-empty string to require an exact match (simple shared password).
-- Leave "" to only require non-empty input.
local CUSTOM_SECRET = ""

--------------------------------------------------------------------------------

local Players = game:GetService("Players")

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
	gui.DisplayOrder = 1000
	gui.Parent = pg

	local root = Instance.new("Frame")
	root.Name = "Panel"
	root.AnchorPoint = Vector2.new(0.5, 0.5)
	root.Position = UDim2.fromScale(0.5, 0.5)
	root.Size = UDim2.fromOffset(400, 220)
	root.BackgroundColor3 = Color3.fromRGB(26, 27, 38)
	root.Parent = gui

	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, 12)
	c.Parent = root

	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.fromRGB(58, 62, 78)
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
	title.TextColor3 = Color3.fromRGB(230, 232, 242)
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.Text = "Mya · Enter key"
	title.Parent = root

	local hint = Instance.new("TextLabel")
	hint.BackgroundTransparency = 1
	hint.Position = UDim2.new(0, 0, 0, 32)
	hint.Size = UDim2.new(1, 0, 0, 36)
	hint.Font = Enum.Font.GothamMedium
	hint.TextSize = 13
	hint.TextColor3 = Color3.fromRGB(150, 156, 178)
	hint.TextWrapped = true
	hint.TextXAlignment = Enum.TextXAlignment.Left
	hint.TextYAlignment = Enum.TextYAlignment.Top
	hint.Text = "Paste your key below. Wrong keys show here — you are not kicked."
	hint.Parent = root

	local box = Instance.new("TextBox")
	box.Name = "KeyBox"
	box.Position = UDim2.new(0, 0, 0, 78)
	box.Size = UDim2.new(1, 0, 0, 40)
	box.BackgroundColor3 = Color3.fromRGB(34, 36, 48)
	box.ClearTextOnFocus = false
	box.Font = Enum.Font.GothamMedium
	box.TextSize = 14
	box.TextColor3 = Color3.fromRGB(230, 232, 242)
	box.Text = ""
	box.PlaceholderText = "Your access key"
	box.PlaceholderColor3 = Color3.fromRGB(100, 104, 120)
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
	errLabel.TextColor3 = Color3.fromRGB(242, 110, 110)
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
	loadBtn.BackgroundColor3 = Color3.fromRGB(122, 162, 247)
	loadBtn.Text = "Load Mya"
	loadBtn.Font = Enum.Font.GothamBold
	loadBtn.TextSize = 14
	loadBtn.TextColor3 = Color3.fromRGB(20, 22, 30)
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
	closeBtn.BackgroundColor3 = Color3.fromRGB(42, 44, 58)
	closeBtn.Text = "Close"
	closeBtn.Font = Enum.Font.GothamMedium
	closeBtn.TextSize = 14
	closeBtn.TextColor3 = Color3.fromRGB(200, 204, 220)
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
			errGui.Parent = pg
			local f = Instance.new("Frame")
			f.Size = UDim2.fromOffset(380, 100)
			f.Position = UDim2.fromScale(0.5, 0.5)
			f.AnchorPoint = Vector2.new(0.5, 0.5)
			f.BackgroundColor3 = Color3.fromRGB(26, 27, 38)
			f.Parent = errGui
			Instance.new("UICorner", f).CornerRadius = UDim.new(0, 10)
			local t = Instance.new("TextLabel")
			t.Size = UDim2.new(1, -20, 1, -20)
			t.Position = UDim2.new(0, 10, 0, 10)
			t.BackgroundTransparency = 1
			t.TextWrapped = true
			t.Font = Enum.Font.GothamMedium
			t.TextSize = 13
			t.TextColor3 = Color3.fromRGB(242, 110, 110)
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
