if not game:GetService('RunService'):IsStudio()then return end
local qa=game.ReplicatedStorage:WaitForChild('RankRewardsQA',60)
if not qa then return end
local r=game.ReplicatedStorage.Nightfall.Remotes:WaitForChild('Progression')
qa.OnClientEvent:Connect(function()
    r:FireServer('AwardDistrict',{rank='S',coins=999999,xp=999999,rewardKey='forged'})
    r:FireServer('AwardEncounterClear',{kind='Boss'})
    qa:FireServer('Forged')
end)
qa:FireServer('Hello')
