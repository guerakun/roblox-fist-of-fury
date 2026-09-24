-- Disposable Studio practice profile integration. Real client EquipBoon requests; no live saves.
if not game:GetService("RunService"):IsStudio()then return end
local T=game:GetService("StudioTestService")
local ok,args=pcall(function()return T:GetTestArgs()end)
if not ok or type(args)~="table"or args.test~="BoonEquipQA"then return end
local P=require(game.ServerScriptService.NightfallServer.ProgressionService)
local C=require(game.ServerScriptService.NightfallServer.CombatService)
local Config=require(game.ReplicatedStorage.Nightfall.Shared.ProgressionConfig)
local qa=Instance.new("RemoteEvent");qa.Name="BoonEquipQA";qa.Parent=game.ReplicatedStorage
local hello,acks={},{}
qa.OnServerEvent:Connect(function(p,kind,serial)if kind=="Hello"then hello[p]=true elseif kind=="Ack"then acks[serial]=p end end)
local function await(fn)
    local deadline=os.clock()+35
    repeat if fn()then return end task.wait(.05)until os.clock()>deadline
    error("Boon equip fixture timed out")
end
local savedFlags,checks={},{}
local function check(value,label)assert(value,label);table.insert(checks,label)end
local profile,saved
local passed,err=xpcall(function()
    local p
    await(function()p=game.Players:GetPlayers()[1];return p and hello[p]and C.GetSnapshot(p)and not P.GetSnapshot(p).loading end)
    profile=P.GetTravelProfile(p);assert(profile.mode=="Practice","Ephemeral practice only")
    saved={xp=profile.data.xp,coins=profile.data.coins,boon=profile.data.boon,owned=table.clone(profile.data.owned)}
    local serial=0
    local function equip(id)
        task.wait(.25) -- Respect the ordinary progression request throttle.
        serial+=1;qa:FireClient(p,id,serial);await(function()return acks[serial]==p end);task.wait(.25)
    end
    C.SetEncounterState({status="Waiting",wave=0})
    for _,id in ipairs({"GlassCannon","Berserker","Anchor"})do
        local boon=Config.FindBoon(id);savedFlags[id]=boon.Enabled
        boon.Enabled=false;profile.data.xp=1000000;profile.data.coins=1000000;profile.data.owned[id]=true;profile.data.boon="Guardian"
        equip(id);check(P.GetSnapshot(p).boon=="Guardian",id..": disabled server rollout rejects equip despite currency/ownership/XP")
        boon.Enabled=true;profile.data.xp=boon.XP-1
        equip(id);check(P.GetSnapshot(p).boon=="Guardian",id..": earned XP boundary cannot be bypassed by coins/ownership")
        profile.data.xp=boon.XP;equip(id)
        check(P.GetSnapshot(p).boon==id,id..": exact earned XP permits real equip request")
        local m=P.GetCombatModifiers(p);local snapshot=C.GetSnapshot(p)
        if id=="GlassCannon"then check(m.damageMultiplier==1.2 and m.damageTakenMultiplier==1.2,id..": real profile provides both sides of trade-off")
        elseif id=="Berserker"then check(m.styleGainMultiplier==2 and not m.canBlock and not snapshot.canBlock,id..": real profile disables authoritative guard capability")
        else check(m.weightMultiplier==1.3 and not m.canDash and not snapshot.canDash,id..": real profile disables authoritative dash capability")end
        C.SetEncounterState({status="Combat",wave=1});equip("Guardian")
        check(P.GetSnapshot(p).boon==id,id..": combat cannot remove trade-off by equipping another boon")
        C.SetEncounterState({status="Waiting",wave=0})
    end
    equip("ForgedBoon");check(P.GetSnapshot(p).boon=="Anchor","Unknown boon request rejected")
    equip({id="GlassCannon",xp=999999,damageMultiplier=999})
    check(P.GetSnapshot(p).boon=="Anchor","Structured forged grant rejected")
end,debug.traceback)
for id,value in pairs(savedFlags)do Config.FindBoon(id).Enabled=value end
if profile and saved then for key,value in pairs(saved)do profile.data[key]=value end end
T:EndTest({passed=passed,error=not passed and tostring(err)or nil,checks=checks,
    scope="Actual practice profile and EquipBoon remote; combat damage/weight and physical device input have separate fixtures"})
