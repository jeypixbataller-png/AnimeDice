-- Anime Dice | Delta Client Stat Panel
-- Local diagnostic and value editor; does not alter server-authoritative rolls.
local Players = game:GetService('Players')
local player = Players.LocalPlayer
if not player then return end
local pg = player:WaitForChild('PlayerGui', 15)
if not pg then warn('PlayerGui unavailable') return end
local previous = pg:FindFirstChild('AnimeDiceClientPanel')
if previous then previous:Destroy() end
local gui = Instance.new('ScreenGui')
gui.Name = 'AnimeDiceClientPanel'
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.DisplayOrder = 9999
gui.Parent = pg
local function new(class, props, parent)
    local object = Instance.new(class)
    for key, value in pairs(props) do object[key] = value end
    object.Parent = parent
    return object
end
local panel = new('Frame', {Size=UDim2.fromOffset(310,390),Position=UDim2.new(.5,-155,.5,-195),BackgroundColor3=Color3.fromRGB(29,27,47),Active=true,Draggable=true},gui)
new('UICorner',{CornerRadius=UDim.new(0,12)},panel)
new('UIStroke',{Color=Color3.fromRGB(110,90,170),Thickness=1},panel)
local header = new('TextLabel',{Size=UDim2.new(1,-45,0,40),Position=UDim2.fromOffset(12,5),BackgroundTransparency=1,Text='ANIME DICE | STAT PANEL',TextColor3=Color3.new(1,1,1),TextSize=17,Font=Enum.Font.GothamBold,TextXAlignment=Enum.TextXAlignment.Left},panel)
local close = new('TextButton',{Size=UDim2.fromOffset(30,30),Position=UDim2.new(1,-36,0,9),Text='X',TextSize=17,TextColor3=Color3.new(1,1,1),BackgroundColor3=Color3.fromRGB(110,45,70)},panel)
new('UICorner',{CornerRadius=UDim.new(0,7)},close)
close.MouseButton1Click:Connect(function() gui:Destroy() end)
local status = new('TextLabel',{Size=UDim2.new(1,-20,0,48),Position=UDim2.fromOffset(10,332),BackgroundColor3=Color3.fromRGB(42,40,63),TextColor3=Color3.fromRGB(210,230,220),TextWrapped=true,TextSize=12,Text='Ready. Scan to find local values; server stats are not changed.'},panel)
new('UICorner',{CornerRadius=UDim.new(0,7)},status)
local keywords={'Trait','Grade','Quirk','Luck','Damage'}
local inputs={}
local function button(text,x,y,w,callback)
    local b=new('TextButton',{Size=UDim2.fromOffset(w,32),Position=UDim2.fromOffset(x,y),Text=text,TextSize=13,Font=Enum.Font.GothamBold,TextColor3=Color3.new(1,1,1),BackgroundColor3=Color3.fromRGB(86,65,147)},panel)
    new('UICorner',{CornerRadius=UDim.new(0,7)},b)
    b.MouseButton1Click:Connect(callback)
    return b
end
for i,name in ipairs(keywords) do
    local y=49+(i-1)*45
    new('TextLabel',{Size=UDim2.fromOffset(83,34),Position=UDim2.fromOffset(12,y),Text=name,TextSize=13,TextColor3=Color3.new(1,1,1),BackgroundTransparency=1,TextXAlignment=Enum.TextXAlignment.Left},panel)
    local input=new('TextBox',{Size=UDim2.fromOffset(126,33),Position=UDim2.fromOffset(94,y),Text='999999',PlaceholderText='number',ClearTextOnFocus=false,TextSize=14,TextColor3=Color3.new(1,1,1),BackgroundColor3=Color3.fromRGB(49,47,74)},panel)
    new('UICorner',{CornerRadius=UDim.new(0,6)},input)
    inputs[name]=input
    button('APPLY',228,y,70,function()
        local number=tonumber(input.Text)
        if not number or number <= 0 or number ~= number then status.Text='Enter a positive number for '..name return end
        local found,updated=0,0
        local function test(obj)
            if obj.Name:lower():find(name:lower(),1,true) and (obj:IsA('NumberValue') or obj:IsA('IntValue')) then
                found=found+1
                local ok=pcall(function() obj.Value=number end)
                if ok then updated=updated+1 end
            end
        end
        test(player)
        for _,obj in ipairs(player:GetDescendants()) do test(obj) end
        status.Text=name..': '..updated..' local values written ('..found..' matched). Server effect unverified.'
    end)
end
button('MAX ALL (LOCAL)',12,283,139,function()
    local total=0
    for _,name in ipairs(keywords) do
        inputs[name].Text='999999'
    end
    for _,obj in ipairs(player:GetDescendants()) do
        if obj:IsA('NumberValue') or obj:IsA('IntValue') then
            for _,name in ipairs(keywords) do
                if obj.Name:lower():find(name:lower(),1,true) then
                    if pcall(function() obj.Value=999999 end) then total=total+1 end
                    break
                end
            end
        end
    end
    status.Text='Wrote '..total..' local numeric values. Actual game stats may be server-controlled.'
end)
button('SCAN',160,283,138,function()
    local results={}
    for _,name in ipairs(keywords) do results[name]=0 end
    local function scan(obj)
        for _,name in ipairs(keywords) do
            if obj.Name:lower():find(name:lower(),1,true) then results[name]=results[name]+1 end
        end
        for attr in pairs(obj:GetAttributes()) do
            for _,name in ipairs(keywords) do
                if attr:lower():find(name:lower(),1,true) then results[name]=results[name]+1 end
            end
        end
    end
    scan(player)
    for _,obj in ipairs(player:GetDescendants()) do scan(obj) end
    local output={}
    for _,name in ipairs(keywords) do table.insert(output,name..' '..results[name]) end
    status.Text=table.concat(output,' | ')
end)
print('Anime Dice Client Stat Panel loaded')
