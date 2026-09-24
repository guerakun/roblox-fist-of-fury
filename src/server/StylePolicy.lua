-- Pure server-owned score state. Clocks, accepted effects and identities are injected by Combat.
local Style={}
Style.Tuning={HitsPerLevel=6,MaxMultiplier=4,DamagePoints=4,BackHitBonus=15,AirHitBonus=20,
    PerfectBlockPoints=40,ThrowBonus=25,OrbPoints=20,
    StageTargets={6500,8500,10000},StagePars={180,210,240},WaveWeights={1,1.5,1.25,2.25},
    DamageAllowance=150,RankThresholds={S=90,A=75,B=55,C=30},MaxEventsPerAttempt=4096}
local function finite(value)return type(value)=="number"and value==value and math.abs(value)<math.huge end
local function integer(value,min,max)return finite(value)and value%1==0 and value>=min and value<=max end
local function validTime(t)return finite(t)and t>=0 end
local function total(state)
    local score=0
    for _,wave in pairs(state.completed)do score+=wave.score end
    local attempt=state.attempt
    if attempt then
        local prior=state.completed[attempt.wave]
        score+=math.max(0,attempt.score-(prior and prior.score or 0))
    end
    return score
end
function Style.New(campaignId,stage,t)
    assert(type(campaignId)=="string"and #campaignId>0 and integer(stage,1,3)and validTime(t),"Invalid style identity")
    return {campaignId=campaignId,stage=stage,started=t,multiplier=1,progress=0,
        completed={},attempt=nil,damageTaken=0,bossDamageTaken=0,result=nil}
end
function Style.BeginWave(state,wave,partySize,kind,t)
    if state.result or not integer(wave,1,4)or not integer(partySize,1,4)or not validTime(t)or t<state.started then return false end
    if kind~="Wave"and kind~="Miniboss"and kind~="Boss"then return false end
    if state.attempt or state.closedWave==wave then return false end -- Only Retry can reopen the same resolved wave.
    state.attempt={wave=wave,partySize=partySize,kind=kind,started=t,score=0,eligible=false,events={},eventCount=0}
    return true
end
function Style.Award(state,event)
    local attempt=state.attempt
    if state.result or not attempt or type(event)~="table"or type(event.id)~="string"or #event.id<1 or #event.id>160
        or attempt.events[event.id]or attempt.eventCount>=Style.Tuning.MaxEventsPerAttempt then return false end
    local kind=event.kind
    local base,gain=0,0
    if kind=="Hit"or kind=="Throw"then
        if not finite(event.damage)or event.damage<=0 then return false end
        base=math.min(event.damage,999)*Style.Tuning.DamagePoints
        gain=1
        if event.backHit then base+=Style.Tuning.BackHitBonus;gain+=1 end
        if event.airHit then base+=Style.Tuning.AirHitBonus;gain+=1 end
        if kind=="Throw"then base+=Style.Tuning.ThrowBonus;gain+=1 end
    elseif kind=="PerfectBlock"then base=Style.Tuning.PerfectBlockPoints
    elseif kind=="Orb"then base=Style.Tuning.OrbPoints
    else return false end
    local gainMultiplier=finite(event.gainMultiplier)and math.clamp(event.gainMultiplier,1,2)or 1
    attempt.events[event.id]=true;attempt.eventCount+=1;attempt.eligible=true
    attempt.score+=math.floor(base*state.multiplier+.000001)
    if kind=="PerfectBlock"then
        state.multiplier=math.min(Style.Tuning.MaxMultiplier,state.multiplier+1)
    else
        state.progress+=gain*gainMultiplier
        while state.progress>=Style.Tuning.HitsPerLevel and state.multiplier<Style.Tuning.MaxMultiplier do
            state.progress-=Style.Tuning.HitsPerLevel;state.multiplier+=1
        end
    end
    if state.multiplier>=Style.Tuning.MaxMultiplier then state.progress=0 end
    return true
end
function Style.TakenHit(state,damage)
    if state.result or not state.attempt or not finite(damage)or damage<=0 then return false end
    state.attempt.eligible=true
    state.damageTaken+=damage
    if state.attempt.kind=="Boss"then state.bossDamageTaken+=damage end
    state.multiplier=math.max(1,state.multiplier-1);state.progress=0
    return true
end
function Style.CommitWave(state,wave,presentAtClear)
    local attempt=state.attempt
    if state.result or not attempt or attempt.wave~=wave then return false end
    if attempt.eligible then
        local prior=state.completed[wave]
        if not prior or attempt.score>prior.score then
            -- The opportunity denominator follows the winning attempt's frozen party size.
            state.completed[wave]={score=attempt.score,partySize=attempt.partySize,kind=attempt.kind,presentAtClear=presentAtClear~=false}
        end
    end
    state.attempt=nil;state.closedWave=wave
    return true
end
function Style.Retry(state)
    if state.result then return false end
    state.attempt=nil;state.closedWave=nil;state.multiplier=1;state.progress=0
    -- Completed-wave bests, elapsed time and ALL accepted damage survive failed attempts.
    return true
end
function Style.Snapshot(state)
    if not state then return {score=0,multiplier=1,progress=0}end
    return {score=math.floor(total(state)),multiplier=state.multiplier,
        progress=state.multiplier==Style.Tuning.MaxMultiplier and 1 or state.progress/Style.Tuning.HitsPerLevel}
end
function Style.Rank(score,target,duration,par,damage)
    local scoreFactor=math.clamp(score/math.max(1,target),0,1)
    local paceFactor=math.clamp(par/math.max(.001,duration),0,1)
    local defenseFactor=math.clamp(1-damage/Style.Tuning.DamageAllowance,0,1)
    local rating=60*scoreFactor+25*paceFactor+15*defenseFactor
    local thresholds=Style.Tuning.RankThresholds
    return rating>=thresholds.S and "S"or rating>=thresholds.A and "A"or rating>=thresholds.B and "B"or rating>=thresholds.C and "C"or "D",rating
end
function Style.Finalize(state,t,options)
    if state.result then return state.result end
    if not validTime(t)or t<state.started or state.attempt or type(options)~="table"
        or not({Normal=true,Hard=true,Nightmare=true})[options.difficulty]then return nil end
    local target,par,eligibleWaves=0,0,0
    local bossEligible=false
    for wave,item in pairs(state.completed)do
        local fraction=Style.Tuning.WaveWeights[wave]/6
        local personalOpportunity=(1+.3*(item.partySize-1))/item.partySize
        target+=Style.Tuning.StageTargets[state.stage]*fraction*personalOpportunity
        par+=Style.Tuning.StagePars[state.stage]*fraction
        eligibleWaves+=1
        if item.kind=="Boss"and item.presentAtClear~=false then bossEligible=true end
    end
    if eligibleWaves==0 then return nil end
    local duration=math.max(0,t-state.started)
    local score=math.floor(total(state))
    local rank,rating=Style.Rank(score,target,duration,par,state.damageTaken)
    local heat={}
    for _,id in ipairs(options.heat or {})do table.insert(heat,id)end
    table.freeze(heat)
    local result={id=state.campaignId..":"..state.stage,campaignId=state.campaignId,stage=state.stage,
        rank=rank,score=score,duration=duration,parTime=par,damageTaken=state.damageTaken,
        bossDamageTaken=bossEligible and state.bossDamageTaken or nil,
        difficulty=options.difficulty,heat=heat,eligibleWaves=eligibleWaves,scoreTarget=target,rating=rating}
    state.result=table.freeze(result)
    return state.result
end
return Style
