--[[
    Secours de France RP - Auto Lockpick
    Minigame UI: PlayerGui.LockpickUI → CanvasGroup → cloned "Lockpick" (visible).
    Success window matches decompiled Lockpick module: rotation % 360 in [0,12] ∪ [348,360).
]]

local P = _G.MYA_SECOURS_RP
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

local VirtualInputManager = game:GetService("VirtualInputManager")

if P.AUTO_LOCKPICK == nil then
	P.AUTO_LOCKPICK = false
end
if P.MYA_FORCE_LOCKPICK == nil then
	P.MYA_FORCE_LOCKPICK = false
end

local function wantsLockpick(): boolean
	if P.MYA_FORCE_LOCKPICK then
		return true
	end
	local s = P.Settings
	if s and s.AUTO_LOCKPICK then
		return true
	end
	return P.AUTO_LOCKPICK == true
end

-- Same logic as ReplicatedStorage...ServiceManager.Lockpick (decompiled v44).
local function rotationInSuccessZone(deg: number): boolean
	local r = deg % 360
	if r < 0 then
		r = r + 360
	end
	if r < 348 then
		return r <= 12
	end
	return true
end

local function getVisibleLockpick(canvas: Instance): Instance?
	local best: Instance? = nil
	for _, child in ipairs(canvas:GetChildren()) do
		if child.Name == "Lockpick" and child:IsA("GuiObject") and child.Visible then
			return child
		end
		if child.Name == "Lockpick" and child:IsA("GuiObject") and not best then
			best = child
		end
	end
	return best
end

local function clickCenter(btn: GuiButton)
	local pos = btn.AbsolutePosition
	local sz = btn.AbsoluteSize
	local x = math.floor(pos.X + sz.X * 0.5)
	local y = math.floor(pos.Y + sz.Y * 0.5)

	if typeof(firesignal) == "function" then
		local ok = pcall(firesignal, btn.MouseButton1Click)
		if ok then
			return
		end
	end

	if typeof(getconnections) == "function" then
		pcall(function()
			for _, conn in getconnections(btn.MouseButton1Click) do
				if typeof(conn.Function) == "function" then
					conn.Function()
				elseif typeof(conn.Fire) == "function" then
					conn:Fire()
				end
			end
		end)
	end

	local g = typeof(getgenv) == "function" and getgenv()
	local m1 = g and g.mouse1click
	if typeof(m1) == "function" then
		pcall(m1, x, y)
		return
	end

	pcall(function()
		VirtualInputManager:SendMouseButtonEvent(x, y, 0, true, game, 1)
	end)
	task.wait(1 / 60)
	pcall(function()
		VirtualInputManager:SendMouseButtonEvent(x, y, 0, false, game, 1)
	end)
end

local lastClick = 0.0
local CLICK_COOLDOWN = 0.18

local lockConn = RunService.RenderStepped:Connect(function()
	if not wantsLockpick() then
		return
	end
	if tick() - lastClick < CLICK_COOLDOWN then
		return
	end

	local ui = LocalPlayer.PlayerGui:FindFirstChild("LockpickUI")
	if not ui or not ui:IsA("ScreenGui") then
		return
	end
	if not ui.Enabled then
		return
	end

	local canvas = ui:FindFirstChild("CanvasGroup")
	if not canvas then
		return
	end

	local lockpick = getVisibleLockpick(canvas)
	if not lockpick then
		return
	end

	local tickImg = lockpick:FindFirstChild("tick")
	local button = lockpick:FindFirstChild("button")
	if not (tickImg and tickImg:IsA("GuiObject") and button and button:IsA("GuiButton")) then
		return
	end

	local rot = tickImg.Rotation
	if rotationInSuccessZone(rot) then
		clickCenter(button :: GuiButton)
		lastClick = tick()
	end
end)

table.insert(P.CONNECTIONS, lockConn)
