--[[
  Hub UI: loads lib via HttpGet, builds window, mounts per-game module by PlaceId.
  Invoked as: loadstring(src)()(BASE_URL, config)
]]

return function(BASE_URL: string, config: { [string]: any })
	local Players = game:GetService("Players")
	local UserInputService = game:GetService("UserInputService")
	local TweenService = game:GetService("TweenService")

	local localPlayer = Players.LocalPlayer
	if not localPlayer then
		localPlayer = Players.PlayerAdded:Wait()
	end

	local utilSrc, uErr = (function()
		local ok, r = pcall(function()
			return game:HttpGet(BASE_URL .. "lib/util.lua", true)
		end)
		if ok then
			return r, nil
		end
		return nil, tostring(r)
	end)()
	if not utilSrc then
		error("[Mya] Failed to load lib/util.lua: " .. tostring(uErr))
	end

	local loadUtilFn = loadstring(utilSrc, "@lib/util.lua")
	if typeof(loadUtilFn) ~= "function" then
		error("[Mya] lib/util.lua did not compile")
	end
	local Util = loadUtilFn()

	local uiSrc, uiErr = Util.httpGet(BASE_URL .. "lib/ui.lua")
	if not uiSrc then
		error("[Mya] Failed to load lib/ui.lua: " .. tostring(uiErr))
	end
	local loadUiChunk = loadstring(uiSrc, "@lib/ui.lua")
	if typeof(loadUiChunk) ~= "function" then
		error("[Mya] lib/ui.lua did not compile")
	end
	local makeUi = loadUiChunk()
	if typeof(makeUi) ~= "function" then
		error("[Mya] lib/ui.lua must return function(theme) ... end")
	end
	local theme = config.THEME
	local UI = makeUi(theme)

	local existing = localPlayer:FindFirstChild("MyaHub")
	if existing then
		existing:Destroy()
	end

	local gui = Instance.new("ScreenGui")
	gui.Name = "MyaHub"
	gui.ResetOnSpawn = false
	gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	gui.Parent = localPlayer:WaitForChild("PlayerGui")

	local root = Instance.new("Frame")
	root.Name = "Window"
	root.AnchorPoint = Vector2.new(0.5, 0.5)
	root.Position = UDim2.fromScale(0.5, 0.5)
	root.Size = UDim2.fromOffset(540, 400)
	root.BackgroundColor3 = theme.bg
	root.Active = true
	root.Selectable = true
	root.Parent = gui
	UI.corner(root)
	UI.stroke(root)

	local titleBar = Instance.new("Frame")
	titleBar.Name = "TitleBar"
	titleBar.BackgroundColor3 = theme.bgElevated
	titleBar.Size = UDim2.new(1, 0, 0, 44)
	titleBar.Parent = root
	UI.corner(titleBar)
	local titleRound = titleBar:FindFirstChildOfClass("UICorner")
	if titleRound then
		titleBar.ClipsDescendants = true
	end

	local titleText = Instance.new("TextLabel")
	titleText.BackgroundTransparency = 1
	titleText.Position = UDim2.new(0, 14, 0, 0)
	titleText.Size = UDim2.new(1, -120, 1, 0)
	titleText.Font = Enum.Font.GothamBold
	titleText.TextSize = 16
	titleText.TextXAlignment = Enum.TextXAlignment.Left
	titleText.TextColor3 = theme.text
	titleText.Text = config.BRAND .. "  ·  " .. tostring(config.VERSION or "")
	titleText.Parent = titleBar

	local btnRow = Instance.new("Frame")
	btnRow.BackgroundTransparency = 1
	btnRow.AnchorPoint = Vector2.new(1, 0.5)
	btnRow.Position = UDim2.new(1, -8, 0.5, 0)
	btnRow.Size = UDim2.new(0, 72, 0, 28)
	btnRow.Parent = titleBar

	local minBtn = Instance.new("TextButton")
	minBtn.Size = UDim2.new(0, 32, 1, 0)
	minBtn.Position = UDim2.new(0, 0, 0, 0)
	minBtn.BackgroundColor3 = theme.surface
	minBtn.Text = "—"
	minBtn.TextColor3 = theme.textMuted
	minBtn.Font = Enum.Font.GothamBold
	minBtn.TextSize = 14
	minBtn.AutoButtonColor = false
	minBtn.Parent = btnRow
	UI.corner(minBtn)

	local closeBtn = Instance.new("TextButton")
	closeBtn.Size = UDim2.new(0, 32, 1, 0)
	closeBtn.Position = UDim2.new(1, 0, 0, 0)
	closeBtn.AnchorPoint = Vector2.new(1, 0)
	closeBtn.BackgroundColor3 = theme.surface
	closeBtn.Text = "×"
	closeBtn.TextColor3 = theme.danger
	closeBtn.Font = Enum.Font.GothamBold
	closeBtn.TextSize = 18
	closeBtn.AutoButtonColor = false
	closeBtn.Parent = btnRow
	UI.corner(closeBtn)

	local body = Instance.new("Frame")
	body.Name = "Body"
	body.BackgroundTransparency = 1
	body.Position = UDim2.new(0, 0, 0, 44)
	body.Size = UDim2.new(1, 0, 1, -44)
	body.Parent = root

	local sidebar = Instance.new("Frame")
	sidebar.Name = "Sidebar"
	sidebar.BackgroundColor3 = theme.bg
	sidebar.Size = UDim2.new(0, 132, 1, -16)
	sidebar.Position = UDim2.new(0, 10, 0, 8)
	sidebar.Parent = body

	local sideLayout = Instance.new("UIListLayout")
	sideLayout.SortOrder = Enum.SortOrder.LayoutOrder
	sideLayout.Padding = UDim.new(0, 6)
	sideLayout.Parent = sidebar

	local content = Instance.new("Frame")
	content.Name = "Content"
	content.BackgroundTransparency = 1
	content.Position = UDim2.new(0, 152, 0, 8)
	content.Size = UDim2.new(1, -162, 1, -52)
	content.Parent = body

	local statusBar = Instance.new("Frame")
	statusBar.Name = "Status"
	statusBar.BackgroundColor3 = theme.bgElevated
	statusBar.AnchorPoint = Vector2.new(0, 1)
	statusBar.Position = UDim2.new(0, 10, 1, -8)
	statusBar.Size = UDim2.new(1, -20, 0, 26)
	statusBar.Parent = body
	UI.corner(statusBar)
	local statusLabel = UI.label(statusBar, "Ready", 13, true)
	statusLabel.Position = UDim2.new(0, 10, 0, 0)
	statusLabel.Size = UDim2.new(1, -20, 1, 0)
	statusLabel.TextYAlignment = Enum.TextYAlignment.Center

	local function notify(msg: string)
		statusLabel.Text = tostring(msg)
	end

	local tabs: { [string]: Frame } = {}
	local tabButtons: { [string]: TextButton } = {}

	local function setTab(name: string)
		for n, f in pairs(tabs) do
			f.Visible = (n == name)
		end
		for n, b in pairs(tabButtons) do
			local on = (n == name)
			b.BackgroundColor3 = if on then theme.surface else theme.bgElevated
			b.TextColor3 = if on then theme.accent else theme.textMuted
		end
	end

	local function makeTab(id: string, label: string)
		local b = Instance.new("TextButton")
		b.Name = id
		b.Size = UDim2.new(1, -8, 0, 34)
		b.BackgroundColor3 = theme.bgElevated
		b.Text = label
		b.Font = Enum.Font.GothamMedium
		b.TextSize = 14
		b.TextColor3 = theme.textMuted
		b.AutoButtonColor = false
		b.Parent = sidebar
		UI.corner(b)
		tabButtons[id] = b
		b.MouseButton1Click:Connect(function()
			setTab(id)
		end)

		local page = Instance.new("Frame")
		page.Name = id .. "Page"
		page.BackgroundTransparency = 1
		page.Size = UDim2.new(1, 0, 1, 0)
		page.Visible = false
		page.Parent = content
		tabs[id] = page
		return page
	end

	local homePage = makeTab("home", "Home")
	local gamesPage = makeTab("games", "Games")
	local settingsPage = makeTab("settings", "Settings")

	local homeScroll = UI.scroll(homePage)
	homeScroll.Size = UDim2.new(1, 0, 1, 0)

	local homeCard = UI.card(homeScroll)
	homeCard.Size = UDim2.new(1, -4, 0, 0)
	UI.label(homeCard, "Welcome to " .. config.BRAND, 18, false)
	UI.label(
		homeCard,
		"This hub loads game-specific features when your PlaceId is listed in config. Use the Games tab to see support status for the current experience.",
		14,
		true
	)

	local placeLabel = UI.label(homeCard, "PlaceId: " .. tostring(game.PlaceId), 14, false)

	local gamesScroll = UI.scroll(gamesPage)
	gamesScroll.Size = UDim2.new(1, 0, 1, 0)

	local gamesCard = UI.card(gamesScroll)
	gamesCard.Size = UDim2.new(1, -4, 0, 0)

	local gamePanel = Instance.new("Frame")
	gamePanel.Name = "GamePanel"
	gamePanel.BackgroundTransparency = 1
	gamePanel.Size = UDim2.new(1, 0, 0, 0)
	gamePanel.AutomaticSize = Enum.AutomaticSize.Y
	gamePanel.LayoutOrder = 1
	gamePanel.Parent = gamesCard

	local gameLayout = Instance.new("UIListLayout")
	gameLayout.SortOrder = Enum.SortOrder.LayoutOrder
	gameLayout.Padding = UDim.new(0, 8)
	gameLayout.Parent = gamePanel

	local settingsScroll = UI.scroll(settingsPage)
	settingsScroll.Size = UDim2.new(1, 0, 1, 0)
	local settingsCard = UI.card(settingsScroll)
	settingsCard.Size = UDim2.new(1, -4, 0, 0)
	UI.label(settingsCard, "Loader base URL (set in loader.lua on your client):", 14, true)
	local urlHint = UI.label(settingsCard, BASE_URL, 13, false)
	urlHint.TextWrapped = true

	local mountedModule: any = nil
	local placeId = game.PlaceId
	local supported = config.SUPPORTED_GAMES or {}
	local gamePath = supported[placeId]

	local supportTitle = UI.label(gamesCard, "", 16, false)
	supportTitle.LayoutOrder = 0

	local function clearGameMount()
		if mountedModule and typeof(mountedModule.unmount) == "function" then
			local ok, err = pcall(function()
				mountedModule.unmount()
			end)
			if not ok then
				notify("Unmount error: " .. tostring(err))
			end
		end
		mountedModule = nil
		for _, c in pairs(gamePanel:GetChildren()) do
			if not c:IsA("UIListLayout") then
				c:Destroy()
			end
		end
	end

	local function tryMountGame()
		clearGameMount()
		if not gamePath then
			supportTitle.Text = "Unsupported experience"
			UI.label(gamePanel, "No module is registered for PlaceId " .. tostring(placeId) .. ".", 14, true)
			UI.label(gamePanel, "Add an entry to SUPPORTED_GAMES in config.lua and host the matching file under games/.", 14, true)
			notify("Unsupported PlaceId")
			return
		end

		supportTitle.Text = "Supported · loading module…"
		notify("Loading game module…")

		local url = BASE_URL .. gamePath
		local mod, err = Util.loadModuleFromUrl(url, gamePath)
		if not mod then
			supportTitle.Text = "Load failed"
			UI.label(gamePanel, tostring(err), 14, true)
			notify("Game module error")
			return
		end

		if typeof(mod.mount) ~= "function" then
			supportTitle.Text = "Invalid module"
			UI.label(gamePanel, "Game module must export mount(context).", 14, true)
			return
		end

		supportTitle.Text = "Supported · " .. gamePath

		local ctx = {
			panel = gamePanel,
			notify = notify,
			getPlaceId = function()
				return placeId
			end,
			theme = theme,
			uiFactory = makeUi,
			baseUrl = BASE_URL,
			gameScriptPath = gamePath,
		}

		local ok, errMount = pcall(function()
			mod.mount(ctx)
		end)
		if not ok then
			UI.label(gamePanel, "Mount error: " .. tostring(errMount), 14, true)
			notify("Mount failed")
			return
		end

		mountedModule = mod
		notify("Game module active")
	end

	tryMountGame()

	game:GetPropertyChangedSignal("PlaceId"):Connect(function()
		placeId = game.PlaceId
		placeLabel.Text = "PlaceId: " .. tostring(placeId)
		supported = config.SUPPORTED_GAMES or {}
		gamePath = supported[placeId]
		tryMountGame()
	end)

	setTab("home")
	root.BackgroundTransparency = 1
	TweenService:Create(root, TweenInfo.new(0.2), { BackgroundTransparency = 0 }):Play()

	local dragging = false
	local dragStart = Vector2.zero
	local startPos = UDim2.new()

	titleBar.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			dragStart = Vector2.new(input.Position.X, input.Position.Y)
			startPos = root.Position
		end
	end)

	titleBar.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = false
		end
	end)

	UserInputService.InputChanged:Connect(function(input)
		if
			dragging
			and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch)
		then
			local delta = Vector2.new(input.Position.X, input.Position.Y) - dragStart
			root.Position = UDim2.new(
				startPos.X.Scale,
				startPos.X.Offset + delta.X,
				startPos.Y.Scale,
				startPos.Y.Offset + delta.Y
			)
		end
	end)

	closeBtn.MouseButton1Click:Connect(function()
		clearGameMount()
		gui:Destroy()
	end)

	local minimized = false
	minBtn.MouseButton1Click:Connect(function()
		minimized = not minimized
		body.Visible = not minimized
		root.Size = if minimized then UDim2.fromOffset(540, 44) else UDim2.fromOffset(540, 400)
	end)
end
