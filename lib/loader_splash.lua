--[[
  In-hub loading overlay: full-body layer on hub.lua’s Body frame.
  Loader uses lib/ui_anim (spectrum bars) or the same logic inlined if ui_anim is missing.
]]

local RunService = game:GetService("RunService")

local function applyCorner(inst: Instance, radius: number)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, radius)
	c.Parent = inst
end

local function defaultTheme()
	return {
		bg = Color3.fromRGB(28, 18, 26),
		border = Color3.fromRGB(90, 55, 72),
		accent = Color3.fromRGB(240, 130, 175),
		text = Color3.fromRGB(255, 228, 238),
		textMuted = Color3.fromRGB(200, 160, 182),
		corner = 10,
	}
end

-- Mirrors lib/ui_anim.createSpectrumLoader when the module was not passed in.
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

--- uiAnim: optional table from loadstring(httpGet "lib/ui_anim.lua") with createSpectrumLoader
local function mountHubLoadingOverlay(body: Frame, theme: { [string]: any }?, uiAnim: { [string]: any }?): () -> ()
	theme = theme or defaultTheme()
	local cornerR = typeof(theme.corner) == "number" and theme.corner or 10

	local overlay = Instance.new("Frame")
	overlay.Name = "HubLoadingOverlay"
	overlay.Size = UDim2.new(1, 0, 1, 0)
	overlay.Position = UDim2.new(0, 0, 0, 0)
	overlay.BackgroundColor3 = theme.bg
	overlay.BackgroundTransparency = 0
	overlay.BorderSizePixel = 0
	overlay.ZIndex = 100
	overlay.Parent = body
	applyCorner(overlay, cornerR)

	local createSpectrum = uiAnim and uiAnim.createSpectrumLoader or inlineSpectrumLoader
	local _, cancelSpectrum = createSpectrum(overlay, theme.accent)

	local tip = Instance.new("TextLabel")
	tip.Name = "DiscordTip"
	tip.BackgroundTransparency = 1
	tip.AnchorPoint = Vector2.new(0.5, 1)
	tip.Position = UDim2.new(0.5, 0, 1, -8)
	tip.Size = UDim2.new(1, -32, 0, 0)
	tip.AutomaticSize = Enum.AutomaticSize.Y
	tip.Font = Enum.Font.GothamMedium
	tip.TextSize = 12
	tip.TextColor3 = theme.textMuted
	tip.TextXAlignment = Enum.TextXAlignment.Center
	tip.TextWrapped = true
	tip.ZIndex = 101
	tip.Text = "Join the discord for suggestions & more scripts !"
	tip.Parent = overlay

	local status = Instance.new("TextLabel")
	status.Name = "Status"
	status.BackgroundTransparency = 1
	status.AnchorPoint = Vector2.new(0.5, 1)
	status.Position = UDim2.new(0.5, 0, 1, -52)
	status.Size = UDim2.new(1, -40, 0, 22)
	status.Font = Enum.Font.GothamMedium
	status.TextSize = 14
	status.TextColor3 = theme.textMuted
	status.TextXAlignment = Enum.TextXAlignment.Center
	status.ZIndex = 101
	status.Text = "Loading"
	status.Parent = overlay

	local t0 = os.clock()
	local conn = RunService.RenderStepped:Connect(function()
		local t = os.clock() - t0
		local dots = 1 + (math.floor(t * 0.7) % 4)
		status.Text = "Loading" .. string.rep(".", dots)
	end)

	return function()
		if conn then
			conn:Disconnect()
			conn = nil
		end
		cancelSpectrum()
		if overlay and overlay.Parent then
			overlay:Destroy()
		end
	end
end

return {
	mountHubLoadingOverlay = mountHubLoadingOverlay,
}
