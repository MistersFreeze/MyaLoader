local function render_frame()
	if not _G.MYA_PROJECT_DELTA_LOADED then
		return
	end
	maybe_repair_esp_highlights()
	update_fov_circles()
	update_health_bars()
	if esp_distance_on and esp_names_on then
		update_esp_distance_names_combined()
	else
		update_esp_distance()
		update_esp_names()
	end
	update_esp_visibility_colors()
	update_esp_view_angle()
	update_world_esp()
	sync_remove_rain()
	aim_step()
	triggerbot_step()
	weapon_mod_step()
end

render_conn = RunService.RenderStepped:Connect(render_frame)
table.insert(connections, render_conn)

hook_players()
table.insert(
	connections,
	lp:GetPropertyChangedSignal("Team"):Connect(function()
		esp_refresh()
	end)
)
table.insert(
	connections,
	lp.CharacterAdded:Connect(function()
		task.defer(function()
			if esp_on then
				esp_refresh()
			end
		end)
	end)
)
