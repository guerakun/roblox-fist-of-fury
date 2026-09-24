-- Server-owned movement and engagement state; damage remains in CombatService.
local Director=require(script.Parent.AttackDirector)
local DifficultyPolicy=require(script.Parent.DifficultyPolicy)
local Archetypes=require(game.ReplicatedStorage.Nightfall.Shared.EnemyArchetypes)
local EnemyAI={}
local ranges={HuskJab=6,HuskJumpKick=16,StriderSlide=17,StriderJab=6,GrapplerGrab=6,GrapplerThrow=6,
    PitcherThrow=21,PitcherShove=7,WardenCounter=7,WardenKick=7,LeaperVaultKick=18,LeaperJab=6,BruteFlop=13,BruteSwing=8}
local function observe(data,target,record,t,delay,airborne)
    local signature=tostring(record.lastAction)..":"..tostring(record.attackStartedAt)..":"..tostring(record.blocking)..":"..tostring(airborne)
    if data.observedTarget~=target then data.observedTarget=target;data.observed={};data.pendingObservation=nil;data.observationSignature=nil end
    if not data.pendingObservation and signature~=data.observationSignature then
        data.observationSignature=signature
        data.pendingObservation={at=t+delay,value={action=record.lastAction,attackAt=record.attackStartedAt,combo=record.combo,blocking=record.blocking,airborne=airborne}}
    end
    if data.pendingObservation and t>=data.pendingObservation.at then data.observed=data.pendingObservation.value;data.pendingObservation=nil end
    return data.observed or {}
end
local closeMoves={Cleaver=true,CrossingSweep=true,AlarmRing=true,TicketCut=true,BellStrike=true,Bite=true,SlagPunch=true}
-- Pure weighted choice: callers supply the random roll so policy has deterministic tests.
function EnemyAI.ChooseEliteMove(spec,data,context,roll)
    if spec.DesperationMove and data.percent>=data.threshold*(spec.DesperationAt or .8) and not data.desperationUsed then return spec.DesperationMove end
    local pool,seen,total={},{},0
    local signature=(spec.PhaseMoves or {})[1]
    local function add(name)
        if seen[name] then return end;seen[name]=true
        local close=closeMoves[name]
        local weight=close and (context.distance<=spec.Reach and 5 or .25) or (context.distance>spec.Reach and 4 or 1.5)
        if name==signature then
            if context.time-(data.lastSignatureAt or -100)<(spec.SignatureCooldown or 8) then weight=0 else weight*=2 end
        end
        if context.lanePlayers>=2 and not close then weight*=1.6 end
        if context.airborne and (name=="CrossingSweep" or name=="AlarmRing" or name=="BellStrike" or name=="SlagPunch")then weight*=.35 end
        if name==data.lastMove then weight*=.25 end
        if weight>0 then total+=weight;table.insert(pool,{name=name,ceiling=total})end
    end
    for _,name in ipairs(spec.Moves or {"Melee"})do add(name)end
    if data.phase==2 then for _,name in ipairs(spec.PhaseMoves or {})do add(name)end end
    if total<=0 then return (spec.Moves or {"Melee"})[1] end
    local point=math.clamp(roll or .5,0,.999999)*total
    for _,entry in ipairs(pool)do if point<entry.ceiling then return entry.name end end
    return pool[#pool].name
end
local function state(model,data,value)
    if data.aiState~=value then data.aiState=value;model:SetAttribute("AIState",value) end
end
function EnemyAI.Step(t,c)
    local alive=c.Combat.GetAlivePlayers()
    local director=c.director
    local profile=c.difficulty or {Aggression=1,TokenBonus=0,ReactionDelay=.35,EvadeChance=1/3,WindupScale=1}
    local function action(model,data,value) if c.RecordAction then c.RecordAction(model,data.kind,value,t)end end
    -- Stagger cancels a captured attack before its token is handed to another actor.
    for model,data in pairs(c.enemies)do
        if (t<data.stunnedUntil or (data.spec.Role=="Grunt" and t<data.launchedUntil)) and data.attacking and t>=(data.armoredUntil or 0) then
            data.attacking=false;data.attackSerial+=1;data.resolveAt=t;data.armoredUntil=0
            data.engaging=false;Director.Release(director,model)
            local cancelledRoot=c.root(model)
            if cancelledRoot then c.fx("EnemyCancel",cancelledRoot.Position,{targetModel=model,enemy=data.kind}) end
        end
    end
    for _,model in ipairs(Director.Sync(director,c.enemies,alive,t))do
        local r=c.root(model)
        if r then c.fx("EnemyCancel",r.Position,{targetModel=model,enemy=c.enemies[model].kind})end
    end
    for _,model in ipairs(Director.Trim(director,Director.Cap(#alive,profile.TokenBonus)))do
        local data=c.enemies[model]
        if data then
            data.engaging=false
            if data.attacking then
                data.attacking=false;data.attackSerial+=1;data.resolveAt=t;data.armoredUntil=0
                local r=c.root(model)
                if r then c.fx("EnemyCancel",r.Position,{targetModel=model,enemy=data.kind})end
            end
        end
    end
    local candidates={}
    for model,data in pairs(c.enemies)do
        local r,h=c.root(model),c.humanoid(model)
        if not r or not h or h.Health<=0 then c.knockOut(model);continue end
        if c.CombatMath.InBlastZone(r.Position,c.arena,c.Config.BlastMargin)then c.knockOut(model);continue end
        if c.encounter.status~="Combat" then h:Move(Vector3.zero);Director.Release(director,model);continue end
        local elite=data.spec.Role~="Grunt"
        if elite and data.phase==1 and data.percent>=data.threshold*.52 then
            data.phase=2;data.moveIndex=0;data.plannedMove=nil;c.attributes(model,data)
            if c.SummonPhase then c.SummonPhase(model,data)end
            c.fx("BossPhase",r.Position,{phase=2,enemy=data.kind,enemyName=data.spec.Name,targetModel=model})
        end
        if not data.entryComplete and (t<(data.entryUntil or 0) or (data.entryKind=="Drop" and h.FloorMaterial==Enum.Material.Air)) then
            state(model,data,"Enter");h.WalkSpeed=data.spec.Speed
            h:MoveTo(Vector3.new(math.clamp(r.Position.X+(data.entryDirection or 1)*4,c.arena.MinX+6,c.arena.MaxX-6),r.Position.Y,math.clamp(r.Position.Z,-11,11)))
            continue
        end
        data.entryComplete=true
        if t<data.stunnedUntil or t<data.launchedUntil then state(model,data,"Stagger");h:Move(Vector3.zero);continue end
        if data.attacking then state(model,data,t<(data.resolveAt or 0) and "Attack" or "Recover");h:Move(Vector3.zero);continue end
        if t<data.recoveryUntil then state(model,data,"Recover");h:Move(Vector3.zero);continue end
        local pos=r.Position
        local x,z=math.clamp(pos.X,c.arena.MinX+6,c.arena.MaxX-6),math.clamp(pos.Z,-12,12)
        if x~=pos.X or z~=pos.Z then r.CFrame+=Vector3.new(x-pos.X,0,z-pos.Z)end
        local target,distance,bestScore
        for _,player in ipairs(alive)do
            local pr=c.root(player.Character)
            if pr and not c.records[player].respawning then
                local d=(Vector3.new(pr.Position.X,0,pr.Position.Z)-Vector3.new(r.Position.X,0,r.Position.Z)).Magnitude
                local focusPenalty=math.max(0,4-(t-(data.targetHistory[player] or 0)))*5
                local assigned=director.slots[model]
                local score=d+focusPenalty-(assigned and assigned.target==player and 8 or 0)
                if not bestScore or score<bestScore then target,distance,bestScore=player,d,score end
            end
        end
        if not target then state(model,data,"Enter");h:Move(Vector3.zero);Director.Release(director,model);continue end
        local pr=c.root(target.Character)
        data.facing=pr.Position.X>=r.Position.X and 1 or -1
        local slot=Director.Assign(director,model,target,r.Position,pr.Position)
        local archetype=Archetypes.Id(data.kind,data.spec)
        local targetHumanoid=c.humanoid(target.Character)
        local observed=observe(data,target,c.records[target],t,profile.ReactionDelay,targetHumanoid and targetHumanoid.FloorMaterial==Enum.Material.Air)
        if archetype=="Warden" then
            local wasBlocking=data.blocking
            data.blocking=t>=(data.guardBrokenUntil or 0)
            if wasBlocking~=data.blocking then c.attributes(model,data)end
            if data.blocking then state(model,data,"Block");action(model,data,"Block") end
        end
        if archetype=="Leaper" and observed.action=="Heavy" and observed.attackAt~=data.lastObservedHeavy then
            data.lastObservedHeavy=observed.attackAt;data.observedHeavies=(data.observedHeavies or 0)+1
            if DifficultyPolicy.Evade(data,profile) then
                data.evadeUntil=t+.5;data.invulnerableUntil=math.max(data.invulnerableUntil or 0,t+.35)
                r.AssemblyLinearVelocity=Vector3.new(-data.facing*26,24,0)
                Director.Release(director,model);data.engaging=false
                c.fx("EnemyEvade",r.Position,{targetModel=model,duration=.5,direction=-data.facing,enemy=data.kind,moveId="LeaperEvade"})
            end
        end
        if t<(data.evadeUntil or 0) then state(model,data,"Evade");action(model,data,"Evade");h:Move(Vector3.zero);continue end
        if (archetype=="Pitcher" and distance<12) or t<(data.retreatUntil or 0) then
            state(model,data,"Retreat");action(model,data,"Retreat");Director.Release(director,model);data.engaging=false
            local away=r.Position.X>=pr.Position.X and 1 or -1
            h.WalkSpeed=data.spec.Speed
            h:MoveTo(Vector3.new(math.clamp(pr.Position.X+away*17,c.arena.MinX+6,c.arena.MaxX-6),r.Position.Y,math.clamp(pr.Position.Z+(slot.serial%2==0 and 3 or -3),-11,11)))
            if archetype~="Pitcher" or t<data.attackAt or distance>7 then continue end
            -- A cornered ranged enemy can shove rather than retreat forever against a bound.
        end
        local pattern=data.phase==2 and data.spec.PhaseMoves or data.spec.Moves
        local moveName=pattern and pattern[data.moveIndex%#pattern+1] or "Melee"
        if not elite then moveName=Archetypes.Select(archetype,distance,observed,data.moveIndex)
        else
            if not data.plannedMove or data.planTarget~=target or t>=(data.planUntil or 0) then
                local lanePlayers=0
                for _,p in ipairs(alive)do local other=c.root(p.Character);if other and math.abs(other.Position.Z-pr.Position.Z)<=5 then lanePlayers+=1 end end
                data.plannedMove=EnemyAI.ChooseEliteMove(data.spec,data,{distance=distance,lanePlayers=lanePlayers,airborne=observed.airborne,time=t},data.aiRng and data.aiRng:NextNumber() or .5)
                data.planTarget=target;data.planUntil=t+1
            end
            moveName=data.plannedMove
        end
        local range=not elite and (ranges[moveName] or data.spec.Reach-1) or (closeMoves[moveName] and data.spec.Reach or 65)
        local token=director.tokens[model]
        if token and token.target~=target then Director.Release(director,model);token=nil;data.engaging=false end
        local inRange=(not c.CanAttack or c.CanAttack(model)) and distance<=range and (elite or (math.abs(pr.Position.Z-r.Position.Z)<=3 and (r.Position.X-pr.Position.X)*slot.offset.X>0))
        if token and inRange and t>=data.attackAt then
            data.engaging=false;data.lastAttackAt=t;state(model,data,"Attack")
            c.beginEnemyAttack(model,data,target,moveName,alive)
        else
            local destination
            if token then
                data.engaging=true;state(model,data,"Engage")
                destination=Vector3.new(pr.Position.X+(slot.offset.X<0 and -1 or 1)*(archetype=="Pitcher" and 17 or 4),r.Position.Y,pr.Position.Z)
            else
                data.engaging=false
                local offset=archetype=="Pitcher" and Vector3.new(slot.offset.X<0 and -17 or 17,0,slot.offset.Z*.4) or slot.offset
                local goal=pr.Position+offset
                local nearSlot=(Vector3.new(goal.X,0,goal.Z)-Vector3.new(r.Position.X,0,r.Position.Z)).Magnitude<4
                state(model,data,nearSlot and "Hold" or "Approach")
                if nearSlot then
                    -- Continuously change lane and range while waiting, never a stationary queue.
                    goal+=Vector3.new(math.sin(t*2.1+slot.serial)*2.5,0,math.sin(t*1.6+slot.serial)*3)
                    if t>=(data.feintAt or t+1) then
                        data.feintAt=t+4+slot.serial%3
                        c.fx("EnemyFeint",r.Position,{targetModel=model,duration=.35,direction=data.facing,enemy=data.kind})
                    end
                    data.feintAt=data.feintAt or t+2+slot.serial%3
                end
                destination=Vector3.new(goal.X,r.Position.Y,goal.Z)
                if t>=data.attackAt and distance<=(elite and range or 20) then
                    local facing=c.records[target].facing or 1
                    local behind=(r.Position.X-pr.Position.X)*facing<0
                    Director.Request(director,model,target,behind,data.lastAttackAt,t)
                    candidates[model]={target=target,move=moveName,inRange=inRange}
                end
            end
            -- Cross through a neighboring lane before closing the opposite-side slot.
            if (r.Position.X-pr.Position.X)*slot.offset.X<0 and math.abs(r.Position.X-pr.Position.X)<10 then
                destination=Vector3.new(destination.X,r.Position.Y,pr.Position.Z+(slot.serial%2==0 and 6 or -6))
            end
            destination=Vector3.new(math.clamp(destination.X,c.arena.MinX+6,c.arena.MaxX-6),r.Position.Y,math.clamp(destination.Z,-11,11))
            h.WalkSpeed=data.spec.Speed;h:MoveTo(destination)
        end
    end
    for _,model in ipairs(Director.Grant(director,t,Director.Cap(#alive,profile.TokenBonus)))do
        local candidate,data=candidates[model],c.enemies[model]
        if candidate and data then
            data.engaging=true
            if candidate.inRange then
                data.engaging=false;data.lastAttackAt=t;state(model,data,"Attack")
                c.beginEnemyAttack(model,data,candidate.target,candidate.move,alive)
            end
        else Director.Release(director,model)end
    end
end
return EnemyAI
