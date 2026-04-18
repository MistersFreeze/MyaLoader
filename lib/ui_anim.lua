--[[
  Hub loading visuals for Mya: pure UI (no stock spinner assets), theme accent only.
]]

local RunService = game:GetService("RunService")

--- Vertical “spectrum” bars — staggered sine wave, pink from `accent` only.
--- Returns holder frame and a cancel function (disconnects animation; does not destroy holder).
local function createSpectrumLoader(parent: Instance, accent: Color3): (Frame, () -> ())
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
	local bars: { Frame } = {}
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
	local conn: RBXScriptConnection? = nil
	conn = RunService.RenderStepped:Connect(function()
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
		if conn then
			conn:Disconnect()
			conn = nil
		end
	end

	return holder, cancel
end

return {
	createSpectrumLoader = createSpectrumLoader,
}
