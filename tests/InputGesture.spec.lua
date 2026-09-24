-- Composes production ownership policy with real hold controllers. No hardware dispatch.
return function(Mode,Desperation,Revive)
    local folder=game.Players.LocalPlayer and game.Players.LocalPlayer.PlayerScripts:FindFirstChild("NightfallClient")
    Mode=Mode or require(folder.InputMode)Desperation=Desperation or require(folder.DesperationControl)Revive=Revive or require(folder.ReviveControl)
    local n=0
    local function check(v,m)n+=1 assert(v,m)end
    local now,paid=0,0
    local messages={}
    local mode=Mode.new({keyboard=true,touch=true,gamepad=true})
    local risk=Desperation.new({clock=function()return now end,blocked=function()return false end,send=function()paid+=1 end})
    risk:Update({status="Combat",canDesperation=true,desperationCost=12,desperationCooldown=0})
    local revive=Revive.new(function(action,payload)table.insert(messages,{action,payload.held})end,function()return false end)
    revive:Update({status="Combat",revive={targetUserId=44,canStart=true,remaining=10,progress=0}})
    mode:Subscribe(function()risk:Reset()revive:Cancel()end)
    mode:Observe("Touch","Unknown",0,"hold")check(risk:TouchBegin(),"Touch cost hold begins")
    now=.2 mode:Observe("Keyboard","L",0)
    check(not mode:CanBegin("Keyboard"),"Foreign Special rejected before Handle")
    check(not risk.armed and paid==0,"Touch is not reinterpreted as paid chord")
    mode:Observe("Keyboard","K",0)check(not mode:CanBegin("Keyboard"),"Foreign Heavy cannot complete chord")
    risk:Handle("Special",Enum.UserInputState.End)check(risk.touchStart~=nil,"Rejected foreign Special End preserves touch ownership")
    now=.36 risk:Step()check(paid==1,"Original deliberate touch hold fires once")
    risk:Step()check(paid==1,"No repeated paid action")
    mode:EndPointer("hold")check(mode:Get()=="Keyboard"and risk.touchStart==nil,"Mode transition cancels old context")
    check(paid==1 and not risk.armed,"Deferred key does not replay")
    check(mode:CanBegin("Keyboard"),"Fresh key available after release")
    risk:Handle("Special",Enum.UserInputState.Begin)risk:Handle("Heavy",Enum.UserInputState.Begin)
    check(paid==2,"Fresh ordered keyboard chord still works")
    risk:Handle("Special",Enum.UserInputState.End)
    mode:Observe("Touch","Unknown",0,"revive")check(revive:Begin(),"Touch revive begins")
    mode:Observe("Gamepad1","ButtonL3",1)check(not mode:CanBegin("Gamepad1"),"Foreign revive begin denied")
    check(#messages==1 and messages[1][2]==true,"One revive begin")
    mode:EndPointer("revive")check(#messages==2 and messages[2][2]==false,"Transition releases revive once")
    revive:Cancel()check(#messages==2,"Later End idempotent")
    mode:Observe("Touch","Unknown",0,"short")risk:TouchBegin()now+=.1
    mode:Observe("Gamepad1","ButtonB",1)mode:EndPointer("short")risk:Step()
    check(paid==2,"Short touch hold never becomes paid on transition")
    mode:Observe("Touch","Unknown",0,"life")risk:TouchBegin()
    mode:ClearPointers()risk:Reset()revive:Cancel()now+=1 risk:Step()
    check(paid==2,"Focus/life reset leaves no delayed paid action")
    check(mode:CanBegin("Touch"),"Second touch remains eligible for ordinary multi-touch")
    return {passed=true,checks=n,paidActions=paid,reviveMessages=#messages,physicalInputVerified=false}
end
