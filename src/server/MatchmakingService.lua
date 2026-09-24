-- Server-only party/queue state machine. Adapter supplies atomic records and transport.
-- No client table is accepted as a roster, match, price, reward, or teleport destination.
local Service={}
Service.__index=Service
local function copy(v) if type(v)~='table' then return v end local r={} for k,x in pairs(v) do r[k]=copy(x) end return r end
local function contains(list,id) return table.find(list,id)~=nil end
local function validId(id) return type(id)=='number' and id%1==0 and id~=0 and math.abs(id)<1e16 end
function Service.new(adapter,options)
    options=options or {}
    return setmetatable({a=adapter,clock=options.clock or os.time,guid=options.guid or function()return game.HttpService:GenerateGUID(false)end,
        server=options.server or game.JobId,ttl=600,timeout=20},Service)
end
function Service:GetParty(id) return self.a:Get('Party:'..id) end
function Service:PartyFor(userId)
    local member=self.a:Get('Member:'..userId)
    return member and member.partyId and self:GetParty(member.partyId)
end
function Service:Create(userId)
    assert(validId(userId),'invalid member')
    local existing=self:PartyFor(userId) if existing and contains(existing.members,userId) then return existing end
    local previous=self.a:Get('Member:'..userId)
    if previous and previous.partyId and self:GetParty(previous.partyId) then return nil,'membership transition in progress' end
    local id=self.guid()
    local party={id=id,leader=userId,members={userId},revision=1,status='Idle',created=self.clock(),server=self.server,invites={}}
    -- Party first: failure leaves only an unreachable expiring record, never a broken member link.
    self.a:Set('Party:'..id,party,self.ttl)
    local member=self.a:Update('Member:'..userId,function(old)
        if old and old.partyId and (not previous or old.partyId~=previous.partyId) then return old end
        return {partyId=id}
    end,self.ttl)
    if member.partyId~=id then return self:PartyFor(userId) end
    return party
end
function Service:Invite(leader,target)
    assert(validId(target) and target~=leader,'invalid invite')
    local p=assert(self:PartyFor(leader),'party missing')
    local result=self.a:Update('Party:'..p.id,function(old)
        if not old or old.leader~=leader or old.status~='Idle' or #old.members>=4 then return old end
        old=copy(old) old.invites[tostring(target)]=self.clock()+60 return old
    end,self.ttl)
    return result and result.invites[tostring(target)]~=nil
end
function Service:Accept(userId,partyId)
    assert(validId(userId) and type(partyId)=='string' and #partyId<=80,'invalid acceptance')
    local p=self:GetParty(partyId)
    if not p or p.server~=self.server or p.status~='Idle' or #p.members>=4 or (p.invites[tostring(userId)] or 0)<self.clock() then return false end
    local current=self:PartyFor(userId)
    if current then if #current.members~=1 or current.status~='Idle' then return false end if not self:Leave(userId) then return false end end
    local member=self.a:Update('Member:'..userId,function(old) return old and old.partyId and old or {partyId=partyId} end,self.ttl)
    if member.partyId~=partyId then return false end
    local succeeded,joined=pcall(function() return self.a:Update('Party:'..partyId,function(old)
        if not old or old.status~='Idle' or #old.members>=4 or (old.invites[tostring(userId)] or 0)<self.clock() then return old end
        old=copy(old) if not contains(old.members,userId) then table.insert(old.members,userId) old.revision+=1 end
        old.invites[tostring(userId)]=nil return old
    end,self.ttl) end)
    if not succeeded then
        local readOK,actual=pcall(function()return self:GetParty(partyId)end)
        if not readOK then return false end -- Keep the claim until an authoritative read can reconcile it.
        joined=actual
    end
    if not joined or not contains(joined.members,userId) then
        self.a:Update('Member:'..userId,function(old) if old and old.partyId==partyId then return {partyId=false} end return old end,self.ttl)
        return false
    end
    return true
end
function Service:Leave(userId)
    local p=self:PartyFor(userId) if not p then return true end
    local changed=self.a:Update('Party:'..p.id,function(old)
        if not old or old.status=='Matching' or old.status=='Matched' then return old end
        old=copy(old) local i=table.find(old.members,userId) if i then table.remove(old.members,i) end
        old.revision+=1 old.status='Idle' old.queueAt=nil
        if old.leader==userId then old.leader=old.members[1] end return old
    end,self.ttl)
    if changed and contains(changed.members,userId) then return false end
    self.a:Update('Member:'..userId,function(old) if old and old.partyId==p.id then return {partyId=false} end return old end,self.ttl)
    -- Stale queue tickets are revision-invalidated; remove is a best-effort cleanup.
    return true
end
function Service:Queue(leader,difficulty,heat,mode)
    local allowed={Normal=true,Hard=true,Nightmare=true}
    assert(allowed[difficulty],'invalid difficulty')
    assert(type(heat)=='table' and #heat<=6,'invalid heat')
    -- Unlock/Heat validity is checked by the hub's server-owned configuration/profile gate.
    local normalized={} for _,id in ipairs(heat) do assert(type(id)=='string' and #id<=32,'invalid heat id') table.insert(normalized,id) end table.sort(normalized)
    local p=assert(self:PartyFor(leader),'party missing')
    local queued=self.a:Update('Party:'..p.id,function(old)
        if not old or old.leader~=leader or old.status~='Idle' or #old.members<1 or #old.members>4 then return old end
        old=copy(old) old.status='Queued' old.queueAt=self.clock() old.difficulty=difficulty old.heat=normalized old.mode=mode=='Solo' and 'Solo' or 'QuickMatch'
        old.revision+=1 return old
    end,self.ttl)
    if not queued or queued.status~='Queued' or queued.leader~=leader then return false end
    -- Record first, queue second: a throttle leaves a visible retryable Queued party.
    self.a:PutQueue(queued.difficulty,{partyId=queued.id,revision=queued.revision,queuedAt=queued.queueAt},self.ttl)
    return true
end
function Service:Cancel(leader)
    local p=self:PartyFor(leader) if not p then return false end
    local r=self.a:Update('Party:'..p.id,function(old)
        if not old or old.leader~=leader or old.status~='Queued' then return old end
        old=copy(old) old.status='Idle' old.revision+=1 old.queueAt=nil return old
    end,self.ttl)
    return r and r.status=='Idle'
end
function Service:Refresh(userId)
    local p=self:PartyFor(userId) if not p then return end
    self.a:Update('Member:'..userId,function(old)return old end,self.ttl)
    self.a:Update('Party:'..p.id,function(old)return old end,self.ttl)
    if p.status=='Queued' then self.a:PutQueue(p.difficulty,{partyId=p.id,revision=p.revision,queuedAt=p.queueAt},self.ttl)
    elseif p.matchId then local m=self.a:Get('Match:'..p.matchId) if m and m.status=='Ready' then self:Finalize(m) end end
end
function Service:Finalize(match)
    local errors={}
    for _,p in ipairs(match.parties) do
        local ok,err=pcall(function()
            self.a:Update('Party:'..p.id,function(old) if old and old.matchId==match.id then old=copy(old) old.status='Matched' end return old end,self.ttl)
            self.a:RemoveQueue(match.difficulty,p.id,p.revision)
        end)
        if not ok then table.insert(errors,tostring(err)) end
    end
    local ok,err=pcall(function()self.a:Dispatch(match)end)
    if not ok then table.insert(errors,tostring(err)) end
    return #errors==0,table.concat(errors,'; ')
end
function Service:Step(difficulty)
    local token=self.guid() local t=self.clock()
    local lease=self.a:Update('Lease:'..difficulty,function(old)
        if old and old.untilTime>t then return old end return {token=token,untilTime=t+30}
    end,60)
    if not lease or lease.token~=token then return nil,'leased' end
    local selected,total,heatKey={},0,nil
    for _,ticket in ipairs(self.a:ListQueue(difficulty,40)) do
        local p=self:GetParty(ticket.partyId)
        if p and (p.status=='Matching' or p.status=='Matched') then
            local pending=self.a:Get('Match:'..p.matchId)
            if pending and pending.status=='Ready' then
                self:Finalize(pending)
            elseif not pending or pending.status=='Aborted' or (pending.status=='Building' and pending.created+60<t) then
                self.a:Update('Match:'..p.matchId,function(old) if old and old.status=='Building' then old=copy(old) old.status='Aborted' end return old end,self.ttl)
                self.a:Update('Party:'..p.id,function(old) if old and (old.status=='Matching' or old.status=='Matched') and old.matchId==p.matchId then old=copy(old) old.status='Queued' old.matchId=nil end return old end,self.ttl)
            end
        elseif p and p.status=='Queued' and p.difficulty==difficulty and p.revision==ticket.revision and #p.members>0 then
            local key=table.concat(p.heat or {},',')
            if (not heatKey or key==heatKey) and total+#p.members<=4 then
                if p.mode=='Solo' and total>0 then continue end
                table.insert(selected,p) total+=#p.members heatKey=key
                if p.mode=='Solo' or total==4 then break end
            end
        else
            self.a:RemoveQueue(difficulty,ticket.partyId,ticket.revision)
        end
    end
    local first=selected[1]
    if not first or (total<4 and first.mode~='Solo' and t-first.queueAt<self.timeout) then
        self.a:Update('Lease:'..difficulty,function(old) if old and old.token==token then return {untilTime=0} end return old end,60)
        return nil,'waiting'
    end
    local id=self.guid()
    local match={id=id,status='Building',created=t,difficulty=difficulty,heat=copy(first.heat),members={},parties={},serverByMember={}}
    for _,p in ipairs(selected) do
        table.insert(match.parties,{id=p.id,leader=p.leader,members=copy(p.members),revision=p.revision})
        for _,uid in ipairs(p.members) do table.insert(match.members,uid) match.serverByMember[tostring(uid)]=p.server end
    end
    self.a:Set('Match:'..id,match,self.ttl)
    local claimed={}
    local worked,err=pcall(function()
        for _,p in ipairs(selected) do
            local r=self.a:Update('Party:'..p.id,function(old)
                if not old or old.status~='Queued' or old.revision~=p.revision then return old end
                old=copy(old) old.status='Matching' old.matchId=id return old
            end,self.ttl)
            assert(r and r.matchId==id and r.status=='Matching','party changed during claim') table.insert(claimed,p.id)
        end
        local accessCode,privateId=self.a:Reserve()
        local ready=self.a:Update('Match:'..id,function(old)
            if not old or old.status~='Building' then return old end
            old=copy(old) old.status='Ready' old.accessCode=accessCode old.privateServerId=privateId return old
        end,self.ttl)
        assert(ready and ready.status=='Ready','match reservation expired') match=ready
    end)
    if not worked then
        local readOK,durable=pcall(function()return self.a:Get('Match:'..id)end)
        if not readOK then return nil,'uncertain match write; claims retained for recovery' end
        if durable and durable.status=='Ready' then
            self:Finalize(durable)
            return durable
        end
        self.a:Update('Match:'..id,function(old) if old and old.status=='Building' then old=copy(old) old.status='Aborted' end return old end,self.ttl)
        for _,partyId in ipairs(claimed) do self.a:Update('Party:'..partyId,function(old) if old and old.matchId==id and old.status=='Matching' then old=copy(old) old.status='Queued' old.matchId=nil end return old end,self.ttl) end
        return nil,tostring(err)
    end
    -- Ready is durable before ticket removal/dispatch. Refresh and queue scans retry finalization.
    local dispatched,dispatchError=self:Finalize(match)
    self.a:Update('Lease:'..difficulty,function(old) if old and old.token==token then return {untilTime=0} end return old end,60)
    if dispatched then return match end
    return match,dispatchError
end
function Service:ValidateJoin(userId,matchId,privateServerId)
    if not validId(userId) or type(matchId)~='string' or #matchId>80 then return nil,'invalid join' end
    local m=self.a:Get('Match:'..matchId)
    if not m or m.status~='Ready' or self.clock()-m.created>self.ttl or not contains(m.members,userId) then return nil,'not a member of an active match' end
    if privateServerId~=m.privateServerId then return nil,'wrong reserved server' end
    return m
end
return Service
