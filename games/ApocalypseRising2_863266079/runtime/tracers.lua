-- Screen tracers: bottom-center of viewport → target upper body (Drawing API).
local tracer_draw = {}
local tracers_on = (_G.MYA_UNIVERSAL_CONFIG and _G.MYA_UNIVERSAL_CONFIG.tracers_on) == true

local function tracer_remove(plr)
	local t = tracer_draw[plr]
	if t and t.line then
		pcall(function()
			t.line:Remove()
		end)
	end
	tracer_draw[plr] = nil
end

local function tracers_clear_all()
	for plr in pairs(tracer_draw) do
		tracer_remove(plr)
	end
end

local function tracer_get_line(plr)
	local t = tracer_draw[plr]
	if t and t.line then
		return t.line
	end
	if not drawing_ok then
		return nil
	end
	local line = Drawing.new("Line")
	line.Thickness = 1
	line.Visible = false
	line.Color = Color3.fromRGB(255, 140, 180)
	line.Transparency = 0.25
	tracer_draw[plr] = { line = line }
	return line
end

local function update_tracers()
	if not _G.MYA_UNIVERSAL_LOADED then
		return
	end
	if not drawing_ok or not camera then
		return
	end
	if not tracers_on then
		for plr, t in pairs(tracer_draw) do
			if t.line then
				t.line.Visible = false
			end
		end
		return
	end

	local vp = camera.ViewportSize
	local from = Vector2.new(vp.X * 0.5, vp.Y - 2)

	for _, plr in ipairs(Players:GetPlayers()) do
		if plr ~= lp and plr.Parent and plr.Character and not is_esp_teammate(plr) and esp_target_within_max_range(plr) then
			local char = plr.Character
			local hum = char:FindFirstChildWhichIsA("Humanoid")
			if hum and hum.Health > 0 then
				local part = char:FindFirstChild("UpperTorso")
					or char:FindFirstChild("Torso")
					or char:FindFirstChild("HumanoidRootPart")
					or char:FindFirstChild("Head")
				if part and part:IsA("BasePart") then
					local v, on = camera:WorldToViewportPoint(part.Position)
					if on then
						local line = tracer_get_line(plr)
						if line then
							line.From = from
							line.To = Vector2.new(v.X, v.Y)
							line.Visible = true
						end
					else
						local t = tracer_draw[plr]
						if t and t.line then
							t.line.Visible = false
						end
					end
				end
			end
		else
			tracer_remove(plr)
		end
	end

	for plr in pairs(tracer_draw) do
		if not plr.Parent then
			tracer_remove(plr)
		end
	end
end

local tracers_conn = RunService.RenderStepped:Connect(update_tracers)
table.insert(connections, tracers_conn)

local MU = _G.MYA_UNIVERSAL
if type(MU) == "table" then
	MU.get_tracers = function()
		return tracers_on
	end
	MU.set_tracers = function(v)
		tracers_on = not not v
		if not tracers_on then
			tracers_clear_all()
		end
	end
end

do
	local old_get = _G.get_config
	if typeof(old_get) == "function" then
		_G.get_config = function()
			local t = old_get()
			if type(t) == "table" then
				t.tracers_on = tracers_on
			end
			return t
		end
	end
	local old_apply = _G.apply_config
	if typeof(old_apply) == "function" then
		_G.apply_config = function(cfg)
			old_apply(cfg)
			if type(cfg) == "table" and cfg.tracers_on ~= nil then
				tracers_on = not not cfg.tracers_on
				if not tracers_on then
					tracers_clear_all()
				end
			end
		end
	end
	local old_unload = _G.unload_mya_universal
	if typeof(old_unload) == "function" then
		_G.unload_mya_universal = function()
			tracers_clear_all()
			return old_unload()
		end
	end
end
