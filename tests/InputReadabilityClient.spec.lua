-- Actual widgets using shared production mode/rectangle modules. No hardware dispatch claim.
-- Full Main/CombatHUD rendering, decorative overlays and physical gestures remain separate root checks.
return function(modules)
    local player=game.Players.LocalPlayer
    local folder=player.PlayerScripts:FindFirstChild("NightfallClient")
    modules=modules or {}
    local function get(name)return modules[name]or require(folder[name])end
    local Mode,Layout=get("InputMode"),get("CompactHUDLayout")
    local Control,DesperationHUD=get("DesperationControl"),get("DesperationHUD")
    local gui=Instance.new("ScreenGui")gui.Name="InputReadabilityFixture"gui.Parent=player.PlayerGui
    local frame=Instance.new("Frame")frame.BackgroundTransparency=1 frame.Parent=gui
    local function widget(class,parent)local o=Instance.new(class or "Frame")o.Parent=parent or frame return o end
    local widgets={buttons={}}
    for _,key in ipairs({"top","encounter","health","abilities","pad","jump","settings","progress","boss","warning","style","toast"})do
        widgets[key]=widget(key=="jump"and "TextButton"or "Frame")
    end
    local labels={}
    for i=1,6 do local button=widget("TextButton",widgets.abilities)button.Text=""widgets.buttons[i]=button
        local label=widget("TextLabel",button)label.Size=UDim2.fromScale(1,1)labels[i]=label end
    local progressToast=widget("Frame")
    local heroButtons={}for i=1,3 do heroButtons[i]=widget("TextButton",widgets.health)end
    local footer=widget("Frame")footer.Size=UDim2.new(1,-16,0,50)
    local mode=Mode.new({keyboard=true,touch=true,gamepad=true})
    local colors={panel=Color3.fromRGB(20,30,40),orange=Color3.fromRGB(255,170,70)}
    local sends=0
    local control=Control.new({send=function()sends+=1 end,blocked=function()return false end})
    control:Update({status="Combat",canDesperation=true,desperationCost=12,desperationCooldown=0})
    local risk=DesperationHUD.new({control=control,special=widgets.buttons[3],colors=colors,inputMode=mode})
    local n=0
    local function check(v,m)n+=1 assert(v,m)end
    local function overlaps(a,b)return a.AbsolutePosition.X<b.AbsolutePosition.X+b.AbsoluteSize.X and b.AbsolutePosition.X<a.AbsolutePosition.X+a.AbsoluteSize.X
        and a.AbsolutePosition.Y<b.AbsolutePosition.Y+b.AbsoluteSize.Y and b.AbsolutePosition.Y<a.AbsolutePosition.Y+a.AbsoluteSize.Y end
    local ok,result=xpcall(function()
        for _,size in ipairs({{749,361},{320,320},{360,640},{1280,720}})do
            frame.Size=UDim2.fromOffset(size[1],size[2])
            for _,name in ipairs({"Keyboard","Touch","Keyboard","Gamepad","Touch","Gamepad"})do
                mode:Request(name)
                for _,rescue in ipairs({false,true})do
                    local l=Layout.Compute(size[1],size[2],mode:Get(),rescue,false)
                    if l then
                        Layout.Main(l,widgets)
                        widgets.pad.Visible=name=="Touch"widgets.pad.Active=widgets.pad.Visible
                        widgets.jump.Visible=name=="Touch"widgets.jump.Active=widgets.jump.Visible
                        footer.Visible=rescue footer.Position=UDim2.fromOffset(8,size[2]-58)
                        local captions=mode:Captions()for i,label in ipairs(labels)do label.Text=captions[i]end
                        risk.Render(name=="Touch")
                        game:GetService("RunService").RenderStepped:Wait()
                        check(widgets.pad.Visible==(name=="Touch")and widgets.jump.Active==(name=="Touch"),"Layout agrees with mode")
                        check(labels[1].Text==(name=="Touch"and "TAP"or name=="Gamepad"and "X"or "J"),"Captions agree")
                        for _,button in ipairs(widgets.buttons)do check(button.AbsoluteSize.X>=44 and button.AbsoluteSize.Y>=44,"44px target")end
                        check(not overlaps(widgets.settings,widgets.progress)and not overlaps(widgets.settings,widgets.top)and not overlaps(widgets.progress,widgets.encounter),"Header controls separate")
                        check(not overlaps(widgets.health,widgets.style)and not overlaps(widgets.warning,widgets.abilities),"Readout separation")
                        if name=="Touch"then
                            check(not overlaps(widgets.pad,widgets.abilities)and not overlaps(widgets.jump,widgets.abilities),"Thumb controls separate")
                            check(risk.button.Visible and risk.button.AbsoluteSize.Y>=44,"Deliberate cost target")
                            check(string.find(risk.button.CostLabel.Text,"+12% SELF",1,true)~=nil,"Cost explicit")
                        else check(not risk.button.Visible and widgets.buttons[3].Visible,"Normal special restored")end
                        if rescue then check(not overlaps(footer,widgets.abilities)and(not widgets.pad.Visible or not overlaps(footer,widgets.pad)),"Rescue footer reserve")end
                    else check(size[1]==1280 and size[2]==720,"Spacious fallback uses existing layout")end
                end
            end
        end
        frame.Size=UDim2.fromOffset(320,320)
        for _,chooseHero in ipairs({false,true})do
            local l=Layout.Compute(320,320,"Touch",true,chooseHero)
            Layout.Main(l,widgets);Layout.Place(progressToast,l.toast)
            for i,button in ipairs(heroButtons)do
                button.Visible=chooseHero;button.Position=UDim2.fromOffset((i-1)*48,56-l.health.y);button.Size=UDim2.fromOffset(44,44)
            end
            for _,critical in ipairs({false,true})do for _,notice in ipairs({false,true})do
                local showMain,showProgress=Layout.ToastVisibility(true,critical,notice)
                widgets.warning.Visible=critical;widgets.toast.Visible=showMain;progressToast.Visible=showProgress
                game:GetService("RunService").RenderStepped:Wait()
                check(not(widgets.toast.Visible and progressToast.Visible),"Only one notification owns row")
                for _,notification in ipairs({widgets.toast,progressToast,widgets.warning})do
                    if notification.Visible then check(not overlaps(notification,widgets.abilities),"Actual notification avoids thumb actions")end
                end
                if chooseHero then for _,button in ipairs(heroButtons)do
                    check(button.Visible and button.AbsoluteSize.X>=44 and button.AbsoluteSize.Y>=44,"Short hero target remains available")
                    check(not overlaps(button,widgets.health)and not overlaps(button,widgets.boss)and not overlaps(button,widgets.abilities),"Actual hero choices clear readouts and controls")
                end end
            end end
        end
        check(sends==0,"Rendering never requests paid action")
        return {passed=true,checks=n,viewports=4,transitionSequence=6,rescueStates=2,sharedWidgetGeometry=true,fullMainIntegrationVerified=false,physicalInputVerified=false}
    end,debug.traceback)
    risk.Destroy()gui:Destroy()assert(ok,result)return result
end
