local function lower_name(inst)
	return string.lower(inst.Name)
end

local function matches_spread(n)
	return n:find("spread", 1, true)
		or n:find("bloom", 1, true)
		or n:find("dispersion", 1, true)
		or n == "inaccuracy"
		or n:find("bulletspread", 1, true)
end

local function matches_recoil(n)
	return n:find("recoil", 1, true) or n:find("kick", 1, true) or n:find("viewpunch", 1, true) or n:find("camkick", 1, true)
end

local function sweep_instance(d)
	if d:IsA("NumberValue") or d:IsA("DoubleValue") or d:IsA("IntValue") then
		local n = lower_name(d)
		if no_spread_on and matches_spread(n) then
			pcall(function()
				d.Value = 0
			end)
		end
		if no_recoil_on and matches_recoil(n) then
			pcall(function()
				d.Value = 0
			end)
		end
	elseif d:IsA("Vector3Value") then
		local n = lower_name(d)
		if no_recoil_on and matches_recoil(n) then
			pcall(function()
				d.Value = Vector3.zero
			end)
		end
		if no_spread_on and matches_spread(n) then
			pcall(function()
				d.Value = Vector3.zero
			end)
		end
	end
end

local function sweep_weapon_mods(root)
	for _, d in ipairs(root:GetDescendants()) do
		sweep_instance(d)
	end
end

local function weapon_mod_step()
	if not no_recoil_on and not no_spread_on then
		return
	end
	local c = lp.Character
	if c then
		sweep_weapon_mods(c)
	end
	local bp = lp:FindFirstChildOfClass("Backpack")
	if bp then
		sweep_weapon_mods(bp)
	end
end
