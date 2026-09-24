-- Root sends an actual TravelState fixture first. This is a UI check, not a teleport test.
return function(expected)
    local player=game.Players.LocalPlayer
    local gui=player.PlayerGui:WaitForChild("CampaignTravel",10)
    assert(gui,"Travel UI did not start")
    task.wait(.15)
    local safe=gui.SafeCanvas
    local panel=safe.TravelPanel
    local button=panel.ReturnToRefuge
    assert(gui:GetAttribute("CanReturn")==expected.canReturn and gui:GetAttribute("Busy")==expected.busy,"State mismatch")
    assert(button.Active==(expected.canReturn and not expected.busy),"Return enablement mismatch")
    assert(panel.TravelMessage.Text==expected.message,"Server message hidden")
    assert(button.AbsoluteSize.Y>=44,"Return touch target too short")
    assert(panel.AbsolutePosition.Y>=safe.AbsolutePosition.Y and panel.AbsolutePosition.Y+panel.AbsoluteSize.Y<=safe.AbsolutePosition.Y+safe.AbsoluteSize.Y+.1,"Travel unsafe area")
    local results=player.PlayerGui:FindFirstChild("NightfallHUD")
    results=results and results.Canvas:FindFirstChild("CampaignResults")
    if results and results.Visible and panel.Visible then
        assert(results.AbsolutePosition.Y+results.AbsoluteSize.Y<=panel.AbsolutePosition.Y,"Results overlap travel strip")
    end
    return {canReturn=expected.canReturn,busy=expected.busy,visible=panel.Visible,minTargetHeight=44,messageVisible=true,safeArea=true,teleportVerified=false}
end
