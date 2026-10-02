-- Actual client rendered-instance geometry; root runs in isolated Play after source sync.
return function(Effects)
    local player=game.Players.LocalPlayer
    Effects=Effects or require(player.PlayerScripts.NightfallClient.BossEffects)
    local existing={}
    for _,child in ipairs(workspace:GetChildren())do existing[child]=true end
    local api=Effects.new({effects=1})
    local ownedFolder
    for _,child in ipairs(workspace:GetChildren())do
        if child.Name=="NightfallBossCosmetics" and not existing[child]then ownedFolder=child;break end
    end
    local results={passed=false,orientedCases=0,cleanup=false,physicalInputVerified=false}
    local ok,problem=pcall(function()
        local origin=Vector3.new(24,0,0)
        local frame=CFrame.fromMatrix(origin,Vector3.zAxis,Vector3.yAxis,-Vector3.xAxis)
        assert(api.Emit({enemy="LastConductor",shape="Box",position=origin,size=Vector3.new(40,10,8),cframe=frame}),"Missing train effect")
        task.wait(.04)
        assert(ownedFolder,"Missing isolated effect folder")
        local folder=ownedFolder.LastConductorImpact
        local rails,cars=0,0
        for _,part in ipairs(folder:GetChildren())do
            if part:IsA("BasePart")then
                assert(part.Anchored and not part.CanCollide and not part.CanTouch and not part.CanQuery)
                if part.Name=="GhostRail"then rails+=1 assert(math.abs(part.CFrame.LookVector:Dot(Vector3.zAxis))>.99,"Rail did not rotate")end
                if part.Name=="SpectralCarriage"then cars+=1 assert(math.abs(part.CFrame.RightVector:Dot(Vector3.zAxis))>.99,"Carriage basis wrong")end
            end
        end
        assert(rails==2 and cars==3,"Expected train pieces missing")results.orientedCases+=1
        task.wait(.08)
        for _,part in ipairs(folder:GetChildren())do
            if part.Name=="SpectralCarriage"then assert(math.abs(part.CFrame.RightVector:Dot(Vector3.zAxis))>.99,"Repeated update double-rotated")end
        end
        task.wait(.4)assert(#ownedFolder:GetChildren()==0)results.cleanup=true
        results.passed=true
    end)
    api.Destroy()assert(ok,problem)return results
end
