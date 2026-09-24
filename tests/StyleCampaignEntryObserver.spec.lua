-- Pure reducer fixture. Optional injected module supports a standalone root-run pure test.
-- Prepared only until root executes; no gameplay or physical-client evidence.
return function(injected)
    local O=injected or require(script.Parent.StyleCampaignEntryObserver)
    local count=0
    local function check(value,label)assert(value,label);count+=1 end
    local function snapshot(stage,wave,status,boss)
        return {stage=stage,wave=wave,status=status,stocks=2,percent=87,downed=false,
            runStats={damageTaken=123},boss=boss or false}
    end
    local function elite(percent)return {kind="KilnSovereign",percent=percent,threshold=340,phase=2}end
    local s=O.New()
    check(O.Observe(s,snapshot(1,0,"Waiting"),0),"Waiting accepted")
    check(O.Observe(s,snapshot(1,0,"Intermission"),1),"Intermission accepted")
    check(O.Observe(s,snapshot(1,1,"Combat"),1.2),"First Combat sample")
    local export=O.Export(s);local first=export.encounterEntries[1]
    check(#export.encounterEntries==1 and first.stocks==2 and first.percent==87 and first.runDamageTaken==123,"Entry snapshot values")
    check(first.attempt==1 and first.priorStatus=="Intermission" and not first.firstObservation,"Prior state and attempt")
    check(math.abs(first.sampleGapSeconds-.2)<1e-8 and first.firstObservedAtSeconds==1.2,"Measured sample gap")
    check(not export.exactEntryTimingVerified and export.terminalElite==false and export.terminalState==false,"Explicit unavailable and scope")
    check(O.Observe(s,snapshot(1,1,"Combat"),2)and #O.Export(s).encounterEntries==1,"Continuous Combat is not another entry")
    check(O.Observe(s,snapshot(1,2,"Combat"),3),"Unobserved intervening state still detects changed encounter")
    check(O.Export(s).encounterEntries[2].priorStatus=="Combat","Missed transition remains visible as limitation")
    O.Observe(s,snapshot(1,2,"Intermission"),4);O.Observe(s,snapshot(1,2,"Combat"),5)
    check(O.Export(s).encounterEntries[3].attempt==2,"Observed same-wave re-entry increments attempt")
    first.percent=999;local laterExport=O.Export(s);laterExport.encounterEntries[2].stocks=999
    check(O.Export(s).encounterEntries[1].percent==87 and O.Export(s).encounterEntries[2].stocks==2,"Export cannot mutate retained samples")
    local late=O.New();O.Observe(late,snapshot(2,3,"Combat"),10)
    check(O.Export(late).encounterEntries[1].firstObservation and O.Export(late).encounterEntries[1].priorStatus==false,"Late first observation is explicit")
    local terminal=O.New();O.Observe(terminal,snapshot(3,4,"Combat",elite(250.5)),20)
    O.Observe(terminal,snapshot(3,4,"Defeat"),20.3)
    local last=O.Export(terminal).terminalElite
    check(last.percent==250.5 and last.threshold==340 and not last.presentInTerminalSnapshot,"Absent terminal actor retains last observation, not zero health")
    check(math.abs(last.ageSeconds-.3)<1e-8 and last.stage==3 and last.wave==4,"Last observation age and same encounter")
    O.Observe(terminal,snapshot(3,4,"Defeat",elite(263.25)),20.6)
    last=O.Export(terminal).terminalElite
    check(last.presentInTerminalSnapshot and last.percent==263.25 and last.ageSeconds==0,"Present terminal actor gets current sample")
    O.Observe(terminal,snapshot(3,4,"Victory"),21)
    check(math.abs(O.Export(terminal).terminalElite.ageSeconds-.4)<1e-8,"Final followup sample age")
    local old=O.New();O.Observe(old,snapshot(2,4,"Combat",elite(20)),1);O.Observe(old,snapshot(3,1,"Defeat"),2)
    check(O.Export(old).terminalElite==false,"Previous district elite never leaks")
    local retry=O.New();O.Observe(retry,snapshot(3,4,"Combat",elite(220)),1);O.Observe(retry,snapshot(3,4,"Intermission"),2)
    O.Observe(retry,snapshot(3,4,"Combat"),3);O.Observe(retry,snapshot(3,4,"Defeat"),4)
    check(O.Export(retry).terminalElite==false,"Same-wave fresh attempt clears old elite")
    local absent=O.New();O.Observe(absent,snapshot(1,1,"Defeat"),0)
    check(O.Export(absent).terminalElite==false and O.Export(absent).terminalState.status=="Defeat","No elite ever observed remains explicit false")
    local malformed=O.New();local bad=snapshot(1,1,"Combat",elite(0/0));bad.percent=0/0;bad.runStats=nil
    check(O.Observe(malformed,bad,0),"Missing optional measurements do not invent a value")
    check(O.Export(malformed).encounterEntries[1].percent==false and O.Export(malformed).encounterEntries[1].runDamageTaken==false,"Unavailable optional fields")
    check(not O.Observe(malformed,nil,1),"Missing snapshot rejected")
    check(not O.Observe(malformed,snapshot(1,1,"Combat"),-1),"Negative sample time rejected")
    check(not O.Observe(malformed,snapshot(1,1,"Combat"),0/0),"Nonfinite sample time rejected")
    check(not O.Observe(malformed,snapshot(4,1,"Combat"),1),"Unknown stage rejected")
    check(not O.Observe(malformed,snapshot(1,0,"Combat"),1),"Combat wave zero rejected")
    check(not O.Observe(malformed,snapshot(1,1,"Unknown"),1),"Unknown state rejected")
    O.Observe(malformed,snapshot(1,1,"Combat"),2)
    check(not O.Observe(malformed,snapshot(1,1,"Combat"),1),"Time cannot move backwards")
    check(O.Export(malformed).rejectedSamples==7,"Invalid sample accounting")
    local bounded=O.New()
    for i=1,66 do
        O.Observe(bounded,snapshot(1,1,"Intermission"),i*2)
        O.Observe(bounded,snapshot(1,1,"Combat"),i*2+1)
    end
    local capped=O.Export(bounded)
    check(#capped.encounterEntries==64 and capped.entriesObserved==66 and capped.truncated,"Retained entries capped with explicit truncation")
    check(capped.encounterEntries[64].attempt==64,"Existing entries are not silently overwritten")
    O.Observe(bounded,snapshot(1,1,"Defeat",elite(42)),200)
    check(O.Export(bounded).terminalElite.percent==42,"Terminal diagnostics still update after entry cap")
    return {passed=true,assertions=count,revision=O.Revision,scope="Pure supplied-state reducer only; no actual campaign sampling or Studio client verification"}
end
