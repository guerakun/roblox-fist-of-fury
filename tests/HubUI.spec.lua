-- Client layout assertions, not a physical touch/controller playtest.
return function(expectedMessage)
    local gui = game.Players.LocalPlayer.PlayerGui:WaitForChild("CurtainBreakDeploy",10)
    assert(gui,"Hub UI did not start")
    local safe = gui:FindFirstChild("SafeCanvas")
    local panel = safe.DeployShade.DeployPanel
    task.wait(.2)
    local size = safe.AbsoluteSize
    assert(panel.AbsoluteSize.X <= size.X+.1 and panel.AbsoluteSize.Y <= size.Y+.1,"Panel exceeds safe area")
    if expectedMessage then assert(panel.QueueStatus.Text==expectedMessage,"Authoritative deployment notice hidden") end
    local buttons=0
    for _,child in ipairs(gui:GetDescendants()) do
        if child:IsA("TextButton") then
            assert(child.AbsoluteSize.Y>=44,"Short touch target "..child.Name)
            buttons+=1
        end
    end
    assert(buttons>=18,"Missing deployment controls")
    assert(panel.DeployChoices.AutomaticCanvasSize==Enum.AutomaticSize.Y,"Choices must scroll on short screens")
    assert(panel.DeployRequest and panel.CloseDeploy and safe.OpenDeploy,"Missing navigation")
    return {buttons=buttons,safeWidth=size.X,safeHeight=size.Y,panelWidth=panel.AbsoluteSize.X,
        panelHeight=panel.AbsoluteSize.Y,minTargetHeight=44,scrolls=true,physicalDeviceVerified=false}
end
