-- MemoryStore record/queue adapter. Never contacts cloud storage in Studio.
local Adapter={}
Adapter.__index=Adapter
local function clone(v)if type(v)~='table'then return v end local r={}for k,x in pairs(v)do r[k]=clone(x)end return r end
function Adapter.new(options)
    options=options or {}
    local self=setmetatable({studio=game:GetService('RunService'):IsStudio(),onReady=options.onReady,
        places=options.places or require(game.ReplicatedStorage.Nightfall.Shared.PlaceIds),localRecords={},localQueues={}},Adapter)
    if not self.studio then
        self.store=game:GetService('MemoryStoreService'):GetHashMap('CurtainBreakMatchRecords_v1')
    end
    return self
end
function Adapter:Get(key)
    if not self.studio then return self.store:GetAsync(key) end
    local r=self.localRecords[key] if r and r.expires>os.time() then return clone(r.value) end return nil
end
function Adapter:Set(key,value,ttl)
    if not self.studio then return self.store:SetAsync(key,value,ttl) end
    self.localRecords[key]={value=clone(value),expires=os.time()+ttl}
end
function Adapter:Update(key,fn,ttl)
    if not self.studio then return self.store:UpdateAsync(key,fn,ttl) end
    local old=self:Get(key) local value=fn(old)
    if value~=nil then self:Set(key,value,ttl) return clone(value) end return old
end
function Adapter:_queue(difficulty)
    return game:GetService('MemoryStoreService'):GetSortedMap('CurtainBreakQueue_'..difficulty..'_v1')
end
function Adapter:PutQueue(difficulty,ticket,ttl)
    if not self.studio then return self:_queue(difficulty):SetAsync(ticket.partyId,ticket,ttl,ticket.queuedAt) end
    self.localQueues[difficulty]=self.localQueues[difficulty]or{}
    self.localQueues[difficulty][ticket.partyId]={value=clone(ticket),expires=os.time()+ttl}
end
function Adapter:ListQueue(difficulty,count)
    local out={}
    if not self.studio then
        for _,row in ipairs(self:_queue(difficulty):GetRangeAsync(Enum.SortDirection.Ascending,count)) do if not row.value.removed then table.insert(out,row.value) end end
    else
        for _,row in pairs(self.localQueues[difficulty]or{}) do if row.expires>os.time() then table.insert(out,clone(row.value)) end end
        table.sort(out,function(a,b)return a.queuedAt==b.queuedAt and a.partyId<b.partyId or a.queuedAt<b.queuedAt end)
        while #out>count do table.remove(out) end
    end
    return out
end
function Adapter:RemoveQueue(difficulty,id,revision)
    if not self.studio then
        -- Atomic tombstone sorted after all live tickets; never erase a newer queued revision.
        return self:_queue(difficulty):UpdateAsync(id,function(old,sortKey)
            if old and old.revision==revision then return {removed=true,revision=revision},1e15 end
            return old,sortKey
        end,600)
    end
    local queue=self.localQueues[difficulty]
    if queue and queue[id] and queue[id].value.revision==revision then queue[id]=nil end
end
function Adapter:Reserve()
    if self.studio then local id=game.HttpService:GenerateGUID(false) return 'studio-access-'..id,'studio-private-'..id end
    assert(self.places.Campaign>0,'Campaign place is not configured')
    return game:GetService('TeleportService'):ReserveServerAsync(self.places.Campaign)
end
function Adapter:Dispatch(match)
    -- Messages contain only a lookup ID; receivers fetch authoritative records themselves.
    if self.onReady then self.onReady(match.id) end
    if not self.studio then game:GetService('MessagingService'):PublishAsync('CurtainBreakMatchReady_v1',{matchId=match.id}) end
end
function Adapter:Subscribe()
    if self.studio then return nil end
    return game:GetService('MessagingService'):SubscribeAsync('CurtainBreakMatchReady_v1',function(message)
        local data=message.Data
        if type(data)=='table' and type(data.matchId)=='string' and #data.matchId<=80 and self.onReady then self.onReady(data.matchId) end
    end)
end
return Adapter
