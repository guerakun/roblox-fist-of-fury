-- Root runs after rebuilding the world. Structural schema, not visible entry/pulse evidence.
return function()
    local Config = require(game.ReplicatedStorage.Nightfall.Shared.Config)
    local city = assert(workspace:FindFirstChild("NightfallCity"), "Build the campaign world first")
    local entries = assert(city:FindFirstChild("EnemyEntries"), "Entry schema missing")
    local scenery = assert(city:FindFirstChild("EnemyEntryScenery"), "Door silhouettes missing")
    assert(entries:GetAttribute("SchemaVersion")==1 and city:GetAttribute("EntryMarkerVersion")==1, "Entry version mismatch")
    local waves, markers, sceneryParts = 0, 0, 0
    for stageIndex, stage in ipairs(Config.Stages) do
        for waveIndex, wave in ipairs(stage.Waves) do
            waves += 1
            local name = "Stage"..stageIndex.."_Wave"..waveIndex
            local group = assert(entries:FindFirstChild(name), "Missing encounter "..name)
            assert(group:GetAttribute("Stage")==stageIndex and group:GetAttribute("Wave")==waveIndex, "Wrong encounter identity")
            assert(group:GetAttribute("WaveCenterX")==wave.SpawnX and #group:GetChildren()==4, "Wave anchor contract changed")
            for _, kind in ipairs({"Left", "Right", "Door", "Drop"}) do
                local marker = assert(group:FindFirstChild(kind), "Missing entry "..name..":"..kind)
                assert(marker:IsA("BasePart") and marker.Anchored and marker.Transparency==1, "Marker must remain an invisible anchor")
                assert(not marker.CanQuery and not marker.CanTouch and not marker.CanCollide, "Entry marker obstructs combat")
                assert(marker:GetAttribute("EntryKind")==kind, "Entry kind mismatch")
                assert(marker.Position.X>=stage.MinX+6 and marker.Position.X<=stage.MaxX-6, "Entry outside stage bounds")
                assert(math.abs(marker.Position.Z)<=12, "Entry outside lane staging bounds")
                if kind=="Drop" then
                    local landing = marker:GetAttribute("LandingPosition")
                    assert(marker.Position.Y==14 and typeof(landing)=="Vector3", "Drop start/landing contract missing")
                    assert(landing==Vector3.new(marker.Position.X,0,marker.Position.Z), "Drop landing not on floor")
                else assert(marker.Position.Y==0, "Spawn routine requires floor-height anchor") end
                markers += 1
            end
            assert(group.Left.Position.X<group.Door.Position.X and group.Right.Position.X>group.Door.Position.X, "Side entrances must bracket encounter")
            assert(group.Door.Position.Z==-12, "Background entrance changed lane")
            local door = assert(scenery:FindFirstChild(name), "Missing authored door "..name)
            assert(#door:GetChildren()==5, "Unexpected service-door part budget")
            for _, part in ipairs(door:GetChildren()) do
                assert(part:IsA("BasePart") and part.Anchored, "Door must be static native geometry")
                assert(not part.CanQuery and not part.CanTouch and not part.CanCollide, "Door interferes with combat")
                assert(part.Position.Z+part.Size.Z/2<-14, "Door intrudes into playable lane")
                sceneryParts += 1
            end
        end
    end
    assert(#entries:GetChildren()==waves and #scenery:GetChildren()==waves, "Orphan entry records")
    return {encounters=waves,markers=markers,sceneryParts=sceneryParts,schema=1}
end
