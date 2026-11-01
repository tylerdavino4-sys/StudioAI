-- StudioAI Roblox Studio plugin
-- The OpenAI API key stays in the local backend and is never placed in this plugin.
local HttpService = game:GetService("HttpService")
local Selection = game:GetService("Selection")
local BACKEND_URL = "http://127.0.0.1:3210"

local toolbar = plugin:CreateToolbar("StudioAI")
local openButton = toolbar:CreateButton("StudioAI", "Open StudioAI assistant", "rbxassetid://4458901886")
openButton.ClickableWhenViewportHidden = true
local widgetInfo = DockWidgetPluginGuiInfo.new(Enum.InitialDockState.Right, false, false, 430, 620, 340, 420)
local widget = plugin:CreateDockWidgetPluginGuiAsync("StudioAI_Main_v1", widgetInfo)
widget.Title = "StudioAI"

local function make(className, props, parent)
    local obj = Instance.new(className)
    for key,value in pairs(props or {}) do obj[key]=value end
    obj.Parent=parent
    return obj
end
local colors={bg=Color3.fromRGB(18,22,31),panel=Color3.fromRGB(27,33,46),input=Color3.fromRGB(35,43,59),text=Color3.fromRGB(239,243,250),muted=Color3.fromRGB(157,169,190),blue=Color3.fromRGB(55,130,245),green=Color3.fromRGB(42,160,105),red=Color3.fromRGB(190,65,75)}
local main=make("Frame",{Size=UDim2.fromScale(1,1),BackgroundColor3=colors.bg,BorderSizePixel=0},widget)
make("TextLabel",{Position=UDim2.fromOffset(12,8),Size=UDim2.new(1,-24,0,34),BackgroundTransparency=1,Text="StudioAI",TextColor3=colors.text,TextSize=24,Font=Enum.Font.GothamBold,TextXAlignment=Enum.TextXAlignment.Left},main)
make("TextLabel",{Position=UDim2.fromOffset(12,41),Size=UDim2.new(1,-24,0,22),BackgroundTransparency=1,Text="Describe what you want to build.",TextColor3=colors.muted,TextSize=12,Font=Enum.Font.Gotham,TextXAlignment=Enum.TextXAlignment.Left},main)
local chat=make("ScrollingFrame",{Position=UDim2.fromOffset(10,70),Size=UDim2.new(1,-20,1,-178),BackgroundColor3=colors.panel,BorderSizePixel=0,ScrollBarThickness=6,CanvasSize=UDim2.fromOffset(0,0),AutomaticCanvasSize=Enum.AutomaticSize.Y},main)
make("UIPadding",{PaddingTop=UDim.new(0,10),PaddingBottom=UDim.new(0,10),PaddingLeft=UDim.new(0,10),PaddingRight=UDim.new(0,10)},chat)
make("UIListLayout",{Padding=UDim.new(0,8),SortOrder=Enum.SortOrder.LayoutOrder},chat)
local function message(who,body,color)
    local card=make("Frame",{Size=UDim2.new(1,-4,0,10),AutomaticSize=Enum.AutomaticSize.Y,BackgroundColor3=colors.input,BorderSizePixel=0},chat)
    make("UICorner",{CornerRadius=UDim.new(0,8)},card)
    make("UIPadding",{PaddingTop=UDim.new(0,8),PaddingBottom=UDim.new(0,8),PaddingLeft=UDim.new(0,9),PaddingRight=UDim.new(0,9)},card)
    make("TextLabel",{Size=UDim2.new(1,0,0,18),BackgroundTransparency=1,Text=who,TextColor3=color or colors.blue,TextSize=12,Font=Enum.Font.GothamBold,TextXAlignment=Enum.TextXAlignment.Left},card)
    make("TextLabel",{Position=UDim2.fromOffset(0,21),Size=UDim2.new(1,0,0,10),AutomaticSize=Enum.AutomaticSize.Y,BackgroundTransparency=1,Text=tostring(body),TextColor3=colors.text,TextSize=13,Font=Enum.Font.Gotham,TextWrapped=true,TextXAlignment=Enum.TextXAlignment.Left,TextYAlignment=Enum.TextYAlignment.Top},card)
    task.defer(function() chat.CanvasPosition=Vector2.new(0,math.max(0,chat.AbsoluteCanvasSize.Y)) end)
end
local status=make("TextLabel",{Position=UDim2.new(0,12,1,-102),Size=UDim2.new(1,-24,0,18),BackgroundTransparency=1,Text="Backend: start the local server first",TextColor3=colors.muted,TextSize=11,Font=Enum.Font.Gotham,TextXAlignment=Enum.TextXAlignment.Left},main)
local promptBox=make("TextBox",{Position=UDim2.new(0,10,1,-78),Size=UDim2.new(1,-100,0,68),BackgroundColor3=colors.input,BorderSizePixel=0,TextColor3=colors.text,PlaceholderColor3=colors.muted,PlaceholderText="Example: Build a small obby...",Text="",TextSize=13,Font=Enum.Font.Gotham,TextWrapped=true,TextXAlignment=Enum.TextXAlignment.Left,TextYAlignment=Enum.TextYAlignment.Top,ClearTextOnFocus=false,MultiLine=true},main)
make("UICorner",{CornerRadius=UDim.new(0,8)},promptBox)
make("UIPadding",{PaddingTop=UDim.new(0,8),PaddingBottom=UDim.new(0,8),PaddingLeft=UDim.new(0,8),PaddingRight=UDim.new(0,8)},promptBox)
local sendButton=make("TextButton",{Position=UDim2.new(1,-82,1,-78),Size=UDim2.fromOffset(72,68),BackgroundColor3=colors.blue,BorderSizePixel=0,Text="Ask AI",TextColor3=Color3.new(1,1,1),TextSize=13,Font=Enum.Font.GothamBold},main)
make("UICorner",{CornerRadius=UDim.new(0,8)},sendButton)

local allowedParents={Workspace=workspace,ServerScriptService=game:GetService("ServerScriptService"),ReplicatedStorage=game:GetService("ReplicatedStorage"),StarterGui=game:GetService("StarterGui"),StarterPack=game:GetService("StarterPack"),Lighting=game:GetService("Lighting")}
local allowedParts={Part=true,SpawnLocation=true,WedgePart=true,CornerWedgePart=true}
local pending={}
local function vector3(value,fallback)
    if type(value)~="table" then return fallback end
    return Vector3.new(tonumber(value[1]) or fallback.X,tonumber(value[2]) or fallback.Y,tonumber(value[3]) or fallback.Z)
end
local function resolveParent(requestedParent)
    requestedParent=tostring(requestedParent or "Workspace")
    requestedParent=requestedParent:gsub("^%s+",""):gsub("%s+$",""):gsub("/",".")
    requestedParent=requestedParent:gsub("^game%.","")
    local segments={}
    for segment in requestedParent:gmatch("[^%.]+") do
        if segment~="" then table.insert(segments,segment) end
    end
    local first=segments[1] or "Workspace"
    local parent
    for name,service in pairs(allowedParents) do
        if string.lower(name)==string.lower(first) then parent=service; break end
    end
    -- If the AI gives only a folder name (for example "Platforms"),
    -- search inside approved services so nested folders can be found too.
    if not parent and #segments==1 then
        local matches={}
        for _,service in pairs(allowedParents) do
            for _,descendant in ipairs(service:GetDescendants()) do
                if descendant:IsA("Folder") and string.lower(descendant.Name)==string.lower(first) then
                    table.insert(matches,descendant)
                end
            end
        end
        if #matches==1 then return matches[1] end
        if #matches>1 then
            error("Folder name is ambiguous: "..requestedParent..". Use its full path, such as Workspace.CyberpunkLobby.Platforms")
        end
        error("Folder not found in an approved location: "..requestedParent..". Create the folder first or use its full path.")
    end
    assert(parent,"Parent is not allowed: "..requestedParent)
    for i=2,#segments do
        local child=parent:FindFirstChild(segments[i])
        assert(child and child:IsA("Folder"),"Folder path not found: "..table.concat(segments,".",1,i))
        parent=child
    end
    return parent
end
local function apply(op)
    local parent=resolveParent(op.parent)
    if op.type=="create_part" then
        local className=op.className or "Part"
        assert(allowedParts[className],"Part class is not allowed")
        local part=Instance.new(className)
        part.Name=tostring(op.name or "StudioAIPart"):sub(1,80)
        local p=op.properties or {}
        part.Size=vector3(p.Size,Vector3.new(4,1,4))
        part.Position=vector3(p.Position,Vector3.new(0,5,0))
        part.Anchored=p.Anchored~=false
        if p.CanCollide~=nil then part.CanCollide=p.CanCollide==true end
        if p.Transparency~=nil then part.Transparency=math.clamp(tonumber(p.Transparency) or 0,0,1) end
        if type(p.Color)=="table" then part.Color=Color3.fromRGB(math.clamp(tonumber(p.Color[1]) or 255,0,255),math.clamp(tonumber(p.Color[2]) or 255,0,255),math.clamp(tonumber(p.Color[3]) or 255,0,255)) end
        if type(p.Material)=="string" then local ok,mat=pcall(function() return Enum.Material[p.Material] end); if ok and mat then part.Material=mat end end
        part.Parent=parent
    elseif op.type=="create_folder" then
        local folder=Instance.new("Folder"); folder.Name=tostring(op.name or "StudioAIFolder"):sub(1,80); folder.Parent=parent
    elseif op.type=="create_script" then
        local className=op.className or "Script"
        assert(className=="Script" or className=="LocalScript" or className=="ModuleScript","Script class is not allowed")
        assert(type(op.source)=="string" and #op.source<=50000,"Script source is missing or too large")
        local obj=Instance.new(className); obj.Name=tostring(op.name or "StudioAIScript"):sub(1,80); obj.Source=op.source; obj.Parent=parent
    else error("Unknown operation type") end
end
local preview
local function clearPreview() if preview then preview:Destroy(); preview=nil end end
local function showPreview(operations)
    clearPreview(); pending=operations
    preview=make("Frame",{Position=UDim2.new(0,10,1,-148),Size=UDim2.new(1,-20,0,38),BackgroundColor3=Color3.fromRGB(31,53,72),BorderSizePixel=0,ZIndex=5},main)
    make("UICorner",{CornerRadius=UDim.new(0,8)},preview)
    make("TextLabel",{Position=UDim2.fromOffset(8,0),Size=UDim2.new(1,-112,1,0),BackgroundTransparency=1,Text=tostring(#pending).." change(s) ready to review",TextColor3=colors.text,TextSize=11,Font=Enum.Font.GothamBold,TextXAlignment=Enum.TextXAlignment.Left,ZIndex=6},preview)
    local applyButton=make("TextButton",{Position=UDim2.new(1,-98,0,4),Size=UDim2.fromOffset(90,30),BackgroundColor3=colors.green,BorderSizePixel=0,Text="Apply",TextColor3=Color3.new(1,1,1),TextSize=12,Font=Enum.Font.GothamBold,ZIndex=6},preview)
    make("UICorner",{CornerRadius=UDim.new(0,6)},applyButton)
    applyButton.MouseButton1Click:Connect(function()
        applyButton.Active=false
        applyButton.Text="Working..."
        local done,failures=0,{}
        for i,op in ipairs(pending) do
            local ok,err=pcall(apply,op)
            if ok then done+=1 else table.insert(failures,{index=i,operation=op,error=tostring(err)}) end
        end
        local repairRounds=0
        while #failures>0 and repairRounds<2 do
            repairRounds+=1
            message("StudioAI","I found "..#failures.." build error(s). Trying automatic repair ("..repairRounds.."/2)...",colors.blue)
            local requestOk,response=pcall(function()
                return HttpService:RequestAsync({Url=BACKEND_URL.."/repair",Method="POST",Headers={["Content-Type"]="application/json"},Body=HttpService:JSONEncode({failures=failures})})
            end)
            if not requestOk or not response.Success then
                table.insert(failures,{error="Could not contact the AI repair service: "..tostring(requestOk and response.Body or response)})
                break
            end
            local decoded,data=pcall(function() return HttpService:JSONDecode(response.Body) end)
            if not decoded or type(data)~="table" or type(data.operations)~="table" or #data.operations==0 then
                table.insert(failures,{error="The AI could not produce a repair: "..tostring(decoded and data.message or data)})
                break
            end
            local nextFailures={}
            for j,op in ipairs(data.operations) do
                local ok,err=pcall(apply,op)
                if ok then done+=1 else table.insert(nextFailures,{index=j,operation=op,error=tostring(err)}) end
            end
            failures=nextFailures
        end
        clearPreview(); pending={}
        if #failures==0 then
            message("StudioAI","Applied "..done.." change(s)."..(repairRounds>0 and " I automatically repaired the build errors." or "").." Check Explorer and the 3D view.",colors.green)
        else
            local details={}
            for _,failure in ipairs(failures) do table.insert(details,tostring(failure.error or "Repair failed")) end
            message("StudioAI","Applied "..done.." change(s), but "..#failures.." error(s) remain after "..repairRounds.." repair attempt(s):\n"..table.concat(details,"\n"),colors.red)
        end
        applyButton.Text="Apply"
    end)
end
local busy=false
local function ask()
    if busy then return end
    local prompt=promptBox.Text:gsub("^%s+",""):gsub("%s+$","")
    if prompt=="" then return end
    busy=true; promptBox.Text=""; message("You",prompt,colors.blue); status.Text="Backend: contacting local AI server..."; sendButton.Text="..."; sendButton.Active=false
    local names={}; for _,item in ipairs(Selection:Get()) do table.insert(names,item:GetFullName()) end
    local ok,response=pcall(function()
        return HttpService:RequestAsync({Url=BACKEND_URL.."/chat",Method="POST",Headers={["Content-Type"]="application/json"},Body=HttpService:JSONEncode({prompt=prompt,selection=names})})
    end)
    if not ok then message("StudioAI","Could not reach local backend. Start START_STUDIOAI.bat. "..tostring(response),colors.red); status.Text="Backend: offline"
    elseif not response.Success then message("StudioAI","Backend error: "..tostring(response.Body),colors.red); status.Text="Backend: error"
    else
        local decoded,data=pcall(function() return HttpService:JSONDecode(response.Body) end)
        if not decoded or type(data)~="table" then message("StudioAI","Unreadable backend response.",colors.red)
        else
            message("StudioAI",data.message or "Here is the plan.",colors.text)
            if type(data.operations)=="table" and #data.operations>0 then
                local lines={}; for i,op in ipairs(data.operations) do table.insert(lines,i..". "..tostring(op.type).." — "..tostring(op.name or "unnamed")) end
                message("Proposed changes",table.concat(lines,"\n").."\n\nReview and press Apply to insert them.",colors.muted)
                showPreview(data.operations)
            else message("StudioAI","No Studio changes were needed for that reply.",colors.muted) end
            status.Text="Backend: connected"
        end
    end
    busy=false; sendButton.Text="Ask AI"; sendButton.Active=true
end
sendButton.MouseButton1Click:Connect(ask)
promptBox.FocusLost:Connect(function(enterPressed) if enterPressed then ask() end end)
message("StudioAI","Hi! Describe a build, script, or game system. I'll show proposed changes before applying them.",colors.green)
openButton.Click:Connect(function() widget.Enabled=not widget.Enabled end)
