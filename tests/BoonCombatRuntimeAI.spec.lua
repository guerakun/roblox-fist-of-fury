-- Root-only disposable Studio client. Injected trusted modifiers isolate combat from persistence/unlock tests.
return function()
    assert(game:GetService("RunService"):IsStudio(),"Studio only")
    local server=game.ServerScriptService.NightfallServer
    local C=require(server.CombatService);local P=require(server.ProgressionService)
    local Config=require(game.ReplicatedStorage.Nightfall.Shared.Config)
    local p=game.Players:GetPlayers()[1];assert(p and #game.Players:GetPlayers()==1,"One initialized client required")
    local qa=Instance.new("RemoteEvent");qa.Name="BoonCombatQA";qa.Parent=game.ReplicatedStorage
    local hello,acks=false,{}
    local connection=qa.OnServerEvent:Connect(function(player,kind,id)
        if player~=p then return end
        if kind=="Hello"then hello=true elseif kind=="Ack"then acks[id]=true end
    end)
    local function await(label,fn,seconds)
        local finish=os.clock()+seconds
        repeat if fn()then return end task.wait(.02)until os.clock()>finish
        error("Timed out: "..label)
    end
    local original=P.GetCombatModifiers;local current={};local result
    local ok,err=xpcall(function()
        await("real client",function()return hello and C.GetSnapshot(p)and p.Character and p.Character:FindFirstChild("HumanoidRootPart")end,25)
        task.wait(2)
        P.GetCombatModifiers=function(player)if player==p then return table.clone(current)end return original(player)end
        C.ClearEnemies();C.ResetLobby();C.SetEncounterState({status="Waiting",wave=0})
        assert(C.SetRunOptions("Normal",{}))
        C.BeginRun("boon-combat:"..game:GetService("HttpService"):GenerateGUID(false))
        C.SetArena(Config.Stages[1],1);C.SetWalkingLimit(170);C.SetCheckpoint(Vector3.new(90,4,0),"BOON FIXTURE")
        local function reset()
            C.ResetPlayers(Vector3.new(90,4,0));p.Character:PivotTo(CFrame.new(90,3,0));p.Character.HumanoidRootPart.Anchored=true
            C.SetEncounterState({status="Combat",wave=1,encounterKind="Wave",partySize=1});task.wait(2.2)
        end
        reset()
        local actor=C.SpawnEnemy("Husk",Vector3.new(95,0,0),1)
        local npc=C.GetEnemies()[actor];npc.threshold=99999;npc.attackAt=workspace:GetServerTimeNow()+180
        actor.HumanoidRootPart.Anchored=true
        local serial=0
        local function request(action,payload)
            serial+=1;qa:FireClient(p,{action=action,payload=payload,serial=serial})
            await("real request ack",function()return acks[serial]end,4);task.wait(.05)
        end
        local function incoming(damage,stun,knockback)
            return C.ApplyHit(actor,p,{Damage=damage,Knockback=knockback or 52,Growth=0,Lift=0,Stun=stun or 0},-1)
        end
        assert(incoming(10));local normalDamage=C.GetSnapshot(p).percent
        local normalVelocity=math.abs(p.Character.HumanoidRootPart.AssemblyLinearVelocity.X)
        assert(normalDamage==10 and math.abs(normalVelocity-52)<.001,"Neutral hit baseline")
        current={damageMultiplier=1.2,damageTakenMultiplier=1.2};reset()
        local before=npc.percent
        assert(C.ApplyHit(p,actor,{Damage=10,Knockback=0,Growth=0,Lift=0,Stun=0},1))
        assert(math.abs(npc.percent-before-12)<.001,"Glass Cannon outgoing damage")
        assert(incoming(10)and C.GetSnapshot(p).percent==12,"Glass Cannon incoming price")
        current={};reset();request("Block",{held=true,direction=1})
        assert(C.GetSnapshot(p).blocking and p.Character:GetAttribute("Blocking"),"Ordinary guard setup")
        current={canBlock=false,styleGainMultiplier=2}
        local revoked=C.GetSnapshot(p)
        assert(not revoked.blocking and revoked.canBlock==false and not p.Character:GetAttribute("Blocking"),"Snapshot retained revoked guard")
        request("Block",{held=true,direction=1,canBlock=true})
        assert(not C.GetSnapshot(p).blocking,"Forged client block capability accepted")
        request("Block",{held=false})
        -- No snapshot/yield between a fresh guard and provider revocation: ApplyHit itself must reject stale guard.
        current={};request("Block",{held=true,direction=1})
        assert(C.GetSnapshot(p).blocking)
        current={canBlock=false,styleGainMultiplier=2}
        assert(incoming(10)and C.GetSnapshot(p).percent==10,"Stale guard reduced or parried incoming damage")
        npc.facing=-1;npc.launchedUntil=0
        local styleBefore=C.GetSnapshot(p).style
        assert(C.ApplyHit(p,actor,{Damage=10,Knockback=0,Growth=0,Lift=0,Stun=0},1))
        local styleAfter=C.GetSnapshot(p).style
        local gainUnits=((styleAfter.multiplier-styleBefore.multiplier)+styleAfter.progress-styleBefore.progress)*6
        assert(math.abs(gainUnits-2)<.000001,"Berserker meter gain: "..game:GetService("HttpService"):JSONEncode({before=styleBefore,after=styleAfter,gainUnits=gainUnits}))
        current={weightMultiplier=1.3,canDash=false};reset()
        local base=C.GetSnapshot(p)
        assert(base.canDash==false and base.weightMultiplier==1.3)
        request("Dash",{direction=1,canDash=true,weightMultiplier=0})
        local denied=C.GetSnapshot(p)
        assert(denied.percent==0 and denied.cooldowns.Dash==0 and denied.cooldowns.Burst==0,"Anchor accepted ordinary Dash")
        assert(incoming(1,2));task.wait(.18)
        local stunned=C.GetSnapshot(p)
        request("Dash",{direction=1,canDash=true})
        denied=C.GetSnapshot(p)
        assert(denied.percent==stunned.percent and denied.cooldowns.Dash==0 and denied.cooldowns.Burst==0,"Anchor Burst charged or escaped")
        reset();assert(incoming(10))
        local anchorVelocity=math.abs(p.Character.HumanoidRootPart.AssemblyLinearVelocity.X)
        assert(math.abs(anchorVelocity-normalVelocity/1.3)<.001,"Anchor effective weight did not reduce knockback")
        -- Capability restoration authorizes a future request, not the old held input.
        current={};reset();request("Dash")
        assert(C.GetSnapshot(p).canDash and C.GetSnapshot(p).cooldowns.Dash>workspace:GetServerTimeNow()+1,"Neutral Dash did not return")
        result={passed=true,injectedServerModifiers=true,realIntentRemotes=true,glassDamageDealt=12,glassDamageTaken=12,
            berserkerStyleGain=2,blockRevocation=true,forgedBlockRejected=true,anchorDashRejected=true,anchorBurstRejected=true,
            baseKnockback=normalVelocity,anchorKnockback=anchorVelocity,capabilityRestore=true,profileUnlockVerified=false,physicalDeviceVerified=false}
    end,debug.traceback)
    P.GetCombatModifiers=original;connection:Disconnect();qa:Destroy()
    C.ClearEnemies();C.ResetLobby();C.ResetPlayers(Vector3.new(28,4,0));C.SetEncounterState({status="Waiting",wave=0,enemiesRemaining=0})
    assert(ok,err);return result
end
