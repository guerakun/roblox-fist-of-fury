-- Original R6 curse silhouettes. Canonical joints support the reviewed Toolbox poses.
local Factory = {}
local charcoal = Color3.fromRGB(30, 34, 46)
local metal = Color3.fromRGB(72, 79, 93)
local bone = Color3.fromRGB(192, 201, 210)
function Factory.Create(kind, spec)
    local scale = spec.Scale
    local model = Instance.new("Model")
    model.Name = spec.Name
    local function part(name, size, position, color, material)
        local p = Instance.new("Part")
        p.Name, p.Size, p.CFrame = name, size * scale, CFrame.new(position * scale)
        p.Color = color or charcoal
        p.Material = material or Enum.Material.SmoothPlastic
        p.TopSurface, p.BottomSurface = Enum.SurfaceType.Smooth, Enum.SurfaceType.Smooth
        p.CanCollide, p.CanTouch, p.Massless = false, false, true
        p.Parent = model
        return p
    end
    local root = part("HumanoidRootPart", Vector3.new(2, 2, 1), Vector3.new(0, 3, 0))
    root.Transparency, root.Massless = 1, false
    local torso = part("Torso", Vector3.new(2, 2, 1), Vector3.new(0, 3, 0))
    torso.CanCollide = true
    local head = part("Head", Vector3.new(1.6, 1, 1.1), Vector3.new(0, 4.5, 0), metal)
    local leftArm = part("Left Arm", Vector3.new(1, 2, 1), Vector3.new(-1.5, 3, 0), metal)
    local rightArm = part("Right Arm", Vector3.new(1, 2, 1), Vector3.new(1.5, 3, 0), metal)
    local leftLeg = part("Left Leg", Vector3.new(1, 2, 1), Vector3.new(-0.5, 1, 0))
    local rightLeg = part("Right Leg", Vector3.new(1, 2, 1), Vector3.new(0.5, 1, 0))
    local function joint(name, a, b, c0, c1)
        local j = Instance.new("Motor6D")
        j.Name, j.Part0, j.Part1, j.C0, j.C1 = name, a, b, c0, c1
        j.Parent = a
    end
    local rot = CFrame.Angles(-math.pi / 2, 0, math.pi)
    joint("RootJoint", root, torso, rot, rot)
    joint("Neck", torso, head, CFrame.new(0, scale, 0) * rot, CFrame.new(0, -0.5 * scale, 0) * rot)
    joint("Right Shoulder", torso, rightArm, CFrame.new(scale, .5 * scale, 0) * CFrame.Angles(0, math.pi / 2, 0), CFrame.new(-.5 * scale, .5 * scale, 0) * CFrame.Angles(0, math.pi / 2, 0))
    joint("Left Shoulder", torso, leftArm, CFrame.new(-scale, .5 * scale, 0) * CFrame.Angles(0, -math.pi / 2, 0), CFrame.new(.5 * scale, .5 * scale, 0) * CFrame.Angles(0, -math.pi / 2, 0))
    joint("Right Hip", torso, rightLeg, CFrame.new(scale, -scale, 0) * CFrame.Angles(0, math.pi / 2, 0), CFrame.new(.5 * scale, scale, 0) * CFrame.Angles(0, math.pi / 2, 0))
    joint("Left Hip", torso, leftLeg, CFrame.new(-scale, -scale, 0) * CFrame.Angles(0, -math.pi / 2, 0), CFrame.new(-.5 * scale, scale, 0) * CFrame.Angles(0, -math.pi / 2, 0))
    local cosmeticPartCount = 0
    local function detail(name, host, size, offset, color, neon, rotation)
        local p = part(name, size, Vector3.zero, color, neon and Enum.Material.Neon or Enum.Material.Metal)
        p.CFrame = host.CFrame * CFrame.new(offset * scale) * (rotation or CFrame.identity)
        p.CanQuery = false
        cosmeticPartCount += 1
        local weld = Instance.new("WeldConstraint")
        weld.Part0, weld.Part1, weld.Parent = host, p, p
        return p
    end
    local function eye(host, offset, width)
        return detail("CurseEye", host, Vector3.new(width or 1.25, .14, .1), offset, spec.Color, true)
    end
    local elite = kind == "Executioner" or kind == "SirenMarshal" or kind == "PlatformWidow"
        or kind == "LastConductor" or kind == "FurnaceHound" or kind == "KilnSovereign"
    if not elite then eye(head, Vector3.new(0, .06, -.59)) end
    detail("Core", torso, Vector3.new(.4, .65, .12), Vector3.new(0, .2, -.57), spec.Color, true)
    if kind == "Executioner" then
        detail("RoadArmor", torso, Vector3.new(2.35, 1.5, 1.2), Vector3.new(0, .05, 0), metal)
        for i = -1, 1 do detail("WarningStripe", torso, Vector3.new(.32, 1.45, .13), Vector3.new(i * .62, .07, -.66), spec.Color, false, CFrame.Angles(0, 0, -.3)) end
        detail("SignalHelmet", head, Vector3.new(2, .4, 1.4), Vector3.new(0, .58, 0), charcoal)
        detail("CleaverHandle", rightArm, Vector3.new(.22, 3.6, .25), Vector3.new(0, -.4, -.65), metal)
        detail("CrosswalkCleaver", rightArm, Vector3.new(1.3, 2.1, .18), Vector3.new(.5, -1.5, -.68), bone)
        detail("CleaverEdge", rightArm, Vector3.new(.12, 2.1, .23), Vector3.new(1.14, -1.5, -.68), spec.Color, true)
    elseif kind == "SirenMarshal" then
        detail("OfficerBreastplate", torso, Vector3.new(2.35, 1.75, 1.25), Vector3.zero, Color3.fromRGB(35, 45, 72))
        for _, x in ipairs({-1.5, 1.5}) do
            local shoulder = x < 0 and leftArm or rightArm
            detail("Pauldron", shoulder, Vector3.new(1.45, .7, 1.4), Vector3.new(0, .95, 0), metal)
            local lamp = detail("AlarmBeacon", shoulder, Vector3.new(.5, .7, .5), Vector3.new(0, 1.5, 0), x < 0 and spec.Color or Color3.fromRGB(80, 166, 255), true)
            lamp.Shape = Enum.PartType.Cylinder
        end
        detail("MarshalHelmet", head, Vector3.new(1.9, .65, 1.5), Vector3.new(0, .45, .05), charcoal)
        detail("Visor", head, Vector3.new(1.7, .3, .13), Vector3.new(0, .06, -.69), Color3.fromRGB(17, 28, 44), false)
        detail("SignalBaton", rightArm, Vector3.new(.3, 2.7, .3), Vector3.new(0, -1.1, -.65), spec.Color, true)
    elseif kind == "PlatformWidow" then
        detail("VeiledMask", head, Vector3.new(1.2, 1.35, .32), Vector3.new(0, -.12, -.6), bone)
        -- Small separated eyes are authored below on the porcelain mask.
        detail("Spine", torso, Vector3.new(.5, 2.7, .6), Vector3.new(0, 0, .72), spec.Color)
        for side = -1, 1, 2 do
            for i = 1, 3 do
                detail("RailRib", torso, Vector3.new(.16, 2.6, .2), Vector3.new(side * (1.2 + i * .2), .7 - i * .45, .65), metal, false, CFrame.Angles(0, 0, side * (.55 + i * .15)))
                detail("RibTip", torso, Vector3.new(.18, .6, .22), Vector3.new(side * (2.0 + i * .16), .0 - i * .42, .65), spec.Color, true)
            end
        end
        detail("TicketBlade", rightArm, Vector3.new(.18, 2.6, .65), Vector3.new(0, -1.4, -.65), spec.Color, true)
    elseif kind == "LastConductor" then
        detail("Coat", torso, Vector3.new(2.3, 2.6, 1.2), Vector3.new(0, -.3, .03), Color3.fromRGB(31, 42, 68))
        for _, x in ipairs({-.45, .45}) do detail("CoatTrim", torso, Vector3.new(.1, 2.5, .13), Vector3.new(x, -.3, -.65), spec.Color, true) end
        detail("Cap", head, Vector3.new(2.05, .65, 1.55), Vector3.new(0, .58, 0), charcoal)
        detail("CapBrim", head, Vector3.new(2.1, .15, .9), Vector3.new(0, .27, -.65), metal)
        detail("CapBadge", head, Vector3.new(.55, .32, .15), Vector3.new(0, .54, -.82), spec.Color, true)
        detail("Staff", rightArm, Vector3.new(.15, 5.2, .15), Vector3.new(0, -.8, -.8), bone)
        local clock = detail("DepartureClock", rightArm, Vector3.new(.28, 1.2, 1.2), Vector3.new(0, 1.75, -.8), bone, false, CFrame.Angles(0, math.pi / 2, 0))
        clock.Shape = Enum.PartType.Cylinder
    elseif kind == "FurnaceHound" then
        detail("Carapace", torso, Vector3.new(2.65, 1.7, 1.85), Vector3.new(0, .3, .0), metal)
        detail("Muzzle", head, Vector3.new(1.65, .7, 1.4), Vector3.new(0, -.4, -.8), charcoal)
        detail("BurningMaw", head, Vector3.new(1.25, .26, .18), Vector3.new(0, -.5, -1.52), spec.Color, true)
        for _, side in ipairs({-1, 1}) do
            detail("HoundEar", head, Vector3.new(.35, 1.0, .5), Vector3.new(side * .62, .75, .05), metal, false, CFrame.Angles(0, 0, side * -.3))
            detail("FrontClaw", side < 0 and leftArm or rightArm, Vector3.new(1.25, .65, 1.65), Vector3.new(0, -.95, -.38), charcoal)
            for i = 1, 3 do detail("Fang", side < 0 and leftArm or rightArm, Vector3.new(.12, .16, .75), Vector3.new((i - 2) * .3, -1.1, -1.35), spec.Color, true) end
        end
        for i = 1, 3 do detail("FurnaceSpine", torso, Vector3.new(.24, 1.0, .35), Vector3.new((i - 2) * .65, 1.3, .6), spec.Color, true) end
    elseif kind == "KilnSovereign" then
        detail("FurnaceBody", torso, Vector3.new(2.9, 2.35, 1.75), Vector3.new(0, .0, .05), metal)
        detail("FurnaceHeart", torso, Vector3.new(1.4, 1.5, .18), Vector3.new(0, -.05, -.92), spec.Color, true)
        for i = -2, 2 do detail("IronGrate", torso, Vector3.new(.15, 1.65, .2), Vector3.new(i * .28, -.05, -1.05), charcoal) end
        detail("Crown", head, Vector3.new(1.95, .5, 1.45), Vector3.new(0, .52, .05), metal)
        for _, x in ipairs({-.6, 0, .6}) do detail("CrownTooth", head, Vector3.new(.25, .8, .35), Vector3.new(x, 1, .0), spec.Color, true) end
        for _, side in ipairs({-1, 1}) do
            local host = side < 0 and leftArm or rightArm
            detail("ForgeGauntlet", host, Vector3.new(1.6, 1.55, 1.65), Vector3.new(0, -.55, -.2), metal)
            detail("HammerFace", host, Vector3.new(1.3, .45, 1.4), Vector3.new(0, -1.45, -.2), spec.Color, true)
            detail("Smokestack", torso, Vector3.new(.6, 2.0, .7), Vector3.new(side * 1.1, 1.5, .8), charcoal)
        end
    elseif kind == "Husk" then
        -- Worn cloth and asymmetric patches: the basic brawler stays visually light.
        detail("HuskJerkin", torso, Vector3.new(2.08, 1.62, 1.08), Vector3.new(0, -.16, 0), Color3.fromRGB(66, 65, 82))
        detail("HuskPatch", torso, Vector3.new(.62, .53, .09), Vector3.new(-.52, .1, -.62), bone, false, CFrame.Angles(0, 0, -.15))
        for _, arm in ipairs({leftArm, rightArm}) do
            for i = 0, 2 do
                local wrap = detail("HuskWornWrap", arm, Vector3.new(1.055, .16, 1.055), Vector3.new(0, -.40 - i * .2, 0), bone:Lerp(charcoal, i * .14))
                wrap.Material = Enum.Material.Fabric
            end
        end
        for i = 1, 3 do detail("HuskHem", torso, Vector3.new(.34, .32 + i * .07, .09), Vector3.new(-.7 + i * .36, -.94, -.56), Color3.fromRGB(66, 65, 82), false, CFrame.Angles(0, 0, (i - 2) * .14)) end
    elseif kind == "Strider" then
        -- Long low shin fins and heel cylinders read as a fast lane-slider.
        detail("StriderChestHarness", torso, Vector3.new(1.26, .68, .15), Vector3.new(0, .45, -.59), spec.Color)
        for _, leg in ipairs({leftLeg, rightLeg}) do
            detail("StriderShinPlate", leg, Vector3.new(.84, 1.30, .24), Vector3.new(0, -.12, -.58), spec.Color)
            detail("StriderToeFin", leg, Vector3.new(.89, .2, 1.56), Vector3.new(0, -.83, -.34), metal)
            local booster = detail("StriderHeelBooster", leg, Vector3.new(.7, .7, .8), Vector3.new(0, -.56, .7), charcoal)
            booster.Shape = Enum.PartType.Cylinder
            detail("StriderVent", leg, Vector3.new(.46, .12, .11), Vector3.new(0, -.56, 1.16), spec.Color)
        end
        detail("StriderSweptBrow", head, Vector3.new(1.83, .21, .24), Vector3.new(0, .33, -.6), spec.Color, false, CFrame.Angles(0, 0, -.08))
    elseif kind == "Grappler" then
        -- Squared grip gauntlets distinguish capture pressure from a weapon silhouette.
        detail("GrapplerApron", torso, Vector3.new(2.22, 1.87, 1.14), Vector3.new(0, -.13, 0), Color3.fromRGB(78, 69, 59))
        for _, arm in ipairs({leftArm, rightArm}) do
            detail("GrapplerGripGauntlet", arm, Vector3.new(1.39, 1.17, 1.4), Vector3.new(0, -.42, -.08), metal)
            detail("GrapplerCuff", arm, Vector3.new(1.43, .2, 1.43), Vector3.new(0, .24, -.08), spec.Color)
            for i = -1, 1 do detail("GrapplerGripFinger", arm, Vector3.new(.22, .53, .24), Vector3.new(i * .35, -.85, -.82), bone) end
        end
        detail("GrapplerJawGuard", head, Vector3.new(1.72, .42, .38), Vector3.new(0, -.33, -.63), spec.Color)
        detail("GrapplerBackLatch", torso, Vector3.new(.82, .87, .22), Vector3.new(0, .3, .67), metal)
    elseif kind == "Pitcher" then
        -- A visible rack of short throwing rods and shoulder canister identifies ranged pressure.
        detail("PitcherBandolier", torso, Vector3.new(.3, 2.23, .14), Vector3.new(0, .06, -.59), Color3.fromRGB(96, 75, 64), false, CFrame.Angles(0, 0, -.48))
        for i = -1, 2 do
            detail("PitcherThrowingRod", torso, Vector3.new(.14, .64, .15), Vector3.new(i * .30, .32 - i * .33, -.77), bone, false, CFrame.Angles(0, 0, -.2))
            detail("PitcherRodGrip", torso, Vector3.new(.2, .15, .2), Vector3.new(i * .30, .12 - i * .33, -.77), spec.Color)
        end
        detail("PitcherRangeSleeve", rightArm, Vector3.new(1.08, .58, 1.1), Vector3.new(0, -.45, 0), spec.Color)
        local canister = detail("PitcherShoulderCanister", torso, Vector3.new(.67, 1.43, .7), Vector3.new(-1.1, .52, .59), metal)
        canister.Shape = Enum.PartType.Cylinder
        detail("PitcherHalfMask", head, Vector3.new(1.2, .32, .19), Vector3.new(0, -.33, -.64), spec.Color)
    elseif kind == "Warden" then
        -- Paired broad forearm shields advertise frontal defense, not an enlarged damage target.
        detail("WardenChestPlate", torso, Vector3.new(2.21, 1.7, 1.19), Vector3.new(0, .08, 0), Color3.fromRGB(49, 76, 85))
        for _, arm in ipairs({leftArm, rightArm}) do
            detail("WardenForearmShield", arm, Vector3.new(1.38, 1.5, .31), Vector3.new(0, -.29, -.71), metal)
            for _, x in ipairs({-.59, .59}) do detail("WardenShieldRail", arm, Vector3.new(.10, 1.57, .12), Vector3.new(x, -.29, -.94), spec.Color) end
            detail("WardenShieldBar", arm, Vector3.new(1.28, .14, .12), Vector3.new(0, -.30, -.94), bone)
        end
        detail("WardenCrownGuard", head, Vector3.new(1.83, .28, 1.25), Vector3.new(0, .51, .02), metal)
        detail("WardenJawPlate", head, Vector3.new(1.29, .23, .2), Vector3.new(0, -.36, -.64), spec.Color)
    elseif kind == "Leaper" then
        -- Arched crest and heel arcs emphasize a tall acrobat silhouette without glowing ground tells.
        for i = 0, 2 do
            detail("LeaperArchedCrest", head, Vector3.new(.22, .75, .30), Vector3.new(0, .69 + math.sin(i * 1.2) * .25, -.1 + i * .35), spec.Color, false, CFrame.Angles(-.28 + i * .25, 0, 0))
        end
        for _, leg in ipairs({leftLeg, rightLeg}) do
            detail("LeaperHeelArc", leg, Vector3.new(.22, .83, .26), Vector3.new(0, -.42, .67), metal, false, CFrame.Angles(.5, 0, 0))
            detail("LeaperHeelFoot", leg, Vector3.new(.58, .14, .86), Vector3.new(0, -.81, .66), spec.Color)
            detail("LeaperAnkleWrap", leg, Vector3.new(1.04, .26, 1.04), Vector3.new(0, -.72, 0), bone)
        end
        detail("LeaperSplitHarness", torso, Vector3.new(.3, 1.98, .12), Vector3.new(.4, .0, -.59), spec.Color, false, CFrame.Angles(0, 0, .33))
        detail("LeaperShoulderFin", leftArm, Vector3.new(1.18, .24, .64), Vector3.new(0, .83, -.12), spec.Color, false, CFrame.Angles(0, 0, -.2))
    elseif kind == "Brute" then
        detail("ConcreteArmor", torso, Vector3.new(2.5, 1.7, 1.35), Vector3.zero, metal)
    elseif kind == "Runner" then
        detail("BladeCrest", head, Vector3.new(.22, 1.1, 1), Vector3.new(0, .7, .15), spec.Color)
    end
    -- Authored surface detail stays welded to the canonical seven hitbox parts.
    -- No new light emitters or large glowing planes: small eyes remain readable
    -- while floor warnings and attack effects retain the strongest contrast.
    local soot = Color3.fromRGB(19, 24, 31)
    local pale = Color3.fromRGB(223, 214, 190)
    local steel = Color3.fromRGB(127, 143, 158)
    local rust = Color3.fromRGB(134, 76, 49)
    local cloth = Color3.fromRGB(42, 52, 65)
    local function finish(name, host, size, offset, color, material, rotation)
        local p = detail(name, host, size, offset, color, false, rotation)
        p.Material = material or Enum.Material.Metal
        return p
    end
    local function rivet(host, x, y, z)
        local p = detail("Rivet", host, Vector3.new(.11, .11, .08), Vector3.new(x, y, z), steel)
        p.Shape = Enum.PartType.Ball
    end
    if kind == "Executioner" then
        finish("ChippedSignalMask", head, Vector3.new(1.52, .92, .15), Vector3.new(0, -.08, -.61), pale, Enum.Material.Concrete)
        for _, side in ipairs({-1, 1}) do
            detail("BlackEyeSocket", head, Vector3.new(.49, .23, .08), Vector3.new(side * .39, .1, -.72), soot)
            detail("TrafficEye", head, Vector3.new(.16, .11, .07), Vector3.new(side * .38, .09, -.78), side < 0 and Color3.fromRGB(247, 79, 66) or Color3.fromRGB(255, 197, 87), true)
            detail("AngledBrow", head, Vector3.new(.54, .09, .1), Vector3.new(side * .38, .27, -.75), charcoal, false, CFrame.Angles(0, 0, side * .16))
            finish("TempleArmor", head, Vector3.new(.14, .64, .8), Vector3.new(side * .81, -.1, -.03), metal)
            detail("RoadKneepad", side < 0 and leftLeg or rightLeg, Vector3.new(.82, .6, .18), Vector3.new(0, -.15, -.58), metal)
        end
        detail("MouthGrille", head, Vector3.new(.85, .24, .1), Vector3.new(0, -.32, -.73), soot)
        for i = -1, 1 do detail("GrilleTooth", head, Vector3.new(.1, .21, .08), Vector3.new(i * .23, -.32, -.8), steel) end
        finish("NeckGaiter", torso, Vector3.new(1.14, .28, 1.05), Vector3.new(0, 1, 0), cloth, Enum.Material.Fabric)
        for _, x in ipairs({-.98, .98}) do for _, y in ipairs({-.48, .58}) do rivet(torso, x, y, -.69) end end
        detail("TrafficSignalShield", leftArm, Vector3.new(.75, 1.58, .24), Vector3.new(0, -.1, -.65), soot)
        for index, color in ipairs({Color3.fromRGB(199, 66, 52), Color3.fromRGB(221, 166, 65), Color3.fromRGB(86, 135, 103)}) do
            local lamp = detail("ShieldSignalLens", leftArm, Vector3.new(.38, .38, .12), Vector3.new(0, .43 - (index - 1) * .5, -.81), color, index == 1)
            lamp.Shape = Enum.PartType.Ball
        end
        for i = -1, 1 do finish("CleaverGripTape", rightArm, Vector3.new(.3, .15, .32), Vector3.new(0, .2 + i * .27, -.65), cloth, Enum.Material.Fabric) end
        detail("CleaverDamage", rightArm, Vector3.new(.55, .06, .04), Vector3.new(.57, -1.07, -.79), metal, false, CFrame.Angles(0, 0, -.4))
        detail("CleaverDamage", rightArm, Vector3.new(.34, .04, .04), Vector3.new(.6, -1.78, -.79), metal, false, CFrame.Angles(0, 0, -.4))
        finish("UtilityBelt", torso, Vector3.new(2.12, .23, 1.12), Vector3.new(0, -.85, 0), soot, Enum.Material.Fabric)
        detail("BeltBuckle", torso, Vector3.new(.38, .24, .1), Vector3.new(0, -.85, -.64), steel)
    elseif kind == "SirenMarshal" then
        finish("MarshalFaceMask", head, Vector3.new(1.4, .48, .27), Vector3.new(0, -.33, -.6), steel)
        for _, side in ipairs({-1, 1}) do
            detail("MarshalEye", head, Vector3.new(.24, .1, .06), Vector3.new(side * .44, .06, -.78), side < 0 and spec.Color or Color3.fromRGB(119, 194, 252), true)
            detail("VisorBrow", head, Vector3.new(.61, .09, .1), Vector3.new(side * .43, .27, -.76), metal, false, CFrame.Angles(0, 0, side * .11))
            detail("CheekGuard", head, Vector3.new(.18, .47, .3), Vector3.new(side * .75, -.26, -.62), charcoal)
            finish("OfficerCuff", side < 0 and leftArm or rightArm, Vector3.new(1.04, .22, 1.06), Vector3.new(0, -.76, 0), pale, Enum.Material.Fabric)
            detail("ArmorElbow", side < 0 and leftArm or rightArm, Vector3.new(1.08, .48, .2), Vector3.new(0, -.12, .56), metal)
            finish("BeltPouch", torso, Vector3.new(.44, .49, .3), Vector3.new(side * .73, -.78, -.68), cloth, Enum.Material.Fabric)
        end
        for i = -1, 1 do detail("RespiratorVent", head, Vector3.new(.12, .25, .07), Vector3.new(i * .27, -.34, -.77), soot) end
        detail("OfficerBadge", torso, Vector3.new(.32, .41, .1), Vector3.new(-.66, .45, -.7), Color3.fromRGB(209, 177, 106), false, CFrame.Angles(0, 0, .18))
        detail("BadgeInset", torso, Vector3.new(.11, .2, .05), Vector3.new(-.66, .45, -.77), soot)
        detail("Nameplate", torso, Vector3.new(.57, .13, .08), Vector3.new(.57, .48, -.7), pale)
        detail("BreastplateSeam", torso, Vector3.new(.08, 1.3, .06), Vector3.new(0, .08, -.67), metal)
        finish("OfficerBelt", torso, Vector3.new(2.16, .2, 1.33), Vector3.new(0, -.91, 0), soot, Enum.Material.Fabric)
        for i = -1, 1 do rivet(torso, i * .16, -.9, -.73) end
        detail("BackRadioPack", torso, Vector3.new(1.15, 1.35, .38), Vector3.new(.19, .15, .78), charcoal)
        for i = -1, 1 do detail("RadioVent", torso, Vector3.new(.7, .08, .06), Vector3.new(.19, .15 + i * .24, 1), steel) end
        detail("RadioAntenna", torso, Vector3.new(.08, 1.55, .08), Vector3.new(.64, 1.16, .82), steel, false, CFrame.Angles(0, 0, -.1))
        detail("LeftReceiver", head, Vector3.new(.25, .46, .46), Vector3.new(-.93, -.03, .02), steel)
    elseif kind == "PlatformWidow" then
        for _, side in ipairs({-1, 1}) do
            detail("PorcelainEyeSocket", head, Vector3.new(.31, .3, .05), Vector3.new(side * .3, .07, -.785), soot, false, CFrame.Angles(0, 0, side * .2))
            detail("NeedleEye", head, Vector3.new(.09, .18, .05), Vector3.new(side * .3, .07, -.83), spec.Color, true)
            finish("TornVeil", head, Vector3.new(.22, 1.53, .83), Vector3.new(side * .74, -.21, .12), cloth, Enum.Material.Fabric, CFrame.Angles(0, 0, side * .1))
            detail("HollowMaskCheek", head, Vector3.new(.13, .4, .08), Vector3.new(side * .4, -.34, -.8), charcoal, false, CFrame.Angles(0, 0, side * -.22))
            finish("StationBandage", side < 0 and leftArm or rightArm, Vector3.new(1.02, .23, 1.04), Vector3.new(0, -.39, 0), pale, Enum.Material.Fabric)
        end
        detail("PorcelainCrack", head, Vector3.new(.055, .65, .035), Vector3.new(.13, .07, -.8), soot, false, CFrame.Angles(0, 0, -.28))
        detail("CrackBranch", head, Vector3.new(.29, .045, .04), Vector3.new(.28, .31, -.81), soot, false, CFrame.Angles(0, 0, -.2))
        detail("SilentMouth", head, Vector3.new(.24, .15, .05), Vector3.new(0, -.5, -.8), soot)
        finish("FrayedCollar", torso, Vector3.new(1.85, .3, 1.14), Vector3.new(0, .86, -.02), pale, Enum.Material.Fabric)
        finish("StationSash", torso, Vector3.new(.29, 1.85, .12), Vector3.new(.15, .02, -.59), Color3.fromRGB(73, 117, 116), Enum.Material.Fabric, CFrame.Angles(0, 0, -.38))
        for i = 1, 3 do
            finish("HangingPaperTicket", torso, Vector3.new(.29, .6 + i * .08, .055), Vector3.new(-.63 + (i - 1) * .58, -.9, -.58), pale, Enum.Material.SmoothPlastic, CFrame.Angles(0, 0, (i - 2) * .14))
            detail("TicketPunch", torso, Vector3.new(.13, .08, .04), Vector3.new(-.63 + (i - 1) * .58, -.81, -.625), soot)
        end
        for _, side in ipairs({-1, 1}) do for i = 1, 2 do detail("RibCoupling", torso, Vector3.new(.29, .22, .34), Vector3.new(side * (1.2 + i * .2), .7 - i * .45, .65), rust) end end
        detail("BladeBinding", rightArm, Vector3.new(.27, .42, .77), Vector3.new(0, -.38, -.65), metal)
    elseif kind == "LastConductor" then
        finish("SkeletalFace", head, Vector3.new(1.32, .86, .13), Vector3.new(0, -.06, -.62), pale, Enum.Material.Concrete)
        for _, side in ipairs({-1, 1}) do
            detail("SunkenEye", head, Vector3.new(.37, .25, .08), Vector3.new(side * .35, .07, -.72), soot)
            detail("TimetableEye", head, Vector3.new(.1, .12, .05), Vector3.new(side * .35, .07, -.78), spec.Color, true)
            finish("CoatLapel", torso, Vector3.new(.39, .84, .13), Vector3.new(side * .4, .6, -.69), steel, Enum.Material.Fabric, CFrame.Angles(0, 0, side * .25))
            finish("CoatPocket", torso, Vector3.new(.53, .24, .12), Vector3.new(side * .69, -.38, -.66), cloth, Enum.Material.Fabric)
            detail("ConductorCuff", side < 0 and leftArm or rightArm, Vector3.new(1.04, .23, 1.07), Vector3.new(0, -.73, 0), pale)
        end
        detail("NoseHollow", head, Vector3.new(.15, .16, .08), Vector3.new(0, -.12, -.73), soot)
        detail("StationmasterMouth", head, Vector3.new(.78, .19, .08), Vector3.new(0, -.34, -.72), soot)
        for i = -2, 2 do detail("MaskTooth", head, Vector3.new(.09, .16, .05), Vector3.new(i * .145, -.34, -.78), bone) end
        finish("IvoryShirt", torso, Vector3.new(.39, .94, .13), Vector3.new(0, .45, -.69), pale, Enum.Material.Fabric)
        finish("ConductorTie", torso, Vector3.new(.14, .61, .08), Vector3.new(0, .5, -.79), soot, Enum.Material.Fabric)
        for i = 1, 3 do rivet(torso, .23, .1 - i * .35, -.68) end
        detail("CapRibbon", head, Vector3.new(2.07, .1, 1.57), Vector3.new(0, .37, 0), Color3.fromRGB(123, 137, 164))
        detail("ClockDial", rightArm, Vector3.new(.84, .84, .04), Vector3.new(0, 1.75, -.98), soot)
        for _, mark in ipairs({Vector3.new(0, 2.12, -1.02), Vector3.new(0, 1.38, -1.02), Vector3.new(-.36, 1.75, -1.02), Vector3.new(.36, 1.75, -1.02)}) do
            detail("ClockTick", rightArm, Vector3.new(.09, .09, .035), mark, pale)
        end
        detail("StoppedMinuteHand", rightArm, Vector3.new(.06, .36, .045), Vector3.new(.06, 1.88, -1.04), pale, false, CFrame.Angles(0, 0, -.34))
        detail("StoppedHourHand", rightArm, Vector3.new(.26, .065, .045), Vector3.new(-.08, 1.75, -1.045), spec.Color)
    elseif kind == "FurnaceHound" then
        for _, side in ipairs({-1, 1}) do
            detail("HoundEyeSocket", head, Vector3.new(.43, .26, .14), Vector3.new(side * .49, .09, -.63), soot)
            detail("CoalEye", head, Vector3.new(.15, .12, .09), Vector3.new(side * .49, .09, -.74), spec.Color, true)
            detail("HeavyBrow", head, Vector3.new(.56, .12, .2), Vector3.new(side * .49, .29, -.67), steel, false, CFrame.Angles(0, 0, side * .23))
            detail("MuzzleSidePlate", head, Vector3.new(.12, .53, .95), Vector3.new(side * .87, -.33, -.7), rust)
            detail("JawHinge", head, Vector3.new(.19, .3, .3), Vector3.new(side * .91, -.42, -.39), steel)
            for i = 1, 2 do detail("IronCanine", head, Vector3.new(.13, .29, .13), Vector3.new(side * (.29 + (i - 1) * .21), -.48, -1.64), pale, false, CFrame.Angles(0, 0, side * .07)) end
        end
        detail("HoundNose", head, Vector3.new(.62, .2, .21), Vector3.new(0, -.16, -1.53), metal)
        for _, side in ipairs({-1, 1}) do detail("Nostril", head, Vector3.new(.14, .08, .055), Vector3.new(side * .17, -.15, -1.65), soot) end
        detail("JawLowerRail", head, Vector3.new(1.54, .14, .19), Vector3.new(0, -.75, -1.48), steel)
        for i = -1, 1 do detail("CarapaceVent", torso, Vector3.new(.15, .82, .1), Vector3.new(i * .5, .35, -1), soot) end
        for _, x in ipairs({-1.1, 1.1}) do for _, y in ipairs({-.3, .9}) do rivet(torso, x, y, -.99) end end
        finish("HeatTile", leftArm, Vector3.new(.85, .85, .17), Vector3.new(0, .27, -.59), pale, Enum.Material.Concrete)
        detail("BrokenEarCap", head, Vector3.new(.48, .2, .59), Vector3.new(.53, 1.08, .05), soot, false, CFrame.Angles(0, 0, -.3))
        detail("BackBoilerPlate", torso, Vector3.new(1.65, .8, .12), Vector3.new(0, .38, 1), rust)
    elseif kind == "KilnSovereign" then
        finish("RefractoryMask", head, Vector3.new(1.53, .92, .16), Vector3.new(0, -.06, -.64), pale, Enum.Material.Concrete)
        for _, side in ipairs({-1, 1}) do
            detail("RoyalEyeRecess", head, Vector3.new(.45, .22, .07), Vector3.new(side * .39, .13, -.76), soot)
            detail("KilnEye", head, Vector3.new(.21, .09, .06), Vector3.new(side * .39, .13, -.82), spec.Color, true)
            detail("IronBrow", head, Vector3.new(.59, .09, .11), Vector3.new(side * .38, .3, -.77), rust, false, CFrame.Angles(0, 0, side * .18))
            detail("CrownCheekGuard", head, Vector3.new(.17, .68, .53), Vector3.new(side * .84, -.17, -.31), metal)
            finish("RefractoryShoulder", side < 0 and leftArm or rightArm, Vector3.new(1.2, .58, 1.23), Vector3.new(0, .84, 0), side < 0 and pale or rust, side < 0 and Enum.Material.Concrete or Enum.Material.Metal)
        end
        detail("KilnNoseRidge", head, Vector3.new(.14, .33, .16), Vector3.new(0, -.02, -.8), steel)
        detail("FurnaceMouth", head, Vector3.new(.77, .19, .08), Vector3.new(0, -.34, -.76), soot)
        for i = -1, 1 do detail("RoyalIronTooth", head, Vector3.new(.11, .18, .065), Vector3.new(i * .24, -.34, -.82), rust) end
        detail("MaskCrack", head, Vector3.new(.045, .38, .04), Vector3.new(.54, -.25, -.76), soot, false, CFrame.Angles(0, 0, -.4))
        for _, y in ipairs({-.9, .84}) do detail("FurnaceDoorFrame", torso, Vector3.new(1.84, .17, .2), Vector3.new(0, y, -1.06), rust) end
        for _, x in ipairs({-1.06, 1.06}) do for _, y in ipairs({-.86, .82}) do rivet(torso, x, y, -1.06) end end
        detail("DoorHinge", torso, Vector3.new(.22, .52, .24), Vector3.new(-.94, -.05, -1.05), steel)
        detail("DoorLatch", torso, Vector3.new(.43, .13, .3), Vector3.new(.94, -.04, -1.13), pale)
        for _, side in ipairs({-1, 1}) do
            detail("ChimneyBand", torso, Vector3.new(.72, .17, .82), Vector3.new(side * 1.1, 1.91, .8), rust)
            detail("ChimneyOpening", torso, Vector3.new(.43, .055, .5), Vector3.new(side * 1.1, 2.53, .8), soot)
        end
        finish("KingApron", torso, Vector3.new(1.65, .57, .12), Vector3.new(0, -1.35, -.5), cloth, Enum.Material.Fabric)
        detail("CrownCenterStone", head, Vector3.new(.28, .26, .1), Vector3.new(0, .57, -.75), Color3.fromRGB(104, 43, 36))
    end
    model:SetAttribute("CosmeticPartCount", cosmeticPartCount)
    local archetypeVisual = kind == "Husk" or kind == "Strider" or kind == "Grappler" or kind == "Pitcher" or kind == "Warden" or kind == "Leaper"
    model:SetAttribute("VisualRevision", archetypeVisual and "Archetypes-1" or "EliteFaces-1")
    if archetypeVisual then model:SetAttribute("ArchetypeVisual", kind) end
    local h = Instance.new("Humanoid")
    h.MaxHealth, h.Health = 100000, 100000
    h.HipHeight, h.BreakJointsOnDeath = 0, false
    h.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
    h.Parent = model
    Instance.new("Animator", h)
    model.PrimaryPart = root
    return model
end
return Factory
