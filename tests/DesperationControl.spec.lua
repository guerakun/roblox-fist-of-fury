-- Ordered gesture and deliberate touch hold contract. No physical input or server-cost claim.
return function(Control)
    Control=Control or require(game.ServerScriptService.DesperationControl)
    local clock=0 local blocked=false local sent=0 local checks=0
    local control=Control.new({clock=function()return clock end,blocked=function()return blocked end,
        send=function(...)assert(select("#",...)==0,"Local controller must not send cost/amount")sent+=1 end})
    local function check(v,message)assert(v,message)checks+=1 end
    local function state(available)return {status="Combat",canDesperation=available,desperationCost=12,desperationCooldown=0}end
    local begin,finish,cancel=Enum.UserInputState.Begin,Enum.UserInputState.End,Enum.UserInputState.Cancel
    control:Update(state(false))check(not control:Handle("Special",begin))check(not control:Handle("Heavy",begin))check(sent==0)
    control:Update(state(true))check(not control:Handle("Heavy",begin),"Reverse order stays normal Heavy")
    check(control:Handle("Special",begin))check(sent==0)
    check(control:Handle("Heavy",begin)and sent==1)
    check(control:Handle("Heavy",begin)and sent==1,"Held repeats cannot repeat cost")
    check(control:Handle("Special",finish))check(not control:Handle("Heavy",begin))
    check(control:Handle("Special",begin))control:Handle("Special",cancel)check(not control.armed)
    control:Handle("Special",begin)blocked=true control:Update(state(true))check(not control.armed and not control:Handle("Special",begin))
    blocked=false
    for _,changes in ipairs({{downed=true},{travelLocked=true},{status="Victory"},{canDesperation=false},{desperationCooldown=1},{desperationCost=0/0}})do
        control:Update(state(true))control:Handle("Special",begin)
        local nextState=state(true)for key,value in pairs(changes)do nextState[key]=value end control:Update(nextState)
        check(not control.armed and not control:Available())
    end
    control:Update(state(true))check(control:TouchBegin())clock=.349 check(control:Step()<1 and sent==1)
    control:TouchEnd()clock=1 check(control:Step()==0 and sent==1,"Short tap must not cost")
    check(control:TouchBegin())clock=1.35 control:Step()check(sent==2)
    clock=2 control:Step()check(sent==2,"Long hold costs once")
    control:TouchEnd()control:TouchBegin()control:CancelTouch()clock=3 control:Step()check(sent==2)
    control:Handle("Special",begin)control:CancelTouch()check(control.armed,"Keyboard chord survives non-touch render")
    control:Reset()check(not control.armed and control.touchStart==nil)
    control:Update(state(false))control:Handle("Special",begin)control:Update(state(true))
    check(not control:Handle("Heavy",begin),"Previously held normal Special cannot become a paid modifier")
    return {passed=true,checks=checks,requests=sent,orderedChord=true,noRepeat=true,shortTapFree=true,focusAndLifeCancel=true,normalActionsImmediate=true}
end
