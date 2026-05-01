--[[
  Hub UI: loads lib via HttpGet, builds window; per-game modules load from the Games tab or via autoload (config.AUTOLOAD_GAME_MODULE).
  Invoked as: loadstring(src)()(BASE_URL, config)
  Local dev: set getgenv().MYA_LOCAL_ROOT to your repo path before running hub (see loader_local.lua).
]]

return function(BASE_URL: string, config: { [string]: any })
	local Players = game:GetService("Players")
	local UserInputService = game:GetService("UserInputService")
	local RunService = game:GetService("RunService")
	local TweenService = game:GetService("TweenService")
	local HttpService = game:GetService("HttpService")
	-- Spread heavy work across frames so injection doesn’t hitch as one long stall.
	local function yieldFrames(n: number)
		for _ = 1, n do
			task.wait()
		end
	end
	local localPlayer = Players.LocalPlayer
	if not localPlayer then
		localPlayer = Players.PlayerAdded:Wait()
	end

	local analyticsSessionId = (function()
		local t = tostring(os.time())
		local r = tostring(math.random(100000, 999999))
		return "mya-" .. t .. "-" .. r
	end)()

	local function analyticsEnabled()
		local g = typeof(getgenv) == "function" and getgenv() or nil
		local enabled = config.ANON_ANALYTICS_ENABLED == true
		if g and g.MYA_ANON_ANALYTICS_ENABLED ~= nil then
			enabled = g.MYA_ANON_ANALYTICS_ENABLED == true
		end
		return enabled
	end

	local function analyticsWebhookUrl()
		local g = typeof(getgenv) == "function" and getgenv() or nil
		if g and typeof(g.MYA_ANON_ANALYTICS_WEBHOOK_URL) == "string" and #g.MYA_ANON_ANALYTICS_WEBHOOK_URL > 0 then
			return g.MYA_ANON_ANALYTICS_WEBHOOK_URL
		end
		if typeof(config.ANON_ANALYTICS_WEBHOOK_URL) == "string" and #config.ANON_ANALYTICS_WEBHOOK_URL > 0 then
			return config.ANON_ANALYTICS_WEBHOOK_URL
		end
		return nil
	end

	local function postJson(url: string, payload: { [string]: any }): boolean
		local body = HttpService:JSONEncode(payload)
		local req = request or http_request or (syn and syn.request)
		if typeof(req) == "function" then
			local ok, res = pcall(function()
				return req({
					Url = url,
					Method = "POST",
					Headers = { ["Content-Type"] = "application/json" },
					Body = body,
				})
			end)
			if ok then
				local code = tonumber((type(res) == "table" and (res.StatusCode or res.status)) or 0) or 0
				if code == 0 or (code >= 200 and code < 300) then
					return true
				end
			end
		end
		local okHttpPost = pcall(function()
			game:HttpPost(url, body, Enum.HttpContentType.ApplicationJson, false)
		end)
		return okHttpPost
	end

	local function sendAnonAnalytics(eventName: string, extra: { [string]: any }?)
		if not analyticsEnabled() then
			return
		end
		local url = analyticsWebhookUrl()
		if not url then
			return
		end
		local payload = {
			event = eventName,
			brand = tostring(config.BRAND or "Mya"),
			version = tostring(config.VERSION or "Loader"),
			session_id = analyticsSessionId,
			place_id = game.PlaceId,
			place_name = tostring(game.Name or "Unknown"),
			timestamp_unix = os.time(),
		}
		if type(extra) == "table" then
			for k, v in pairs(extra) do
				payload[k] = v
			end
		end
		local embedFields = {
			{ name = "event", value = tostring(payload.event), inline = true },
			{ name = "place_id", value = tostring(payload.place_id), inline = true },
			{ name = "place_name", value = tostring(payload.place_name), inline = false },
			{ name = "session_id", value = tostring(payload.session_id), inline = false },
			{ name = "module_kind", value = tostring(payload.module_kind or "n/a"), inline = true },
			{ name = "module_path", value = tostring(payload.module_path or "n/a"), inline = false },
			{ name = "timestamp_unix", value = tostring(payload.timestamp_unix), inline = true },
		}
		local discordPayload = {
			username = "Mya Analytics",
			embeds = {
				{
					title = "Mya Anonymous Analytics",
					color = 15762095,
					fields = embedFields,
				},
			},
		}
		task.spawn(function()
			pcall(function()
				postJson(url, discordPayload)
			end)
		end)
	end

	local function sendAnonAnalyticsDelayed(delaySec: number, eventName: string, extra: { [string]: any }?)
		task.delay(math.max(0, delaySec), function()
			pcall(function()
				sendAnonAnalytics(eventName, extra)
			end)
		end)
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
	yieldFrames(2)

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
	yieldFrames(2)

	-- If lib/loader_splash.lua cannot be fetched: same spectrum as loader_splash (inline).
	local function mountHubLoadingOverlayFallback(bodyFrame: Frame, th: { [string]: any }, uiAnim: { [string]: any }?): () -> ()
		local cornerR = typeof(th.corner) == "number" and th.corner or 10
		local function corner(inst: Instance, r: number)
			local c = Instance.new("UICorner")
			c.CornerRadius = UDim.new(0, r)
			c.Parent = inst
		end
		local overlay = Instance.new("Frame")
		overlay.Name = "HubLoadingOverlay"
		overlay.Size = UDim2.new(1, 0, 1, 0)
		overlay.BackgroundColor3 = th.bg
		overlay.BackgroundTransparency = 0
		overlay.BorderSizePixel = 0
		overlay.ZIndex = 100
		overlay.Parent = bodyFrame
		corner(overlay, cornerR)

		local function inlineSpectrumLoader(parent: Instance, accent: Color3): (Frame, () -> ())
			local lighter = accent:Lerp(Color3.new(1, 1, 1), 0.38)
			local holder = Instance.new("Frame")
			holder.Name = "LoadingSpectrum"
			holder.BackgroundTransparency = 1
			holder.AnchorPoint = Vector2.new(0.5, 0.5)
			holder.Position = UDim2.new(0.5, 0, 0.42, 0)
			holder.Size = UDim2.fromOffset(220, 80)
			holder.ZIndex = 102
			holder.Parent = parent
			local layout = Instance.new("UIListLayout")
			layout.FillDirection = Enum.FillDirection.Horizontal
			layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
			layout.VerticalAlignment = Enum.VerticalAlignment.Bottom
			layout.Padding = UDim.new(0, 7)
			layout.Parent = holder
			local n = 7
			local bars = {}
			for i = 1, n do
				local bar = Instance.new("Frame")
				bar.Name = "Bar" .. i
				bar.BorderSizePixel = 0
				bar.BackgroundColor3 = accent
				bar.Size = UDim2.fromOffset(11, 22)
				bar.ZIndex = 103
				local cr = Instance.new("UICorner")
				cr.CornerRadius = UDim.new(0, 5)
				cr.Parent = bar
				local grad = Instance.new("UIGradient")
				grad.Rotation = 90
				grad.Color = ColorSequence.new({
					ColorSequenceKeypoint.new(0, lighter),
					ColorSequenceKeypoint.new(1, accent),
				})
				grad.Parent = bar
				bar.Parent = holder
				bars[i] = bar
			end
			local t0 = os.clock()
			local conn = RunService.RenderStepped:Connect(function()
				local t = os.clock() - t0
				for i = 1, n do
					local phase = t * 2.65 + (i - 1) * 0.62
					local wave = (math.sin(phase) * 0.5 + 0.5)
					local h = 12 + wave * 54
					bars[i].Size = UDim2.fromOffset(11, h)
					bars[i].BackgroundTransparency = 0.08 + (1 - wave) * 0.22
				end
			end)
			local function cancel()
				conn:Disconnect()
			end
			return holder, cancel
		end
		local createSpectrum = uiAnim and uiAnim.createSpectrumLoader or inlineSpectrumLoader
		local _, cancelSpectrum = createSpectrum(overlay, th.accent)

		local tip = Instance.new("TextLabel")
		tip.BackgroundTransparency = 1
		tip.AnchorPoint = Vector2.new(0.5, 1)
		tip.Position = UDim2.new(0.5, 0, 1, -8)
		tip.Size = UDim2.new(1, -32, 0, 0)
		tip.AutomaticSize = Enum.AutomaticSize.Y
		tip.Font = Enum.Font.GothamMedium
		tip.TextSize = 12
		tip.TextColor3 = th.textMuted
		tip.TextXAlignment = Enum.TextXAlignment.Center
		tip.TextWrapped = true
		tip.ZIndex = 101
		tip.Text = "Join the discord for suggestions & more scripts !"
		tip.Parent = overlay
		local status = Instance.new("TextLabel")
		status.BackgroundTransparency = 1
		status.AnchorPoint = Vector2.new(0.5, 1)
		status.Position = UDim2.new(0.5, 0, 1, -52)
		status.Size = UDim2.new(1, -40, 0, 22)
		status.Font = Enum.Font.GothamMedium
		status.TextSize = 14
		status.TextColor3 = th.textMuted
		status.TextXAlignment = Enum.TextXAlignment.Center
		status.ZIndex = 101
		status.Text = "Loading"
		status.Parent = overlay
		local t0 = os.clock()
		local conn = RunService.RenderStepped:Connect(function()
			local t = os.clock() - t0
			status.Text = "Loading" .. string.rep(".", 1 + (math.floor(t * 0.7) % 4))
		end)
		return function()
			if conn then
				conn:Disconnect()
			end
			cancelSpectrum()
			if overlay and overlay.Parent then
				overlay:Destroy()
			end
		end
	end

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
	yieldFrames(2)

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
	task.wait()

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
	task.wait()

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
	local statusLabel = UI.label(statusBar, "Ready · press Delete anytime to hide or bring this window back", 13, true)
	statusLabel.Position = UDim2.new(0, 10, 0, 0)
	statusLabel.Size = UDim2.new(1, -20, 1, 0)
	statusLabel.TextYAlignment = Enum.TextYAlignment.Center

	local function notify(msg: string)
		statusLabel.Text = tostring(msg)
	end

	-- Loading overlay before tabs/toast: yields during HttpGet so injection hitches less.
	local hubOverlayStarted = os.clock()
	local hubLoadingCleanup: (() -> ())? = nil
	local uiAnimMod: { [string]: any }? = nil
	do
		local uaSrc = Util.httpGet(BASE_URL .. "lib/ui_anim.lua")
		if uaSrc then
			local okUa, m = pcall(function()
				return loadstring(uaSrc, "@lib/ui_anim.lua")()
			end)
			if okUa and typeof(m) == "table" then
				uiAnimMod = m
			end
		end
	end
	yieldFrames(2)
	do
		local src = Util.httpGet(BASE_URL .. "lib/loader_splash.lua")
		if src then
			local ok, mod = pcall(function()
				return loadstring(src, "@lib/loader_splash.lua")()
			end)
			if ok and typeof(mod) == "table" and typeof(mod.mountHubLoadingOverlay) == "function" then
				local okMount, fn = pcall(function()
					return mod.mountHubLoadingOverlay(body, theme, uiAnimMod)
				end)
				if okMount and typeof(fn) == "function" then
					hubLoadingCleanup = fn
				end
			end
		end
		if not hubLoadingCleanup then
			hubLoadingCleanup = mountHubLoadingOverlayFallback(body, theme, uiAnimMod)
		end
		local savedBodyVis = {
			sidebar = sidebar.Visible,
			content = content.Visible,
			statusBar = statusBar.Visible,
		}
		sidebar.Visible = false
		content.Visible = false
		statusBar.Visible = false
		local innerHubCleanup = hubLoadingCleanup
		hubLoadingCleanup = function()
			if innerHubCleanup then
				innerHubCleanup()
			end
			sidebar.Visible = savedBodyVis.sidebar
			content.Visible = savedBodyVis.content
			statusBar.Visible = savedBodyVis.statusBar
		end
	end
	yieldFrames(2)

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
	task.wait()

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
	local antivcPage = makeTab("antivcban", "Anti VC Ban")
	yieldFrames(2)

	-- External script (not hosted in this repo); credit: discord.gg/bxUtg5QkPF
	local ANTIVC_BAN_SCRIPT_URL = "https://raw.githubusercontent.com/FizzyVR1234/ScriptsByFizzy/refs/heads/main/antivcban.lua"
	local ANTIVC_BAN_CREDIT_URL = "https://discord.gg/bxUtg5QkPF"

	local homeScroll = UI.scroll(homePage)
	homeScroll.Size = UDim2.new(1, 0, 1, 0)

	local homeCard = UI.panel(homeScroll)
	homeCard.Size = UDim2.new(1, -4, 0, 0)
	UI.label(homeCard, "Welcome to " .. config.BRAND, 18, false)
	UI.label(
		homeCard,
		"Peek at the Games tab whenever you want to check if this experience has its own script",
		14,
		true
	)

	local placeLabel = UI.label(homeCard, "PlaceId: " .. tostring(game.PlaceId), 14, false)
	task.wait()

	local gamesScroll = UI.scroll(gamesPage)
	gamesScroll.Size = UDim2.new(1, 0, 1, 0)

	local gamesCard = UI.panel(gamesScroll)
	gamesCard.Size = UDim2.new(1, -4, 0, 0)

	-- Catalog of PlaceIds from config (display names; keep in sync with config.SUPPORTED_GAMES).
	local GAME_DISPLAY_NAMES: { [number]: string } = {
		[11729688377] = "Booga Booga",
		[70845479499574] = "Bite By Night",
		[7353845952] = "Project Delta",
		[7336302630] = "Project Delta",
		[72920620366355] = "Operation One",
		[110400717151509] = "Neighbors",
		[12699642568] = "Neighbors",
		[18667984660] = "Flex Your FPS",
		[112399855119586] = "Corner",
		[15546218972] = "Corner",
		[155615604] = "Prison Life",
		[93978595733734] = "Violence District",
		[11574110446] = "Desolate Valley",
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
	UI.label(gamesCatalog, "Games we’ve got modules for", 16, false)
	-- One row per module path; multiple PlaceIds that share the same script are merged.
	local byPath: { [string]: { number } } = {}
	for id, scriptPath in pairs(config.SUPPORTED_GAMES or {}) do
		local key = if typeof(scriptPath) == "string" then scriptPath else "?"
		if not byPath[key] then
			byPath[key] = {}
		end
		table.insert(byPath[key], id)
	end
	local pathsList = {}
	for p in pairs(byPath) do
		table.insert(pathsList, p)
	end
	table.sort(pathsList)
	for _, pathKey in ipairs(pathsList) do
		local ids = byPath[pathKey]
		table.sort(ids)
		local id0 = ids[1]
		local name = GAME_DISPLAY_NAMES[id0]
		if not name then
			name = pathKey
		end
		local idsText = {}
		for _, pid in ipairs(ids) do
			table.insert(idsText, tostring(pid))
		end
		local placeClause = if #ids == 1
			then ("PlaceId " .. idsText[1])
			else ("PlaceIds " .. table.concat(idsText, ", "))
		UI.label(gamesCatalog, name .. " — " .. placeClause, 14, true)
	end
	if #pathsList == 0 then
		UI.label(gamesCatalog, "Nothing listed here yet — add games in config when you’re ready.", 14, true)
	end
	yieldFrames(2)

	local gamePanel = Instance.new("Frame")
	gamePanel.Name = "GamePanel"
	gamePanel.BackgroundTransparency = 1
	gamePanel.Size = UDim2.new(1, 0, 0, 0)
	gamePanel.AutomaticSize = Enum.AutomaticSize.Y
	gamePanel.LayoutOrder = 3
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
		"Universal works in most games and keeps things simple: ESP, aim tools, fly, noclip, speed, and jump tweaks. Press Delete anytime to open or hide the menu.",
		14,
		true
	)
	local function tryMountMyaUniversal()
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
		sendAnonAnalyticsDelayed(0.8, "module_mount", {
			module_kind = "mya_universal",
			module_path = "games/MyaUniversal/init.lua",
		})
		notify("Mya Universal active · Delete for menu")
	end
	UI.primaryButton(universalCard, "Launch Mya Universal", function()
		tryMountMyaUniversal()
	end)
	task.wait()

	local dumperScroll = UI.scroll(dumperPage)
	dumperScroll.Size = UDim2.new(1, 0, 1, 0)
	local dumperCard = UI.panel(dumperScroll)
	dumperCard.Size = UDim2.new(1, -4, 0, 0)
	UI.label(dumperCard, "Pro Script Dumper", 18, false)
	UI.label(
		dumperCard,
		"Pulls LocalScripts and ModuleScripts out of whatever you’re playing and drops them into a folder in your executor’s workspace. Tip of the hat to zzerexx for the original Pro Script Dumper.",
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
		do
			local trimmed = src:match("^%s*(.-)%s*$") or src
			local head = string.lower(string.sub(trimmed, 1, 24))
			if string.sub(trimmed, 1, 1) == "<" or string.find(head, "<!doctype", 1, true) or string.find(head, "<html", 1, true) then
				notify(
					"Dumper: host returned HTML instead of Lua (often private repo or wrong BASE_URL). Open BASE_URL/universal/dumper.lua in a browser - you should see plain Lua source."
				)
				return
			end
		end
		local fn, cerr = Util.loadstringCompile(src, "universal/dumper.lua")
		if not fn then
			notify("Dumper compile failed: " .. tostring(cerr))
			return
		end
		task.spawn(function()
			local ok, err = pcall(fn, BASE_URL)
			if not ok then
				notify("Dumper error: " .. tostring(err))
			else
				notify("Dumper started")
			end
		end)
	end)
	task.wait()

	local antivcScroll = UI.scroll(antivcPage)
	antivcScroll.Size = UDim2.new(1, 0, 1, 0)
	local antivcCard = UI.panel(antivcScroll)
	antivcCard.Size = UDim2.new(1, -4, 0, 0)
	UI.label(antivcCard, "Anti VC Ban", 18, false)
	UI.label(
		antivcCard,
		"If you rely on voice chat, this is a small helper from an outside repo — run it once each session if it helps you out. Keep your mic on so it can actually do its job.",
		14,
		true
	)
	UI.label(antivcCard, "Credits: discord.gg/bxUtg5QkPF", 14, true)
	UI.primaryButton(antivcCard, "Launch Anti VC Ban", function()
		notify("Downloading Anti VC Ban…")
		local src, herr = Util.httpGet(ANTIVC_BAN_SCRIPT_URL)
		if not src then
			notify("Anti VC Ban download failed: " .. tostring(herr))
			return
		end
		local fn, cerr = Util.loadstringCompile(src, "antivcban.lua")
		if not fn then
			notify("Anti VC Ban compile failed: " .. tostring(cerr))
			return
		end
		task.spawn(function()
			local ok, err = pcall(fn)
			if not ok then
				notify("Anti VC Ban error: " .. tostring(err))
			else
				notify("Anti VC Ban started")
			end
		end)
	end)
	UI.primaryButton(antivcCard, "Copy Discord invite", function()
		local ok = pcall(function()
			if typeof(setclipboard) == "function" then
				setclipboard(ANTIVC_BAN_CREDIT_URL)
			else
				error("setclipboard unavailable")
			end
		end)
		if ok then
			notify("Copied " .. ANTIVC_BAN_CREDIT_URL)
		else
			notify("Discord: " .. ANTIVC_BAN_CREDIT_URL)
		end
	end)
	task.wait()

	local creditsScroll = UI.scroll(creditsPage)
	creditsScroll.Size = UDim2.new(1, 0, 1, 0)
	local creditsCard = UI.panel(creditsScroll)
	creditsCard.Size = UDim2.new(1, -4, 0, 0)
	UI.label(creditsCard, "Credits", 18, false)
	UI.label(
		creditsCard,
		"These folks keep Mya going:",
		14,
		true
	)

	UI.label(creditsCard, "@ilovehewho · Roblox", 16, false)
	UI.label(creditsCard, "Discord: @fubelt", 14, false)
	yieldFrames(2)

	local mountedModule: any = nil
	local placeId = game.PlaceId
	sendAnonAnalyticsDelayed(2.0, "hub_launch", {
		module_kind = "hub",
	})
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
		yieldFrames(2)
		if not gui or not gui.Parent then
			return
		end
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
			UI.label(gamePanel, "Failed to load this game module.", 14, true)
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
		sendAnonAnalyticsDelayed(0.8, "module_mount", {
			module_kind = "game",
			module_path = gamePath,
		})
		notify("Game module active")
		closeHubAfterGameLoad()
	end

	local loadGameBtn = UI.primaryButton(gamesCard, "Load game module", function()
		tryMountGame()
	end)
	loadGameBtn.LayoutOrder = 2
	loadGameBtn.Visible = false

	local function syncGameTabForPlace()
		supported = config.SUPPORTED_GAMES or {}
		gamePath = supported[placeId]
		if not gamePath then
			supportTitle.Text = "Unsupported experience"
			loadGameBtn.Visible = false
		else
			supportTitle.Text = "Supported · " .. gamePath
			loadGameBtn.Visible = true
		end
	end

	-- Prevents double autoload when PlaceId fires (e.g. 0 → real) and the deferred initial sync both run.
	local pendingAutoloadPlaceId: number? = nil
	local pendingUniversalAutoload = false

	local function maybeAutoloadFromConfig()
		local g = typeof(getgenv) == "function" and getgenv() or nil
		local autoGame = config.AUTOLOAD_GAME_MODULE
		if g and g.MYA_AUTOLOAD_GAME_MODULE ~= nil then
			autoGame = g.MYA_AUTOLOAD_GAME_MODULE
		end
		if autoGame ~= false then
			local gp = (config.SUPPORTED_GAMES or {})[placeId]
			if gp then
				if pendingAutoloadPlaceId == placeId then
					return
				end
				pendingAutoloadPlaceId = placeId
				task.defer(function()
					pcall(tryMountGame)
					pendingAutoloadPlaceId = nil
				end)
				return
			end
		end
		local autoUni = config.AUTOLOAD_MYA_UNIVERSAL_WHEN_UNSUPPORTED
		if g and g.MYA_AUTOLOAD_MYA_UNIVERSAL_WHEN_UNSUPPORTED ~= nil then
			autoUni = g.MYA_AUTOLOAD_MYA_UNIVERSAL_WHEN_UNSUPPORTED
		end
		if autoUni == true then
			local gp = (config.SUPPORTED_GAMES or {})[placeId]
			if not gp then
				if pendingUniversalAutoload then
					return
				end
				pendingUniversalAutoload = true
				task.defer(function()
					pcall(tryMountMyaUniversal)
					pendingUniversalAutoload = false
				end)
			end
		end
	end

	placeIdConn = game:GetPropertyChangedSignal("PlaceId"):Connect(function()
		clearGameMount()
		pendingAutoloadPlaceId = nil
		pendingUniversalAutoload = false
		placeId = game.PlaceId
		placeLabel.Text = "PlaceId: " .. tostring(placeId)
		syncGameTabForPlace()
		maybeAutoloadFromConfig()
	end)

	-- Let the in-window loader stay visible briefly; fast machines otherwise flash it.
	local MIN_HUB_OVERLAY_SEC = 1.5
	do
		local elapsed = os.clock() - hubOverlayStarted
		if elapsed < MIN_HUB_OVERLAY_SEC then
			task.wait(MIN_HUB_OVERLAY_SEC - elapsed)
		end
	end
	if hubLoadingCleanup then
		hubLoadingCleanup()
		hubLoadingCleanup = nil
	end

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
		if input.KeyCode ~= Enum.KeyCode.Delete then
			return
		end
		gui.Enabled = not gui.Enabled
	end)

	-- After all connections exist (so closeHub can disconnect drag), sync PlaceId when the experience is ready.
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
		placeLabel.Text = "PlaceId: " .. tostring(placeId)
		syncGameTabForPlace()
		maybeAutoloadFromConfig()
	end)
end
