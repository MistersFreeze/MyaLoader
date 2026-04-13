--[[
    Mya · Operation One — tactical UI (standalone from legacy purple theme)
]]--
local gethui_support = gethui ~= nil
local uis  = cloneref ~= nil and cloneref(game:GetService("UserInputService")) or game:GetService("UserInputService")
local http = game:GetService("HttpService")
local ts   = game:GetService("TweenService")

local CONFIG_FOLDER = "mya_op1_configs"

local function normalize_fs_path(path)
    if type(path) ~= "string" then return path end
    return path:gsub("\\", "/")
end

local function ensure_config_dir()
    if not makefolder then return end
    pcall(function()
        local exists = false
        if isfolder then
            local ok, res = pcall(isfolder, CONFIG_FOLDER)
            if ok and res then exists = true end
        end
        if not exists then makefolder(CONFIG_FOLDER) end
    end)
end
ensure_config_dir()

local function rand_str(len)
    local chars = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
    local r = {}
    for i = 1, len do r[i] = chars:sub(math.random(1,#chars), math.random(1,#chars)) end
    return table.concat(r)
end

-- -------------------- Colour palette (pink accent) --------------------
local C = {
	bg = Color3.fromRGB(14, 16, 20),
	panel = Color3.fromRGB(22, 24, 30),
	header = Color3.fromRGB(18, 20, 26),
	tab_off = Color3.fromRGB(26, 28, 34),
	tab_on = Color3.fromRGB(230, 120, 175),
	accent = Color3.fromRGB(230, 120, 175),
	row_hover = Color3.fromRGB(32, 34, 42),
	tog_off = Color3.fromRGB(48, 50, 58),
	tog_on = Color3.fromRGB(230, 120, 175),
	text = Color3.fromRGB(236, 238, 244),
	dim = Color3.fromRGB(120, 124, 138),
	red = Color3.fromRGB(220, 80, 80),
	green = Color3.fromRGB(90, 200, 130),
	slid_bg = Color3.fromRGB(38, 40, 48),
	slid_fg = Color3.fromRGB(230, 120, 175),
	input_bg = Color3.fromRGB(28, 30, 38),
	picker_bg = Color3.fromRGB(16, 18, 22),
	sub_off = Color3.fromRGB(30, 32, 40),
	sub_on = Color3.fromRGB(230, 120, 175),
}

-- -------------------- Root GUI --------------------
local ui = Instance.new("ScreenGui")
ui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ui.Name           = rand_str(5)
ui.IgnoreGuiInset = true
ui.DisplayOrder   = 10
ui.Parent         = gethui_support and gethui() or game:GetService("CoreGui")

-- Separate ScreenGui so notifications stay visible when the main menu is hidden
local notif_ui = Instance.new("ScreenGui")
notif_ui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
notif_ui.Name           = rand_str(5) .. "_N"
notif_ui.IgnoreGuiInset = true
notif_ui.DisplayOrder   = 100
notif_ui.Enabled        = true
notif_ui.ResetOnSpawn   = false
notif_ui.Parent         = gethui_support and gethui() or game:GetService("CoreGui")

local blocker = Instance.new("TextButton")
blocker.BackgroundTransparency = 1
blocker.Size    = UDim2.fromScale(1, 1)
blocker.ZIndex  = 1
blocker.Modal   = true
blocker.Text    = ""
blocker.Visible = false
blocker.Parent  = ui

local old_mouse_icon = uis.MouseIconEnabled
local old_mouse_behavior = uis.MouseBehavior

ui:GetPropertyChangedSignal("Enabled"):Connect(function()
    blocker.Visible = ui.Enabled
    if ui.Enabled then
        old_mouse_icon = uis.MouseIconEnabled
        old_mouse_behavior = uis.MouseBehavior
        uis.MouseIconEnabled = false
        uis.MouseBehavior = Enum.MouseBehavior.Default
    else
        uis.MouseIconEnabled = old_mouse_icon
        uis.MouseBehavior = old_mouse_behavior
        if current_picker_close then current_picker_close() end
    end
end)

local notif_top = Instance.new("Frame")
notif_top.Name = "NotifTop"
notif_top.BackgroundTransparency = 1
notif_top.Size = UDim2.fromScale(1, 1)
notif_top.Parent = notif_ui

local notif_container = Instance.new("Frame", notif_top)
notif_container.Name = "NotifContainer"
notif_container.BackgroundTransparency = 1
notif_container.Size = UDim2.fromOffset(260, 400)
notif_container.Position = UDim2.new(1, -270, 1, -420)

local n_layout = Instance.new("UIListLayout", notif_container)
n_layout.FillDirection = Enum.FillDirection.Vertical
n_layout.HorizontalAlignment = Enum.HorizontalAlignment.Right
n_layout.VerticalAlignment = Enum.VerticalAlignment.Bottom
n_layout.Padding = UDim.new(0, 8)

local function notify(title, text, duration)
    duration = duration or 3
    local f = Instance.new("Frame")
    f.BackgroundColor3 = C.panel
    f.Size = UDim2.fromOffset(250, 55)
    f.Position = UDim2.fromOffset(260, 0)
    Instance.new("UICorner", f).CornerRadius = UDim.new(0, 4)
    local str = Instance.new("UIStroke", f)
    str.Color = Color3.fromRGB(40,40,55)

    local lbl_t = Instance.new("TextLabel", f)
    lbl_t.BackgroundTransparency=1; lbl_t.Position=UDim2.fromOffset(16, 8); lbl_t.Size=UDim2.new(1, -24, 0, 16)
    lbl_t.Font=Enum.Font.GothamBold; lbl_t.Text=title; lbl_t.TextColor3=C.accent; lbl_t.TextSize=12; lbl_t.TextXAlignment=Enum.TextXAlignment.Left

    local lbl_d = Instance.new("TextLabel", f)
    lbl_d.BackgroundTransparency=1; lbl_d.Position=UDim2.fromOffset(16, 26); lbl_d.Size=UDim2.new(1, -24, 0, 16)
    lbl_d.Font=Enum.Font.Gotham; lbl_d.Text=text; lbl_d.TextColor3=C.text; lbl_d.TextSize=11; lbl_d.TextXAlignment=Enum.TextXAlignment.Left; lbl_d.TextWrapped = true

    local stripe = Instance.new("Frame", f)
    stripe.BackgroundColor3=C.accent; stripe.BorderSizePixel=0; stripe.Size=UDim2.new(0,3,1,0)
    Instance.new("UICorner", stripe).CornerRadius = UDim.new(0, 4)

    f.Parent = notif_container
    ts:Create(f, TweenInfo.new(0.4, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out), {Position = UDim2.new(0,0,0,0)}):Play()

    task.spawn(function()
        task.wait(duration)
        if not f then return end
        local t_out = ts:Create(f, TweenInfo.new(0.4, Enum.EasingStyle.Cubic, Enum.EasingDirection.In), {Position = UDim2.fromOffset(260, 0), BackgroundTransparency = 1})
        t_out:Play()
        ts:Create(str, TweenInfo.new(0.4), {Transparency=1}):Play()
        ts:Create(lbl_t, TweenInfo.new(0.4), {TextTransparency=1}):Play()
        ts:Create(lbl_d, TweenInfo.new(0.4), {TextTransparency=1}):Play()
        ts:Create(stripe, TweenInfo.new(0.4), {BackgroundTransparency=1}):Play()
        t_out.Completed:Wait()
        f:Destroy()
    end)
end
_G.mya_notify = notify

-- Custom Cursor
local cursor = Instance.new("Frame")
cursor.Name = "cursor"; cursor.Size = UDim2.fromOffset(18, 18); cursor.AnchorPoint = Vector2.new(0.5, 0.5)
cursor.BackgroundTransparency = 1; cursor.ZIndex = 5000; cursor.Visible = false; cursor.Parent = ui

local function make_cursor_segment(size, pos)
    local f = Instance.new("Frame")
    f.BackgroundColor3 = Color3.new(1,1,1); f.BorderSizePixel = 0; f.Size = size; f.Position = pos; f.Parent = cursor
    return f
end
make_cursor_segment(UDim2.new(1, 0, 0, 1), UDim2.fromScale(0, 0.5))
make_cursor_segment(UDim2.new(0, 1, 1, 0), UDim2.fromScale(0.5, 0))

game:GetService("RunService").RenderStepped:Connect(function()
    if ui.Enabled then
        local m = uis:GetMouseLocation()
        cursor.Position = UDim2.fromOffset(m.X, m.Y)
        cursor.Visible = true
        uis.MouseIconEnabled = false
    else
        cursor.Visible = false
    end
end)

local current_picker_close = nil

-- -------------------- Main Window --------------------
local WIN_W, WIN_H = 360, 560

local main = Instance.new("Frame")
main.Name = "main"
main.BackgroundColor3 = C.bg
main.BackgroundTransparency = 0
main.BorderSizePixel = 0
main.Position = UDim2.new(0.5, 80, 0.5, 0)
main.AnchorPoint = Vector2.new(0.5, 0.5)
main.Size = UDim2.fromOffset(WIN_W, WIN_H)
main.Active = true
main.ZIndex = 10
main.Parent = ui
Instance.new("UICorner", main).CornerRadius = UDim.new(0, 8)

local accentBar = Instance.new("Frame")
accentBar.Name = "AccentBar"
accentBar.BackgroundColor3 = C.accent
accentBar.BorderSizePixel = 0
accentBar.Size = UDim2.new(0, 4, 1, 0)
accentBar.Position = UDim2.new(0, 0, 0, 0)
accentBar.Parent = main
Instance.new("UICorner", accentBar).CornerRadius = UDim.new(0, 8)

local header = Instance.new("Frame")
header.BackgroundColor3 = C.header
header.BorderSizePixel = 0
header.Size = UDim2.new(1, -4, 0, 40)
header.Position = UDim2.new(0, 4, 0, 0)
header.ZIndex = 10
header.Parent = main
Instance.new("UICorner", header).CornerRadius = UDim.new(0, 8)
local hdr_sq = Instance.new("Frame")
hdr_sq.BackgroundColor3 = C.header
hdr_sq.BorderSizePixel = 0
hdr_sq.Position = UDim2.fromOffset(0, 28)
hdr_sq.Size = UDim2.new(1, 0, 0, 14)
hdr_sq.Parent = header

local title_lbl = Instance.new("TextLabel")
title_lbl.Font = Enum.Font.GothamBold
title_lbl.Text = "OPERATION ONE"
title_lbl.TextColor3 = C.text
title_lbl.TextSize = 15
title_lbl.BackgroundTransparency = 1
title_lbl.BorderSizePixel = 0
title_lbl.Position = UDim2.fromOffset(14, 0)
title_lbl.Size = UDim2.new(1, -24, 1, 0)
title_lbl.TextXAlignment = Enum.TextXAlignment.Left
title_lbl.TextYAlignment = Enum.TextYAlignment.Center
title_lbl.Parent = header

-- -------------------- Tab bar --------------------
local TAB_NAMES = { "Combat", "Movement", "Visuals", "Misc", "Configs" }

local tab_bar = Instance.new("Frame")
tab_bar.BackgroundColor3=C.header; tab_bar.BorderSizePixel=0
tab_bar.Position=UDim2.fromOffset(4,40); tab_bar.Size=UDim2.new(1,-4,0,30)
tab_bar.ZIndex=10; tab_bar.Parent=main
Instance.new("UIListLayout",tab_bar).FillDirection=Enum.FillDirection.Horizontal

local tab_buttons = {}; local tab_containers = {}; local active_tab = nil

-- Sub-nav bar (hidden for tabs without sub-pages)
local sub_bar = Instance.new("Frame")
sub_bar.BackgroundColor3 = C.bg; sub_bar.BorderSizePixel = 0
sub_bar.Position = UDim2.fromOffset(4, 70); sub_bar.Size = UDim2.new(1, -4, 0, 26)
sub_bar.ZIndex = 10; sub_bar.Visible = false; sub_bar.Parent = main
local sub_bar_layout = Instance.new("UIListLayout", sub_bar)
sub_bar_layout.FillDirection = Enum.FillDirection.Horizontal
sub_bar_layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
sub_bar_layout.Padding = UDim.new(0, 4)
sub_bar_layout.VerticalAlignment = Enum.VerticalAlignment.Center

local content = Instance.new("Frame")
content.BackgroundTransparency=1; content.BorderSizePixel=0
content.Position=UDim2.fromOffset(4,70); content.Size=UDim2.new(1,-4,1,-70)
content.ClipsDescendants=true; content.Parent=main

-- -------------------- Sub-page infrastructure --------------------
local SUB_PAGES = {
    Combat   = { "Aim Assist", "Silent Aim", "Weapons" },
    Movement = { "Fly", "Jump Boost" },
    Visuals  = { "Player ESP", "Gadgets", "World" },
}

local all_sub_buttons = {}
local all_sub_pages   = {}

local function make_page()
    local page = Instance.new("ScrollingFrame")
    page.BackgroundTransparency=1; page.BorderSizePixel=0
    page.Size=UDim2.fromScale(1,1); page.CanvasSize=UDim2.fromOffset(0,0)
    page.AutomaticCanvasSize=Enum.AutomaticSize.Y; page.ScrollBarThickness=3
    page.ScrollBarImageColor3=C.accent; page.Visible=false; page.Parent=content
    local ul=Instance.new("UIListLayout"); ul.SortOrder=Enum.SortOrder.LayoutOrder; ul.Padding=UDim.new(0,0); ul.Parent=page
    local up=Instance.new("UIPadding"); up.PaddingTop=UDim.new(0,6); up.Parent=page
    return page
end

local function switch_sub(tab_name, sub_name)
    local subs = all_sub_pages[tab_name]
    local btns = all_sub_buttons[tab_name]
    if not subs then return end
    for n, pg in pairs(subs) do pg.Visible = (n == sub_name) end
    for n, b  in pairs(btns) do
        b.BackgroundColor3 = (n == sub_name) and C.sub_on or C.sub_off
        b.TextColor3       = (n == sub_name) and Color3.fromRGB(45, 18, 32) or C.dim
    end
end

local function switch_tab(name)
    active_tab = name
    local has_subs = SUB_PAGES[name] ~= nil

    for n, cont in pairs(tab_containers) do cont.Visible = (n == name) end
    for n, b in pairs(tab_buttons) do
        b.BackgroundColor3 = (n == name) and C.tab_on or C.tab_off
        b.TextColor3       = (n == name) and Color3.fromRGB(45, 18, 32) or C.dim
    end

    -- Show/hide sub-nav bar and adjust content position
    sub_bar.Visible = has_subs
    if has_subs then
        content.Position = UDim2.fromOffset(4, 96)
        content.Size     = UDim2.new(1, -4, 1, -96)
    else
        content.Position = UDim2.fromOffset(4, 70)
        content.Size     = UDim2.new(1, -4, 1, -70)
    end

    -- Rebuild sub-bar buttons
    for _, c in ipairs(sub_bar:GetChildren()) do
        if c:IsA("TextButton") then c:Destroy() end
    end
    if has_subs then
        local sub_names = SUB_PAGES[name]
        all_sub_buttons[name] = all_sub_buttons[name] or {}
        for i, sn in ipairs(sub_names) do
            local sb = Instance.new("TextButton")
            sb.LayoutOrder = i; sb.BackgroundColor3 = C.sub_off; sb.BorderSizePixel = 0
            sb.Size = UDim2.fromOffset(math.floor((WIN_W - 8 - (#sub_names - 1) * 4) / #sub_names), 20)
            sb.Font = Enum.Font.GothamSemibold; sb.Text = sn; sb.TextColor3 = C.dim; sb.TextSize = 10
            sb.AutoButtonColor = false; sb.Parent = sub_bar
            Instance.new("UICorner", sb).CornerRadius = UDim.new(0, 8)
            sb.MouseButton1Click:Connect(function() switch_sub(name, sn) end)
            all_sub_buttons[name][sn] = sb
        end
        switch_sub(name, sub_names[1])
    end
end

-- Create tab buttons
for i, name in ipairs(TAB_NAMES) do
    local b = Instance.new("TextButton")
    b.LayoutOrder=i; b.BackgroundColor3=C.tab_off; b.BorderSizePixel=0
    b.Size=UDim2.new(1/#TAB_NAMES,0,1,0); b.Font=Enum.Font.GothamSemibold
    b.Text=name; b.TextColor3=C.dim; b.TextSize=11; b.AutoButtonColor=false; b.Parent=tab_bar
    tab_buttons[name] = b
    b.MouseButton1Click:Connect(function() switch_tab(name) end)
end

-- Create tab containers (invisible wrappers that hold sub-pages or direct pages)
for _, name in ipairs(TAB_NAMES) do
    local cont = Instance.new("Frame")
    cont.BackgroundTransparency = 1; cont.Size = UDim2.fromScale(1, 1)
    cont.Visible = false; cont.Parent = content
    tab_containers[name] = cont

    if SUB_PAGES[name] then
        all_sub_pages[name] = {}
        for _, sn in ipairs(SUB_PAGES[name]) do
            local pg = Instance.new("ScrollingFrame")
            pg.BackgroundTransparency=1; pg.BorderSizePixel=0
            pg.Size=UDim2.fromScale(1,1); pg.CanvasSize=UDim2.fromOffset(0,0)
            pg.AutomaticCanvasSize=Enum.AutomaticSize.Y; pg.ScrollBarThickness=3
            pg.ScrollBarImageColor3=C.accent; pg.Visible=false; pg.Parent=cont
            local ul=Instance.new("UIListLayout"); ul.SortOrder=Enum.SortOrder.LayoutOrder; ul.Padding=UDim.new(0,0); ul.Parent=pg
            local up=Instance.new("UIPadding"); up.PaddingTop=UDim.new(0,6); up.Parent=pg
            all_sub_pages[name][sn] = pg
        end
    end
end

-- -------------------- Row builders --------------------
local function section_label(parent, text, order)
    local lbl = Instance.new("TextLabel")
    lbl.LayoutOrder=order; lbl.Font=Enum.Font.GothamBold
    lbl.Text="  "..text:upper(); lbl.TextColor3=C.accent; lbl.TextSize=10
    lbl.BackgroundTransparency=1; lbl.BorderSizePixel=0
    lbl.Size=UDim2.new(1,0,0,22); lbl.TextXAlignment=Enum.TextXAlignment.Left
    lbl.Parent=parent
end

local function make_row(parent, order, h)
    h = h or 34
    local row = Instance.new("Frame")
    row.LayoutOrder=order; row.BackgroundColor3=Color3.fromRGB(20,20,26)
    row.BackgroundTransparency=0; row.BorderSizePixel=0
    row.Size=UDim2.new(1,0,0,h); row.Parent=parent
    local sep=Instance.new("Frame")
    sep.BackgroundColor3=Color3.fromRGB(35,35,45); sep.BorderSizePixel=0
    sep.Position=UDim2.new(0,0,1,-1); sep.Size=UDim2.new(1,0,0,1); sep.Parent=row
    row.MouseEnter:Connect(function() row.BackgroundColor3=C.row_hover end)
    row.MouseLeave:Connect(function() row.BackgroundColor3=Color3.fromRGB(20,20,26) end)
    return row
end

-- -------------------- Color Picker (must be defined before make_toggle_with_color) --------------------
local function bind_colorpicker_popup(display, default_color, on_change)
    local picker_w, picker_h = 240, 185
    local h, s, v = default_color:ToHSV()

    local drop = Instance.new("TextButton")
    drop.AutoButtonColor = false; drop.Text = ""
    drop.BackgroundColor3 = C.bg; drop.BorderSizePixel = 0
    drop.Size = UDim2.fromOffset(picker_w, picker_h); drop.Visible = false
    drop.ZIndex = 200; drop.Active = true; drop.Parent = main
    Instance.new("UICorner", drop).CornerRadius = UDim.new(0,6)
    local d_stroke = Instance.new("UIStroke", drop)
    d_stroke.Color = Color3.fromRGB(80, 80, 100); d_stroke.Thickness = 1.5

    local sv_map = Instance.new("TextButton")
    sv_map.AutoButtonColor = false; sv_map.Text = ""
    sv_map.BackgroundColor3 = Color3.fromHSV(h, 1, 1); sv_map.BorderSizePixel = 0
    sv_map.Position = UDim2.fromOffset(10, 10); sv_map.Size = UDim2.fromOffset(picker_w-50, 140)
    sv_map.ZIndex = 10; sv_map.Active = true; sv_map.Parent = drop

    local g_v = Instance.new("UIGradient", sv_map)
    g_v.Color = ColorSequence.new(Color3.new(1,1,1), Color3.new(0,0,0))
    g_v.Rotation = 90
    local s_overlay = Instance.new("Frame")
    s_overlay.Size = UDim2.fromScale(1,1); s_overlay.BackgroundTransparency = 0
    s_overlay.BorderSizePixel = 0; s_overlay.Parent = sv_map
    local g_s = Instance.new("UIGradient", s_overlay)
    g_s.Color = ColorSequence.new(Color3.new(1,1,1), Color3.fromHSV(0,0,1))
    g_s.Transparency = NumberSequence.new(0, 1)

    local sv_thumb = Instance.new("Frame")
    sv_thumb.BackgroundColor3 = Color3.new(1,1,1)
    sv_thumb.Size = UDim2.fromOffset(6,6); sv_thumb.ZIndex = 15; sv_thumb.Parent = sv_map
    Instance.new("UICorner", sv_thumb).CornerRadius = UDim.new(1,0)
    Instance.new("UIStroke", sv_thumb).Color = Color3.new(0,0,0)

    local hue_rail = Instance.new("TextButton")
    hue_rail.AutoButtonColor = false; hue_rail.Text = ""
    hue_rail.Position = UDim2.fromOffset(picker_w-30, 10); hue_rail.Size = UDim2.fromOffset(20, 140)
    hue_rail.BorderSizePixel = 0; hue_rail.ZIndex = 10; hue_rail.Active = true; hue_rail.Parent = drop
    local h_grad = Instance.new("UIGradient", hue_rail)
    h_grad.Rotation = 90
    h_grad.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromHSV(0,1,1)),
        ColorSequenceKeypoint.new(0.16, Color3.fromHSV(0.16,1,1)),
        ColorSequenceKeypoint.new(0.33, Color3.fromHSV(0.33,1,1)),
        ColorSequenceKeypoint.new(0.5, Color3.fromHSV(0.5,1,1)),
        ColorSequenceKeypoint.new(0.66, Color3.fromHSV(0.66,1,1)),
        ColorSequenceKeypoint.new(0.83, Color3.fromHSV(0.83,1,1)),
        ColorSequenceKeypoint.new(1, Color3.fromHSV(1,1,1))
    })
    local hue_thumb = Instance.new("Frame")
    hue_thumb.BackgroundColor3 = Color3.new(1,1,1); hue_thumb.Size = UDim2.new(1, 4, 0, 4)
    hue_thumb.Position = UDim2.new(0.5, -12, 0, 0); hue_thumb.ZIndex = 15; hue_thumb.Parent = hue_rail
    Instance.new("UIStroke", hue_thumb).Color = Color3.new(0,0,0)

    local hex_box = Instance.new("TextBox")
    hex_box.Size = UDim2.new(1, -20, 0, 20); hex_box.Position = UDim2.fromOffset(10, 155)
    hex_box.BackgroundColor3 = C.input_bg; hex_box.TextColor3 = C.text; hex_box.Font = Enum.Font.Gotham
    hex_box.TextSize = 11; hex_box.ClearTextOnFocus = false; hex_box.ZIndex = 10; hex_box.Parent = drop
    Instance.new("UICorner", hex_box).CornerRadius = UDim.new(0,4)

    local function update_all()
        local color = Color3.fromHSV(h, s, v)
        display.BackgroundColor3 = color
        sv_map.BackgroundColor3 = Color3.fromHSV(h, 1, 1)
        hue_thumb.Position = UDim2.new(0.5, -12, h, -2)
        sv_thumb.Position = UDim2.new(s, -3, 1-v, -3)
        hex_box.Text = "#"..color:ToHex():upper()
        if on_change then on_change(color) end
    end

    local hue_drag, sv_drag = false, false
    hue_rail.InputBegan:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 then hue_drag = true end
    end)
    sv_map.InputBegan:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 then sv_drag = true end
    end)

    uis.InputChanged:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseMovement then
            if hue_drag then
                local y = math.clamp((inp.Position.Y - hue_rail.AbsolutePosition.Y) / hue_rail.AbsoluteSize.Y, 0, 1)
                h = y; update_all()
            elseif sv_drag then
                local x = math.clamp((inp.Position.X - sv_map.AbsolutePosition.X) / sv_map.AbsoluteSize.X, 0, 1)
                local y = 1 - math.clamp((inp.Position.Y - sv_map.AbsolutePosition.Y) / sv_map.AbsoluteSize.Y, 0, 1)
                s, v = x, y; update_all()
            end
        end
    end)
    uis.InputEnded:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 then hue_drag = false; sv_drag = false end
    end)

    hex_box.FocusLost:Connect(function()
        local ok, col = pcall(Color3.fromHex, hex_box.Text)
        if ok then h, s, v = col:ToHSV(); update_all() else update_all() end
    end)

    local detector = Instance.new("TextButton")
    detector.BackgroundTransparency = 1; detector.Text = ""; detector.Size = UDim2.fromScale(1,1)
    detector.ZIndex = 199; detector.Visible = false; detector.Parent = main

    local function close()
        drop.Visible = false
        detector.Visible = false
        if current_picker_close == close then current_picker_close = nil end
    end
    detector.MouseButton1Click:Connect(close)

    display.MouseButton1Click:Connect(function()
        if drop.Visible then
            close()
        else
            if current_picker_close then current_picker_close() end
            local abs_pos = display.AbsolutePosition
            drop.Position = UDim2.fromOffset(abs_pos.X - picker_w - 10, abs_pos.Y)
            drop.Visible = true; detector.Visible = true
            current_picker_close = close
        end
    end)

    update_all()
    return function(col) h, s, v = col:ToHSV(); update_all() end
end

local function make_colorpicker(parent, label, order, default_color, on_change)
    local row = make_row(parent, order, 34)
    local lbl = Instance.new("TextLabel")
    lbl.Font = Enum.Font.Gotham; lbl.Text = label; lbl.TextColor3 = C.text; lbl.TextSize = 13
    lbl.BackgroundTransparency = 1; lbl.BorderSizePixel = 0
    lbl.Position = UDim2.fromOffset(14, 0); lbl.Size = UDim2.new(1, -40, 1, 0)
    lbl.TextXAlignment = Enum.TextXAlignment.Left; lbl.Parent = row

    local display = Instance.new("TextButton")
    display.Text = ""; display.BackgroundColor3 = default_color
    display.Position = UDim2.new(1, -40, 0.5, -9); display.Size = UDim2.fromOffset(26, 18)
    display.AutoButtonColor = false; display.ZIndex = 5
    Instance.new("UICorner", display).CornerRadius = UDim.new(0, 4); display.Parent = row
    Instance.new("UIStroke", display).Color = Color3.fromRGB(50, 50, 60)

    return bind_colorpicker_popup(display, default_color, on_change)
end

-- -------------------- Toggle --------------------
local function make_toggle(parent, label, order, toggle_key)
    local row = make_row(parent, order)
    local lbl = Instance.new("TextLabel")
    lbl.Font=Enum.Font.Gotham; lbl.Text=label; lbl.TextColor3=C.text; lbl.TextSize=13
    lbl.BackgroundTransparency=1; lbl.BorderSizePixel=0
    lbl.Position=UDim2.fromOffset(14,0); lbl.Size=UDim2.new(1,-56,1,0)
    lbl.TextXAlignment=Enum.TextXAlignment.Left; lbl.Parent=row

    local pill=Instance.new("Frame")
    pill.BackgroundColor3=C.tog_off; pill.BorderSizePixel=0
    pill.Position=UDim2.new(1,-46,0.5,-9); pill.Size=UDim2.fromOffset(36,18)
    Instance.new("UICorner",pill).CornerRadius=UDim.new(1,0); pill.Parent=row

    local knob=Instance.new("Frame")
    knob.BackgroundColor3=Color3.new(1,1,1); knob.BorderSizePixel=0
    knob.Size=UDim2.fromOffset(12,12); knob.Position=UDim2.fromOffset(3,3)
    Instance.new("UICorner",knob).CornerRadius=UDim.new(1,0); knob.Parent=pill

    local state=false
    local function refresh()
        pill.BackgroundColor3=state and C.tog_on or C.tog_off
        knob.Position=state and UDim2.fromOffset(21,3) or UDim2.fromOffset(3,3)
    end

    local hit=Instance.new("TextButton")
    hit.BackgroundTransparency=1; hit.BorderSizePixel=0
    hit.Size=UDim2.fromScale(1,1); hit.Text=""; hit.Parent=row
    hit.MouseButton1Click:Connect(function()
        if _G[toggle_key] then _G[toggle_key]() end
    end)

    local set_key = "set_"..toggle_key:gsub("toggle_","")
    _G[set_key] = function(s) state=s; refresh() end
end

local function make_toggle_with_color(parent, label, order, toggle_key, default_color, on_color_change)
    local row = make_row(parent, order)
    local hit = Instance.new("TextButton")
    hit.BackgroundTransparency = 1; hit.BorderSizePixel = 0
    hit.Size = UDim2.fromScale(1, 1); hit.Text = ""; hit.ZIndex = 1; hit.Parent = row

    local lbl = Instance.new("TextLabel")
    lbl.Font = Enum.Font.Gotham; lbl.Text = label; lbl.TextColor3 = C.text; lbl.TextSize = 13
    lbl.BackgroundTransparency = 1; lbl.BorderSizePixel = 0; lbl.ZIndex = 2; lbl.Active = false
    lbl.Position = UDim2.fromOffset(14, 0); lbl.Size = UDim2.new(1, -118, 1, 0)
    lbl.TextXAlignment = Enum.TextXAlignment.Left; lbl.Parent = row

    local display = Instance.new("TextButton")
    display.Text = ""; display.BackgroundColor3 = default_color
    display.Position = UDim2.new(1, -80, 0.5, -9); display.Size = UDim2.fromOffset(26, 18)
    display.AutoButtonColor = false; display.ZIndex = 5
    Instance.new("UICorner", display).CornerRadius = UDim.new(0, 4); display.Parent = row
    Instance.new("UIStroke", display).Color = Color3.fromRGB(50, 50, 60)

    local pill = Instance.new("Frame")
    pill.BackgroundColor3 = C.tog_off; pill.BorderSizePixel = 0; pill.Active = false
    pill.Position = UDim2.new(1, -46, 0.5, -9); pill.Size = UDim2.fromOffset(36, 18); pill.ZIndex = 3
    Instance.new("UICorner", pill).CornerRadius = UDim.new(1, 0); pill.Parent = row

    local knob = Instance.new("Frame")
    knob.BackgroundColor3 = Color3.new(1, 1, 1); knob.BorderSizePixel = 0; knob.Active = false
    knob.Size = UDim2.fromOffset(12, 12); knob.Position = UDim2.fromOffset(3, 3); knob.ZIndex = 4
    Instance.new("UICorner", knob).CornerRadius = UDim.new(1, 0); knob.Parent = pill

    local state = false
    local function refresh()
        pill.BackgroundColor3 = state and C.tog_on or C.tog_off
        knob.Position = state and UDim2.fromOffset(21, 3) or UDim2.fromOffset(3, 3)
    end

    hit.MouseButton1Click:Connect(function()
        if _G[toggle_key] then _G[toggle_key]() end
    end)

    local set_key = "set_" .. toggle_key:gsub("toggle_", "")
    _G[set_key] = function(s) state = s; refresh() end

    return bind_colorpicker_popup(display, default_color, on_color_change)
end

local function make_toggle_with_two_colors(parent, label, order, toggle_key, def_a, on_a, def_b, on_b)
    local row = make_row(parent, order)
    local hit = Instance.new("TextButton")
    hit.BackgroundTransparency = 1; hit.BorderSizePixel = 0
    hit.Size = UDim2.fromScale(1, 1); hit.Text = ""; hit.ZIndex = 1; hit.Parent = row

    local lbl = Instance.new("TextLabel")
    lbl.Font = Enum.Font.Gotham; lbl.Text = label; lbl.TextColor3 = C.text; lbl.TextSize = 13
    lbl.BackgroundTransparency = 1; lbl.BorderSizePixel = 0; lbl.ZIndex = 2; lbl.Active = false
    lbl.Position = UDim2.fromOffset(14, 0); lbl.Size = UDim2.new(1, -154, 1, 0)
    lbl.TextXAlignment = Enum.TextXAlignment.Left; lbl.Parent = row

    local d1 = Instance.new("TextButton")
    d1.Text = ""; d1.BackgroundColor3 = def_a
    d1.Position = UDim2.new(1, -114, 0.5, -9); d1.Size = UDim2.fromOffset(26, 18)
    d1.AutoButtonColor = false; d1.ZIndex = 5
    Instance.new("UICorner", d1).CornerRadius = UDim.new(0, 4); d1.Parent = row
    Instance.new("UIStroke", d1).Color = Color3.fromRGB(50, 50, 60)

    local d2 = Instance.new("TextButton")
    d2.Text = ""; d2.BackgroundColor3 = def_b
    d2.Position = UDim2.new(1, -80, 0.5, -9); d2.Size = UDim2.fromOffset(26, 18)
    d2.AutoButtonColor = false; d2.ZIndex = 5
    Instance.new("UICorner", d2).CornerRadius = UDim.new(0, 4); d2.Parent = row
    Instance.new("UIStroke", d2).Color = Color3.fromRGB(50, 50, 60)

    local pill = Instance.new("Frame")
    pill.BackgroundColor3 = C.tog_off; pill.BorderSizePixel = 0; pill.Active = false
    pill.Position = UDim2.new(1, -46, 0.5, -9); pill.Size = UDim2.fromOffset(36, 18); pill.ZIndex = 3
    Instance.new("UICorner", pill).CornerRadius = UDim.new(1, 0); pill.Parent = row

    local knob = Instance.new("Frame")
    knob.BackgroundColor3 = Color3.new(1, 1, 1); knob.BorderSizePixel = 0; knob.Active = false
    knob.Size = UDim2.fromOffset(12, 12); knob.Position = UDim2.fromOffset(3, 3); knob.ZIndex = 4
    Instance.new("UICorner", knob).CornerRadius = UDim.new(1, 0); knob.Parent = pill

    local state = false
    local function refresh()
        pill.BackgroundColor3 = state and C.tog_on or C.tog_off
        knob.Position = state and UDim2.fromOffset(21, 3) or UDim2.fromOffset(3, 3)
    end

    hit.MouseButton1Click:Connect(function()
        if _G[toggle_key] then _G[toggle_key]() end
    end)

    local set_key = "set_" .. toggle_key:gsub("toggle_", "")
    _G[set_key] = function(s) state = s; refresh() end

    local upd_a = bind_colorpicker_popup(d1, def_a, on_a)
    local upd_b = bind_colorpicker_popup(d2, def_b, on_b)
    return upd_a, upd_b
end

-- -------------------- Slider --------------------
local function make_slider(parent, label, order, min_v, max_v, def, fmt, on_change)
    local row = make_row(parent, order, 48)

    local lbl=Instance.new("TextLabel")
    lbl.Font=Enum.Font.Gotham; lbl.TextColor3=C.text; lbl.TextSize=12
    lbl.BackgroundTransparency=1; lbl.BorderSizePixel=0
    lbl.Position=UDim2.fromOffset(14,4); lbl.Size=UDim2.new(1,-28,0,16)
    lbl.TextXAlignment=Enum.TextXAlignment.Left; lbl.Text=label; lbl.Parent=row

    local val_lbl=Instance.new("TextLabel")
    val_lbl.Font=Enum.Font.GothamSemibold; val_lbl.TextColor3=C.accent; val_lbl.TextSize=11
    val_lbl.BackgroundTransparency=1; val_lbl.BorderSizePixel=0
    val_lbl.Position=UDim2.fromOffset(14,4); val_lbl.Size=UDim2.new(1,-28,0,16)
    val_lbl.TextXAlignment=Enum.TextXAlignment.Right; val_lbl.Parent=row

    local track=Instance.new("Frame")
    track.BackgroundColor3=C.slid_bg; track.BorderSizePixel=0
    track.Position=UDim2.fromOffset(14,28); track.Size=UDim2.new(1,-28,0,6)
    Instance.new("UICorner",track).CornerRadius=UDim.new(1,0); track.Parent=row

    local fill=Instance.new("Frame")
    fill.BackgroundColor3=C.slid_fg; fill.BorderSizePixel=0; fill.Size=UDim2.fromScale(0,1)
    Instance.new("UICorner",fill).CornerRadius=UDim.new(1,0); fill.Parent=track

    local thumb=Instance.new("Frame")
    thumb.BackgroundColor3=Color3.new(1,1,1); thumb.BorderSizePixel=0
    thumb.Size=UDim2.fromOffset(12,12); thumb.Position=UDim2.new(0,-6,0.5,-6)
    Instance.new("UICorner",thumb).CornerRadius=UDim.new(1,0); thumb.Parent=track

    local cur=def; local dragging=false
    local function set_val(v)
        cur=math.clamp(v,min_v,max_v)
        local pct=(cur-min_v)/(max_v-min_v)
        fill.Size=UDim2.fromScale(pct,1); thumb.Position=UDim2.new(pct,-6,0.5,-6)
        val_lbl.Text=string.format(fmt or "%g",cur)
        if on_change then on_change(cur) end
    end
    set_val(def)

    local function from_x(x)
        local abs=track.AbsolutePosition; local sz=track.AbsoluteSize
        set_val(min_v+math.clamp((x-abs.X)/sz.X,0,1)*(max_v-min_v))
    end
    track.InputBegan:Connect(function(inp)
        if inp.UserInputType==Enum.UserInputType.MouseButton1 then dragging=true; from_x(inp.Position.X) end
    end)
    uis.InputChanged:Connect(function(inp)
        if dragging and inp.UserInputType==Enum.UserInputType.MouseMovement then from_x(inp.Position.X) end
    end)
    uis.InputEnded:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
    end)

    return set_val
end

-- -------------------- Keybind --------------------
local function make_keybind(parent, label, order, def_key, on_bind)
    local row=make_row(parent,order)
    local lbl=Instance.new("TextLabel")
    lbl.Font=Enum.Font.Gotham; lbl.Text=label; lbl.TextColor3=C.text; lbl.TextSize=13
    lbl.BackgroundTransparency=1; lbl.BorderSizePixel=0
    lbl.Position=UDim2.fromOffset(14,0); lbl.Size=UDim2.new(0.5,0,1,0)
    lbl.TextXAlignment=Enum.TextXAlignment.Left; lbl.Parent=row

    local bb=Instance.new("TextButton")
    bb.Font=Enum.Font.GothamSemibold; bb.TextSize=11; bb.TextColor3=C.text
    bb.BackgroundColor3=C.input_bg; bb.BorderSizePixel=0
    bb.Position=UDim2.new(0.5,0,0.5,-10); bb.Size=UDim2.new(0.44,0,0,20)
    Instance.new("UICorner",bb).CornerRadius=UDim.new(0,4); bb.Parent=row

    local cur=def_key; local listening=false
    local function key_label(k)
        if typeof(k)~="EnumItem" then return "[ ? ]" end
        if k.EnumType==Enum.UserInputType then
            if k==Enum.UserInputType.MouseButton1 then return "[ LMB ]" end
            if k==Enum.UserInputType.MouseButton2 then return "[ RMB ]" end
            if k==Enum.UserInputType.MouseButton3 then return "[ MMB ]" end
            return "[ "..k.Name.." ]"
        end
        return "[ "..k.Name:lower().." ]"
    end
    bb.Text=key_label(def_key)

    bb.MouseButton1Click:Connect(function()
        if listening then return end
        listening=true; bb.Text="[ ... ]"
        local c1,c2
        c1=uis.InputBegan:Connect(function(inp)
            local is_kb  = inp.UserInputType==Enum.UserInputType.Keyboard
            local is_mb1 = inp.UserInputType==Enum.UserInputType.MouseButton1
            local is_mb2 = inp.UserInputType==Enum.UserInputType.MouseButton2
            local is_mb3 = inp.UserInputType==Enum.UserInputType.MouseButton3
            if not(is_kb or is_mb1 or is_mb2 or is_mb3) then return end
            cur=is_kb and inp.KeyCode or inp.UserInputType
            c1:Disconnect(); c2:Disconnect(); listening=false; bb.Text=key_label(cur)
            if on_bind then on_bind(cur) end
        end)
        c2=uis.InputBegan:Connect(function(inp)
            if inp.KeyCode==Enum.KeyCode.Escape then
                c1:Disconnect(); c2:Disconnect(); listening=false; bb.Text=key_label(cur)
            end
        end)
    end)
    return bb, function(k) cur=k; bb.Text=key_label(k) end
end


-- ================================================================
--                     COMBAT TAB
-- ================================================================

-- ---- Combat > Aim Assist ----
local pg = all_sub_pages["Combat"]["Aim Assist"]
section_label(pg, "Aim Assist", 1)
make_toggle(pg, "Aim Assist",       2,  "toggle_aim_assist")
local upd_col_fov = make_toggle_with_color(pg, "Show FOV", 3, "toggle_show_fov", Color3.new(1, 1, 1),
    function(c) if _G.set_color_fov then _G.set_color_fov(c) end end)
make_toggle(pg, "Visibility Check", 4,  "toggle_vis_check")

local aim_fov_set   = make_slider(pg, "FOV Radius",  5, 20, 400, 120, "%d px",
    function(v) if _G.set_aim_fov_value   then _G.set_aim_fov_value(v)     end end)
local aim_speed_set = make_slider(pg, "Smoothness",  6,  0, 100,  25, "%d %%",
    function(v) if _G.set_aim_speed_value then _G.set_aim_speed_value(v/100) end end)

local aim_key_btn, aim_key_update = make_keybind(pg, "Aim Key", 7, Enum.UserInputType.MouseButton2,
    function(k) if _G.set_aim_key_value then _G.set_aim_key_value(k) end end)

-- ---- Combat > Silent Aim ----
pg = all_sub_pages["Combat"]["Silent Aim"]
section_label(pg, "Silent Aim", 1)
make_toggle(pg, "Silent Aim",       2,  "toggle_silent_aim")
local upd_col_sfov = make_toggle_with_color(pg, "Show Silent FOV", 3, "toggle_show_silent_fov", Color3.fromRGB(230, 120, 175),
    function(c) if _G.set_color_silent_fov then _G.set_color_silent_fov(c) end end)

local silent_fov_set = make_slider(pg, "Silent FOV Radius", 4, 10, 300, 80, "%d px",
    function(v) if _G.set_silent_aim_fov_value then _G.set_silent_aim_fov_value(v) end end)

local silent_aim_key_btn, silent_aim_key_update = make_keybind(pg, "Silent Aim Key", 5, Enum.UserInputType.MouseButton2,
    function(k) if _G.set_silent_aim_key_value then _G.set_silent_aim_key_value(k) end end)

section_label(pg, "Targeting", 6)
local tgt_row = make_row(pg, 7)
local tgt_lbl = Instance.new("TextLabel")
tgt_lbl.Font = Enum.Font.Gotham; tgt_lbl.Text = "Silent target mode"; tgt_lbl.TextColor3 = C.text; tgt_lbl.TextSize = 13
tgt_lbl.BackgroundTransparency = 1; tgt_lbl.Position = UDim2.fromOffset(14, 0); tgt_lbl.Size = UDim2.new(0.55, 0, 1, 0)
tgt_lbl.TextXAlignment = Enum.TextXAlignment.Left; tgt_lbl.Parent = tgt_row
local function silent_mode_label(m)
    if m == "esp" then return "ESP (bones)" end
    if m == "viewmodels" then return "Viewmodels (mouse)" end
    return "Hybrid"
end
local tgt_mode_btn = Instance.new("TextButton")
tgt_mode_btn.Font = Enum.Font.GothamSemibold; tgt_mode_btn.TextSize = 11; tgt_mode_btn.TextColor3 = C.text
tgt_mode_btn.BackgroundColor3 = C.input_bg; tgt_mode_btn.BorderSizePixel = 0
tgt_mode_btn.Position = UDim2.new(0.56, 0, 0.5, -10); tgt_mode_btn.Size = UDim2.new(0.4, -14, 0, 22)
tgt_mode_btn.AutoButtonColor = false; tgt_mode_btn.Parent = tgt_row
Instance.new("UICorner", tgt_mode_btn).CornerRadius = UDim.new(0, 4)
tgt_mode_btn.MouseButton1Click:Connect(function()
    if _G.cycle_silent_target_mode then _G.cycle_silent_target_mode() end
end)
_G.set_silent_target_mode_ui = function(m)
    tgt_mode_btn.Text = silent_mode_label(m)
end
if _G.get_silent_target_mode then
    tgt_mode_btn.Text = silent_mode_label(_G.get_silent_target_mode())
end

-- ---- Combat > Weapons ----
pg = all_sub_pages["Combat"]["Weapons"]
section_label(pg, "Weapons", 1)
make_toggle(pg, "No Recoil",        2,  "toggle_no_recoil")
make_toggle(pg, "No Spread",        3,  "toggle_no_spread")
make_toggle(pg, "Run And Shoot",    4,  "toggle_run_and_shoot")

local recoil_v_set = make_slider(pg, "Recoil vertical %", 5, 0, 100, 0, "%d %%",
    function(v) if _G.set_recoil_vertical_pct then _G.set_recoil_vertical_pct(v) end end)
local recoil_h_set = make_slider(pg, "Recoil horizontal %", 6, 0, 100, 0, "%d %%",
    function(v) if _G.set_recoil_horizontal_pct then _G.set_recoil_horizontal_pct(v) end end)

_G.sync_recoil_sliders_from_state = function(v_pct, h_pct)
    if v_pct ~= nil then recoil_v_set(tonumber(v_pct) or 0) end
    if h_pct ~= nil then recoil_h_set(tonumber(h_pct) or 0) end
end


-- Expose slider updaters for config load
_G.set_aim_fov   = function(v) aim_fov_set(v)        end
_G.set_aim_speed = function(v) aim_speed_set(v*100)   end
_G.set_silent_aim_fov = function(v) silent_fov_set(v) end

-- Keybind updaters for config load
_G.ui_set_aim_key = function(k) aim_key_update(k) end
_G.ui_set_silent_aim_key = function(k) silent_aim_key_update(k) end


-- ================================================================
--                     MOVEMENT TAB
-- ================================================================

-- ---- Movement > Fly ----
pg = all_sub_pages["Movement"]["Fly"]
section_label(pg, "Fly", 1)
make_toggle(pg, "Fly",  2,  "toggle_fly")

local fly_speed_set = make_slider(pg, "Fly Speed", 3, 10, 200, 50, "%d studs/s",
    function(v) if _G.set_fly_speed_value then _G.set_fly_speed_value(v) end end)

-- ---- Movement > Jump Boost ----
pg = all_sub_pages["Movement"]["Jump Boost"]
section_label(pg, "Jump Boost", 1)
make_toggle(pg, "Jump Boost",  2,  "toggle_jump_boost")

local jump_power_set = make_slider(pg, "Jump Power", 3, 20, 200, 80, "%d",
    function(v) if _G.set_jump_power_value then _G.set_jump_power_value(v) end end)

_G.set_fly_speed  = function(v) fly_speed_set(v)  end
_G.set_jump_power = function(v) jump_power_set(v)  end


-- ================================================================
--                     VISUALS TAB
-- ================================================================

-- ---- Visuals > Player ESP ----
pg = all_sub_pages["Visuals"]["Player ESP"]
section_label(pg, "Player ESP", 1)
local upd_col_box = make_toggle_with_color(pg, "Boxes", 2, "toggle_boxes", Color3.new(1, 1, 1),
    function(c) if _G.set_color_box then _G.set_color_box(c) end end)
local upd_col_skel_vis, upd_col_skel_hid = make_toggle_with_two_colors(pg, "Skeleton", 3, "toggle_skeletons",
    Color3.fromRGB(0, 255, 0), function(c) if _G.set_color_skel_vis then _G.set_color_skel_vis(c) end end,
    Color3.new(1, 1, 1), function(c) if _G.set_color_skel_hid then _G.set_color_skel_hid(c) end end)
local upd_col_tracer = make_toggle_with_color(pg, "Tracers", 4, "toggle_tracers", Color3.new(1, 1, 1),
    function(c) if _G.set_color_tracer then _G.set_color_tracer(c) end end)
make_toggle(pg, "Health Bars",  5,  "toggle_healthbars")
make_toggle(pg, "Names",        6,  "toggle_names")
make_toggle(pg, "Team Check",   7,  "toggle_team_check")
local upd_col_chams = make_toggle_with_color(pg, "Chams", 8, "toggle_chams", Color3.fromRGB(255, 50, 50),
    function(c) if _G.set_color_chams then _G.set_color_chams(c) end end)

-- ---- Visuals > Gadgets ----
pg = all_sub_pages["Visuals"]["Gadgets"]
section_label(pg, "Gadgets", 1)
make_toggle(pg, "Gadgets",      2,  "toggle_gadgets")
local upd_col_throw = make_colorpicker(pg, "Throwable", 3, Color3.fromRGB(255, 60, 60),
    function(c) if _G.set_color_throwable then _G.set_color_throwable(c) end end)
local upd_col_place = make_colorpicker(pg, "Placeable", 4, Color3.fromRGB(255, 170, 0),
    function(c) if _G.set_color_placeable then _G.set_color_placeable(c) end end)

-- ---- Visuals > World ----
pg = all_sub_pages["Visuals"]["World"]
section_label(pg, "World", 1)
make_toggle(pg, "Fullbright",   2,  "toggle_fullbright")


-- ================================================================
--                     MISC TAB (no sub-pages)
-- ================================================================
local misc_page = Instance.new("ScrollingFrame")
misc_page.BackgroundTransparency=1; misc_page.BorderSizePixel=0
misc_page.Size=UDim2.fromScale(1,1); misc_page.CanvasSize=UDim2.fromOffset(0,0)
misc_page.AutomaticCanvasSize=Enum.AutomaticSize.Y; misc_page.ScrollBarThickness=3
misc_page.ScrollBarImageColor3=C.accent; misc_page.Visible=true; misc_page.Parent=tab_containers["Misc"]
local ul=Instance.new("UIListLayout"); ul.SortOrder=Enum.SortOrder.LayoutOrder; ul.Padding=UDim.new(0,0); ul.Parent=misc_page
local up=Instance.new("UIPadding"); up.PaddingTop=UDim.new(0,6); up.Parent=misc_page

section_label(misc_page, "Interface", 1)
local _, menu_key_update = make_keybind(misc_page, "Menu Bind", 2, Enum.KeyCode.Insert,
    function(k) _G.new_menu_key = k end)
_G.ui_set_menu_key = function(k) menu_key_update(k) end

section_label(misc_page, "Script", 10)
make_toggle(misc_page, "Unload Script", 11, "unload_mya")


-- ================================================================
--                     CONFIGS TAB (no sub-pages)
-- ================================================================
local cfg_page = Instance.new("Frame")
cfg_page.BackgroundTransparency=1; cfg_page.Size=UDim2.fromScale(1,1)
cfg_page.Visible=true; cfg_page.Parent=tab_containers["Configs"]

local function sync_ui_from_config(cfg)
    if cfg.aim_fov ~= nil        and _G.set_aim_fov        then _G.set_aim_fov(cfg.aim_fov)               end
    if cfg.aim_speed ~= nil      and _G.set_aim_speed      then _G.set_aim_speed(cfg.aim_speed)           end
    if cfg.silent_aim_fov ~= nil and _G.set_silent_aim_fov then _G.set_silent_aim_fov(cfg.silent_aim_fov) end
    if cfg.fly_speed      ~= nil and _G.set_fly_speed      then _G.set_fly_speed(cfg.fly_speed)           end
    if cfg.jump_power     ~= nil and _G.set_jump_power     then _G.set_jump_power(cfg.jump_power)         end
    if cfg.silent_target_mode ~= nil and _G.set_silent_target_mode then _G.set_silent_target_mode(cfg.silent_target_mode) end
    if cfg.recoil_vertical_pct   ~= nil or cfg.recoil_horizontal_pct ~= nil then
        if _G.sync_recoil_sliders_from_state then
            _G.sync_recoil_sliders_from_state(cfg.recoil_vertical_pct, cfg.recoil_horizontal_pct)
        end
    end
    local function str_to_enum_local(s)
        if not s then return nil end
        local et,en=s:match("^(.+)%.(.+)$"); if not et then return nil end
        local ok,r=pcall(function() return Enum[et][en] end); return ok and r or nil
    end
    local ak=str_to_enum_local(cfg.aim_key);  if ak then aim_key_update(ak)  end
    local sak=str_to_enum_local(cfg.silent_aim_key); if sak then silent_aim_key_update(sak) end
    local mk=str_to_enum_local(cfg.menu_key); if mk then menu_key_update(mk) end
    local function tc(t) if not t then return nil end return Color3.new(t.r or 1,t.g or 1,t.b or 1) end
    local c_box   =tc(cfg.color_box);        if c_box      then upd_col_box(c_box)           end
    local c_tr    =tc(cfg.color_tracer);     if c_tr       then upd_col_tracer(c_tr)          end
    local c_sv    =tc(cfg.color_skel_vis);   if c_sv       then upd_col_skel_vis(c_sv)        end
    local c_sh    =tc(cfg.color_skel_hid);   if c_sh       then upd_col_skel_hid(c_sh)        end
    local c_ch    =tc(cfg.color_chams);      if c_ch       then upd_col_chams(c_ch)           end
    local c_fov   =tc(cfg.color_fov);        if c_fov      then upd_col_fov(c_fov)            end
    local c_sfov  =tc(cfg.color_silent_fov); if c_sfov     then upd_col_sfov(c_sfov)          end
    local c_th    =tc(cfg.color_throwable);  if c_th       then upd_col_throw(c_th)           end
    local c_pl    =tc(cfg.color_placeable);  if c_pl       then upd_col_place(c_pl)           end
end

local cfg_top = Instance.new("Frame", cfg_page)
cfg_top.BackgroundTransparency = 1; cfg_top.Size = UDim2.new(1, -12, 0, 30)
cfg_top.Position = UDim2.fromOffset(6, 4)

local cfg_title = Instance.new("TextLabel", cfg_top)
cfg_title.Font = Enum.Font.GothamBold; cfg_title.Text = "Config Manager"
cfg_title.TextColor3 = C.accent; cfg_title.TextSize = 12
cfg_title.BackgroundTransparency = 1; cfg_title.Size = UDim2.new(0.5, 0, 1, 0)
cfg_title.TextXAlignment = Enum.TextXAlignment.Left


local list_scroller = Instance.new("ScrollingFrame")
list_scroller.Size = UDim2.new(1, 0, 1, -95); list_scroller.Position = UDim2.fromOffset(0, 38)
list_scroller.BackgroundTransparency = 1; list_scroller.BorderSizePixel = 0; list_scroller.Parent = cfg_page
list_scroller.ScrollBarThickness = 2; list_scroller.ScrollBarImageColor3 = C.accent
local lay = Instance.new("UIListLayout", list_scroller)
lay.Padding = UDim.new(0, 6)
lay.HorizontalAlignment = Enum.HorizontalAlignment.Center
Instance.new("UIPadding", list_scroller).PaddingTop = UDim.new(0, 2)
list_scroller.CanvasSize = UDim2.new(0,0,0,0); list_scroller.AutomaticCanvasSize = Enum.AutomaticSize.Y

local function refresh_configs()
    for _, c in ipairs(list_scroller:GetChildren()) do if c:IsA("Frame") then c:Destroy() end end
    local files = {}
    pcall(function()
        ensure_config_dir()
        if listfiles then files = listfiles(CONFIG_FOLDER) end
    end)

    local function make_card(name)
        local card = Instance.new("Frame")
        card.BackgroundColor3 = C.panel
        card.Size = UDim2.new(1, -12, 0, 60); card.Parent = list_scroller
        card.LayoutOrder = 0
        Instance.new("UICorner", card).CornerRadius = UDim.new(0, 6)
        local stroke = Instance.new("UIStroke", card)
        stroke.Color = Color3.fromRGB(40, 40, 55)
        stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border

        card.MouseEnter:Connect(function() stroke.Color = C.accent end)
        card.MouseLeave:Connect(function() stroke.Color = Color3.fromRGB(40, 40, 55) end)

        local lbl = Instance.new("TextLabel")
        lbl.Font = Enum.Font.GothamMedium
        lbl.Text = "  "..name; lbl.TextColor3 = C.text; lbl.TextSize = 13
        lbl.BackgroundTransparency = 1; lbl.Size = UDim2.new(0.5, 0, 1, 0); lbl.TextXAlignment = Enum.TextXAlignment.Left; lbl.Parent = card

        local btn_row = Instance.new("Frame")
        btn_row.BackgroundTransparency = 1; btn_row.Size = UDim2.new(0.5, 0, 1, 0); btn_row.Position = UDim2.fromScale(0.5, 0); btn_row.Parent = card
        local bl = Instance.new("UIListLayout", btn_row); bl.FillDirection = Enum.FillDirection.Horizontal; bl.HorizontalAlignment = Enum.HorizontalAlignment.Right; bl.VerticalAlignment = Enum.VerticalAlignment.Center; bl.Padding = UDim.new(0, 8)
        Instance.new("UIPadding", btn_row).PaddingRight = UDim.new(0, 10)

        local function b(txt, col, cb)
            local btn = Instance.new("TextButton")
            btn.BackgroundColor3 = C.bg; btn.Text = txt; btn.Font = Enum.Font.GothamBold; btn.TextSize = 10; btn.TextColor3 = col; btn.Size = UDim2.fromOffset(45, 28); btn.Parent = btn_row
            Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 4)
            local s = Instance.new("UIStroke", btn); s.Color = col; s.Transparency = 0.3
            btn.MouseEnter:Connect(function() btn.BackgroundColor3 = col; btn.TextColor3 = Color3.new(1,1,1); s.Transparency = 0 end)
            btn.MouseLeave:Connect(function() btn.BackgroundColor3 = C.bg; btn.TextColor3 = col; s.Transparency = 0.3 end)
            btn.MouseButton1Click:Connect(cb)
        end

        local safe_path = CONFIG_FOLDER .. "/" .. name .. ".json"
        
        b("LOAD", C.accent, function()
            local ok, err = pcall(function()
                ensure_config_dir()
                local raw = readfile(safe_path)
                local cfg = http:JSONDecode(raw)
                if _G.apply_config then _G.apply_config(cfg) end
                sync_ui_from_config(cfg)
                notify("Config Loaded", "Successfully loaded " .. name .. ".", 3)
            end)
            if not ok then warn("[Mya] LOAD failed for " .. safe_path .. " | Error: " .. tostring(err)) end
        end)
        
        b("SAVE", C.green, function()
            local ok, err = pcall(function()
                ensure_config_dir()
                local gc = _G.get_config
                if not gc then return end
                writefile(safe_path, http:JSONEncode(gc()))
                refresh_configs()
                notify("Config Saved", "Successfully saved " .. name .. ".", 3)
            end)
            if not ok then warn("[Mya] SAVE failed for " .. safe_path .. " | Error: " .. tostring(err)) end
        end)
        
        b("X", C.red, function() 
            local ok = pcall(delfile, safe_path); 
            refresh_configs() 
            if ok then notify("Config Deleted", "Successfully deleted " .. name .. ".", 3) end
        end)
    end

    for _, p in ipairs(files) do
        local n = p:match("([^\\/]+)%.json$")
        if n then make_card(n) end
    end
end

local footer = Instance.new("Frame")
footer.BackgroundColor3 = C.panel; footer.BorderSizePixel = 0
footer.Size = UDim2.new(1, -12, 0, 44); footer.Position = UDim2.new(0, 6, 1, -50); footer.Parent = cfg_page
Instance.new("UICorner", footer).CornerRadius = UDim.new(0, 6)
local f_stroke = Instance.new("UIStroke", footer); f_stroke.Color = C.accent; f_stroke.Transparency = 0.5

local cin = Instance.new("TextBox")
cin.Font = Enum.Font.Gotham; cin.PlaceholderText = "Type new config name..."
cin.PlaceholderColor3 = C.dim; cin.Text = ""; cin.TextColor3 = C.text; cin.TextSize = 13
cin.BackgroundTransparency = 1; cin.Position = UDim2.fromOffset(12, 0)
cin.Size = UDim2.new(1, -95, 1, 0); cin.TextXAlignment = Enum.TextXAlignment.Left; cin.Parent = footer

local sbtn = Instance.new("TextButton")
sbtn.BackgroundColor3 = C.accent; sbtn.Text = "CREATE"; sbtn.Font = Enum.Font.GothamBold
sbtn.TextSize = 11; sbtn.TextColor3 = Color3.new(1,1,1)
sbtn.Size = UDim2.fromOffset(75, 30); sbtn.Position = UDim2.new(1, -82, 0.5, -15); sbtn.Parent = footer
Instance.new("UICorner", sbtn).CornerRadius = UDim.new(0, 4)

sbtn.MouseButton1Click:Connect(function()
    local n = cin.Text:gsub("^%s+", ""):gsub("%s+$", "")
    if n == "" then return end
    
    local ok, err = pcall(function()
        ensure_config_dir()
        local gc = _G.get_config
        if not gc then error("_G.get_config is nil") end
        local cfg_data = gc()
        local json_data = http:JSONEncode(cfg_data)
        writefile(CONFIG_FOLDER .. "/" .. n .. ".json", json_data)
    end)
    
    if not ok then
        warn("[Mya] CREATE failed for " .. n .. " | Error: " .. tostring(err))
        sbtn.Text = "ERROR"
        task.delay(2, function() sbtn.Text = "CREATE" end)
    else
        cin.Text = ""
        sbtn.Text = "CREATED"
        task.delay(1.5, function() sbtn.Text = "CREATE" end)
        refresh_configs()
        notify("Config Created", "Successfully created " .. n .. ".", 3)
    end
end)

refresh_configs()

-- -------------------- Drag Logic --------------------
local drag_con
header.InputBegan:Connect(function(inp)
    if inp.UserInputType == Enum.UserInputType.MouseButton1 then
        local st, sp = inp.Position, main.Position
        drag_con = uis.InputChanged:Connect(function(i)
            if i.UserInputType == Enum.UserInputType.MouseMovement then
                local d = i.Position - st
                main.Position = UDim2.new(sp.X.Scale, sp.X.Offset + d.X, sp.Y.Scale, sp.Y.Offset + d.Y)
            end
        end)
    end
end)
header.InputEnded:Connect(function(inp)
    if inp.UserInputType == Enum.UserInputType.MouseButton1 then if drag_con then drag_con:Disconnect() end end
end)

switch_tab("Combat")
_G.user_interface = ui
notify("Mya", "Operation One · UI ready. Insert to toggle.", 4)
