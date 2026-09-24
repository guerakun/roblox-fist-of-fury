-- Original native-part hero silhouettes and face art; no external character assets.
-- Only the seven canonical body parts participate in hit queries; all ornament is cosmetic.
local Factory = {}
local CharacterArt = require(game.ReplicatedStorage.Nightfall.Shared.CharacterArt)
local function rgb(r, g, b) return Color3.fromRGB(r, g, b) end
function Factory.Create(hero)
    local art = CharacterArt[hero] or CharacterArt.Gale
    local model = Instance.new("Model")
    model.Name = hero
    local skin = art.Skin
    local ink = rgb(28, 25, 32)
    local function part(name, size, color, position)
        local p = Instance.new("Part")
        p.Name, p.Size, p.Color, p.CFrame = name, size, color, CFrame.new(position)
        p.TopSurface, p.BottomSurface = Enum.SurfaceType.Smooth, Enum.SurfaceType.Smooth
        p.CanCollide, p.Massless = false, true
        p.Parent = model
        return p
    end
    local root = part("HumanoidRootPart", Vector3.new(2, 2, 1), skin, Vector3.new(0, 3, 0))
    root.Transparency, root.Massless = 1, false
    local torso = part("Torso", Vector3.new(2, 2, 1), art.Outfit, Vector3.new(0, 3, 0))
    torso.CanCollide = true
    local head = part("Head", Vector3.new(2, 1, 1), skin, Vector3.new(0, 4.5, 0))
    local headMesh = Instance.new("SpecialMesh")
    headMesh.MeshType, headMesh.Scale, headMesh.Parent = Enum.MeshType.Head, Vector3.new(1.05, 1.05, 1.05), head
    local armColor = art.Outfit
    local ra = part("Right Arm", Vector3.new(1, 2, 1), armColor, Vector3.new(1.5, 3, 0))
    local la = part("Left Arm", Vector3.new(1, 2, 1), armColor, Vector3.new(-1.5, 3, 0))
    local legColor = art.Legs
    local rl = part("Right Leg", Vector3.new(1, 2, 1), legColor, Vector3.new(.5, 1, 0))
    local ll = part("Left Leg", Vector3.new(1, 2, 1), legColor, Vector3.new(-.5, 1, 0))
    local function joint(name, p0, p1, c0, c1)
        local motor = Instance.new("Motor6D")
        motor.Name, motor.Part0, motor.Part1, motor.C0, motor.C1 = name, p0, p1, c0, c1
        motor.Parent = p0
    end
    local rot = CFrame.Angles(-math.pi / 2, 0, math.pi)
    joint("RootJoint", root, torso, rot, rot)
    joint("Neck", torso, head, CFrame.new(0, 1, 0) * rot, CFrame.new(0, -.5, 0) * rot)
    joint("Right Shoulder", torso, ra, CFrame.new(1, .5, 0) * CFrame.Angles(0, math.pi / 2, 0), CFrame.new(-.5, .5, 0) * CFrame.Angles(0, math.pi / 2, 0))
    joint("Left Shoulder", torso, la, CFrame.new(-1, .5, 0) * CFrame.Angles(0, -math.pi / 2, 0), CFrame.new(.5, .5, 0) * CFrame.Angles(0, -math.pi / 2, 0))
    joint("Right Hip", torso, rl, CFrame.new(1, -1, 0) * CFrame.Angles(0, math.pi / 2, 0), CFrame.new(.5, 1, 0) * CFrame.Angles(0, math.pi / 2, 0))
    joint("Left Hip", torso, ll, CFrame.new(-1, -1, 0) * CFrame.Angles(0, -math.pi / 2, 0), CFrame.new(-.5, 1, 0) * CFrame.Angles(0, -math.pi / 2, 0))
    local function detail(name, size, color, body, offset, shape)
        local p = part(name, size, color, Vector3.zero)
        if shape then p.Shape = shape end
        p.CanTouch, p.CanQuery, p.CastShadow = false, false, false
        p.CFrame = body.CFrame * offset
        local weld = Instance.new("WeldConstraint")
        weld.Part0, weld.Part1, weld.Parent = body, p, p
        return p
    end
    local function surface(name, body, face, canvasSize)
        local gui = Instance.new("SurfaceGui")
        gui.Name, gui.Adornee, gui.Face = name, body, face
        gui.SizingMode, gui.CanvasSize = Enum.SurfaceGuiSizingMode.FixedSize, canvasSize or Vector2.new(256, 256)
        gui.AlwaysOnTop, gui.LightInfluence, gui.Brightness, gui.MaxDistance = false, .2, 1.1, 110
        gui.Parent = body
        return gui
    end
    local function shape(parent, name, x, y, width, height, color, radius, rotation)
        local frame = Instance.new("Frame")
        frame.Name, frame.Position, frame.Size = name, UDim2.fromOffset(x, y), UDim2.fromOffset(width, height)
        frame.BackgroundColor3, frame.BorderSizePixel, frame.Rotation = color, 0, rotation or 0
        frame.Parent = parent
        if radius then
            local corner = Instance.new("UICorner")
            corner.CornerRadius = UDim.new(0, radius)
            corner.Parent = frame
        end
        return frame
    end
    -- Original vector expressions; the transparent carrier never participates in queries.
    local faceCarrier = detail("AuthoredFace", Vector3.new(1.56, .84, .018), skin, head, CFrame.new(0, -.045, -.546))
    faceCarrier.Transparency = 1
    local face = surface(art.FaceId, faceCarrier, Enum.NormalId.Front, Vector2.new(512, 320))
    face.LightInfluence, face.Brightness = .05, 1.1
    for _, side in ipairs({-1, 1}) do
        local x = side < 0 and 114 or 313
        local eye = shape(face, "EyeContour", x, 112, 91, 53, ink, 19, side * -4)
        eye.ClipsDescendants = true
        shape(eye, "EyeWhite", 3, 4, 85, 44, rgb(249, 246, 231), 17)
        local iris = shape(eye, "Iris", 28, 5, 39, 44, art.Iris, 20)
        shape(iris, "Pupil", 15, 5, 12, 34, ink, 6)
        shape(iris, "Glint", 8, 5, 9, 10, rgb(255, 255, 251), 5)
        shape(face, "Brow", x - 2, 91, 94, 9, art.Hair, 4, side * -7)
    end
    shape(face, "Nose", 252, 184, 7, 26, skin:Lerp(ink, .24), 4, -9)
    shape(face, "Smile", 223, 240, 67, 5, skin:Lerp(ink, .55), 3, hero == "Piston" and -7 or 0)
    if hero == "Gale" then
        shape(face, "BrowNotch", 143, 86, 5, 18, skin, 1, -7)
    elseif hero == "Piston" then
        for _, x in ipairs({119, 144, 169, 344, 369, 394}) do
            shape(face, "Freckle", x, 191 + x % 3 * 7, 5, 5, skin:Lerp(ink, .3), 3)
        end
    else
        shape(face, "BeautyDot", 351, 194, 7, 7, rgb(113, 78, 76), 4)
    end
    for _, side in ipairs({-1, 1}) do
        detail("Ear", Vector3.new(.14, .25, .16), skin, head, CFrame.new(side * .87, -.08, -.025), Enum.PartType.Ball)
    end
    for _, leg in ipairs({rl, ll}) do
        detail("WorkBoot", Vector3.new(1.05, .44, 1.13), rgb(25, 29, 38), leg, CFrame.new(0, -.79, -.035))
        detail("BootSole", Vector3.new(1.08, .10, 1.16), rgb(74, 80, 87), leg, CFrame.new(0, -.96, -.045))
    end
    if hero == "Gale" then
        -- Low swept undercut, asymmetrical silver-teal silhouette, no imported mesh.
        detail("Undercut", Vector3.new(1.62, .22, 1.04), rgb(55, 85, 93), head, CFrame.new(0, .38, .08))
        for i = 0, 4 do
            local crest = 1 - math.abs(i - 3) / 4
            local shade = art.Hair:Lerp(rgb(102, 158, 170), i % 2 == 0 and .12 or .30)
            detail("SweptHair", Vector3.new(.46, .30 + crest * .14, 1.08), shade, head,
                CFrame.new(-.58 + i * .27, .53 + crest * .14, .045) * CFrame.Angles(-.09, -.08, -.19), Enum.PartType.Ball)
        end
        detail("SideSweep", Vector3.new(.76, .18, .23), art.Hair, head, CFrame.new(.3, .38, -.48) * CFrame.Angles(0, 0, -.2), Enum.PartType.Ball)
        -- Broad wrap reads from either side camera; narrow front seams alone disappear at range.
        detail("CourierYoke", Vector3.new(2.06, .40, 1.08), rgb(119, 147, 157), torso, CFrame.new(0, .65, 0))
        detail("CroppedHem", Vector3.new(2.04, .20, 1.05), rgb(26, 34, 43), torso, CFrame.new(0, -.56, 0))
        detail("Underlayer", Vector3.new(1.99, .35, 1.01), rgb(93, 117, 125), torso, CFrame.new(0, -.81, 0))
        detail("OffsetZip", Vector3.new(.055, 1.4, .06), art.Accent, torso, CFrame.new(.26, .2, -.53))
        detail("ShortCollar", Vector3.new(2.03, .18, 1.03), rgb(68, 88, 97), torso, CFrame.new(0, .9, 0))
        for side, arm in ipairs({la, ra}) do
            detail("ShoulderPiping", Vector3.new(.08, .88, 1.025), art.Accent, arm, CFrame.new(side == 1 and -.43 or .43, .45, 0))
            detail("ForearmWrap", Vector3.new(1.04, .55, 1.04), rgb(79, 107, 117), arm, CFrame.new(0, -.48, 0))
            detail("Fingers", Vector3.new(.99, .23, 1.01), skin, arm, CFrame.new(0, -.91, 0))
            for i = 1, 2 do
                local ribbon = detail("WindRibbon", Vector3.new(.12, .72 + i * .12, .045), art.Hair, arm,
                    CFrame.new((i - 1.5) * .23, -.54, .7 + i * .10) * CFrame.Angles(.7, 0, (i - 1.5) * .3))
                ribbon.Transparency = .18
            end
        end
        local back = surface("CourierSeams", torso, Enum.NormalId.Back)
        shape(back, "AmberSeam", 25, 57, 205, 5, art.Accent, 2, -9)
        shape(back, "RouteTab", 183, 83, 35, 62, rgb(83, 125, 132), 4)
    elseif hero == "Piston" then
        -- Rounded curls and welding lenses identify a mechanic before the gauntlet silhouette.
        for i = 0, 8 do
            local angle = i * math.pi * 2 / 9
            detail("Curl", Vector3.new(.53, .43, .51), art.Hair, head,
                CFrame.new(math.cos(angle) * .62, .49 + (i % 2) * .10, math.sin(angle) * .32 + .06), Enum.PartType.Ball)
        end
        detail("CrownCurl", Vector3.new(.81, .44, .65), art.Hair, head, CFrame.new(0, .69, .06), Enum.PartType.Ball)
        detail("GoggleBridge", Vector3.new(.37, .08, .12), art.Accent, head, CFrame.new(0, .43, -.56))
        for _, x in ipairs({-.35, .35}) do
            detail("WeldingRim", Vector3.new(.57, .38, .18), art.Accent, head, CFrame.new(x, .45, -.56), Enum.PartType.Ball)
            detail("WeldingLens", Vector3.new(.43, .26, .04), rgb(100, 205, 204), head, CFrame.new(x, .45, -.66), Enum.PartType.Ball)
            detail("OverallStrap", Vector3.new(.23, 1.77, .08), rgb(54, 142, 147), torso, CFrame.new(x * 1.6, .06, -.54))
            detail("Buckle", Vector3.new(.27, .19, .10), art.Accent, torso, CFrame.new(x * 1.6, .47, -.59))
        end
        detail("BibPocket", Vector3.new(.70, .48, .10), rgb(22, 79, 88), torso, CFrame.new(0, -.01, -.56))
        detail("UtilityBelt", Vector3.new(2.06, .22, 1.06), rgb(61, 52, 44), torso, CFrame.new(0, -.81, 0))
        for _, arm in ipairs({ra, la}) do
            detail("WorkGlove", Vector3.new(1.04, .60, 1.04), rgb(156, 60, 58), arm, CFrame.new(0, -.66, 0))
        end
        local gauntlet = detail("PistonGauntlet", Vector3.new(1.36, 1.11, 1.34), art.Accent, ra, CFrame.new(0, -.48, -.04))
        gauntlet.Material = Enum.Material.Metal
        local plate = detail("SteelKnuckles", Vector3.new(1.39, .40, .29), rgb(128, 151, 164), ra, CFrame.new(0, -.81, -.78))
        plate.Material = Enum.Material.Metal
        for _, x in ipairs({-.53, .53}) do
            local piston = detail("GauntletPiston", Vector3.new(.15, .90, .15), rgb(157, 176, 188), ra, CFrame.new(x, -.36, -.55))
            piston.Material = Enum.Material.Metal
        end
        for i = 0, 2 do detail("SteamVent", Vector3.new(.64, .07, .08), rgb(60, 67, 73), ra, CFrame.new(0, -.2 - i * .16, .65)) end
    else
        -- Tied navy hair and a split long coat; a broad hooked glaive, not a short sword.
        detail("HairCap", Vector3.new(1.71, .44, 1.12), art.Hair, head, CFrame.new(0, .43, .06), Enum.PartType.Ball)
        for i = 1, 3 do
            detail("SideFringe", Vector3.new(.36, .38, .18), art.Hair, head,
                CFrame.new(-.55 + i * .28, .30 - i * .07, -.52) * CFrame.Angles(0, 0, -.32), Enum.PartType.Ball)
        end
        detail("PonytailTie", Vector3.new(.52, .36, .52), art.Accent, head, CFrame.new(0, .38, .66), Enum.PartType.Ball)
        for i = 1, 3 do
            detail("Ponytail", Vector3.new(.48 - i * .05, .67, .39), art.Hair, head,
                CFrame.new(i * .12, .25 - i * .49, .76 + i * .07) * CFrame.Angles(-.13, 0, .16), Enum.PartType.Ball)
        end
        detail("CoralClip", Vector3.new(.48, .22, .25), art.Accent, head, CFrame.new(-.69, .26, -.42) * CFrame.Angles(0, 0, -.5))
        detail("TidalMantle", Vector3.new(2.12, .42, 1.16), rgb(100, 155, 178), torso, CFrame.new(0, .67, .025))
        for _, x in ipairs({-.62, .62}) do
            detail("CoatTail", Vector3.new(.92, 1.34, 1.07), art.Outfit, torso, CFrame.new(x, -1.26, .05) * CFrame.Angles(0, 0, -x * .05))
            detail("FoamHem", Vector3.new(.94, .14, 1.09), rgb(218, 233, 236), torso, CFrame.new(x, -1.89, .05))
            detail("CoatLapel", Vector3.new(.15, 1.41, .075), rgb(218, 233, 236), torso, CFrame.new(x * .36, .3, -.54) * CFrame.Angles(0, 0, x * -.14))
        end
        for _, arm in ipairs({ra, la}) do
            detail("FoamCuff", Vector3.new(1.045, .2, 1.045), rgb(218, 233, 236), arm, CFrame.new(0, -.7, 0))
            detail("Hand", Vector3.new(1.01, .25, 1.01), skin, arm, CFrame.new(0, -.9, 0))
        end
        local shaft = detail("GlaiveShaft", Vector3.new(.19, 4.6, .19), rgb(108, 145, 161), ra,
            CFrame.new(.2, -.36, -.76) * CFrame.Angles(0, 0, -.10))
        for i = 0, 2 do detail("Grip", Vector3.new(.2, .10, .2), art.Accent, shaft, CFrame.new(0, -.22 + i * .18, 0)) end
        local blade = detail("GlaiveBlade", Vector3.new(.90, 1.35, .32), rgb(199, 227, 235), shaft,
            CFrame.new(.28, 1.96, 0) * CFrame.Angles(0, .48, -.24))
        blade.Material = Enum.Material.Metal
        detail("GlaiveHook", Vector3.new(.69, .23, .34), rgb(221, 239, 242), shaft, CFrame.new(.48, 1.35, 0) * CFrame.Angles(0, 0, .34))
    end

    local humanoid = Instance.new("Humanoid")
    humanoid.Name, humanoid.RequiresNeck, humanoid.DisplayDistanceType = "Humanoid", true, Enum.HumanoidDisplayDistanceType.None
    humanoid.Parent = model
    Instance.new("Animator", humanoid)
    local fill = Instance.new("PointLight")
    fill.Name, fill.Brightness, fill.Range, fill.Color, fill.Shadows = "CharacterFill", .55, 9, rgb(227, 232, 255), false
    fill.Parent = root
    local count = 0
    for _, item in ipairs(model:GetDescendants()) do if item:IsA("BasePart") then count += 1 end end
    model:SetAttribute("CharacterPartCount", count)
    model:SetAttribute("OriginalFaceArt", true)
    model:SetAttribute("OriginalFaceId", art.FaceId)
    model:SetAttribute("ArtRevision", "OriginalCast2")
    model.PrimaryPart = root
    return model
end
return Factory