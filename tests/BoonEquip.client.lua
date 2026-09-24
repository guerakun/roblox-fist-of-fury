if not game:GetService("RunService"):IsStudio()then return end
local qa=game.ReplicatedStorage:WaitForChild("BoonEquipQA",70);if not qa then return end
local remote=game.ReplicatedStorage.Nightfall.Remotes:WaitForChild("Progression")
qa.OnClientEvent:Connect(function(id,serial)remote:FireServer("EquipBoon",id);qa:FireServer("Ack",serial)end)
qa:FireServer("Hello")
