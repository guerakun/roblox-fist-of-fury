-- Root-only two-client actual resolver/physical contact fixture. Scripted timing is not human avoidance evidence.
return function()
    assert(game:GetService("RunService"):IsStudio(),"Studio only")
    local server=game.ServerScriptService.NightfallServer
    local C=require(server.CombatService)
    local Config=require(game.ReplicatedStorage.Nightfall.Shared.Config)
    local Moves=require(server.EnemyMoves)
    local Http=game:GetService("HttpService")
    local players=game.Players:GetPlayers();assert(#players==2,"Exactly two initialized clients required")
    local qa=Instance.new("RemoteEvent");qa.Name="RiskCoopQA";qa.Parent=game.ReplicatedStorage
    local hello,acks,presses,reports={},{},{},{}
    local connection=qa.OnServerEvent:Connect(function(p,kind,value)
        if kind=="Hello"then hello[p]=true
        elseif kind=="Ack"then acks[value]=acks[value]or {};acks[value][p]=true
        elseif kind=="Pressed"then presses[value.serial]=value
        elseif kind=="Report"then reports[value.serial]=reports[value.serial]or {};reports[value.serial][p]=value.observed end
    end)
    local function await(label,fn,seconds)
        local finish=os.clock()+seconds
        repeat if fn()then return end task.wait(.02)until os.clock()>finish
        error("Timed out: "..label)
    end
    local serial=0
    local function packet(kind,fields)
        serial+=1;local value=fields or {};value.kind=kind;value.serial=serial;return value
    end
    local function broadcastAck(kind,fields)
        local value=packet(kind,fields)
        for _,p in ipairs(players)do qa:FireClient(p,value)end
        await(kind.." acknowledgements",function()return acks[value.serial]and acks[value.serial][players[1]]and acks[value.serial][players[2]]end,4)
    end
    local function anchor(p,x,z)
        p.Character:PivotTo(CFrame.new(x,3,z or 0));p.Character.HumanoidRootPart.Anchored=true
    end
    local result
    local ok,err=xpcall(function()
        await("actual clients",function()
            for _,p in ipairs(players)do if not hello[p]or not C.GetSnapshot(p)or not p.Character or not p.Character:FindFirstChild("HumanoidRootPart")then return false end end
            return true
        end,30)
        task.wait(2)
        C.ClearEnemies();C.ResetLobby();C.SetEncounterState({status="Waiting",wave=0});assert(C.SetRunOptions("Normal",{}))
        C.BeginRun("risk-coop:"..Http:GenerateGUID(false));C.SetArena(Config.Stages[1],1);C.SetWalkingLimit(170)
        C.SetCheckpoint(Vector3.new(90,4,0),"COOP PARRY FIXTURE")
        local cases={}
        for _,case in ipairs({{kind="Executioner",move="CrossroadRuin",volumes=2,followup=0},{kind="Husk",move="HuskJab",volumes=1,followup=.46}})do
            C.ClearEnemies();C.ResetPlayers(Vector3.new(90,4,0))
            for _,p in ipairs(players)do anchor(p,90,0)end
            C.SetEncounterState({status="Combat",wave=1,encounterKind="Wave",partySize=2})
            local order=C.GetAlivePlayers();local defender,other=order[1],order[2]
            assert(defender and other and C.GetSnapshot(defender).canBlock,"First resolver target must have guard available")
            local actor=C.SpawnEnemy(case.kind,Vector3.new(85,0,0),1)
            local data=C.GetEnemies()[actor]
            actor.HumanoidRootPart.Anchored=true
            data.spec=table.clone(data.spec);data.spec.Moves={case.move};data.spec.PhaseMoves={};data.spec.DesperationMove=nil
            data.spec.PhaseSummons=0;data.spec.FeintChance=0;data.attackAt=workspace:GetServerTimeNow()+120
            data.nextMove=case.move
            broadcastAck("Track",{model=actor})
            task.wait(2.2)
            -- These accepted control hits prove spawn protection and camera exclusion are not masking the resolver.
            for _,p in ipairs(players)do
                assert(C.ApplyHit(actor,p,{Damage=1,Knockback=0,Growth=0,Lift=0,Stun=0},1),"Control hit rejected")
            end
            task.wait(.6)
            local before={};for _,p in ipairs(players)do before[p]=C.GetSnapshot(p).runStats.damageTaken end
            local styleBefore=C.GetSnapshot(defender).style.multiplier
            local move=Moves.Build(case.move,{origin=actor.HumanoidRootPart.Position,target=defender.Character.HumanoidRootPart.Position,
                direction=1,arena=Config.Stages[1],partyPositions={},spec=data.spec,phase=1})
            assert(#move.Volumes==case.volumes)
            for _,volume in ipairs(move.Volumes)do
                for _,p in ipairs(players)do assert(Moves.Contains(volume,p.Character.HumanoidRootPart.Position),"Co-located target outside tested footprint")end
            end
            data.attackAt=workspace:GetServerTimeNow()+.2
            await("actual selected "..case.move,function()return data.attacking and data.lastMove==case.move end,4)
            local capturedSerial=data.attackSerial
            local impactAt=data.resolveAt-case.followup
            local press=packet("ParryAt",{at=impactAt-.09,direction=-1})
            qa:FireClient(defender,press)
            local parried=false;local deadline=os.clock()+3
            repeat
                parried=data.attackSerial>capturedSerial and C.GetSnapshot(defender).style.multiplier>styleBefore
                if not parried then task.wait(.01)end
            until parried or os.clock()>deadline
            assert(parried,"Actual parry failed: "..Http:JSONEncode({move=case.move,impactAt=impactAt,pressed=presses[press.serial],
                attackerSerial=data.attackSerial,capturedSerial=capturedSerial,defender=C.GetSnapshot(defender),other=C.GetSnapshot(other)}))
            -- Only postpone the next independent attack; the captured canceled resolver is otherwise untouched.
            data.attackAt=workspace:GetServerTimeNow()+120
            task.wait(.75)
            for _,p in ipairs(players)do assert(C.GetSnapshot(p).runStats.damageTaken==before[p],"Canceled resolver damaged a co-located target")end
            local query=packet("Report")
            for _,p in ipairs(players)do qa:FireClient(p,query)end
            await("FX reports",function()return reports[query.serial]and reports[query.serial][players[1]]and reports[query.serial][players[2]]end,4)
            for _,p in ipairs(players)do
                local observed=reports[query.serial][p]
                assert(observed.cancelled and observed.perfect and observed.tells==case.volumes,"Missing initial tell or replicated parry/cancel")
                assert(observed.impacts==0 and observed.afterCancelTells==0 and observed.afterCancelImpacts==0,"Canceled attack emitted impact/followup FX")
            end
            table.insert(cases,{move=case.move,initialVolumes=case.volumes,actualPerfectBlock=true,secondTargetDamage=0,
                laterImpactEvents=0,laterTellEvents=0,pressedLead=impactAt-presses[press.serial].at})
            broadcastAck("Release")
        end
        C.ClearEnemies();C.BeginRun("contested-orb:"..Http:GenerateGUID(false));C.ResetPlayers(Vector3.new(90,4,0))
        for index,p in ipairs(players)do anchor(p,90-(index-1)*4,0)end
        C.SetEncounterState({status="Combat",wave=1,encounterKind="Wave",partySize=2})
        local keeper=C.SpawnEnemy("Husk",Vector3.new(115,0,0),1)
        C.GetEnemies()[keeper].attackAt=workspace:GetServerTimeNow()+120;keeper.HumanoidRootPart.Anchored=true
        local victim=C.SpawnEnemy("Husk",Vector3.new(100,0,0),1)
        C.GetEnemies()[victim].threshold=1;victim.HumanoidRootPart.Anchored=true
        assert(C.ApplyHit(players[1],victim,{Damage=2,Knockback=0,Growth=0,Lift=0,Stun=0},1))
        local folder=workspace.CombatPickups;assert(#folder:GetChildren()==1,"Contested orb missing")
        local orb=folder:GetChildren()[1];local position=orb.PrimaryPart.Position
        local scores={};for _,p in ipairs(players)do scores[p]=C.GetSnapshot(p).style.score end
        for index,p in ipairs(players)do
            anchor(p,97,index==1 and -1 or 1)
            local snapshot=C.GetSnapshot(p)
            assert(not snapshot.downed and not snapshot.grabbed and(position-p.Character.HumanoidRootPart.Position).Magnitude<5,"Both contenders must be eligible and near")
        end
        for _,p in ipairs(players)do
            local r=p.Character.HumanoidRootPart;r.Anchored=false;r:SetNetworkOwner(nil)
            p.Character.Humanoid:MoveTo(Vector3.new(100,3,0))
        end
        await("contested actual physical claim",function()return not orb.Parent end,3)
        local total,winners=0,0
        for _,p in ipairs(players)do
            local delta=C.GetSnapshot(p).style.score-scores[p]
            assert(delta==0 or delta==20,"Unexpected contested score delta")
            total+=delta;if delta>0 then winners+=1 end
        end
        assert(total==20 and winners==1,"Physical contention paid zero or multiple winners")
        task.wait(.3)
        local final=0;for _,p in ipairs(players)do final+=C.GetSnapshot(p).style.score-scores[p]end
        assert(final==20,"Later limb contact paid again")
        result={passed=true,actualEnemyResolvers=cases,contestedPhysicalOrb={eligibleContenders=2,actualWinners=1,scorePaid=20},
            humanTimingVerified=false,physicalDevicesVerified=false}
    end,debug.traceback)
    connection:Disconnect();qa:Destroy()
    C.ClearEnemies();C.ResetLobby();C.ResetPlayers(Vector3.new(28,4,0));C.SetEncounterState({status="Waiting",wave=0,enemiesRemaining=0})
    assert(ok,err);return result
end
