-- Deterministic hold intent fixture; no simulated progress can complete a revive.
return function()
    local module=game.ServerScriptService:FindFirstChild("ReviveControl")
    if not module then module=game.Players.LocalPlayer.PlayerScripts.NightfallClient.ReviveControl end
    local Control=require(module)
    local requests={}local blocked=false
    local control=Control.new(function(action,payload)table.insert(requests,{action=action,payload=payload})end,function()return blocked end)
    local function state(target,channel,canStart,progress)
        return {status="Combat",downed=false,revive={targetUserId=target,name="ALLY",canStart=canStart~=false,
            channeling=channel==true,progress=progress or 0,remaining=8}}
    end
    assert(not control:Begin(),"No snapshot cannot authorize a hold")
    control:Update(state(42))assert(control:Begin())assert(not control:Begin(),"Repeated Begin must not duplicate")
    assert(#requests==1 and requests[1].action=="Revive" and requests[1].payload.held and requests[1].payload.targetUserId==42)
    assert(requests[1].payload.progress==nil and requests[1].payload.duration==nil)
    control:Update(state(42,true,false,.5))assert(#requests==1,"Channel acknowledgement cannot emit progress")
    control:Update(state(42,true,false,1))assert(#requests==1,"Even 100 percent display cannot complete locally")
    control:Update(state(42,false,true))assert(#requests==2 and requests[2].payload.held==false,"Interruption must release")
    assert(not control:Cancel(),"Repeated End/Cancel must not duplicate release")
    assert(control:Begin())control:Update(state(43))
    assert(requests[#requests].payload.held==false and not control.heldTarget,"Target switch must not auto-retarget")
    assert(control:Begin())blocked=true control:Update(state(43))
    assert(not control.heldTarget and not control:Begin(),"Blocked UI cannot start or retain hold")
    blocked=false assert(control:Begin())control:Cancel()assert(not control.heldTarget)
    for _,clear in ipairs({{status="Combat",revive=false},{status="Combat",downed=true,revive=state(43).revive},
        {status="Victory",revive=state(43).revive},{status="Waiting",revive=state(43).revive},
        {status="Defeat",revive=state(43).revive},state(43,false,false)})do
        control:Update(state(43))assert(control:Begin())control:Update(clear)assert(not control.heldTarget and not control:Begin())
    end
    local expired=state(43)expired.revive.remaining=0
    control:Update(state(43))assert(control:Begin())control:Update(expired)assert(not control.heldTarget)
    return {passed=true,requests=#requests,duplicateBegin=false,serverProgressOnly=true,targetSwitchCancel=true,
        interruptionCancel=true,focusCancel=true,lifeAndStatusCancel=true,explicitFalseClear=true,expiryCancel=true}
end
