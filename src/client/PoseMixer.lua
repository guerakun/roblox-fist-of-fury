-- Sample imported clips and blend cosmetic joint poses; no root or camera motion.
local Mixer={}
function Mixer.Sample(data,time)
    local frames=data and data.frames
    if not frames or #frames==0 then return {}end
    local before,after=frames[1],frames[#frames]
    for i=1,#frames-1 do if time>=frames[i].time and time<=frames[i+1].time then before,after=frames[i],frames[i+1];break end end
    local alpha=math.clamp((time-before.time)/math.max(.0001,after.time-before.time),0,1)
    local result={}
    for body,pose in pairs(before.poses)do result[body]=pose:Lerp(after.poses[body]or pose,alpha)end
    return result
end
function Mixer.Blend(a,b,weight)
    local result={}
    for body,pose in pairs(a)do result[body]=pose:Lerp(b[body]or CFrame.identity,weight)end
    for body,pose in pairs(b)do if not result[body]then result[body]=CFrame.identity:Lerp(pose,weight)end end
    return result
end
function Mixer.Ground(poses)
    local result={}
    for body,pose in pairs(poses)do
        local rotation=pose-pose.Position
        local rotationWeight=body=="Torso"and .35 or body=="Head"and .5 or .8
        local offset=pose.Position*(body=="Torso"and .12 or .25)
        result[body]=CFrame.new(offset)*CFrame.identity:Lerp(rotation,rotationWeight)
    end
    return result
end
function Mixer.Weight(age,duration)
    return math.clamp(math.min(age/.055,(duration-age)/.10),0,1)
end
function Mixer.Locomotion(state,data,speed,grounded,dt,time)
    state.phase=(state.phase or 0)+dt*math.clamp(speed/16,0,1.8)
    local target=grounded and math.clamp(speed/5,0,1)or 0
    state.walk=(state.walk or 0)+(target-(state.walk or 0))*(1-math.exp(-16*dt))
    local idle=Mixer.Ground(Mixer.Sample(data.Idle,time%math.max(.05,data.Idle.duration)))
    local walk=Mixer.Ground(Mixer.Sample(data.Walk,state.phase%math.max(.05,data.Walk.duration)))
    local pose=Mixer.Blend(idle,walk,state.walk)
    if not grounded then
        pose=Mixer.Blend(pose,{Torso=CFrame.Angles(math.rad(-6),0,0),["Left Leg"]=CFrame.Angles(math.rad(-18),0,0),
            ["Right Leg"]=CFrame.Angles(math.rad(12),0,0),["Left Arm"]=CFrame.Angles(0,0,math.rad(-20)),["Right Arm"]=CFrame.Angles(0,0,math.rad(20))},.8)
    end
    return pose
end
return Mixer
