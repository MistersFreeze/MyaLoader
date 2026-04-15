local function aim_step()
	if not aim_on or not camera then
		return
	end
	if not bind_pressed(aim_bind) then
		aim_remainder_x, aim_remainder_y = 0, 0
		return
	end

	local best_screen = select(1, get_best_target(aim_assist_fov))
	if not best_screen then
		aim_remainder_x, aim_remainder_y = 0, 0
		return
	end

	local vp = camera.ViewportSize
	local center = Vector2.new(vp.X / 2, vp.Y / 2)
	local dx = best_screen.X - center.X
	local dy = best_screen.Y - center.Y

	local actual_speed = math.pow(aim_speed, 3)
	if typeof(mousemoverel) ~= "function" then
		return
	end

	if aim_speed >= 1.0 then
		mousemoverel(dx, dy)
		aim_remainder_x, aim_remainder_y = 0, 0
	else
		aim_remainder_x = aim_remainder_x + (dx * actual_speed)
		aim_remainder_y = aim_remainder_y + (dy * actual_speed)
		local move_x = math.round(aim_remainder_x)
		local move_y = math.round(aim_remainder_y)
		if move_x ~= 0 or move_y ~= 0 then
			mousemoverel(move_x, move_y)
			aim_remainder_x = aim_remainder_x - move_x
			aim_remainder_y = aim_remainder_y - move_y
		end
	end
end
