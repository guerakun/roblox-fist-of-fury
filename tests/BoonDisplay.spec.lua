-- Presentation permission mirror only; authoritative boon checks have separate server specs.
return function(Display,Config)
    Display=Display or require(game.ServerScriptService.BoonDisplay)
    Config=Config or require(game.ReplicatedStorage.Nightfall.Shared.ProgressionConfig)
    local count=0 local function check(v)assert(v)count+=1 end
    local snapshot={xp=1000000,boon="Guardian",canEquipBoon=true}
    local fixture={}
    local pending={GlassCannon=true,Berserker=true,Anchor=true}
    for _,boon in ipairs(Config.Boons)do
        local copy=table.clone(boon)if pending[copy.Id]then copy.Enabled=false end table.insert(fixture,copy)
    end
    local order=Display.Ordered(fixture)local disabledSeen=false local disabled=0
    for _,boon in ipairs(order)do
        local state=Display.State(boon,snapshot)
        if boon.Enabled==false then
            disabledSeen=true disabled+=1
            check(not state.canEquip and not state.unlocked and state.label=="NOT AVAILABLE")
            local forged={xp=1000000,boon=boon.Id,canEquipBoon=true}
            check(Display.State(boon,forged).label=="NOT AVAILABLE")
        else check(not disabledSeen)end
    end
    check(disabled==3 and #order==#Config.Boons and order[1].Id=="Guardian")
    local enabled={Id="TestEarned",XP=600}
    check(Display.State(enabled,{xp=599,canEquipBoon=true}).label=="LOCKED")
    check(Display.State(enabled,{xp=600,canEquipBoon=true}).canEquip)
    check(Display.State(enabled,{xp=600,canEquipBoon=false}).label=="AFTER FIGHT")
    check(not Display.State(enabled,{xp=600,canEquipBoon=false}).canEquip)
    check(Display.State(enabled,{xp=600,boon="TestEarned",canEquipBoon=true}).label=="EQUIPPED")
    check(not Display.State(enabled,{xp=600,boon="TestEarned",canEquipBoon=true}).canEquip)
    check(not Display.State(enabled,{xp=600}).canEquip)
    return {passed=true,checks=count,disabledBoons=disabled,earnedThreshold=true,enabledFirst=true,betweenFightGate=true,noPaidUnlock=true}
end
