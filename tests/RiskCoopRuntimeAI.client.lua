-- Disposable Studio companion: real timed Block intents and observation of replicated enemy FX.
if not game:GetService("RunService"):IsStudio()then return end
local qa=game.ReplicatedStorage:WaitForChild("RiskCoopQA",70)
if not qa then return end
local remotes=game.ReplicatedStorage.Nightfall.Remotes
local tracked=nil
local observed={tells=0,impacts=0,afterCancelTells=0,afterCancelImpacts=0,cancelled=false,perfect=false}
qa.OnClientEvent:Connect(function(packet)
    if packet.kind=="Track"then
        tracked=packet.model
        observed={tells=0,impacts=0,afterCancelTells=0,afterCancelImpacts=0,cancelled=false,perfect=false}
        qa:FireServer("Ack",packet.serial)
    elseif packet.kind=="ParryAt"then
        task.spawn(function()
            while workspace:GetServerTimeNow()<packet.at do task.wait()end
            remotes.Action:FireServer("Block",{held=true,direction=packet.direction})
            qa:FireServer("Pressed",{serial=packet.serial,at=workspace:GetServerTimeNow(),targetAt=packet.at})
        end)
    elseif packet.kind=="Release"then
        remotes.Action:FireServer("Block",{held=false})
        qa:FireServer("Ack",packet.serial)
    elseif packet.kind=="Report"then qa:FireServer("Report",{serial=packet.serial,observed=table.clone(observed)})end
end)
remotes.FX.OnClientEvent:Connect(function(event)
    if event.targetModel==tracked then
        if event.kind=="Telegraph"then
            observed.tells+=1
            if observed.cancelled then observed.afterCancelTells+=1 end
        elseif event.kind=="EnemyImpact"then
            observed.impacts+=1
            if observed.cancelled then observed.afterCancelImpacts+=1 end
        elseif event.kind=="EnemyCancel"then observed.cancelled=true end
    end
    if event.kind=="PerfectBlock"and event.attackerModel==tracked then observed.perfect=true end
end)
qa:FireServer("Hello")
