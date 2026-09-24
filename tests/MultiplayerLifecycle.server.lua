-- TEST ONLY, outside both production projects. Run via StudioTestService with two clients.
-- Uses real Player lifecycle signals and server-authorized test hits. Never writes live persistence.
if not game:GetService('RunService'):IsStudio() then return end
local T=game:GetService('StudioTestService')
local ok,args=pcall(function()return T:GetTestArgs()end)
if not ok or type(args)~='table' or args.test~='CurtainBreakLifecycle' then return end
local P=game.Players
local C=require(game.ServerScriptService.NightfallServer.CombatService)
local R=game.ReplicatedStorage
local Config=require(R.Nightfall.Shared.Config)
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
    assert(type(args.sourceCommit)=='string'and #args.sourceCommit>0,'Pass frozen sourceCommit provenance')
    result.sourceCommit=args.sourceCommit;result.difficulty='Normal';result.heat={}
    task.wait(2) -- CharacterAdded setup can still finish after the first snapshot.
    local players=P:GetPlayers() table.sort(players,function(a,b)return a.UserId<b.UserId end)
    local a,b=players[1],players[2]
    -- Isolate survival/stock transfer from automatic campaign advances.
    C.SetReadyCallback(function()end)
    C.ClearEnemies();C.ResetLobby();C.SetEncounterState({status='Waiting',wave=0})
    assert(C.SetRunOptions('Normal',{}))
    local campaign='lifecycle:'..game:GetService('HttpService'):GenerateGUID(false)
    C.BeginRun(campaign);C.SetArena(Config.Stages[1],1);C.SetWalkingLimit(170)
    C.SetCheckpoint(Vector3.new(90,4,0),'LIFECYCLE FIXTURE')
    C.ResetPlayers(Vector3.new(90,4,0));C.SetEncounterState({status='Intermission',wave=0})
    local enemy=C.SpawnEnemy('Husk',Vector3.new(85,0,0),1)
    enemy.HumanoidRootPart.Anchored=true
    task.wait(2.2)
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
    -- Real accepted damage, then a one-time earned clear. Travel itself grants nothing.
    hit(a,40);hit(b,40)
    local damagedA,damagedB=C.GetSnapshot(a),C.GetSnapshot(b)
    check('registered damage retained before clear',damagedA.percent>15 and damagedB.percent>15)
    check('district clear accepted once',C.CompleteDistrict(campaign,1))
    local clearedA,clearedB=C.GetSnapshot(a),C.GetSnapshot(b)
    check('district clear adds one stock and heals fifteen',
        clearedA.stocks==math.min(3,damagedA.stocks+1)and clearedB.stocks==math.min(3,damagedB.stocks+1)
        and clearedA.percent==math.max(0,damagedA.percent-15)and clearedB.percent==math.max(0,damagedB.percent-15))
    check('duplicate district clear rejected',not C.CompleteDistrict(campaign,1))
    check('duplicate clear has no survival benefit',C.GetSnapshot(a).percent==clearedA.percent and C.GetSnapshot(a).stocks==clearedA.stocks
        and C.GetSnapshot(b).percent==clearedB.percent and C.GetSnapshot(b).stocks==clearedB.stocks)
    C.ClearEnemies();C.SetArena(Config.Stages[2],2);C.SetWalkingLimit(300)
    C.SetCheckpoint(Vector3.new(230,4,0),'DISTRICT TRAVEL FIXTURE');C.EnterDistrict(Vector3.new(230,4,0))
    check('new district preserves stocks and percent',C.GetSnapshot(a).stocks==clearedA.stocks and C.GetSnapshot(a).percent==clearedA.percent
        and C.GetSnapshot(b).stocks==clearedB.stocks and C.GetSnapshot(b).percent==clearedB.percent)
    enemy=C.SpawnEnemy('Husk',Vector3.new(225,0,0),1);enemy.HumanoidRootPart.Anchored=true
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
    result.coverage='Stock transfer conservation, KO/downed state, one-time earned district benefit and survival-preserving travel, real disconnect/replacement. Scripted accepted hits; no human difficulty or same-identity reconnect claim unless identityReused=true.'
end
local success,err=xpcall(run,debug.traceback)
if success then finish() else finish(tostring(err)) end
