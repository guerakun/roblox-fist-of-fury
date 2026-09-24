-- Root-only, isolated Studio SERVER Play fixture (~45 seconds).
-- Run after the frozen HumanBot series, with combat Waiting and no enemies.
-- Rebuilds the authored city; tests structural/lifetime behavior, not rendering or memory growth.
return function()
    local RunService=game:GetService("RunService")
    assert(RunService:IsStudio() and RunService:IsServer() and RunService:IsRunning(),"Isolated Studio server Play required")
    local S=game.ServerScriptService.NightfallServer
    local World=require(S.WorldBuilder)
    local Art=require(S.ArtAssetsInstaller)
    local Destruction=require(S.DestructionService)
    local Combat=require(S.CombatService)
    local Tags=game:GetService("CollectionService")
    local Lighting=game:GetService("Lighting")
    assert(Combat.GetRunStatus()=="Waiting" and next(Combat.GetEnemies())==nil,"Do not run during campaign/bot collection")
    local started=os.clock()
    local function untilTrue(predicate,seconds,message)
        local deadline=os.clock()+seconds
        repeat
            if predicate()then return end
            task.wait(.1)
        until os.clock()>=deadline
        assert(predicate(),message)
    end
    local function props(city)
        local result={}
        for _,model in ipairs(Tags:GetTagged("Destructible"))do
            if model:IsA("Model") and model:IsDescendantOf(city)then table.insert(result,model)end
        end
        table.sort(result,function(a,b)return a.Name<b.Name end)
        assert(#result==34,"Current authored scene must contain 34 breakable assemblies")
        return result
    end
    local function fresh()
        local old=workspace:FindFirstChild("NightfallCity")
        local city=World.Build()
        Art.DressWorld()
        assert(not old or old.Parent==nil,"Previous city still parented after replacement")
        local cities=0
        for _,child in ipairs(workspace:GetChildren())do if child.Name=="NightfallCity"then cities+=1 end end
        assert(cities==1,"Rebuild duplicated the named city")
        for _,name in ipairs({"NightfallAtmosphere","NightfallBloom","NightfallGrade"})do
            local count=0
            for _,child in ipairs(Lighting:GetChildren())do if child.Name==name then count+=1 end end
            assert(count==1,"Rebuild duplicated/missed owned lighting effect "..name)
        end
        return city
    end
    local function counts(city)
        local result={total=0,classes={},props=#props(city)}
        for _,item in ipairs(city:GetDescendants())do
            result.total+=1
            result.classes[item.ClassName]=(result.classes[item.ClassName]or 0)+1
        end
        return result
    end
    local function sameCounts(a,b)
        assert(a.total==b.total and a.props==b.props,"Rebuild changed scene/prop totals")
        for class,count in pairs(a.classes)do assert(b.classes[class]==count,"Rebuild changed "..class.." count")end
        for class,count in pairs(b.classes)do assert(a.classes[class]==count,"Rebuild added class "..class)end
    end
    Destruction.Init()
    local debris=assert(workspace:FindFirstChild("NightfallDebris"),"Debris folder missing")
    untilTrue(function()return #debris:GetChildren()==0 end,5,"Preexisting cosmetic debris did not expire")
    local ok,result=xpcall(function()
        local city=fresh()
        local baseline=counts(city)
        local assemblies=props(city)
        local saved={}
        for _,assembly in ipairs(assemblies)do
            assert(assembly.PrimaryPart,"Prop has no PrimaryPart")
            local record={model=assembly,health=assembly:GetAttribute("Health"),parts={},enabled={}}
            for _,item in ipairs(assembly:GetDescendants())do
                if item:IsA("BasePart")then
                    table.insert(record.parts,{part=item,transparency=item.Transparency,collide=item.CanCollide,
                        touch=item.CanTouch,query=item.CanQuery,shadow=item.CastShadow})
                elseif item:IsA("ParticleEmitter")or item:IsA("Light")then
                    table.insert(record.enabled,{item=item,value=item.Enabled})
                end
            end
            table.insert(saved,record)
        end
        local breakStart=os.clock()
        local broken=0
        -- No yield between breaks: the test can inspect the immediate global cap.
        for _,assembly in ipairs(assemblies)do broken+=Destruction.BreakNearby(assembly.PrimaryPart.Position,.1,1)end
        assert(broken==34,"Did not break every current assembly exactly once")
        for _,record in ipairs(saved)do
            assert(record.model:GetAttribute("Broken")==true and record.model:GetAttribute("Health")==0,"Prop was not marked broken")
            for _,state in ipairs(record.parts)do
                local part=state.part
                assert(part.Transparency==1 and not part.CanCollide and not part.CanTouch and not part.CanQuery and not part.CastShadow,"Broken prop retained visible/physical state")
            end
            for _,state in ipairs(record.enabled)do assert(not state.item.Enabled,"Broken prop retained emission/light")end
        end
        local peak=#debris:GetChildren()
        assert(peak==30,"Stress fixture did not reach the global 30-piece limit")
        for _,piece in ipairs(debris:GetChildren())do
            assert(piece:IsA("BasePart") and not piece.Anchored,"Unexpected debris object")
            assert(not piece.CanCollide and not piece.CanTouch and not piece.CanQuery and not piece.CastShadow,"Debris participates in gameplay queries/physics")
            assert(piece:GetNetworkOwner()==nil,"Debris must remain server owned")
            assert(#piece:GetChildren()==0 and #Tags:GetTags(piece)==0,"Fragment retained children/tags")
        end
        for _,assembly in ipairs(assemblies)do assert(Destruction.BreakNearby(assembly.PrimaryPart.Position,.1,1)==0,"Repeated break rescheduled an already broken assembly")end
        assert(#debris:GetChildren()==30,"Repeated break exceeded the debris cap")
        untilTrue(function()return #debris:GetChildren()==0 end,5,"Debris did not clean up")
        local cleanupSeconds=os.clock()-breakStart
        untilTrue(function()
            for _,assembly in ipairs(assemblies)do if assembly:GetAttribute("Broken")then return false end end
            return true
        end,23,"All 34 props did not restore within the observation deadline")
        for _,record in ipairs(saved)do
            assert(record.model:GetAttribute("Health")==record.health,"Restored prop health changed")
            for _,state in ipairs(record.parts)do
                local part=state.part
                assert(part.Transparency==state.transparency and part.CanCollide==state.collide and part.CanTouch==state.touch
                    and part.CanQuery==state.query and part.CastShadow==state.shadow,"Restored part properties differ")
            end
            for _,state in ipairs(record.enabled)do assert(state.item.Enabled==state.value,"Restored emitter/light state changed")end
        end
        local restoreSeconds=os.clock()-breakStart
        sameCounts(baseline,counts(city))

        -- Destroy a city while one of its restoration callbacks is still pending.
        local oldAssembly=assemblies[1]
        local oldName=oldAssembly.Name
        assert(Destruction.BreakNearby(oldAssembly.PrimaryPart.Position,.1,-1)>=1,"Pending-restore fixture did not break")
        local replacement=fresh()
        sameCounts(baseline,counts(replacement))
        assert(oldAssembly.Parent==nil,"Old assembly survived rebuild")
        local newAssembly=assert(replacement.StreetDetails:FindFirstChild(oldName),"Replacement prop identity missing")
        local originalHealth=newAssembly:GetAttribute("Health")
        local originalTransparency=newAssembly.PrimaryPart.Transparency
        -- Sentinels detect any stale callback that looks up/restores the replacement by name.
        newAssembly:SetAttribute("Health",12345)
        newAssembly.PrimaryPart.Transparency=.371
        local sentinelTransparency=newAssembly.PrimaryPart.Transparency -- engine stores a float32
        task.wait(21)
        assert(newAssembly:GetAttribute("Health")==12345 and newAssembly.PrimaryPart.Transparency==sentinelTransparency
            and newAssembly:GetAttribute("Broken")==false,"Old restoration callback changed replacement")
        assert(#debris:GetChildren()==0,"Old-world debris survived rebuild cleanup")
        newAssembly:SetAttribute("Health",originalHealth)
        newAssembly.PrimaryPart.Transparency=originalTransparency
        local repeated=fresh()
        sameCounts(baseline,counts(repeated))
        assert(Combat.GetRunStatus()=="Waiting" and next(Combat.GetEnemies())==nil,"Campaign started during isolated lifetime fixture")
        return {assemblies=34,peakDebris=peak,cleanupSeconds=cleanupSeconds,restoreSeconds=restoreSeconds,
            restoredProperties=true,repeatBreakRejected=true,stableBuildCounts=baseline,oldRestoreIsolated=true,
            elapsed=os.clock()-started,scope="Isolated Studio structural/lifetime fixture; no memory-growth/render/device claim"}
    end,debug.traceback)
    -- Leave an undamaged authored world even if a sentinel assertion fails.
    local cleanupOK,cleanupError=pcall(fresh)
    assert(cleanupOK,cleanupError)
    assert(ok,result)
    return result
end
