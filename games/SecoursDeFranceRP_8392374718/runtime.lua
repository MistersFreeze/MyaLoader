--[[
    Secours de France RP - Runtime Bootstrap
    Loads sub-modules from runtime/ directory
]]

local fetch = _G.MYA_FETCH
local repoBase = _G.MYA_REPO_BASE
local base = repoBase .. "games/SecoursDeFranceRP_8392374718/runtime/"

local modules = {
    "globals.lua",
    "esp_atm.lua",
    "esp_houses.lua",
    "esp_vendeur.lua",
    "esp_players.lua",
    "farm_atm.lua",
    "farm_houses.lua",
    "auto_lockpick.lua",
}

for _, mod in ipairs(modules) do
    local src = fetch(base .. mod)
    if src then
        local fn = loadstring(src, "@SecoursDeFranceRP/runtime/" .. mod)
        if typeof(fn) == "function" then
            fn()
        end
    end
end

-- Global Unload hook
_G.unload_secours_rp = function()
    local P = _G.MYA_SECOURS_RP
    if not P then return end
    
    P.ATM_ESP = false
    P.HOUSE_ESP = false
    P.VENDEUR_ESP = false
    P.AUTO_ATM = false
    P.AUTO_HOUSE = false
    P.AUTO_LOCKPICK = false
    P.MYA_FORCE_LOCKPICK = false
    if P.Settings then
        P.Settings.AUTO_ATM = false
        P.Settings.AUTO_HOUSE = false
        P.Settings.AUTO_LOCKPICK = false
        P.Settings.AUTO_HOUSE_TELEPORT = false
    end

    P.clearHighlights(P.ATM_HIGHLIGHTS)
    P.clearHighlights(P.HOUSE_HIGHLIGHTS)
    P.clearHighlights(P.VENDEUR_HIGHLIGHTS)
    
    for p, _ in pairs(P.PLAYER_ESP_LIST) do
        local d = P.PLAYER_ESP_LIST[p]
        if d then
            d.tracer:Remove()
            d.name:Remove()
            d.dist:Remove()
            d.healthBg:Remove()
            d.healthFill:Remove()
            if d.highlight then d.highlight:Destroy() end
        end
    end
    table.clear(P.PLAYER_ESP_LIST)
    
    P.clearDrawings(P.ATM_TRACERS)
    P.clearDrawings(P.HOUSE_TRACERS)
    P.clearDrawings(P.VENDEUR_TRACERS)
    
    for _, c in pairs(P.CONNECTIONS) do
        if c then c:Disconnect() end
    end
    table.clear(P.CONNECTIONS)
end
