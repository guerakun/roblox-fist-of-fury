-- Scripted real remote burst plus passive accepted FX observation. No animation/position writes.
local p=game.Players.LocalPlayer
local remotes=game.ReplicatedStorage.Nightfall.Remotes
local qa=remotes:WaitForChild("AttackRhythmQA")
local echoes={}
local presentationBefore
local function presentationState()
    return {starts=p:GetAttribute("PresentationStartCount")or 0,poseStart=p:GetAttribute("PresentationPoseStart")}
end
local connection=remotes.FX.OnClientEvent:Connect(function(event)
    if event.kind=="Attack"and event.playerUserId==p.UserId then
        table.insert(echoes,{attackId=event.attackId,actorLife=event.actorLife,requestId=event.requestId,startAt=event.startAt,duration=event.duration,action=event.action,combo=event.combo})
    end
end)
qa.OnClientEvent:Connect(function(command)
    if command=="Burst"then
        presentationBefore=presentationState()
        for i=1,12 do remotes.Action:FireServer("Light",{direction=Vector3.xAxis,requestId=i})end
        qa:FireServer("Sent")
    elseif command=="Report"then
        qa:FireServer("Echoes",{echoes=echoes,presentationBefore=presentationBefore,presentationAfter=presentationState()})
    end
end)
script.Destroying:Connect(function()connection:Disconnect()end)
qa:FireServer("Ready")
