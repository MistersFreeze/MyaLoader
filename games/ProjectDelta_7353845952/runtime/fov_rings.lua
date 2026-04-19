if drawing_ok then
	fov_circle_aim = Drawing.new("Circle")
	fov_circle_aim.Visible = false
	fov_circle_aim.Filled = false
	fov_circle_aim.Thickness = 1
	fov_circle_aim.Color = color_fov_aim
	fov_circle_aim.NumSides = 32
	fov_circle_aim.Transparency = 0.5

	fov_circle_silent = Drawing.new("Circle")
	fov_circle_silent.Visible = false
	fov_circle_silent.Filled = false
	fov_circle_silent.Thickness = 1
	fov_circle_silent.Color = color_fov_silent
	fov_circle_silent.NumSides = 32
	fov_circle_silent.Transparency = 0.5
end

local function update_fov_circles()
	if not drawing_ok or not camera then
		if fov_circle_aim then
			fov_circle_aim.Visible = false
		end
		if fov_circle_silent then
			fov_circle_silent.Visible = false
		end
		return
	end
	local vp = camera.ViewportSize
	local center = Vector2.new(vp.X / 2, vp.Y / 2)
	local aim_pos = aim_fov_follow_cursor and get_fov_screen_anchor(true) or center
	if aim_on and show_aim_fov_circle and fov_circle_aim then
		fov_circle_aim.Position = aim_pos
		fov_circle_aim.Radius = aim_assist_fov
		fov_circle_aim.Visible = true
	elseif fov_circle_aim then
		fov_circle_aim.Visible = false
	end

	local silent_pos = silent_aim_fov_follow_cursor and get_fov_screen_anchor(true) or center
	if silent_aim_on and show_silent_aim_fov_circle and fov_circle_silent then
		fov_circle_silent.Position = silent_pos
		fov_circle_silent.Radius = silent_aim_fov
		fov_circle_silent.Visible = true
	elseif fov_circle_silent then
		fov_circle_silent.Visible = false
	end
end
