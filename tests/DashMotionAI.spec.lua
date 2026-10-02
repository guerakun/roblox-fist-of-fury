-- Instance/cleanup checks; actual displacement requires the real-client ArenaActions fixture.
return function(Dash)
    Dash=Dash or require(game.ServerScriptService.NightfallServer.DashMotion)
    local root=Instance.new("Part");root.Anchored=true;root.Parent=workspace
    local data={};local callbacks={};local n=0
    local function check(v,m)n+=1;assert(v,m)end
    local function schedule(duration,callback)check(duration==.18,"bounded authored duration");table.insert(callbacks,callback)end
    local ok,problem=xpcall(function()
        for _,direction in ipairs({Vector3.xAxis,Vector3.zAxis,Vector3.new(1,0,1).Unit})do
            Dash.Start(data,root,direction,schedule)
            local motion=data.dashMotion
            check(motion.force.VelocityConstraintMode==Enum.VelocityConstraintMode.Plane,"horizontal force only")
            check(motion.force.PrimaryTangentAxis==Vector3.xAxis and motion.force.SecondaryTangentAxis==Vector3.zAxis,"Y remains unconstrained")
            check((motion.force.PlaneVelocity-Vector2.new(direction.X,direction.Z)*74).Magnitude<.001,"authored XZ speed")
            callbacks[#callbacks]()
            check(data.dashMotion==nil and motion.force.Parent==nil and motion.attachment.Parent==nil,"timeout cleans both instances")
        end
        Dash.Start(data,root,Vector3.zAxis,schedule);local old=callbacks[#callbacks]
        Dash.Start(data,root,Vector3.xAxis,schedule);local current=data.dashMotion
        old();check(data.dashMotion==current,"stale timeout cannot cancel newer life/action")
        Dash.Stop(data);check(data.dashMotion==nil and #root:GetChildren()==0,"explicit hit/reset cleanup")
        Dash.Stop(data);check(data.dashMotion==nil,"cleanup is idempotent")
    end,debug.traceback)
    Dash.Stop(data);root:Destroy();assert(ok,problem)
    return {passed=true,assertions=n,scope="Actuator axes, speed and cleanup; real motion separate"}
end
