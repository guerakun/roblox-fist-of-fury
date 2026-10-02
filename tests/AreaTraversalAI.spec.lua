-- Pure lifecycle evidence only; physical two-client rescue/gate interaction remains runtime validation.
return function(Policy)
    Policy=Policy or require(game.ServerScriptService.NightfallServer.AreaTraversalPolicy)
    local bounds={MinX=48,MaxX=92,MinZ=-24,MaxZ=24}
    local ally={};local survivor={}
    local records={[ally]={downed=true,downedUntil=12,stocks=0,percent=215,position=Vector3.new(30,3,0)},
        [survivor]={downed=false,stocks=2,position=Vector3.new(60,3,0)}}
    local function positionOf(_,data)return data.position end
    local n=0;local function check(v,message)n+=1;assert(v,message)end
    local canSeal,count=Policy.CanSeal(records,bounds,5,positionOf)
    check(not canSeal and count==1,"revivable ally behind open gate blocks sealing")
    check(not Policy.CanSeal(records,bounds,11.999,positionOf),"wait entire original revive window")
    check(Policy.CanSeal(records,bounds,12,positionOf),"expiry releases gate")
    check(records[ally].stocks==0 and records[ally].percent==215 and records[ally].downedUntil==12,"gate wait never heals or extends deadline")
    records[ally].position=Vector3.new(52,3,0)
    check(Policy.CanSeal(records,bounds,5,positionOf),"downed ally already in next arena can still be rescued")
    records[ally].position=Vector3.new(49,3,0)
    check(not Policy.CanSeal(records,bounds,5,positionOf),"body must clear gate inset")
    records[ally].position=nil
    check(not Policy.CanSeal(records,bounds,5,positionOf),"unknown body position waits until deadline")
    records[ally].downed=false
    check(Policy.CanSeal(records,bounds,5,positionOf),"rescued ally uses normal living-party rally check")
    records[ally].downed=true;records[ally].downedUntil=nil
    check(Policy.CanSeal(records,bounds,5,positionOf),"expired or unavailable revive cannot stall forever")
    records[ally]=nil
    check(Policy.CanSeal(records,bounds,5,positionOf),"departed ally is not an indefinite barrier")
    return {passed=true,assertions=n,scope="Pure downed gate lifecycle; physical co-op unverified"}
end
