-- Pure encounter move descriptions. CombatService resolves these exact locked footprints.
local Moves = {}
local orange = Color3.fromRGB(255, 151, 70)
local red = Color3.fromRGB(255, 76, 104)
local cyan = Color3.fromRGB(84, 226, 240)
function Moves.Build(name, context)
    local origin, target = context.origin, context.target
    local direction, arena = context.direction, context.arena
    local result = {Name = name, Windup = 1.0, Recovery = 1.0, Volumes = {}, Armored = true}
    local function box(position, length, width, jumpable, multiplier)
        local height = jumpable and 3 or 16
        table.insert(result.Volumes, {position = Vector3.new(position.X, 0, position.Z), size = Vector3.new(length, height, width), shape = "Box", height = height, jumpable = jumpable or false, multiplier = multiplier or 1, color = jumpable and cyan or red})
    end
    local function circle(position, radius, jumpable, multiplier)
        local height = jumpable and 3 or 16
        table.insert(result.Volumes, {position = Vector3.new(position.X, 0, position.Z), size = Vector3.new(radius * 2, height, radius * 2), radius = radius, shape = "Circle", height = height, jumpable = jumpable or false, multiplier = multiplier or 1, color = jumpable and cyan or orange})
    end
    local function forward(distance) return origin + Vector3.new(direction * distance, 0, 0) end
    local function safePoint(position)
        return Vector3.new(math.clamp(position.X, arena.MinX + 12, arena.MaxX - 12), 0, math.clamp(position.Z, -10, 10))
    end
    if name == "Cleaver" then
        result.Name, result.Windup, result.Recovery = "CROSSWALK CLEAVE", .9, 1.0
        box(forward(6), 12, 9, false)
    elseif name == "CrossingSweep" then
        result.Name, result.Windup, result.Recovery = "SWEEP / JUMP THE LINE", 1.1, 1.2
        box(forward(7), 18, 25, true, 1.15)
    elseif name == "SirenLine" then
        result.Name, result.Windup, result.Recovery = "SIREN BEAM / CHANGE LANE", 1.1, 1.05
        box(Vector3.new(origin.X + direction * 18, 0, target.Z), 36, 6, false)
    elseif name == "AlarmRing" then
        result.Name, result.Windup, result.Recovery = "ALARM PULSE / JUMP", 1.15, 1.25
        circle(origin, 12, true, 1.15)
    elseif name == "SplitAlarm" then
        result.Name, result.Windup, result.Recovery = "DOUBLE SIREN / CENTER SAFE", 1.25, 1.2
        box(Vector3.new(origin.X + direction * 18, 0, -9), 40, 7, false)
        box(Vector3.new(origin.X + direction * 18, 0, 9), 40, 7, false)
    elseif name == "RailLunge" then
        result.Name, result.Windup, result.Recovery = "RAIL LUNGE / SIDESTEP", 1.0, 1.2
        local endpoint = safePoint(origin + Vector3.new(direction * math.min(32, math.max(16, math.abs(target.X - origin.X) + 5)), 0, 0))
        box((origin + endpoint) / 2, math.max(8, math.abs(endpoint.X - origin.X)) + 4, 5, false, 1.1)
        result.MoveTo = endpoint
    elseif name == "TicketCut" then
        result.Name, result.Windup, result.Recovery = "TICKET CUT", .78, .9
        box(forward(5), 11, 11, false, .9)
    elseif name == "PlatformMark" then
        result.Name, result.Windup, result.Recovery = "PLATFORM MARK / KEEP MOVING", 1.15, 1.2
        circle(safePoint(target), 6, false)
    elseif name == "GhostTrain" then
        result.Name, result.Windup, result.Recovery = "GHOST TRAIN / CHANGE PLATFORM", 1.35, 1.25
        local lane = math.clamp(math.floor(target.Z / 8 + .5) * 8, -8, 8)
        box(Vector3.new(arena.CenterX, 0, lane), arena.MaxX - arena.MinX - 8, 7, false, 1.1)
    elseif name == "DepartureCross" then
        result.Name, result.Windup, result.Recovery = "DEPARTURE / CENTER PLATFORM", 1.4, 1.35
        box(Vector3.new(arena.CenterX, 0, -9), arena.MaxX - arena.MinX - 8, 7, false)
        box(Vector3.new(arena.CenterX, 0, 9), arena.MaxX - arena.MinX - 8, 7, false)
    elseif name == "BellStrike" then
        result.Name, result.Windup, result.Recovery = "LAST BELL / JUMP", 1.0, 1.1
        circle(origin, 10, true)
    elseif name == "Pounce" then
        result.Name, result.Windup, result.Recovery = "FURNACE POUNCE / MOVE", 1.05, 1.25
        result.MoveTo = safePoint(target)
        circle(result.MoveTo, 7, false, 1.05)
    elseif name == "CinderTrail" then
        result.Name, result.Windup, result.Recovery = "CINDER LANE / SIDESTEP", 1.1, 1.3
        box(Vector3.new(origin.X + direction * 14, 0, origin.Z), 28, 7, false)
    elseif name == "Bite" then
        result.Name, result.Windup, result.Recovery = "IRON JAWS", .85, .9
        box(forward(5), 11, 8, false)
    elseif name == "ForgeCrush" then
        result.Name, result.Windup, result.Recovery = "FORGE MARKS / SPREAD OUT", 1.35, 1.4
        local chosen = {}
        for _, position in ipairs(context.partyPositions) do
            local point = safePoint(position)
            local nearby = false
            for _, other in ipairs(chosen) do if (other - point).Magnitude < 6 then nearby = true break end end
            if not nearby and #chosen < 4 then table.insert(chosen, point) circle(point, 5.5, false, 1.05) end
        end
        if #result.Volumes == 0 then circle(safePoint(target), 5.5, false) end
    elseif name == "FurnaceVent" then
        result.Name, result.Windup, result.Recovery = "FURNACE VENT / CHANGE LANE", 1.2, 1.25
        local z = target.Z >= 0 and 7 or -7
        box(Vector3.new(arena.CenterX, 0, z), arena.MaxX - arena.MinX - 12, 12, false)
    elseif name == "TwinVent" then
        result.Name, result.Windup, result.Recovery = "OVERPRESSURE / CENTER SAFE", 1.4, 1.45
        box(Vector3.new(arena.CenterX, 0, -10), arena.MaxX - arena.MinX - 12, 6, false)
        box(Vector3.new(arena.CenterX, 0, 10), arena.MaxX - arena.MinX - 12, 6, false)
        -- A low central pressure wave can be jumped; the outer vents cannot.
        box(Vector3.new(origin.X, 0, 0), 18, 12, true, .8)
    elseif name == "SlagPunch" then
        result.Name, result.Windup, result.Recovery = "SLAG HAMMER / JUMP", 1.05, 1.35
        box(forward(8), 18, 18, true, 1.15)
    else
        result.Name, result.Windup, result.Recovery, result.Armored = "CURSE STRIKE", context.spec.Windup, .6, false
        box(forward((context.spec.Reach + 2) / 2), context.spec.Reach + 2, 7, false)
    end
    return result
end
function Moves.Contains(volume, position)
    if position.Y - 2.5 > volume.height or position.Y < -3 then return false end
    local dx, dz = position.X - volume.position.X, position.Z - volume.position.Z
    if volume.shape == "Circle" then return dx * dx + dz * dz <= volume.radius * volume.radius end
    return math.abs(dx) <= volume.size.X / 2 and math.abs(dz) <= volume.size.Z / 2
end
return Moves
