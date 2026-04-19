if _G.MYA_PROJECT_DELTA then
	return
end

local cloneref = (cloneref or function(x)
	return x
end)
local Players = cloneref(game:GetService("Players"))
local RunService = cloneref(game:GetService("RunService"))
local UserInputService = cloneref(game:GetService("UserInputService"))
local Workspace = cloneref(game:GetService("Workspace"))

local lp = Players.LocalPlayer
