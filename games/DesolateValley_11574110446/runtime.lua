local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")

local MYA_DEBUG = true
local MYA_PREFIX = "[MYA] "

local function myaLog(msg)
	if not MYA_DEBUG then
		return
	end
	local text = MYA_PREFIX .. tostring(msg)
	if typeof(rconsoleprint) == "function" then
		-- Best-effort pink in executors that support rconsole color tokens.
		pcall(function()
			rconsoleprint("@@LIGHTMAGENTA@@")
			rconsoleprint(text .. "\n")
			rconsoleprint("@@WHITE@@")
		end)
		return
	end
	print(text)
end

-- Immediate boot signal to confirm runtime file actually executed.
pcall(function()
	print(MYA_PREFIX .. "runtime chunk executed")
end)

local R = {
	visuals = {
		foraging = true,
		mining = true,
		enemies = true,
		bosses = true,
		players = true,
	},
	misc = {
		autoSkillCheck = true,
		autoDodge = false,
	},
	autofarm = {
		skull = false,
		moveSpeed = 85,
	},
}

local highlights = {}
local forageLabels = {}
local miningLabels = {}
local bossNames = {}
local lastSkillPress = 0
local lastDodgePress = 0
local nextFarmTick = 0
local skullRetryAt = {}
local nextEspTick = 0
local nextDodgeTick = 0
local nextSkillTick = 0
local resourceTargetsCache = {}
local nextResourceCacheAt = 0
local skullPotCache = {}
local nextSkullCacheAt = 0

local FORAGE_COLOR = Color3.fromRGB(110, 255, 155)
local MINING_COLOR = Color3.fromRGB(120, 180, 255)
local ENEMY_COLOR = Color3.fromRGB(255, 125, 125)
local BOSS_COLOR = Color3.fromRGB(255, 70, 135)
local PLAYER_COLOR = Color3.fromRGB(120, 200, 255)

local FORAGE_KEYWORDS = { "foraging" }
local MINING_KEYWORDS = { "ore" }
local BOSS_KEYWORDS = { "boss", "queen", "captain", "warden", "reaper", "golem", "paladin" }

local function hasKeyword(txt, words)
	local s = string.lower(tostring(txt or ""))
	for i = 1, #words do
		if string.find(s, words[i], 1, true) then
			return true
		end
	end
	return false
end

local function clearHighlight(inst)
	local h = highlights[inst]
	if h then
		pcall(function()
			h:Destroy()
		end)
		highlights[inst] = nil
	end
end

local function setHighlight(target, color)
	if not target or not target.Parent then
		return
	end
	local h = highlights[target]
	if not h then
		h = Instance.new("Highlight")
		h.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
		h.Parent = target
		highlights[target] = h
	end
	h.FillColor = color
	h.OutlineColor = color
	h.FillTransparency = 0.82
	h.OutlineTransparency = 0.3
end

local function ensureLabel(store, inst, text, color, name)
	if store[inst] then
		return
	end
	local adornee = inst:IsA("Model") and (inst.PrimaryPart or inst:FindFirstChildWhichIsA("BasePart", true)) or inst
	if not adornee or not adornee:IsA("BasePart") then
		return
	end
	local bb = Instance.new("BillboardGui")
	bb.Name = name
	bb.Size = UDim2.fromOffset(100, 22)
	bb.StudsOffset = Vector3.new(0, 2.5, 0)
	bb.AlwaysOnTop = true
	bb.Adornee = adornee
	bb.Parent = adornee
	local tl = Instance.new("TextLabel")
	tl.Size = UDim2.fromScale(1, 1)
	tl.BackgroundTransparency = 1
	tl.Font = Enum.Font.GothamBold
	tl.TextSize = 11
	tl.TextColor3 = color
	tl.TextStrokeTransparency = 0.4
	tl.Text = text
	tl.Parent = bb
	store[inst] = bb
end

local function clearLabels(store)
	for inst, bb in pairs(store) do
		if bb and bb.Parent then
			bb:Destroy()
		end
		store[inst] = nil
	end
end

local function getCharactersFolder()
	local ig = workspace:FindFirstChild("InstancedGeometry")
	return ig and ig:FindFirstChild("Characters") or nil
end

local function getInteractablesFolder()
	local ig = workspace:FindFirstChild("InstancedGeometry")
	return ig and ig:FindFirstChild("Interactables") or nil
end

local function canonicalTarget(inst)
	if inst:IsA("Model") then
		return inst
	end
	local m = inst:FindFirstAncestorWhichIsA("Model")
	return m or inst
end

local function buildResourceText(inst)
	local root = canonicalTarget(inst)
	local chunks = {
		root.Name,
		root:GetAttribute("Type"),
		root:GetAttribute("ResourceType"),
		root:GetAttribute("ResourceIndex"),
		root:GetAttribute("UseTool"),
	}
	return string.lower(table.concat(chunks, " "))
end

local function classifyResource(inst)
	local tagged = inst
	local root = canonicalTarget(inst)
	local function getAttrDeep(key)
		local v = tagged:GetAttribute(key)
		if v ~= nil then
			return v
		end
		if root and root ~= tagged then
			v = root:GetAttribute(key)
			if v ~= nil then
				return v
			end
		end
		if root and root:IsA("Model") then
			local bp = root.PrimaryPart or root:FindFirstChildWhichIsA("BasePart", true)
			if bp then
				v = bp:GetAttribute(key)
				if v ~= nil then
					return v
				end
			end
		end
		return nil
	end
	local id = getAttrDeep("ID")
	local active = getAttrDeep("Active")
	local iState = getAttrDeep("IState")
	if id == nil and active == nil and iState == nil then
		return nil, root
	end

	local resourceType = string.lower(tostring(getAttrDeep("ResourceType") or ""))
	-- Strict classification to avoid map-wide false positives:
	-- only explicit resource types are accepted.
	if resourceType == "foraging" then
		return "foraging", root
	end
	if resourceType == "ore" then
		return "mining", root
	end

	-- Conservative fallback only for clearly named resource nodes.
	local text = string.lower(
		table.concat({
			tostring(tagged.Name or ""),
			tostring(root and root.Name or ""),
			tostring(getAttrDeep("Type") or ""),
			tostring(getAttrDeep("ResourceIndex") or ""),
			tostring(getAttrDeep("UseTool") or ""),
		}, " ")
	)
	if string.find(text, "resource", 1, true) then
		if hasKeyword(text, FORAGE_KEYWORDS) then
			return "foraging", root
		end
		if hasKeyword(text, MINING_KEYWORDS) then
			return "mining", root
		end
	end
	return nil, root
end

local function rebuildResourceTargetsCache()
	local out = {}
	local seen = {}
	-- Real interactables tagged by game systems.
	for _, tagged in ipairs(CollectionService:GetTagged("Int")) do
		if tagged and tagged.Parent then
			local class, root = classifyResource(tagged)
			if class and not seen[root] then
				seen[root] = true
				table.insert(out, { class = class, root = root })
			end
		end
	end
	resourceTargetsCache = out
	local f, m = 0, 0
	for i = 1, #out do
		if out[i].class == "foraging" then
			f = f + 1
		elseif out[i].class == "mining" then
			m = m + 1
		end
	end
	myaLog(string.format("Resource cache rebuilt | tagged Int: %d | foraging: %d | mining: %d", #CollectionService:GetTagged("Int"), f, m))
end

local function rebuildBossCache()
	table.clear(bossNames)
	local npcData = ReplicatedStorage:FindFirstChild("NPCData")
	if not npcData then
		return
	end
	for _, desc in ipairs(npcData:GetDescendants()) do
		if desc:IsA("ModuleScript") and desc.Name == "ClientData" then
			local ok, data = pcall(require, desc)
			if ok and type(data) == "table" and data.IsBoss == true then
				bossNames[string.lower(desc.Parent.Name)] = true
			end
		end
	end
end

function R.syncEsp()
	local wanted = {}

	if R.visuals.players then
		for _, plr in ipairs(Players:GetPlayers()) do
			if plr ~= Players.LocalPlayer and plr.Character then
				wanted[plr.Character] = PLAYER_COLOR
			end
		end
	end

	local chars = getCharactersFolder()
	if chars then
		for _, model in ipairs(chars:GetChildren()) do
			if model:IsA("Model") and Players:GetPlayerFromCharacter(model) == nil then
				local lname = string.lower(model.Name)
				local isBoss = bossNames[lname] == true or hasKeyword(lname, BOSS_KEYWORDS)
				if isBoss and R.visuals.bosses then
					wanted[model] = BOSS_COLOR
				elseif R.visuals.enemies then
					wanted[model] = ENEMY_COLOR
				end
			end
		end
	end

	for i = 1, #resourceTargetsCache do
		local row = resourceTargetsCache[i]
		local root = row.root
		if root and root.Parent then
			if row.class == "foraging" and R.visuals.foraging then
				wanted[root] = FORAGE_COLOR
				ensureLabel(forageLabels, root, "Foraging", FORAGE_COLOR, "MyaForageLabel")
			elseif row.class == "mining" and R.visuals.mining then
				wanted[root] = MINING_COLOR
				ensureLabel(miningLabels, root, "Mining", MINING_COLOR, "MyaMiningLabel")
			end
		end
	end
	if not R.visuals.foraging then
		clearLabels(forageLabels)
	end
	if not R.visuals.mining then
		clearLabels(miningLabels)
	end

	local toClear = {}
	for inst in pairs(highlights) do
		if not wanted[inst] then
			table.insert(toClear, inst)
		end
	end
	for i = 1, #toClear do
		clearHighlight(toClear[i])
	end
	for inst, col in pairs(wanted) do
		setHighlight(inst, col)
	end
	if MYA_DEBUG then
		local totalHighlights = 0
		for _ in pairs(highlights) do
			totalHighlights = totalHighlights + 1
		end
		myaLog("ESP sync complete | active highlights: " .. tostring(totalHighlights))
	end
end

local function pressKey(keyCode)
	pcall(function()
		VirtualInputManager:SendKeyEvent(true, keyCode, false, game)
		VirtualInputManager:SendKeyEvent(false, keyCode, false, game)
	end)
end

local function pressInteractKey()
	pressKey(Enum.KeyCode.E)
end

local function inGreatZone(lineRotation, goalRotation)
	local low = 104 + goalRotation
	local high = 114 + goalRotation
	return low <= lineRotation and lineRotation <= high
end

function R.updateSkillCheckAssist()
	if not R.misc.autoSkillCheck then
		return
	end
	local pg = Players.LocalPlayer and Players.LocalPlayer:FindFirstChild("PlayerGui")
	if not pg then
		return
	end
	local gui = pg:FindFirstChild("SkillCheckPromptGui")
	local check = gui and gui:FindFirstChild("Check")
	if check and check.Visible then
		local line = check:FindFirstChild("Line")
		local goal = check:FindFirstChild("Goal")
		if line and goal and inGreatZone(line.Rotation, goal.Rotation) then
			local now = os.clock()
			if now - lastSkillPress >= 0.085 then
				lastSkillPress = now
				myaLog(string.format("SkillCheck hit window | line=%.2f goal=%.2f -> press E", line.Rotation, goal.Rotation))
				pressInteractKey()
			end
		end
	end
end

function R.updateAutoDodge()
	if not R.misc.autoDodge then
		return
	end
	local lp = Players.LocalPlayer
	local root = lp and lp.Character and lp.Character:FindFirstChild("HumanoidRootPart")
	if not root then
		return
	end
	local chars = getCharactersFolder()
	if not chars then
		return
	end
	for _, m in ipairs(chars:GetChildren()) do
		if m:IsA("Model") and Players:GetPlayerFromCharacter(m) == nil then
			local hrp = m:FindFirstChild("HumanoidRootPart")
			if hrp and (hrp.Position - root.Position).Magnitude < 12 then
				local now = os.clock()
				if now - lastDodgePress > 0.65 then
					lastDodgePress = now
					myaLog("AutoDodge trigger near enemy: " .. tostring(m.Name))
					pressKey(Enum.KeyCode.A)
				end
				return
			end
		end
	end
end

local function getLocalRoot()
	local lp = Players.LocalPlayer
	local ch = lp and lp.Character
	return ch and ch:FindFirstChild("HumanoidRootPart") or nil
end

local function isDecorativeSkull(inst)
	local model = inst and (inst:IsA("Model") and inst or inst:FindFirstAncestorWhichIsA("Model"))
	if not model then
		return true
	end
	local meshes = model:FindFirstChild("Meshes")
	if meshes then
		local hasSkull2 = meshes:FindFirstChild("skull2") ~= nil
		local hasUntitled = false
		for _, ch in ipairs(meshes:GetChildren()) do
			if string.find(string.lower(ch.Name), "untitled", 1, true) then
				hasUntitled = true
				break
			end
		end
		if hasSkull2 and hasUntitled then
			return true
		end
	end
	return false
end

local function getSkullPotPosition(inst)
	local model = inst:IsA("Model") and inst or inst:FindFirstAncestorWhichIsA("Model")
	if not model then
		return nil
	end
	local base = model.PrimaryPart or model:FindFirstChildWhichIsA("BasePart", true)
	return base and base.Position or nil
end

local function collectSkullPots()
	local out = {}
	local seen = {}
	for _, tagged in ipairs(CollectionService:GetTagged("Int")) do
		if tagged and tagged.Parent then
			local root = canonicalTarget(tagged)
			local text = string.lower(
				table.concat({
					tostring(tagged.Name or ""),
					tostring(root and root.Name or ""),
					tostring(tagged:GetAttribute("Type") or ""),
					tostring(tagged:GetAttribute("Name") or ""),
					tostring(tagged:GetAttribute("ResourceIndex") or ""),
				}, " ")
			)
			local isSkullPot = string.find(text, "skullpot", 1, true) ~= nil
				or (string.find(text, "skull", 1, true) ~= nil and string.find(text, "item", 1, true) == nil and string.find(text, "cursedskull", 1, true) == nil)
			if isSkullPot then
				local key = root:GetDebugId()
				if not seen[key] and not isDecorativeSkull(root) then
					seen[key] = true
					table.insert(out, root)
				end
			end
		end
	end
	myaLog("Skull scan | skull pot candidates: " .. tostring(#out))
	return out
end

local function collectSkullItemsNear(pos, radius)
	local out = {}
	for _, tagged in ipairs(CollectionService:GetTagged("Int")) do
		if tagged and tagged.Parent then
			local root = canonicalTarget(tagged)
			local n = string.lower(root.Name or "")
			local t = string.lower(tostring(tagged:GetAttribute("Type") or ""))
			local ri = string.lower(tostring(tagged:GetAttribute("ResourceIndex") or ""))
			if string.find(n, "skullitem", 1, true) or string.find(n, "cursedskull", 1, true) or string.find(t, "skullitem", 1, true) or string.find(ri, "cursedskull", 1, true) then
				local p = root:IsA("Model") and (root.PrimaryPart and root.PrimaryPart.Position or (root:FindFirstChildWhichIsA("BasePart", true) and root:FindFirstChildWhichIsA("BasePart", true).Position)) or root.Position
				if p and (p - pos).Magnitude <= radius then
					table.insert(out, root)
				end
			end
		end
	end
	myaLog("Skull pickup scan | nearby SkullItem count: " .. tostring(#out))
	return out
end

local function tweenRootTo(root, targetPos, speed)
	local dist = (root.Position - targetPos).Magnitude
	local t = math.clamp(dist / math.max(20, speed), 0.06, 0.7)
	local tw = TweenService:Create(root, TweenInfo.new(t, Enum.EasingStyle.Linear), { CFrame = CFrame.new(targetPos) })
	tw:Play()
	tw.Completed:Wait()
end

local function findNearestSkullPot(fromPos)
	if os.clock() >= nextSkullCacheAt then
		nextSkullCacheAt = os.clock() + 2.0
		skullPotCache = collectSkullPots()
	end
	local now = os.clock()
	local best, bestPos, bestDist = nil, nil, math.huge
	for _, m in ipairs(skullPotCache) do
		local retryAt = skullRetryAt[m]
		if not retryAt or retryAt <= now then
			local pos = getSkullPotPosition(m)
			if pos then
				local d = (pos - fromPos).Magnitude
				if d < bestDist then
					best = m
					bestPos = pos
					bestDist = d
				end
			end
		end
	end
	if best then
		myaLog(string.format("Nearest SkullPot: %s | dist=%.2f", tostring(best.Name), bestDist))
	else
		myaLog("Nearest SkullPot: none")
	end
	return best, bestPos, bestDist
end

function R.updateAutoFarm()
	if not R.autofarm.skull then
		return
	end
	local now = os.clock()
	if now < nextFarmTick then
		return
	end
	nextFarmTick = now + 0.2

	local root = getLocalRoot()
	if not root then
		return
	end
	local skull, skullPos = findNearestSkullPot(root.Position)
	if not skull or not skullPos then
		return
	end
	myaLog("AutoFarm start cycle on SkullPot")

	local dir = (skullPos - root.Position)
	if dir.Magnitude < 0.001 then
		dir = root.CFrame.LookVector
	end
	dir = dir.Unit
	local a = skullPos - dir * 3.0 + Vector3.new(0, 2.1, 0)
	local b = skullPos + dir * 3.2 + Vector3.new(0, 2.1, 0)

	tweenRootTo(root, a, R.autofarm.moveSpeed)
	tweenRootTo(root, b, R.autofarm.moveSpeed)
	myaLog("AutoFarm pass-through done")

	for _ = 1, 12 do
		pressInteractKey()
		task.wait(0.06)
	end

	local pickups = collectSkullItemsNear(skullPos, 18)
	if #pickups == 0 then
		skullRetryAt[skull] = os.clock() + 2.2
		myaLog("No pickups found after break attempt; retry later")
		return
	end
	myaLog("Pickups detected; collecting...")
	for _, item in ipairs(pickups) do
		local p = item:IsA("Model") and (item.PrimaryPart and item.PrimaryPart.Position or (item:FindFirstChildWhichIsA("BasePart", true) and item:FindFirstChildWhichIsA("BasePart", true).Position)) or item.Position
		if p then
			tweenRootTo(root, p + Vector3.new(0, 2.0, 0), R.autofarm.moveSpeed)
			for _ = 1, 8 do
				pressInteractKey()
				task.wait(0.05)
			end
			myaLog("Pickup interaction sent for item: " .. tostring(item.Name))
		end
	end
	myaLog("AutoFarm cycle complete")
end

function R.clearAll()
	clearLabels(forageLabels)
	clearLabels(miningLabels)
	local toClear = {}
	for inst in pairs(highlights) do
		table.insert(toClear, inst)
	end
	for i = 1, #toClear do
		clearHighlight(toClear[i])
	end
end

function R.setVisual(name, v)
	if R.visuals[name] ~= nil then
		R.visuals[name] = v and true or false
	end
end
function R.getVisual(name)
	return R.visuals[name] == true
end
function R.setAutoSkillCheck(v)
	R.misc.autoSkillCheck = v and true or false
end
function R.getAutoSkillCheck()
	return R.misc.autoSkillCheck == true
end
function R.setAutoDodge(v)
	R.misc.autoDodge = v and true or false
end
function R.getAutoDodge()
	return R.misc.autoDodge == true
end
function R.setSkullAutofarm(v)
	R.autofarm.skull = v and true or false
end
function R.getSkullAutofarm()
	return R.autofarm.skull == true
end

rebuildBossCache()
myaLog("Desolate runtime initialized")

_G.MYA_DESOLATE = R
_G.unload_mya_desolate = function()
	local st = _G.MYA_DESOLATE
	if st and st.clearAll then
		pcall(st.clearAll)
	end
	_G.MYA_DESOLATE = nil
	if _G.MYA_DESOLATE_HEARTBEAT and typeof(_G.MYA_DESOLATE_HEARTBEAT.Disconnect) == "function" then
		pcall(function()
			_G.MYA_DESOLATE_HEARTBEAT:Disconnect()
		end)
	end
	_G.MYA_DESOLATE_HEARTBEAT = nil
end

if _G.MYA_DESOLATE_HEARTBEAT and typeof(_G.MYA_DESOLATE_HEARTBEAT.Disconnect) == "function" then
	pcall(function()
		_G.MYA_DESOLATE_HEARTBEAT:Disconnect()
	end)
end
_G.MYA_DESOLATE_HEARTBEAT = RunService.Heartbeat:Connect(function()
	local st = _G.MYA_DESOLATE
	if not st then
		return
	end
	local now = os.clock()
	if now >= nextResourceCacheAt then
		nextResourceCacheAt = now + 1.5
		pcall(rebuildResourceTargetsCache)
	end
	if now >= nextEspTick then
		nextEspTick = now + 0.22
		pcall(st.syncEsp)
	end
	if now >= nextSkillTick then
		nextSkillTick = now + 0.02
		pcall(st.updateSkillCheckAssist)
	end
	if now >= nextDodgeTick then
		nextDodgeTick = now + 0.08
		pcall(st.updateAutoDodge)
	end
	pcall(st.updateAutoFarm)
end)
myaLog("Heartbeat loop attached")
