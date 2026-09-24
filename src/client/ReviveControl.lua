-- Local hold lifecycle only. The server owns eligibility, progress and completion.
local Control={}
Control.__index=Control
function Control.new(send,blocked)
    return setmetatable({send=send,blocked=blocked,state={},heldTarget=nil,channelSeen=false},Control)
end
function Control:Available()
    local state=self.state
    local revive=state.revive
    return type(revive)=="table" and type(revive.targetUserId)=="number"
        and (revive.canStart==true or revive.channeling==true) and (tonumber(revive.remaining) or 0)>0
        and state.downed~=true and state.travelLocked~=true and state.status~="Waiting" and state.status~="Victory" and state.status~="Defeat"
end
function Control:Cancel()
    if self.heldTarget==nil then return false end
    self.heldTarget=nil self.channelSeen=false
    self.send("Revive",{held=false})
    return true
end
function Control:Begin()
    if self.heldTarget~=nil or self.blocked() or not self:Available() then return false end
    self.heldTarget=self.state.revive.targetUserId
    self.channelSeen=self.state.revive.channeling==true
    self.send("Revive",{held=true,targetUserId=self.heldTarget})
    return true
end
function Control:Update(state)
    self.state=state
    if self.heldTarget==nil then return end
    local revive=state.revive
    if self.blocked() or not self:Available() or revive.targetUserId~=self.heldTarget
        or (self.channelSeen and revive.channeling~=true) then self:Cancel() return end
    if revive.channeling==true then self.channelSeen=true end
end
return Control
