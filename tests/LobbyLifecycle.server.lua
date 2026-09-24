-- Actual Studio lifecycle events; scripted clearing/traversal isolates lifecycle from combat difficulty.
if not game:GetService('RunService'):IsStudio()then return end
local T=game:GetService('StudioTestService')local ok,args=pcall(function()return T:GetTestArgs()end)
if not ok or type(args)~='table'or args.test~='LobbyLifecycle'then return end
local P=game.Players local C=require(game.ServerScriptService.NightfallServer.CombatService)
local Config=require(game.ReplicatedStorage.Nightfall.Shared.Config)
local qa=Instance.new('RemoteEvent')qa.Name='LobbyLifecycleQA'qa.Parent=game.ReplicatedStorage
local hello={}qa.OnServerEvent:Connect(function(p,kind)if kind=='Hello'then hello[p]=true end end)
local result={passed=false,assertions={},scope='actual readiness/departures; scripted combat clearing and traversal'}local ended=false
local function finish(err)if ended then return end ended=true result.passed=err==nil result.error=err T:EndTest(result)end
local function await(label,predicate,seconds)
    local deadline=os.clock()+seconds repeat if predicate()then table.insert(result.assertions,label)return end task.wait(.1)until os.clock()>deadline error(label..' timed out')
end
task.delay(180,function()finish('deadline')end)
local worked,err=xpcall(function()
    await('two clients initialized',function()local ps=P:GetPlayers()if #ps~=2 then return false end for _,p in ipairs(ps)do if not hello[p]or not C.GetSnapshot(p)or not p.Character then return false end end return true end,45)
    assert(type(args.sourceCommit)=='string'and #args.sourceCommit>0,'Pass frozen sourceCommit provenance')
    result.sourceCommit=args.sourceCommit;result.difficulty='Normal';result.heat={}
    assert(C.GetRunStatus()=='Waiting'and C.SetRunOptions('Normal',{}),'Fresh unmanaged lobby required')
    task.wait(2)
    local ps=P:GetPlayers()local a,b=ps[1],ps[2]local oldIds={[a.UserId]=true,[b.UserId]=true}
    qa:FireClient(a,'Ready',true)
    await('one ready waits',function()return C.GetReadyCount()==1 and C.GetRunStatus()=='Waiting'end,5)
    qa:FireClient(a,'Ready',false)
    await('first cancellation acknowledged',function()return C.GetReadyCount()==0 and C.GetRunStatus()=='Waiting'end,5)
    qa:FireClient(b,'Ready',true)
    await('cancel swaps readiness without starting',function()return not C.GetSnapshot(a).ready and C.GetSnapshot(b).ready and C.GetRunStatus()=='Waiting'end,5)
    qa:FireClient(b,'Ready',false)
    await('second cancellation acknowledged',function()return C.GetReadyCount()==0 and C.GetRunStatus()=='Waiting'end,5)
    qa:FireClient(a,'Ready',true)
    await('ready leader waits on unready member',function()return C.GetSnapshot(a).ready and not C.GetSnapshot(b).ready and C.GetRunStatus()=='Waiting'end,5)
    qa:FireClient(b,'Leave')
    await('unready departure starts remaining ready party',function()return #P:GetPlayers()==1 and C.GetRunStatus()~='Waiting'end,20)
    local deadline=os.clock()+75
    repeat
        local s=C.GetSnapshot(a)
        if s.stage==2 then break end
        for enemy in pairs(C.GetEnemies())do C.ApplyHit(a,enemy,{Damage=9999,Knockback=0,Growth=0,Lift=0,Stun=0},1)end
        local root=a.Character and a.Character:FindFirstChild('HumanoidRootPart')
        if root and (s.status=='Traverse'or s.status=='Advance')then root.CFrame=CFrame.new(s.targetX,4,0)end
        task.wait(.1)
    until os.clock()>deadline
    assert(C.GetSnapshot(a).stage==2,'scripted campaign reaches district2')table.insert(result.assertions,'real encounter progression reaches district2')
    qa:FireClient(a,'Leave')
    await('empty server resets lobby',function()return #P:GetPlayers()==0 and C.GetPlayerCount()==0 and C.GetRunStatus()=='Waiting' and C.GetReadyCount()==0 end,20)
    T:AddPlayers(1)
    await('fresh identity joins reset lobby',function()
        local p=P:GetPlayers()[1]local s=p and C.GetSnapshot(p)
        return s and not oldIds[p.UserId] and hello[p]and s.stage==1 and s.wave==0 and s.status=='Waiting'and s.readyCount==0 and s.stocks==Config.Stocks and s.percent==0 and s.runStats.damageTaken==0 and s.difficulty=='Normal'and #s.heat==0 and s.style.score==0
            and s.districtResult==false and s.districtReceipt==false
    end,40)
    local options=C.GetRunOptions()
    assert(not options.locked and not options.admissionLocked,'Unmanaged empty lobby should release its run lock')
    for _,gate in ipairs(workspace.NightfallCity.Gates:GetChildren())do
        if gate:IsA('BasePart')then assert(gate:GetAttribute('Opened')==false,'Fresh lobby curtain remained open')end
    end
    table.insert(result.assertions,'empty unmanaged server clears score, results, options lock and gates')
    result.managedAdmissionResetCoveredHere=false -- Sticky published admission has its own Heat/admission fixture.
end,debug.traceback)
if worked then finish()else finish(tostring(err))end
