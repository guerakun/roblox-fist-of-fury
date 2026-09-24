if not game:GetService("RunService"):IsStudio()then return end
local qa=game.ReplicatedStorage:WaitForChild("HeatQA",70)
if not qa then return end
local remotes=game.ReplicatedStorage.Nightfall.Remotes
qa.OnClientEvent:Connect(function(packet)
    remotes.Action:FireServer("Revive",{held=packet.held,targetUserId=packet.targetUserId})
    qa:FireServer("Ack",packet.serial)
end)
remotes.FX.OnClientEvent:Connect(function(event)
    if event.kind=="Telegraph"and(event.moveId=="MutatedCrossfire"or event.moveId=="HuskJab")then
        qa:FireServer(event.moveId=="MutatedCrossfire"and "MutationTell"or "JabTell",{duration=event.duration,shape=event.shape,size=event.size})
    end
end)
qa:FireServer("Hello")
