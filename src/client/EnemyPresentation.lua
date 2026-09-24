--!strict
-- Enemy action presentation only. Server move IDs determine authored poses and cosmetic cues.
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")
local Presentation = {}
local actionKinds = {
    HuskJab = "Jab", HuskJumpKick = "Kick", StriderSlide = "Slide", StriderJab = "Jab",
    GrapplerGrab = "Grab", GrapplerThrow = "Throw", PitcherThrow = "Throw", PitcherShove = "Jab",
    WardenCounter = "Guard", WardenKick = "Kick", LeaperVaultKick = "Kick", LeaperJab = "Jab",
    BruteFlop = "Flop", BruteSwing = "Swing", LeaperEvade = "Evade", MutatedCrossfire = "Swing",
}
function Presentation.Pose(moveId: string?, progress: number, anticipation: boolean): any
    local kind = moveId and actionKinds[moveId]
    if not kind then return nil end
    local p = math.clamp(progress, 0, 1)
    if kind == "Evade" then
        return {Torso = CFrame.Angles(-p * math.pi * 2, 0, 0),
            ["Right Leg"] = CFrame.Angles(-.7 * math.sin(p * math.pi), 0, 0),
            ["Left Leg"] = CFrame.Angles(-.7 * math.sin(p * math.pi), 0, 0)}
    end
    local strength = anticipation and (.35 + p * .35) or math.sin(p * math.pi)
    local function rot(x: number, y: number, z: number): CFrame
        return CFrame.Angles(math.rad(x * strength), math.rad(y * strength), math.rad(z * strength))
    end
    if kind == "Slide" then
        return {Torso = rot(0, 0, -18), ["Right Leg"] = rot(-76, 0, 0), ["Left Leg"] = rot(53, 0, 0), ["Right Arm"] = rot(-50, 0, 0)}
    elseif kind == "Kick" then
        return {Torso = rot(0, -22, 10), ["Right Leg"] = rot(-85, 0, 0), ["Left Leg"] = rot(35, 0, -12), ["Left Arm"] = rot(-52, 0, -30)}
    elseif kind == "Grab" or kind == "Throw" then
        return {Torso = rot(anticipation and 10 or -15, 0, 0), ["Right Arm"] = rot(-85, 0, 10), ["Left Arm"] = rot(-85, 0, -10)}
    elseif kind == "Guard" then
        return {["Right Arm"] = rot(-76, 0, 24), ["Left Arm"] = rot(-76, 0, -24), Torso = rot(0, -15, 0)}
    elseif kind == "Flop" then
        return {Torso = rot(anticipation and -18 or 68, 0, 0), ["Right Arm"] = rot(-42, 0, 65), ["Left Arm"] = rot(-42, 0, -65)}
    elseif kind == "Swing" then
        return {Torso = rot(0, anticipation and -35 or 72, 0), ["Right Arm"] = rot(-80, 0, -22), ["Left Arm"] = rot(-34, 0, 18)}
    end
    return {Torso = rot(0, anticipation and -17 or 33, 0), ["Right Arm"] = rot(anticipation and -40 or -95, 0, 8), ["Left Arm"] = rot(-45, 0, -15)}
end
function Presentation.new(folder: Instance, preferences: any): any
    local grabs: {[number]: any} = {}
    local projectiles = 0
    local projectileOwners: {[BasePart]: Model} = {}
    local grabOwners: {[number]: Model} = {}
    local api = {}
    local function release(userId: number)
        local cue = grabs[userId]
        if cue then cue:Destroy(); grabs[userId] = nil end
        grabOwners[userId] = nil
    end
    function api.Emit(event: any)
        if event.kind == "EnemyEntry" then
            local model = event.targetModel
            if typeof(model) ~= "Instance" or not model:IsA("Model") or not model.Parent then return end
            local prior = model:FindFirstChild("EnemyEntryCue")
            if prior then prior:Destroy() end
            local cue = Instance.new("Highlight")
            cue.Name = "EnemyEntryCue"; cue.Adornee = model; cue.DepthMode = Enum.HighlightDepthMode.Occluded
            cue.FillColor = Color3.fromRGB(115, 208, 230); cue.FillTransparency = .7
            cue.OutlineColor = Color3.fromRGB(213, 241, 247); cue.OutlineTransparency = .1; cue.Parent = model
            local duration = math.clamp(tonumber(event.duration) or .6, .3, 2)
            TweenService:Create(cue, TweenInfo.new(duration), {FillTransparency=1,OutlineTransparency=1}):Play()
            Debris:AddItem(cue,duration+.02)
            local arrivalRoot = model:FindFirstChild("HumanoidRootPart")
            if arrivalRoot and arrivalRoot:IsA("BasePart") then
                local oldDirection = arrivalRoot:FindFirstChild("EntryDirection")
                if oldDirection then oldDirection:Destroy() end
                local directionCue = Instance.new("BillboardGui")
                directionCue.Name = "EntryDirection"; directionCue.Adornee = arrivalRoot
                directionCue.Size = UDim2.fromOffset(130,24); directionCue.StudsOffsetWorldSpace = Vector3.new(0,3.5,0)
                directionCue.AlwaysOnTop = false; directionCue.MaxDistance = 220; directionCue.Parent = arrivalRoot
                local text = Instance.new("TextLabel")
                text.Size = UDim2.fromScale(1,1); text.BackgroundTransparency = 1
                text.TextColor3 = Color3.fromRGB(213,241,247); text.TextStrokeTransparency = .3
                text.Font = Enum.Font.GothamBold; text.TextSize = 12
                local labels = {Left="→ ARRIVING",Right="← ARRIVING",Door="DOOR ENTRY",Drop="↓ DROPPING IN"}
                text.Text = labels[event.entry] or "ARRIVING"; text.Parent = directionCue
                TweenService:Create(text,TweenInfo.new(duration),{TextTransparency=1,TextStrokeTransparency=1}):Play()
                Debris:AddItem(directionCue,duration+.02)
            end
        elseif event.kind == "EnemyCancel" then
            for p, owner in pairs(projectileOwners) do if owner == event.targetModel then p:Destroy() end end
            for userId, owner in pairs(grabOwners) do if owner == event.targetModel then release(userId) end end
        elseif event.kind == "EnemyGrabRelease" and type(event.targetUserId) == "number" then
            release(event.targetUserId)
        elseif event.kind == "EnemyGrab" and type(event.targetUserId) == "number" then
            local victim = Players:GetPlayerByUserId(event.targetUserId)
            local root = victim and victim.Character and victim.Character:FindFirstChild("HumanoidRootPart")
            if not root or not root:IsA("BasePart") then return end
            release(event.targetUserId)
            local cue = Instance.new("BillboardGui")
            cue.Name = "CoopGrabRescue"; cue.Adornee = root; cue.Size = UDim2.fromOffset(220, 48)
            cue.StudsOffsetWorldSpace = Vector3.new(0, 4.8, 0); cue.AlwaysOnTop = true; cue.Parent = root
            local label = Instance.new("TextLabel")
            label.BackgroundColor3 = Color3.fromRGB(22, 28, 39); label.BackgroundTransparency = .18
            label.Size = UDim2.fromScale(1, 1); label.Font = Enum.Font.GothamBold; label.TextSize = 12
            label.TextColor3 = Color3.fromRGB(255, 210, 96); label.Text = event.targetUserId == Players.LocalPlayer.UserId and "YOU ARE GRABBED\nAN ALLY CAN FREE YOU" or "ALLY GRABBED\nHIT THE GRAPPLER TO FREE THEM"
            label.Parent = cue
            grabs[event.targetUserId] = cue
            grabOwners[event.targetUserId] = event.targetModel
            local userId = event.targetUserId
            task.delay(math.clamp(tonumber(event.duration) or 1, .3, 5) + .15, function()
                if grabs[userId] == cue then release(userId) end
            end)
        elseif event.kind == "EnemyProjectile" then
            if typeof(event.origin) ~= "Vector3" or typeof(event.endpoint) ~= "Vector3" or projectiles >= 16 then return end
            -- Projectile is part of critical attack readability, independent of cosmetic-density setting.
            local duration = math.clamp(tonumber(event.duration) or .4, .05, 3)
            local p = Instance.new("Part")
            p.Name = "EnemyProjectileCue"; p.Size = Vector3.new(.32, .32, 1.1); p.Material = Enum.Material.Neon
            p.Color = preferences.highContrast and Color3.fromRGB(255, 225, 97) or Color3.fromRGB(240, 128, 188)
            p.Anchored = true; p.CanCollide = false; p.CanTouch = false; p.CanQuery = false; p.CastShadow = false
            local orientation = CFrame.lookAt(event.origin, event.endpoint).Rotation
            p.CFrame = CFrame.new(event.origin) * orientation; p.Parent = folder
            projectiles += 1
            local owner = event.targetModel
            local deathConnection: RBXScriptConnection? = nil
            local healthConnection: RBXScriptConnection? = nil
            if typeof(owner) == "Instance" and owner:IsA("Model") then
                projectileOwners[p] = owner
                deathConnection = owner.Destroying:Connect(function() p:Destroy() end)
                local h = owner:FindFirstChildOfClass("Humanoid")
                if h then healthConnection = h.Died:Connect(function() p:Destroy() end) end
            end
            p.Destroying:Connect(function()
                projectiles -= 1; projectileOwners[p] = nil
                if deathConnection then deathConnection:Disconnect() end
                if healthConnection then healthConnection:Disconnect() end
            end)
            TweenService:Create(p, TweenInfo.new(duration, Enum.EasingStyle.Linear), {CFrame = CFrame.new(event.endpoint) * orientation}):Play()
            Debris:AddItem(p, duration + .06)
        end
    end
    return api
end
return Presentation
