-- Test only, outside both project trees. Sends ordinary hub intent remotes.
if not game:GetService('RunService'):IsStudio()then return end
local qa=game.ReplicatedStorage:WaitForChild('HubPartyQA',60)if not qa then return end
local r=game.ReplicatedStorage.HubRemotes
r.State.OnClientEvent:Connect(function(state)qa:FireServer('State',state)end)
qa.OnClientEvent:Connect(function(action,payload)r.Request:FireServer(action,payload)end)
r.Request:FireServer('Refresh',{})
