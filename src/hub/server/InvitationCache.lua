-- Ephemeral display invitations; MatchmakingService independently authorizes acceptance.
local Cache={}
Cache.__index=Cache
function Cache.new(now)return setmetatable({entries={},now=now or os.time},Cache)end
function Cache:Prune(userId)
    local list=self.entries[userId]if not list then return end
    for id,info in pairs(list)do if info.expires<=self.now()then list[id]=nil end end
    if not next(list)then self.entries[userId]=nil end
end
function Cache:Add(userId,partyId,name)
    self:Prune(userId)
    local list=self.entries[userId]or{}self.entries[userId]=list
    local count,oldest,expires=0,nil,math.huge
    for id,info in pairs(list)do count+=1 if info.expires<expires then oldest=id expires=info.expires end end
    if count>=32 and not list[partyId]then list[oldest]=nil end
    list[partyId]={name=name,expires=self.now()+60}
end
function Cache:List(userId)self:Prune(userId)return self.entries[userId]or{}end
function Cache:Accept(userId,partyId)local list=self.entries[userId]if list then list[partyId]=nil end self:Prune(userId)end
function Cache:Remove(userId)self.entries[userId]=nil end
function Cache:Sweep()for id in pairs(self.entries)do self:Prune(id)end end
return Cache
