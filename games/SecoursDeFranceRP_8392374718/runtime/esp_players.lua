--[[
    Secours de France RP - Player ESP (Fixed Cleanup & Performance)
]]

local P = _G.MYA_SECOURS_RP
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

local function createPlayerDrawings(player)
    if P.PLAYER_ESP_LIST[player] then return end
    
    local drawings = {
        tracer = Drawing.new("Line"),
        name = Drawing.new("Text"),
        dist = Drawing.new("Text"),
        healthBg = Drawing.new("Line"),
        healthFill = Drawing.new("Line")
    }
    
    drawings.tracer.Visible = false
    drawings.tracer.Thickness = 1
    drawings.tracer.Transparency = 1
    drawings.tracer.Color = Color3.fromRGB(255, 105, 180)
    
    drawings.name.Visible = false
    drawings.name.Size = 14
    drawings.name.Center = true
    drawings.name.Outline = true
    drawings.name.Color = Color3.fromRGB(255, 105, 180)
    drawings.name.Font = 2
    
    drawings.dist.Visible = false
    drawings.dist.Size = 13
    drawings.dist.Center = true
    drawings.dist.Outline = true
    drawings.dist.Color = Color3.new(1, 1, 1)
    
    drawings.healthBg.Visible = false
    drawings.healthBg.Thickness = 2
    drawings.healthBg.Color = Color3.new(0, 0, 0)
    
    drawings.healthFill.Visible = false
    drawings.healthFill.Thickness = 2
    
    local highlight = Instance.new("Highlight")
    highlight.FillColor = Color3.fromRGB(255, 105, 180)
    highlight.FillTransparency = 0.7
    highlight.OutlineColor = Color3.fromRGB(255, 105, 180)
    highlight.OutlineTransparency = 0
    highlight.Enabled = false
    highlight.Name = "MyaPlayerHighlight"
    
    drawings.highlight = highlight
    
    P.PLAYER_ESP_LIST[player] = drawings
end

local function removePlayerDrawings(player)
    local d = P.PLAYER_ESP_LIST[player]
    if d then
        pcall(function() d.tracer:Remove() end)
        pcall(function() d.name:Remove() end)
        pcall(function() d.dist:Remove() end)
        pcall(function() d.healthBg:Remove() end)
        pcall(function() d.healthFill:Remove() end)
        pcall(function() if d.highlight then d.highlight:Destroy() end end)
        P.PLAYER_ESP_LIST[player] = nil
    end
end

local function clearAllPlayerESP()
    for player, _ in pairs(P.PLAYER_ESP_LIST) do
        removePlayerDrawings(player)
    end
end

local conn = RunService.Heartbeat:Connect(function()
    local cam = Workspace.CurrentCamera
    
    if not P.PLAYER_ESP then
        clearAllPlayerESP()
        return
    end

    for _, player in pairs(Players:GetPlayers()) do
        if player == LocalPlayer then continue end
        
        local char = player.Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        local head = char and char:FindFirstChild("Head")
        
        if char and hum and hrp and head then
            createPlayerDrawings(player)
            local d = P.PLAYER_ESP_LIST[player]
            
            if d.highlight then
                d.highlight.Adornee = char
                d.highlight.Parent = char
                d.highlight.Enabled = true
            end
            
            local hrpPos, onScreen = cam:WorldToViewportPoint(hrp.Position)
            
            -- Extra check for behind camera (Z < 0)
            if onScreen and hrpPos.Z > 0 then
                local distVal = math.floor((cam.CFrame.Position - hrp.Position).Magnitude)
                
                -- Bounding calculations
                local top, _ = cam:WorldToViewportPoint(head.Position + Vector3.new(0, 1.5, 0))
                local bottom, _ = cam:WorldToViewportPoint(hrp.Position - Vector3.new(0, 3, 0))
                
                -- Tracer
                if P.PLAYER_TRACERS_ENABLED then
                    d.tracer.From = Vector2.new(cam.ViewportSize.X / 2, cam.ViewportSize.Y)
                    d.tracer.To = Vector2.new(hrpPos.X, hrpPos.Y)
                    d.tracer.Visible = true
                else
                    d.tracer.Visible = false
                end
                
                -- Name
                if P.PLAYER_NAMES_ENABLED then
                    d.name.Text = player.DisplayName or player.Name
                    d.name.Position = Vector2.new(hrpPos.X, top.Y - 15)
                    d.name.Visible = true
                else
                    d.name.Visible = false
                end
                
                -- Distance
                if P.PLAYER_DISTANCE_ENABLED then
                    d.dist.Text = distVal .. "m"
                    d.dist.Position = Vector2.new(hrpPos.X, bottom.Y + 5)
                    d.dist.Visible = true
                else
                    d.dist.Visible = false
                end
                
                -- Health
                if P.PLAYER_HEALTH_ENABLED then
                    local hPct = math.clamp(hum.Health / hum.MaxHealth, 0, 1)
                    local barX = hrpPos.X - (math.abs(top.Y - bottom.Y) / 4) - 6
                    
                    d.healthBg.From = Vector2.new(barX, top.Y)
                    d.healthBg.To = Vector2.new(barX, bottom.Y)
                    d.healthBg.Visible = true
                    
                    d.healthFill.From = Vector2.new(barX, bottom.Y)
                    d.healthFill.To = Vector2.new(barX, bottom.Y - (math.abs(top.Y - bottom.Y) * hPct))
                    d.healthFill.Color = Color3.fromHSV(hPct * 0.3, 1, 1)
                    d.healthFill.Visible = true
                else
                    d.healthBg.Visible = false
                    d.healthFill.Visible = false
                end
            else
                d.tracer.Visible = false
                d.name.Visible = false
                d.dist.Visible = false
                d.healthBg.Visible = false
                d.healthFill.Visible = false
                if d.highlight then d.highlight.Enabled = false end
            end
        else
            -- Player has no character but is still in game
            local d = P.PLAYER_ESP_LIST[player]
            if d then
                d.tracer.Visible = false
                d.name.Visible = false
                d.dist.Visible = false
                d.healthBg.Visible = false
                d.healthFill.Visible = false
                if d.highlight then d.highlight.Enabled = false end
            end
        end
    end
    
    -- Cleanup for players who left
    for player, _ in pairs(P.PLAYER_ESP_LIST) do
        if not player or not player.Parent then
            removePlayerDrawings(player)
        end
    end
end)

table.insert(P.CONNECTIONS, conn)
