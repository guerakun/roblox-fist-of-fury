-- Pure injected observer and unchanged-diversity comparison. Root alone runs Studio.
return function(injectedO,injectedD)
    local O=injectedO or require(game.ServerScriptService.NightfallServer.EnemyOpportunityDiagnostics)
    local D=injectedD or require(game.ServerScriptService.NightfallServer.ActionDiversity)
    local n=0
    local function check(value,label)assert(value,label);n+=1 end
    local function observed()
        local o=O.New()
        local d=D.New({Begin=function(a,t)O.Begin(o,a,t)end,
            Finish=function(a,complete)return O.Finish(o,a,complete)end,
            Depart=function(a)O.Depart(o,a)end})
        return o,d
    end
    local o,d=observed();local a,b={},{}
    check(O.Alias(o,a)=="Enemy1"and O.Alias(o,a)=="Enemy1"and O.Alias(o,b)=="Enemy2","Stable distinct run-local aliases")
    -- Events before first sampled engagement are retained only if inside that window.
    O.Event(o,a,"tokenRequests",0);O.Event(o,a,"tokenGrants",0)
    D.Engage(d,a,"Grappler",0)
    O.Context(o,a,0,{visible=true,fixedSlotFeasible=false})
    O.Context(o,a,0,{inRange=false});O.Sample(o,a,0)
    O.Sample(o,a,.1) -- stale context must remain unavailable
    O.Context(o,a,.2,{visible=false});O.Sample(o,a,.2)
    D.Action(d,a,"Grappler","Grab",1);O.Event(o,a,"grabAttempts",1)
    D.Action(d,a,"Grappler","Grab",1.4);O.Event(o,a,"grabCaptures",1.4)
    D.Action(d,a,"Grappler","Throw",2)
    -- Boundary event belongs to next window, not the one ending at30.
    O.Event(o,a,"tokenRequests",30);D.Engage(d,a,"Grappler",30)
    local w=d.windows[1];local c=w.opportunity
    check(w.actorAlias=="Enemy1"and w.passed and #w.actions==2,"Additive window identity preserves two real actions")
    check(c.sampledTicks==3 and c.contextTicks==2,"Same-tick context only")
    check(c.visible.known==2 and c.visible.yes==1,"Known false distinguished from unavailable")
    check(c.fixedSlotFeasible.known==1 and c.fixedSlotFeasible.yes==0,"Existing fixed slot result only")
    check(c.inRange.known==1 and c.inRange.yes==0,"Unavailable later range does not become false")
    check(c.tokenRequests==1 and c.tokenGrants==1 and c.grabAttempts==1 and c.grabCaptures==1,"Events counted once inside window")
    D.Engage(d,a,"Grappler",60)
    check(d.windows[2].opportunity.tokenRequests==1 and not d.windows[2].passed,"Boundary request does not qualify an action")
    check(c.tokenRequests==1,"Retained counts detached from next window")
    D.Leave(d,a,61)
    check(d.partialWindows==1 and o.actors[a].window==nil and o.actors[a].context==nil,"Departure clears active observations")
    check(O.Alias(o,a)=="Enemy1","Same actor re-entry keeps alias")
    D.Engage(d,a,"Grappler",70);O.Sample(o,a,70);D.Engage(d,a,"Grappler",100)
    check(d.windows[3].opportunity.visible.known==0,"Re-entry never reuses departed context")
    local empty=O.New();O.Event(empty,a,"tokenRequests",0);O.Begin(empty,a,1)
    check(empty.unattributedEvents==1,"Events before new window reported unattributed")
    O.Event(empty,a,"tokenGrants",40);O.Depart(empty,a)
    check(empty.unattributedEvents==2 and #empty.actors[a].pending==0,"Departure clears pending events honestly")
    O.Event(empty,a,"madeUpAction",2);O.Context(empty,a,0/0,{visible=true})
    check(empty.invalidObservations==2,"Invalid diagnostic inputs rejected")
    local pending=O.New()
    for i=1,O.MaxPending+1 do O.Event(pending,a,"tokenRequests",i)end
    check(#pending.actors[a].pending==64 and pending.pendingEventsDropped==1,"Pending journal bounded")
    local capped=O.New();local actors={}
    for i=1,O.MaxActors+1 do actors[i]={};O.Alias(capped,actors[i])end
    check(capped.allocated==1024 and capped.actorCapReached and O.Alias(capped,actors[1025])==false,"Alias cap explicit, no recycled identity")
    local detail=O.New()
    for i=1,O.MaxDetails+1 do O.Begin(detail,a,i*31);O.Finish(detail,a,true)end
    check(detail.details==1024 and detail.detailsDropped==1,"Detailed window retention bounded")
    local reset=O.New();check(O.Alias(reset,a)=="Enemy1"and not reset.actorCapReached,"New run resets identity/counters")
    check(getmetatable(o.actors).__mode=="k","Removed models are not strongly retained by alias map")
    -- Replay identical action/engagement calls with and without diagnostic hooks.
    local plain=D.New();local diag,with=observed();local who={}
    local function each(name,...)
        D[name](plain,who,...);D[name](with,who,...)
    end
    each("Engage","Husk",0)
    each("Action","Husk","Hold",1);each("Action","Husk","Reposition",2)
    each("Action","Husk","HuskJab",5);each("Action","Husk","HuskJab",6)
    each("Engage","Husk",30)
    each("Action","Husk","HuskJab",31);each("Action","Husk","HuskJumpKick",40)
    each("Engage","Husk",60);each("Leave",65)
    check(plain.partialWindows==with.partialWindows and #plain.windows==#with.windows,"Observed and plain window boundaries unchanged")
    for i,legacy in ipairs(plain.windows)do
        local added=with.windows[i]
        check(legacy.kind==added.kind and legacy.start==added.start and legacy.duration==added.duration and legacy.passed==added.passed,"Legacy window fields unchanged")
        check(table.concat(legacy.actions,",")==table.concat(added.actions,","),"Legacy action set unchanged")
    end
    check(plain.byKind.Husk.eligible==with.byKind.Husk.eligible and plain.byKind.Husk.passed==with.byKind.Husk.passed and plain.byKind.Husk.minDistinct==with.byKind.Husk.minDistinct,"Acceptance denominator unchanged")
    return {passed=true,assertions=n,revision=O.Revision,scope="Pure supplied-context diagnostics and unchanged diversity replay; no live opportunity or behavior evidence"}
end
