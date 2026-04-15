if drawing_ok then
	fov_circle_aim = Drawing.new("Circle")
	fov_circle_aim.Visible = false
	fov_circle_aim.Filled = false
	fov_circle_aim.Thickness = 1
	fov_circle_aim.Color = color_fov_aim
	fov_circle_aim.NumSides = 64
	fov_circle_aim.Transparency = 0.5

	fov_circle_silent = Drawing.new("Circle")
	fov_circle_silent.Visible = false
	fov_circle_silent.Filled = false
	fov_circle_silent.Thickness = 1
	fov_circle_silent.Color = color_fov_silent
	fov_circle_silent.NumSides = 64
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
	local c = Vector2.new(vp.X / 2, vp.Y / 2)
	if show_aim_fov_circle and fov_circle_aim then
		fov_circle_aim.Position = c
		fov_circle_aim.Radius = aim_assist_fov
		fov_circle_aim.Visible = true
	elseif fov_circle_aim then
		fov_circle_aim.Visible = false
	end
	if show_silent_fov_circle and fov_circle_silent then
		fov_circle_silent.Position = c
		fov_circle_silent.Radius = silent_fov
		fov_circle_silent.Visible = true
	elseif fov_circle_silent then
		fov_circle_silent.Visible = false
	end
end
