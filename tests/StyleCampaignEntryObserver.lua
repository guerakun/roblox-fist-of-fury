-- TEST ONLY: pure sampled-state reducer. It never reads or changes game state.
local Observer = {}
Observer.Revision = "entry-elite-samples-v1"
Observer.MaxEntries = 64
local validStates = {Waiting=true, Combat=true, Intermission=true, Traverse=true, Advance=true, Victory=true, Defeat=true}
local function finite(value)
    return type(value)=="number" and value==value and math.abs(value)<math.huge
end
local function nonnegative(value)
    return finite(value) and value>=0 and value or false
end
local function copy(value)
    if type(value)~="table" then return value end
    local out={}
    for key,item in pairs(value)do out[key]=copy(item)end
    return out
end
function Observer.New()
    return {entries={},entryAttempts={},truncated=false,entriesObserved=0,rejectedSamples=0,
        previous=nil,lastElite=nil,terminalElite=false,terminalState=false}
end
function Observer.Observe(state,snapshot,t)
    if type(snapshot)~="table" or not finite(t) or t<0 or (state.previous and t<state.previous.at)
        or not finite(snapshot.stage) or snapshot.stage%1~=0 or snapshot.stage<1 or snapshot.stage>3
        or not finite(snapshot.wave) or snapshot.wave%1~=0 or snapshot.wave<0 or snapshot.wave>4
        or not validStates[snapshot.status] or (snapshot.status=="Combat" and snapshot.wave==0)then
        state.rejectedSamples+=1
        return false
    end
    local previous=state.previous
    local sameEncounter=previous and previous.stage==snapshot.stage and previous.wave==snapshot.wave
    local entry=snapshot.status=="Combat" and (not sameEncounter or previous.status~="Combat")
    if not sameEncounter or entry then state.lastElite=nil end
    if entry then
        local key=snapshot.stage..":"..snapshot.wave
        local attempt=(state.entryAttempts[key] or 0)+1
        state.entryAttempts[key]=attempt
        state.entriesObserved+=1
        if #state.entries<Observer.MaxEntries then
            table.insert(state.entries,{stage=snapshot.stage,wave=snapshot.wave,attempt=attempt,
                firstObservedAtSeconds=t,stocks=nonnegative(snapshot.stocks),percent=nonnegative(snapshot.percent),
                downed=snapshot.downed==true,runDamageTaken=nonnegative(type(snapshot.runStats)=="table" and snapshot.runStats.damageTaken),
                priorStatus=previous and previous.status or false,firstObservation=previous==nil,
                sampleGapSeconds=previous and t-previous.at or false})
        else state.truncated=true end
    end
    local terminal=snapshot.status=="Victory" or snapshot.status=="Defeat"
    local boss=snapshot.boss
    local validElite=type(boss)=="table" and type(boss.kind)=="string" and finite(boss.percent) and boss.percent>=0
        and finite(boss.threshold) and boss.threshold>0
    if (snapshot.status=="Combat" or terminal) and validElite then
        state.lastElite={stage=snapshot.stage,wave=snapshot.wave,kind=boss.kind,percent=boss.percent,
            threshold=boss.threshold,phase=nonnegative(boss.phase),sampledAtSeconds=t}
    end
    if terminal then
        state.terminalState={status=snapshot.status,stage=snapshot.stage,wave=snapshot.wave,observedAtSeconds=t}
        if state.lastElite and state.lastElite.stage==snapshot.stage and state.lastElite.wave==snapshot.wave then
            state.terminalElite=copy(state.lastElite)
            state.terminalElite.presentInTerminalSnapshot=validElite
            state.terminalElite.ageSeconds=t-state.lastElite.sampledAtSeconds
        else state.terminalElite=false end
    else
        state.terminalState=false
        state.terminalElite=false
    end
    state.previous={stage=snapshot.stage,wave=snapshot.wave,status=snapshot.status,at=t}
    return true
end
function Observer.Export(state)
    return {revision=Observer.Revision,encounterEntries=copy(state.entries),entriesObserved=state.entriesObserved,
        truncated=state.truncated,rejectedSamples=state.rejectedSamples,terminalElite=copy(state.terminalElite),
        terminalState=copy(state.terminalState),exactEntryTimingVerified=false,
        scope="First observed Combat states at nominal 0.2s sampling; floored player percent; one snapshot-listed elite; absent terminal elite is not a lethal-hit measurement"}
end
return Observer
