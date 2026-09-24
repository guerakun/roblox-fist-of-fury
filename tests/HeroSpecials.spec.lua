-- Run as a ModuleScript in a Studio CLIENT; root owns execution. Never ships in either place.
return function(Specials)
    local Players = game:GetService("Players")
    Specials = Specials or require(Players.LocalPlayer.PlayerScripts:FindFirstChild("HeroSpecials", true))
    local Config = require(game.ReplicatedStorage.Nightfall.Shared.Config)
    local holder = Instance.new("Folder")
    holder.Name = "HeroSpecialsSpec"; holder.Parent = workspace
    local preferences = {effects = 1}
    local api = Specials.new(holder, preferences)
    local results = {coverageCases = 0, cosmeticParts = 0, poses = 0, cleanup = false, cap = false}
    local ok, message = pcall(function()
        local center = Vector3.new(90, 3, 0)
        for _, id in ipairs(Config.CharacterOrder) do
            local attack = Config.Characters[id].Special
            local pose = Specials.Pose(id, attack.Windup + .12)
            assert(type(pose) == "table" and typeof(pose.Torso) == "CFrame", "Missing original pose " .. id)
            assert(Specials.Pose(id, attack.Windup + .6) == nil, "Pose must finish")
            results.poses += 1
            for _, direction in ipairs({-1, 1}) do
                assert(api.Emit(center, id, direction), "Effect refused")
                task.wait(attack.Windup + .05)
                local effect = holder:FindFirstChild(id .. "Special")
                assert(effect, "Missing effect " .. id)
                local minX, maxX, minZ, maxZ = math.huge, -math.huge, math.huge, -math.huge
                local edges = 0
                for _, p in ipairs(effect:GetChildren()) do
                    if p:IsA("BasePart") then
                        assert(p.Anchored and not p.CanCollide and not p.CanTouch and not p.CanQuery, "Unsafe cosmetic")
                        results.cosmeticParts += 1
                        if p.Name == "CoverageEdge" then
                            edges += 1
                            for _, side in ipairs({-1, 1}) do
                                local endpoint = p.Position + p.CFrame.LookVector * p.Size.Z * .5 * side
                                minX = math.min(minX, endpoint.X); maxX = math.max(maxX, endpoint.X)
                                minZ = math.min(minZ, endpoint.Z); maxZ = math.max(maxZ, endpoint.Z)
                            end
                        end
                    end
                end
                assert(edges == 4, "Missing configured coverage edges")
                assert(math.abs(minX - (center.X + math.min(0, direction * attack.Range))) < .02, "Rear X mismatch")
                assert(math.abs(maxX - (center.X + math.max(0, direction * attack.Range))) < .02, "Forward X mismatch")
                assert(math.abs(minZ + attack.Width / 2) < .02 and math.abs(maxZ - attack.Width / 2) < .02, "Lane width mismatch")
                results.coverageCases += 1
                task.wait(.8)
                assert(#holder:GetChildren() == 0, "Effect did not expire")
            end
        end
        for _ = 1, 8 do assert(api.Emit(center, "Gale", 1), "Cap prematurely reached") end
        assert(not api.Emit(center, "Gale", 1), "Effect cap exceeded")
        results.cap = true
        api.Destroy()
        assert(#holder:GetChildren() == 0, "Destroy left effects")
        preferences.effects = 0
        assert(not api.Emit(center, "Gale", 1), "Reduced effects ignored")
        results.cleanup = true
    end)
    api.Destroy(); holder:Destroy()
    assert(ok, message)
    return results
end
