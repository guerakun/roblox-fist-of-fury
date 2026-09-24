-- Pure geometry tests; no remotes, rewards, player changes, or encounter mutations.
return function()
    local Config = require(game.ReplicatedStorage.Nightfall.Shared.Config)
    local Moves = require(game.ServerScriptService.NightfallServer.EnemyMoves)
    local Factory = require(game.ServerScriptService.NightfallServer.EnemyFactory)
    local context = {origin = Vector3.new(90, 4, 0), target = Vector3.new(110, 3, 0), direction = 1,
        arena = Config.Stages[1], partyPositions = {Vector3.new(100,3,0), Vector3.new(101,3,0), Vector3.new(120,3,8), Vector3.new(135,3,-8)}}
    local eliteCount, moveCount = 0, 0
    for kind, spec in pairs(Config.Enemies) do
        if spec.Role ~= "Grunt" then
            eliteCount += 1
            context.spec = spec
            for _, pattern in ipairs({spec.Moves, spec.PhaseMoves}) do
                for _, name in ipairs(pattern) do
                    local move = Moves.Build(name, context)
                    assert(move.Windup >= .7 and move.Recovery >= .8, kind .. " needs reaction and punish windows")
                    assert(#move.Volumes > 0, kind .. " missing hit volume")
                    for _, volume in ipairs(move.Volumes) do
                        assert(volume.size.X > 0 and volume.size.Z > 0 and volume.height > 0, "positive footprint")
                        assert(volume.position.X == volume.position.X, "finite footprint")
                        assert(Moves.Contains(volume, volume.position + Vector3.new(0, 3, 0)), "standing at center is hit")
                        assert(not Moves.Contains(volume, volume.position + Vector3.new(400, 3, 0)), "distant character safe")
                        if volume.jumpable then
                            assert(not Moves.Contains(volume, volume.position + Vector3.new(0, 6, 0)), "jump clears low strike")
                        end
                    end
                    moveCount += 1
                end
            end
            local rig = Factory.Create(kind, spec)
            assert(rig.PrimaryPart and rig:FindFirstChildOfClass("Humanoid"), "valid elite rig " .. kind)
            assert(rig.Torso:FindFirstChild("Right Shoulder"), "canonical R6 shoulder")
            assert(#rig:GetChildren() >= 15, "distinct authored silhouette")
            rig:Destroy()
        end
    end
    assert(eliteCount == 6, "six unique elites")
    context.spec = Config.Enemies.SirenMarshal
    local split = Moves.Build("SplitAlarm", context)
    for _, volume in ipairs(split.Volumes) do
        assert(not Moves.Contains(volume, Vector3.new(108, 3, 0)), "split siren preserves central lane")
    end
    local train = Moves.Build("GhostTrain", context)
    assert(Moves.Contains(train.Volumes[1], Vector3.new(20, 3, 0)), "train covers lane at both ends")
    assert(not Moves.Contains(train.Volumes[1], Vector3.new(110, 3, 8)), "adjacent platform safe")
    local marks = Moves.Build("ForgeCrush", context)
    assert(#marks.Volumes == 3, "nearby party members share one mark")
    local stored = marks.Volumes[1].position
    context.partyPositions[1] = Vector3.new(150, 3, 10)
    assert(marks.Volumes[1].position == stored, "telegraphs do not retarget after lock")
    for _, stage in ipairs(Config.Stages) do
        assert(#stage.Waves == 4 and stage.Waves[2].Kind == "Miniboss" and stage.Waves[4].Kind == "Boss", "district structure")
        for kind in pairs(stage.Waves[2].Enemies) do assert(Config.Enemies[kind].Role == "Miniboss", "miniboss role") end
        for kind in pairs(stage.Waves[4].Enemies) do assert(Config.Enemies[kind].Role == "Boss", "boss role") end
    end
    return "PASS: six elite rigs, " .. moveCount .. " pattern entries, punish windows, lane gaps, jumping, mark deduplication, locked targeting and district structure"
end
