--[[
    Secours de France RP - ATM ESP
]]

local P = _G.MYA_SECOURS_RP
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")

local function getATMs()
    local atms = {}
    local gameplay = Workspace:FindFirstChild("Systems") and Workspace.Systems:FindFirstChild("Gameplay") and Workspace.Systems.Gameplay:FindFirstChild("Interventions")
    local atmFolder = gameplay and gameplay:FindFirstChild("ATM")
    if atmFolder then
        for _, v in pairs(atmFolder:GetDescendants()) do
            if v.Name == "ATM" and v:IsA("Model") then
                table.insert(atms, v)
            end
        end
    end
    return atms
end

local conn = RunService.Heartbeat:Connect(function()
    local cam = Workspace.CurrentCamera
    if P.ATM_ESP then
        for _, atm in pairs(getATMs()) do
            P.createHighlight(atm, Color3.fromRGB(0, 255, 255), P.ATM_HIGHLIGHTS)
            
            if P.ATM_TRACERS_ENABLED then
                P.createTracer(atm, Color3.fromRGB(0, 255, 255), P.ATM_TRACERS)
                local l = P.ATM_TRACERS[atm]
                if l then
                    local pos, onScreen = cam:WorldToViewportPoint(atm:GetPivot().Position)
                    if onScreen then
                        l.To = Vector2.new(pos.X, pos.Y)
                        l.From = Vector2.new(cam.ViewportSize.X / 2, cam.ViewportSize.Y)
                        l.Visible = true
                    else
                        l.Visible = false
                    end
                end
            else
                P.clearDrawings(P.ATM_TRACERS)
            end
        end
    else
        P.clearHighlights(P.ATM_HIGHLIGHTS)
        P.clearDrawings(P.ATM_TRACERS)
    end
end)

table.insert(P.CONNECTIONS, conn)
