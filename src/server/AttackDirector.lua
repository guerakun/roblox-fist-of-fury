-- Server-owned engagement positions and a party-wide windup budget.
local Director = {}
local offsets = {{5,0},{-5,0},{10,0},{-10,0},{12,8},{-12,-8}}
function Director.New() return {slots={},tokens={},requests={},lastGranted={},serial=0} end
function Director.CountActive(enemies, now)
    local count=0
    for _,data in pairs(enemies)do if data.attacking and now()<data.resolveAt then count+=1 end end
    return count
end
function Director.Cap(aliveCount, bonus) return math.max(0,aliveCount)+1+(bonus or 0) end
function Director.Release(state, model) state.tokens[model]=nil end
function Director.BeginAttack(state,model,t,recoveryUntil)
    local token=state.tokens[model]
    if token then token.expires=math.max(t+3,recoveryUntil+.05) end
end
function Director.Reset(state) table.clear(state.slots);table.clear(state.tokens);table.clear(state.requests);table.clear(state.lastGranted) end
function Director.Sync(state,enemies,alive,t)
    local targets, cancelled={},{};for _,p in ipairs(alive)do targets[p]=true end
    for model,slot in pairs(state.slots)do
        if not enemies[model] or not targets[slot.target] then
            local data=enemies[model]
            if data then
                data.engaging=false
                if data.attacking then
                    -- Invalidate the captured resolver before handing its token to another actor.
                    data.attacking=false;data.attackSerial+=1;data.resolveAt=t;data.armoredUntil=0
                    table.insert(cancelled,model)
                end
            end
            state.slots[model]=nil;state.tokens[model]=nil
        end
    end
    for model in pairs(state.lastGranted)do if not enemies[model]then state.lastGranted[model]=nil end end
    for model,token in pairs(state.tokens)do
        local data=enemies[model]
        if not data or t>=token.expires or ((t<data.stunnedUntil or (data.spec.Role=="Grunt" and t<data.launchedUntil)) and t>=(data.armoredUntil or 0)) or (not data.attacking and not data.engaging) then state.tokens[model]=nil end
    end
    table.clear(state.requests)
    return cancelled
end
function Director.Assign(state,model,target,origin,targetPosition,arena,positionAllowed)
    local existing=state.slots[model]
    local function feasible(offsetX,offsetZ)
        if arena and (targetPosition.X+offsetX<arena.MinX+6 or targetPosition.X+offsetX>arena.MaxX-6)then return false end
        return not positionAllowed or positionAllowed(Vector3.new(targetPosition.X+offsetX,origin.Y,math.clamp(targetPosition.Z+(offsetZ or 0),-11,11)))
    end
    if existing and existing.target==target and feasible(existing.offset.X,existing.offset.Z) then
        existing.approachFeasible=feasible(existing.offset.X<0 and -4 or 4,0)
        return existing
    end
    state.slots[model]=nil
    local occupied,left,right={},0,0
    for _,slot in pairs(state.slots)do if slot.target==target then
        occupied[slot.index]=true
        if slot.offset.X<0 then left+=1 else right+=1 end
    end end
    local best,bestScore
    for i,offset in ipairs(offsets)do if not occupied[i] and feasible(offset[1],offset[2]) then
        local delta=Vector3.new(offset[1],0,offset[2])
        -- Favor filling the other side before minimizing walking distance.
        local crowd=offset[1]<0 and left or right
        local score=(targetPosition+delta-origin).Magnitude+crowd*35
        if not bestScore or score<bestScore then best,bestScore=i,score end
    end end
    state.serial+=1
    local offset
    if best then offset=Vector3.new(offsets[best][1],0,offsets[best][2])
    else
        best=6+state.serial
        local side=left<=right and -1 or 1
        if not feasible(side*14)then
            if feasible(-side*14)then side=-side else side=origin.X<targetPosition.X and -1 or 1 end
        end
        offset=Vector3.new(side*14,0,state.serial%2==0 and 10 or -10)
    end
    local slot={target=target,index=best,offset=offset,serial=state.serial,approachFeasible=feasible(offset.X<0 and -4 or 4,0)}
    state.slots[model]=slot
    return slot
end
function Director.Request(state,model,target,behind,lastAttack,t)
    local slot=state.slots[model]
    table.insert(state.requests,{model=model,target=target,
        priority=(behind and 4 or 0)+math.min(30,t-math.max(lastAttack or 0,state.lastGranted[model] or 0)),serial=slot and slot.serial or 0})
end
function Director.Trim(state,cap)
    local ordered={}
    for model,token in pairs(state.tokens)do table.insert(ordered,{model=model,serial=token.serial})end
    table.sort(ordered,function(a,b)return a.serial<b.serial end)
    local removed={}
    for i=cap+1,#ordered do local model=ordered[i].model;state.tokens[model]=nil;table.insert(removed,model)end
    return removed
end
function Director.Grant(state,t,cap)
    local count=0;for _ in pairs(state.tokens)do count+=1 end
    table.sort(state.requests,function(a,b)
        if a.priority==b.priority then return a.serial<b.serial end
        return a.priority>b.priority
    end)
    local granted={}
    for _,request in ipairs(state.requests)do
        if count>=cap then break end
        if not state.tokens[request.model] then
            state.tokens[request.model]={target=request.target,expires=t+3,serial=request.serial}
            state.lastGranted[request.model]=t
            table.insert(granted,request.model);count+=1
        end
    end
    table.clear(state.requests)
    return granted
end
return Director
