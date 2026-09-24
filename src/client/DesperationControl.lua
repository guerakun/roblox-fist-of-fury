-- Explicit local gestures only. The server validates eligibility and applies every cost.
local Control={}
Control.__index=Control
Control.TouchHold=.35
function Control.new(options)
    return setmetatable({send=options.send,blocked=options.blocked,clock=options.clock or os.clock,state={},armed=false,
        spent=false,touchStart=nil},Control)
end
function Control:Available()
    local state=self.state
    local cost=state.desperationCost
    return state.canDesperation==true and state.status=="Combat"and state.downed~=true and state.travelLocked~=true
        and type(cost)=="number"and cost==cost and cost>=0 and cost<math.huge
        and (tonumber(state.desperationCooldown)or 0)<=0 and not self.blocked()
end
function Control:Reset()
    self.armed=false self.spent=false self.touchStart=nil
end
function Control:Update(state)
    self.state=state
    if not self:Available()then self:Reset()end
end
function Control:Fire()
    if self.spent or not self:Available()then return false end
    self.spent=true self.send()return true
end
function Control:Handle(action,inputState)
    if action=="Special"and(inputState==Enum.UserInputState.End or inputState==Enum.UserInputState.Cancel)then
        local armed=self.armed self:Reset()return armed
    end
    if inputState~=Enum.UserInputState.Begin then return false end
    if action=="Special"and self:Available()then
        if not self.armed then self.armed=true self.spent=false end
        return true
    end
    if action=="Heavy"and self.armed then self:Fire()return true end
    return false
end
function Control:TouchBegin()
    if self.touchStart~=nil or not self:Available()then return false end
    self:Reset()self.touchStart=self.clock()return true
end
function Control:TouchEnd()self:Reset()end
function Control:CancelTouch()
    self.touchStart=nil
    if not self.armed then self.spent=false end
end
function Control:Step()
    if not self:Available()then self:Reset()return 0 end
    if self.touchStart==nil then return 0 end
    local progress=math.clamp((self.clock()-self.touchStart)/Control.TouchHold,0,1)
    if progress>=1 then self:Fire()end
    return progress
end
return Control
