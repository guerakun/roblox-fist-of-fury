-- Actual disabled deployment buttons plus real widget renderer state; no physical selection claim.
return function()
    local player=game.Players.LocalPlayer
    local Heat=require(game.ReplicatedStorage.Nightfall.Shared.HeatConfig)
    local Display=require(player.PlayerScripts.HubClient.HeatDisplay)
    local gui=player.PlayerGui:WaitForChild("CurtainBreakDeploy",10)assert(gui)
    assert(gui:GetAttribute("HeatAvailable")==Heat.Enabled)
    local summaryLabel=gui:FindFirstChild("HeatSummary",true)assert(summaryLabel)
    if not Heat.Enabled then assert(summaryLabel.Text=="HEAT CONTRACTS ARE NOT AVAILABLE")end
    local definitions=Display.Definitions(Heat)
    for _,definition in ipairs(definitions)do
        local button=gui:FindFirstChild("Heat_"..definition.id,true)assert(button)
        assert(button.Text==Display.Label(Heat,definition))
        if not Heat.Enabled then assert(not button.Active and not button.Selectable)end
        assert(button.AbsoluteSize.Y>=44)
    end
    if not Heat.Enabled then assert(gui:GetAttribute("SelectedHeatPoints")==0 and gui:GetAttribute("SelectedHeatRewardPercent")==0)end
    local fixture={Enabled=true,Order=Heat.Order,Contracts=Heat.Contracts}
    local button=Instance.new("TextButton")button.Size=UDim2.fromOffset(280,49)button.Parent=gui
    for _,definition in ipairs(definitions)do
        Display.ApplyButton(button,fixture,definition,true,false)
        assert(button.Active and button.Selectable and button.Text==Display.Label(fixture,definition))
        Display.ApplyButton(button,fixture,definition,false,false)assert(not button.Active and not button.Selectable)
        Display.ApplyButton(button,fixture,definition,true,true)assert(not button.Active and not button.Selectable)
    end
    button:Destroy()
    return {passed=true,actualHeatButtons=6,metadataRendererCases=18,pointsAndRewardSeparate=true,productionEnabled=Heat.Enabled,physicalInputVerified=false}
end
