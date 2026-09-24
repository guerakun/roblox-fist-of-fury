-- Pure observational windows. Only actual actions enter the set; movement toward a slot is excluded.
local Diversity={}
function Diversity.New(observer)
    return {actors={},byKind={},windows={},partialWindows=0,observer=observer}
end
local function finish(state,actor,complete)
    local window=state.actors[actor]
    if not window then return end
    if complete then
        local actions={};for action in pairs(window.actions)do table.insert(actions,action)end;table.sort(actions)
        local summary=state.byKind[window.kind] or {eligible=0,passed=0,minDistinct=false}
        state.byKind[window.kind]=summary
        summary.eligible+=1;if #actions>=2 then summary.passed+=1 end
        summary.minDistinct=summary.minDistinct and math.min(summary.minDistinct,#actions) or #actions
        local result={kind=window.kind,start=window.start,duration=30,actions=actions,passed=#actions>=2}
        if state.observer then result.actorAlias,result.opportunity=state.observer.Finish(actor,true)end
        table.insert(state.windows,result)
    else
        state.partialWindows+=1
        if state.observer then state.observer.Finish(actor,false)end
    end
    state.actors[actor]=nil
end
function Diversity.Engage(state,actor,kind,t)
    local window=state.actors[actor]
    if window and t-window.start>=30 then
        finish(state,actor,true);window=nil
    end
    if not window then
        state.actors[actor]={kind=kind,start=t,last=t,actions={}}
        if state.observer then state.observer.Begin(actor,t)end
    else window.last=t end
end
function Diversity.Action(state,actor,kind,action,t)
    if action=="Approach" or action=="Hold" or action=="Engage" or action=="Enter" or action=="Reposition" then return end
    Diversity.Engage(state,actor,kind,t)
    state.actors[actor].actions[action]=true
end
function Diversity.Leave(state,actor,t)
    local window=state.actors[actor]
    if window then finish(state,actor,math.min(t,window.last)-window.start>=30)end
    if state.observer then state.observer.Depart(actor)end
end
function Diversity.Flush(state,t)
    local actors={};for actor in pairs(state.actors)do table.insert(actors,actor)end
    for _,actor in ipairs(actors)do Diversity.Leave(state,actor,t)end
end
function Diversity.Summary(state)
    local pending=0;for _ in pairs(state.actors)do pending+=1 end
    return {windowSeconds=30,byKind=state.byKind,windows=state.windows,partialWindows=state.partialWindows,pendingWindows=pending,
        policy="10Hz sampled proximity within 28 studs; actual attacks/block/evade/retreat/grab/throw; partial windows ineligible"}
end
return Diversity
