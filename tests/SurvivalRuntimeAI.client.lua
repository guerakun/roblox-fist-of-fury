-- Studio-only companion: uses the actual production Revive intent.
if not game:GetService("RunService"):IsStudio()then return end
local qa=game.ReplicatedStorage:WaitForChild("SurvivalQA",70)
if not qa then return end
local action=game.ReplicatedStorage:WaitForChild("Nightfall"):WaitForChild("Remotes"):WaitForChild("Action")
qa.OnClientEvent:Connect(function(packet)
    if packet.flood then for _=1,35 do action:FireServer("Block",{held=false})end end
    action:FireServer("Revive",{held=packet.held,targetUserId=packet.targetUserId})
    qa:FireServer("Ack",packet.serial)
end)
qa:FireServer("Hello")
