-- Local capability policy, not a physical-key or server enforcement test.
return function(Capabilities)
    Capabilities = Capabilities or require(game.ServerScriptService.ActionCapabilities)
    local releases,checks = 0,0
    local guard = Capabilities.new(function() releases+=1 end)
    local function check(value,message) assert(value,message) checks+=1 end
    for _,action in ipairs({"Block","Dash","Burst","Jump","Recovery","Light","Special"}) do
        check(guard:Allows(action,true),"Legacy snapshot keeps ordinary controls")
    end
    guard:Update({canBlock=false,canDash=true},false)
    check(not guard:Allows("Block",true),"Berserker cannot begin local guard")
    check(guard:Allows("Block",false),"Release remains allowed while guard is disabled")
    check(guard:Allows("Jump") and guard:Allows("Recovery"),"Guard restriction cannot suppress jump/recovery")
    check(guard:Allows("Dash") and releases==0)
    guard:Update({canBlock=true,canDash=false},false)
    check(not guard:Allows("Dash") and not guard:Allows("Burst"),"Anchor blocks both dash paths")
    check(guard:Allows("Block",true) and guard:Allows("Jump") and guard:Allows("Recovery"))
    guard:Update({canBlock=false,canDash=false},true)
    check(releases==1,"Revocation releases held guard")
    guard:Update({canBlock=false,canDash=false,blocking=true},true)
    check(releases==1,"Repeated snapshots do not repeat cancellation")
    guard:Update({canBlock=true,canDash=true},false)
    check(releases==1 and guard:Allows("Block",true) and guard:Allows("Dash"),"Reenable authorizes only future input")
    guard:Update({canBlock=false,blocking=true},false)
    check(releases==2,"Server acknowledged hold also clears on revocation")
    guard:Update({},false)
    check(guard:Allows("Block",true) and guard:Allows("Dash"),"Missing fields default allow")
    return {passed=true,checks=checks,releaseCallbacks=releases,legacyDefaults=true,restrictedActionPolicy=true,jumpRecoveryPreserved=true,physicalInputVerified=false}
end
