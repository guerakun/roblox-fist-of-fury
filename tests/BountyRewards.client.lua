if not game:GetService('RunService'):IsStudio()then return end
local qa=game.ReplicatedStorage:WaitForChild('BountyRewardsQA',70)if not qa then return end
local remote=game.ReplicatedStorage.Nightfall.Remotes:WaitForChild('Progression')
qa.OnClientEvent:Connect(function(kind)
    if kind=='Forge'then
        remote:FireServer('AwardBounty',{campaignId='BountyQA:A',stage=1,wave=2,coins=999999})
        remote:FireServer('AwardDistrict',{rank='S',coins=999999})
        qa:FireServer('Forged')
    end
end)
qa:FireServer('Hello')
