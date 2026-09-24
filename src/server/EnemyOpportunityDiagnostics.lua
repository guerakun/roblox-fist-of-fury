-- Observation only. No game services, movement decisions, or diversity eligibility changes.
local O={Revision="enemy-opportunity-v1",MaxActors=1024,MaxDetails=1024,MaxPending=64}
local events={tokenRequests=true,tokenGrants=true,grabAttempts=true,grabCaptures=true}
local function counts()
    return {sampledTicks=0,contextTicks=0,visible={known=0,yes=0},fixedSlotFeasible={known=0,yes=0},inRange={known=0,yes=0},
        tokenRequests=0,tokenGrants=0,grabAttempts=0,grabCaptures=0}
end
local function finite(t)return type(t)=="number" and t==t and math.abs(t)<math.huge end
function O.New()
    return {actors=setmetatable({},{__mode="k"}),allocated=0,details=0,actorCapReached=false,
        detailsDropped=0,pendingEventsDropped=0,unattributedEvents=0,invalidObservations=0}
end
local function actor(state,key)
    local record=state.actors[key]
    if not record then
        if state.allocated>=O.MaxActors then state.actorCapReached=true;return nil end
        state.allocated+=1;record={alias="Enemy"..state.allocated,pending={}}
        state.actors[key]=record
    end
    return record
end
function O.Alias(state,key)
    local record=actor(state,key);return record and record.alias or false
end
function O.Begin(state,key,start)
    local record=actor(state,key);if not record then return end
    record.window={start=start,counts=counts()}
    local retained={}
    for _,event in ipairs(record.pending)do
        if event.at<start then state.unattributedEvents+=1
        elseif event.at<start+30 then record.window.counts[event.name]+=1
        else table.insert(retained,event)end
    end
    record.pending=retained
end
function O.Context(state,key,t,fields)
    if not finite(t)or type(fields)~="table"then state.invalidObservations+=1;return end
    local record=actor(state,key);if not record then return end
    if not record.context or record.context.at~=t then record.context={at=t}end
    for _,name in ipairs({"visible","fixedSlotFeasible","inRange"})do
        if type(fields[name])=="boolean"then record.context[name]=fields[name]end
    end
end
function O.Event(state,key,name,t)
    if not events[name]or not finite(t)then state.invalidObservations+=1;return end
    local record=actor(state,key);if not record then return end
    local window=record.window
    if window and t>=window.start and t<window.start+30 then window.counts[name]+=1;return end
    if #record.pending>=O.MaxPending then state.pendingEventsDropped+=1;return end
    table.insert(record.pending,{name=name,at=t})
end
function O.Sample(state,key,t)
    local record=state.actors[key];local window=record and record.window
    if not window then return end
    local c=window.counts;c.sampledTicks+=1
    local context=record.context
    if context and context.at==t then
        c.contextTicks+=1
        for _,name in ipairs({"visible","fixedSlotFeasible","inRange"})do
            if type(context[name])=="boolean"then
                c[name].known+=1;if context[name]then c[name].yes+=1 end
            end
        end
    end
end
function O.Finish(state,key,complete)
    local record=state.actors[key];if not record then return false,false end
    local window=record.window;record.window=nil
    if not complete or not window then return record.alias,false end
    if state.details>=O.MaxDetails then state.detailsDropped+=1;return record.alias,false end
    state.details+=1
    -- Counts are detached from live state; the retained diversity window owns them now.
    return record.alias,window.counts
end
function O.Depart(state,key)
    local record=state.actors[key];if not record then return end
    state.unattributedEvents+=#record.pending
    record.pending={};record.context=nil;record.window=nil
    -- Keep only the weakly-keyed alias so re-entry of the same actor can be joined.
end
function O.Summary(state)
    return {revision=O.Revision,allocatedAliases=state.allocated,actorCapReached=state.actorCapReached,
        detailedWindows=state.details,detailsDropped=state.detailsDropped,pendingEventsDropped=state.pendingEventsDropped,
        unattributedEvents=state.unattributedEvents,invalidObservations=state.invalidObservations,
        maxActors=O.MaxActors,maxDetailedWindows=O.MaxDetails,maxPendingEventsPerActor=O.MaxPending,
        scope="Diagnostic only; same-tick existing AI context. known=0 is unavailable. fixedSlotFeasible is Director's existing +/-4 slot test, not move/landing reachability. Events outside observed windows may be unattributed. No diversity eligibility/action changes."}
end
return O
