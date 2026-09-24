return function()
    local S=require(game.ServerScriptService.NightfallServer.StylePolicy)
    local checks=0
    local function check(condition,message)assert(condition,message);checks+=1 end
    local function begin(campaign,stage,wave,party,kind)
        local state=S.New(campaign or "style",stage or 1,10)
        check(S.BeginWave(state,wave or 1,party or 1,kind or "Wave",10))
        return state
    end
    local state=begin()
    for i=1,6 do check(S.Award(state,{id="hit"..i,kind="Hit",damage=8}))end
    check(state.multiplier==2 and state.progress==0,"Six accepted hits raise a level")
    local before=S.Snapshot(state).score
    check(not S.Award(state,{id="hit6",kind="Hit",damage=999}),"Duplicate effect")
    check(not S.Award(state,{id="forged",kind="Coins",damage=999}),"Unknown event")
    check(not S.Award(state,{id="zero",kind="Hit",damage=0}),"Zero damage cannot farm hit style")
    check(S.Snapshot(state).score==before)
    check(S.Award(state,{id="airback",kind="Hit",damage=10,backHit=true,airHit=true}))
    check(S.Snapshot(state).score==before+(40+15+20)*2 and state.progress==3)
    check(S.TakenHit(state,20)and state.multiplier==1 and state.progress==0)
    check(S.CommitWave(state,1))
    local best=S.Snapshot(state).score
    check(S.BeginWave(state,2,1,"Miniboss",20))
    check(S.Award(state,{id="failed",kind="Hit",damage=100}))
    check(S.TakenHit(state,30));check(S.Retry(state))
    check(S.Snapshot(state).score==best and state.damageTaken==50 and state.multiplier==1,"Retry must discard failed score but retain damage")
    check(S.BeginWave(state,1,1,"Wave",30));check(S.Award(state,{id="low-replay",kind="Hit",damage=1}));check(S.CommitWave(state,1))
    check(S.Snapshot(state).score==best,"Low replay must not add score")
    check(not S.BeginWave(state,1,2,"Wave",40),"Resolved wave reopened without retry");check(S.Retry(state));check(S.BeginWave(state,1,2,"Wave",40));check(S.Award(state,{id="high-replay",kind="Hit",damage=999}));check(S.CommitWave(state,1))
    check(S.Snapshot(state).score==3996 and state.completed[1].partySize==2,"Best replay replaces score and denominator together")
    check(S.BeginWave(state,4,2,"Boss",50));check(S.TakenHit(state,7));check(S.Retry(state))
    check(S.BeginWave(state,4,2,"Boss",70));check(S.Award(state,{id="boss",kind="Hit",damage=20}));check(S.CommitWave(state,4))
    local result=S.Finalize(state,100,{difficulty="Normal",heat={}})
    check(result and result.id=="style:1"and result.bossDamageTaken==7 and result.damageTaken==57 and result.duration==90)
    check(result.eligibleWaves==2 and result.parTime==180*(1+2.25)/6,"Missed waves cannot pad late arrival par")
    check(not pcall(function()result.rank="S"end)and not pcall(function()result.heat[1]="Frenzy"end),"Result immutable")
    check(S.Finalize(state,999,{difficulty="Nightmare",heat={"Frenzy"}})==result,"First result never changes")
    check(not S.Award(state,{id="late",kind="Hit",damage=999})and not S.Retry(state))
    local a=begin("a");local b=begin("b")
    check(S.Award(a,{id="a",kind="PerfectBlock"})and a.multiplier==2 and b.multiplier==1,"Per-player isolation")
    check(S.Award(a,{id="boon",kind="Hit",damage=1,gainMultiplier=2})and a.progress==2)
    check(S.CommitWave(a,1));local noBoss=S.Finalize(a,20,{difficulty="Hard",heat={}})
    check(noBoss.bossDamageTaken==nil,"Missing boss participation is not a no-hit boss")
    check(not S.BeginWave(b,1,1,"Wave",12),"Duplicate begin erased attempt")
    check(S.CommitWave(b,1));check(S.Finalize(b,20,{difficulty="Normal",heat={}})==nil,"No participation cannot rank")
    local capped=begin("cap")
    for i=1,30 do S.Award(capped,{id="h"..i,kind="Hit",damage=1})end
    check(capped.multiplier==4 and S.Snapshot(capped).progress==1)
    for i=1,8 do S.TakenHit(capped,1)end check(capped.multiplier==1)
    for _,case in ipairs({{5000,0,"S"},{4999,0,"A"},{3500,0,"A"},{3499,0,"B"},{1500,0,"B"},{1499,0,"C"},{500,150,"C"},{499,150,"D"},{0,150,"D"}})do
        check(S.Rank(case[1],6000,100,100,case[2])==case[3],"Exact rank threshold/below boundary")
    end
    for _,party in ipairs({1,4})do
        local late=begin("late"..party,1,4,party,"Boss")
        check(S.Award(late,{id="late-hit",kind="Hit",damage=1}));check(S.CommitWave(late,4))
        local r=S.Finalize(late,30,{difficulty="Normal",heat={}})
        check(math.abs(r.scoreTarget-6500*2.25/6*(1+.3*(party-1))/party)<1e-8,"Party opportunity denominator")
        check(r.parTime==67.5 and r.eligibleWaves==1,"Late join eligible par")
    end
    return {passed=true,checks=checks,tuningProvisional=true,physicalGameplay=false}
end
