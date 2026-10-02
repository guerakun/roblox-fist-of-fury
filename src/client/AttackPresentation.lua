-- Local anticipation budget and accepted-event reconciliation; never authorizes a hit.
local Ledger={};Ledger.__index=Ledger
function Ledger.new(config)return setmetatable({config=config,nextId=0,life=0,cooldowns={},pending={},busyUntil=0,lastAccepted=0,combo=0,lastLight=-100},Ledger)end
function Ledger:Reset(life)
    self.life=life or 0;self.cooldowns={};self.pending={};self.busyUntil=0;self.serverBusyUntil=0;self.state={};self.latestPrediction=nil;self.lastAccepted=0;self.combo=0;self.lastLight=-100
end
function Ledger:Update(state,time)
    if type(state.actorLife)=="number"and state.actorLife~=self.life then self:Reset(state.actorLife)end
    self.state=state
    local deadline=state.busyUntil
    self.serverBusyUntil=type(deadline)=="number"and deadline==deadline and math.abs(deadline)<math.huge
        and deadline or time+math.max(0,tonumber(state.busyRemaining)or 0)
end
function Ledger:Spec(action)
    if action=="Dash"then return {Cooldown=1.4,ActionDuration=(self.config.Dash and self.config.Dash.AnimationDuration)or .30}end
    if action=="Desperation"or action=="Special"then
        local hero=self.config.Characters[(self.state or {}).hero]
        return hero and hero.Special
    end
    return self.config.Attacks[action]
end
function Ledger:Predict(action,time)
    local state=self.state or {};local spec=self:Spec(action)
    if not spec or state.downed or state.grabbed or state.travelLocked then return nil end
    if action~="Dash"and state.status~="Combat"then return nil end
    local cooldown=action=="Desperation"and time+(state.desperationCooldown or 0)or ((state.cooldowns or {})[action]or 0)
    if time<math.max(self.busyUntil,self.serverBusyUntil or 0) or time<math.max(self.cooldowns[action]or 0,cooldown)then return nil end
    local duration=spec.ActionDuration or (action=="Special"or action=="Desperation")and(spec.Windup+.48)or spec.Cooldown
    self.nextId=self.nextId%2147483647+1
    local combo=self.combo
    if action=="Light"then combo=time-self.lastLight<.9 and self.combo%3+1 or 1;self.combo=combo;self.lastLight=time end
    local pose=action=="Desperation"and"Special"or action
    if pose=="Light"and combo%2==0 then pose="Light2"end
    local item={requestId=self.nextId,actorLife=self.life,action=pose,startAt=time,duration=duration,combo=combo,predicted=true}
    for id,old in pairs(self.pending)do if time-old.startAt>2 then self.pending[id]=nil end end
    self.pending[item.requestId]=item;self.latestPrediction=item
    self.busyUntil=time+duration;self.cooldowns[action]=time+(action=="Desperation"and 4 or spec.Cooldown)
    return item
end
function Ledger:Echo(event,time)
    if type(event.actorLife)=="number"and event.actorLife~=self.life then return nil,"OldLife"end
    if type(event.attackId)=="number"then
        if event.attackId<=self.lastAccepted then return nil,"Duplicate"end
        self.lastAccepted=event.attackId
    end
    if event.action=="Light"and type(event.combo)=="number"then self.combo=event.combo;self.lastLight=event.startAt or time end
    local old=event.requestId and self.pending[event.requestId]
    local matched=old and old.actorLife==event.actorLife
    if event.requestId then self.pending[event.requestId]=nil end
    local action=event.kind=="Dash"and"Dash"or event.action
    if action=="Light"and(event.combo or 1)%2==0 then action="Light2"end
    local spec=self:Spec(event.action or action)
    local serverStart=tonumber(event.startAt)or time
    local start=matched and math.min(serverStart,old.startAt)or serverStart
    local duration=tonumber(event.duration)or(spec and(spec.ActionDuration or spec.Cooldown))or .4
    self.serverBusyUntil=math.max(self.serverBusyUntil or 0,serverStart+duration)
    local requested=event.requestedAction or (event.kind=="Dash"and"Dash"or event.action)
    if requested and spec then
        self.cooldowns[requested]=math.max(self.cooldowns[requested]or 0,serverStart+(requested=="Desperation"and 4 or spec.Cooldown))
        if requested=="Desperation"then self.cooldowns.Special=math.max(self.cooldowns.Special or 0,serverStart+spec.Cooldown)end
    end
    local latest=self.latestPrediction
    if latest and latest~=old and latest.startAt>start and time<latest.startAt+latest.duration then return nil,"Superseded"end
    if time-start>=duration then return nil,"Expired"end
    return {action=action,startAt=start,duration=duration,matched=matched==true,requestId=event.requestId}
end
return Ledger
