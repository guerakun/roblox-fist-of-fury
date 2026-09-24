-- Pure injected predicates/service checks; no external badge call or live award.
return function(Policy,Service,Config)
    local n=0 local function check(v)assert(v)n+=1 end
    local function contains(values,key)return table.find(values,key)~=nil end
    local function result(stage,rank,boss)
        return {campaignId="server:run",id="server:run:"..stage,stage=stage,rank=rank or "C",bossDamageTaken=boss}
    end
    for stage=1,3 do
        local ids=Policy.Evaluate(result(stage),0,false)
        check(#ids==1 and ids[1]=="District"..stage)
    end
    check(contains(Policy.Evaluate(result(1,"S"),0,false),"RankS"))
    check(not contains(Policy.Evaluate(result(3,"A"),15,false),"Heat5"))
    check(not contains(Policy.Evaluate(result(2,"A"),15,true),"Heat5"))
    for _,points in ipairs({0,4,5,9,10,14,15}) do
        local ids=Policy.Evaluate(result(3,"C"),points,true)
        for _,threshold in ipairs({5,10,15}) do check(contains(ids,"Heat"..threshold)==(points>=threshold)) end
    end
    check(contains(Policy.Evaluate(result(1,"C",0),0,false),"NoHitBoss"))
    check(not contains(Policy.Evaluate(result(1,"C"),0,false),"NoHitBoss"))
    check(not contains(Policy.Evaluate(result(1,"C",.001),0,false),"NoHitBoss"))
    for _,bad in ipairs({-1,16,.5,math.huge,0/0,"15"}) do check(#Policy.Evaluate(result(3),bad,true)==0) end
    for _,bad in ipairs({{},{stage=1,rank="S"},result(0),result(4),result(1,"forged"),result(1,"C",-1),result(1,"C",0/0)}) do
        check(#Policy.Evaluate(bad,0,true)==0)
    end
    check(#Policy.Evaluate(result(3),15,"true")==0)
    local calls=0
    local zero=Service.new({Has=function()calls+=1 return false end,Award=function()calls+=1 return true end},Config.Badges)
    for _,key in ipairs(Config.Order) do
        check(Config.Badges[key].BadgeId==0)
        local success,status=zero:Award(42,key) check(not success and status=="unconfigured")
    end
    check(calls==0)
    local hasCalls,awardCalls=0,0
    local adapter={Has=function(uid,badge)check(uid==42 and badge==123)hasCalls+=1 return false end,
        Award=function(uid,badge)check(uid==42 and badge==123)awardCalls+=1 return true end}
    local service=Service.new(adapter,{First=123,Alias={BadgeId=123}})
    local success,status=service:Award(42,"First") check(success and status=="awarded")
    success,status=service:Award(42,"First") check(success and status=="cached")
    check(service:Award(42,"Alias") and hasCalls==1 and awardCalls==1)
    local owned=Service.new({Has=function()return true end,Award=function()error("Owned badge must not award again")end},{Badge=1})
    success,status=owned:Award(42,"Badge") check(success and status=="alreadyOwned")
    local attempts=0
    local retry=Service.new({Has=function()attempts+=1 if attempts==1 then error("temporary has failure")end return false end,
        Award=function()if attempts==2 then error("temporary award failure")end return attempts>=4 end},{Badge=2})
    check(not retry:Award(42,"Badge")) check(not retry:Award(42,"Badge")) check(not retry:Award(42,"Badge"))
    check(retry:Award(42,"Badge") and attempts==4)
    local inFlight=Service.new({Has=function()coroutine.yield("has pending")return false end,Award=function()return true end},{Badge=3})
    local final
    local thread=coroutine.create(function()final={inFlight:Award(42,"Badge")}end)
    local resumed,marker=coroutine.resume(thread) check(resumed and marker=="has pending")
    success,status=inFlight:Award(42,"Badge") check(not success and status=="inFlight")
    check(coroutine.resume(thread) and final[1] and final[2]=="awarded")
    check(inFlight:Award(42,"Badge"))
    check(not service:Award(0,"First") and not service:Award(0/0,"First") and not service:Award(42,"Unknown"))
    local invalid=Service.new(adapter,{Bad="123",Negative=-1})
    check(not invalid:Award(42,"Bad") and not invalid:Award(42,"Negative"))
    local ownedChecks=0
    local forgotten=Service.new({Has=function()ownedChecks+=1 return true end,Award=function()error("already owned")end},{Badge=4})
    check(forgotten:Award(42,"Badge") and forgotten:Award(42,"Badge") and ownedChecks==1)
    check(forgotten:Forget(42) and forgotten:Award(42,"Badge") and ownedChecks==2)
    local hasAfter=false local awardAfter=0 local hasCount=0
    local departing=Service.new({Has=function()hasCount+=1 if hasCount==1 then coroutine.yield("pending departure")end return hasAfter end,
        Award=function()awardAfter+=1 hasAfter=true return true end},{Badge=5})
    local departureResult
    local pendingThread=coroutine.create(function()departureResult={departing:Award(42,"Badge")}end)
    check(coroutine.resume(pendingThread)) check(departing:Forget(42))
    success,status=departing:Award(42,"Badge") check(not success and status=="inFlight")
    check(coroutine.resume(pendingThread) and departureResult[1])
    check(next(departing.succeeded)==nil and next(departing.inFlight)==nil)
    success,status=departing:Award(42,"Badge") check(success and status=="alreadyOwned" and awardAfter==1 and hasCount==2)
    return {passed=true,checks=n,scope="pure earned predicates and fake badge adapter; no configured/live badge issuance"}
end
