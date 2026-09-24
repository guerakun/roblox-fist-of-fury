-- Shared metadata presentation only. Matchmaking validates all submitted IDs again.
local Display={}
function Display.Definitions(config)
    local result={}
    for _,id in ipairs(config.Order)do
        local item=config.Contracts[id]
        if item then table.insert(result,{id=id,name=item.Name,description=item.Description,points=item.Points,reward=item.RewardPercent})end
    end
    return result
end
function Display.Available(config,id)
    return config.Enabled==true and config.Contracts[id]~=nil
end
function Display.Label(config,definition)
    if not Display.Available(config,definition.id)then return definition.name.." / NOT AVAILABLE"end
    return definition.name.." / "..definition.points.." HEAT / +"..definition.reward.."% EARNED\n"..definition.description
end
function Display.ApplyButton(button,config,definition,isLeader,isQueued)
    button.Text=Display.Label(config,definition)
    button.Active=Display.Available(config,definition.id)and isLeader==true and not isQueued
    button.Selectable=button.Active
end
function Display.Summary(config,selected)
    local result={ids={},points=0,rewardPercent=0}
    for _,id in ipairs(config.Order)do
        if selected[id]==true and Display.Available(config,id)then
            table.insert(result.ids,id)
            result.points+=config.Contracts[id].Points result.rewardPercent+=config.Contracts[id].RewardPercent
        end
    end
    return result
end
function Display.Toggle(config,selected,id,isLeader,isQueued)
    if not isLeader or isQueued or not Display.Available(config,id)then return false end
    selected[id]=not selected[id]return true
end
return Display
