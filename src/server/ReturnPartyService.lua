-- Server records authorize return-party restoration; client payloads never supply membership.
local Return={}
Return.__index=Return
local function copy(v)if type(v)~='table'then return v end local t={}for k,x in pairs(v)do t[k]=copy(x)end return t end
function Return.new(adapter,options)
    options=options or{}
    return setmetatable({a=adapter,clock=options.clock or os.time,server=options.server or game.JobId,guid=options.guid or function()return game.HttpService:GenerateGUID(false)end},Return)
end
function Return:Create(match,members)
    local id=self.guid()local allowed={}
    for _,uid in ipairs(members)do assert(table.find(match.members,uid),'foreign return member')allowed[uid]=true end
    local parties={}
    for _,p in ipairs(match.parties)do
        local ps={}for _,uid in ipairs(p.members)do if allowed[uid]then table.insert(ps,uid)end end
        if #ps>0 then table.insert(parties,{id=self.guid(),members=ps,leader=table.find(ps,p.leader)and p.leader or ps[1]})end
    end
    local sources={}for _,p in ipairs(match.parties)do table.insert(sources,p.id)end
    local record={id=id,created=self.clock(),matchId=match.id,members=copy(members),parties=parties,sourceParties=sources}
    self.a:Set('Return:'..id,record,600)
    return record
end
function Return:Restore(userId,joinData)
    local data=type(joinData)=='table'and joinData.TeleportData
    local id=type(data)=='table'and data.returnId
    if type(id)~='string'or #id>80 then return false,'no return record'end
    local record=self.a:Get('Return:'..id)
    if not record or self.clock()-record.created>600 or not table.find(record.members,userId)then return false,'invalid return membership'end
    local selected
    for _,party in ipairs(record.parties)do if table.find(party.members,userId)then selected=party break end end
    if not selected then return false,'missing return party'end
    -- First arrival binds this party to one hub server; other servers fail closed into solo parties.
    local bound=self.a:Update('ReturnBind:'..selected.id,function(old)return old or{server=self.server}end,600)
    local existing=self.a:Get('Party:'..selected.id)
    local separate=not bound or bound.server~=self.server or (existing and existing.status~='Idle')
    if separate then
        -- Delayed arrivals must not mutate a roster whose leader already queued.
        local fallback=self.a:Update('ReturnSolo:'..id..':'..userId,function(old)return old or{id=self.guid()}end,600)
        selected={id=fallback.id,leader=userId,members={userId}}
    end
    local party=self.a:Update('Party:'..selected.id,function(old)
        if old then return old end
        return {id=selected.id,leader=userId,members={},server=self.server,status='Idle',revision=1,created=self.clock(),invites={}}
    end,600)
    if not party or party.server~=self.server then return false,'return party unavailable'end
    -- Only replace the previous campaign membership, or an already restored identical membership.
    local member=self.a:Update('Member:'..userId,function(old)
        if old and old.partyId and old.partyId~=selected.id then
            -- Source party IDs are retained in the authoritative return record.
            local source=false for _,p in ipairs(record.sourceParties or{})do if p==old.partyId then source=true end end
            if not source then return old end
        end
        return {partyId=selected.id}
    end,600)
    if not member or member.partyId~=selected.id then return false,'newer party membership retained'end
    local wrote,result=pcall(function()return self.a:Update('Party:'..selected.id,function(old)
        if not old or old.server~=self.server or old.status~='Idle' then return old end
        old=copy(old)if not table.find(old.members,userId)then table.insert(old.members,userId)old.revision+=1 end
        if userId==selected.leader then old.leader=userId end return old
    end,600)end)
    if not wrote then
        local readOK,actual=pcall(function()return self.a:Get('Party:'..selected.id)end)
        if not readOK then error('return membership outcome uncertain; retry retained claim')end
        result=actual
    end
    if not result or not table.find(result.members,userId)then
        self.a:Update('Member:'..userId,function(old)if old and old.partyId==selected.id then return {partyId=false}end return old end,600)
        error('return party changed; retry restoration')
    end
    return true,result,separate and 'Your party already departed or returned elsewhere. You have a new refuge party.'or nil
end
return Return
