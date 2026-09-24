-- Root runs in Studio. Structural evidence only; this is not a likeness/readability approval.
return function()
    local Factory = require(game.ServerScriptService.NightfallServer.EnemyFactory)
    local Config = require(game.ReplicatedStorage.Nightfall.Shared.Config)
    local markers = {Husk="HuskWornWrap", Strider="StriderHeelBooster", Grappler="GrapplerGripGauntlet",
        Pitcher="PitcherThrowingRod", Warden="WardenForearmShield", Leaper="LeaperArchedCrest"}
    local results = {}
    local models = {}
    local ok, err = pcall(function()
        for kind, marker in pairs(markers) do
            local spec = Config.Enemies[kind] or {Name=kind,Scale=1,Color=Color3.fromRGB(120,165,185)}
            local model = Factory.Create(kind, spec)
            table.insert(models, model)
            local parts, queryable, motors, external = 0, 0, 0, 0
            for _, item in ipairs(model:GetDescendants()) do
                if item:IsA("BasePart") then
                    parts += 1
                    if item.CanQuery then queryable += 1
                    else assert(not item.CanCollide and not item.CanTouch and item.Massless, "Unsafe cosmetic "..kind..":"..item.Name) end
                elseif item:IsA("Motor6D") then motors += 1
                elseif item:IsA("SpecialMesh") and item.MeshId ~= "" then external += 1 end
                assert(not item:IsA("LuaSourceContainer"), "Unexpected embedded behavior")
            end
            assert(queryable==7 and motors==6, "Canonical target rig changed "..kind)
            assert(parts<=45 and external==0, "Visual budget or asset policy changed "..kind)
            assert(model:FindFirstChild(marker, true), "Missing distinct silhouette marker "..kind)
            assert(model:GetAttribute("CosmeticPartCount")==parts-7, "Cosmetic count mismatch "..kind)
            assert(model:GetAttribute("ArchetypeVisual")==kind, "Visual identity missing "..kind)
            results[kind]={parts=parts,queryable=queryable,motors=motors,externalMeshes=external}
        end
    end)
    for _, model in ipairs(models) do model:Destroy() end
    assert(ok,err)
    return results
end
