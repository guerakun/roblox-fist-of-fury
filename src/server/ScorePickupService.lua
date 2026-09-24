-- Server-owned physical score pickups. The registry claims before any effect is dispatched.
local Registry=require(script.Parent.PickupRegistry)
local Visuals=require(script.Parent.PickupVisuals)
local Players=game:GetService("Players")
local Service={}
Service.__index=Service
function Service.new(runId,callbacks)
    return setmetatable({registry=Registry.new(runId),callbacks=callbacks,visuals={}},Service)
end
function Service:DestroyRecord(record)
    local visual=self.visuals[record.id]
    if visual then visual:Destroy();self.visuals[record.id]=nil end
end
function Service:Spawn(id,position,expiresAt,context)
    local record=self.registry:Spawn(id,"ScoreOrb",position,expiresAt,context)
    if not record then return nil end
    local folder=workspace:FindFirstChild("CombatPickups")
    if not folder then folder=Instance.new("Folder");folder.Name="CombatPickups";folder.Parent=workspace end
    local visual=Visuals.ScoreOrb(folder,position,id,expiresAt)
    self.visuals[id]=visual
    local sensor=Instance.new("Part")
    sensor.Name="ServerTouchSensor";sensor.Shape=Enum.PartType.Ball;sensor.Size=Vector3.new(3,3,3)
    sensor.Anchored=true;sensor.Transparency=1;sensor.CanCollide=false;sensor.CanQuery=false;sensor.CanTouch=true
    sensor.CFrame=CFrame.new(position);sensor.Parent=visual
    sensor.Touched:Connect(function(part)
        local character=part:FindFirstAncestorOfClass("Model")
        local player=character and Players:GetPlayerFromCharacter(character)
        local root=character and character:FindFirstChild("HumanoidRootPart")
        if not player or not root or player.Character~=character then return end
        local t=workspace:GetServerTimeNow()
        local eligible=self.callbacks.Eligible(player,record.payload)
        local claimed=self.registry:Claim(id,record.generation,t,player.UserId,(root.Position-position).Magnitude,eligible,5,record.runId)
        if not claimed then return end
        self:DestroyRecord(claimed)
        self.callbacks.Claimed(player,claimed)
    end)
    return record
end
function Service:Step(t)
    for _,record in ipairs(self.registry:Sweep(t))do self:DestroyRecord(record)end
end
function Service:Clear()
    for _,record in ipairs(self.registry:Clear())do self:DestroyRecord(record)end
end
return Service
