--[[
  Secours de France RP GUI
]]

local P = _G.MYA_SECOURS_RP
if not P then error("[SecoursRP] Load runtime.lua first") end

local fetch = _G.MYA_FETCH
local repoBase = _G.MYA_REPO_BASE

local libSrc = fetch(repoBase .. "lib/mya_game_ui.lua")
local libFn = loadstring(libSrc, "@lib/mya_game_ui")
local MyaUI = libFn()
local THEME, C = MyaUI.defaultTheme()

local ui = Instance.new("ScreenGui")
ui.Name = "MyaSecoursRP"
ui.IgnoreGuiInset = true
ui.ResetOnSpawn = false
ui.Parent = (gethui and gethui()) or game:GetService("CoreGui")

local ts = game:GetService("TweenService")
local uis = game:GetService("UserInputService")

local shell = MyaUI.createHubShell({
    ui = ui,
    THEME = THEME,
    C = C,
    ts = ts,
    uis = uis,
    titleText = "Mya  ·  Secours de France",
    tabNames = { "Farming", "Visuals", "Settings" },
    subPages = {
        Farming = { "ATM", "Houses" },
        Visuals = { "Players", "World" },
    },
    statusDefault = "Ready · Press Delete to toggle",
})

local atm_page = shell.all_sub_pages["Farming"]["ATM"]
local house_page = shell.all_sub_pages["Farming"]["Houses"]
local players_page = shell.all_sub_pages["Visuals"]["Players"]
local world_page = shell.all_sub_pages["Visuals"]["World"]
local settings_page = shell.tab_containers["Settings"]

-- Helper UI functions
local function make_row(parent, h)
    local row = Instance.new("Frame")
    row.BackgroundColor3 = C.panel
    row.BorderSizePixel = 0
    row.Size = UDim2.new(1, 0, 0, h or 34)
    row.Parent = parent
    local sep = Instance.new("Frame")
    sep.BackgroundColor3 = THEME.border
    sep.BorderSizePixel = 0
    sep.Position = UDim2.new(0, 0, 1, -1)
    sep.Size = UDim2.new(1, 0, 0, 1)
    sep.Parent = row
    return row
end

local function section_label(parent, text)
    local lbl = Instance.new("TextLabel")
    lbl.Font = Enum.Font.GothamBold
    lbl.Text = "  " .. text:upper()
    lbl.TextColor3 = C.accent
    lbl.TextSize = 10
    lbl.BackgroundTransparency = 1
    lbl.Size = UDim2.new(1, 0, 0, 22)
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Parent = parent
end

local function make_toggle(parent, label, get_fn, set_fn)
    local row = make_row(parent)
    local lbl = Instance.new("TextLabel")
    lbl.Font = Enum.Font.Gotham; lbl.Text = label; lbl.TextColor3 = C.text; lbl.TextSize = 13
    lbl.BackgroundTransparency = 1; lbl.Position = UDim2.fromOffset(14, 0); lbl.Size = UDim2.new(1, -56, 1, 0)
    lbl.TextXAlignment = Enum.TextXAlignment.Left; lbl.Parent = row
    local pill = Instance.new("Frame")
    pill.BackgroundColor3 = get_fn() and C.tog_on or C.tog_off
    pill.Position = UDim2.new(1, -46, 0.5, -9); pill.Size = UDim2.fromOffset(36, 18)
    Instance.new("UICorner", pill).CornerRadius = UDim.new(1, 0); pill.Parent = row
    local knob = Instance.new("Frame")
    knob.BackgroundColor3 = Color3.new(1, 1, 1); knob.Size = UDim2.fromOffset(12, 12)
    knob.Position = get_fn() and UDim2.fromOffset(21, 3) or UDim2.fromOffset(3, 3)
    Instance.new("UICorner", knob).CornerRadius = UDim.new(1, 0); knob.Parent = pill
    local btn = Instance.new("TextButton")
    btn.BackgroundTransparency = 1; btn.Size = UDim2.fromScale(1, 1); btn.Text = ""; btn.Parent = row
    btn.MouseButton1Click:Connect(function()
        local new = not get_fn()
        set_fn(new)
        pill.BackgroundColor3 = new and C.tog_on or C.tog_off
        knob.Position = new and UDim2.fromOffset(21, 3) or UDim2.fromOffset(3, 3)
    end)
end

local function make_slider(parent, label, min_v, max_v, def, fmt, on_change)
    local row = make_row(parent, 48)
    local lbl = Instance.new("TextLabel")
    lbl.Font = Enum.Font.Gotham; lbl.Text = label; lbl.TextColor3 = C.text; lbl.TextSize = 12
    lbl.BackgroundTransparency = 1; lbl.Position = UDim2.fromOffset(14, 4); lbl.Size = UDim2.new(1, -28, 0, 16)
    lbl.TextXAlignment = Enum.TextXAlignment.Left; lbl.Parent = row
    local val_lbl = Instance.new("TextLabel")
    val_lbl.Font = Enum.Font.GothamSemibold; val_lbl.TextColor3 = C.accent; val_lbl.TextSize = 11
    val_lbl.BackgroundTransparency = 1; val_lbl.Position = UDim2.fromOffset(14, 4); val_lbl.Size = UDim2.new(1, -28, 0, 16)
    val_lbl.TextXAlignment = Enum.TextXAlignment.Right; val_lbl.Text = string.format(fmt, def); val_lbl.Parent = row
    local track = Instance.new("Frame")
    track.BackgroundColor3 = C.slid_bg; track.Position = UDim2.fromOffset(14, 28); track.Size = UDim2.new(1, -28, 0, 6)
    Instance.new("UICorner", track).CornerRadius = UDim.new(1, 0); track.Parent = row
    local fill = Instance.new("Frame")
    fill.BackgroundColor3 = C.slid_fg; fill.Size = UDim2.fromScale((def - min_v) / (max_v - min_v), 1)
    Instance.new("UICorner", fill).CornerRadius = UDim.new(1, 0); fill.Parent = track
    local thumb = Instance.new("Frame")
    thumb.BackgroundColor3 = Color3.new(1, 1, 1); thumb.Size = UDim2.fromOffset(12, 12)
    thumb.Position = UDim2.new((def - min_v) / (max_v - min_v), -6, 0.5, -6)
    Instance.new("UICorner", thumb).CornerRadius = UDim.new(1, 0); thumb.Parent = track
    local dragging = false
    local function update(input)
        local pct = math.clamp((input.Position.X - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
        local val = min_v + (max_v - min_v) * pct
        fill.Size = UDim2.fromScale(pct, 1); thumb.Position = UDim2.new(pct, -6, 0.5, -6)
        val_lbl.Text = string.format(fmt, val); on_change(val)
    end
    track.InputBegan:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = true; update(input) end end)
    uis.InputChanged:Connect(function(input) if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then update(input) end end)
    uis.InputEnded:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end end)
end

local function make_big_pink_button(parent, text, callback)
    local row = make_row(parent, 40)
    row.BackgroundColor3 = C.accent
    local btn = Instance.new("TextButton")
    btn.Font = Enum.Font.GothamBold; btn.Text = text; btn.TextColor3 = Color3.new(1, 1, 1); btn.TextSize = 14
    btn.BackgroundTransparency = 1; btn.Size = UDim2.fromScale(1, 1); btn.Parent = row
    btn.MouseButton1Click:Connect(callback)
end

-- ATM Page
section_label(atm_page, "Automation")
make_toggle(atm_page, "Auto Steal ATMs", function() return P.AUTO_ATM end, function(v) P.AUTO_ATM = v end)
make_slider(atm_page, "Farming Delay", 0.5, 5, P.FARM_DELAY, "%.1fs", function(v) P.FARM_DELAY = v end)

-- House Page
section_label(house_page, "Automation")
make_toggle(house_page, "Auto Steal Houses", function() return P.AUTO_HOUSE end, function(v) P.AUTO_HOUSE = v end)
make_toggle(house_page, "Auto Lockpick (Minigame)", function() return P.AUTO_LOCKPICK end, function(v) P.AUTO_LOCKPICK = v end)
make_slider(house_page, "Farming Delay", 0.5, 5, P.FARM_DELAY, "%.1fs", function(v) P.FARM_DELAY = v end)

-- Visuals Page
-- Players Sub-page
section_label(players_page, "Player ESP")
make_toggle(players_page, "Enable Player ESP", function() return P.PLAYER_ESP end, function(v) P.PLAYER_ESP = v end)
make_toggle(players_page, "Player Tracers", function() return P.PLAYER_TRACERS_ENABLED end, function(v) P.PLAYER_TRACERS_ENABLED = v end)
make_toggle(players_page, "Player Names", function() return P.PLAYER_NAMES_ENABLED end, function(v) P.PLAYER_NAMES_ENABLED = v end)
make_toggle(players_page, "Show Distance", function() return P.PLAYER_DISTANCE_ENABLED end, function(v) P.PLAYER_DISTANCE_ENABLED = v end)
make_toggle(players_page, "Health Bars", function() return P.PLAYER_HEALTH_ENABLED end, function(v) P.PLAYER_HEALTH_ENABLED = v end)

-- World Sub-page
section_label(world_page, "ESP")
make_toggle(world_page, "ATM ESP", function() return P.ATM_ESP end, function(v) P.ATM_ESP = v end)
make_toggle(world_page, "ATM Tracers", function() return P.ATM_TRACERS_ENABLED end, function(v) P.ATM_TRACERS_ENABLED = v end)
make_toggle(world_page, "House ESP", function() return P.HOUSE_ESP end, function(v) P.HOUSE_ESP = v end)
make_toggle(world_page, "House Tracers", function() return P.HOUSE_TRACERS_ENABLED end, function(v) P.HOUSE_TRACERS_ENABLED = v end)

section_label(world_page, "Shops")
make_toggle(world_page, "Dark Store Seller ESP", function() return P.VENDEUR_ESP end, function(v) P.VENDEUR_ESP = v end)
make_toggle(world_page, "Seller Tracers", function() return P.VENDEUR_TRACERS_ENABLED end, function(v) P.VENDEUR_TRACERS_ENABLED = v end)

-- Settings Page
section_label(settings_page, "Client")
make_big_pink_button(settings_page, "UNLOAD SCRIPT", function()
    _G.unload_secours_rp()
    ui:Destroy()
end)

-- Menu Toggle
uis.InputBegan:Connect(function(input, gp)
    if not gp and input.KeyCode == Enum.KeyCode.Delete then shell.main.Visible = not shell.main.Visible end
end)

shell.statusLabel.Text = "Secours de France RP Modular Loaded"
