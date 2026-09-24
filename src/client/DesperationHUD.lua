-- A separate cost-confirmation control replaces the cooldown Special tile on touch.
local UserInputService=game:GetService("UserInputService")
local HUD={}
function HUD.new(options)
    local control=options.control local special=options.special local colors=options.colors
    local button=Instance.new("TextButton")button.Name="DesperationHold"button.Text=""button.BackgroundColor3=colors.panel
    button.BorderSizePixel=0 button.Selectable=false button.Visible=false button.Parent=special.Parent
    local corner=Instance.new("UICorner")corner.CornerRadius=UDim.new(0,8)corner.Parent=button
    local stroke=Instance.new("UIStroke")stroke.Color=colors.orange stroke.Thickness=1 stroke.Parent=button
    local label=Instance.new("TextLabel")label.Name="CostLabel"label.BackgroundTransparency=1 label.Size=UDim2.fromScale(1,1)
    label.Font=Enum.Font.GothamBold label.TextSize=10 label.TextColor3=colors.orange label.TextWrapped=true label.Parent=button
    local fill=Instance.new("Frame")fill.Name="HoldProgress"fill.BorderSizePixel=0 fill.BackgroundColor3=colors.orange
    fill.Position=UDim2.new(0,0,1,-4)fill.Size=UDim2.new(0,0,0,4)fill.Parent=button
    local pointer=nil local connections={}
    local function connect(signal,fn)table.insert(connections,signal:Connect(fn))end
    connect(button.InputBegan,function(input)
        if options.inputMode then
            options.inputMode:Observe(input.UserInputType.Name,input.KeyCode.Name,input.Position.Magnitude,input)
            if not options.inputMode:CanBegin(input.UserInputType.Name)then return end
        end
        if (input.UserInputType==Enum.UserInputType.Touch or input.UserInputType==Enum.UserInputType.MouseButton1)
            and control:TouchBegin()then pointer=input end
    end)
    connect(UserInputService.InputEnded,function(input)if input==pointer then pointer=nil control:TouchEnd()end end)
    connect(UserInputService.InputChanged,function(input)
        if input==pointer and input.UserInputState==Enum.UserInputState.Cancel then pointer=nil control:TouchEnd()end
    end)
    local api={button=button}
    function api.Render(touch)
        if not touch then pointer=nil control:CancelTouch()end
        local progress=control:Step()
        local visible=touch and control:Available()
        button.Visible=visible special.Visible=not visible
        button.Position=special.Position button.Size=special.Size button.AnchorPoint=special.AnchorPoint
        fill.Size=UDim2.new(progress,0,0,4)
        label.Text="HOLD\nDESPERATION\n+"..tostring(control.state.desperationCost or 0).."% SELF"
        if not visible then pointer=nil end
    end
    function api.Destroy()
        control:Reset()special.Visible=true
        for _,connection in ipairs(connections)do connection:Disconnect()end
        button:Destroy()
    end
    return api
end
return HUD
