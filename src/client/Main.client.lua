--!strict
-- Nightfall client: input, presentation, and camera only. Damage stays on the server.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local ContextActionService = game:GetService("ContextActionService")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")
local SoundService = game:GetService("SoundService")
local player = Players.LocalPlayer
local package = ReplicatedStorage:WaitForChild("Nightfall")
local remotes = package:WaitForChild("Remotes")
local actionRemote = remotes:WaitForChild("Action") :: RemoteEvent
local stateRemote = remotes:WaitForChild("State") :: RemoteEvent
local fxRemote = remotes:WaitForChild("FX") :: RemoteEvent

local COLORS = {
    ink = Color3.fromRGB(12, 17, 29), panel = Color3.fromRGB(20, 28, 43),
    text = Color3.fromRGB(239, 243, 255), muted = Color3.fromRGB(158, 174, 198),
    cyan = Color3.fromRGB(95, 232, 231), orange = Color3.fromRGB(255, 166, 76),
    red = Color3.fromRGB(255, 92, 112), green = Color3.fromRGB(88, 224, 167),
}
local HEROES = { "Naruto", "Luffy", "Tanjiro" }
local HERO_COLORS = { Naruto = COLORS.orange, Luffy = COLORS.red, Tanjiro = COLORS.green }
local HERO_MOVES = { Naruto = "SPIRAL BURST", Luffy = "ELASTIC CANNON", Tanjiro = "TIDAL ARC" }
local snapshot: any = {hero = "Naruto", percent = 0, stocks = 3, stage = 1, wave = 0,
    waves = 3, enemiesRemaining = 0, status = "Waiting", cooldowns = {}}
local facing = 1
local humanoid: Humanoid? = nil
local root: BasePart? = nil
local cameraKick = 0
local cameraPosition: Vector3? = nil
local gamepadMove = Vector2.zero
local touchMove = Vector2.zero
local heldKeys: {[Enum.KeyCode]: boolean} = {}
local lastLocalAction = 0
local poseSerial = 0
local shoulderDefaults: {[Motor6D]: CFrame} = {}
local rigJoints: {[Motor6D]: CFrame} = {}
local toolboxData: any = nil
local poseAction: string? = nil
local poseStart = 0
local localBlocking = false
local locomotionStart = os.clock()
local tracks: {[string]: AnimationTrack} = {}
local activeEffects = 0
local actorPoses: {[Model]: any} = {}
local activeSounds = 0
local lastHitSound = 0
local ambience = Instance.new("Sound")
ambience.Name = "NightfallCityAmbience"
ambience.SoundId = "rbxassetid://9112759731"
ambience.Volume = 0.12
ambience.Looped = true
ambience.Parent = SoundService
ambience:Play()
local function combatSound(kind: string, position: Vector3)
    local now = os.clock()
    if activeSounds >= 8 or (kind == "Hit" and now - lastHitSound < 0.07) then return end
    if kind == "Hit" then lastHitSound = now end
    local anchor = Instance.new("Part")
    anchor.Anchored = true; anchor.CanCollide = false; anchor.CanTouch = false; anchor.CanQuery = false
    anchor.Transparency = 1; anchor.Size = Vector3.one * 0.1; anchor.Position = position; anchor.Parent = workspace
    local sound = Instance.new("Sound")
    sound.SoundId = kind == "Hit" and "rbxassetid://132504023010884" or "rbxassetid://135315310485417"
    sound.Volume = kind == "Hit" and 0.33 or 0.17
    sound.PlaybackSpeed = kind == "Dash" and 1.15 or 1
    sound.RollOffMinDistance = 16; sound.RollOffMaxDistance = 130
    sound.Parent = anchor; sound:Play()
    activeSounds += 1
    task.delay(2.5, function() activeSounds -= 1 end)
    Debris:AddItem(anchor, 2.5)
end
task.spawn(function()
    local shared = package:WaitForChild("Shared", 20)
    local animations = shared and shared:WaitForChild("ToolboxAnimations", 20)
    if animations and animations:IsA("ModuleScript") then
        local ok, data = pcall(require, animations)
        if ok then toolboxData = data end
    end
end)
local effectsFolder = Instance.new("Folder")
effectsFolder.Name = "NightfallLocalEffects"
effectsFolder.Parent = workspace

local function make(class: string, properties: any, parent: Instance?): any
    local object = Instance.new(class)
    for key, value in pairs(properties) do (object :: any)[key] = value end
    object.Parent = parent
    return object
end
local function round(parent: Instance, radius: number)
    make("UICorner", {CornerRadius = UDim.new(0, radius)}, parent)
end
local function outline(parent: Instance, color: Color3, transparency: number?)
    return make("UIStroke", {Color = color, Transparency = transparency or 0.65, Thickness = 1}, parent)
end
local function label(parent: Instance, text: string, size: number, color: Color3, position: UDim2, dimensions: UDim2): TextLabel
    return make("TextLabel", {BackgroundTransparency = 1, Text = text, TextSize = size,
        Font = Enum.Font.GothamBold, TextColor3 = color, TextXAlignment = Enum.TextXAlignment.Left,
        Position = position, Size = dimensions}, parent)
end
local gui = make("ScreenGui", {Name = "NightfallHUD", ResetOnSpawn = false, IgnoreGuiInset = false,
    ZIndexBehavior = Enum.ZIndexBehavior.Sibling, DisplayOrder = 10}, player:WaitForChild("PlayerGui"))
local canvas = make("Frame", {BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1)}, gui)
local top = make("Frame", {BackgroundColor3 = COLORS.ink, BackgroundTransparency = 0.08,
    Position = UDim2.fromOffset(22, 16), Size = UDim2.fromOffset(342, 108)}, canvas)
round(top, 10); outline(top, COLORS.cyan)
label(top, "CURTAIN BREAK", 25, COLORS.text, UDim2.fromOffset(16, 9), UDim2.fromOffset(312, 30))
label(top, "F I S T   O F   F U R Y", 10, COLORS.cyan, UDim2.fromOffset(17, 39), UDim2.fromOffset(312, 16))
local chapterLabel = label(top, "01 / VEIL OVER THE CITY", 12, COLORS.muted, UDim2.fromOffset(17, 69), UDim2.fromOffset(310, 18))
local progressBack = make("Frame", {BackgroundColor3 = COLORS.panel, BorderSizePixel = 0,
    Position = UDim2.fromOffset(17, 94), Size = UDim2.fromOffset(308, 3)}, top)
local progressFill = make("Frame", {BackgroundColor3 = COLORS.cyan, BorderSizePixel = 0,
    Size = UDim2.fromScale(0, 1)}, progressBack)
local encounter = make("Frame", {BackgroundColor3 = COLORS.ink, BackgroundTransparency = 0.08,
    AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -22, 0, 16), Size = UDim2.fromOffset(245, 85)}, canvas)
round(encounter, 10); outline(encounter, COLORS.muted)
local waveLabel = label(encounter, "CO-OP / 1–4 PLAYERS", 12, COLORS.cyan, UDim2.fromOffset(16, 10), UDim2.fromOffset(215, 21))
local enemyLabel = label(encounter, "ENTER THE CURTAIN", 20, COLORS.text, UDim2.fromOffset(16, 34), UDim2.fromOffset(215, 26))
local objectiveLabel = label(encounter, "Clear each arena. Keep moving →", 10, COLORS.muted, UDim2.fromOffset(16, 63), UDim2.fromOffset(220, 15))

local playerPanel = make("Frame", {BackgroundColor3 = COLORS.ink, BackgroundTransparency = 0.05,
    Position = UDim2.new(0, 22, 1, -174), Size = UDim2.fromOffset(280, 151)}, canvas)
round(playerPanel, 10); outline(playerPanel, COLORS.orange)
local heroLabel = label(playerPanel, "NARUTO", 17, COLORS.orange, UDim2.fromOffset(15, 10), UDim2.fromOffset(245, 22))
local percentLabel = label(playerPanel, "0%", 46, COLORS.text, UDim2.fromOffset(14, 32), UDim2.fromOffset(170, 55))
local stocksLabel = label(playerPanel, "● ● ●", 19, COLORS.cyan, UDim2.fromOffset(180, 47), UDim2.fromOffset(86, 28))
local damageHint = label(playerPanel, "HIGHER % = BIGGER LAUNCH", 9, COLORS.muted, UDim2.fromOffset(16, 85), UDim2.fromOffset(249, 15))
local heroButtons: {[string]: TextButton} = {}
for index, hero in ipairs(HEROES) do
    local button = make("TextButton", {Name = hero, Text = tostring(index) .. "  " .. string.upper(hero),
        TextColor3 = HERO_COLORS[hero], TextSize = 10, Font = Enum.Font.GothamBold,
        AutoButtonColor = true, BackgroundColor3 = COLORS.panel, BorderSizePixel = 0,
        Position = UDim2.fromOffset(12 + (index - 1) * 87, 110), Size = UDim2.fromOffset(82, 29)}, playerPanel)
    round(button, 5); heroButtons[hero] = button
    button.Activated:Connect(function() actionRemote:FireServer("SelectCharacter", {hero = hero}) end)
end
local abilities = make("Frame", {BackgroundTransparency = 1, AnchorPoint = Vector2.new(1, 1),
    Position = UDim2.new(1, -22, 1, -23), Size = UDim2.fromOffset(468, 78)}, canvas)
local abilityLabels: {[string]: TextLabel} = {}
local abilityButtons: {[string]: TextButton} = {}
local abilityNames = {"Light", "Heavy", "Special", "Dash", "Block", "Recovery"}
local abilityKeys = {"J / X", "K / Y", "L / B", "Q / LT", "F / LB", "E / RB"}
for index, action in ipairs(abilityNames) do
    local button = make("TextButton", {Text = "", BackgroundColor3 = COLORS.ink, BackgroundTransparency = 0.05,
        Size = UDim2.fromOffset(73, 74), Position = UDim2.fromOffset((index - 1) * 79, 0), BorderSizePixel = 0}, abilities)
    round(button, 8); outline(button, action == "Special" and COLORS.cyan or COLORS.muted)
    local key = label(button, abilityKeys[index], 10, COLORS.muted, UDim2.fromOffset(6, 8), UDim2.fromOffset(61, 16))
    key.TextXAlignment = Enum.TextXAlignment.Center
    local text = label(button, string.upper(action), 10, COLORS.text, UDim2.fromOffset(3, 33), UDim2.fromOffset(67, 24))
    text.TextXAlignment = Enum.TextXAlignment.Center
    abilityLabels[action] = text; abilityButtons[action] = button
end
local moveLabel = label(canvas, "A D  MOVE    W S  DEPTH    SPACE  JUMP / DOUBLE JUMP", 10, COLORS.muted,
    UDim2.new(1, -490, 1, -126), UDim2.fromOffset(468, 20))
moveLabel.TextXAlignment = Enum.TextXAlignment.Right
local moveName = label(canvas, "SPIRAL BURST", 12, COLORS.cyan, UDim2.new(1, -490, 1, -149), UDim2.fromOffset(468, 20))
moveName.TextXAlignment = Enum.TextXAlignment.Right
local toastLabel = label(canvas, "", 22, COLORS.text, UDim2.new(0.5, -280, 0, 139), UDim2.fromOffset(560, 35))
toastLabel.TextXAlignment = Enum.TextXAlignment.Center
local toastSerial = 0
local function toast(text: string, color: Color3?)
    toastSerial += 1
    local token = toastSerial
    toastLabel.Text = text; toastLabel.TextColor3 = color or COLORS.text; toastLabel.TextTransparency = 0
    task.delay(3, function()
        if toastSerial == token then TweenService:Create(toastLabel, TweenInfo.new(0.6), {TextTransparency = 1}):Play() end
    end)
end

local ending = make("Frame", {Visible = false, BackgroundColor3 = COLORS.ink, BackgroundTransparency = 0.03,
    AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.48), Size = UDim2.fromOffset(420, 224)}, canvas)
round(ending, 14); outline(ending, COLORS.cyan, 0.25)
local endingTitle = label(ending, "CURTAIN BROKEN", 30, COLORS.cyan, UDim2.fromOffset(22, 24), UDim2.fromOffset(376, 44))
endingTitle.TextXAlignment = Enum.TextXAlignment.Center
local endingDetail = label(ending, "The city lives to see another dawn.", 13, COLORS.muted, UDim2.fromOffset(24, 80), UDim2.fromOffset(372, 48))
endingDetail.TextWrapped = true; endingDetail.TextXAlignment = Enum.TextXAlignment.Center
local retry = make("TextButton", {Text = "PLAY AGAIN  /  R", Font = Enum.Font.GothamBold, TextSize = 14,
    BackgroundColor3 = COLORS.cyan, TextColor3 = COLORS.ink, Position = UDim2.fromOffset(80, 156), Size = UDim2.fromOffset(260, 42)}, ending)
round(retry, 7)
retry.Activated:Connect(function() actionRemote:FireServer("Restart", {}) end)

-- Responsive panels retain legible labels; mobile gets a separate thumb pad and jump button.
local hudScale = make("UIScale", {Scale = 1}, top)
local encounterScale = make("UIScale", {Scale = 1}, encounter)
local playerScale = make("UIScale", {Scale = 1}, playerPanel)
local abilityScale = make("UIScale", {Scale = 1}, abilities)
local endingScale = make("UIScale", {Scale = 1}, ending)
local function resize()
    local camera = workspace.CurrentCamera
    if not camera then return end
    local width = camera.ViewportSize.X
    local scale = math.clamp(width / 1040, 0.57, 1)
    hudScale.Scale = scale; encounterScale.Scale = scale; playerScale.Scale = scale
    abilityScale.Scale = scale; endingScale.Scale = math.min(1, width / 460)
    playerPanel.Position = UDim2.new(0, 16, 1, -(151 * scale + 18))
    abilities.Position = UDim2.new(1, -16, 1, -18)
    moveLabel.Visible = width > 830 and not UserInputService.TouchEnabled
    moveName.Visible = width > 830
end

local function characterReady(character: Model)
    humanoid = character:WaitForChild("Humanoid") :: Humanoid
    root = character:WaitForChild("HumanoidRootPart") :: BasePart
    shoulderDefaults = {}; rigJoints = {}; tracks = {}; cameraPosition = nil; poseAction = nil; localBlocking = false
    for _, item in ipairs(character:GetDescendants()) do
        if item:IsA("Motor6D") and item.Part1 then rigJoints[item] = item.C0 end
        if item:IsA("Motor6D") and (string.find(item.Name, "Shoulder") or item.Name == "Waist") then
            shoulderDefaults[item] = item.C0
        end
    end
end
player.CharacterAdded:Connect(characterReady)
if player.Character then task.spawn(characterReady, player.Character) end
-- Disable the default controller so movement cannot escape the authored side-view orientation.
task.spawn(function()
    local module = player:WaitForChild("PlayerScripts"):WaitForChild("PlayerModule", 15)
    if module and module:IsA("ModuleScript") then
        local ok, controls = pcall(function() return require(module):GetControls() end)
        if ok then controls:Disable() end
    end
end)

local function asset(category: string, name: string): Instance?
    local assets = package:FindFirstChild("Assets")
    local folder = assets and assets:FindFirstChild(category)
    if not folder then return nil end
    local heroFolder = folder:FindFirstChild(snapshot.hero)
    return (heroFolder and heroFolder:FindFirstChild(name)) or folder:FindFirstChild(snapshot.hero .. "_" .. name) or folder:FindFirstChild(name)
end
local function animate(action: string)
    if not humanoid then return end
    local animation = asset("Animations", action)
    if animation and animation:IsA("Animation") and animation.AnimationId ~= "" then
        local key = snapshot.hero .. action
        local track = tracks[key]
        if not track then
            local animator = humanoid:FindFirstChildOfClass("Animator")
            if animator then
                local ok, loaded = pcall(function() return animator:LoadAnimation(animation) end)
                if ok then track = loaded; tracks[key] = track end
            end
        end
        if track then track.Priority = Enum.AnimationPriority.Action; track:Play(0.06); return end
    end
    if action == "Special" and toolboxData and toolboxData.Heavy then action = "Heavy" end
    if toolboxData and toolboxData[action] and humanoid.RigType == Enum.HumanoidRigType.R6 then
        poseAction = action; poseStart = os.clock()
        return
    end
    -- Visible authored pose fallback when an imported action or matching rig is unavailable.
    poseSerial += 1
    local serial = poseSerial
    local duration = action == "Heavy" and 0.32 or 0.21
    for joint, neutral in pairs(shoulderDefaults) do
        if joint.Parent then
            local rotation = CFrame.Angles(math.rad(action == "Block" and -72 or -105), 0, math.rad(facing * 16))
            if joint.Name == "Waist" then rotation = CFrame.Angles(0, math.rad(facing * -20), 0) end
            TweenService:Create(joint, TweenInfo.new(0.07), {C0 = neutral * rotation}):Play()
        end
    end
    task.delay(duration, function()
        if serial ~= poseSerial then return end
        for joint, neutral in pairs(shoulderDefaults) do
            if joint.Parent then TweenService:Create(joint, TweenInfo.new(0.16), {C0 = neutral}):Play() end
        end
    end)
end

local function send(action: string, held: boolean?)
    if UserInputService:GetFocusedTextBox() then return end
    if action == "Jump" then
        if snapshot.downed or snapshot.blocking or localBlocking or ending.Visible then return end
        if humanoid and humanoid.Health > 0 then
            local character = humanoid.Parent
            if character and (character:GetAttribute("Downed") or character:GetAttribute("Blocking")) then return end
            if humanoid.FloorMaterial ~= Enum.Material.Air then
                humanoid.Jump = true
                -- Explicit transition survives the disabled default PlayerModule clearing Jump.
                humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
            else actionRemote:FireServer("Recovery", {direction = facing}) end
        end
        return
    end
    if action == "Block" then localBlocking = held == true end
    actionRemote:FireServer(action, {direction = facing, held = held})
    if action == "Light" or action == "Heavy" or action == "Special" or action == "Dash" or (action == "Block" and held) then
        local now = os.clock()
        if now - lastLocalAction > 0.15 then animate(action); lastLocalAction = now end
    end
end
local bindings: any = {
    Light = {Enum.KeyCode.J, Enum.KeyCode.ButtonX}, Heavy = {Enum.KeyCode.K, Enum.KeyCode.ButtonY},
    Special = {Enum.KeyCode.L, Enum.KeyCode.ButtonB}, Dash = {Enum.KeyCode.Q, Enum.KeyCode.ButtonL2},
    Block = {Enum.KeyCode.F, Enum.KeyCode.ButtonL1}, Recovery = {Enum.KeyCode.E, Enum.KeyCode.ButtonR1},
    Jump = {Enum.KeyCode.Space, Enum.KeyCode.ButtonA},
}
for action, keys in pairs(bindings) do
    ContextActionService:BindAction("Nightfall_" .. action, function(_, inputState)
        if inputState == Enum.UserInputState.Begin then send(action, action == "Block" and true or nil)
        elseif (inputState == Enum.UserInputState.End or inputState == Enum.UserInputState.Cancel) and action == "Block" then send("Block", false) end
        return Enum.ContextActionResult.Sink
    end, false, table.unpack(keys))
end
for action, button in pairs(abilityButtons) do
    if action == "Block" then
        button.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then send("Block", true) end
        end)
        button.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then send("Block", false) end
        end)
    else button.Activated:Connect(function() send(action) end) end
end
UserInputService.InputBegan:Connect(function(input, processed)
    if processed then return end
    heldKeys[input.KeyCode] = true
    if input.KeyCode == Enum.KeyCode.One then actionRemote:FireServer("SelectCharacter", {hero = "Naruto"})
    elseif input.KeyCode == Enum.KeyCode.Two then actionRemote:FireServer("SelectCharacter", {hero = "Luffy"})
    elseif input.KeyCode == Enum.KeyCode.Three then actionRemote:FireServer("SelectCharacter", {hero = "Tanjiro"})
    elseif input.KeyCode == Enum.KeyCode.R and ending.Visible then actionRemote:FireServer("Restart", {})
    elseif input.KeyCode == Enum.KeyCode.DPadRight or input.KeyCode == Enum.KeyCode.DPadLeft then
        local current = table.find(HEROES, snapshot.hero) or 1
        local offset = input.KeyCode == Enum.KeyCode.DPadRight and 1 or -1
        actionRemote:FireServer("SelectCharacter", {hero = HEROES[(current - 1 + offset) % #HEROES + 1]})
    elseif input.KeyCode == Enum.KeyCode.ButtonStart and ending.Visible then actionRemote:FireServer("Restart", {}) end
end)
UserInputService.InputEnded:Connect(function(input) heldKeys[input.KeyCode] = nil end)
UserInputService.InputChanged:Connect(function(input)
    if input.KeyCode == Enum.KeyCode.Thumbstick1 then gamepadMove = Vector2.new(input.Position.X, -input.Position.Y) end
end)
UserInputService.WindowFocusReleased:Connect(function()
    heldKeys = {}; gamepadMove = Vector2.zero; touchMove = Vector2.zero; localBlocking = false
    actionRemote:FireServer("Block", {held = false})
end)

local touchPad = make("Frame", {Visible = UserInputService.TouchEnabled, Active = true,
    BackgroundColor3 = COLORS.panel, BackgroundTransparency = 0.3, Position = UDim2.new(0, 25, 1, -280), Size = UDim2.fromOffset(116, 116)}, canvas)
round(touchPad, 58); outline(touchPad, COLORS.cyan)
local touchKnob = make("Frame", {BackgroundColor3 = COLORS.cyan, BackgroundTransparency = 0.28,
    AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(42, 42)}, touchPad)
round(touchKnob, 21)
local touchInput: InputObject? = nil
local function updateTouch(input: InputObject)
    local point = Vector2.new(input.Position.X, input.Position.Y)
    local delta = (point - (touchPad.AbsolutePosition + touchPad.AbsoluteSize / 2)) / 42
    if delta.Magnitude > 1 then delta = delta.Unit end
    touchMove = delta; touchKnob.Position = UDim2.new(0.5, delta.X * 34, 0.5, delta.Y * 34)
end
touchPad.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Touch then touchInput = input; updateTouch(input) end
end)
UserInputService.InputChanged:Connect(function(input) if input == touchInput then updateTouch(input) end end)
UserInputService.InputEnded:Connect(function(input)
    if input == touchInput then touchInput = nil; touchMove = Vector2.zero; touchKnob.Position = UDim2.fromScale(0.5, 0.5) end
end)
local touchJump = make("TextButton", {Visible = UserInputService.TouchEnabled, Text = "JUMP", Font = Enum.Font.GothamBold,
    TextSize = 12, TextColor3 = COLORS.text, BackgroundColor3 = COLORS.panel,
    AnchorPoint = Vector2.new(1, 1), Position = UDim2.new(1, -30, 1, -123), Size = UDim2.fromOffset(70, 58)}, canvas)
round(touchJump, 14); outline(touchJump, COLORS.cyan)
touchJump.Activated:Connect(function() send("Jump") end)

local function particlePart(position: Vector3, color: Color3, size: Vector3): BasePart
    return make("Part", {Anchored = true, CanCollide = false, CanTouch = false, CanQuery = false,
        CastShadow = false, Material = Enum.Material.Neon, Color = color, Size = size,
        Position = position, Transparency = 0.1}, effectsFolder)
end
local function burst(position: Vector3, color: Color3, heavy: boolean, direction: number)
    if activeEffects >= 24 then return end
    activeEffects += 1
    task.delay(0.65, function() activeEffects -= 1 end)
    local ring = particlePart(position, color, Vector3.new(0.12, 1, 1))
    ring.Shape = Enum.PartType.Cylinder
    ring.CFrame = CFrame.new(position) * CFrame.Angles(0, 0, math.rad(90))
    local scale = heavy and 12 or 6
    TweenService:Create(ring, TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
        {Size = Vector3.new(0.04, scale, scale), Transparency = 1}):Play()
    Debris:AddItem(ring, 0.4)
    for index = 1, (heavy and 9 or 5) do
        local angle = index * math.pi * 2 / (heavy and 9 or 5)
        local offset = Vector3.new(math.cos(angle) * 4 * direction, math.sin(angle) * 3, math.sin(angle * 2) * 1.3)
        local streak = particlePart(position, color, Vector3.new(0.16, 0.16, heavy and 2 or 1))
        streak.CFrame = CFrame.lookAt(position, position + offset)
        TweenService:Create(streak, TweenInfo.new(0.23), {Position = position + offset, Transparency = 1}):Play()
        Debris:AddItem(streak, 0.3)
    end
end
-- Distinct cosmetic specials. Every piece is anchored/non-queryable and has bounded lifetime.
-- A single temporary render connection animates up to eight overlapping specials.
local specialEffects: {any} = {}
local specialConnection: RBXScriptConnection? = nil
local function startSpecial(position: Vector3, hero: string, direction: number): boolean
    if #specialEffects >= 8 or activeEffects >= 24 then return false end
    if hero ~= "Naruto" and hero ~= "Luffy" and hero ~= "Tanjiro" then return false end
    direction = direction >= 0 and 1 or -1
    local windup, reach = 0.22, 15
    if hero == "Luffy" then windup, reach = 0.38, 23
    elseif hero == "Tanjiro" then windup, reach = 0.18, 12 end
    -- Match current balancing without making imported visual code part of damage execution.
    local shared = package:FindFirstChild("Shared")
    local configModule = shared and shared:FindFirstChild("Config")
    if configModule and configModule:IsA("ModuleScript") then
        local ok, config = pcall(require, configModule)
        local spec = ok and config.Characters and config.Characters[hero]
        if spec then windup = spec.Special.Windup; reach = spec.Special.Range end
    end
    local holder = Instance.new("Folder")
    holder.Name = hero .. "Special"
    holder.Parent = effectsFolder
    local lifetime = windup + 0.62
    Debris:AddItem(holder, lifetime + 0.1)
    activeEffects += 1
    local origin = position + Vector3.new(0, 0.65, 1.25)
    local function piece(color: Color3, size: Vector3, shape: Enum.PartType?): BasePart
        local part = particlePart(origin, color, size)
        if shape then part.Shape = shape end
        part.Parent = holder
        return part
    end
    local function trail(part: BasePart, color: Color3, width: number, duration: number)
        local a = make("Attachment", {Position = Vector3.new(0, width * 0.5, 0)}, part)
        local b = make("Attachment", {Position = Vector3.new(0, -width * 0.5, 0)}, part)
        make("Trail", {Attachment0 = a, Attachment1 = b, Color = ColorSequence.new(color, COLORS.text),
            Lifetime = duration, MinLength = 0.04, LightEmission = 1, FaceCamera = true,
            Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 0.12), NumberSequenceKeypoint.new(1, 1)})}, part)
    end
    local update: (number) -> ()
    if hero == "Naruto" then
        local core = piece(Color3.fromRGB(212, 252, 255), Vector3.one * 0.5, Enum.PartType.Ball)
        local shell = piece(Color3.fromRGB(58, 200, 255), Vector3.one * 0.8, Enum.PartType.Ball)
        shell.Transparency = 0.65
        local satellites = {}
        for index = 1, 4 do
            local dot = piece(COLORS.cyan, Vector3.one * 0.18, Enum.PartType.Ball)
            trail(dot, Color3.fromRGB(69, 213, 255), 0.2, 0.2)
            satellites[index] = dot
        end
        trail(core, Color3.fromRGB(118, 231, 255), 1.2, 0.13)
        update = function(t)
            local charging = math.clamp(t / windup, 0, 1)
            local strike = math.clamp((t - windup) / 0.13, 0, 1)
            local fade = math.clamp((t - windup - 0.2) / 0.35, 0, 1)
            local center = origin + Vector3.new(direction * (2.4 + reach * strike), 0.2, 0)
            local radius = 0.3 + charging * 1.1 + strike * 0.45
            core.Position = center; core.Size = Vector3.one * radius * 1.1; core.Transparency = fade
            shell.Position = center; shell.Size = Vector3.one * radius * 2.15; shell.Transparency = 0.65 + fade * 0.35
            for index, dot in ipairs(satellites) do
                local theta = t * 31 + index * math.pi * 0.5
                dot.Position = center + Vector3.new(math.sin(theta * 0.5) * radius * 0.45, math.cos(theta) * radius, math.sin(theta) * radius)
                dot.Transparency = fade
            end
        end
    elseif hero == "Luffy" then
        local skin = Color3.fromRGB(242, 181, 137)
        local fist = piece(skin, Vector3.new(1.65, 1.55, 1.5), Enum.PartType.Ball)
        fist.Material = Enum.Material.SmoothPlastic
        local arm = piece(skin, Vector3.new(0.75, 0.75, 1))
        arm.Material = Enum.Material.SmoothPlastic
        local cuff = piece(Color3.fromRGB(226, 53, 64), Vector3.new(1.0, 1.0, 0.7))
        local speedLines = {}
        for index = 1, 4 do speedLines[index] = piece(Color3.fromRGB(255, 236, 201), Vector3.new(0.08, 0.08, 1)) end
        trail(fist, COLORS.orange, 0.8, 0.09)
        update = function(t)
            local charge = math.clamp(t / windup, 0, 1)
            local strikeAge = t - windup
            local extension = math.clamp(strikeAge / 0.085, 0, 1)
            local recoil = math.clamp((strikeAge - 0.13) / 0.2, 0, 1)
            local fade = math.clamp((strikeAge - 0.29) / 0.18, 0, 1)
            local shoulder = origin + Vector3.new(direction * 0.75, 0, 0)
            local distance = strikeAge < 0 and (1.5 - charge * 2.6) or (1.5 + (reach - 1.5) * extension * (1 - recoil))
            local endpoint = shoulder + Vector3.new(direction * distance, 0.16 + math.sin(charge * math.pi) * 0.2, 0)
            fist.Position = endpoint; fist.Transparency = fade
            fist.Size = Vector3.one * (1.5 + extension * (1 - recoil) * 0.75)
            local length = math.max(0.1, (endpoint - shoulder).Magnitude)
            arm.Size = Vector3.new(0.63, 0.63, length)
            arm.CFrame = CFrame.lookAt((shoulder + endpoint) / 2, endpoint)
            arm.Transparency = fade
            cuff.CFrame = CFrame.lookAt(endpoint - Vector3.new(direction * 0.8, 0, 0), endpoint)
            cuff.Transparency = fade
            for index, line in ipairs(speedLines) do
                local offset = Vector3.new(0, (index - 2.5) * 0.55, 0.6)
                line.Size = Vector3.new(0.06, 0.06, math.max(0.1, length * 0.6))
                line.CFrame = CFrame.lookAt((shoulder + endpoint) / 2 + offset, endpoint + offset)
                line.Transparency = strikeAge >= 0 and math.clamp(0.4 + recoil * 0.6, 0, 1) or 1
            end
        end
    else
        local blade = piece(Color3.fromRGB(210, 255, 252), Vector3.new(0.13, 3.8, 0.16))
        trail(blade, Color3.fromRGB(68, 228, 221), 0.8, 0.17)
        local water, foam = {}, {}
        for index = 1, 16 do
            water[index] = piece(Color3.fromRGB(31, 195, 206), Vector3.new(0.3, 0.45, 1))
            foam[index] = piece(Color3.fromRGB(213, 255, 251), Vector3.new(0.09, 0.11, 1))
        end
        update = function(t)
            local charge = math.clamp(t / windup, 0, 1)
            local sweep = math.clamp((t - windup) / 0.17, 0, 1)
            local fade = math.clamp((t - windup - 0.16) / 0.36, 0, 1)
            local bladeAngle = math.rad(-40 + charge * 55 + sweep * 165)
            blade.CFrame = CFrame.new(origin + Vector3.new(direction * (1.6 + sweep * 2), 0.8, 0)) * CFrame.Angles(0, 0, direction * bladeAngle)
            blade.Transparency = fade
            for index = 1, 16 do
                local fraction = (index - 1) / 16
                local theta0 = math.rad(-75 + fraction * 150)
                local theta1 = math.rad(-75 + (index / 16) * 150)
                local radius = 1.2 + reach * sweep
                local a = origin + Vector3.new(direction * math.cos(theta0) * radius, math.sin(theta0) * (2.1 + sweep * 1.0), math.sin(theta0) * sweep * 4)
                local b = origin + Vector3.new(direction * math.cos(theta1) * radius, math.sin(theta1) * (2.1 + sweep * 1.0), math.sin(theta1) * sweep * 4)
                local edge = water[index]
                edge.Size = Vector3.new(0.3 + sweep * 0.3, 0.42, math.max(0.1, (b - a).Magnitude + 0.12))
                edge.CFrame = CFrame.lookAt((a + b) / 2, b)
                edge.Transparency = (t < windup or fraction > sweep) and 1 or math.clamp(0.2 + fade * 0.8, 0, 1)
                local white = foam[index]
                white.Size = Vector3.new(0.1, 0.12, math.max(0.1, (b - a).Magnitude))
                white.CFrame = edge.CFrame + Vector3.new(0, 0.23, 0.12)
                white.Transparency = edge.Transparency
            end
        end
    end
    table.insert(specialEffects, {start = os.clock(), duration = lifetime, windup = windup, position = position, struck = false, holder = holder, update = update})
    if not specialConnection then
        specialConnection = RunService.RenderStepped:Connect(function()
            local now = os.clock()
            for index = #specialEffects, 1, -1 do
                local effect = specialEffects[index]
                local age = now - effect.start
                if age >= effect.windup and not effect.struck then
                    effect.struck = true
                    combatSound("Attack", effect.position)
                    if root and (root.Position - effect.position).Magnitude < 65 then cameraKick = math.max(cameraKick, 0.68) end
                end
                if age >= effect.duration or not effect.holder.Parent then
                    effect.holder:Destroy(); table.remove(specialEffects, index); activeEffects -= 1
                else effect.update(age) end
            end
            if #specialEffects == 0 and specialConnection then specialConnection:Disconnect(); specialConnection = nil end
        end)
    end
    return true
end
local function importedEffect(kind: string, position: Vector3): boolean
    local template = asset("VFX", kind)
    if not template or activeEffects >= 24 then return false end
    local effect = template:Clone()
    for _, item in ipairs(effect:GetDescendants()) do
        if item:IsA("LuaSourceContainer") then item:Destroy() end
    end
    if effect:IsA("LuaSourceContainer") then effect:Destroy(); return false end
    local holder: Instance = effect
    if effect:IsA("Model") then effect:PivotTo(CFrame.new(position)); effect.Parent = effectsFolder
    elseif effect:IsA("BasePart") then effect.CFrame = CFrame.new(position); effect.Parent = effectsFolder
    elseif effect:IsA("Attachment") or effect:IsA("ParticleEmitter") then
        local base = particlePart(position, COLORS.cyan, Vector3.one * 0.1); base.Transparency = 1
        effect.Parent = base; holder = base
    else effect:Destroy(); return false end
    for _, item in ipairs(holder:GetDescendants()) do
        if item:IsA("BasePart") then item.Anchored = true; item.CanCollide = false; item.CanTouch = false; item.CanQuery = false end
        if item:IsA("ParticleEmitter") then item.Enabled = false; item:Emit(math.clamp(item:GetAttribute("BurstCount") or item:GetAttribute("EmitCount") or 16, 1, 60)) end
    end
    if effect:IsA("BasePart") then effect.Anchored = true; effect.CanCollide = false; effect.CanTouch = false; effect.CanQuery = false end
    activeEffects += 1
    task.delay(3, function() activeEffects -= 1 end)
    Debris:AddItem(holder, 3)
    return true
end
local function damageNumber(position: Vector3, amount: number, heavy: boolean)
    local anchor = particlePart(position, COLORS.text, Vector3.one * 0.1); anchor.Transparency = 1
    local billboard = make("BillboardGui", {Size = UDim2.fromOffset(100, 45), AlwaysOnTop = true, StudsOffset = Vector3.new(0, 2, 0)}, anchor)
    local number = label(billboard, "+" .. tostring(math.floor(amount)) .. "%", heavy and 27 or 21,
        heavy and COLORS.orange or COLORS.text, UDim2.fromScale(0, 0), UDim2.fromScale(1, 1))
    number.TextXAlignment = Enum.TextXAlignment.Center; number.TextStrokeTransparency = 0.35
    TweenService:Create(billboard, TweenInfo.new(0.6), {StudsOffset = Vector3.new(0, 4.5, 0)}):Play()
    TweenService:Create(number, TweenInfo.new(0.6), {TextTransparency = 1, TextStrokeTransparency = 1}):Play()
    Debris:AddItem(anchor, 0.65)
end
local function registerActor(model: Model): any
    if actorPoses[model] then return actorPoses[model] end
    local actorHumanoid = model:FindFirstChildOfClass("Humanoid")
    if not actorHumanoid then return nil end
    local joints = {}
    for _, child in ipairs(model:GetDescendants()) do
        if child:IsA("Motor6D") and child.Part1 then joints[child] = child.C0 end
    end
    local actor = {humanoid = actorHumanoid, joints = joints, start = 0, action = nil}
    actorPoses[model] = actor
    return actor
end
fxRemote.OnClientEvent:Connect(function(event: any)
    if type(event) ~= "table" then return end
    local kind = event.kind
    if kind == "Attack" or kind == "Dash" then
        local action = kind == "Dash" and "Dash" or event.action
        if action == "Special" or action == "Slam" then action = "Heavy" end
        if action == "Light" and (event.combo or 1) % 2 == 0 then action = "Light2" end
        if event.playerUserId == player.UserId then
            animate(action or "Light")
        else
            local model: Model? = nil
            if event.playerUserId then
                local owner = Players:GetPlayerByUserId(event.playerUserId)
                model = owner and owner.Character
            elseif event.enemy and typeof(event.position) == "Vector3" then
                local folder = workspace:FindFirstChild("Enemies")
                local closest = 8
                if folder then
                    for _, candidate in ipairs(folder:GetChildren()) do
                        local candidateRoot = candidate:FindFirstChild("HumanoidRootPart")
                        if candidate:IsA("Model") and candidateRoot and candidateRoot:IsA("BasePart") then
                            local distance = (candidateRoot.Position - event.position).Magnitude
                            if distance < closest then closest = distance; model = candidate end
                        end
                    end
                end
            end
            if model then
                local actor = registerActor(model)
                if actor then actor.action = action; actor.start = os.clock() end
            end
        end
    end
    if kind == "Wave" then toast("CURSES INCOMING", COLORS.red)
    elseif kind == "StageClear" then toast("CURTAIN OPEN  /  MOVE RIGHT →", COLORS.cyan)
    elseif kind == "Victory" then toast("THE CURTAIN IS BROKEN", COLORS.cyan) end
    if typeof(event.position) ~= "Vector3" then return end
    local position = event.position
    local distinctSpecial = kind == "Attack" and event.action == "Special"
    if distinctSpecial then distinctSpecial = startSpecial(position, event.hero, tonumber(event.direction) or 1) end
    if not distinctSpecial and (kind == "Hit" or kind == "Attack" or kind == "Dash") then combatSound(kind, position) end
    local color = HERO_COLORS[event.hero] or (event.enemy and COLORS.red or COLORS.cyan)
    if kind == "BossPhase" then
        toast("SIGNAL EATER / OVERLOAD", COLORS.red)
        burst(position, COLORS.red, true, 1)
        cameraKick = math.max(cameraKick, 0.9)
    elseif kind == "GuardBreak" then
        toast("GUARD BROKEN", COLORS.orange)
        burst(position, COLORS.orange, true, 1)
    elseif kind == "Telegraph" then
        local radius = math.clamp(tonumber(event.radius) or 6, 2, 30)
        local duration = math.clamp(tonumber(event.duration) or 0.6, 0.15, 4)
        local direction = tonumber(event.direction) or 1
        local warning = particlePart(Vector3.new(position.X + (event.heavy and 0 or direction * radius * 0.5), 0.16, position.Z), COLORS.red,
            Vector3.new(event.heavy and radius * 2 or radius, 0.06, event.heavy and 25 or 7))
        warning.Transparency = 0.72
        TweenService:Create(warning, TweenInfo.new(duration), {Transparency = 0.22}):Play()
        Debris:AddItem(warning, duration + 0.05)
    end
    local heavy = event.heavy == true or event.action == "Heavy" or event.action == "Special" or kind == "KO"
    if kind == "Hit" or kind == "KO" or kind == "Attack" or kind == "Special" or kind == "Dash" or kind == "Recovery" then
        if not distinctSpecial and not importedEffect(kind, position) then burst(position, color, heavy, tonumber(event.direction) or 1) end
        if not distinctSpecial and root and (root.Position - position).Magnitude < 65 then cameraKick = math.max(cameraKick, heavy and 0.75 or 0.24) end
    end
    if kind == "Hit" and type(event.damage) == "number" and activeEffects < 24 then damageNumber(position, event.damage, heavy) end
end)

local previousStatus = ""
stateRemote.OnClientEvent:Connect(function(state: any)
    if type(state) ~= "table" then return end
    if state.kind == "Toast" or state.kind == "Message" then toast(state.text or state.message or ""); return end
    for key, value in pairs(state) do snapshot[key] = value end
    local hero = snapshot.hero
    local color = HERO_COLORS[hero] or COLORS.cyan
    heroLabel.Text = string.upper(hero); heroLabel.TextColor3 = color
    local percent = math.floor(snapshot.percent or 0)
    percentLabel.Text = tostring(percent) .. "%"
    percentLabel.TextColor3 = percent >= 100 and COLORS.red or (percent >= 60 and COLORS.orange or COLORS.text)
    local stocks = math.clamp(math.floor(snapshot.stocks or 0), 0, 9)
    stocksLabel.Text = stocks > 0 and string.rep("● ", stocks) or "OUT"
    damageHint.Text = snapshot.downed and "WAITING FOR YOUR TEAM" or (snapshot.blocking and "GUARDING / WATCH YOUR BACK" or "HIGHER % = BIGGER LAUNCH")
    chapterLabel.Text = string.format("%02d / %s", snapshot.stage or 1, string.upper(snapshot.stageName or "VEIL OVER THE CITY"))
    waveLabel.Text = string.format("WAVE %d / %d  ·  CO-OP", snapshot.wave or 0, snapshot.waves or 3)
    enemyLabel.Text = tostring(snapshot.enemiesRemaining or 0) .. " CURSES REMAIN"
    local total = math.max(1, snapshot.waves or 3)
    local progress = math.clamp(((snapshot.stage or 1) - 1) / 3 + (snapshot.wave or 0) / total / 3, 0, 1)
    TweenService:Create(progressFill, TweenInfo.new(0.3), {Size = UDim2.fromScale(progress, 1)}):Play()
    moveName.Text = HERO_MOVES[hero] or "SPECIAL"
    for name, button in pairs(heroButtons) do button.BackgroundTransparency = name == hero and 0 or 0.65 end
    local status = snapshot.status
    objectiveLabel.Text = (status == "StageClear" or status == "Advance") and "MOVE RIGHT / RALLY AT EXIT →" or (status == "Intermission" and "BREATHE / NEXT WAVE APPROACHING" or "Clear the wave to open the curtain")
    ending.Visible = status == "Defeat" or status == "Victory"
    if ending.Visible then
        endingTitle.Text = status == "Victory" and "CURTAIN BROKEN" or "THE CITY GOES DARK"
        endingTitle.TextColor3 = status == "Victory" and COLORS.cyan or COLORS.red
        endingDetail.Text = status == "Victory" and "Three districts reclaimed. Your squad made it through."
            or "Your squad ran out of stocks. Guard, recover, and stay together on the next run."
    elseif status ~= previousStatus and (status == "StageClear" or status == "Advance") then toast("DISTRICT CLEARED  /  ADVANCE →", COLORS.cyan) end
    if status == "Intermission" and previousStatus ~= status then toast("WAVE CLEARED / REGROUP", COLORS.cyan) end
    previousStatus = status
end)

local renderAccum = 0
local partyAccum = 0
local cameraTarget = Vector3.new(60, 5, 0)
local cameraDistance = 52
-- Sample original imported R6 KeyframeSequence data cosmetically; damage stays server-owned.
local function applyToolboxPose(joints: any, data: any, time: number, dt: number)
    if not data or not data.frames or #data.frames == 0 then return end
    local frames = data.frames
    local before, after = frames[1], frames[#frames]
    for index = 1, #frames - 1 do
        if time >= frames[index].time and time <= frames[index + 1].time then before = frames[index]; after = frames[index + 1]; break end
    end
    local alpha = math.clamp((time - before.time) / math.max(0.0001, after.time - before.time), 0, 1)
    for joint, neutral in pairs(joints) do
        if joint.Parent and joint.Part1 then
            local bodyName = joint.Part1.Name
            local from = before.poses[bodyName] or CFrame.identity
            local to = after.poses[bodyName] or from
            joint.C0 = joint.C0:Lerp(neutral * from:Lerp(to, alpha), math.min(1, dt * 24))
            joint.Transform = CFrame.identity
        end
    end
end
local function sampleToolbox(dt: number)
    if not toolboxData then return end
    local now = os.clock()
    if humanoid and humanoid.RigType == Enum.HumanoidRigType.R6 then
        local chosen = poseAction
        local data = chosen and toolboxData[chosen]
        if data and now - poseStart > math.max(0.05, data.duration) then poseAction = nil; chosen = nil; data = nil end
        if localBlocking and snapshot.blocking then chosen = "Block"; data = toolboxData.Block end
        local actionPose = data ~= nil
        if not data then
            chosen = humanoid.MoveDirection.Magnitude > 0.1 and "Walk" or "Idle"
            data = toolboxData[chosen]
        end
        if data then
            local duration = math.max(0.05, data.duration)
            local time = actionPose and math.clamp(now - poseStart, 0, duration) or (now - locomotionStart) % duration
            applyToolboxPose(rigJoints, data, time, dt)
        end
    end
    for model, actor in pairs(actorPoses) do
        if not model.Parent or actor.humanoid.Health <= 0 then actorPoses[model] = nil
        else
            local data = actor.action and toolboxData[actor.action]
            if data and now - actor.start > math.max(0.05, data.duration) then actor.action = nil; data = nil end
            local actionPose = data ~= nil
            if not data then
                local actorRoot = model:FindFirstChild("HumanoidRootPart")
                local moving = actorRoot and actorRoot:IsA("BasePart") and Vector3.new(actorRoot.AssemblyLinearVelocity.X, 0, actorRoot.AssemblyLinearVelocity.Z).Magnitude > 2
                data = toolboxData[moving and "Walk" or "Idle"]
            end
            if data then
                local duration = math.max(0.05, data.duration)
                applyToolboxPose(actor.joints, data, actionPose and math.clamp(now - actor.start, 0, duration) or now % duration, dt)
            end
        end
    end
end
RunService.PreSimulation:Connect(sampleToolbox)
RunService:BindToRenderStep("NightfallPresentation", Enum.RenderPriority.Camera.Value + 1, function(dt)
    local camera = workspace.CurrentCamera
    if not camera then return end
    if humanoid and root and humanoid.Health > 0 then
        local keyboard = Vector2.new((heldKeys[Enum.KeyCode.D] and 1 or 0) - (heldKeys[Enum.KeyCode.A] and 1 or 0),
            (heldKeys[Enum.KeyCode.S] and 1 or 0) - (heldKeys[Enum.KeyCode.W] and 1 or 0))
        local movement = keyboard + (gamepadMove.Magnitude > 0.15 and gamepadMove or Vector2.zero) + touchMove
        if movement.Magnitude > 1 then movement = movement.Unit end
        if UserInputService:GetFocusedTextBox() or ending.Visible then movement = Vector2.zero end
        if math.abs(movement.X) > 0.1 then facing = movement.X > 0 and 1 or -1 end
        humanoid:Move(Vector3.new(movement.X, 0, movement.Y * 0.7), false)
    end
    partyAccum += dt
    if partyAccum > 0.1 then
        partyAccum = 0
        for _, teammate in ipairs(Players:GetPlayers()) do
            if teammate ~= player and teammate.Character then registerActor(teammate.Character) end
        end
        local enemiesFolder = workspace:FindFirstChild("Enemies")
        if enemiesFolder then
            for _, enemy in ipairs(enemiesFolder:GetChildren()) do if enemy:IsA("Model") then registerActor(enemy) end end
        end
        local localX = root and root.Position.X or 60
        local minX, maxX = localX, localX
        for _, teammate in ipairs(Players:GetPlayers()) do
            local character = teammate.Character
            local teammateRoot = character and character:FindFirstChild("HumanoidRootPart")
            local teammateHumanoid = character and character:FindFirstChildOfClass("Humanoid")
            if teammateRoot and teammateRoot:IsA("BasePart") and teammateHumanoid and teammateHumanoid.Health > 0
                and math.abs(teammateRoot.Position.X - localX) < 170 then
                minX = math.min(minX, teammateRoot.Position.X); maxX = math.max(maxX, teammateRoot.Position.X)
            end
        end
        local stageStart = ((snapshot.stage or 1) - 1) * 180
        local midpoint = math.clamp((minX + maxX) / 2, stageStart + 38, stageStart + 142)
        cameraTarget = Vector3.new(midpoint, 5, 0)
        local aspect = camera.ViewportSize.X / math.max(1, camera.ViewportSize.Y)
        cameraDistance = math.clamp((maxX - minX + 54) / (2 * math.tan(math.rad(22)) * aspect), 52, 140)
    end
    camera.CameraType = Enum.CameraType.Scriptable; camera.FieldOfView = 44
    local goalPosition = cameraTarget + Vector3.new(0, cameraDistance * 0.37, cameraDistance)
    cameraPosition = cameraPosition and cameraPosition:Lerp(goalPosition, 1 - math.exp(-6 * dt)) or goalPosition
    cameraKick = math.max(0, cameraKick - dt * 3)
    local shake = Vector3.new(math.noise(os.clock() * 28, 0), math.noise(0, os.clock() * 28), 0) * cameraKick
    camera.CFrame = CFrame.lookAt(cameraPosition + shake, cameraTarget + shake)
    renderAccum += dt
    if renderAccum > 0.1 then
        renderAccum = 0
        local now = workspace:GetServerTimeNow()
        for name, text in pairs(abilityLabels) do
            local finish = (snapshot.cooldowns or {})[name]
            local remaining = type(finish) == "number" and math.max(0, finish - now) or 0
            text.Text = remaining > 0 and string.format("%.1fs", remaining) or string.upper(name)
            text.TextColor3 = remaining > 0 and COLORS.muted or COLORS.text
        end
    end
end)
if workspace.CurrentCamera then workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(resize) end
workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
    if workspace.CurrentCamera then workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(resize) end
    resize()
end)
resize()
toast("STAY TOGETHER. BREAK THE CURTAIN.", COLORS.cyan)
