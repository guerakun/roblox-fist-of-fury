-- Pure rectangle contract; widget rendering is a separate fixture.
return function(Layout)
    Layout=Layout or require(game.Players.LocalPlayer.PlayerScripts.NightfallClient.CompactHUDLayout)
    local n=0
    local function check(v,m)n+=1 assert(v,m)end
    local function overlap(a,b)return a.x<b.x+b.w and b.x<a.x+a.w and a.y<b.y+b.h and b.y<a.y+a.h end
    for _,size in ipairs({{749,361},{320,320},{360,640},{1280,720}})do
        for _,mode in ipairs({"Keyboard","Gamepad","Touch"})do
            for _,rescue in ipairs({false,true})do
                local l=Layout.Compute(size[1],size[2],mode,rescue,false)
                if l then
                    for _,key in ipairs({"top","encounter","settings","progress","health","style","boss","warning","abilities"})do
                        local r=l[key]check(r.x>=0 and r.y>=0 and r.x+r.w<=size[1] and r.y+r.h<=size[2],key.." safe bounds")
                    end
                    check(not overlap(l.top,l.settings)and not overlap(l.encounter,l.progress)and not overlap(l.settings,l.progress),"Menu buttons do not overlap headers")
                    check(not overlap(l.health,l.style),"Style/health separation")
                    check(not overlap(l.boss,l.health)and not overlap(l.boss,l.style),"Boss/health separation")
                    check(not overlap(l.warning,l.abilities),"Critical warning avoids buttons")
                    for _,r in ipairs(l.cells)do check(r.w>=44 and r.h>=44,"Minimum target44")end
                    if mode=="Touch"then
                        check(not overlap(l.pad,l.abilities)and not overlap(l.jump,l.abilities)and not overlap(l.pad,l.jump),"Touch control separation")
                        check(l.jump.w>=44 and l.jump.h>=44,"Jump44")
                        if rescue then check(l.abilities.y+l.abilities.h<=size[2]-60,"Footer clear")end
                    end
                    local again=Layout.Compute(size[1],size[2],mode,rescue,false)
                    check(again.abilities.y==l.abilities.y,"No cumulative layout offset")
                else check(size[1]>=650 and size[2]>=450,"Only spacious viewport uses existing full layout")end
            end
        end
    end
    for _,heroChoices in ipairs({false,true})do
        local l=Layout.Compute(320,320,"Touch",true,heroChoices)
        check(not overlap(l.toast,l.abilities),"Notification row avoids thumb actions")
        for i=1,3 do
            local hero={x=8+(i-1)*48,y=56,w=44,h=44}
            if heroChoices then check(not overlap(hero,l.health)and not overlap(hero,l.boss)and not overlap(hero,l.abilities),"Hero choices remain accessible")end
        end
        for _,critical in ipairs({false,true})do for _,notice in ipairs({false,true})do
            local main,progress=Layout.ToastVisibility(true,critical,notice)
            check(not(main and progress)and(not critical or(not main and not progress)),"Critical/notification row is mutually exclusive")
        end end
    end
    return {passed=true,checks=n,viewports=4,modes=3,rescueStates=2,physicalInputVerified=false}
end
