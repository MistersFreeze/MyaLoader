local function triggerbot_step()
	if not triggerbot_on or not camera then
		return
	end
	if not bind_pressed(trigger_bind) then
		return
	end
	local t = tick()
	if t < trigger_next then
		return
	end
	local _, worldPos, char = get_best_target(trigger_fov)
	if not worldPos or not char then
		return
	end
	if typeof(mouse1click) == "function" then
		mouse1click()
		trigger_next = t + trigger_delay
	end
end
