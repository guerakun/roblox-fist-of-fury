-- Real widget geometry/affordance fixture. Physical input and combat authority remain separate.
return function(Capabilities)
    local player=game.Players.LocalPlayer
    Capabilities=Capabilities or require(player.PlayerScripts.NightfallClient.ActionCapabilities)
    local guard=Capabilities.new(function()end)
    local gui=Instance.new("ScreenGui")gui.Name="ActionCapabilitiesFixture"gui.Parent=player.PlayerGui
    local frame=Instance.new("Frame")frame.Size=UDim2.fromOffset(240,90)frame.Parent=gui
    local scale=Instance.new("UIScale")scale.Parent=frame
    local colors={text=Color3.new(1,1,1),muted=Color3.fromRGB(120,130,145)}
    local widgets={}
    for i,action in ipairs({"Block","Dash","Recovery"})do
        local button=Instance.new("TextButton")button.Name=action;button.Text="";button.Size=UDim2.fromOffset(70,60);button.Position=UDim2.fromOffset((i-1)*75,0);button.Parent=frame
        local label=Instance.new("TextLabel")label.Size=UDim2.fromScale(1,1);label.TextSize=10;label.Parent=button
        widgets[action]={button,label}
    end
    local minimum=math.huge
    for _,factor in ipairs({.8,1})do
        scale.Scale=factor
        guard:Update({canBlock=false,canDash=false},false)
        for action,pair in pairs(widgets)do guard:RenderButton(pair[1],pair[2],action,2,colors)end
        game:GetService("RunService").RenderStepped:Wait()
        for _,action in ipairs({"Block","Dash"})do
            local pair=widgets[action]
            assert(not pair[1].Active and not pair[1].Selectable and not pair[1].AutoButtonColor)
            assert(pair[2].Text==(action=="Block"and"NO GUARD"or"NO DASH"))
            minimum=math.min(minimum,pair[1].AbsoluteSize.X,pair[1].AbsoluteSize.Y)
        end
        assert(widgets.Recovery[1].Active and widgets.Recovery[2].Text=="2.0s")
        guard:Update({canBlock=true,canDash=true},false)
        for action,pair in pairs(widgets)do
            guard:RenderButton(pair[1],pair[2],action,0,colors)
            assert(pair[1].Active and pair[1].Selectable and pair[1].AutoButtonColor)
            assert(pair[2].Text==string.upper(action))
        end
        guard:RenderButton(widgets.Dash[1],widgets.Dash[2],"Dash",1.21,colors)
        assert(widgets.Dash[2].Text=="1.2s" and widgets.Dash[2].TextColor3==colors.muted)
    end
    assert(minimum>=44)
    gui:Destroy()
    return {passed=true,widgets=3,scales=2,minimumTarget=minimum,disabledAndRestored=true,cooldownPreserved=true,physicalInputVerified=false}
end

