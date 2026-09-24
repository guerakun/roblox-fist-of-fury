-- Pure admission/arrival policy. TeleportData is only a lookup key.
local Admission={}
Admission.__index=Admission
function Admission.new(service,options)
    options=options or{}
    return setmetatable({service=service,clock=options.clock or os.time,privateId=options.privateId,timeout=options.timeout or 30,arrived={},match=nil,firstAt=nil},Admission)
end
function Admission:Admit(userId,joinData)
    local payload=type(joinData)=='table' and joinData.TeleportData
    local id=type(payload)=='table' and payload.matchId
    if type(id)~='string' or #id>80 then return false,'A refuge deployment is required.'end
    if self.match and self.match.id~=id then return false,'Different deployment.'end
    local match,reason=self.service:ValidateJoin(userId,id,self.privateId)
    if not match then return false,reason end
    if match.failed and match.failed[tostring(userId)]then return false,'This deployment was cancelled for this member.'end
    -- A yielding lookup may race another first arrival; recheck after the lookup.
    if self.match and self.match.id~=match.id then return false,'Different deployment.'end
    self.match=self.match or match self.firstAt=self.firstAt or self.clock()
    self.arrived[userId]=true
    return true,match
end
function Admission:Remove(userId)self.arrived[userId]=nil if not next(self.arrived)then self.firstAt=nil end end
function Admission:Ready()
    if not self.match or not next(self.arrived)then return false end
    if self.clock()-self.firstAt>=self.timeout then return true,'arrival timeout'end
    for _,uid in ipairs(self.match.members)do
        if not self.arrived[uid] and not (self.match.failed and self.match.failed[tostring(uid)])then return false end
    end
    return true,'all arrived'
end
return Admission
