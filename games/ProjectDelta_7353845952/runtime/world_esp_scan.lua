-- World ESP: scan Workspace for NPCs, crates, corpses, vehicles, landmine hazards (landmine, claymore, trap), extraction (heuristics + attributes).
local world_pool = {}
local last_scan_t = 0
-- Full scans are expensive; defer off render + longer interval reduces hitching.
local SCAN_INTERVAL = 4.0
local refresh_queued = false
-- Real characters are compact; foliage assemblies often have huge part counts.
local MAX_CHARACTER_BODY_PARTS = 88

function invalidate_world_pool()
	world_pool = {}
	last_scan_t = 0
	refresh_queued = false
end

function world_pool_scan_enabled()
	return npc_esp_on
		or crate_esp_on
		or corpse_esp_on
		or vehicle_esp_on
		or landmine_esp_on
		or extraction_esp_on
end

local CollectionService = nil
pcall(function()
	CollectionService = game:GetService("CollectionService")
end)

local function get_world_anchor(m)
	local p = m:FindFirstChild("HumanoidRootPart") or m:FindFirstChildWhichIsA("BasePart")
	if p and p:IsA("BasePart") then
		return p
	end
	return nil
end

local function is_under_terrain(inst)
	local p = inst
	while p do
		if p:IsA("Terrain") then
			return true
		end
		p = p.Parent
	end
	return false
end

-- Block obvious map / foliage names (reduces corpses & NPCs on trees, rocks, decor).
local ENV_NAME_HINTS = {
	"tree",
	"trees",
	"bush",
	"bushes",
	"foliage",
	"leaves",
	"leaf",
	"branch",
	"branches",
	"stump",
	"log",
	"pine",
	"oak",
	"birch",
	"rock",
	"rocks",
	"boulder",
	"stone",
	"pebble",
	"cliff",
	"grass",
	"fern",
	"moss",
	"ivy",
	"vine",
	"hay",
	"straw",
	"vegetation",
	"forest",
	"woodpile",
	"deco",
	"decor",
	"prop",
	"static",
	"building",
	"house",
	"roof",
	"wall",
	"walls",
	"fence",
	"barrier",
	"pillar",
	"road",
	"bridge",
	"rail",
	"sign",
	"lamp",
	"light",
	"post",
	"pole",
	"debris",
	"rubble",
	"junk",
	"scrap",
	"terrain",
	"foli",
	"canopy",
	"sapling",
	"twig",
	"hedge",
	"shrub",
	"thicket",
	"grove",
}

local function is_likely_map_prop_name(nameLower)
	for i = 1, #ENV_NAME_HINTS do
		if nameLower:find(ENV_NAME_HINTS[i], 1, true) then
			return true
		end
	end
	return false
end

-- Humanoid corpses/NPCs should look like a character rig, not a huge map chunk.
local function looks_like_character_rig(m)
	if is_under_terrain(m) then
		return false
	end
	local n = m.Name:lower()
	if is_likely_map_prop_name(n) then
		return false
	end
	local hum = m:FindFirstChildWhichIsA("Humanoid")
	if not hum then
		return false
	end
	local rt = hum.RigType
	if rt ~= Enum.HumanoidRigType.R15 and rt ~= Enum.HumanoidRigType.R6 and rt ~= Enum.HumanoidRigType.Custom then
		return false
	end
	local head = m:FindFirstChild("Head")
	local hrp = m:FindFirstChild("HumanoidRootPart")
	local torso = m:FindFirstChild("Torso") or m:FindFirstChild("UpperTorso")
	if not head and not hrp and not torso then
		return false
	end
	local ok, ext = pcall(function()
		return m:GetExtentsSize()
	end)
	if ok and ext then
		local mag = ext.Magnitude
		if mag > 135 or ext.X > 72 or ext.Z > 72 or ext.Y > 118 then
			return false
		end
	end
	local bp = 0
	for _, d in ipairs(m:GetDescendants()) do
		if d:IsA("BasePart") then
			bp = bp + 1
			if bp > MAX_CHARACTER_BODY_PARTS then
				return false
			end
		end
	end
	return true
end

local function model_has_collection_tag(m, tags)
	if not CollectionService then
		return false
	end
	for _, tag in ipairs(tags) do
		if CollectionService:HasTag(m, tag) then
			return true
		end
	end
	return false
end

-- Landmine toggle covers landmines, claymores, and tripwire/bear traps (former separate Trap ESP).
local function classify_landmine_model(m)
	if m:FindFirstChildWhichIsA("Humanoid") then
		return nil
	end
	local ap = get_world_anchor(m)
	if not ap then
		return nil
	end
	if is_under_terrain(m) then
		return nil
	end
	if m:GetAttribute("Trap") ~= nil or m:GetAttribute("IsTrap") ~= nil or m:GetAttribute("TrapType") ~= nil then
		return "landmine", "Trap"
	end
	if model_has_collection_tag(m, { "Trap", "Tripwire", "Hazard" }) then
		return "landmine", "Trap"
	end
	if m:GetAttribute("Landmine") ~= nil or m:GetAttribute("IsLandmine") ~= nil or m:GetAttribute("MineType") ~= nil then
		return "landmine", "Landmine"
	end
	if model_has_collection_tag(m, { "Landmine", "Mine", "ExplosiveMine" }) then
		return "landmine", "Landmine"
	end
	local n = m.Name:lower()
	if is_likely_map_prop_name(n) then
		return nil
	end
	if n:find("claymore") then
		return "landmine", "Claymore"
	end
	if n:find("trap") or n:find("tripwire") or n:find("trip wire") or n:find("beartrap") or n:find("snare") then
		return "landmine", "Trap"
	end
	if n:find("landmine") or n:find("apmine") or n:find("a%-mine") or n:find("anti personnel") then
		return "landmine", "Landmine"
	end
	return nil
end

local function extraction_attribute_hit(inst)
	if not inst then
		return false
	end
	return inst:GetAttribute("Extraction") ~= nil
		or inst:GetAttribute("ExtractionPoint") ~= nil
		or inst:GetAttribute("ExtractionZone") ~= nil
		or inst:GetAttribute("ExtractPoint") ~= nil
		or inst:GetAttribute("Extract") ~= nil
		or inst:GetAttribute("Exfil") ~= nil
		or inst:GetAttribute("ExfilPoint") ~= nil
		or inst:GetAttribute("Evac") ~= nil
		or inst:GetAttribute("EvacPoint") ~= nil
		or inst:GetAttribute("EvacuationPoint") ~= nil
		or inst:GetAttribute("IsExtraction") ~= nil
		or inst:GetAttribute("IsExfil") ~= nil
		or inst:GetAttribute("Exit") ~= nil
		or inst:GetAttribute("ExitPoint") ~= nil
		or inst:GetAttribute("Helipad") ~= nil
		or inst:GetAttribute("LZ") ~= nil
		or inst:GetAttribute("LandingZone") ~= nil
end

local function extraction_name_hit(n)
	if type(n) ~= "string" then
		return false
	end
	n = n:lower()
	return n:find("extraction", 1, true)
		or n:find("exfil", 1, true)
		or n:find("evacuation", 1, true)
		or n:find("extract point", 1, true)
		or n:find("extractpoint", 1, true)
		or n:find("evac point", 1, true)
		or n:find("evacpoint", 1, true)
		or n:find("exfilpoint", 1, true)
		or n:find("helipad", 1, true)
		or n:find("landing zone", 1, true)
		or n:find("landingzone", 1, true)
		or (n:find("extract", 1, true) and (n:find("zone", 1, true) or n:find("point", 1, true) or n:find("heli", 1, true) or n:find("area", 1, true)))
		or (n:find("heli", 1, true) and n:find("extract", 1, true))
		or (n:find("evac", 1, true) and (n:find("zone", 1, true) or n:find("point", 1, true)))
		or (n:find("lz", 1, true) and (n:find("extract", 1, true) or n:find("evac", 1, true) or n:find("heli", 1, true)))
end

local function classify_extraction_model(m)
	if not extraction_esp_on then
		return nil
	end
	if m:FindFirstChildWhichIsA("Humanoid") then
		return nil
	end
	local ap = get_world_anchor(m)
	if not ap then
		return nil
	end
	if is_under_terrain(m) then
		return nil
	end
	if extraction_attribute_hit(m) then
		return "extraction"
	end
	do
		local p = m.Parent
		while p and p ~= Workspace do
			if p:IsA("Model") and extraction_attribute_hit(p) then
				return "extraction"
			end
			p = p.Parent
		end
	end
	if model_has_collection_tag(m, { "Extraction", "Exfil", "Evacuation", "Extract", "ExtractionPoint", "HeliExtract", "ExfilPoint", "EvacPoint", "Helipad", "LandingZone" }) then
		return "extraction"
	end
	local n = m.Name
	if extraction_name_hit(n) then
		return "extraction"
	end
	if is_likely_map_prop_name(n:lower()) then
		return nil
	end
	return nil
end

local function classify_world_model(m)
	if vehicle_esp_on and m:GetAttribute("Vehicle") ~= nil and m:GetAttribute("Vehicle") ~= false then
		local ap = get_world_anchor(m)
		if ap then
			return "vehicle"
		end
	end

	if extraction_esp_on then
		local ex = classify_extraction_model(m)
		if ex then
			return ex
		end
	end

	if landmine_esp_on then
		local lm, mineTag = classify_landmine_model(m)
		if lm then
			return lm, mineTag
		end
	end

	local hum = m:FindFirstChildWhichIsA("Humanoid")
	local plr = Players:GetPlayerFromCharacter(m)
	if hum then
		if is_under_terrain(m) then
			return nil
		end
		local dead = hum.Health <= 0
		if not dead then
			pcall(function()
				if hum:GetState() == Enum.HumanoidStateType.Dead then
					dead = true
				end
			end)
		end
		if dead then
			if corpse_esp_on and looks_like_character_rig(m) then
				return "corpse"
			end
			return nil
		end
		if plr then
			return nil
		end
		if npc_esp_on and looks_like_character_rig(m) then
			return "npc"
		end
		return nil
	end

	if crate_esp_on then
		local ct = m:GetAttribute("ContainerType")
		if ct and not m:GetAttribute("NotLootable") then
			local ap = get_world_anchor(m)
			if ap then
				return "crate"
			end
		end
		local n = m.Name:lower()
		-- Avoid generic "container" (matches foliage / world containers).
		if n:find("crate") or n:find("supply") or n:find("loot") or n:find("ammo") or n:find("ammobox") then
			local ap = get_world_anchor(m)
			if ap then
				return "crate"
			end
		end
	end

	if vehicle_esp_on then
		local n = m.Name:lower()
		if n:find("vehicle") or n:find("jeep") or n:find("truck") or n:find("heli") or n:find("van") or n:find("tank") then
			local ap = get_world_anchor(m)
			if ap then
				return "vehicle"
			end
		end
	end

	return nil
end

local function is_under_local_character(inst)
	local c = lp.Character
	return c and inst:IsDescendantOf(c)
end

-- Tagged instances only — O(number tagged), not O(all parts).
-- (CollectionService tag name, label for Drawing text)
local TAG_MINE_HAZARDS = {
	{ "Landmine", "Landmine" },
	{ "Mine", "Landmine" },
	{ "ExplosiveMine", "Landmine" },
	{ "Claymore", "Claymore" },
	{ "APMine", "Landmine" },
	{ "Trap", "Trap" },
	{ "Tripwire", "Trap" },
}
local TAG_EXTRACT = {
	"Extraction",
	"Exfil",
	"Evacuation",
	"Extract",
	"ExtractionPoint",
	"HeliExtract",
	"ExfilPoint",
	"EvacPoint",
	"Helipad",
	"LandingZone",
	"ExtractionZone",
}

local function push_pool_entry(pool, seen, classified_models, m, kind, part, mineTag)
	if not part or seen[part] then
		return
	end
	seen[part] = true
	if m:IsA("Model") then
		classified_models[m] = true
	end
	pool[#pool + 1] = { m = m, kind = kind, part = part, mineTag = mineTag }
end

local function append_tagged_instances(pool, seen, classified_models)
	if not CollectionService then
		return
	end
	local function scan_mine_hazard_tags()
		if not landmine_esp_on then
			return
		end
		for ti = 1, #TAG_MINE_HAZARDS do
			local pair = TAG_MINE_HAZARDS[ti]
			local tagName = pair[1]
			local mineLabel = pair[2]
			local ok, tagged = pcall(function()
				return CollectionService:GetTagged(tagName)
			end)
			if ok and tagged then
				for ii = 1, #tagged do
					local inst = tagged[ii]
					if inst.Parent and not is_under_local_character(inst) and not is_under_terrain(inst) then
						if inst:IsA("Model") then
							local ap = get_world_anchor(inst)
							if ap then
								push_pool_entry(pool, seen, classified_models, inst, "landmine", ap, mineLabel)
							end
						elseif inst:IsA("BasePart") and not inst:IsA("Terrain") then
							push_pool_entry(pool, seen, classified_models, inst, "landmine", inst, mineLabel)
						end
					end
				end
			end
		end
	end
	local function scan_tag_list_simple(tags, kind, enabled)
		if not enabled then
			return
		end
		for ti = 1, #tags do
			local tagName = tags[ti]
			local ok, tagged = pcall(function()
				return CollectionService:GetTagged(tagName)
			end)
			if ok and tagged then
				for ii = 1, #tagged do
					local inst = tagged[ii]
					if inst.Parent and not is_under_local_character(inst) and not is_under_terrain(inst) then
						if inst:IsA("Model") then
							local ap = get_world_anchor(inst)
							if ap then
								push_pool_entry(pool, seen, classified_models, inst, kind, ap, nil)
							end
						elseif inst:IsA("BasePart") and not inst:IsA("Terrain") then
							push_pool_entry(pool, seen, classified_models, inst, kind, inst, nil)
						end
					end
				end
			end
		end
	end
	scan_mine_hazard_tags()
	scan_tag_list_simple(TAG_EXTRACT, "extraction", extraction_esp_on)
end

local function ancestor_in_classified_model(inst, classified_models)
	local p = inst.Parent
	while p and p ~= Workspace do
		if p:IsA("Model") and classified_models[p] then
			return true
		end
		p = p.Parent
	end
	return false
end

-- Loose BaseParts near the player only (engine query — no full-map descendant walk).
-- Attributes/tags are often on a parent Model; the overlap query returns a child part.
local function ancestor_has_landmine_markers(inst)
	local p = inst
	local d = 0
	while p and p ~= Workspace and d < 12 do
		if
			p:GetAttribute("Landmine") ~= nil
			or p:GetAttribute("IsLandmine") ~= nil
			or p:GetAttribute("MineType") ~= nil
		then
			return true
		end
		if CollectionService then
			if
				CollectionService:HasTag(p, "Landmine")
				or CollectionService:HasTag(p, "Mine")
				or CollectionService:HasTag(p, "ExplosiveMine")
			then
				return true
			end
		end
		p = p.Parent
		d = d + 1
	end
	return false
end

local function ancestor_has_trap_markers(inst)
	local p = inst
	local d = 0
	while p and p ~= Workspace and d < 12 do
		if p:GetAttribute("Trap") ~= nil or p:GetAttribute("IsTrap") ~= nil or p:GetAttribute("TrapType") ~= nil then
			return true
		end
		if CollectionService and (CollectionService:HasTag(p, "Trap") or CollectionService:HasTag(p, "Tripwire")) then
			return true
		end
		p = p.Parent
		d = d + 1
	end
	return false
end

local function classify_mine_hazard_loose_part(inst)
	if not landmine_esp_on or not inst:IsA("BasePart") or inst:IsA("Terrain") then
		return nil
	end
	if ancestor_has_trap_markers(inst) then
		return "landmine", "Trap"
	end
	if ancestor_has_landmine_markers(inst) then
		local p = inst
		for _ = 0, 11 do
			if not p or p == Workspace then
				break
			end
			if CollectionService and CollectionService:HasTag(p, "Claymore") then
				return "landmine", "Claymore"
			end
			p = p.Parent
		end
		return "landmine", "Landmine"
	end
	local n = inst.Name:lower()
	if is_likely_map_prop_name(n) then
		return nil
	end
	if n:find("claymore") then
		return "landmine", "Claymore"
	end
	if n:find("trap") or n:find("tripwire") or n:find("trip wire") or n:find("beartrap") or n:find("snare") then
		return "landmine", "Trap"
	end
	if
		n:find("landmine")
		or n:find("apmine")
		or n:find("a%-mine")
		or n:find("anti personnel")
		or n:find("at mine")
		or n:find("atmine")
	then
		return "landmine", "Landmine"
	end
	return nil
end

local function ancestor_has_extraction_markers(inst)
	local p = inst
	local d = 0
	while p and p ~= Workspace and d < 14 do
		if extraction_attribute_hit(p) then
			return true
		end
		if CollectionService then
			if
				CollectionService:HasTag(p, "Extraction")
				or CollectionService:HasTag(p, "Exfil")
				or CollectionService:HasTag(p, "Extract")
				or CollectionService:HasTag(p, "Evacuation")
				or CollectionService:HasTag(p, "ExfilPoint")
				or CollectionService:HasTag(p, "EvacPoint")
				or CollectionService:HasTag(p, "Helipad")
				or CollectionService:HasTag(p, "LandingZone")
				or CollectionService:HasTag(p, "ExtractionZone")
			then
				return true
			end
		end
		if p:IsA("Model") and extraction_name_hit(p.Name) then
			return true
		end
		p = p.Parent
		d = d + 1
	end
	return false
end

local function classify_extraction_loose_part(inst)
	if not extraction_esp_on or not inst:IsA("BasePart") or inst:IsA("Terrain") then
		return nil
	end
	if ancestor_has_extraction_markers(inst) then
		return "extraction"
	end
	local n = inst.Name
	if extraction_name_hit(n) then
		return "extraction"
	end
	local nl = n:lower()
	if is_likely_map_prop_name(nl) then
		return nil
	end
	if
		nl:find("extraction", 1, true)
		or nl:find("exfil", 1, true)
		or (nl:find("extract", 1, true) and (nl:find("zone", 1, true) or nl:find("point", 1, true) or nl:find("trigger", 1, true)))
		or (nl:find("evac", 1, true) and nl:find("zone", 1, true))
	then
		return "extraction"
	end
	return nil
end

-- Pick up extract/exfil/evac prompts even when the parent Model name is generic.
local function proximity_prompt_suggests_extraction(pp)
	if not pp:IsA("ProximityPrompt") then
		return false
	end
	local ot = string.lower(tostring(pp.ObjectText or ""))
	local at = string.lower(tostring(pp.ActionText or ""))
	local s = ot .. " " .. at
	return s:find("extract", 1, true) or s:find("exfil", 1, true) or s:find("evac", 1, true) or s:find("evacuate", 1, true)
end

local function append_parts_in_radius(pool, seen, classified_models)
	local need = landmine_esp_on or extraction_esp_on
	if not need then
		return
	end
	local root = get_root()
	if not root then
		return
	end
	local radius = math.clamp(world_esp_other_max, 100, 1800)
	local ov = OverlapParams.new()
	ov.FilterType = Enum.RaycastFilterType.Blacklist
	local filt = {}
	local ch = lp.Character
	if ch then
		filt[1] = ch
	end
	ov.FilterDescendantsInstances = filt
	ov.MaxParts = 4000
	ov.RespectCanQuery = false

	local ok, parts = pcall(function()
		return Workspace:GetPartBoundsInRadius(root.Position, radius, ov)
	end)
	if not ok or type(parts) ~= "table" then
		return
	end
	local np = #parts
	for i = 1, np do
		local inst = parts[i]
		if inst:IsA("BasePart") and not inst:IsA("Terrain") then
			if not is_under_local_character(inst) and not is_under_terrain(inst) and not ancestor_in_classified_model(inst, classified_models) then
				local sz = inst.Size.Magnitude
				local kind, mineTag = nil, nil
				-- Hazards are small; extraction colliders can be large.
				if landmine_esp_on and sz <= 220 then
					kind, mineTag = classify_mine_hazard_loose_part(inst)
				end
				if not kind and extraction_esp_on and sz <= 2400 then
					kind = classify_extraction_loose_part(inst)
				end
				if kind then
					push_pool_entry(pool, seen, classified_models, inst, kind, inst, mineTag)
				end
			end
		end
	end
end

function refresh_world_pool()
	if not world_pool_scan_enabled() then
		if #world_pool > 0 then
			world_pool = {}
		end
		return
	end
	world_pool = {}
	local classified_models = {}
	local seen_parts = {}
	append_tagged_instances(world_pool, seen_parts, classified_models)

	local descendants = Workspace:GetDescendants()
	local nd = #descendants
	for i = 1, nd do
		local inst = descendants[i]
		if inst:IsA("Model") and not classified_models[inst] then
			local kind, mineTag = classify_world_model(inst)
			if kind then
				local ap = get_world_anchor(inst)
				if ap then
					push_pool_entry(world_pool, seen_parts, classified_models, inst, kind, ap, mineTag)
				end
			end
		end
	end

	if extraction_esp_on then
		for i = 1, nd do
			local inst = descendants[i]
			if inst:IsA("ProximityPrompt") and proximity_prompt_suggests_extraction(inst) then
				local holder = inst.Parent
				if holder then
					local model = holder:IsA("Model") and holder or holder:FindFirstAncestorOfClass("Model")
					if model and not classified_models[model] then
						local ap = get_world_anchor(model)
						if not ap and holder:IsA("BasePart") then
							ap = holder
						end
						if ap then
							push_pool_entry(world_pool, seen_parts, classified_models, model, "extraction", ap)
						end
					end
				end
			end
		end
	end

	append_parts_in_radius(world_pool, seen_parts, classified_models)

	local MAX_WORLD_POOL = 400
	if #world_pool > MAX_WORLD_POOL then
		local root = get_root()
		if root then
			local pos = root.Position
			table.sort(world_pool, function(a, b)
				return (pos - a.part.Position).Magnitude < (pos - b.part.Position).Magnitude
			end)
			while #world_pool > MAX_WORLD_POOL do
				table.remove(world_pool)
			end
		end
	end
end

function get_world_pool()
	return world_pool
end

function maybe_refresh_world_pool()
	if not world_pool_scan_enabled() then
		if #world_pool > 0 then
			world_pool = {}
		end
		refresh_queued = false
		return
	end
	if refresh_queued then
		return
	end
	local now = os.clock()
	if now - last_scan_t < SCAN_INTERVAL then
		return
	end
	last_scan_t = now
	refresh_queued = true
	task.defer(function()
		pcall(refresh_world_pool)
		refresh_queued = false
	end)
end
