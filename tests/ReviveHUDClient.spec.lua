-- Actual client widget geometry and state fixture, not physical input evidence.
return function()
    local player=game.Players.LocalPlayer
    local module=player.PlayerScripts.NightfallClient.ReviveHUD
    local HUD=require(module)
    local Layout=require(module.Parent.RescueTouchLayout)
    local gui=Instance.new("ScreenGui")gui.Name="ReviveFixture"gui.Parent=player.PlayerGui
    local frame=Instance.new("Frame")frame.Size=UDim2.fromOffset(360,320)frame.Parent=gui
    local share=Instance.new("TextButton")share.AnchorPoint=Vector2.new(.5,1)share.Visible=true share.Parent=frame
    local function widget(size,anchor)
        local item=Instance.new("Frame")item.Size=size item.AnchorPoint=anchor or Vector2.zero item.Parent=frame return item
    end
    local widgets={abilities=widget(UDim2.fromOffset(220,132),Vector2.new(1,1)),
        pad=widget(UDim2.fromOffset(116,116)),jump=widget(UDim2.fromOffset(54,54),Vector2.new(1,1))}
    local function overlaps(a,b)
        return a.AbsolutePosition.X<b.AbsolutePosition.X+b.AbsoluteSize.X and b.AbsolutePosition.X<a.AbsolutePosition.X+a.AbsoluteSize.X
            and a.AbsolutePosition.Y<b.AbsolutePosition.Y+b.AbsoluteSize.Y and b.AbsolutePosition.Y<a.AbsolutePosition.Y+a.AbsoluteSize.Y
    end
    local messages={}
    local colors={panel=Color3.fromRGB(20,30,40),text=Color3.new(1,1,1),cyan=Color3.fromRGB(60,220,230)}
    local hud=HUD.new({player=player,parent=frame,colors=colors,actionName="ReviveFixtureAction",reserveAttribute="ReviveFixtureReserve",
        actionRemote={FireServer=function(_,action,payload)table.insert(messages,{action,payload})end}})
    local priorMenu,priorSettings=player:GetAttribute("MenuOpen"),player:GetAttribute("SettingsOpen")
    player:SetAttribute("MenuOpen",false)player:SetAttribute("SettingsOpen",false)
    local ok,result=xpcall(function()
        local state={status="Combat",revive={targetUserId=99,name="A LONG TEAMMATE NAME",canStart=true,channeling=false,remaining=9,progress=.4}}
        hud.Update(state)
        for _,width in ipairs({320,360,650,1280})do
            frame.Size=UDim2.fromOffset(width,320)
            for _,touch in ipairs({true,false})do
                share.Visible=true hud.Render(width,touch,false,share)
                widgets.abilities.Position=UDim2.new(1,-16,1,-18)
                widgets.pad.Position=UDim2.new(0,26,1,-136)
                widgets.jump.Position=UDim2.new(1,-29,1,-160)
                Layout.Apply(touch,widgets)
                game:GetService("RunService").RenderStepped:Wait()
                assert(hud.button.Visible and hud.button.AbsoluteSize.Y>=44 and share.AbsoluteSize.Y>=44)
                local left=hud.button.AbsolutePosition.X-frame.AbsolutePosition.X
                local right=share.AbsolutePosition.X+share.AbsoluteSize.X-frame.AbsolutePosition.X
                assert(left>=0 and right<=width and hud.button.AbsolutePosition.X+hud.button.AbsoluteSize.X<share.AbsolutePosition.X,"Rescue controls overlap or escape safe frame")
                assert(math.abs(hud.button.ServerProgress.Size.X.Scale-.4)<.0001)
                if touch then
                    assert(player:GetAttribute("ReviveFixtureReserve")==true)
                    for _,existing in pairs(widgets)do
                        assert(not overlaps(hud.button,existing) and not overlaps(share,existing),"Rescue row overlaps existing touch controls")
                    end
                end
            end
        end
        assert(hud.control:Begin())player:SetAttribute("SettingsOpen",true)
        hud.Render(1280,false,false,share)assert(not hud.button.Visible and not hud.control.heldTarget)
        assert(messages[1][1]=="Revive" and messages[1][2].held==true and messages[2][2].held==false)
        player:SetAttribute("SettingsOpen",false)
        hud.Update({status="Combat",downed=true,downedRemaining=4.2,revive=false})hud.Render(1280,false,false,share)
        assert(not hud.button.Visible and hud.downed.Visible and string.find(hud.downed.Text,"4.2",1,true))
        hud.Update({status="Combat",downed=true,downedRemaining=0,revive=false})hud.Render(1280,false,false,share)
        assert(string.find(hud.downed.Text,"WINDOW CLOSED",1,true))
        hud.Update({status="Victory",revive=false})hud.Render(1280,false,false,share)
        assert(not hud.button.Visible and not hud.downed.Visible and #messages==2)
        return {passed=true,widthCases=4,inputLayouts=2,minimumTouchTarget=44,existingControlBounds=true,serverProgress=true,modalCancel=true,downedExpiry=true,physicalInputVerified=false}
    end,debug.traceback)
    hud.Destroy()gui:Destroy()player:SetAttribute("MenuOpen",priorMenu)player:SetAttribute("SettingsOpen",priorSettings)
    assert(ok,result)return result
end
