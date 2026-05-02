--[[
    Secours de France RP - House ESP
]]

local P = _G.MYA_SECOURS_RP
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")

local function getHouses()
    local houses = {}
    local lot = Workspace:FindFirstChild("Quartier_Lotissements")
    if lot then
        for _, v in pairs(lot:GetDescendants()) do
            if v.Name == "House" and v:IsA("Model") then table.insert(houses, v) end
        end
    end
    local hf = Workspace:FindFirstChild("Houses")
    if hf then
        for _, v in pairs(hf:GetChildren()) do
            if v:IsA("Model") then table.insert(houses, v) end
        end
    end
    return houses
end

local conn = RunService.Heartbeat:Connect(function()
    local cam = Workspace.CurrentCamera
    if P.HOUSE_ESP then
        for _, house in pairs(getHouses()) do
            local canRoob = house:GetAttribute("CanBeRoob") ~= false and house:GetAttribute("Owner") == nil
            local color = canRoob and Color3.fromRGB(0, 255, 0) or Color3.fromRGB(255, 0, 0)
            P.createHighlight(house, color, P.HOUSE_HIGHLIGHTS)
            
            if P.HOUSE_TRACERS_ENABLED then
                P.createTracer(house, color, P.HOUSE_TRACERS)
                local l = P.HOUSE_TRACERS[house]
                if l then
                    local pos, onScreen = cam:WorldToViewportPoint(house:GetPivot().Position)
                    if onScreen then
                        l.To = Vector2.new(pos.X, pos.Y)
                        l.From = Vector2.new(cam.ViewportSize.X / 2, cam.ViewportSize.Y)
                        l.Visible = true
                    else
                        l.Visible = false
                    end
                end
            else
                P.clearDrawings(P.HOUSE_TRACERS)
            end
        end
    else
        P.clearHighlights(P.HOUSE_HIGHLIGHTS)
        P.clearDrawings(P.HOUSE_TRACERS)
    end
end)

table.insert(P.CONNECTIONS, conn)
