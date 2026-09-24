-- Actual replacement widget geometry/hold progress; not physical touch/controller dispatch.
return function(Control,HUD)
    local player=game.Players.LocalPlayer
    Control=Control or require(player.PlayerScripts.NightfallClient.DesperationControl)
    HUD=HUD or require(player.PlayerScripts.NightfallClient.DesperationHUD)
    local gui=Instance.new("ScreenGui")gui.Name="DesperationFixture"gui.Parent=player.PlayerGui
    local frame=Instance.new("Frame")frame.Size=UDim2.fromOffset(220,132)frame.Parent=gui
    local scale=Instance.new("UIScale")scale.Parent=frame
    local special=Instance.new("TextButton")special.Position=UDim2.fromOffset(150,0)special.Size=UDim2.fromOffset(70,60)special.Parent=frame
    local t=0 local requests=0 local blocked=false
    local control=Control.new({send=function()requests+=1 end,blocked=function()return blocked end,clock=function()return t end})
    local hud=HUD.new({control=control,special=special,colors={panel=Color3.fromRGB(20,30,40),orange=Color3.fromRGB(255,166,76)}})
    local ok,result=xpcall(function()
        local snapshot={status="Combat",canDesperation=true,desperationCost=12,desperationCooldown=0}
        control:Update(snapshot)
        for _,factor in ipairs({.8,1})do
            scale.Scale=factor hud.Render(true)game:GetService("RunService").RenderStepped:Wait()
            assert(hud.button.Visible and not special.Visible and hud.button.AbsoluteSize.Y>=44)
            assert(hud.button.AbsolutePosition==special.AbsolutePosition and hud.button.AbsoluteSize==special.AbsoluteSize)
            assert(string.find(hud.button.CostLabel.Text,"+12% SELF",1,true))
        end
        assert(control:TouchBegin())t=.2 hud.Render(true)assert(requests==0 and hud.button.HoldProgress.Size.X.Scale>0)
        t=.4 hud.Render(true)assert(requests==1)
        hud.Render(true)assert(requests==1)
        control:TouchEnd()hud.Render(false)assert(special.Visible and not hud.button.Visible)
        control:Handle("Special",Enum.UserInputState.Begin)hud.Render(false)assert(control.armed)
        blocked=true control:Update(snapshot)hud.Render(true)assert(not hud.button.Visible and not control.armed)
        return {passed=true,scaleCases=2,minimumTouchTarget=48,reusesSpecialBounds=true,explicitCost=true,oneHoldOneRequest=true,physicalInputVerified=false}
    end,debug.traceback)
    hud.Destroy()gui:Destroy()assert(ok,result)return result
end
