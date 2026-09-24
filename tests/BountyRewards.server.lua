-- Root-only actual Progression integration with ephemeral profiles and a forged client request.
local T=game:GetService('StudioTestService')
local ok,args=pcall(function()return T:GetTestArgs()end)
if not ok or type(args)~='table' or args.test~='BountyRewardsQA'then return end
assert(game:GetService('RunService'):IsStudio())
local P=require(game.ServerScriptService.NightfallServer.ProgressionService)
local qa=Instance.new('RemoteEvent');qa.Name='BountyRewardsQA';qa.Parent=game.ReplicatedStorage
local hello,forged={},{}
qa.OnServerEvent:Connect(function(p,kind)if kind=='Hello'then hello[p]=true elseif kind=='Forged'then forged[p]=true end end)
local checks={}
local function check(v,label)assert(v,label)table.insert(checks,label)end
local function waitFor(fn)
    local deadline=os.clock()+35 repeat if fn()then return end task.wait(.05)until os.clock()>deadline
    error('Bounty QA timeout')
end
local success,err=xpcall(function()
    local player
    waitFor(function()player=game.Players:GetPlayers()[1];return player and hello[player] and not P.GetSnapshot(player).loading end)
    local profile=P.GetTravelProfile(player);assert(profile.mode=='Practice','Ephemeral only')
    local function coins()return P.GetSnapshot(player).coins end
    local function result(c)return {campaignId=c,id=c..':1',stage=1,rank='S',difficulty='Normal',heat={},score=10,duration=100,parTime=120,damageTaken=1}end
    local start=coins();local observed=0
    P.SetRewardObserver(function(_,delta)observed+=delta end)
    P.BeginCampaign({player},'BountyQA:A')
    P.AwardEncounterClear({player},1,'Wave','BountyQA:A:1:1')
    P.AwardBounty({player},'BountyQA:A',1,1)
    check(coins()==start+50,'separate earned encounter and bounty payment')
    P.AwardBounty({player,player},'BountyQA:A',1,1)
    check(coins()==start+50,'retry and duplicate participant cannot pay bounty twice')
    local r=P.AwardDistrict(player,result('BountyQA:A'))
    check(r.basePaidCoins==25 and r.bountyCoins==25 and r.coins==12 and r.bountyXP==0,'rank excludes bounty base and receipt reports actual components')
    check(observed==coins()-start,'observer equals paid deltas exactly')
    local before=coins();qa:FireClient(player,'Forge');waitFor(function()return forged[player]end);task.wait(.2)
    check(coins()==before,'actual client bounty forgery ignored')
    P.BeginCampaign({player},'BountyQA:B')
    P.AwardBounty({player},'BountyQA:A',1,2)
    check(coins()==before,'retired campaign bounty callback rejected')
    profile.mode='Unavailable';P.AwardBounty({player},'BountyQA:B',1,1);P.AwardDistrict(player,result('BountyQA:B'))
    check(coins()==before and P.GetDistrictReceipt(player,'BountyQA:B:1').status=='readOnly','read-only bounty is unpaid')
    profile.mode='Practice';P.ResumeAfterTravelFailure(player)
    r=P.GetDistrictReceipt(player,'BountyQA:B:1')
    check(coins()==before+25 and r.bountyCoins==25 and r.status=='paid','same-campaign deferred bounty settles once')
    P.ResumeAfterTravelFailure(player);check(coins()==before+25,'repeat pending flush does not repay')
    P.BeginCampaign({player},'BountyQA:C');profile.mode='Unavailable'
    P.AwardBounty({player},'BountyQA:C',1,1);P.AwardBounty({player},'BountyQA:C',1,2)
    before=coins();local callbacks=0
    P.SetRewardObserver(function()callbacks+=1;P.BeginCampaign({player},'BountyQA:D')end)
    profile.mode='Practice';P.ResumeAfterTravelFailure(player)
    check(callbacks==1 and coins()==before+25,'reentrant campaign rotation cannot settle remaining retired bounty')
end,debug.traceback)
P.SetRewardObserver(nil)
T:EndTest({passed=success,error=success and nil or err,checks=checks,scope='actual ephemeral Progression and client forgery; no spawned bounty enemy or live persistence claim'})
