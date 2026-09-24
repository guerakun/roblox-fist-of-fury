if not game:GetService("RunService"):IsStudio()then return end
local qa=game.ReplicatedStorage:WaitForChild("RiskQA",70)
if not qa then return end
local action=game.ReplicatedStorage:WaitForChild("Nightfall"):WaitForChild("Remotes"):WaitForChild("Action")
qa.OnClientEvent:Connect(function(packet)
    action:FireServer(packet.action,packet.payload or {direction=1})
    qa:FireServer("Ack",packet.serial)
end)
qa:FireServer("Hello")
