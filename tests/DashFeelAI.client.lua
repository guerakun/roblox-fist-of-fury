-- Actual request only; production Main controls normal idle locomotion.
local qa=game.ReplicatedStorage.Nightfall.Remotes:WaitForChild("DashFeelQA")
qa.OnClientEvent:Connect(function(command)
    if command=="Dash"then
        game.ReplicatedStorage.Nightfall.Remotes.Action:FireServer("Dash",{direction=Vector3.zAxis,requestId=101})
        qa:FireServer("Sent")
    end
end)
qa:FireServer("Ready")
