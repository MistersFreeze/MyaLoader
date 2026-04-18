--[[
  In-hub loading overlay: full-body layer on hub.lua’s Body frame (∞ path line + status).
  No separate ScreenGui — use this so only MyaHub is visible while the hub finishes wiring.
]]

local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

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

--- Covers hub Body (sidebar + content + status) until cleanup() runs.
local function mountHubLoadingOverlay(body: Frame, theme: { [string]: any }?): () -> ()
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

	local stroke = Instance.new("UIStroke")
	stroke.Color = theme.border
	stroke.Thickness = 1
	stroke.Transparency = 0.3
	stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	stroke.Parent = overlay

	-- Figure-eight (∞): x = sin(t), y = sin(2t)/2 — polyline segments follow the path (real line, not dots).
	local PATH_SAMPLES = 140
	local TRAIL_LEN = 42
	local LINE_THICK = 6
	local SEG_COUNT = TRAIL_LEN - 1
	local pathPoints = {}
	for i = 1, PATH_SAMPLES do
		local t = (i - 1) / PATH_SAMPLES * (2 * math.pi)
		local nx = math.sin(t)
		local ny = math.sin(2 * t) * 0.5
		pathPoints[i] = { nx, ny }
	end

	local logoW, logoH = 380, 190
	local cx, cy = logoW * 0.5, logoH * 0.5
	local scaleX, scaleY = 168, 82

	local logoHolder = Instance.new("Frame")
	logoHolder.Name = "InfinityLogo"
	logoHolder.AnchorPoint = Vector2.new(0.5, 0.5)
	logoHolder.Position = UDim2.new(0.5, 0, 0.42, 0)
	logoHolder.Size = UDim2.fromOffset(logoW, logoH)
	logoHolder.BackgroundTransparency = 1
	logoHolder.ClipsDescendants = false
	logoHolder.ZIndex = 101
	logoHolder.Parent = overlay

	local lineSegs = {}
	local lineCorners = {}
	local tearGradT = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 1),
		NumberSequenceKeypoint.new(0.2, 0.12),
		NumberSequenceKeypoint.new(0.5, 0),
		NumberSequenceKeypoint.new(0.8, 0.12),
		NumberSequenceKeypoint.new(1, 1),
	})
	for i = 1, SEG_COUNT do
		local seg = Instance.new("Frame")
		seg.Name = "LineSeg" .. i
		seg.AnchorPoint = Vector2.new(0.5, 0.5)
		seg.BorderSizePixel = 0
		seg.BackgroundColor3 = theme.accent
		seg.ZIndex = 102
		local cr = Instance.new("UICorner")
		cr.CornerRadius = UDim.new(0, LINE_THICK * 0.5)
		cr.Parent = seg
		lineCorners[i] = cr
		-- One UIGradient per frame: soft cross-section like a liquid tear (rounded, not square).
		local g = Instance.new("UIGradient")
		g.Rotation = 90
		g.Transparency = tearGradT
		g.Parent = seg
		seg.Parent = logoHolder
		lineSegs[i] = seg
	end

	local headTear = Instance.new("Frame")
	headTear.Name = "HeadTear"
	headTear.AnchorPoint = Vector2.new(0.5, 0.5)
	headTear.BorderSizePixel = 0
	headTear.BackgroundColor3 = theme.accent
	headTear.Size = UDim2.fromOffset(10, 13)
	headTear.ZIndex = 103
	local headCr = Instance.new("UICorner")
	headCr.CornerRadius = UDim.new(0, 6)
	headCr.Parent = headTear
	local headG = Instance.new("UIGradient")
	headG.Rotation = 90
	headG.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.92),
		NumberSequenceKeypoint.new(0.35, 0.08),
		NumberSequenceKeypoint.new(0.72, 0),
		NumberSequenceKeypoint.new(1, 0.45),
	})
	headG.Parent = headTear
	headTear.Parent = logoHolder

	local arcS = 0.0
	local ARC_SPEED = 54
	local SAMPLE_SPACING = 0.52

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

	local pulseGoal = 0.42
	local tw = TweenService:Create(stroke, TweenInfo.new(2.8, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), {
		Transparency = pulseGoal,
	})
	tw:Play()

	local t0 = os.clock()
	local conn = RunService.RenderStepped:Connect(function(dt)
		local t = os.clock() - t0
		arcS = (arcS + ARC_SPEED * dt) % PATH_SAMPLES
		local phase = (math.sin(t * 0.9) * 0.5 + 0.5)
		stroke.Color = theme.border:Lerp(theme.accent, phase)

		local px = {}
		local py = {}
		for k = 1, TRAIL_LEN do
			local idxFloat = (arcS - (k - 1) * SAMPLE_SPACING) % PATH_SAMPLES
			if idxFloat < 0 then
				idxFloat = idxFloat + PATH_SAMPLES
			end
			local base = math.floor(idxFloat)
			local frac = idxFloat - base
			local i0 = base + 1
			local p0 = pathPoints[i0]
			local p1 = pathPoints[(i0 % PATH_SAMPLES) + 1]
			local nx = p0[1] + (p1[1] - p0[1]) * frac
			local ny = p0[2] + (p1[2] - p0[2]) * frac
			px[k] = cx + nx * scaleX
			py[k] = cy + ny * scaleY
		end

		for i = 1, SEG_COUNT do
			local seg = lineSegs[i]
			local x1, y1 = px[i], py[i]
			local x2, y2 = px[i + 1], py[i + 1]
			local dx = x2 - x1
			local dy = y2 - y1
			local len = math.sqrt(dx * dx + dy * dy)
			if len < 0.25 then
				seg.Visible = false
			else
				seg.Visible = true
				local mx = (x1 + x2) * 0.5
				local my = (y1 + y2) * 0.5
				seg.Position = UDim2.new(0, mx, 0, my)
				seg.Size = UDim2.new(0, len + 0.5, 0, LINE_THICK)
				seg.Rotation = math.deg(math.atan2(dy, dx))
				local capR = math.clamp(math.min(len * 0.5, LINE_THICK * 0.5), 1, LINE_THICK * 0.5)
				lineCorners[i].CornerRadius = UDim.new(0, capR)
				local fade = (i - 1) / math.max(1, SEG_COUNT - 1)
				seg.BackgroundTransparency = 0.03 + 0.86 * fade
				if i <= 3 then
					seg.BackgroundTransparency = math.clamp(seg.BackgroundTransparency - 0.12, 0, 1)
				end
			end
		end

		local hdx = px[2] - px[1]
		local hdy = py[2] - py[1]
		local hlen = math.sqrt(hdx * hdx + hdy * hdy)
		if hlen < 0.2 then
			headTear.Visible = false
		else
			headTear.Visible = true
			headTear.Position = UDim2.new(0, px[1], 0, py[1])
			headTear.Rotation = math.deg(math.atan2(hdy, hdx)) + 90
		end
		local dots = 1 + (math.floor(t * 0.7) % 4)
		status.Text = "Loading" .. string.rep(".", dots)
	end)

	return function()
		if conn then
			conn:Disconnect()
			conn = nil
		end
		tw:Cancel()
		if overlay and overlay.Parent then
			overlay:Destroy()
		end
	end
end

return {
	mountHubLoadingOverlay = mountHubLoadingOverlay,
}
