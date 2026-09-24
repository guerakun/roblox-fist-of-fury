-- Root-only Studio fixture; production projects exclude tests and Studio profiles are ephemeral.
if not game:GetService('RunService'):IsStudio() then return end
local T=game:GetService('StudioTestService')
local ok,args=pcall(function()return T:GetTestArgs()end)
if not ok or type(args)~='table' or args.test~='RankRewardsQA' then return end
local P=require(game.ServerScriptService.NightfallServer.ProgressionService)
local qa=Instance.new('RemoteEvent');qa.Name='RankRewardsQA';qa.Parent=game.ReplicatedStorage
local hello,ack={},{}
qa.OnServerEvent:Connect(function(p,action)if action=='Hello'then hello[p]=true elseif action=='Forged'then ack[p]=true end end)
local assertions={}
local function check(v,label)assert(v,label);table.insert(assertions,label)end
local function waitFor(predicate,seconds)
    local deadline=os.clock()+seconds repeat if predicate()then return end task.wait(.05)until os.clock()>deadline error('Fixture timed out')
end
local worked,err=xpcall(function()
    waitFor(function()local p=game.Players:GetPlayers()[1];return p and hello[p] and not P.GetSnapshot(p).loading end,40)
    local player=game.Players:GetPlayers()[1]
    local profile=P.GetTravelProfile(player)
    assert(profile.mode=='Practice','Never alter persisted profiles in this fixture')
    local function balance()local s=P.GetSnapshot(player);return s.coins,s.xp end
    local function result(campaign,rank)
        return {id=campaign..':1',campaignId=campaign,stage=1,rank=rank or 'S',score=1234,duration=100,parTime=120,damageTaken=10,difficulty='Normal',heat={}}
    end
    local beforeCoins,beforeXP=balance()
    P.BeginCampaign({player},'RankQA:A')
    P.AwardEncounterClear({player},1,'Boss','RankQA:A:1:4')
    local r=P.AwardDistrict(player,result('RankQA:A'))
    local coins,xp=balance()
    check(coins-beforeCoins==180 and xp-beforeXP==180 and r.coins==60 and r.baseCoins==120,'late-join nominal base and actual S bonus')
    P.AwardEncounterClear({player},1,'Boss','RankQA:A:1:4')
    P.AwardDistrict(player,result('RankQA:A','D'))
    check(select(1,balance())==coins and select(2,balance())==xp,'retry/new-grade cannot pay coins or XP twice')
    qa:FireClient(player,'Forge')
    waitFor(function()return ack[player]end,5);task.wait(.2)
    check(select(1,balance())==coins and select(2,balance())==xp,'actual client forged reward actions ignored')
    P.BeginCampaign({player},'RankQA:B')
    check(P.AwardDistrict(player,result('RankQA:A'))==false,'stale result rejected after new campaign')
    P.AwardEncounterClear({player},1,'Boss','RankQA:A:1:4')
    check(select(1,balance())==coins,'stale encounter rejected after new campaign')
    profile.mode='Unavailable'
    P.AwardEncounterClear({player},1,'Boss','RankQA:B:1:4')
    P.AwardDistrict(player,result('RankQA:B'))
    check(P.GetDistrictReceipt(player,'RankQA:B:1').status=='readOnly' and select(1,balance())==coins,'read-only receipt survives repeated getter without grant')
    profile.mode='Practice';P.ResumeAfterTravelFailure(player)
    check(select(1,balance())==coins+180 and select(2,balance())==xp+180 and P.GetDistrictReceipt(player,'RankQA:B:1').status=='paid','same-campaign deferred base and bonus settle once')
    coins,xp=balance()
    P.BeginCampaign({player},'RankQA:C')
    profile.mode='Unavailable'
    P.AwardEncounterClear({player},1,'Wave','RankQA:C:1:1')
    P.AwardEncounterClear({player},1,'Boss','RankQA:C:1:4')
    P.AwardDistrict(player,result('RankQA:C'))
    local callbacks=0
    P.SetRewardObserver(function()
        callbacks+=1
        P.BeginCampaign({player},'RankQA:D')
    end)
    profile.mode='Practice';P.ResumeAfterTravelFailure(player);P.SetRewardObserver(nil)
    local c,x=balance()
    check(callbacks==1 and (c-coins==25 or c-coins==120),'observer rotation cannot relabel old pending grants into new run')
    P.BeginCampaign({player},'RankQA:E')
    profile.mode='Unavailable'
    P.AwardEncounterClear({player},1,'Boss','RankQA:E:1:4')
    P.AwardDistrict(player,result('RankQA:E'))
    coins,xp=balance()
    P.SetRewardObserver(function()profile.mode='Released'end)
    profile.mode='Practice';P.AwardDistrict(player,result('RankQA:E'));P.SetRewardObserver(nil)
    check(select(1,balance())==coins+120 and P.GetDistrictReceipt(player,'RankQA:E:1').status=='readOnly','profile release during base callback prevents bonus mutation')
    profile.mode='Practice'
end,debug.traceback)
P.SetRewardObserver(nil)
T:EndTest({passed=worked,error=worked and nil or err,assertions=assertions,scope='Studio ephemeral profile, actual client forgery, server reward integration; not live persistence or real reconnect'})
