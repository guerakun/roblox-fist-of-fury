-- Root-only isolated Studio geometry fixture. Rebuilds the world; never run during a campaign.
return function(World,Config,Installer)
    local city=World.Build()
    if Installer then Installer.DressWorld() end
    local floor=assert(city.Streets:FindFirstChild("ContinuousCombatFloor"))
    assert(floor.CanCollide and floor.Position.Y+floor.Size.Y/2==0 and floor.Size.Z>=56,"widened physical floor")
    local gates,markers=0,0
    local roles={"Wave","Wave","Miniboss","Boss"}
    for stageIndex,stage in ipairs(Config.Stages)do
        local entrance=assert(city.Streets:FindFirstChild("StageEntrance"..stageIndex))
        assert(entrance.CanCollide and entrance.Position.X+entrance.Size.X/2==stage.MinX+4,"closed rear entrance")
        for areaIndex,wave in ipairs(stage.Waves)do
            assert(wave.Kind==roles[areaIndex],"two skirmishes then mini and boss")
            local b=wave.Bounds
            local gate=assert(city.Gates:FindFirstChild("Stage"..stageIndex.."_Area"..areaIndex))
            assert(gate:IsA("BasePart") and gate.Anchored and gate.CanCollide and not gate:GetAttribute("Opened"),"initial exit closed")
            assert(gate.Position.X==b.MaxX and gate.Size.X==1 and gate.Size.Z>=b.MaxZ-b.MinZ+4 and gate.Size.Y>=48,"exit bounds")
            gates+=1
            local group=assert(city.EnemyEntries:FindFirstChild("Stage"..stageIndex.."_Wave"..areaIndex))
            for _,kind in ipairs({"Left","Right","Door","Drop"})do
                local marker=assert(group:FindFirstChild(kind));local q=marker.Position
                assert(q.X>=b.MinX+6 and q.X<=b.MaxX-6 and q.Z>=b.MinZ+6 and q.Z<=b.MaxZ-6,"spawn inset")
                assert(not marker.CanCollide and not marker.CanQuery and not marker.CanTouch and marker.Transparency==1,"marker cosmetic only")
                assert(q.Y==(kind=="Drop" and 14 or 0),"floor/root coordinate contract")
                if kind=="Drop" then assert(marker:GetAttribute("LandingPosition")==Vector3.new(q.X,0,q.Z),"landing anchor")end
                markers+=1
            end
        end
    end
    assert(gates==12 and markers==48,"complete three-district layout")
    local props=0
    for _,item in ipairs(city:GetDescendants())do
        if item:IsA("Model") and item:GetAttribute("Destructible")then
            props+=1
            assert(item.PrimaryPart and math.abs(item.PrimaryPart.Position.Z)>=25,"props moved outside combat interior")
        end
        if item:IsA("BasePart") and (item:IsDescendantOf(city.Architecture) or item:IsDescendantOf(city.StreetDetails))then
            assert(not item.CanCollide,"scenery never obstructs combat")
        end
    end
    assert(props==34,"preserved all breakable assemblies")
    local dressedParts=0
    if Installer then
        for _,item in ipairs(city.AuthoredMeshDetails:GetDescendants())do
            if item:IsA("BasePart")then
                assert(not item.CanCollide and not item.CanQuery and not item.CanTouch,"mesh decor nonphysical")
                for _,x in ipairs({-1,1})do for _,y in ipairs({-1,1})do for _,z in ipairs({-1,1})do
                    local corner=item.CFrame:PointToWorldSpace(item.Size*Vector3.new(x,y,z)/2)
                    assert(corner.Z < -24,"pump part bounds outside arena")
                end end end
                dressedParts+=1
            end
        end
        assert(dressedParts==12,"three preserved pumps")
    end
    return {passed=true,gates=gates,entryMarkers=markers,destructibles=props,dressedParts=dressedParts,buildVersion=city:GetAttribute("BuildVersion"),
        scope="Actual built geometry only; gate transitions, player movement, attack fairness and visual readability require separate play tests"}
end
