-- Fullbright: save/restore Lighting once, apply while enabled (Project Delta).
local Lighting = game:GetService("Lighting")

local lighting_saved = false
local saved_ambient, saved_brightness, saved_outdoor, saved_color_shift_top, saved_color_shift_bottom

function sync_fullbright()
	if fullbright_on then
		if not lighting_saved then
			saved_ambient = Lighting.Ambient
			saved_brightness = Lighting.Brightness
			saved_outdoor = Lighting.OutdoorAmbient
			saved_color_shift_top = Lighting.ColorShift_Top
			saved_color_shift_bottom = Lighting.ColorShift_Bottom
			lighting_saved = true
		end
		Lighting.Ambient = Color3.fromRGB(198, 198, 210)
		Lighting.OutdoorAmbient = Color3.fromRGB(175, 175, 190)
		Lighting.Brightness = 3
		Lighting.ColorShift_Top = Color3.fromRGB(255, 255, 255)
		Lighting.ColorShift_Bottom = Color3.fromRGB(210, 210, 220)
	else
		if lighting_saved then
			Lighting.Ambient = saved_ambient
			Lighting.Brightness = saved_brightness
			Lighting.OutdoorAmbient = saved_outdoor
			Lighting.ColorShift_Top = saved_color_shift_top
			Lighting.ColorShift_Bottom = saved_color_shift_bottom
		end
	end
end

function restore_fullbright_on_unload()
	if lighting_saved then
		Lighting.Ambient = saved_ambient
		Lighting.Brightness = saved_brightness
		Lighting.OutdoorAmbient = saved_outdoor
		Lighting.ColorShift_Top = saved_color_shift_top
		Lighting.ColorShift_Bottom = saved_color_shift_bottom
	end
	lighting_saved = false
end
