-- Accepted server dash only. A short replicated horizontal actuator survives idle Humanoid braking.
-- It never writes CFrame, network ownership, yaw, or vertical force.
local Dash={Duration=.18,Speed=74}
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
        if data.dashMotion==motion then Dash.Stop(data)end
    end)
end
return Dash
