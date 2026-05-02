-- AR2: no flight / noclip / walk-speed module. Stubs satisfy exports + render_hooks;
-- keeps hook_players (ESP refresh + highlight cleanup on leave) from universal movement.lua.

local function refresh_movement() end

local function restore_movement() end

local function start_fly() end

local function stop_fly() end

local function start_noclip() end

local function stop_noclip() end

local function hook_other(plr)
	if plr == lp then
		return
	end
	plr.CharacterAdded:Connect(function()
		if esp_on then
			task.defer(esp_refresh)
		end
	end)
end

local function hook_players()
	for _, plr in ipairs(Players:GetPlayers()) do
		hook_other(plr)
	end
	table.insert(
		connections,
		Players.PlayerAdded:Connect(function(plr)
			hook_other(plr)
			task.defer(esp_refresh)
		end)
	)
	table.insert(
		connections,
		Players.PlayerRemoving:Connect(function(plr)
			local h = highlights[plr]
			if h then
				if type(h) == "table" then
					for _, x in ipairs(h) do
						pcall(function()
							x:Destroy()
						end)
					end
				else
					pcall(function()
						h:Destroy()
					end)
				end
				highlights[plr] = nil
			end
			remove_health_draw(plr)
			pcall(function()
				if _G.remove_distance_draw then
					_G.remove_distance_draw(plr)
				end
			end)
			pcall(function()
				if _G.remove_name_draw then
					_G.remove_name_draw(plr)
				end
			end)
		end)
	)
end
