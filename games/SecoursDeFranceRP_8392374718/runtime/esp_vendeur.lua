--[[
    Secours de France RP - Seller ESP (Dark Store)
]]

local P = _G.MYA_SECOURS_RP
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")

local function getVendeurs()
    local vendeurs = {}
    -- Priority 1: Known path
    local pnjFolder = Workspace:FindFirstChild("Systems") and Workspace.Systems:FindFirstChild("PNJ")
    if pnjFolder then
        for _, v in pairs(pnjFolder:GetChildren()) do
            if v.Name:find("Vendeur") then
                table.insert(vendeurs, v)
            end
        end
    end
    -- Priority 2: Search entire workspace if not found (cached)
    if #vendeurs == 0 then
        for _, v in pairs(Workspace:GetDescendants()) do
            if v:IsA("Model") and v.Name:find("Vendeur") then
                table.insert(vendeurs, v)
            end
        end
    end
    return vendeurs
end

local conn = RunService.Heartbeat:Connect(function()
    local cam = Workspace.CurrentCamera
    if P.VENDEUR_ESP then
        for _, pnj in pairs(getVendeurs()) do
            P.createHighlight(pnj, Color3.fromRGB(255, 165, 0), P.VENDEUR_HIGHLIGHTS)
            
            if P.VENDEUR_TRACERS_ENABLED then
                P.createTracer(pnj, Color3.fromRGB(255, 165, 0), P.VENDEUR_TRACERS)
                local l = P.VENDEUR_TRACERS[pnj]
                if l then
                    local pos, onScreen = cam:WorldToViewportPoint(pnj:GetPivot().Position)
                    if onScreen then
                        l.To = Vector2.new(pos.X, pos.Y)
                        l.From = Vector2.new(cam.ViewportSize.X / 2, cam.ViewportSize.Y)
                        l.Visible = true
                    else
                        l.Visible = false
                    end
                end
            else
                P.clearDrawings(P.VENDEUR_TRACERS)
            end
        end
    else
        P.clearHighlights(P.VENDEUR_HIGHLIGHTS)
        P.clearDrawings(P.VENDEUR_TRACERS)
    end
end)

table.insert(P.CONNECTIONS, conn)
