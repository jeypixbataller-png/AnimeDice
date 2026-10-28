-- Anime Dice V2 | Read-only Stat Inspector for Delta
-- Does not modify game values or server-side rolls.
local Players = game:GetService("Players")
local player = Players.LocalPlayer
if not player then return end
local pg = player:WaitForChild("PlayerGui", 15)
if not pg then warn("PlayerGui not available") return end

local old = pg:FindFirstChild("AnimeDiceInspectorV2")
if old then old:Destroy() end
local gui = Instance.new("ScreenGui")
gui.Name = "AnimeDiceInspectorV2"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.DisplayOrder = 10000
gui.Parent = pg

local function style(obj, color, radius)
    obj.BackgroundColor3 = color
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, radius or 8)
    c.Parent = obj
end
local frame = Instance.new("Frame")
frame.Name = "Panel"
frame.Size = UDim2.fromOffset(350, 440)
frame.Position = UDim2.new(0.5, -175, 0.5, -220)
frame.Active = true
frame.Draggable = true
style(frame, Color3.fromRGB(27, 24, 43), 12)
frame.Parent = gui

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -55, 0, 38)
title.Position = UDim2.fromOffset(12, 5)
title.BackgroundTransparency = 1
title.Text = "ANIME DICE | INSPECTOR V2"
title.TextColor3 = Color3.new(1, 1, 1)
title.TextSize = 16
title.Font = Enum.Font.GothamBold
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = frame

local close = Instance.new("TextButton")
close.Size = UDim2.fromOffset(34, 30)
close.Position = UDim2.new(1, -42, 0, 8)
close.Text = "X"
close.TextSize = 18
close.TextColor3 = Color3.new(1,1,1)
style(close, Color3.fromRGB(125, 50, 78), 7)
close.Parent = frame
close.MouseButton1Click:Connect(function() gui:Destroy() end)

local filter = Instance.new("TextBox")
filter.Size = UDim2.new(1, -24, 0, 36)
filter.Position = UDim2.fromOffset(12, 49)
filter.Text = "trait,grade,quirk,luck,damage,roll"
filter.PlaceholderText = "Comma-separated keywords"
filter.ClearTextOnFocus = false
filter.TextSize = 14
filter.TextColor3 = Color3.new(1,1,1)
style(filter, Color3.fromRGB(58, 51, 85), 7)
filter.Parent = frame

local scan = Instance.new("TextButton")
scan.Size = UDim2.new(0.5, -18, 0, 36)
scan.Position = UDim2.fromOffset(12, 93)
scan.Text = "SCAN PLAYER"
scan.TextSize = 14
scan.TextColor3 = Color3.new(1,1,1)
style(scan, Color3.fromRGB(87, 69, 151), 7)
scan.Parent = frame
local copy = Instance.new("TextButton")
copy.Size = UDim2.new(0.5, -18, 0, 36)
copy.Position = UDim2.new(0.5, 6, 0, 93)
copy.Text = "COPY RESULTS"
copy.TextSize = 14
copy.TextColor3 = Color3.new(1,1,1)
style(copy, Color3.fromRGB(87, 69, 151), 7)
copy.Parent = frame

local status = Instance.new("TextLabel")
status.Size = UDim2.new(1, -24, 0, 40)
status.Position = UDim2.fromOffset(12, 133)
status.BackgroundTransparency = 1
status.Text = "Ready. Read-only scan; no stat changes."
status.TextColor3 = Color3.fromRGB(210, 202, 231)
status.TextSize = 12
status.TextWrapped = true
status.TextXAlignment = Enum.TextXAlignment.Left
status.Parent = frame

local scroll = Instance.new("ScrollingFrame")
scroll.Size = UDim2.new(1, -24, 1, -185)
scroll.Position = UDim2.fromOffset(12, 175)
scroll.ScrollBarThickness = 6
scroll.CanvasSize = UDim2.fromOffset(0, 0)
scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
style(scroll, Color3.fromRGB(39, 35, 60), 8)
scroll.Parent = frame
local layout = Instance.new("UIListLayout")
layout.Padding = UDim.new(0, 5)
layout.SortOrder = Enum.SortOrder.LayoutOrder
layout.Parent = scroll
local padding = Instance.new("UIPadding")
padding.PaddingTop = UDim.new(0, 7)
padding.PaddingLeft = UDim.new(0, 7)
padding.PaddingRight = UDim.new(0, 7)
padding.PaddingBottom = UDim.new(0, 7)
padding.Parent = scroll

local lastText = ""
local function safeValue(v)
    local s = tostring(v)
    if #s > 100 then s = s:sub(1,100) .. "..." end
    return s
end
local function keywords()
    local out = {}
    for s in filter.Text:lower():gmatch("[^,]+") do
        local t = s:match("^%s*(.-)%s*$")
        if #t > 0 then table.insert(out, t) end
    end
    return out
end
local function matches(s, words)
    s = s:lower()
    for _, w in ipairs(words) do
        if s:find(w, 1, true) then return true end
    end
    return false
end
local function clearRows()
    for _, child in ipairs(scroll:GetChildren()) do
        if child:IsA("TextLabel") then child:Destroy() end
    end
end
local function addRow(s)
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -8, 0, 0)
    label.AutomaticSize = Enum.AutomaticSize.Y
    label.BackgroundColor3 = Color3.fromRGB(54, 48, 76)
    label.TextColor3 = Color3.new(1,1,1)
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.TextYAlignment = Enum.TextYAlignment.Top
    label.TextWrapped = true
    label.TextSize = 12
    label.Font = Enum.Font.Code
    label.Text = s
    local pad = Instance.new("UIPadding")
    pad.PaddingTop = UDim.new(0, 6)
    pad.PaddingBottom = UDim.new(0, 6)
    pad.PaddingLeft = UDim.new(0, 6)
    pad.PaddingRight = UDim.new(0, 6)
    pad.Parent = label
    label.Parent = scroll
end

scan.MouseButton1Click:Connect(function()
    status.Text = "Scanning..."
    clearRows()
    local words = keywords()
    if #words == 0 then status.Text = "Enter at least one keyword." return end
    local lines, total, displayed = {}, 0, 0
    local maxRows = 120
    local function record(text)
        total += 1
        table.insert(lines, text)
        if displayed < maxRows then
            addRow(text)
            displayed += 1
        end
    end
    local objects = {player}
    for _, obj in ipairs(player:GetDescendants()) do
        table.insert(objects, obj)
    end
    for _, obj in ipairs(objects) do
        local ok, path = pcall(function() return obj:GetFullName() end)
        path = ok and path or obj.Name
        if matches(obj.Name, words) then
            local info = "[OBJECT] " .. path .. "\nType: " .. obj.ClassName
            if obj:IsA("ValueBase") then
                local success, value = pcall(function() return obj.Value end)
                if success then info = info .. " | Value: " .. safeValue(value) end
            elseif obj:IsA("TextLabel") or obj:IsA("TextButton") or obj:IsA("TextBox") then
                info = info .. " | Text: " .. safeValue(obj.Text)
            end
            record(info)
        end
        for name, value in pairs(obj:GetAttributes()) do
            if matches(name, words) then
                record("[ATTRIBUTE] " .. path .. "\n" .. name .. " = " .. safeValue(value) .. " (" .. typeof(value) .. ")")
            end
        end
    end
    lastText = table.concat(lines, "\n\n")
    status.Text = "Found " .. total .. " matches. Showing " .. displayed .. ". Values are read-only."
    if total == 0 then addRow("No matching player objects or attributes found.") end
end)

copy.MouseButton1Click:Connect(function()
    if lastText == "" then
        status.Text = "Scan first!"
        return
    end

    local clipboard =
        setclipboard
        or toclipboard
        or (syn and syn.write_clipboard)

    if type(clipboard) == "function" then
        local ok, err = pcall(function()
            clipboard(lastText)
        end)

        if ok then
            status.Text = "Copy requested! Check clipboard."
        else
            status.Text = "Copy failed: " .. tostring(err)
        end
    else
        status.Text = "Clipboard API unavailable"
    end
end)

print("Anime Dice Inspector V2 loaded")
