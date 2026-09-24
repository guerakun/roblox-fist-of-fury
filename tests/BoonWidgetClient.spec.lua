-- Actual widget affordances use the same helper as ProgressionUI; full journal/device checks are separate.
return function(Display,Config)
    local player=game.Players.LocalPlayer
    Display=Display or require(player.PlayerScripts.NightfallClient.BoonDisplay)
    Config=Config or require(game.ReplicatedStorage.Nightfall.Shared.ProgressionConfig)
    local gui=Instance.new("ScreenGui")gui.Name="BoonWidgetFixture"gui.Parent=player.PlayerGui
    local button=Instance.new("TextButton")button.Size=UDim2.fromOffset(100,44)button.Parent=gui
    local checked=0
    for _,boon in ipairs(Config.Boons)do
        local state=Display.ApplyButton(button,boon,{xp=1000000,canEquipBoon=true})
        if boon.Enabled==false then
            assert(button.Text=="NOT AVAILABLE"and not button.Active and not button.Selectable and not button.AutoButtonColor)
        else assert(state.canEquip and button.Active and button.Selectable)end
        checked+=1
    end
    game:GetService("RunService").RenderStepped:Wait()assert(button.AbsoluteSize.Y>=44)
    Display.ApplyButton(button,{Id="Known",XP=0},{xp=0,canEquipBoon=false})
    assert(button.Text=="AFTER FIGHT"and not button.Active and not button.Selectable)
    gui:Destroy()
    return {passed=true,widgetsChecked=checked,minimumTouchTarget=44,disabledUnavailable=true,fullJournalLayoutVerified=false,physicalInputVerified=false}
end
