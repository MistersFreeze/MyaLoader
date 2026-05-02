-- Crosshair-ring arrows (Drawing lines) pointing at enemy HRP/Head; optional stud distance labels.
local ARROW_PINK = Color3.fromRGB(255, 130, 175)
local ARROW_MAX_TARGETS = 20
local arrow_pool = {}

local function ensure_pool(n)
	while #arrow_pool < n do
		local l1 = Drawing.new("Line")
		local l2 = Drawing.new("Line")
		for _, ln in ipairs({ l1, l2 }) do
			ln.Visible = false
			ln.Color = ARROW_PINK
			ln.Thickness = 2
		end
		local txt = Drawing.new("Text")
		txt.Visible = false
		txt.Size = 14
		txt.Center = true
		txt.Outline = false
		txt.Color = ARROW_PINK
		arrow_pool[#arrow_pool + 1] = { l1 = l1, l2 = l2, txt = txt }
	end
end

local function hide_slot(i)
	local p = arrow_pool[i]
	if p then
		p.l1.Visible = false
		p.l2.Visible = false
		if p.txt then
			p.txt.Visible = false
		end
	end
end

local function hide_all_slots()
	for i = 1, #arrow_pool do
		hide_slot(i)
	end
end

local function clear_esp_arrows()
	hide_all_slots()
	for _, p in ipairs(arrow_pool) do
		pcall(function()
			p.l1:Remove()
		end)
		pcall(function()
			p.l2:Remove()
		end)
		if p.txt then
			pcall(function()
				p.txt:Remove()
			end)
		end
	end
	arrow_pool = {}
end

_G.clear_esp_arrows = clear_esp_arrows

local function update_esp_arrows()
	if not arrows_esp_on or not drawing_ok or not camera then
		hide_all_slots()
		return
	end

	local anchor = get_fov_screen_anchor(aim_fov_follow_cursor)
	local r = arrows_esp_ring_radius
	local tipLen = arrows_esp_tip_len
	local halfW = arrows_esp_half_width
	local myRoot = get_root()

	local cand = {}
	for _, plr in ipairs(Players:GetPlayers()) do
		if plr ~= lp and plr.Parent and plr.Character and not is_esp_teammate(plr) and esp_target_within_max_range(plr) then
			local hum = plr.Character:FindFirstChildWhichIsA("Humanoid")
			if hum and hum.Health > 0 then
				local part = plr.Character:FindFirstChild("HumanoidRootPart") or plr.Character:FindFirstChild("Head")
				if part and part:IsA("BasePart") then
					local studs = 0
					if myRoot and myRoot:IsA("BasePart") then
						studs = (myRoot.Position - part.Position).Magnitude
					end
					cand[#cand + 1] = {
						pos = part.Position,
						dist = (part.Position - camera.CFrame.Position).Magnitude,
						studs = studs,
					}
				end
			end
		end
	end
	table.sort(cand, function(a, b)
		return a.dist < b.dist
	end)

	-- Off-screen indicators only: hide arrows when the tracked part is in view (viewport + in front).
	local off = {}
	for _, c in ipairs(cand) do
		local sp, onScreen = camera:WorldToViewportPoint(c.pos)
		if not (onScreen and sp.Z > 0) then
			off[#off + 1] = {
				pos = c.pos,
				dist = c.dist,
				studs = c.studs,
				sp = sp,
			}
		end
	end
	table.sort(off, function(a, b)
		return a.dist < b.dist
	end)

	local n = math.min(#off, ARROW_MAX_TARGETS)
	ensure_pool(n)
	for i = n + 1, #arrow_pool do
		hide_slot(i)
	end
	if n == 0 then
		return
	end

	for i = 1, n do
		local pair = arrow_pool[i]
		local sp = off[i].sp
		local scr = Vector2.new(sp.X, sp.Y)
		local dir = scr - anchor
		if sp.Z < 0 then
			dir = anchor - scr
		end
		if dir.Magnitude < 3 then
			hide_slot(i)
		else
			dir = dir.Unit
			local base = anchor + dir * r
			local tip = anchor + dir * (r + tipLen)
			local perp = Vector2.new(-dir.Y, dir.X)
			local w1 = base + perp * halfW
			local w2 = base - perp * halfW
			pair.l1.From = w1
			pair.l1.To = tip
			pair.l1.Visible = true
			pair.l2.From = w2
			pair.l2.To = tip
			pair.l2.Visible = true
			if arrows_esp_distance_on and pair.txt then
				-- Inward from tip (toward ring) so distance reads under the chevron, not past the point.
				local labelPos = tip - dir * 20
				pair.txt.Position = labelPos
				pair.txt.Text = string.format("%.0fm", off[i].studs)
				pair.txt.Color = ARROW_PINK
				pair.txt.Visible = true
			elseif pair.txt then
				pair.txt.Visible = false
			end
		end
	end
end
