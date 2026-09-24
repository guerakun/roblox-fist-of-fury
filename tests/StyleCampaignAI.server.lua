-- Observation-only companion to an ordinary HumanBot/client campaign. Outside production projects.
-- Root installs for one fresh Studio campaign; no readiness, movement, damage or reward mutation.
if not game:GetService("RunService"):IsStudio()then return end
local Players=game:GetService("Players")
local Http=game:GetService("HttpService")
local C=require(game.ServerScriptService:WaitForChild("NightfallServer"):WaitForChild("CombatService"))
local P=require(game.ServerScriptService.NightfallServer.ProgressionService)
-- AFTER the frozen tier series only: install the sibling test-only ModuleScript with this observer.
local EntryObserver=require(script.Parent:WaitForChild("StyleCampaignEntryObserver",10))
local entryStates={}
local watched,started,finished={},false,false
local began=os.clock()
local output={schema=1,observer="StyleCampaignAI",observerRevision="style-with-"..EntryObserver.Revision,players={},failures={},policyChanged=false}
local failureKeys={}
local function fail(message)if not failureKeys[message]and #output.failures<100 then failureKeys[message]=true;table.insert(output.failures,message)end end
local function observe(player,snapshot)
    local record=watched[player]
    if not record then
        record={alias="Player"..tostring(#output.players+1),districts={},seen={}}
        watched[player]=record;table.insert(output.players,record)
        entryStates[record]=EntryObserver.New()
    end
    -- Reuse this existing snapshot pass; no additional polling or gameplay mutation.
    if not EntryObserver.Observe(entryStates[record],snapshot,os.clock()-began)then
        fail(record.alias..": invalid entry-observer sample")
    end
    local profile=P.GetSnapshot(player)
    if record.initialCoins==nil and profile.loading~=true and type(profile.coins)=="number"then record.initialCoins=profile.coins end
    local style=snapshot.style
    if type(style)~="table"or type(style.score)~="number"or type(style.multiplier)~="number"or type(style.progress)~="number"or style.score<0 or style.multiplier<1 or style.multiplier>4
        or style.progress<0 or style.progress>1 then fail(record.alias..": malformed style snapshot")end
    local result=snapshot.districtResult
    local receipt=snapshot.districtReceipt
    if type(result)=="table"then
        local previous=record.seen[result.id]
        if not previous then
            previous={id=result.id,stage=result.stage,rank=result.rank,score=result.score,duration=result.duration,
                parTime=result.parTime,damageTaken=result.damageTaken,bossDamageTaken=result.bossDamageTaken,
                firstSeenStatus=snapshot.status,receiptRevisions={}}
            record.seen[result.id]=previous;table.insert(record.districts,previous)
        elseif previous.rank~=result.rank or previous.score~=result.score or previous.duration~=result.duration
            or previous.damageTaken~=result.damageTaken or previous.bossDamageTaken~=result.bossDamageTaken then
            fail(record.alias..": immutable result changed "..result.id)
        end
        if type(receipt)=="table"then
            if receipt.resultId~=result.id then fail(record.alias..": receipt/result mismatch")end
            if previous.revision and receipt.revision<previous.revision then fail(record.alias..": receipt revision moved backward")end
            previous.latestReceipt={status=receipt.status,basePaidCoins=receipt.basePaidCoins,coins=receipt.coins,bountyCoins=receipt.bountyCoins or 0}
            if previous.revision~=receipt.revision then
                table.insert(previous.receiptRevisions,{revision=receipt.revision,status=receipt.status,
                    baseCoins=receipt.baseCoins,basePaidCoins=receipt.basePaidCoins,bonusCoins=receipt.coins,bountyCoins=receipt.bountyCoins or 0,
                    baseXP=receipt.baseXP,basePaidXP=receipt.basePaidXP,bonusXP=receipt.xp})
                previous.revision=receipt.revision
            end
        end
    elseif result~=false or receipt~=false then fail(record.alias..": expired result/receipt must clear false")end
    if snapshot.status=="Victory"or snapshot.status=="Defeat"then
        record.outcome=snapshot.status
        if record.initialCoins and type(profile.coins)=="number"then
            record.coinDelta=profile.coins-record.initialCoins
            record.runCoins=snapshot.runStats.coinsEarned
            if record.coinDelta~=record.runCoins then fail(record.alias..": run coin observer does not match balance delta")end
        end
    end
end
while not finished and os.clock()-began<1800 do
    local terminal=nil
    for _,player in ipairs(Players:GetPlayers())do
        local snapshot=C.GetSnapshot(player)
        if snapshot then
            observe(player,snapshot)
            if snapshot.status~="Waiting"then started=true end
            if started and(snapshot.status=="Victory"or snapshot.status=="Defeat")then terminal=snapshot.status end
        end
    end
    if terminal then
        -- One extra sample catches the final state/receipt publication without changing gameplay.
        task.wait(.3)
        for _,player in ipairs(Players:GetPlayers())do local snapshot=C.GetSnapshot(player);if snapshot then observe(player,snapshot)end end
        output.outcome=terminal;finished=true
    else task.wait(.2)end
end
output.seconds=os.clock()-began;output.finished=finished
local coverage=output.outcome=="Victory"and #output.players>0
for _,record in ipairs(output.players)do
    record.seen=nil
    record.encounterObservations=EntryObserver.Export(entryStates[record])
    local stages,receiptCoins={},0
    for _,district in ipairs(record.districts)do
        stages[district.stage]=true
        if not district.latestReceipt then coverage=false
        else receiptCoins+=district.latestReceipt.basePaidCoins+district.latestReceipt.coins+(district.latestReceipt.bountyCoins or 0)end
    end
    record.threeDistrictsObserved=stages[1]and stages[2]and stages[3]or false
    if not record.threeDistrictsObserved then coverage=false end
    record.receiptCoins=receiptCoins
    if output.outcome=="Victory"and receiptCoins~=record.runCoins then fail(record.alias..": complete district receipts do not reconcile run coins")end
end
output.campaignCoverageComplete=coverage
output.invariantsPassed=finished and #output.failures==0
output.passed=output.invariantsPassed and coverage
local encoded=Http:JSONEncode(output)
workspace:SetAttribute("StyleCampaignReport",encoded)
print("STYLE_CAMPAIGN_QA "..encoded)
