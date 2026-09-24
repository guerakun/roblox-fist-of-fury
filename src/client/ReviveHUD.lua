-- Contextual rescue control; all displayed channel values come from the server.
local UserInputService=game:GetService("UserInputService")
local ContextActionService=game:GetService("ContextActionService")
local FocusGuard=require(script.Parent.FocusGuard)
local Control=require(script.Parent.ReviveControl)
local HUD={}
function HUD.new(options)
    local player=options.player
    local actionName=options.actionName or "NightfallChannelRevive"
    local connections={}
    local function connect(signal,callback)table.insert(connections,signal:Connect(callback))end
    local function make(class,properties,parent)
        local item=Instance.new(class)
        for key,value in pairs(properties)do item[key]=value end
        item.Parent=parent return item
    end
    local colors=options.colors
    local button=make("TextButton",{Name="ChannelRevive",Text="",Visible=false,AnchorPoint=Vector2.new(.5,1),
        Size=UDim2.fromOffset(174,50),BorderSizePixel=0,BackgroundColor3=colors.panel,Selectable=false},options.parent)
    make("UICorner",{CornerRadius=UDim.new(0,7)},button)
    make("UIStroke",{Color=colors.cyan,Thickness=1},button)
    local function label(name,y,height,size)
        return make("TextLabel",{Name=name,BackgroundTransparency=1,Text="",Font=Enum.Font.GothamBold,
            TextSize=size,TextColor3=colors.text,TextTruncate=Enum.TextTruncate.AtEnd,
            Position=UDim2.fromOffset(6,y),Size=UDim2.new(1,-12,0,height)},button)
    end
    local title=label("HoldLabel",2,21,12)
    local detail=label("TargetWindow",24,18,10)
    local fill=make("Frame",{Name="ServerProgress",BorderSizePixel=0,BackgroundColor3=colors.cyan,
        Position=UDim2.new(0,0,1,-4),Size=UDim2.new(0,0,0,4)},button)
    local downed=make("TextLabel",{Name="DownedWindow",Visible=false,AnchorPoint=Vector2.new(.5,1),
        BackgroundColor3=colors.panel,BackgroundTransparency=.05,TextColor3=colors.text,BorderSizePixel=0,
        Font=Enum.Font.GothamBold,TextSize=12,TextWrapped=true,Size=UDim2.fromOffset(290,50)},options.parent)
    make("UICorner",{CornerRadius=UDim.new(0,7)},downed)
    local touchInput=nil
    local control,guard
    control=Control.new(function(action,payload)options.actionRemote:FireServer(action,payload)end,
        function()return guard and guard:Blocked()or false end)
    guard=FocusGuard.new({input=UserInputService,player=player,clearHeld=function()
        touchInput=nil control:Cancel()
    end})
    local deathConnection=nil
    local childConnection=nil
    local function characterReady(character)
        control:Cancel()touchInput=nil
        if deathConnection then deathConnection:Disconnect()deathConnection=nil end
        if childConnection then childConnection:Disconnect()childConnection=nil end
        local function bindHumanoid(humanoid)
            if not humanoid:IsA("Humanoid") or deathConnection then return end
            deathConnection=humanoid.Died:Connect(function()touchInput=nil control:Cancel()end)
        end
        local humanoid=character:FindFirstChildOfClass("Humanoid")
        if humanoid then bindHumanoid(humanoid)end
        childConnection=character.ChildAdded:Connect(bindHumanoid)
    end
    connect(player.CharacterAdded,characterReady)
    if player.Character then characterReady(player.Character)end
    connect(button.InputBegan,function(input)
        if input.UserInputType~=Enum.UserInputType.Touch and input.UserInputType~=Enum.UserInputType.MouseButton1 then return end
        if control:Begin()then touchInput=input end
    end)
    connect(UserInputService.InputEnded,function(input)
        if input==touchInput then touchInput=nil control:Cancel()end
    end)
    connect(UserInputService.InputChanged,function(input)
        if input==touchInput and input.UserInputState==Enum.UserInputState.Cancel then touchInput=nil control:Cancel()end
    end)
    ContextActionService:BindActionAtPriority(actionName,function(_,state)
        if state==Enum.UserInputState.End or state==Enum.UserInputState.Cancel then
            local held=control:Cancel()return held and Enum.ContextActionResult.Sink or Enum.ContextActionResult.Pass
        end
        if state==Enum.UserInputState.Begin and control:Begin()then return Enum.ContextActionResult.Sink end
        return Enum.ContextActionResult.Pass
    end,false,3000,Enum.KeyCode.V,Enum.KeyCode.ButtonL3)
    local api={button=button,downed=downed,control=control}
    local snapshot={}
    function api.Update(state)
        snapshot=state control:Update(state)
    end
    function api.Render(width,touch,gamepad,shareButton)
        control:Update(snapshot)
        local visible=control:Available()and not guard:Blocked()
        button.Visible=visible
        downed.Visible=snapshot.downed==true and snapshot.status~="Defeat" and snapshot.status~="Victory" and not guard:Blocked()
        local bottom=touch and -18 or -104
        local shareVisible=shareButton.Visible
        local cell=math.min(174,math.max(120,(width-36)/2))
        button.Size=UDim2.fromOffset(cell,50)
        shareButton.Size=UDim2.fromOffset(visible and cell or 204,50)
        button.Position=UDim2.new(.5,shareVisible and -(cell+8)/2 or 0,1,bottom)
        shareButton.Position=UDim2.new(.5,visible and (cell+8)/2 or 0,1,bottom)
        downed.Position=UDim2.new(.5,0,1,bottom)
        downed.Size=UDim2.fromOffset(math.min(290,width-24),50)
        if visible then
            local revive=snapshot.revive
            title.Text=revive.channeling and "HOLD / REVIVING" or gamepad and "HOLD L3 / REVIVE" or touch and "HOLD TO REVIVE" or "HOLD V / REVIVE"
            detail.Text=string.format("%.1fs / %s",math.max(0,revive.remaining or 0),string.upper(revive.name or "TEAMMATE"))
            fill.Size=UDim2.new(math.clamp(tonumber(revive.progress)or 0,0,1),0,0,4)
        else fill.Size=UDim2.new(0,0,0,4)end
        if downed.Visible then
            local remaining=math.max(0,tonumber(snapshot.downedRemaining)or 0)
            downed.Text=remaining>0 and string.format("DOWNED / %.1fs TO BE REVIVED\nAn ally can hold revive nearby",remaining)
                or "REVIVE WINDOW CLOSED\nWait for your team or a retry"
        end
    end
    function api.Destroy()
        guard:Destroy()
        for _,connection in ipairs(connections)do connection:Disconnect()end
        if deathConnection then deathConnection:Disconnect()end
        if childConnection then childConnection:Disconnect()end
        ContextActionService:UnbindAction(actionName)
        button:Destroy()downed:Destroy()
    end
    return api
end
return HUD
