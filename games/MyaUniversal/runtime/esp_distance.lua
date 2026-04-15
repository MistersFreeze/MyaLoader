local DIST_UP = 1.8
local distance_draw = {}

function remove_distance_draw(plr)
	local d = distance_draw[plr]
	if not d then
		return
	end
	pcall(function()
		d:Remove()
	end)
	distance_draw[plr] = nil
end

local function ensure_distance_text(plr)
	if not drawing_ok or distance_draw[plr] then
		return
	end
	local t = Drawing.new("Text")
	t.Visible = false
	t.Size = 14
	t.Center = true
	t.Outline = true
	t.Color = Color3.fromRGB(240, 240, 250)
	distance_draw[plr] = t
end

local function hide_distance(plr)
	local d = distance_draw[plr]
	if d then
		d.Visible = false
	end
end

local function update_esp_distance()
	if not drawing_ok or not esp_distance_on or not camera then
		for plr in pairs(distance_draw) do
			hide_distance(plr)
		end
		return
	end
	local myRoot = get_root()
	if not myRoot then
		for plr in pairs(distance_draw) do
			hide_distance(plr)
		end
		return
	end

	for _, plr in ipairs(Players:GetPlayers()) do
		if plr ~= lp and not is_teammate(plr) then
			local char = plr.Character
			local hrp = char and char:FindFirstChild("HumanoidRootPart")
			local head = char and char:FindFirstChild("Head")
			if not char or not hrp or not head or not hrp:IsA("BasePart") or not head:IsA("BasePart") then
				hide_distance(plr)
			else
				local distStuds = (myRoot.Position - hrp.Position).Magnitude
				local pos, onScreen = camera:WorldToViewportPoint(head.Position + Vector3.new(0, DIST_UP, 0))
				if onScreen and pos.Z > 0 then
					ensure_distance_text(plr)
					local d = distance_draw[plr]
					d.Position = Vector2.new(pos.X, pos.Y)
					d.Text = string.format("%.0fm", distStuds)
					d.Visible = true
				else
					hide_distance(plr)
				end
			end
		else
			hide_distance(plr)
		end
	end
end

_G.remove_distance_draw = remove_distance_draw
