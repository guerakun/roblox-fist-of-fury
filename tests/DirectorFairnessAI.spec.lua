return function()
    local D=require(game.ServerScriptService.NightfallServer.AttackDirector)
    local state=D.New();local target={};local actors={{},{},{}}
    for i,actor in ipairs(actors)do state.slots[actor]={target=target,serial=i}end
    local chosen={}
    for round=1,3 do
        local t=100+(round-1)*.1
        for i,actor in ipairs(actors)do D.Request(state,actor,target,i<3,nil,t)end
        local granted=D.Grant(state,t,1)
        assert(#granted==1,"Cap remains authoritative")
        chosen[round]=granted[1];D.Release(state,granted[1])
    end
    assert(chosen[1]==actors[1] and chosen[2]==actors[2],"Rear priority retained for equal waiting age")
    assert(chosen[3]==actors[3],"Waiting front actor cannot starve behind repeated rear reservations")
    -- An expired reservation also counts as service; an unreachable actor cannot monopolize the cap.
    local blocked=D.New();local a,b={},{}
    blocked.slots[a]={target=target,serial=1};blocked.slots[b]={target=target,serial=2}
    D.Request(blocked,a,target,true,nil,100);D.Request(blocked,b,target,false,nil,100)
    assert(D.Grant(blocked,100,1)[1]==a,"Initial rear reservation")
    D.Release(blocked,a)
    D.Request(blocked,a,target,true,nil,103.1);D.Request(blocked,b,target,false,nil,103.1)
    assert(D.Grant(blocked,103.1,1)[1]==b,"Blocked reservation cannot win every expiry")
    local edge=D.New();local enemy={}
    local slot=D.Assign(edge,enemy,target,Vector3.new(10,3,0),Vector3.new(20,3,0),{MinX=0,MaxX=180})
    assert(slot.offset.X<0,"Initial left slot")
    slot=D.Assign(edge,enemy,target,Vector3.new(10,3,0),Vector3.new(6,3,0),{MinX=0,MaxX=180})
    assert(slot.offset.X>0,"Infeasible rear slot reassigns at left boundary")
    slot=D.Assign(edge,enemy,target,Vector3.new(170,3,0),Vector3.new(174,3,0),{MinX=0,MaxX=180})
    assert(slot.offset.X<0,"Infeasible front slot reassigns at right boundary")
    D.Reset(state);assert(next(state.lastGranted)==nil,"Campaign reset clears scheduling history")
    return {rotation=true,blockedReservationFairness=true,capPreserved=true}
end
