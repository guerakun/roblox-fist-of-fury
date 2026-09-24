-- Pure atomic registry. Visuals, actor/life validation and gameplay effects stay with the server owner.
local Registry={}
Registry.__index=Registry
local function finite(n)return type(n)=="number"and n==n and math.abs(n)<math.huge end
function Registry.new(runId)
    assert(type(runId)=="string"and #runId>0,"Run identity required")
    return setmetatable({runId=runId,records={},used={},usedCount=0,count=0,serial=0},Registry)
end
function Registry:Spawn(id,kind,position,expiresAt,payload)
    if type(id)~="string"or #id<1 or #id>160 or self.used[id]or self.usedCount>=1024 or self.count>=64
        or type(kind)~="string"or #kind<1 or #kind>32 or not finite(expiresAt)or expiresAt<0
        or typeof(position)~="Vector3"or not finite(position.X)or not finite(position.Y)or not finite(position.Z)then return nil end
    self.serial+=1
    local record={id=id,kind=kind,position=position,expiresAt=expiresAt,payload=payload,
        generation=self.serial,runId=self.runId,claimed=false}
    self.records[id]=record;self.used[id]=true;self.usedCount+=1;self.count+=1
    return record
end
function Registry:Claim(id,generation,t,actorId,distance,eligible,radius,expectedRunId)
    local record=self.records[id]
    if radius==nil then radius=5 end
    if not finite(radius)or radius<0 then return nil end
    if expectedRunId~=self.runId or not record or record.generation~=generation or not finite(t)or t>=record.expiresAt
        or eligible~=true or not finite(distance)or distance<0 or distance>radius
        or type(actorId)~="number"or actorId~=actorId or math.abs(actorId)==math.huge or actorId%1~=0 then return nil end
    -- This transition happens before any gameplay callback or potentially yielding grant.
    record.claimed=true;record.claimant=actorId
    self.records[id]=nil;self.count-=1
    return record
end
function Registry:Remove(id,generation,expectedRunId)
    local record=self.records[id]
    if expectedRunId~=self.runId or not record or generation~=record.generation then return nil end
    self.records[id]=nil;self.count-=1
    return record
end
function Registry:Sweep(t)
    local expired={}
    for id,record in pairs(self.records)do
        if t>=record.expiresAt then table.insert(expired,self:Remove(id,record.generation,self.runId))end
    end
    return expired
end
function Registry:Clear()
    local removed={}
    for id,record in pairs(self.records)do table.insert(removed,record);self.records[id]=nil end
    self.count=0
    -- Used identities survive stage/retry cleanup. A new run receives a new registry.
    return removed
end
return Registry
