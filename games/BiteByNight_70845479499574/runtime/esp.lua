local function update_survivor_esp()
	if not settings.survivor_esp then
		hide_all(survivor_highlights)
		return
	end
	local seen = {}
	for _, plr in ipairs(Players:GetPlayers()) do
		if plr ~= lp then
			local model = plr.Character
			if model and model:IsA("Model") and model.Parent and model:IsDescendantOf(Workspace) then
				local parent_name = model.Parent.Name
				local is_survivorish = (parent_name == "ALIVE") or (parent_name ~= "KILLER" and parent_name ~= "LOBBY")
				if not is_survivorish then
					continue
				end
			seen[model] = true
			local h = ensure_highlight(
				survivor_highlights,
				model,
				"MyaBiteSurvivorESP",
				Color3.fromRGB(255, 170, 210)
			)
			h.Adornee = model
			h.Enabled = true
			end
		end
	end
	for key in pairs(survivor_highlights) do
		if not seen[key] then
			cleanup_key(survivor_highlights, key)
		end
	end
end

local function update_killer_esp()
	if not settings.killer_esp then
		hide_all(killer_highlights)
		return
	end
	local killer = get_killer_folder()
	if not killer then
		hide_all(killer_highlights)
		return
	end
	local seen = {}
	for _, model in ipairs(killer:GetChildren()) do
		if model ~= lp.Character and model:IsA("Model") then
			seen[model] = true
			local h = ensure_highlight(killer_highlights, model, "MyaBiteKillerESP", Color3.fromRGB(255, 45, 45))
			h.Adornee = model
			h.Enabled = true
		end
	end
	for key in pairs(killer_highlights) do
		if not seen[key] then
			cleanup_key(killer_highlights, key)
		end
	end
end

local function update_generator_esp()
	if not settings.generator_esp then
		hide_all(generator_highlights)
		return
	end
	local gens = get_generators_folder()
	if not gens then
		hide_all(generator_highlights)
		return
	end
	local seen = {}
	for _, model in ipairs(gens:GetChildren()) do
		if model:IsA("Model") then
			seen[model] = true
			local h = ensure_highlight(
				generator_highlights,
				model,
				"MyaBiteGeneratorESP",
				Color3.fromRGB(255, 220, 120)
			)
			h.Adornee = model
			h.Enabled = true
		end
	end
	for key in pairs(generator_highlights) do
		if not seen[key] then
			cleanup_key(generator_highlights, key)
		end
	end
end

local function update_batteries_esp()
	if not settings.batteries_esp then
		hide_all(battery_highlights)
		return
	end
	local batteries = get_batteries_folder()
	if not batteries then
		hide_all(battery_highlights)
		return
	end
	local seen = {}
	for _, model in ipairs(batteries:GetChildren()) do
		if model:IsA("Model") or model:IsA("BasePart") then
			seen[model] = true
			local h = ensure_highlight(
				battery_highlights,
				model,
				"MyaBiteBatteryESP",
				Color3.fromRGB(120, 220, 255)
			)
			h.Adornee = model
			h.Enabled = true
		end
	end
	for key in pairs(battery_highlights) do
		if not seen[key] then
			cleanup_key(battery_highlights, key)
		end
	end
end

local function runtime_step()
	cleanup_stale(survivor_highlights)
	cleanup_stale(killer_highlights)
	cleanup_stale(generator_highlights)
	cleanup_stale(battery_highlights)
	update_survivor_esp()
	update_killer_esp()
	update_generator_esp()
	update_batteries_esp()
end

