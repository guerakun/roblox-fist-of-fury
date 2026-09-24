--!strict
-- Elite impact AFTERIMAGES. Damage has already resolved when EnemyImpact reaches this module.
-- Footprints are never recomputed from a moving character; no collision or gameplay code lives here.
local RunService = game:GetService("RunService")
local Debris = game:GetService("Debris")
local Effects = {}
local MAX_EFFECTS, MAX_PARTS_PER_EFFECT = 6, 24
local COLORS = {
    amber = Color3.fromRGB(255, 180, 67), hot = Color3.fromRGB(255, 244, 205),
    sirenRed = Color3.fromRGB(255, 74, 105), sirenBlue = Color3.fromRGB(93, 164, 255),
    widow = Color3.fromRGB(134, 242, 238), paper = Color3.fromRGB(233, 236, 212),
    spectral = Color3.fromRGB(130, 195, 255), train = Color3.fromRGB(42, 65, 105),
    cinder = Color3.fromRGB(255, 102, 42), coal = Color3.fromRGB(59, 41, 43),
    steam = Color3.fromRGB(205, 224, 231),
}
function Effects.new(preferences: any): any
    local folder = Instance.new("Folder")
    folder.Name = "NightfallBossCosmetics"
    folder.Parent = workspace
    local active: {any} = {}
    local connection: RBXScriptConnection? = nil
    local api: any = {}
    local function startTicker()
        if connection then return end
        connection = RunService.RenderStepped:Connect(function()
            local now = os.clock()
            for index = #active, 1, -1 do
                local effect = active[index]
                local age = now - effect.start
                if age >= effect.duration or not effect.holder.Parent or preferences.effects <= 0 then
                    effect.holder:Destroy(); table.remove(active, index)
                else
                    effect.update(age)
                    local fade = math.clamp((age - effect.fadeStart) / math.max(.01, effect.duration - effect.fadeStart), 0, 1)
                    for _, item in ipairs(effect.parts) do
                        item.part.Transparency = item.alpha + (1 - item.alpha) * fade
                    end
                end
            end
            if #active == 0 and connection then connection:Disconnect(); connection = nil end
        end)
    end
    function api.Emit(event: any): boolean
        if preferences.effects <= 0 or #active >= MAX_EFFECTS or typeof(event.position) ~= "Vector3" then return false end
        local enemy = event.enemy
        if enemy ~= "Executioner" and enemy ~= "SirenMarshal" and enemy ~= "PlatformWidow"
            and enemy ~= "LastConductor" and enemy ~= "FurnaceHound" and enemy ~= "KilnSovereign" then return false end
        local density = math.clamp(preferences.effects, .1, 1)
        local mechanic = string.upper(tostring(event.mechanic or ""))
        local origin = Vector3.new(event.position.X, .12, event.position.Z)
        local circle = event.shape == "Circle"
        local size = typeof(event.size) == "Vector3" and event.size or Vector3.new(12, 16, 8)
        local length, width = math.clamp(size.X, 1, 180), math.clamp(size.Z, 1, 30)
        local radius = math.clamp(tonumber(event.radius) or math.min(length, width) * .5, .5, 30)
        local height = math.clamp(tonumber(event.height) or size.Y, 1, 16)
        local holder = Instance.new("Folder")
        holder.Name = enemy .. "Impact"
        holder.Parent = folder
        local pieces: {any} = {}
        local duration, fadeStart = .48, .10
        local update: (number) -> () = function() end
        local function part(name: string, dimensions: Vector3, position: Vector3, color: Color3, alpha: number?, shape: Enum.PartType?, class: string?): BasePart
            local p = Instance.new(class or "Part") :: BasePart
            p.Name, p.Size, p.Position = name, dimensions, position
            p.Anchored, p.CanCollide, p.CanTouch, p.CanQuery = true, false, false, false
            p.CastShadow, p.Material, p.Color, p.Transparency = false, Enum.Material.Neon, color, alpha or .1
            if shape and p:IsA("Part") then p.Shape = shape end
            p.Parent = holder
            table.insert(pieces, {part = p, alpha = p.Transparency})
            return p
        end
        local function line(name: string, a: Vector3, b: Vector3, thickness: number, color: Color3, alpha: number?): BasePart
            local p = part(name, Vector3.new(thickness, thickness, math.max(.05, (b - a).Magnitude)), (a + b) * .5, color, alpha)
            p.CFrame = CFrame.lookAt((a + b) * .5, b)
            return p
        end
        local function ring(name: string, center: Vector3, ringRadius: number, count: number, color: Color3, thickness: number): {BasePart}
            local segments: {BasePart} = {}
            for index = 1, count do
                local a = (index - 1) / count * math.pi * 2
                local b = index / count * math.pi * 2
                segments[index] = line(name, center + Vector3.new(math.cos(a), 0, math.sin(a)) * ringRadius,
                    center + Vector3.new(math.cos(b), 0, math.sin(b)) * ringRadius, thickness, color, .2)
            end
            return segments
        end
        if enemy == "Executioner" then
            duration = .42
            local low = height <= 3.1
            local a = origin + Vector3.new(-length * .43, .35, -width * .33)
            local b = origin + Vector3.new(length * .43, low and 1.4 or math.min(6, height * .5), width * .33)
            line("CleaverAfterimage", a, b, .48, COLORS.amber, .28)
            line("CleaverEdge", a, b, .11, COLORS.hot, .05)
            local fragments = {}
            for index = 1, math.max(3, math.floor(8 * density)) do
                local fraction = index / 9
                local base = origin + Vector3.new((fraction - .5) * length * .85, .25, math.sin(index * 2.4) * width * .33)
                local shard = part("CrosswalkShard", Vector3.new(.25, .08, .8), base, index % 2 == 0 and COLORS.hot or COLORS.amber, .15)
                fragments[index] = {part = shard, base = base, spin = index * .7}
            end
            update = function(t)
                for _, shard in ipairs(fragments) do
                    shard.part.CFrame = CFrame.new(shard.base + Vector3.new(0, math.sin(t / duration * math.pi) * (low and .8 or 2.3), 0)) * CFrame.Angles(t * 5, shard.spin + t * 3, .4)
                end
            end
        elseif enemy == "SirenMarshal" then
            duration = .46
            if circle or string.find(mechanic, "PULSE", 1, true) then
                local count = math.max(8, math.floor(12 * density))
                local segments = ring("AlarmPulse", origin + Vector3.new(0, .4, 0), radius * .97, count, COLORS.sirenRed, .28)
                for index, p in ipairs(segments) do if index % 2 == 0 then p.Color = COLORS.sirenBlue end end
                part("AlarmCore", Vector3.new(.8, .3, .8), origin + Vector3.new(0, .3, 0), COLORS.hot, .1, Enum.PartType.Ball)
                update = function(t)
                    local shrink = 1 - t / duration * .15
                    for index, p in ipairs(segments) do
                        local a = (index - 1) / count * math.pi * 2 + t * .7
                        local b = index / count * math.pi * 2 + t * .7
                        local p0 = origin + Vector3.new(math.cos(a) * radius * .97 * shrink, .4, math.sin(a) * radius * .97 * shrink)
                        local p1 = origin + Vector3.new(math.cos(b) * radius * .97 * shrink, .4, math.sin(b) * radius * .97 * shrink)
                        p.Size = Vector3.new(.28, .28, (p1 - p0).Magnitude); p.CFrame = CFrame.lookAt((p0 + p1) * .5, p1)
                    end
                end
            else
                for _, z in ipairs({-width * .25, 0, width * .25}) do
                    line("SirenBeam", origin + Vector3.new(-length * .49, 1.1, z), origin + Vector3.new(length * .49, 1.1, z), z == 0 and .14 or .35,
                        z == 0 and COLORS.hot or z < 0 and COLORS.sirenRed or COLORS.sirenBlue, z == 0 and .08 or .38)
                end
                local bars = {}
                for index = 1, math.max(3, math.floor(6 * density)) do
                    local x = (index / 7 - .5) * length * .93
                    bars[index] = part("AlarmRib", Vector3.new(.14, math.min(height * .45, 5), width * .6), origin + Vector3.new(x, math.min(height * .225, 2.5), 0), index % 2 == 0 and COLORS.sirenBlue or COLORS.sirenRed, .6)
                end
                update = function(t)
                    for _, p in ipairs(bars) do p.Size = Vector3.new(.14, math.max(.05, math.min(height * .45, 5) * (1 - t / duration)), width * .6) end
                end
            end
        elseif enemy == "PlatformWidow" then
            duration = .44
            if circle then ring("PlatformSeal", origin + Vector3.new(0, .25, 0), radius * .93, math.max(8, math.floor(10 * density)), COLORS.widow, .16)
            else
                for index = -1, 1 do
                    local z = index * width * .3
                    line("RailRibbon", origin + Vector3.new(-length * .48, .4, z), origin + Vector3.new(length * .48, 1.8 + math.abs(index) * .7, z), .13, COLORS.widow, .25)
                    line("RailGlint", origin + Vector3.new(-length * .47, .48, z + .07), origin + Vector3.new(length * .47, 1.9 + math.abs(index) * .7, z + .07), .045, COLORS.paper, .15)
                end
            end
            local tickets = {}
            for index = 1, math.max(3, math.floor(6 * density)) do
                local theta = index * 2.399
                local base = circle and origin + Vector3.new(math.cos(theta) * radius * .52, .5, math.sin(theta) * radius * .52)
                    or origin + Vector3.new((index / 7 - .5) * length * .8, .5, math.sin(theta) * width * .3)
                local ticket = part("SpectralTicket", Vector3.new(.36, .06, .64), base, COLORS.paper, .15)
                tickets[index] = {part = ticket, base = base, angle = theta}
            end
            update = function(t)
                for _, ticket in ipairs(tickets) do ticket.part.CFrame = CFrame.new(ticket.base + Vector3.new(0, math.sin(t / duration * math.pi) * 2, 0)) * CFrame.Angles(ticket.angle + t * 8, t * 4, .5) end
            end
        elseif enemy == "LastConductor" then
            if circle or string.find(mechanic, "BELL", 1, true) then
                duration = .48
                local clockRadius = math.min(radius * .35, height * .42, 3.5)
                local center = origin + Vector3.new(0, clockRadius + .1, 0)
                local count = math.max(8, math.floor(12 * density))
                for index = 1, count do
                    local theta = index / count * math.pi * 2
                    local a = center + Vector3.new(math.cos(theta), math.sin(theta), 0) * clockRadius * .8
                    local b = center + Vector3.new(math.cos(theta), math.sin(theta), 0) * clockRadius
                    line("DepartureClockTick", a, b, .12, COLORS.spectral, .15)
                end
                local minute = line("MinuteHand", center, center + Vector3.new(0, clockRadius * .8, 0), .12, COLORS.hot, .1)
                local hour = line("HourHand", center, center + Vector3.new(clockRadius * .5, 0, 0), .15, COLORS.spectral, .1)
                update = function(t)
                    local endMinute = center + Vector3.new(math.sin(t * 12), math.cos(t * 12), 0) * clockRadius * .8
                    local endHour = center + Vector3.new(math.cos(t * 4), math.sin(t * 4), 0) * clockRadius * .5
                    minute.CFrame = CFrame.lookAt((center + endMinute) * .5, endMinute)
                    hour.CFrame = CFrame.lookAt((center + endHour) * .5, endHour)
                end
            else
                -- The entire lane already flashed and resolved damage. This .26s train is an afterimage.
                duration, fadeStart = .32, .12
                local carLength = math.min(7.2, length / 3.5)
                local trainLength = carLength * 3 + 1
                local carWidth = math.min(4.8, width * .75)
                local moving = {}
                local function trainPart(name: string, dimensions: Vector3, offset: Vector3, color: Color3, alpha: number)
                    local p = part(name, dimensions, origin + offset, color, alpha)
                    table.insert(moving, {part = p, offset = offset})
                    return p
                end
                for car = -1, 1 do
                    local x = car * (carLength + .35)
                    trainPart("SpectralCarriage", Vector3.new(carLength, 3.1, carWidth), Vector3.new(x, 2.15, 0), COLORS.train, .58)
                    trainPart("SpectralRoof", Vector3.new(carLength + .1, .22, carWidth + .12), Vector3.new(x, 3.8, 0), COLORS.spectral, .46)
                    local windows = density >= .5 and 3 or 1
                    for window = 1, windows do
                        local wx = x + (window / (windows + 1) - .5) * carLength
                        trainPart("TrainWindow", Vector3.new(carLength / (windows + 2), 1.1, .08), Vector3.new(wx, 2.65, carWidth * .5 + .05), COLORS.spectral, .18)
                    end
                end
                for _, z in ipairs({-carWidth * .3, carWidth * .3}) do
                    trainPart("TrainLamp", Vector3.new(.17, .6, .65), Vector3.new(trainLength * .5 - .2, 1.7, z), COLORS.hot, .1)
                    line("GhostRail", origin + Vector3.new(-length * .49, .2, z), origin + Vector3.new(length * .49, .2, z), .1, COLORS.spectral, .3)
                end
                update = function(t)
                    local phase = math.clamp(t / .26, 0, 1)
                    local travel = math.max(0, length - trainLength - .4)
                    local shift = Vector3.new((phase - .5) * travel, 0, 0)
                    for _, item in ipairs(moving) do item.part.Position = origin + item.offset + shift end
                end
            end
        elseif enemy == "FurnaceHound" then
            duration = .54
            if circle then ring("PounceScorch", origin + Vector3.new(0, .15, 0), radius * .9, math.max(6, math.floor(8 * density)), COLORS.cinder, .25) end
            local clawLength = circle and radius * 1.4 or length * .87
            local spacing = circle and radius * .27 or width * .24
            for index = -1, 1 do
                line("CinderClaw", origin + Vector3.new(-clawLength * .5, .3, index * spacing - .15),
                    origin + Vector3.new(clawLength * .5, .5, index * spacing + .15), .22, index == 0 and COLORS.hot or COLORS.cinder, .12)
            end
            local embers = {}
            for index = 1, math.max(3, math.floor(6 * density)) do
                local theta = index * 2.399
                local base = circle and origin + Vector3.new(math.cos(theta) * radius * .4, .3, math.sin(theta) * radius * .4)
                    or origin + Vector3.new((index / 7 - .5) * length * .8, .3, math.sin(theta) * width * .22)
                local ember = part("CinderFragment", Vector3.new(.24, .6, .24), base, COLORS.cinder, .1)
                embers[index] = {part = ember, base = base, angle = theta}
            end
            update = function(t)
                for _, ember in ipairs(embers) do
                    ember.part.CFrame = CFrame.new(ember.base + Vector3.new(0, math.sin(t / duration * math.pi) * math.min(height * .6, 4), 0)) * CFrame.Angles(ember.angle + t * 5, t * 6, t * 4)
                end
            end
        elseif enemy == "KilnSovereign" then
            duration, fadeStart = .68, .18
            local columns = circle and math.max(3, math.floor(4 * density)) or math.max(2, math.floor(6 * density))
            local columnHeight = math.min(height * .72, 7.5)
            local columnsData = {}
            for index = 1, columns do
                local theta = index / columns * math.pi * 2
                local base = circle and origin + Vector3.new(math.cos(theta) * radius * .43, .1, math.sin(theta) * radius * .43)
                    or origin + Vector3.new((index / (columns + 1) - .5) * length * .9, .1, math.sin(index * 2.399) * width * .25)
                local flame = part("FurnaceColumn", Vector3.new(1.2, columnHeight, 1.2), base + Vector3.new(0, columnHeight * .5, 0), COLORS.cinder, .4, Enum.PartType.Ball)
                local steam = part("PressureSteam", Vector3.new(1.7, math.max(.6, columnHeight * .45), 1.7), base + Vector3.new(0, columnHeight * .75, 0), COLORS.steam, .68, Enum.PartType.Ball)
                steam.Material = Enum.Material.SmoothPlastic
                part("VentGrate", Vector3.new(1.7, .12, 1.7), base, COLORS.coal, .22)
                columnsData[index] = {flame = flame, steam = steam, base = base, index = index}
            end
            if circle then
                local edge = radius * .57
                for _, z in ipairs({-edge, edge}) do line("ForgeStamp", origin + Vector3.new(-edge, .3, z), origin + Vector3.new(edge, .3, z), .14, COLORS.hot, .18) end
                for _, x in ipairs({-edge, edge}) do line("ForgeStamp", origin + Vector3.new(x, .3, -edge), origin + Vector3.new(x, .3, edge), .14, COLORS.hot, .18) end
            end
            update = function(t)
                for _, column in ipairs(columnsData) do
                    local pulse = .87 + math.sin(t * 23 + column.index) * .13
                    local h = math.max(.1, columnHeight * (1 - t / duration * .4) * pulse)
                    column.flame.Size = Vector3.new(1.2 * pulse, h, 1.2 * pulse)
                    column.flame.Position = column.base + Vector3.new(0, h * .5, 0)
                    column.steam.Position = column.base + Vector3.new(0, columnHeight * .75 + math.min(t * 1.3, height - columnHeight), 0)
                    column.steam.Size = Vector3.new(1.7 + t, math.max(.6, columnHeight * .45), 1.7 + t)
                end
            end
        end
        -- Construction is also capped, so adding a future ornament cannot silently exceed the budget.
        if #pieces > MAX_PARTS_PER_EFFECT then holder:Destroy(); return false end
        duration = math.min(duration, .85)
        Debris:AddItem(holder, duration + .05)
        update(0)
        table.insert(active, {holder = holder, parts = pieces, duration = duration, fadeStart = fadeStart, start = os.clock(), update = update})
        startTicker()
        return true
    end
    function api.Destroy()
        if connection then connection:Disconnect(); connection = nil end
        for _, effect in ipairs(active) do effect.holder:Destroy() end
        table.clear(active)
        folder:Destroy()
    end
    return api
end
return Effects