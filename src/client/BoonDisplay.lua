-- Earned-only boon labels and local affordances; the server owns eligibility and modifiers.
local Display={}
function Display.Ordered(boons)
    local result={}
    for _,enabled in ipairs({true,false})do
        for _,boon in ipairs(boons)do if (boon.Enabled~=false)==enabled then table.insert(result,boon)end end
    end
    return result
end
function Display.State(boon,snapshot)
    local enabled=boon.Enabled~=false
    local unlocked=enabled and (snapshot.xp or 0)>=(boon.XP or math.huge)
    local equipped=enabled and snapshot.boon==boon.Id
    local canEquip=unlocked and not equipped and snapshot.canEquipBoon==true
    local label=not enabled and "NOT AVAILABLE"or equipped and "EQUIPPED"or not unlocked and "LOCKED"
        or not snapshot.canEquipBoon and "AFTER FIGHT"or "EQUIP"
    local requirement=not enabled and "NOT AVAILABLE YET"or boon.XP==0 and "AVAILABLE TO EVERYONE"or tostring(boon.XP).." LIFETIME XP"
    return {enabled=enabled,unlocked=unlocked,equipped=equipped,canEquip=canEquip,label=label,requirement=requirement}
end
function Display.ApplyButton(button,boon,snapshot)
    local state=Display.State(boon,snapshot)
    button.Text=state.label button.Active=state.canEquip button.Selectable=state.canEquip button.AutoButtonColor=state.canEquip
    return state
end
return Display
