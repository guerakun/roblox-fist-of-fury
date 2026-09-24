-- Root-only ephemeral Studio integration. Supplies server results, never claims actual live badges.
local Test=game:GetService('StudioTestService')
local ok,args=pcall(function()return Test:GetTestArgs()end)
if not ok or type(args)~='table' or args.test~='AchievementsQA' then return end
assert(game:GetService('RunService'):IsStudio())
local P=require(game.ServerScriptService.NightfallServer.ProgressionService)
local Heat=require(game.ReplicatedStorage.Nightfall.Shared.HeatConfig)
local checks={}
local function check(v,label)assert(v,label)table.insert(checks,label)end
local passed,err=xpcall(function()
    local deadline=os.clock()+40 local player
    repeat player=game.Players:GetPlayers()[1];task.wait(.05)until player and not P.GetSnapshot(player).loading or os.clock()>deadline
    local profile=P.GetTravelProfile(player);assert(profile.mode=='Practice','Ephemeral only')
    local serial=0
    local function run(options)
        serial+=1 local campaign='AchievementQA:'..serial
        profile.data.completedTiers={} profile.data.achievements={}
        for _,id in ipairs({'Heat5','Heat10','Heat15'})do profile.data.owned[id]=nil end
        P.BeginCampaign({player},campaign)
        for stage=1,3 do
            for wave=1,4 do
                if not (options.missing and stage==1 and wave==1)then
                    local kind=wave==4 and 'Boss' or wave==2 and 'Miniboss' or 'Wave'
                    P.AwardEncounterClear({player},stage,kind,campaign..':'..stage..':'..wave)
                end
            end
            local selected=options.heat or {}
            if options.mixedHeat and stage==1 then selected={}end
            if options.reorder and stage==2 then selected={}for i=#Heat.Order,1,-1 do table.insert(selected,Heat.Order[i])end end
            local difficulty=options.tier or 'Normal'
            if options.mixedTier and stage==1 then difficulty='Normal'end
            assert(P.AwardDistrict(player,{id=campaign..':'..stage,campaignId=campaign,stage=stage,
                rank='A',score=100,duration=120,parTime=120,damageTaken=10,bossDamageTaken=0,
                difficulty=difficulty,heat=selected}))
        end
        return P.GetSnapshot(player)
    end
    local s=run({missing=true,heat=Heat.Order})
    check(not s.completedTiers.Normal and not s.achievements.Heat5,'missed encounter excludes full-run unlock and Heat badge')
    s=run({mixedHeat=true,heat=Heat.Order})
    check(not s.completedTiers.Normal and not s.achievements.Heat5,'mixed Heat cannot earn full-run threshold')
    s=run({mixedTier=true,tier='Hard',heat=Heat.Order})
    check(not s.completedTiers.Hard and not s.achievements.Heat5,'mixed difficulty cannot unlock or qualify Heat')
    s=run({heat=Heat.Order,reorder=true})
    check(s.completedTiers.Normal and Heat.Unlocked(s.completedTiers,'Hard'),'complete Normal unlocks Hard')
    check(s.achievements.Heat5 and s.achievements.Heat10 and s.achievements.Heat15,'equivalent reordered Heat earns thresholds')
    check(s.owned.Heat5 and s.owned.Heat10 and s.owned.Heat15,'Heat cosmetics earned locally without purchases')
    check(s.achievements.District1 and s.achievements.District2 and s.achievements.District3 and s.achievements.NoHitBoss,'district and explicit no-hit predicates integrate')
    s=run({tier='Hard'})
    check(s.completedTiers.Hard and Heat.Unlocked(s.completedTiers,'Nightmare'),'complete Hard unlocks Nightmare')
    check(not s.achievements.Heat5 and not s.owned.Heat5,'zero Heat does not award threshold cosmetic')
end,debug.traceback)
Test:EndTest({passed=passed,error=passed and nil or err,checks=checks,scope='ephemeral Progression integration with injected server results; no live badges, combat Heat effects or actual full-campaign claim'})
