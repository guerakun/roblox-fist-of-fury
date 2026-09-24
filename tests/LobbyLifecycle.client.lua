-- Test only: ordinary readiness requests plus Studio's synthetic-client leave operation.
if not game:GetService('RunService'):IsStudio()then return end
local qa=game.ReplicatedStorage:WaitForChild('LobbyLifecycleQA',60)if not qa then return end
qa.OnClientEvent:Connect(function(command,value)
    if command=='Ready'then game.ReplicatedStorage.Nightfall.Remotes.Action:FireServer('Ready',{ready=value})
    elseif command=='Leave'then game:GetService('StudioTestService'):LeaveTest()end
end)
qa:FireServer('Hello')
