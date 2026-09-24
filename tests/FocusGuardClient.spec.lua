-- Actual local TextBox/attribute signal fixture; synthetic focus, not physical controls.
-- Root runs in an isolated client, not during a bot comparison.
return function()
    local p=game.Players.LocalPlayer
    local Guard=require(p.PlayerScripts.NightfallClient.FocusGuard)
    local input=game:GetService("UserInputService")
    assert(not p:GetAttribute("MenuOpen") and not p:GetAttribute("SettingsOpen"),"Close modal menus before fixture")
    local clears,releases=0,0
    local guard=Guard.new({input=input,player=p,clearHeld=function()clears+=1 end,releaseBlock=function()releases+=1 end})
    local gui=Instance.new("ScreenGui")gui.Name="FocusGuardFixture"gui.Parent=p.PlayerGui
    local box=Instance.new("TextBox")box.Size=UDim2.fromOffset(150,40)box.Parent=gui
    local ok,result=xpcall(function()
        box:CaptureFocus()task.wait(.15)
        assert(input:GetFocusedTextBox()==box and clears>=1 and releases>=1)
        assert(not guard:CanReturn(true,false,true))
        box:ReleaseFocus()task.wait(.1)
        assert(not guard:Blocked())
        for _,name in ipairs({"MenuOpen","SettingsOpen"})do
            local before=clears p:SetAttribute(name,true)task.wait(.1)
            assert(clears>before and guard:Blocked() and not guard:CanReturn(true,false,true))
            p:SetAttribute(name,false)task.wait(.1)assert(not guard:Blocked())
        end
        return {passed=true,actualTextFocus=true,actualModalSignals=true,releaseCallbacks=releases,physicalInputVerified=false}
    end,debug.traceback)
    box:ReleaseFocus()p:SetAttribute("MenuOpen",false)p:SetAttribute("SettingsOpen",false)
    guard:Destroy()gui:Destroy()assert(ok,result)return result
end
