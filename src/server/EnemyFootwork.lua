-- Physical waiting footwork. Fixed waypoints avoid Humanoid.MoveTo's one-stud arrival dead zone.
local Footwork={}
local offsets={Vector3.new(2.5,0,3),Vector3.new(-2.5,0,-3),Vector3.new(2.5,0,-3),Vector3.new(-2.5,0,3)}
local function flatDistance(a,b)return Vector2.new(a.X-b.X,a.Z-b.Z).Magnitude end
function Footwork.Goal(data,origin,center,t,constrain)
    local goal=data.footworkGoal
    if not goal or flatDistance(origin,goal)<.8 or t>=(data.footworkUntil or 0)
        or not data.footworkCenter or flatDistance(center,data.footworkCenter)>3 then
        local chosen,bestDistance
        for step=1,#offsets do
            local index=((data.footworkIndex or 0)+step-1)%#offsets+1
            local candidate=constrain(center+offsets[index])
            if candidate then
                local distance=flatDistance(candidate,origin)
                if not bestDistance or distance>bestDistance then chosen,bestDistance={point=candidate,index=index},distance end
                if distance>=2.5 then chosen={point=candidate,index=index};break end
            end
        end
        if chosen then
            goal=chosen.point;data.footworkIndex=chosen.index;data.footworkGoal=goal
            data.footworkCenter=center;data.footworkUntil=t+1.2
        end
    end
    return goal and constrain(goal) or center
end
function Footwork.Direction(origin,goal)
    local delta=Vector3.new(goal.X-origin.X,0,goal.Z-origin.Z)
    return delta.Magnitude>.15 and delta.Unit or Vector3.zero
end
return Footwork
