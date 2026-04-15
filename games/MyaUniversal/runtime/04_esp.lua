local function esp_clear()
	for _, h in pairs(highlights) do
		pcall(function()
			h:Destroy()
		end)
	end
	highlights = {}
end

local function esp_refresh()
	esp_clear()
	if not esp_on then
		return
	end
	for _, plr in ipairs(Players:GetPlayers()) do
		if plr ~= lp and plr.Character and not is_teammate(plr) then
			local hl = Instance.new("Highlight")
			hl.Name = "MyaUniESP"
			hl.Adornee = plr.Character
			hl.FillColor = Color3.fromRGB(255, 90, 140)
			hl.OutlineColor = Color3.fromRGB(255, 255, 255)
			hl.FillTransparency = 0.55
			hl.OutlineTransparency = 0.3
			hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
			hl.Parent = esp_gui
			highlights[plr] = hl
		end
	end
end
