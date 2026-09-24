-- Test-only client companion for CombatAdmissionAI.server.lua, outside all production projects.
if not game:GetService("RunService"):IsStudio() then return end
local qa=game.ReplicatedStorage:WaitForChild("CombatAdmissionQA",70)
if not qa then return end
local action=game.ReplicatedStorage:WaitForChild("Nightfall"):WaitForChild("Remotes"):WaitForChild("Action")
qa.OnClientEvent:Connect(function(packet)
    if packet.kind=="ReadyProbe" then
        action:FireServer("Ready",{ready=true})
        qa:FireServer("Ack",packet.serial)
    end
end)
qa:FireServer("Hello")
