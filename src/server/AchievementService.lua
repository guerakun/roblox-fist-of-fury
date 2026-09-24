-- Dependency-injected badge adapter. No Roblox service calls occur in this module.
-- adapter.Has(userId,badgeId) and adapter.Award(userId,badgeId) must return boolean.
-- Profile earned achievements are separate from this external-issuance cache.
local Service = {}
Service.__index = Service
local function id(n)
    return type(n)=="number" and n==n and n%1==0 and n>0 and n<=9007199254740991
end
function Service.new(adapter,ids)
    assert(type(adapter)=="table" and type(ids)=="table","badge adapter/config required")
    return setmetatable({adapter=adapter,ids=ids,succeeded={},inFlight={}},Service)
end
function Service:Award(userId,key)
    if not id(userId) or type(key)~="string" then return false,"invalid" end
    local definition=self.ids[key]
    if definition==nil then return false,"unknown" end
    local badgeId=type(definition)=="table" and definition.BadgeId or definition
    if badgeId==0 then return false,"unconfigured" end
    if not id(badgeId) then return false,"invalid" end
    local token=tostring(userId)..":"..tostring(badgeId)
    if self.succeeded[token] then return true,"cached" end
    if self.inFlight[token] then return false,"inFlight" end
    if type(self.adapter.Has)~="function" or type(self.adapter.Award)~="function" then return false,"adapter" end
    local pending={userId=userId,forget=false}
    self.inFlight[token]=pending
    local ok,has=pcall(self.adapter.Has,userId,badgeId)
    if not ok or type(has)~="boolean" then self.inFlight[token]=nil return false,"hasFailed" end
    if has then
        if not pending.forget then self.succeeded[token]=userId end
        self.inFlight[token]=nil
        return true,"alreadyOwned"
    end
    local awarded,success=pcall(self.adapter.Award,userId,badgeId)
    self.inFlight[token]=nil
    if not awarded or success~=true then return false,"awardFailed" end
    if not pending.forget then self.succeeded[token]=userId end
    return true,"awarded"
end
function Service:Forget(userId)
    if not id(userId) then return false end
    for token,owner in pairs(self.succeeded) do if owner==userId then self.succeeded[token]=nil end end
    -- Keep pending guards alive across departure; only suppress their eventual cache entry.
    for _,pending in pairs(self.inFlight) do if pending.userId==userId then pending.forget=true end end
    return true
end
return Service
