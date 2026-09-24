return function()
    local Cache=require(game.ServerScriptService.HubSnapshotCache)
    local now,calls,fail=10,0,false
    local cache=Cache.new({ttl=5,now=function()return now end,load=function(id)
        calls+=1 if fail then error('injected throttle')end return {id=id,status='Idle'}
    end})
    assert(cache:Get(1).id==1)
    for _=1,100 do assert(cache:Get(1).status=='Idle')end
    assert(calls==1,'Refresh bursts must coalesce')
    now=15 assert(cache:Get(1).id==1 and calls==2)
    now=20 fail=true assert(cache:Get(1).status=='Idle' and calls==3)
    for _=1,100 do cache:Get(1)end assert(calls==3,'Failure retains cooldown')
    local ok=pcall(function()cache:Get(2)end)assert(not ok and calls==4)
    for _=1,10 do assert(not pcall(function()cache:Get(2)end))end assert(calls==4)
    fail=false now=25 assert(cache:Get(2).id==2 and calls==5)
    cache:Remove(1)assert(cache.entries[1]==nil)
    local nestedCalls=0 local concurrent
    concurrent=Cache.new({load=function(id)nestedCalls+=1 assert(concurrent:Get(id)==nil)return {id=id}end})
    assert(concurrent:Get(8).id==8 and nestedCalls==1,'In-flight reads cannot launch another loader')
    local budgetCalls=0
    local budget=Cache.new({now=function()return now end,load=function(id)budgetCalls+=2 return {id=id}end})
    for _=1,100 do for id=1,30 do budget:Get(id)end end
    assert(budgetCalls==60,'Thirty participants and repeated refreshes do not amplify storage reads')
    local slowCalls=0
    local slow=Cache.new({ttl=5,now=function()return now end,load=function()slowCalls+=1 now+=8 error('slow failure')end})
    assert(not pcall(function()slow:Get(1)end))
    for _=1,100 do assert(not pcall(function()slow:Get(1)end))end
    assert(slowCalls==1,'Cooldown begins after a slow failure completes')
    return {slowFailureCooldown=true,passed=true,burstReads=100,readsPerFiveSeconds=1,failedLoadCooldown=true,inFlight=true,cleanup=true}
end
