-- WO-2.1: behavior-preserving extraction. Context keeps authoritative state in CombatService.
local Director = require(script.Parent.AttackDirector)
local EnemyAI = {}
local closeMoves = {Cleaver = true, CrossingSweep = true, AlarmRing = true, TicketCut = true, BellStrike = true, Bite = true, SlagPunch = true}
function EnemyAI.Step(t, context)
    local Combat, enemies, records = context.Combat, context.enemies, context.records
    local root, humanoid, knockOut = context.root, context.humanoid, context.knockOut
    local CombatMath, Config, arena, encounter = context.CombatMath, context.Config, context.arena, context.encounter
    local attributes, fx, beginEnemyAttack = context.attributes, context.fx, context.beginEnemyAttack
    local function attackCount() return Director.CountActive(enemies, context.now) end
    local alive = Combat.GetAlivePlayers()
    for model, data in pairs(enemies) do
        local r, h = root(model), humanoid(model)
        if not r or not h or h.Health <= 0 then knockOut(model) continue end
        if CombatMath.InBlastZone(r.Position, arena, Config.BlastMargin) then knockOut(model) continue end
        if encounter.status ~= "Combat" then h:Move(Vector3.zero) continue end
        local elite = data.spec.Role ~= "Grunt"
        if elite and data.phase == 1 and data.percent >= data.threshold * .52 then
            data.phase = 2
            -- Reset only the next pattern choice; the captured windup and its warning resolve unchanged.
            data.moveIndex = 0
            attributes(model, data)
            fx("BossPhase", r.Position, {phase = 2, enemy = data.kind, enemyName = data.spec.Name, targetModel = model})
        end
        if t < data.stunnedUntil or t < data.launchedUntil or t < data.recoveryUntil or data.attacking then h:Move(Vector3.zero) continue end
        local pos = r.Position
        local x, z = math.clamp(pos.X, arena.MinX + 6, arena.MaxX - 6), math.clamp(pos.Z, -12, 12)
        if x ~= pos.X or z ~= pos.Z then r.CFrame += Vector3.new(x - pos.X, 0, z - pos.Z) end
        local target, distance, bestScore
        for _, player in ipairs(alive) do
            local pr = root(player.Character)
            if pr and not records[player].respawning then
                local d = (Vector3.new(pr.Position.X, 0, pr.Position.Z) - Vector3.new(r.Position.X, 0, r.Position.Z)).Magnitude
                local focusPenalty = math.max(0, 4 - (t - (data.targetHistory[player] or 0))) * 5
                local score = d + focusPenalty
                if not bestScore or score < bestScore then target, distance, bestScore = player, d, score end
            end
        end
        if not target then h:Move(Vector3.zero) continue end
        local pr = root(target.Character)
        data.facing = pr.Position.X >= r.Position.X and 1 or -1
        local pattern = data.phase == 2 and data.spec.PhaseMoves or data.spec.Moves
        local moveName = pattern and pattern[data.moveIndex % #pattern + 1] or "Melee"
        local range = not elite and data.spec.Reach - 1 or (closeMoves[moveName] and data.spec.Reach or 65)
        if distance > range or (not elite and math.abs(pr.Position.Z - r.Position.Z) > 3) then
            h.WalkSpeed = data.spec.Speed
            h:MoveTo(Vector3.new(pr.Position.X - data.facing * 4, r.Position.Y, math.clamp(pr.Position.Z, -11, 11)))
        elseif t >= data.attackAt and attackCount() < Director.Cap(#alive) then
            beginEnemyAttack(model, data, target, moveName, alive)
        else h:Move(Vector3.zero) end
    end
end
return EnemyAI
