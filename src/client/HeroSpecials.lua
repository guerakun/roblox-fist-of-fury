--!strict
-- Original special presentation. Config is the footprint/timing source; this module never queries hits.
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Debris = game:GetService("Debris")
local Config = require(game:GetService("ReplicatedStorage").Nightfall.Shared.Config)
local Specials = {}
local function angle(x: number, y: number, z: number): CFrame
    return CFrame.Angles(math.rad(x), math.rad(y), math.rad(z))
end
function Specials.Pose(hero: string, age: number): any
    local spec = Config.Characters[hero]
    if not spec then return nil end
    local windup = spec.Special.Windup
    if age > windup + .48 then return nil end
    local charge = math.clamp(age / windup, 0, 1)
    local release = math.clamp((age - windup) / .12, 0, 1)
    local settle = 1 - math.clamp((age - windup - .16) / .32, 0, 1)
    local power = release * settle
    charge *= settle
    if hero == "Gale" then
        return {Torso = angle(-8 * charge, -25 * charge + 100 * power, -12 * power),
            ["Right Leg"] = angle(-24 * charge - 65 * power, 0, -12 * power),
            ["Left Leg"] = angle(18 * charge, 0, 8 * power),
            ["Right Arm"] = angle(-40 * charge, 0, 25 * power), ["Left Arm"] = angle(-28 * charge, 0, -28 * power)}
    elseif hero == "Piston" then
        return {Torso = angle(0, -22 * charge + 48 * power, 0),
            ["Right Arm"] = angle(-38 * charge - 58 * power, 8 * charge, 8 * power),
            ["Left Arm"] = angle(-45 * charge, 0, -12 * charge), ["Right Leg"] = angle(12 * power, 0, 0)}
    else
        return {Torso = angle(0, -38 * charge + 100 * power, 0),
            ["Right Arm"] = angle(-80 * charge + 34 * power, 0, -32 * charge + 65 * power),
            ["Left Arm"] = angle(-46 * charge, 0, 22 * charge - 40 * power),
            ["Right Leg"] = angle(0, -15 * power, -10 * power), ["Left Leg"] = angle(0, 12 * power, 8 * power)}
    end
end
function Specials.new(folder: Instance, preferences: any, onImpact: ((Vector3) -> ())?): any
    local effects = {}
    local connection: RBXScriptConnection? = nil
    local api = {}
    local function part(holder: Instance, name: string, color: Color3, size: Vector3, shape: Enum.PartType?): BasePart
        local p = Instance.new("Part")
        p.Name = name; p.Anchored = true; p.CanCollide = false; p.CanTouch = false; p.CanQuery = false
        p.CastShadow = false; p.Color = color; p.Material = Enum.Material.Neon; p.Size = size
        p.Transparency = 1
        if shape then p.Shape = shape end
        p.Parent = holder
        return p
    end
    local function segment(p: BasePart, a: Vector3, b: Vector3, thickness: number, fade: number)
        p.Size = Vector3.new(thickness, thickness, math.max(.01, (b - a).Magnitude))
        p.CFrame = CFrame.lookAt((a + b) * .5, b)
        p.Transparency = fade
    end
    function api.Emit(position: Vector3, hero: string, direction: number, userId: number?): boolean
        local spec = Config.Characters[hero]
        if not spec or preferences.effects <= 0 or #effects >= 8 then return false end
        local attack = spec.Special
        local reach, width, windup = attack.Range, attack.Width, attack.Windup
        direction = direction >= 0 and 1 or -1
        local holder = Instance.new("Folder")
        holder.Name = hero .. "Special"; holder.Parent = folder
        holder:SetAttribute("FootprintRange", reach); holder:SetAttribute("FootprintWidth", width)
        holder:SetAttribute("Windup", windup); holder:SetAttribute("AuthoritativeDamage", false)
        local owner = userId and Players:GetPlayerByUserId(userId)
        local character = owner and owner.Character
        local origin = position
        local frozen = false
        local edges = {}
        for i = 1, 4 do edges[i] = part(holder, "CoverageEdge", spec.Color, Vector3.one) end
        local bits = {}
        local count = hero == "Tide" and 18 or hero == "Gale" and 18 or 14
        for i = 1, count do bits[i] = part(holder, "SpecialRibbon", spec.Color, Vector3.one) end
        local fist: BasePart? = nil
        if hero == "Piston" then
            fist = part(holder, "MechanicalFist", Color3.fromRGB(202, 157, 85), Vector3.new(1.6, 1.8, 1.6))
            fist.Material = Enum.Material.Metal
            for i = 1, 8 do bits[i].Material = Enum.Material.Metal; bits[i].Color = Color3.fromRGB(145, 172, 187) end
            for i = 9, count do bits[i].Color = Color3.fromRGB(210, 230, 226) end
        end
        local effect = {holder = holder, started = os.clock(), lifetime = windup + .58}
        effect.update = function(age: number)
            if character then
                local h = character:FindFirstChildOfClass("Humanoid")
                if not character.Parent or (owner and owner.Character ~= character) or (h and h.Health <= 0) or character:GetAttribute("Downed") then
                    holder:Destroy()
                    return
                end
            end
            if not frozen then
                local root = character and character:FindFirstChild("HumanoidRootPart")
                if root and root:IsA("BasePart") then origin = root.Position end
                if age >= windup then
                    frozen = true
                    if onImpact then onImpact(origin) end
                end
            end
            local charge = math.clamp(age / windup, 0, 1)
            local strike = age >= windup
            local fade = math.clamp((age - windup - .10) / .38, 0, 1)
            local function point(x: number, y: number, z: number): Vector3
                return origin + Vector3.new(direction * x, y, z)
            end
            -- Configured coverage edges clarify the forward box; replicated timing/origin remain a visual estimate.
            local corners = {point(0, -2.78, -width/2), point(reach, -2.78, -width/2),
                point(reach, -2.78, width/2), point(0, -2.78, width/2)}
            for i, edge in ipairs(edges) do
                segment(edge, corners[i], corners[i % 4 + 1], .045, strike and math.min(1, .48 + fade) or 1)
            end
            if hero == "Gale" then
                -- Three corkscrew wind ribbons spanning only the configured forward box.
                for i, ribbon in ipairs(bits) do
                    local band = math.floor((i - 1) / 6)
                    local step = (i - 1) % 6
                    local length = strike and reach or 2.1 * charge
                    local theta = age * 19 + band * math.pi * 2/3 + step * .65
                    local radius = strike and (width/2 - .15) or .8
                    local a = point(length * step/6, math.cos(theta) * 1.3, math.sin(theta) * radius)
                    local b = point(length * (step+1)/6, math.cos(theta+.65) * 1.3, math.sin(theta+.65) * radius)
                    segment(ribbon, a, b, .08, strike and .16 + fade * .84 or .55)
                end
            elseif hero == "Piston" then
                local extension = strike and (1 - math.clamp((age - windup - .09)/.24, 0, 1)) or 0
                local endpoint = math.max(1.2, (reach - .8) * extension)
                if fist then fist.Position = point(endpoint, -.1, 0); fist.Transparency = strike and fade or .12 end
                -- Segmented piston/chain is steel, never a skin-colored stretching limb.
                for i = 1, 8 do
                    segment(bits[i], point((i-1)*endpoint/8, -.1, 0), point(i*endpoint/8, -.1, 0), i%2==0 and .18 or .27, fade)
                end
                for i = 9, count do
                    local lane = (i-9)/5 * width - width/2
                    segment(bits[i], point(strike and reach*.35 or .3, -.4, lane),
                        point(strike and reach-.1 or 1.2, .4 + (i%2)*.35, lane), .065,
                        strike and math.min(1, .58 + fade) or 1)
                end
            else
                -- Front half-ellipse matches forward Range and full lane Width, not a radial hitbox.
                local span = strike and math.pi or .3 * charge
                for i, ribbon in ipairs(bits) do
                    local a = (i-1)/#bits * span
                    local b = i/#bits * span
                    segment(ribbon, point(math.sin(a) * reach, .15, math.cos(a) * width/2),
                        point(math.sin(b) * reach, .15, math.cos(b) * width/2), i%3==0 and .18 or .10,
                        strike and .12 + fade*.88 or .7)
                    if i%3==0 then ribbon.Color = Color3.fromRGB(218, 246, 247) end
                end
            end
        end
        table.insert(effects, effect)
        Debris:AddItem(holder, effect.lifetime + .15)
        if not connection then
            connection = RunService.RenderStepped:Connect(function()
                for i = #effects, 1, -1 do
                    local active = effects[i]
                    local age = os.clock() - active.started
                    if not active.holder.Parent or age >= active.lifetime then active.holder:Destroy(); table.remove(effects, i)
                    else active.update(age) end
                end
                if #effects == 0 and connection then connection:Disconnect(); connection = nil end
            end)
        end
        return true
    end
    function api.Destroy()
        for _, active in ipairs(effects) do active.holder:Destroy() end
        table.clear(effects)
        if connection then connection:Disconnect(); connection = nil end
    end
    return api
end
return Specials
