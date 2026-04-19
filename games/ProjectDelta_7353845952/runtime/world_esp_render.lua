-- World ESP: per-frame update + unload (ties together scan, labels, fullbright).

local function world_kind_enabled(kind)
	if kind == "npc" then
		return npc_esp_on
	end
	if kind == "crate" then
		return crate_esp_on
	end
	if kind == "corpse" then
		return corpse_esp_on
	end
	if kind == "vehicle" then
		return vehicle_esp_on
	end
	if kind == "landmine" then
		return landmine_esp_on
	end
	if kind == "extraction" then
		return extraction_esp_on
	end
	return true
end

function update_world_esp()
	sync_fullbright()

	if not world_pool_scan_enabled() then
		for _, d in pairs(get_world_labels()) do
			d.Visible = false
		end
		return
	end

	maybe_refresh_world_pool()

	local labels = get_world_labels()
	local pool = get_world_pool()

	if not drawing_ok or not camera then
		for _, d in pairs(labels) do
			d.Visible = false
		end
		return
	end

	local myRoot = get_root()
	if not myRoot then
		for _, d in pairs(labels) do
			d.Visible = false
		end
		return
	end

	for m in pairs(labels) do
		if not m.Parent then
			pcall(function()
				labels[m]:Remove()
			end)
			labels[m] = nil
		end
	end

	local active = {}
	for _, entry in ipairs(pool) do
		local m, kind, part = entry.m, entry.kind, entry.part
		local mineTag = entry.mineTag
		if world_kind_enabled(kind) and m.Parent and part.Parent then
			local dist = (myRoot.Position - part.Position).Magnitude
			local maxd = kind == "crate" and crate_esp_max_dist
				or kind == "corpse" and corpse_esp_max_dist
				or world_esp_other_max
			if dist <= maxd then
				active[m] = true
				local d = ensure_world_label(m, kind)
				if d then
					local pos, onScreen = camera:WorldToViewportPoint(part.Position + Vector3.new(0, 2, 0))
					if onScreen and pos.Z > 0 then
						d.Position = Vector2.new(pos.X, pos.Y)
						local tag = kind == "npc" and "NPC"
							or kind == "crate" and "Crate"
							or kind == "corpse" and "Corpse"
							or kind == "landmine" and (mineTag or "Landmine")
							or kind == "extraction" and "Extract"
							or "Vehicle"
						d.Text = string.format("%s [%.0fm]", tag, dist)
						d.Visible = true
					else
						d.Visible = false
					end
				end
			end
		end
	end

	for m, d in pairs(labels) do
		if not active[m] then
			d.Visible = false
		end
	end
end

function world_esp_unload()
	world_clear_all_labels()
	restore_fullbright_on_unload()
	invalidate_world_pool()
end
