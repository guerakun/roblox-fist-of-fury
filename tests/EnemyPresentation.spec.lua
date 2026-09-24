-- Client module test; root owns execution and records actual results.
return function(Presentation)
    Presentation = Presentation or require(game.Players.LocalPlayer.PlayerScripts:FindFirstChild("EnemyPresentation", true))
    local ids = {"HuskJab","HuskJumpKick","StriderSlide","StriderJab","GrapplerGrab","GrapplerThrow","PitcherThrow","PitcherShove","WardenCounter","WardenKick","LeaperVaultKick","LeaperJab","BruteFlop","BruteSwing","LeaperEvade"}
    for _, id in ipairs(ids) do
        for _, tell in ipairs({true, false}) do
            local pose = Presentation.Pose(id, .5, tell)
            assert(type(pose) == "table", "Missing pose " .. id)
            for _, transform in pairs(pose) do assert(typeof(transform) == "CFrame", "Invalid pose") end
        end
    end
    local folder = Instance.new("Folder"); folder.Name = "EnemyPresentationSpec"; folder.Parent = workspace
    local api = Presentation.new(folder, {effects = 0, highContrast = true})
    api.Emit({kind="EnemyProjectile",origin=Vector3.new(1,4,0),endpoint=Vector3.new(11,4,0),duration=.2})
    local p = folder:FindFirstChild("EnemyProjectileCue")
    assert(p and p.Anchored and not p.CanQuery and not p.CanTouch and not p.CanCollide, "Unsafe or missing critical projectile")
    task.wait(.4)
    assert(#folder:GetChildren()==0, "Projectile cleanup")
    local owner = Instance.new("Model"); owner.Parent = workspace
    api.Emit({kind="EnemyProjectile",origin=Vector3.new(1,4,0),endpoint=Vector3.new(11,4,0),duration=1,targetModel=owner})
    api.Emit({kind="EnemyCancel",targetModel=owner})
    assert(#folder:GetChildren()==0, "Cancelled projectile remains")
    api.Emit({kind="EnemyProjectile",origin=Vector3.new(1,4,0),endpoint=Vector3.new(11,4,0),duration=1,targetModel=owner})
    owner:Destroy(); task.wait()
    assert(#folder:GetChildren()==0, "Removed enemy projectile remains")
    local entryOwner=Instance.new("Model"); entryOwner.Parent=workspace
    local entryRoot=Instance.new("Part"); entryRoot.Name="HumanoidRootPart"; entryRoot.Anchored=true
    entryRoot.CanCollide=false; entryRoot.CanQuery=false; entryRoot.CanTouch=false; entryRoot.Position=Vector3.new(0,-300,0); entryRoot.Parent=entryOwner
    for _,kind in ipairs({"Left","Right","Door","Drop"}) do
        api.Emit({kind="EnemyEntry",targetModel=entryOwner,entry=kind,duration=.3})
        assert(entryOwner:FindFirstChild("EnemyEntryCue") and entryRoot:FindFirstChild("EntryDirection"), "Entry cue missing "..kind)
        task.wait(.4)
        assert(not entryOwner:FindFirstChild("EnemyEntryCue") and not entryRoot:FindFirstChild("EntryDirection"), "Entry cue cleanup "..kind)
    end
    entryOwner:Destroy()
    local player = game.Players.LocalPlayer
    local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
    assert(root, "Local rig required for rescue cue test")
    api.Emit({kind="EnemyGrab",targetUserId=player.UserId,duration=1})
    local cue = root:FindFirstChild("CoopGrabRescue")
    assert(cue and string.find(cue.TextLabel.Text,"YOU ARE GRABBED"), "Victim cue missing")
    api.Emit({kind="EnemyGrabRelease",targetUserId=player.UserId})
    assert(not root:FindFirstChild("CoopGrabRescue"), "Rescue cue remains")
    folder:Destroy()
    return {poses=30,criticalProjectileAtEffectsZero=true,cleanup=true,cancel=true,ownerRemoval=true,grabRelease=true,entryCue=true,entryKinds=4}
end
