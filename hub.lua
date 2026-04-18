--[[
  Hub UI: loads lib via HttpGet, builds window, mounts per-game module by PlaceId.
  Invoked as: loadstring(src)()(BASE_URL, config)
  Local dev: set getgenv().MYA_LOCAL_ROOT to your repo path before running hub (see loader_local.lua).
]]

return function(BASE_URL: string, config: { [string]: any })
	local Players = game:GetService("Players")
	local UserInputService = game:GetService("UserInputService")
	local TweenService = game:GetService("TweenService")
	local localPlayer = Players.LocalPlayer
	if not localPlayer then
		localPlayer = Players.PlayerAdded:Wait()
	end

	-- When BASE_URL is http(s), always fetch over HTTP — even if MYA_LOCAL_ROOT is set
	-- (e.g. leftover from loader_local), readfile would fail or hit the wrong tree.
	local function baseUrlIsHttp(base)
		local b = string.lower(tostring(base))
		return string.sub(b, 1, 7) == "http://" or string.sub(b, 1, 8) == "https://"
	end

	local function fetchUtilSource(): (string?, string?)
		local rel = "lib/util.lua"
		local url = BASE_URL .. rel
		local g = typeof(getgenv) == "function" and getgenv()
		if not baseUrlIsHttp(BASE_URL) and g and g.MYA_LOCAL_ROOT and typeof(readfile) == "function" then
			local root = g.MYA_LOCAL_ROOT
			if string.sub(root, -1) ~= "/" and string.sub(root, -1) ~= "\\" then
				root = root .. "/"
			end
			local disk = root .. rel:gsub("/", "\\")
			local variants = { disk, root .. rel, (root .. rel):gsub("\\", "/") }
			for _, p in ipairs(variants) do
				local ok, src = pcall(readfile, p)
				if ok and typeof(src) == "string" and #src > 0 then
					return src, nil
				end
			end
			return nil, "readfile failed for lib/util.lua under MYA_LOCAL_ROOT"
		end
		local ok, r = pcall(function()
			return game:HttpGet(url, true)
		end)
		if ok then
			return r, nil
		end
		return nil, tostring(r)
	end

	local utilSrc, uErr = fetchUtilSource()
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
	gui.Parent = Util.loaderScreenGuiParent()
	Util.configureLoaderScreenGui(gui)

	-- First-person games lock the mouse to the camera; unlock so the hub can be clicked.
	task.defer(function()
		pcall(function()
			UserInputService.MouseBehavior = Enum.MouseBehavior.Default
		end)
	end)

	local root = Instance.new("Frame")
	root.Name = "Window"
	root.AnchorPoint = Vector2.new(0.5, 0.5)
	root.Position = UDim2.fromScale(0.5, 0.5)
	root.Size = UDim2.fromOffset(540, 400)
	root.BackgroundColor3 = theme.bg
	root.BorderSizePixel = 0
	root.Active = true
	root.Selectable = false
	root.Parent = gui
	UI.corner(root)

	local titleBar = Instance.new("Frame")
	titleBar.Name = "TitleBar"
	titleBar.BackgroundColor3 = theme.bgElevated
	titleBar.BorderSizePixel = 0
	titleBar.Selectable = false
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
	titleText.Size = UDim2.new(1, -200, 1, 0)
	titleText.Font = Enum.Font.GothamBold
	titleText.TextSize = 16
	titleText.TextXAlignment = Enum.TextXAlignment.Left
	titleText.TextColor3 = theme.text
	titleText.Text = config.BRAND .. "  ·  " .. tostring(config.VERSION or "")
	titleText.Parent = titleBar

	local DISCORD_INVITE = "https://discord.gg/YeyepQG6K9"

	-- Returns "browser" | "clipboard" | "none" (for status line feedback).
	local function openDiscordInvite(): string
		local url = DISCORD_INVITE
		local mode = "none"
		pcall(function()
			local g = typeof(getgenv) == "function" and getgenv()
			if g and typeof(g.openbrowser) == "function" then
				g.openbrowser(url)
				mode = "browser"
			end
		end)
		if mode == "none" then
			local ok = pcall(function()
				game:GetService("GuiService"):OpenBrowserWindow(url)
			end)
			if ok then
				mode = "browser"
			end
		end
		if mode == "none" and typeof(setclipboard) == "function" then
			setclipboard(url)
			mode = "clipboard"
		end
		return mode
	end

	local btnRow = Instance.new("Frame")
	btnRow.BackgroundTransparency = 1
	btnRow.AnchorPoint = Vector2.new(1, 0.5)
	btnRow.Position = UDim2.new(1, -8, 0.5, 0)
	btnRow.Size = UDim2.new(0, 146, 0, 28)
	btnRow.Parent = titleBar

	local discordBtn = Instance.new("TextButton")
	discordBtn.BorderSizePixel = 0
	discordBtn.Size = UDim2.new(0, 68, 1, 0)
	discordBtn.Position = UDim2.new(0, 0, 0, 0)
	discordBtn.BackgroundColor3 = theme.surface
	discordBtn.Text = "Discord"
	discordBtn.TextColor3 = theme.accent
	discordBtn.Font = Enum.Font.GothamSemibold
	discordBtn.TextSize = 12
	discordBtn.AutoButtonColor = false
	discordBtn.Parent = btnRow
	UI.corner(discordBtn)

	local minBtn = Instance.new("TextButton")
	minBtn.BorderSizePixel = 0
	minBtn.Size = UDim2.new(0, 32, 1, 0)
	minBtn.Position = UDim2.new(0, 74, 0, 0)
	minBtn.BackgroundColor3 = theme.surface
	minBtn.Text = "—"
	minBtn.TextColor3 = theme.textMuted
	minBtn.Font = Enum.Font.GothamBold
	minBtn.TextSize = 14
	minBtn.AutoButtonColor = false
	minBtn.Parent = btnRow
	UI.corner(minBtn)

	local closeBtn = Instance.new("TextButton")
	closeBtn.BorderSizePixel = 0
	closeBtn.Size = UDim2.new(0, 32, 1, 0)
	closeBtn.Position = UDim2.new(0, 110, 0, 0)
	closeBtn.AnchorPoint = Vector2.new(0, 0)
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
	body.BorderSizePixel = 0
	body.Position = UDim2.new(0, 0, 0, 44)
	body.Size = UDim2.new(1, 0, 1, -44)
	body.Selectable = false
	body.Parent = root

	local sidebar = Instance.new("Frame")
	sidebar.Name = "Sidebar"
	sidebar.BackgroundTransparency = 1
	sidebar.BorderSizePixel = 0
	sidebar.Size = UDim2.new(0, 132, 1, -16)
	sidebar.Position = UDim2.new(0, 10, 0, 8)
	sidebar.Selectable = false
	sidebar.Parent = body

	local sideLayout = Instance.new("UIListLayout")
	sideLayout.SortOrder = Enum.SortOrder.LayoutOrder
	sideLayout.Padding = UDim.new(0, 6)
	sideLayout.Parent = sidebar

	local content = Instance.new("Frame")
	content.Name = "Content"
	content.BackgroundTransparency = 1
	content.BorderSizePixel = 0
	content.Selectable = false
	content.Position = UDim2.new(0, 152, 0, 8)
	content.Size = UDim2.new(1, -162, 1, -52)
	content.Parent = body

	local statusBar = Instance.new("Frame")
	statusBar.Name = "Status"
	statusBar.BackgroundColor3 = theme.bgElevated
	statusBar.BorderSizePixel = 0
	statusBar.Selectable = false
	statusBar.AnchorPoint = Vector2.new(0, 1)
	statusBar.Position = UDim2.new(0, 10, 1, -8)
	statusBar.Size = UDim2.new(1, -20, 0, 26)
	statusBar.Parent = body
	UI.corner(statusBar)
	local statusLabel = UI.label(statusBar, "Ready · Insert hides or shows the hub", 13, true)
	statusLabel.Position = UDim2.new(0, 10, 0, 0)
	statusLabel.Size = UDim2.new(1, -20, 1, 0)
	statusLabel.TextYAlignment = Enum.TextYAlignment.Center

	local function notify(msg: string)
		statusLabel.Text = tostring(msg)
	end

	-- In-window toast when invite is copied (clipboard fallback).
	local toastToken = 0
	local toastPendingHide: thread? = nil
	local toastFrame = Instance.new("Frame")
	toastFrame.Name = "ClipboardToast"
	toastFrame.BackgroundColor3 = theme.surface
	toastFrame.BorderSizePixel = 0
	toastFrame.AnchorPoint = Vector2.new(0.5, 0)
	toastFrame.Position = UDim2.new(0.5, 0, 0, 12)
	toastFrame.Size = UDim2.fromOffset(300, 46)
	toastFrame.Visible = false
	toastFrame.ZIndex = 50
	-- Parent to body so the toast hides when the hub is minimized (title-only).
	toastFrame.Parent = body
	UI.corner(toastFrame)
	local toastStroke = Instance.new("UIStroke")
	toastStroke.Color = theme.accent
	toastStroke.Thickness = 1
	toastStroke.Transparency = 0.4
	toastStroke.Parent = toastFrame
	local toastLabel = Instance.new("TextLabel")
	toastLabel.BackgroundTransparency = 1
	toastLabel.Size = UDim2.new(1, -20, 1, 0)
	toastLabel.Position = UDim2.fromOffset(10, 0)
	toastLabel.Font = Enum.Font.GothamMedium
	toastLabel.TextSize = 14
	toastLabel.TextColor3 = theme.text
	toastLabel.TextXAlignment = Enum.TextXAlignment.Center
	toastLabel.TextYAlignment = Enum.TextYAlignment.Center
	toastLabel.TextWrapped = true
	toastLabel.Text = "Copied to clipboard — paste to open Discord"
	toastLabel.Parent = toastFrame

	local function showClipboardCopiedToast()
		toastToken += 1
		local token = toastToken
		if toastPendingHide then
			task.cancel(toastPendingHide)
			toastPendingHide = nil
		end
		toastFrame.Visible = true
		toastFrame.BackgroundTransparency = 1
		toastStroke.Transparency = 1
		toastLabel.TextTransparency = 1
		toastFrame.Position = UDim2.new(0.5, 0, 0, 4)

		local tiIn = TweenInfo.new(0.38, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
		TweenService:Create(toastFrame, tiIn, {
			BackgroundTransparency = 0.06,
			Position = UDim2.new(0.5, 0, 0, 14),
		}):Play()
		TweenService:Create(toastStroke, tiIn, { Transparency = 0.35 }):Play()
		TweenService:Create(toastLabel, tiIn, { TextTransparency = 0 }):Play()

		toastPendingHide = task.delay(2.35, function()
			toastPendingHide = nil
			if token ~= toastToken then
				return
			end
			local tiOut = TweenInfo.new(0.45, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
			local tBg = TweenService:Create(toastFrame, tiOut, {
				BackgroundTransparency = 1,
				Position = UDim2.new(0.5, 0, 0, -2),
			})
			TweenService:Create(toastStroke, tiOut, { Transparency = 1 }):Play()
			TweenService:Create(toastLabel, tiOut, { TextTransparency = 1 }):Play()
			tBg:Play()
			tBg.Completed:Connect(function()
				if token ~= toastToken then
					return
				end
				toastFrame.Visible = false
			end)
		end)
	end

	discordBtn.MouseButton1Click:Connect(function()
		local mode = openDiscordInvite()
		if mode == "clipboard" then
			notify("Discord invite copied to clipboard")
			showClipboardCopiedToast()
		elseif mode == "browser" then
			notify("Opening Discord…")
		else
			notify("Discord: " .. DISCORD_INVITE)
		end
	end)

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
		b.BorderSizePixel = 0
		b.Selectable = false
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

	local function makeCategoryLabel(text: string)
		local lbl = Instance.new("TextLabel")
		lbl.BackgroundTransparency = 1
		lbl.Size = UDim2.new(1, -8, 0, 22)
		lbl.Font = Enum.Font.GothamBold
		lbl.TextSize = 11
		lbl.TextXAlignment = Enum.TextXAlignment.Left
		lbl.TextColor3 = theme.textMuted
		lbl.Text = text
		lbl.Parent = sidebar
		local pad = Instance.new("UIPadding", lbl)
		pad.PaddingLeft = UDim.new(0, 4)
		pad.PaddingTop = UDim.new(0, 6)
	end

	local homePage = makeTab("home", "Home")
	local gamesPage = makeTab("games", "Games")
	local creditsPage = makeTab("credits", "Credits")
	makeCategoryLabel("UNIVERSAL")
	local universalPage = makeTab("myauniversal", "Mya Universal")
	local dumperPage = makeTab("dumper", "Dumper")

	local homeScroll = UI.scroll(homePage)
	homeScroll.Size = UDim2.new(1, 0, 1, 0)

	local homeCard = UI.panel(homeScroll)
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

	local gamesCard = UI.panel(gamesScroll)
	gamesCard.Size = UDim2.new(1, -4, 0, 0)

	-- Catalog of PlaceIds from config (display names; keep in sync with config.SUPPORTED_GAMES).
	local GAME_DISPLAY_NAMES: { [number]: string } = {
		[72920620366355] = "Operation One",
		[110400717151509] = "Neighbors",
		[12699642568] = "Neighbors",
		[18667984660] = "Flex Your FPS",
	}
	local gamesCatalog = Instance.new("Frame")
	gamesCatalog.BackgroundTransparency = 1
	gamesCatalog.Size = UDim2.new(1, 0, 0, 0)
	gamesCatalog.AutomaticSize = Enum.AutomaticSize.Y
	gamesCatalog.LayoutOrder = 0
	gamesCatalog.Parent = gamesCard
	local catalogLayout = Instance.new("UIListLayout")
	catalogLayout.SortOrder = Enum.SortOrder.LayoutOrder
	catalogLayout.Padding = UDim.new(0, 6)
	catalogLayout.Parent = gamesCatalog
	UI.label(gamesCatalog, "Supported games", 16, false)
	local supportedIds = {}
	for id in pairs(config.SUPPORTED_GAMES or {}) do
		table.insert(supportedIds, id)
	end
	table.sort(supportedIds)
	for _, id in ipairs(supportedIds) do
		local name = GAME_DISPLAY_NAMES[id]
		if not name then
			local path = (config.SUPPORTED_GAMES or {})[id]
			name = if typeof(path) == "string" then path else "Unknown"
		end
		UI.label(gamesCatalog, name .. " — PlaceId " .. tostring(id), 14, true)
	end
	if #supportedIds == 0 then
		UI.label(gamesCatalog, "No games listed in hub config yet.", 14, true)
	end

	local gamePanel = Instance.new("Frame")
	gamePanel.Name = "GamePanel"
	gamePanel.BackgroundTransparency = 1
	gamePanel.Size = UDim2.new(1, 0, 0, 0)
	gamePanel.AutomaticSize = Enum.AutomaticSize.Y
	gamePanel.LayoutOrder = 2
	gamePanel.Parent = gamesCard

	local gameLayout = Instance.new("UIListLayout")
	gameLayout.SortOrder = Enum.SortOrder.LayoutOrder
	gameLayout.Padding = UDim.new(0, 8)
	gameLayout.Parent = gamePanel

	local universalScroll = UI.scroll(universalPage)
	universalScroll.Size = UDim2.new(1, 0, 1, 0)
	local universalCard = UI.panel(universalScroll)
	universalCard.Size = UDim2.new(1, -4, 0, 0)
	UI.label(universalCard, "Mya Universal", 18, false)
	UI.label(
		universalCard,
		"Works in any experience: ESP highlights, aim assist (hold RMB), fly, noclip, walk speed, and jump power. Uses a small in-game menu (Insert).",
		14,
		true
	)
	UI.primaryButton(universalCard, "Launch Mya Universal", function()
		notify("Loading Mya Universal…")
		local url = BASE_URL .. "games/MyaUniversal/init.lua"
		local mod, err = Util.loadModuleFromUrl(url, "games/MyaUniversal/init.lua")
		if not mod then
			notify("Mya Universal load failed: " .. tostring(err))
			return
		end
		if typeof(mod.mount) ~= "function" then
			notify("Invalid Mya Universal module")
			return
		end
		local ctx = {
			notify = notify,
			baseUrl = BASE_URL,
			theme = theme,
		}
		local okM, errM = pcall(function()
			mod.mount(ctx)
		end)
		if not okM then
			notify("Mya Universal mount error: " .. tostring(errM))
			return
		end
		notify("Mya Universal active · Insert for menu")
	end)

	local dumperScroll = UI.scroll(dumperPage)
	dumperScroll.Size = UDim2.new(1, 0, 1, 0)
	local dumperCard = UI.panel(dumperScroll)
	dumperCard.Size = UDim2.new(1, -4, 0, 0)
	UI.label(dumperCard, "Pro Script Dumper", 18, false)
	UI.label(
		dumperCard,
		"Decompiles LocalScripts and ModuleScripts to files under workspace/Pro Script Dumper. Requires executor APIs (decompile, writefile, …). Uses an external Material UI library when launched.",
		14,
		true
	)
	UI.primaryButton(dumperCard, "Launch Dumper", function()
		notify("Downloading Dumper…")
		local url = BASE_URL .. "universal/dumper.lua"
		local src, herr = Util.httpGet(url)
		if not src then
			notify("Dumper download failed: " .. tostring(herr))
			return
		end
		local fn, cerr = Util.loadstringCompile(src, "universal/dumper.lua")
		if not fn then
			notify("Dumper compile failed: " .. tostring(cerr))
			return
		end
		task.spawn(function()
			local ok, err = pcall(fn)
			if not ok then
				notify("Dumper error: " .. tostring(err))
			else
				notify("Dumper started")
			end
		end)
	end)

	local creditsScroll = UI.scroll(creditsPage)
	creditsScroll.Size = UDim2.new(1, 0, 1, 0)
	local creditsCard = UI.panel(creditsScroll)
	creditsCard.Size = UDim2.new(1, -4, 0, 0)
	UI.label(creditsCard, "Credits", 18, false)
	UI.label(
		creditsCard,
		"Mya is maintained by the people below. Spots marked “placeholder” are for future contributors.",
		14,
		true
	)

	UI.label(creditsCard, "@ilovehewho · Roblox", 16, false)
	UI.label(creditsCard, "Discord: @fubelt", 14, false)

	UI.label(creditsCard, "— Additional contributors (placeholder) —", 12, true)
	UI.label(creditsCard, "• Name / role / link — add when you have more people to credit.", 13, true)
	UI.label(creditsCard, "• …", 13, true)

	local mountedModule: any = nil
	local placeId = game.PlaceId
	local supported = config.SUPPORTED_GAMES or {}
	local gamePath = supported[placeId]

	local supportTitle = UI.label(gamesCard, "", 16, false)
	supportTitle.LayoutOrder = 1

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

	local placeIdConn: RBXScriptConnection? = nil
	local uisDragConn: RBXScriptConnection? = nil
	local insertToggleConn: RBXScriptConnection? = nil

	local function closeHubAfterGameLoad()
		if placeIdConn then
			placeIdConn:Disconnect()
			placeIdConn = nil
		end
		if uisDragConn then
			uisDragConn:Disconnect()
			uisDragConn = nil
		end
		if insertToggleConn then
			insertToggleConn:Disconnect()
			insertToggleConn = nil
		end
		if gui and gui.Parent then
			gui:Destroy()
		end
	end

	local function tryMountGame()
		clearGameMount()
		if not gamePath then
			supportTitle.Text = "Unsupported experience"
			UI.label(gamePanel, "No module is registered for PlaceId " .. tostring(placeId) .. ".", 14, true)
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
		closeHubAfterGameLoad()
	end

	placeIdConn = game:GetPropertyChangedSignal("PlaceId"):Connect(function()
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

	uisDragConn = UserInputService.InputChanged:Connect(function(input)
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
		if placeIdConn then
			placeIdConn:Disconnect()
			placeIdConn = nil
		end
		if uisDragConn then
			uisDragConn:Disconnect()
			uisDragConn = nil
		end
		if insertToggleConn then
			insertToggleConn:Disconnect()
			insertToggleConn = nil
		end
		gui:Destroy()
	end)

	local minimized = false
	minBtn.MouseButton1Click:Connect(function()
		minimized = not minimized
		body.Visible = not minimized
		root.Size = if minimized then UDim2.fromOffset(540, 44) else UDim2.fromOffset(540, 400)
	end)

	insertToggleConn = UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if gameProcessed then
			return
		end
		if input.KeyCode ~= Enum.KeyCode.Insert then
			return
		end
		gui.Enabled = not gui.Enabled
	end)

	-- After all connections exist (so closeHub can disconnect drag), mount when the experience is ready.
	-- Matches loader.lua wait: game.Loaded + PlaceId (avoids "unsupported" flash when PlaceId was still 0).
	task.defer(function()
		if not game:IsLoaded() then
			game.Loaded:Wait()
		end
		local deadline = os.clock() + 15
		while game.PlaceId == 0 and os.clock() < deadline do
			task.wait(0.05)
		end
		placeId = game.PlaceId
		supported = config.SUPPORTED_GAMES or {}
		gamePath = supported[placeId]
		placeLabel.Text = "PlaceId: " .. tostring(placeId)
		tryMountGame()
	end)
end
