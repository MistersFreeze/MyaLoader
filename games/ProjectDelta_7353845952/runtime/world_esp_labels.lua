-- World ESP: Drawing.Text labels keyed by Model (same pattern as esp_distance name tags).
local world_labels = {}

function world_clear_all_labels()
	for m, d in pairs(world_labels) do
		pcall(function()
			d:Remove()
		end)
		world_labels[m] = nil
	end
end

function ensure_world_label(m, kind)
	local d = world_labels[m]
	if d then
		return d
	end
	if not drawing_ok then
		return nil
	end
	local t = Drawing.new("Text")
	t.Visible = false
	t.Size = 14
	t.Center = true
	t.Outline = true
	if kind == "npc" then
		t.Color = Color3.fromRGB(120, 220, 160)
	elseif kind == "crate" then
		t.Color = Color3.fromRGB(240, 200, 120)
	elseif kind == "corpse" then
		t.Color = Color3.fromRGB(180, 140, 200)
	elseif kind == "landmine" then
		t.Color = Color3.fromRGB(255, 90, 70)
	elseif kind == "extraction" then
		t.Color = Color3.fromRGB(90, 230, 255)
	else
		t.Color = Color3.fromRGB(120, 180, 255)
	end
	world_labels[m] = t
	return t
end

function get_world_labels()
	return world_labels
end
