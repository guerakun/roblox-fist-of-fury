-- Accepted server dash only. A short replicated horizontal actuator survives idle Humanoid braking.
-- It never writes CFrame, network ownership, yaw, or vertical force.
local Dash={Duration=.16,Speed=58,BrakeDuration=.08,PresentationDuration=.30}
function Dash.Stop(data)
    local motion=data and data.dashMotion
    if not motion then return end
    data.dashMotion=nil
    motion.force:Destroy();motion.attachment:Destroy()
end
function Dash.Start(data,root,direction,schedule)
    Dash.Stop(data)
    local attachment=Instance.new("Attachment")
    attachment.Name="CurtainBreakDashAttachment";attachment.Parent=root
    local force=Instance.new("LinearVelocity")
    force.Name="CurtainBreakDashVelocity";force.Attachment0=attachment
    force.RelativeTo=Enum.ActuatorRelativeTo.World
    force.VelocityConstraintMode=Enum.VelocityConstraintMode.Plane
    force.PrimaryTangentAxis=Vector3.xAxis;force.SecondaryTangentAxis=Vector3.zAxis
    force.PlaneVelocity=Vector2.new(direction.X,direction.Z)*Dash.Speed
    force.ForceLimitsEnabled=false
    local motion={force=force,attachment=attachment}
    data.dashMotion=motion;force.Parent=root
    local enqueue=schedule or task.delay
    enqueue(Dash.Duration,function()
        if data.dashMotion~=motion then return end
        local humanoid=root.Parent and root.Parent:FindFirstChildOfClass("Humanoid")
        local input=humanoid and humanoid.MoveDirection or Vector3.zero
        local desired=Vector2.new(input.X,input.Z)
        if desired.Magnitude>1 then desired=desired.Unit end
        force.PlaneVelocity=desired*(humanoid and humanoid.WalkSpeed or 0)
        motion.braking=true
        enqueue(Dash.BrakeDuration,function()
            if data.dashMotion==motion then Dash.Stop(data)end
        end)
    end)
end
return Dash
