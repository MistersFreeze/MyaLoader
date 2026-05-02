--[[
    Secours de France RP - ATM Farm
]]

local P = _G.MYA_SECOURS_RP
local LocalPlayer = game:GetService("Players").LocalPlayer
local Workspace = game:GetService("Workspace")

local function getATMs()
    local atms = {}
    local gameplay = Workspace:FindFirstChild("Systems") and Workspace.Systems:FindFirstChild("Gameplay") and Workspace.Systems.Gameplay:FindFirstChild("Interventions")
    local atmFolder = gameplay and gameplay:FindFirstChild("ATM")
    if atmFolder then
        for _, v in pairs(atmFolder:GetDescendants()) do
            if v.Name == "ATM" and v:IsA("Model") then table.insert(atms, v) end
        end
    end
    return atms
end

task.spawn(function()
    while true do
        local S = P.Settings or P
        if S.AUTO_ATM then
            local atms = getATMs()
            local ATM_Function = P.getRemote("ATM_Function")
            local token = P.getToken()
            
            for _, atm in pairs(atms) do
                if not S.AUTO_ATM then break end
                local lastAtm = LocalPlayer:GetAttribute("LastATM")
                if lastAtm == nil or tick() - lastAtm > 155 then
                    if LocalPlayer.Backpack:FindFirstChild("ATM Key") or (LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("ATM Key")) then
                        ATM_Function:InvokeServer(token, "Alert")
                        task.wait(5)
                        ATM_Function:InvokeServer(token)
                        task.wait(S.FARM_DELAY or P.FARM_DELAY or 1.5)
                    end
                end
            end
        end
        task.wait(5)
    end
end)
