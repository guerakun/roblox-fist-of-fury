-- Original R6 hero silhouettes, faces, and garment detail. Reviewed mesh references stay in CharacterArt.
-- Only the seven canonical body parts participate in hit queries; all ornament is cosmetic.
local Factory = {}
local CharacterArt = require(game.ReplicatedStorage.Nightfall.Shared.CharacterArt)
local function rgb(r, g, b) return Color3.fromRGB(r, g, b) end
function Factory.Create(hero)
    local model = Instance.new("Model")
    model.Name = hero
    local skin = rgb(239, 192, 157)
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
    local torso = part("Torso", Vector3.new(2, 2, 1), hero == "Naruto" and rgb(246, 133, 36) or hero == "Luffy" and rgb(175, 35, 47) or rgb(22, 36, 42), Vector3.new(0, 3, 0))
    torso.CanCollide = true
    local head = part("Head", Vector3.new(2, 1, 1), skin, Vector3.new(0, 4.5, 0))
    local headMesh = Instance.new("SpecialMesh")
    headMesh.MeshType, headMesh.Scale, headMesh.Parent = Enum.MeshType.Head, Vector3.new(1.05, 1.05, 1.05), head
    local armColor = hero == "Luffy" and skin or hero == "Naruto" and rgb(28, 37, 63) or rgb(26, 41, 44)
    local ra = part("Right Arm", Vector3.new(1, 2, 1), armColor, Vector3.new(1.5, 3, 0))
    local la = part("Left Arm", Vector3.new(1, 2, 1), armColor, Vector3.new(-1.5, 3, 0))
    local legColor = hero == "Luffy" and rgb(49, 83, 141) or hero == "Naruto" and rgb(239, 123, 30) or rgb(24, 32, 43)
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
    local function checkedSurface(name, body, face, columns, rows)
        local gui = surface(name, body, face)
        for row = 0, rows - 1 do
            for column = 0, columns - 1 do
                shape(gui, "WovenCheck", column * 256 / columns, row * 256 / rows, 256 / columns, 256 / rows,
                    (row + column) % 2 == 0 and rgb(42, 148, 104) or rgb(20, 36, 35))
            end
        end
        shape(gui, "HemStitch", 0, 248, 256, 5, rgb(16, 31, 29))
        return gui
    end

    -- Authored vector face panels: whites, iris rims, pupils, glints, lids and character marks.
    -- The transparent face carrier does not enlarge damage bounds and is naturally occluded by hair.
    local faceCarrier = detail("AuthoredFace", Vector3.new(1.56, .84, .018), skin, head, CFrame.new(0, -.045, -.546))
    faceCarrier.Transparency = 1
    local face = surface("OriginalAnimeFace", faceCarrier, Enum.NormalId.Front, Vector2.new(512, 320))
    face.LightInfluence, face.Brightness = .05, 1.2
    local irisColor = hero == "Naruto" and rgb(48, 140, 215) or hero == "Luffy" and rgb(45, 38, 35) or rgb(155, 55, 70)
    local eyeHeight = hero == "Luffy" and 70 or hero == "Tanjiro" and 61 or 51
    for _, side in ipairs({-1, 1}) do
        local x = side < 0 and 114 or 313
        local slant = hero == "Luffy" and side * -2 or side * -8
        local eye = shape(face, "EyeContour", x, 111, 91, eyeHeight, ink, 19, slant)
        eye.ClipsDescendants = true
        shape(eye, "EyeWhite", 3, 4, 85, eyeHeight - 9, rgb(255, 248, 235), 17)
        local iris = shape(eye, "IrisRim", 26, 6, 42, eyeHeight - 8, ink, 21)
        shape(iris, "IrisColor", 4, 3, 34, eyeHeight - 13, irisColor, 16)
        shape(iris, "Pupil", 15, 5, 13, math.max(20, eyeHeight - 18), rgb(16, 22, 29), 7)
        shape(iris, "EyeGlint", 9, 6, 9, 11, rgb(255, 255, 251), 5)
        shape(eye, "UpperLid", 0, -1, 91, hero == "Naruto" and 10 or 7, ink, 4)
        shape(face, "LowerLid", x + 7, 113 + eyeHeight, 78, 4, rgb(172, 110, 89), 2, slant)
        shape(face, "ExpressionBrow", x - 3, hero == "Luffy" and 88 or 87, 95, hero == "Tanjiro" and 13 or 10, hero == "Naruto" and rgb(116, 79, 26) or ink, 4, side * -10)
    end
    shape(face, "NoseContour", 252, 189, 7, 26, rgb(172, 112, 84), 4, -11)
    shape(face, "NoseHighlight", 260, 194, 3, 15, rgb(253, 214, 176), 2)
    if hero == "Luffy" then
        local grin = shape(face, "GrinOutline", 213, 242, 89, 29, rgb(88, 43, 37), 14)
        shape(grin, "SmileTeeth", 5, 3, 79, 14, rgb(255, 247, 225), 6)
        shape(face, "UnderEyeScar", 326, 197, 63, 5, rgb(117, 60, 52), 2, -5)
        for index = 0, 2 do shape(face, "ScarStitch", 333 + index * 20, 191, 4, 15, rgb(117, 60, 52), 1, 8) end
    else
        shape(face, "MouthLine", 222, 247, 67, 5, rgb(108, 55, 47), 3, hero == "Naruto" and -3 or 0)
        shape(face, "LowerLip", 238, 258, 36, 3, rgb(203, 145, 117), 2)
    end
    if hero == "Naruto" then
        for _, side in ipairs({-1, 1}) do
            for index = 0, 2 do
                shape(face, "WhiskerMark", side < 0 and 39 or 410, 186 + index * 22, 64, 4,
                    rgb(124, 82, 59), 2, side * (6 + index * 3))
            end
        end
    elseif hero == "Tanjiro" then
        local scarColor = rgb(132, 59, 51)
        shape(face, "ForeheadScarA", 120, 12, 28, 46, scarColor, 5, -17)
        shape(face, "ForeheadScarB", 139, 38, 26, 43, scarColor, 5, 23)
        shape(face, "ForeheadScarC", 118, 60, 24, 25, scarColor, 4, -12)
        shape(face, "ScarHighlight", 125, 27, 7, 24, rgb(178, 97, 78), 2, -17)
    end
    detail("NoseContour", Vector3.new(.075, .105, .068), rgb(226, 171, 135), head, CFrame.new(0, -.12, -.571), Enum.PartType.Ball)
    for _, side in ipairs({-1, 1}) do detail("EarContour", Vector3.new(.14, .25, .16), skin, head, CFrame.new(side * .87, -.08, -.025), Enum.PartType.Ball) end

    for _, leg in ipairs({rl, ll}) do
        if hero == "Luffy" then
            detail("Shin", Vector3.new(1.025, 1.08, 1.025), skin, leg, CFrame.new(0, -.46, 0))
            detail("SandalSole", Vector3.new(1.06, .13, 1.11), rgb(103, 67, 40), leg, CFrame.new(0, -.93, -.02))
            detail("SandalStrap", Vector3.new(.87, .095, .13), rgb(126, 79, 40), leg, CFrame.new(0, -.72, -.535))
        else
            detail("Boot", Vector3.new(1.03, .38, 1.08), rgb(21, 28, 37), leg, CFrame.new(0, -.81, -.03))
        end
    end
    if hero == "Naruto" then
        detail("JacketPanel", Vector3.new(1.3, 1.45, .08), rgb(26, 36, 62), torso, CFrame.new(0, .25, -.53))
        detail("Zip", Vector3.new(.055, 1.9, .09), rgb(220, 220, 210), torso, CFrame.new(0, 0, -.58))
        detail("ZipPull", Vector3.new(.10, .16, .035), rgb(187, 196, 203), torso, CFrame.new(.045, .56, -.64))
        detail("RaisedCollar", Vector3.new(2.07, .24, 1.03), rgb(26, 36, 62), torso, CFrame.new(0, .89, 0))
        for _, arm in ipairs({ra, la}) do
            detail("OrangeSleeve", Vector3.new(1.02, .78, 1.02), rgb(238, 128, 38), arm, CFrame.new(0, .2, 0))
            detail("SleeveCuff", Vector3.new(1.04, .17, 1.04), rgb(24, 32, 49), arm, CFrame.new(0, -.77, 0))
            detail("Hand", Vector3.new(1.015, .27, 1.015), skin, arm, CFrame.new(0, -.9, 0))
        end
        local back = surface("JacketBackSeams", torso, Enum.NormalId.Back)
        shape(back, "ShoulderYoke", 0, 0, 256, 59, rgb(30, 42, 63))
        shape(back, "CenterSeam", 126, 60, 4, 185, rgb(201, 94, 28))
        shape(back, "Hem", 0, 242, 256, 10, rgb(29, 41, 61))
        shape(back, "BackCrestRing", 94, 95, 68, 68, rgb(151, 46, 41), 34)
        shape(back, "BackCrestInset", 105, 106, 46, 46, rgb(240, 130, 39), 23)
        shape(back, "BackCrestCore", 119, 120, 18, 18, rgb(151, 46, 41), 9)
        shape(back, "BackCrestTail", 143, 144, 27, 9, rgb(151, 46, 41), 4, 36)
        for _, side in ipairs({-1, 1}) do detail("HeadbandRibbon", Vector3.new(.16, .51, .055), rgb(26, 37, 53), head, CFrame.new(side * .17, -.03, .57) * CFrame.Angles(0, 0, side * .26)) end
        if not CharacterArt[hero] then
            detail("Headband", Vector3.new(1.65, .28, 1.05), rgb(23, 34, 53), head, CFrame.new(0, .27, 0))
            detail("MetalPlate", Vector3.new(.83, .24, .07), rgb(164, 187, 203), head, CFrame.new(0, .27, -.56))
            for index = -3, 3 do detail("GoldenSpike", Vector3.new(.32, .6, .68), rgb(255, 199, 41), head, CFrame.new(index * .2, .75 - math.abs(index) * .025, .06) * CFrame.Angles(0, 0, -index * .15)) end
        end
    elseif hero == "Luffy" then
        detail("OpenVest", Vector3.new(.83, 1.72, .07), skin, torso, CFrame.new(0, .05, -.54))
        detail("Sash", Vector3.new(2.07, .28, 1.07), rgb(246, 192, 46), torso, CFrame.new(0, -.78, 0))
        for _, angle in ipairs({-.68, .68}) do detail("ChestScar", Vector3.new(.60, .058, .025), rgb(162, 89, 68), torso, CFrame.new(0, .16, -.59) * CFrame.Angles(0, 0, angle)) end
        for index = 0, 2 do detail("VestButton", Vector3.new(.095, .095, .035), rgb(233, 177, 61), torso, CFrame.new(-.49, .46 - index * .43, -.56), Enum.PartType.Ball) end
        local back = surface("VestBackSeams", torso, Enum.NormalId.Back)
        shape(back, "ShoulderSeam", 8, 33, 240, 4, rgb(131, 31, 39))
        shape(back, "CenterSeam", 126, 36, 4, 186, rgb(134, 29, 37))
        shape(back, "VestHem", 4, 228, 248, 5, rgb(120, 29, 37))
        shape(back, "NeckOpening", 85, 0, 86, 26, skin, 13)
        for _, faceId in ipairs({Enum.NormalId.Left, Enum.NormalId.Right}) do
            local side = surface("VestSideSeam", torso, faceId)
            shape(side, "Stitch", 126, 45, 5, 192, rgb(126, 28, 37))
        end
        if not CharacterArt[hero] then
            detail("HatBrim", Vector3.new(.16, 2.6, 2.6), rgb(222, 177, 91), head, CFrame.new(0, .66, .02) * CFrame.Angles(0, 0, math.pi / 2), Enum.PartType.Cylinder)
            detail("HatCrown", Vector3.new(.48, 1.65, 1.65), rgb(222, 177, 91), head, CFrame.new(0, .94, .02) * CFrame.Angles(0, 0, math.pi / 2), Enum.PartType.Cylinder)
            detail("HatRibbon", Vector3.new(.16, 1.7, 1.7), rgb(180, 35, 43), head, CFrame.new(0, .75, .02) * CFrame.Angles(0, 0, math.pi / 2), Enum.PartType.Cylinder)
        end
    else
        for row = 0, 3 do for column = 0, 3 do
            local color = (row + column) % 2 == 0 and rgb(40, 155, 111) or rgb(20, 32, 35)
            detail("HaoriCheck", Vector3.new(.48, .47, .07), color, torso, CFrame.new(-.75 + column * .5, .72 - row * .48, -.55))
        end end
        local back = checkedSurface("HaoriBackChecks", torso, Enum.NormalId.Back, 4, 4)
        shape(back, "BackCenterSeam", 127, 0, 3, 249, rgb(15, 30, 29))
        for _, arm in ipairs({ra, la}) do
            checkedSurface("SleeveFrontChecks", arm, Enum.NormalId.Front, 2, 4)
            checkedSurface("SleeveBackChecks", arm, Enum.NormalId.Back, 2, 4)
            checkedSurface("SleeveOuterChecks", arm, arm == ra and Enum.NormalId.Right or Enum.NormalId.Left, 2, 4)
            detail("HaoriCuff", Vector3.new(1.035, .18, 1.035), rgb(22, 39, 36), arm, CFrame.new(0, -.83, 0))
            detail("Hand", Vector3.new(1.02, .24, 1.02), skin, arm, CFrame.new(0, -.92, 0))
        end
        for _, side in ipairs({-1, 1}) do detail("WhiteCollar", Vector3.new(.13, .52, .04), rgb(224, 225, 206), torso, CFrame.new(side * .13, .71, -.61) * CFrame.Angles(0, 0, side * -.38)) end
        for _, leg in ipairs({rl, ll}) do
            for index = 0, 2 do detail("LegWrap", Vector3.new(1.02, .11, 1.035), rgb(206, 207, 187), leg, CFrame.new(0, -.35 - index * .19, 0)) end
        end
        for _, x in ipairs({-.77, .77}) do
            local earring = detail("HanafudaEarring", Vector3.new(.15, .4, .1), rgb(237, 224, 199), head, CFrame.new(x, -.39, -.15))
            local art = surface("AuthoredEarringMotif", earring, Enum.NormalId.Front, Vector2.new(64, 160))
            shape(art, "Sun", 20, 19, 24, 24, rgb(180, 57, 48), 12)
            for index = -1, 1 do shape(art, "Ray", 30 + index * 10, 53, 4, 80, rgb(77, 78, 74), 1, index * 14) end
            shape(art, "Footer", 7, 141, 50, 4, rgb(77, 78, 74))
        end
        detail("Scabbard", Vector3.new(.17, 3.4, .19), rgb(21, 28, 34), torso, CFrame.new(-.25, .05, .69) * CFrame.Angles(0, 0, -.52))
        local handle = detail("SwordHandle", Vector3.new(.2, .64, .2), rgb(236, 218, 193), torso, CFrame.new(.65, 1.62, .69) * CFrame.Angles(0, 0, -.52))
        for index = 0, 3 do detail("HandleBinding", Vector3.new(.225, .065, .225), rgb(45, 46, 43), handle, CFrame.new(0, -.24 + index * .15, 0)) end
        detail("SwordGuard", Vector3.new(.48, .085, .43), rgb(84, 91, 86), handle, CFrame.new(0, -.36, 0))
        if not CharacterArt[hero] then
            for index = -3, 3 do detail("BurgundyHair", Vector3.new(.34, .51, .7), rgb(72, 30, 39), head, CFrame.new(index * .19, .56, 0) * CFrame.Angles(0, 0, -index * .14)) end
        end
    end

    -- Preserve reviewed asset IDs, native mesh scales, and attachment transforms exactly.
    for _, spec in ipairs(CharacterArt[hero] or {}) do
        local p = detail(spec.Name, spec.Size, spec.Color, head, spec.Offset)
        p:SetAttribute("ToolboxSource", spec.Source)
        local mesh = Instance.new("SpecialMesh")
        mesh.MeshType, mesh.MeshId, mesh.TextureId, mesh.Scale = Enum.MeshType.FileMesh, spec.Mesh, spec.Texture, spec.Scale
        mesh.Parent = p
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
    model.PrimaryPart = root
    return model
end
return Factory