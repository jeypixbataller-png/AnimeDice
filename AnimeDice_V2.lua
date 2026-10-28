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
    if lastText == "" then status.Text = "Scan first to generate results." return end
    if type(setclipboard) == "function" then
        local ok = pcall(function() setclipboard(lastText) end)
        status.Text = ok and "Results copied to clipboard." or "Clipboard failed; read the rows instead."
    else
        status.Text = "Clipboard unavailable; read the results on screen."
    end
end)

print("Anime Dice Inspector V2 loaded")
