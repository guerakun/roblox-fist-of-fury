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
    api.Emit({kind="EnemyEntry",targetModel=owner,duration=.3})
    assert(owner:FindFirstChild("EnemyEntryCue"), "Entry cue missing")
    task.wait(.4)
    assert(not owner:FindFirstChild("EnemyEntryCue"), "Entry cue cleanup")
    owner:Destroy(); task.wait()
    assert(#folder:GetChildren()==0, "Removed enemy projectile remains")
    local player = game.Players.LocalPlayer
    local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
    assert(root, "Local rig required for rescue cue test")
    api.Emit({kind="EnemyGrab",targetUserId=player.UserId,duration=1})
    local cue = root:FindFirstChild("CoopGrabRescue")
    assert(cue and string.find(cue.TextLabel.Text,"YOU ARE GRABBED"), "Victim cue missing")
    api.Emit({kind="EnemyGrabRelease",targetUserId=player.UserId})
    assert(not root:FindFirstChild("CoopGrabRescue"), "Rescue cue remains")
    folder:Destroy()
    return {poses=30,criticalProjectileAtEffectsZero=true,cleanup=true,cancel=true,ownerRemoval=true,grabRelease=true,entryCue=true}
end
