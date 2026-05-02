--[[
    Secours de France RP - House burglary + interior steals.
    Door flow matches game: ProximityPrompt → Lockpick minigame → Home_Function:InvokeServer("Roob", house).
    Interior uses Home_Function:InvokeServer("RoobHouseElement", proximityPrompt) — first arg is the prompt (see dumped Cambriolage_Prompt.Settings).
]]

local P = _G.MYA_SECOURS_RP
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local LocalPlayer = Players.LocalPlayer

local function settings()
	return P.Settings or P
end

local function getHouses()
	local houses = {}
	local lot = Workspace:FindFirstChild("Quartier_Lotissements")
	if lot then
		for _, v in pairs(lot:GetDescendants()) do
			if v.Name == "House" and v:IsA("Model") then
				table.insert(houses, v)
			end
		end
	end
	local hf = Workspace:FindFirstChild("Houses")
	if hf then
		for _, v in pairs(hf:GetChildren()) do
			if v:IsA("Model") then
				table.insert(houses, v)
			end
		end
	end
	return houses
end

local function findEntryDoorProximity(house: Model): ProximityPrompt?
	for _, d in ipairs(house:GetDescendants()) do
		if d:IsA("ProximityPrompt") and d:FindFirstAncestor("EntryDoor") then
			return d
		end
	end
	return nil
end

local function lockpickCloneVisible(): boolean
	local ui = LocalPlayer.PlayerGui:FindFirstChild("LockpickUI")
	if not ui or not ui:IsA("ScreenGui") or not ui.Enabled then
		return false
	end
	local canvas = ui:FindFirstChild("CanvasGroup")
	if not canvas then
		return false
	end
	for _, ch in ipairs(canvas:GetChildren()) do
		if ch.Name == "Lockpick" and ch:IsA("GuiObject") and ch.Visible then
			return true
		end
	end
	return false
end

local function waitForLockpickUi(timeout: number): boolean
	local t0 = tick()
	while tick() - t0 < timeout do
		if lockpickCloneVisible() then
			return true
		end
		task.wait(0.05)
	end
	return false
end

local function waitLockpickGone(timeout: number)
	local t0 = tick()
	while tick() - t0 < timeout do
		if not lockpickCloneVisible() then
			return
		end
		task.wait(0.08)
	end
end

local function waitInsideBurglary(house: Model, timeout: number): boolean
	local t0 = tick()
	while tick() - t0 < timeout do
		if house:GetAttribute("Roober") == LocalPlayer.Name and LocalPlayer:GetAttribute("HomeRoobDelay") ~= nil then
			return true
		end
		task.wait(0.1)
	end
	return false
end

local function moveNearPrompt(hrp: BasePart, prompt: ProximityPrompt)
	local parent = prompt.Parent
	if parent and parent:IsA("BasePart") then
		hrp.CFrame = parent.CFrame * CFrame.new(0, 0, 2.5)
	elseif parent and parent:IsA("Model") then
		hrp.CFrame = parent:GetPivot() * CFrame.new(0, 0, 2.5)
	end
end

local function promptWorldPosition(prompt: ProximityPrompt): Vector3?
	local p = prompt.Parent
	if p and p:IsA("BasePart") then
		return p.Position
	end
	if p and p:IsA("Attachment") then
		return p.WorldPosition
	end
	if p and p:IsA("Model") then
		return p:GetPivot().Position
	end
	return nil
end

local function canReachStealPrompt(hrp: BasePart, prompt: ProximityPrompt): boolean
	local target = promptWorldPosition(prompt)
	if not target then
		return false
	end
	local maxDist = prompt.MaxActivationDistance
	if maxDist <= 0 then
		maxDist = 10
	end
	return (hrp.Position - target).Magnitude <= maxDist * 1.06
end

-- Server checks range; standing in activation radius matches pressing E on the prompt.
local function moveInRangeOfStealPrompt(hrp: BasePart, prompt: ProximityPrompt)
	local target = promptWorldPosition(prompt)
	if not target then
		return
	end
	local maxDist = prompt.MaxActivationDistance
	if maxDist <= 0 then
		maxDist = 10
	end
	local standOff = math.clamp(maxDist * 0.85, 2, 12)
	local fromHrp = hrp.Position - target
	local dir = fromHrp.Magnitude > 0.05 and fromHrp.Unit or Vector3.new(0, 0, 1)
	hrp.CFrame = CFrame.new(target + dir * standOff, target)
end

local function collectCambriolagePrompts(house: Model): { ProximityPrompt }
	local list: { ProximityPrompt } = {}
	for _, v in ipairs(house:GetDescendants()) do
		if v.Name == "Cambriolage_Prompt" and v:IsA("ProximityPrompt") and v.Enabled then
			table.insert(list, v)
		end
	end
	return list
end

local function sortPromptsByDistance(hrp: BasePart, prompts: { ProximityPrompt })
	table.sort(prompts, function(a, b)
		local pa, pb = promptWorldPosition(a), promptWorldPosition(b)
		if not pa then
			return false
		end
		if not pb then
			return true
		end
		return (pa - hrp.Position).Magnitude < (pb - hrp.Position).Magnitude
	end)
end

local function stealInteriorItem(hrp: BasePart, prompt: ProximityPrompt, Home_Function: any, allowTeleport: boolean)
	if not prompt.Parent then
		return
	end
	if allowTeleport then
		moveInRangeOfStealPrompt(hrp, prompt)
		task.wait(0.1)
	elseif not canReachStealPrompt(hrp, prompt) then
		return
	end

	if typeof(fireproximityprompt) == "function" then
		pcall(fireproximityprompt, prompt)
		local hold = tonumber(prompt.HoldDuration) or 0
		task.wait(math.max(0.14, hold + 0.08))
	else
		pcall(function()
			Home_Function:InvokeServer("RoobHouseElement", prompt)
		end)
	end
end

task.spawn(function()
	while true do
		local S = settings()
		if S.AUTO_HOUSE then
			local Home_Function = P.getRemote("Home_Function")
			if Home_Function then
				local houses = getHouses()
				for _, house in ipairs(houses) do
					if not S.AUTO_HOUSE then
						break
					end
					if house:IsA("Model") then
						local canRoob = house:GetAttribute("CanBeRoob") ~= false
							and house:GetAttribute("Owner") == nil
							and house:GetAttribute("Roober") == nil
						if canRoob then
							local char = LocalPlayer.Character
							local hrp = char and char:FindFirstChild("HumanoidRootPart")
							local doorPrompt = findEntryDoorProximity(house)

							P.MYA_FORCE_LOCKPICK = true
							pcall(function()
								if S.AUTO_HOUSE_TELEPORT and hrp and hrp:IsA("BasePart") and doorPrompt then
									moveNearPrompt(hrp, doorPrompt)
									task.wait(0.12)
								end
								if typeof(fireproximityprompt) == "function" and doorPrompt then
									if not S.AUTO_HOUSE_TELEPORT and hrp and hrp:IsA("BasePart") and doorPrompt then
										if not canReachStealPrompt(hrp, doorPrompt) then
											return
										end
									end
									pcall(fireproximityprompt, doorPrompt)
								end
							end)

							local uiStarted = waitForLockpickUi(5)
							if not uiStarted then
								pcall(function()
									Home_Function:InvokeServer("Roob", house)
								end)
								task.wait(1.5)
							else
								waitLockpickGone(95)
							end

							P.MYA_FORCE_LOCKPICK = false

							if waitInsideBurglary(house, 28) then
								local char2 = LocalPlayer.Character
								local hrp2 = char2 and char2:FindFirstChild("HumanoidRootPart")
								if hrp2 and hrp2:IsA("BasePart") then
									local prompts = collectCambriolagePrompts(house)
									sortPromptsByDistance(hrp2, prompts)
									for _, prompt in ipairs(prompts) do
										if not S.AUTO_HOUSE then
											break
										end
										if prompt.Parent and prompt.Enabled then
											char2 = LocalPlayer.Character
											hrp2 = char2 and char2:FindFirstChild("HumanoidRootPart")
											if hrp2 and hrp2:IsA("BasePart") then
												stealInteriorItem(hrp2, prompt, Home_Function, S.AUTO_HOUSE_TELEPORT)
												task.wait(S.FARM_DELAY or P.FARM_DELAY or 1.5)
											end
										end
									end
								end
							end

							task.wait(0.75)
						end
					end
				end
			end
		end
		task.wait(5)
	end
end)
