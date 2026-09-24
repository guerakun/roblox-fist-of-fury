return function()
    local Risk=require(game.ServerScriptService.NightfallServer.RiskPolicy)
    local checks=0 local function check(value,message)assert(value,message);checks+=1 end
    local state={alive=true,status="Combat",specialReadyAt=20,desperationReadyAt=10}
    check(Risk.Desperation(10,state))
    for key,value in pairs({alive=false,downed=true,respawning=true,grabbed=true,travelLocked=true,status="Waiting",
        stunnedUntil=10.01,busyUntil=10.01,desperationReadyAt=10.01,specialReadyAt=10})do
        local denied=table.clone(state);denied[key]=value;check(not Risk.Desperation(10,denied),key)
    end
    local percent,ko=Risk.PayPercent(187,12,200);check(percent==199 and not ko)
    percent,ko=Risk.PayPercent(188,12,200);check(percent==200 and ko)
    check(Risk.ArmPerfect(0,nil))
    check(not Risk.ArmPerfect(.349,0))
    check(Risk.ArmPerfect(.35,0))
    check(not Risk.ArmPerfect(.5,.2),"Every fresh early press restarts rearm")
    check(Risk.PerfectBlock(.12,0,true,false,false))
    check(not Risk.PerfectBlock(.12001,0,true,false,false))
    check(not Risk.PerfectBlock(.1,0,false,false,false))
    check(not Risk.PerfectBlock(.1,0,true,true,false))
    check(not Risk.PerfectBlock(.1,0,true,false,true))
    check(not Risk.PerfectBlock(0,1,true,false,false))
    check(Risk.BountyPhase(7.99,0,true)=="Opportunity")
    check(Risk.BountyPhase(8,0,false)=="Flee")
    check(Risk.BountyPhase(8,0,true)=="Escaped")
    check(Risk.BountyPhase(14,0,false)=="Escaped")
    for _,case in ipairs({{"campaign-1",3,3,true},{"campaign-2",1,1,true},{"campaign-2",3,3,true},{"campaign-1",1,1,false},{"campaign-1",1,3,false},{"campaign-1",2,1,false}})do check(Risk.BountySelected(case[1],case[2],case[3])==case[4],"Golden deterministic bounty choice")end
    return {passed=true,checks=checks,purePolicyOnly=true}
end
