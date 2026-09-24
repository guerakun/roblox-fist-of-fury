-- TEST ONLY, outside both production projects. Run via StudioTestService with two clients.
-- Uses real Player lifecycle signals and server-authorized test hits. Never writes live persistence.
if not game:GetService('RunService'):IsStudio() then return end
local T=game:GetService('StudioTestService')
local ok,args=pcall(function()return T:GetTestArgs()end)
if not ok or type(args)~='table' or args.test~='CurtainBreakLifecycle' then return end
local P=game.Players
local C=require(game.ServerScriptService.NightfallServer.CombatService)
local R=game.ReplicatedStorage
local qa=Instance.new('RemoteEvent',R) qa.Name='NightfallCampaignQA' qa:SetAttribute('TestName','NightfallMultiplayerCampaign')
local hellos={} qa.OnServerEvent:Connect(function(p,kind) if kind=='Hello' then hellos[p]=true end end)
local result={test=args.test,assertions={},blocked={},passed=false}
local ended=false
local function check(label,condition,detail)
    table.insert(result.assertions,{name=label,passed=condition==true,detail=detail})
    assert(condition,label)
end
local function await(predicate,seconds)
    local untilTime=os.clock()+seconds
    repeat if predicate() then return true end task.wait(.1) until os.clock()>untilTime
    return false
end
local function finish(err)
    if ended then return end ended=true
    result.error=err
    result.passed=err==nil
    T:EndTest(result)
end
task.delay(180,function()finish('lifecycle deadline')end)
local function run()
    assert(await(function()
        if #P:GetPlayers()~=2 then return false end
        for _,p in ipairs(P:GetPlayers()) do if not C.GetSnapshot(p) or not p.Character or not p.Character:FindFirstChild('HumanoidRootPart') then return false end end
        return true
    end,50),'clients initialized')
    local players=P:GetPlayers() table.sort(players,function(a,b)return a.UserId<b.UserId end)
    local a,b=players[1],players[2]
    -- Isolate survival/stock transfer from automatic campaign advances.
    C.SetReadyCallback(function()end)
    C.SetEncounterState({status='Intermission',wave=0})
    local enemy=C.SpawnEnemy('Grunt',Vector3.new(70,4,0),1)
    local function hit(player,damage)
        assert(await(function() return C.ApplyHit(enemy,player,{Damage=damage,Stun=0,Knockback=0,Growth=0,Lift=0},1) end,8),'accepted test hit')
    end
    for stock=2,0,-1 do
        hit(a,999)
        check('KO charges exactly one stock '..stock,C.GetSnapshot(a).stocks==stock)
        task.wait(1.3)
    end
    check('downed and anchored at zero',C.GetSnapshot(a).downed and a.Character.HumanoidRootPart.Anchored)
    check('invalid recipient rejected',not C.ShareStock(b,0/0))
    check('unknown recipient rejected',not C.ShareStock(b,987654321))
    local before=C.GetSnapshot(a).stocks+C.GetSnapshot(b).stocks
    check('valid stock rescue accepted',C.ShareStock(b,a.UserId))
    local sa,sb=C.GetSnapshot(a),C.GetSnapshot(b)
    check('stock transfer conserves total',sa.stocks+sb.stocks==before,{before=before,after=sa.stocks+sb.stocks})
    check('recipient restored once',sa.stocks==1 and not sa.downed and sa.percent==0 and not a.Character.HumanoidRootPart.Anchored)
    check('duplicate transfer rejected',not C.ShareStock(b,a.UserId))
    C.SetArena(require(R.Nightfall.Shared.Config).Stages[2],2)
    C.ResetPlayers(Vector3.new(230,4,0))
    check('baseline district reset stocks and percent',C.GetSnapshot(a).stocks==3 and C.GetSnapshot(a).percent==0 and C.GetSnapshot(b).stocks==3)
    enemy=C.SpawnEnemy('Grunt',Vector3.new(270,4,0),1)
    hit(a,25)
    local beforeLeave=C.GetSnapshot(a)
    local oldId=a.UserId
    assert(await(function()return hellos[a] end,15),'client leave driver ready')
    qa:FireClient(a,{kind='Leave'})
    check('real client disconnect',await(function()return #P:GetPlayers()==1 end,20))
    T:AddPlayers(1)
    check('replacement joins',await(function()return #P:GetPlayers()==2 end,40))
    local replacement for _,p in ipairs(P:GetPlayers()) do if p~=b then replacement=p end end
    assert(await(function()return C.GetSnapshot(replacement) and replacement.Character and replacement.Character:FindFirstChild('HumanoidRootPart')end,15))
    if replacement.UserId==oldId then
        local after=C.GetSnapshot(replacement)
        check('same identity reconnect retains survival',after.stocks==beforeLeave.stocks and after.percent==beforeLeave.percent and after.hero==beforeLeave.hero)
    else
        table.insert(result.blocked,'Studio AddPlayers creates a new identity; same-UserId reconnect cases 1-4 require a real test account or supported identity reuse. No production identity override added.')
        check('new identity gets first-join stocks',C.GetSnapshot(replacement).stocks==3)
    end
    result.identityReused=replacement.UserId==oldId
    result.coverage='Stock transfer conservation, KO/downed state, baseline district reset, real disconnect/replacement. Full campaign ready/late membership covered by separate harness. Other lifecycle assertions remain explicitly unverified.'
end
local success,err=xpcall(run,debug.traceback)
if success then finish() else finish(tostring(err)) end
