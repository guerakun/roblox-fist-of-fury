--!strict
-- Nightfall client: input, presentation, and camera only. Damage stays on the server.
local RescueTouchLayout = require(script.Parent:WaitForChild("RescueTouchLayout"))
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
local Config = require(package:WaitForChild("Shared"):WaitForChild("Config"))
local HeroSpecials = require(script.Parent:WaitForChild("HeroSpecials"))
local EnemyPresentation = require(script.Parent:WaitForChild("EnemyPresentation"))
local FocusGuard = require(script.Parent:WaitForChild("FocusGuard"))
local ActionCapabilities = require(script.Parent:WaitForChild("ActionCapabilities"))
local DesperationControl = require(script.Parent:WaitForChild("DesperationControl"))
local DesperationHUD = require(script.Parent:WaitForChild("DesperationHUD"))
local riskFeedback = require(script.Parent:WaitForChild("RiskFeedback")).new({player=player,colors=COLORS})
local HEROES = Config.CharacterOrder
local HERO_COLORS, HERO_MOVES = {}, {}
for _, id in ipairs(HEROES) do
    HERO_COLORS[id] = Config.Characters[id].Color
    HERO_MOVES[id] = Config.Characters[id].SpecialName
end
local snapshot: any = {hero = "Gale", percent = 0, stocks = 3, stage = 1, wave = 0,
    waves = 3, enemiesRemaining = 0, status = "Waiting", cooldowns = {}}
local facing = 1
local humanoid: Humanoid? = nil
local root: BasePart? = nil
local cameraKick = 0
local cameraCenter: Vector3? = nil
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
local desperationControl: any = nil
local desperationHUD: any = nil
local desperationHintActive = false
local localBlocking = false
local touchInput: InputObject? = nil
local blockInput: InputObject? = nil
local touchKnob: Frame? = nil
local locomotionStart = os.clock()
local tracks: {[string]: AnimationTrack} = {}
local activeEffects = 0
local actorPoses: {[Model]: any} = {}
local activeSounds = 0
local lastHitSound = 0
local preferences = {shake = 0.65, effects = 1, volume = 0.8, ambience = 0.65, music = 0.6, highContrast = false}
local bossEffects = require(script.Parent:WaitForChild("BossEffects")).new(preferences)
local hitPoseHoldUntil = 0
local touchPad: Frame? = nil
local touchJump: TextButton? = nil
local stageAudio = require(script.Parent:WaitForChild("StageAudio")).new(preferences)
stageAudio.Update(snapshot)
local function releaseBlock()
    localBlocking = false
    blockInput = nil
    actionRemote:FireServer("Block", {held = false})
end
local actionCapabilities = ActionCapabilities.new(releaseBlock)
local focusGuard = FocusGuard.new({input = UserInputService, player = player, releaseBlock = releaseBlock,
    clearHeld = function()
        heldKeys = {}; gamepadMove = Vector2.zero; touchMove = Vector2.zero; touchInput = nil
        if desperationControl then desperationControl:Reset() end
        if touchKnob then touchKnob.Position = UDim2.fromScale(.5, .5) end
    end})
local function combatSound(kind: string, position: Vector3)
    local now = os.clock()
    if preferences.volume <= 0 or activeSounds >= 8 or (kind == "Hit" and now - lastHitSound < 0.07) then return end
    if kind == "Hit" then lastHitSound = now end
    local anchor = Instance.new("Part")
    anchor.Anchored = true; anchor.CanCollide = false; anchor.CanTouch = false; anchor.CanQuery = false
    anchor.Transparency = 1; anchor.Size = Vector3.one * 0.1; anchor.Position = position; anchor.Parent = workspace
    local sound = Instance.new("Sound")
    sound.SoundId = kind == "Hit" and "rbxassetid://132504023010884" or "rbxassetid://135315310485417"
    sound.Volume = (kind == "Hit" and 0.33 or 0.17) * preferences.volume
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
local enemyPresentation = EnemyPresentation.new(effectsFolder, preferences)

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
gui.ScreenInsets = Enum.ScreenInsets.CoreUISafeInsets
local canvas = make("Frame", {Name = "Canvas", BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1)}, gui)
local top = make("Frame", {BackgroundColor3 = COLORS.ink, BackgroundTransparency = 0.08,
    Position = UDim2.fromOffset(22, 16), Size = UDim2.fromOffset(342, 108)}, canvas)
round(top, 10); outline(top, COLORS.cyan)
local titleLabel = label(top, "CURTAIN BREAK", 25, COLORS.text, UDim2.fromOffset(16, 9), UDim2.fromOffset(312, 30))
local brandLabel = label(top, "F I S T   O F   F U R Y", 10, COLORS.cyan, UDim2.fromOffset(17, 39), UDim2.fromOffset(312, 16))
local chapterLabel = label(top, "01 / VEIL OVER THE CITY", 12, COLORS.muted, UDim2.fromOffset(17, 69), UDim2.fromOffset(310, 18))
local progressBack = make("Frame", {BackgroundColor3 = COLORS.panel, BorderSizePixel = 0,
    Position = UDim2.fromOffset(17, 94), Size = UDim2.fromOffset(308, 3)}, top)
local progressFill = make("Frame", {BackgroundColor3 = COLORS.cyan, BorderSizePixel = 0,
    Size = UDim2.fromScale(0, 1)}, progressBack)
local encounter = make("Frame", {BackgroundColor3 = COLORS.ink, BackgroundTransparency = 0.08,
    AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -22, 0, 16), Size = UDim2.fromOffset(245, 85)}, canvas)
round(encounter, 10); outline(encounter, COLORS.muted)
local waveLabel = label(encounter, "CO-OP / 1–4 PLAYERS", 11, COLORS.cyan, UDim2.fromOffset(16, 10), UDim2.fromOffset(215, 21))
local enemyLabel = label(encounter, "ENTER THE CURTAIN", 20, COLORS.text, UDim2.fromOffset(16, 34), UDim2.fromOffset(215, 26))
local objectiveLabel = label(encounter, "Clear each arena. Keep moving →", 10, COLORS.muted, UDim2.fromOffset(16, 63), UDim2.fromOffset(220, 15))

local playerPanel = make("Frame", {BackgroundColor3 = COLORS.ink, BackgroundTransparency = 0.05,
    Position = UDim2.new(0, 22, 1, -174), Size = UDim2.fromOffset(280, 151)}, canvas)
round(playerPanel, 10); outline(playerPanel, COLORS.orange)
local heroLabel = label(playerPanel, string.upper(Config.Characters[HEROES[1]].Name), 17, HERO_COLORS[HEROES[1]], UDim2.fromOffset(15, 10), UDim2.fromOffset(245, 22))
local percentLabel = label(playerPanel, "0%", 46, COLORS.text, UDim2.fromOffset(14, 32), UDim2.fromOffset(170, 55))
local stocksLabel = label(playerPanel, "● ● ●", 19, COLORS.cyan, UDim2.fromOffset(180, 47), UDim2.fromOffset(86, 28))
local damageHint = label(playerPanel, "HIGHER % = BIGGER LAUNCH", 9, COLORS.muted, UDim2.fromOffset(16, 85), UDim2.fromOffset(249, 15))
local heroButtons: {[string]: TextButton} = {}
for index, hero in ipairs(HEROES) do
    local button = make("TextButton", {Name = hero, Text = tostring(index) .. "  " .. string.upper(Config.Characters[hero].Name),
        TextScaled = true, TextWrapped = true, TextColor3 = HERO_COLORS[hero], TextSize = 10, Font = Enum.Font.GothamBold,
        AutoButtonColor = true, BackgroundColor3 = COLORS.panel, BorderSizePixel = 0,
        Position = UDim2.fromOffset(12 + (index - 1) * 87, 110), Size = UDim2.fromOffset(82, 29)}, playerPanel)
    round(button, 5); heroButtons[hero] = button
    button.Activated:Connect(function() actionRemote:FireServer("SelectCharacter", {hero = hero}) end)
end
local abilities = make("Frame", {BackgroundTransparency = 1, AnchorPoint = Vector2.new(1, 1),
    Position = UDim2.new(1, -22, 1, -23), Size = UDim2.fromOffset(468, 78)}, canvas)
local abilityLabels: {[string]: TextLabel} = {}
local abilityKeyLabels: {[string]: TextLabel} = {}
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
    abilityLabels[action] = text; abilityButtons[action] = button; abilityKeyLabels[action] = key
end
local moveLabel = label(canvas, "A D  MOVE    W S  DEPTH    SPACE  JUMP / DOUBLE JUMP", 10, COLORS.muted,
    UDim2.new(1, -490, 1, -126), UDim2.fromOffset(468, 20))
moveLabel.TextXAlignment = Enum.TextXAlignment.Right
local moveName = label(canvas, HERO_MOVES[HEROES[1]], 12, COLORS.cyan, UDim2.new(1, -490, 1, -149), UDim2.fromOffset(468, 20))
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

local ending = make("Frame", {Name = "CampaignResults", Visible = false, BackgroundColor3 = COLORS.ink, BackgroundTransparency = 0.03,
    AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.48), Size = UDim2.fromOffset(420, 348)}, canvas)
round(ending, 14); outline(ending, COLORS.cyan, 0.25)
local endingTitle = label(ending, "CURTAIN BROKEN", 30, COLORS.cyan, UDim2.fromOffset(22, 24), UDim2.fromOffset(376, 44))
endingTitle.TextXAlignment = Enum.TextXAlignment.Center
local endingDetail = label(ending, "The city lives to see another dawn.", 13, COLORS.muted, UDim2.fromOffset(24, 80), UDim2.fromOffset(372, 48))
endingDetail.TextWrapped = true; endingDetail.TextXAlignment = Enum.TextXAlignment.Center
local retry = make("TextButton", {Text = "PLAY AGAIN  /  R", Font = Enum.Font.GothamBold, TextSize = 14,
    BackgroundColor3 = COLORS.cyan, TextColor3 = COLORS.ink, Position = UDim2.fromOffset(80, 288), Size = UDim2.fromOffset(260, 42)}, ending)
round(retry, 7)
retry.Activated:Connect(function() actionRemote:FireServer("Restart", {}) end)

local presentation = require(script.Parent:WaitForChild("CombatHUD")).new({
    colors = COLORS, settings = preferences, ending = ending, actionRemote = actionRemote, playerPanel = playerPanel,
    onSettingsChanged = function() stageAudio.UpdatePreferences() end,
})
task.spawn(function()
    local module = script.Parent:WaitForChild("ProgressionUI", 20)
    if module and module:IsA("ModuleScript") then
        local ok, problem = pcall(function() require(module).Init() end)
        if not ok then warn("Nightfall progression UI: " .. tostring(problem)) end
    end
end)
local function inputLabels()
    local last = UserInputService:GetLastInputType()
    local controller = string.find(last.Name, "Gamepad") ~= nil
    local touch = last == Enum.UserInputType.Touch or (UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled)
    local keyboardKeys = {"J", "K", "L", "Q", "HOLD F", "E"}
    local controllerKeys = {"X", "Y", "B", "LT", "HOLD LB", "RB"}
    for index, action in ipairs(abilityNames) do
        abilityKeyLabels[action].Text = touch and (action == "Block" and "HOLD" or "TAP") or (controller and controllerKeys[index] or keyboardKeys[index])
    end
    moveLabel.Text = controller and "LEFT STICK  MOVE / DEPTH    A  JUMP    D-PAD  HERO" or "A D  MOVE    W S  DEPTH    SPACE  JUMP / RECOVERY"
    retry.Text = controller and "PLAY AGAIN / START" or touch and "PLAY AGAIN" or "PLAY AGAIN / R"
end
UserInputService.LastInputTypeChanged:Connect(inputLabels)
inputLabels()
-- Responsive panels retain legible labels; mobile gets a separate thumb pad and jump button.
local hudScale = make("UIScale", {Scale = 1}, top)
local encounterScale = make("UIScale", {Scale = 1}, encounter)
local playerScale = make("UIScale", {Scale = 1}, playerPanel)
local abilityScale = make("UIScale", {Scale = 1}, abilities)
local endingScale = make("UIScale", {Scale = 1}, ending)
local function resize()
    local camera = workspace.CurrentCamera
    if not camera then return end
    local safe = canvas.AbsoluteSize
    local width = safe.X > 100 and safe.X or camera.ViewportSize.X
    local height = safe.Y > 100 and safe.Y or camera.ViewportSize.Y
    local scale = math.clamp(width / 1040, 0.57, 1)
    local touch = UserInputService.TouchEnabled
    if touchPad then touchPad.Visible = touch end
    if touchJump then touchJump.Visible = touch end
    local travelReserve = player:GetAttribute("TravelPanelVisible") and 96 or 0
    endingScale.Scale = math.min(1, width / 460, math.max(.25, (height - 24 - travelReserve) / 348))
    ending.Position = UDim2.new(.5, 0, .48, -travelReserve * .48)
    abilities.Position = UDim2.new(1, -16, 1, -18)
    if touch then
        local sideSpace = (width - 252) * .5
        local titleWidth = math.clamp(sideSpace, 144, 210)
        local encounterWidth = math.clamp(sideSpace, 132, 174)
        hudScale.Scale = 1; encounterScale.Scale = 1; playerScale.Scale = 1
        top.Size = UDim2.fromOffset(titleWidth, 48); top.Position = UDim2.fromOffset(12, 8)
        titleLabel.Position = UDim2.fromOffset(11, 3); titleLabel.Size = UDim2.new(1, -22, 0, 23); titleLabel.TextSize = titleWidth < 180 and 15 or 18
        brandLabel.Visible = false
        chapterLabel.Position = UDim2.fromOffset(12, 27); chapterLabel.Size = UDim2.new(1, -24, 0, 15); chapterLabel.TextSize = 9
        chapterLabel.TextTruncate = Enum.TextTruncate.AtEnd
        progressBack.Position = UDim2.fromOffset(12, 44); progressBack.Size = UDim2.new(1, -24, 0, 2)
        encounter.Size = UDim2.fromOffset(encounterWidth, 48); encounter.Position = UDim2.new(1, -12, 0, 8)
        waveLabel.Position = UDim2.fromOffset(10, 4); waveLabel.Size = UDim2.new(1, -20, 0, 17); waveLabel.TextSize = 9
        enemyLabel.Position = UDim2.fromOffset(10, 22); enemyLabel.Size = UDim2.new(1, -20, 0, 22); enemyLabel.TextSize = 14
        enemyLabel.TextTruncate = Enum.TextTruncate.AtEnd; objectiveLabel.Visible = false
        local chooseHero = height >= 450 and (snapshot.status == "Intermission" or snapshot.status == "Traverse" or snapshot.status == "Advance")
        local healthHeight = chooseHero and 124 or 70
        playerPanel.Size = UDim2.fromOffset(178, healthHeight); playerPanel.Position = UDim2.new(0, 16, 1, -(150 + healthHeight))
        heroLabel.Position = UDim2.fromOffset(10, 6); heroLabel.Size = UDim2.fromOffset(158, 19); heroLabel.TextSize = 14
        percentLabel.Position = UDim2.fromOffset(10, 26); percentLabel.Size = UDim2.fromOffset(91, 35); percentLabel.TextSize = 30
        stocksLabel.Position = UDim2.fromOffset(99, 33); stocksLabel.Size = UDim2.fromOffset(72, 23); stocksLabel.TextSize = 14
        damageHint.Visible = false
        for index, hero in ipairs(HEROES) do
            local button = heroButtons[hero]
            button.Visible = chooseHero; button.Size = UDim2.fromOffset(52, 44); button.Position = UDim2.fromOffset(8 + (index - 1) * 55, 72); button.TextSize = 9
        end
        local buttonScale = math.clamp(width / 750, .8, 1)
        abilityScale.Scale = buttonScale; abilities.Size = UDim2.fromOffset(220, 132)
        for index, action in ipairs(abilityNames) do
            abilityButtons[action].Position = UDim2.fromOffset((index - 1) % 3 * 75, math.floor((index - 1) / 3) * 66)
            abilityButtons[action].Size = UDim2.fromOffset(70, 60); abilityLabels[action].Position = UDim2.fromOffset(2, 27)
        end
        if touchJump then touchJump.Position = UDim2.new(1, -29, 1, -(132 * buttonScale + 28)) end
        if touchPad then touchPad.Position = UDim2.new(0, 26, 1, -136) end
    else
        hudScale.Scale = scale; encounterScale.Scale = scale; playerScale.Scale = scale
        top.Size = UDim2.fromOffset(342, 108); top.Position = UDim2.fromOffset(22, 16)
        titleLabel.Position = UDim2.fromOffset(16, 9); titleLabel.Size = UDim2.fromOffset(312, 30); titleLabel.TextSize = 25
        brandLabel.Visible = true
        chapterLabel.Position = UDim2.fromOffset(17, 69); chapterLabel.Size = UDim2.fromOffset(310, 18); chapterLabel.TextSize = 12
        progressBack.Position = UDim2.fromOffset(17, 94); progressBack.Size = UDim2.fromOffset(308, 3)
        encounter.Size = UDim2.fromOffset(245, 85); encounter.Position = UDim2.new(1, -22, 0, 16)
        waveLabel.Position = UDim2.fromOffset(16, 10); waveLabel.Size = UDim2.fromOffset(215, 21); waveLabel.TextSize = 11
        enemyLabel.Position = UDim2.fromOffset(16, 34); enemyLabel.Size = UDim2.fromOffset(215, 26); enemyLabel.TextSize = 20; objectiveLabel.Visible = true
        playerPanel.Size = UDim2.fromOffset(280, 151); playerPanel.Position = UDim2.new(0, 16, 1, -(151 * scale + 18))
        heroLabel.Position = UDim2.fromOffset(15, 10); heroLabel.Size = UDim2.fromOffset(245, 22); heroLabel.TextSize = 17
        percentLabel.Position = UDim2.fromOffset(14, 32); percentLabel.Size = UDim2.fromOffset(170, 55); percentLabel.TextSize = 46
        stocksLabel.Position = UDim2.fromOffset(180, 47); stocksLabel.Size = UDim2.fromOffset(86, 28); stocksLabel.TextSize = 19; damageHint.Visible = true
        for index, hero in ipairs(HEROES) do
            local button = heroButtons[hero]
            button.Visible = true; button.Size = UDim2.fromOffset(82, 29); button.Position = UDim2.fromOffset(12 + (index - 1) * 87, 110); button.TextSize = 10
        end
        abilityScale.Scale = scale; abilities.Size = UDim2.fromOffset(468, 78)
        for index, action in ipairs(abilityNames) do
            abilityButtons[action].Position = UDim2.fromOffset((index - 1) * 79, 0)
            abilityButtons[action].Size = UDim2.fromOffset(73, 74); abilityLabels[action].Position = UDim2.fromOffset(3, 33)
        end
    end
    local rescueFooter = touch and player:GetAttribute("RescuePanelVisible") == true
    RescueTouchLayout.Apply(rescueFooter, {abilities=abilities, pad=touchPad, jump=touchJump, health=playerPanel})
    heroLabel.Visible = true
    if rescueFooter and height < 450 then
        -- Keep percent/stocks readable above the raised joystick in short landscape.
        playerPanel.Position = UDim2.fromOffset(16, 64); playerPanel.Size = UDim2.fromOffset(178, 44)
        heroLabel.Visible = false
        percentLabel.Position = UDim2.fromOffset(10, 2); stocksLabel.Position = UDim2.fromOffset(99, 8)
    end
    moveLabel.Visible = width > 830 and not touch; moveName.Visible = width > 830 and not touch
    toastLabel.Position = UDim2.new(0.5, -math.min(280, width * .46), 0, touch and 119 or (width < 650 and 217 or 201))
    toastLabel.Size = UDim2.fromOffset(math.min(560, width * .92), touch and 25 or 35); toastLabel.TextSize = touch and 13 or 19
    presentation.resize()
end
local function characterReady(character: Model)
    focusGuard:Reset("character-ready")
    humanoid = character:WaitForChild("Humanoid") :: Humanoid
    root = character:WaitForChild("HumanoidRootPart") :: BasePart
    humanoid.Died:Connect(function() if player.Character == character then focusGuard:Reset("death") end end)
    shoulderDefaults = {}; rigJoints = {}; tracks = {}; cameraCenter = nil; poseAction = nil; localBlocking = false
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
    if action == "Special" then
        poseAction = "Special"; poseStart = os.clock()
        return
    end
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
    if action == "Block" and held == false then releaseBlock(); return end
    if not actionCapabilities:Allows(action, held) or focusGuard:Blocked() then return end
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
local function desperationTouchMode()
    local last = UserInputService:GetLastInputType()
    return UserInputService.TouchEnabled and string.find(last.Name, "Gamepad") == nil
end
desperationControl = DesperationControl.new({blocked=function()return focusGuard:Blocked()end,send=function()
    actionRemote:FireServer("Desperation", {direction=facing})
    animate("Special")
end})
desperationHUD = DesperationHUD.new({control=desperationControl,special=abilityButtons.Special,colors=COLORS})
local bindings: any = {
    Light = {Enum.KeyCode.J, Enum.KeyCode.ButtonX}, Heavy = {Enum.KeyCode.K, Enum.KeyCode.ButtonY},
    Special = {Enum.KeyCode.L, Enum.KeyCode.ButtonB}, Dash = {Enum.KeyCode.Q, Enum.KeyCode.ButtonL2},
    Block = {Enum.KeyCode.F, Enum.KeyCode.ButtonL1}, Recovery = {Enum.KeyCode.E, Enum.KeyCode.ButtonR1},
    Jump = {Enum.KeyCode.Space, Enum.KeyCode.ButtonA},
}
for action, keys in pairs(bindings) do
    ContextActionService:BindAction("Nightfall_" .. action, function(_, inputState)
        if focusGuard:ReleaseInput(action, inputState) then return Enum.ContextActionResult.Sink end
        if desperationControl:Handle(action, inputState) then return Enum.ContextActionResult.Sink end
        if focusGuard:Blocked() then return Enum.ContextActionResult.Pass end
        if inputState == Enum.UserInputState.Begin then send(action, action == "Block" and true or nil) end
        return Enum.ContextActionResult.Sink
    end, false, table.unpack(keys))
end
for action, button in pairs(abilityButtons) do
    if action == "Block" then
        button.InputBegan:Connect(function(input)
            if actionCapabilities:Allows("Block", true) and not focusGuard:Blocked() and (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) then blockInput = input; send("Block", true) end
        end)
        button.InputEnded:Connect(function(input)
            if input == blockInput then send("Block", false) end
        end)
    else button.Activated:Connect(function() send(action) end) end
end
UserInputService.InputBegan:Connect(function(input, processed)
    if processed or focusGuard:Blocked() then return end
    heldKeys[input.KeyCode] = true
    if input.KeyCode == Enum.KeyCode.One then actionRemote:FireServer("SelectCharacter", {hero = HEROES[1]})
    elseif input.KeyCode == Enum.KeyCode.Two then actionRemote:FireServer("SelectCharacter", {hero = HEROES[2]})
    elseif input.KeyCode == Enum.KeyCode.Three then actionRemote:FireServer("SelectCharacter", {hero = HEROES[3]})
    elseif input.KeyCode == Enum.KeyCode.R and ending.Visible then actionRemote:FireServer("Restart", {})
    elseif input.KeyCode == Enum.KeyCode.DPadRight or input.KeyCode == Enum.KeyCode.DPadLeft then
        local current = table.find(HEROES, snapshot.hero) or 1
        local offset = input.KeyCode == Enum.KeyCode.DPadRight and 1 or -1
        actionRemote:FireServer("SelectCharacter", {hero = HEROES[(current - 1 + offset) % #HEROES + 1]})
    elseif input.KeyCode == Enum.KeyCode.ButtonStart and ending.Visible then actionRemote:FireServer("Restart", {}) end
end)
UserInputService.InputEnded:Connect(function(input)
    heldKeys[input.KeyCode] = nil
    if input == blockInput then releaseBlock() end
end)
UserInputService.InputChanged:Connect(function(input)
    if input.KeyCode == Enum.KeyCode.Thumbstick1 then gamepadMove = not focusGuard:Blocked() and Vector2.new(input.Position.X, -input.Position.Y) or Vector2.zero end
end)

touchPad = make("Frame", {Visible = UserInputService.TouchEnabled, Active = true,
    BackgroundColor3 = COLORS.panel, BackgroundTransparency = 0.3, Position = UDim2.new(0, 25, 1, -280), Size = UDim2.fromOffset(116, 116)}, canvas)
round(touchPad, 58); outline(touchPad, COLORS.cyan)
touchKnob = make("Frame", {BackgroundColor3 = COLORS.cyan, BackgroundTransparency = 0.28,
    AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(42, 42)}, touchPad)
round(touchKnob, 21)
local function updateTouch(input: InputObject)
    local point = Vector2.new(input.Position.X, input.Position.Y)
    local delta = (point - (touchPad.AbsolutePosition + touchPad.AbsoluteSize / 2)) / 42
    if delta.Magnitude > 1 then delta = delta.Unit end
    touchMove = delta; touchKnob.Position = UDim2.new(0.5, delta.X * 34, 0.5, delta.Y * 34)
end
touchPad.InputBegan:Connect(function(input)
    if not focusGuard:Blocked() and input.UserInputType == Enum.UserInputType.Touch then touchInput = input; updateTouch(input) end
end)
UserInputService.InputChanged:Connect(function(input) if input == touchInput and not focusGuard:Blocked() then updateTouch(input) end end)
UserInputService.InputEnded:Connect(function(input)
    if input == touchInput then touchInput = nil; touchMove = Vector2.zero; touchKnob.Position = UDim2.fromScale(0.5, 0.5) end
end)
touchJump = make("TextButton", {Visible = UserInputService.TouchEnabled, Text = "JUMP", Font = Enum.Font.GothamBold,
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
    if preferences.effects <= 0 or activeEffects >= 24 then return end
    activeEffects += 1
    task.delay(0.65, function() activeEffects -= 1 end)
    local ring = particlePart(position, color, Vector3.new(0.12, 1, 1))
    ring.Shape = Enum.PartType.Cylinder
    ring.CFrame = CFrame.new(position) * CFrame.Angles(0, 0, math.rad(90))
    local scale = heavy and 12 or 6
    TweenService:Create(ring, TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
        {Size = Vector3.new(0.04, scale, scale), Transparency = 1}):Play()
    Debris:AddItem(ring, 0.4)
    local sparkCount = math.max(2, math.floor((heavy and 9 or 5) * preferences.effects))
    for index = 1, sparkCount do
        local angle = index * math.pi * 2 / sparkCount
        local offset = Vector3.new(math.cos(angle) * 4 * direction, math.sin(angle) * 3, math.sin(angle * 2) * 1.3)
        local streak = particlePart(position, color, Vector3.new(0.16, 0.16, heavy and 2 or 1))
        streak.CFrame = CFrame.lookAt(position, position + offset)
        TweenService:Create(streak, TweenInfo.new(0.23), {Position = position + offset, Transparency = 1}):Play()
        Debris:AddItem(streak, 0.3)
    end
end
-- Original authored special poses and effects share Config dimensions with server attacks.
local heroSpecials = HeroSpecials.new(effectsFolder, preferences, function(position: Vector3)
    combatSound("Attack", position)
    if root and (root.Position - position).Magnitude < 65 then cameraKick = math.max(cameraKick, .68) end
end)
local function startSpecial(position: Vector3, hero: string, direction: number, userId: number?): boolean
    return heroSpecials.Emit(position, hero, direction, userId)
end
local function importedEffect(kind: string, position: Vector3): boolean
    local template = asset("VFX", kind)
    if preferences.effects <= 0 or not template or activeEffects >= 24 then return false end
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
        if item:IsA("ParticleEmitter") then item.Enabled = false; item:Emit(math.clamp(math.floor((item:GetAttribute("BurstCount") or item:GetAttribute("EmitCount") or 16) * preferences.effects), 1, 60)) end
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
local activeHazards = 0
local hazardOwners: {[BasePart]: Model} = {}
local function hazardFootprint(event: any, impact: boolean)
    if activeHazards >= 36 or typeof(event.position) ~= "Vector3" then return end
    activeHazards += 1
    local duration = impact and 0.28 or math.clamp(tonumber(event.duration) or 0.6, 0.1, 5)
    local radius = math.clamp(tonumber(event.radius) or 6, 1, 60)
    local color = typeof(event.color) == "Color3" and event.color or (event.jumpable and COLORS.cyan or COLORS.red)
    if preferences.highContrast then color = event.jumpable and Color3.fromRGB(185, 255, 253) or COLORS.orange end
    local position = event.position
    local size: Vector3
    if event.shape == "Circle" then size = Vector3.new(0.07, radius * 2, radius * 2)
    elseif typeof(event.size) == "Vector3" then size = Vector3.new(math.max(0.1, event.size.X), 0.07, math.max(0.1, event.size.Z))
    else
        position += Vector3.new(event.heavy and 0 or (event.direction or 1) * radius * 0.5, 0, 0)
        size = Vector3.new(event.heavy and radius * 2 or radius, 0.07, event.heavy and 25 or 7)
    end
    local floorPosition = Vector3.new(position.X, 0.17, position.Z)
    local warningPart = particlePart(floorPosition, color, size)
    if event.shape == "Circle" then warningPart.Shape = Enum.PartType.Cylinder; warningPart.CFrame = CFrame.new(floorPosition) * CFrame.Angles(0, 0, math.pi / 2) end
    warningPart.Transparency = impact and 0.18 or 0.76
    if not impact and typeof(event.targetModel) == "Instance" and event.targetModel:IsA("Model") then hazardOwners[warningPart] = event.targetModel end
    if not impact then
        local marker = make("BillboardGui", {Size = UDim2.fromOffset(96, 26), AlwaysOnTop = true, StudsOffsetWorldSpace = Vector3.new(0, 0.6, 0)}, warningPart)
        local hint = label(marker, event.jumpable and "↑ JUMP" or "! DODGE", 13, color, UDim2.fromScale(0, 0), UDim2.fromScale(1, 1))
        hint.TextXAlignment = Enum.TextXAlignment.Center; hint.TextStrokeTransparency = 0.2
        TweenService:Create(warningPart, TweenInfo.new(duration), {Transparency = preferences.highContrast and 0.16 or 0.28}):Play()
    else TweenService:Create(warningPart, TweenInfo.new(duration), {Transparency = 1}):Play() end
    Debris:AddItem(warningPart, duration + 0.04)
    task.delay(duration + 0.05, function() activeHazards -= 1; hazardOwners[warningPart] = nil end)
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
-- Critical body warnings ignore cosmetic effect-density settings.
local bodyTells: {[Model]: Highlight} = {}
local function clearBodyTell(model: Model)
    local flash = bodyTells[model]
    if flash then flash:Destroy(); bodyTells[model] = nil end
    local actor = actorPoses[model]
    if actor then actor.tellUntil = nil end
end
local function bodyTell(event: any)
    local model = event.targetModel
    if typeof(model) ~= "Instance" or not model:IsA("Model") or not model.Parent then return end
    clearBodyTell(model)
    local duration = math.clamp(tonumber(event.duration) or .35, .30, 5)
    local actor = registerActor(model)
    if actor then actor.tellStart = os.clock(); actor.tellUntil = actor.tellStart + duration; actor.moveId = event.moveId end
    local color = preferences.highContrast and COLORS.orange or (typeof(event.color) == "Color3" and event.color or COLORS.red)
    local flash = make("Highlight", {Name = "EnemyBodyTell", Adornee = model,
        DepthMode = Enum.HighlightDepthMode.Occluded, FillColor = color, FillTransparency = .36,
        OutlineColor = COLORS.text, OutlineTransparency = .05}, model)
    bodyTells[model] = flash
    Debris:AddItem(flash, duration)
    task.delay(duration, function() if bodyTells[model] == flash then clearBodyTell(model) end end)
end
local hitFlashes: {[Model]: Highlight} = {}
local damageEdge = make("Frame", {Name = "DamageEdge", BackgroundTransparency = 1, BorderSizePixel = 0, Size = UDim2.fromScale(1, 1)}, gui)
local damageStroke = make("UIStroke", {Color = COLORS.red, Thickness = 5, Transparency = 1}, damageEdge)
local damageTween: Tween? = nil
local function hitFeedback(event: any)
    if tonumber(event.damage) == nil or event.damage <= 0 then return end
    local target: Model? = nil
    if typeof(event.targetModel) == "Instance" and event.targetModel:IsA("Model") then target = event.targetModel
    elseif type(event.targetUserId) == "number" then
        local victim = Players:GetPlayerByUserId(event.targetUserId)
        target = victim and victim.Character
    end
    if event.playerUserId == player.UserId then hitPoseHoldUntil = math.max(hitPoseHoldUntil, os.clock() + 0.045) end
    if not target or not target.Parent then return end
    if target == player.Character then
        hitPoseHoldUntil = math.max(hitPoseHoldUntil, os.clock() + 0.06)
        if preferences.effects > 0 then
            if damageTween then damageTween:Cancel() end
            damageStroke.Transparency = 0.25
            damageTween = TweenService:Create(damageStroke, TweenInfo.new(0.25), {Transparency = 1}); damageTween:Play()
        end
    else
        local actor = registerActor(target)
        if actor then actor.poseHoldUntil = os.clock() + 0.06 end
    end
    if preferences.effects <= 0 then return end
    if hitFlashes[target] then hitFlashes[target]:Destroy() end
    local flash = make("Highlight", {Name = "HitReaction", Adornee = target, DepthMode = Enum.HighlightDepthMode.Occluded,
        FillColor = target == player.Character and COLORS.red or COLORS.text, FillTransparency = 0.35,
        OutlineColor = COLORS.text, OutlineTransparency = 0.1}, target)
    hitFlashes[target] = flash
    TweenService:Create(flash, TweenInfo.new(0.17), {FillTransparency = 1, OutlineTransparency = 1}):Play()
    Debris:AddItem(flash, 0.2)
    task.delay(0.21, function() if hitFlashes[target] == flash then hitFlashes[target] = nil end end)
end
fxRemote.OnClientEvent:Connect(function(event: any)
    if type(event) ~= "table" then return end
    local kind = event.kind
    local riskMessage, riskColor = riskFeedback.Emit(event)
    if riskMessage then toast(riskMessage, riskColor) end
    enemyPresentation.Emit(event)
    if kind == "EnemyEvade" and typeof(event.targetModel) == "Instance" and event.targetModel:IsA("Model") then
        local actor = registerActor(event.targetModel)
        if actor then actor.moveId = "LeaperEvade"; actor.start = os.clock(); actor.moveDuration = event.duration or .5; actor.tellUntil = nil end
    end
    if kind == "Hit" then hitFeedback(event) end
    if kind == "Attack" or kind == "Dash" then
        local action = kind == "Dash" and "Dash" or event.action
        if action == "Slam" then action = "Heavy" end
        if action == "Light" and (event.combo or 1) % 2 == 0 then action = "Light2" end
        if event.playerUserId == player.UserId then
            animate(action or "Light")
        else
            local model: Model? = nil
            if event.playerUserId then
                local owner = Players:GetPlayerByUserId(event.playerUserId)
                model = owner and owner.Character
            elseif typeof(event.targetModel) == "Instance" and event.targetModel:IsA("Model") then
                model = event.targetModel
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
                if actor then actor.action = action; actor.start = os.clock(); actor.moveId = event.moveId; actor.moveDuration = .45; actor.tellUntil = nil end
            end
        end
    end
    if kind == "Wave" then toast("CURSES INCOMING", COLORS.red)
    elseif kind == "StageClear" then toast("CURTAIN OPEN  /  MOVE RIGHT →", COLORS.cyan)
    elseif kind == "Victory" then toast("THE CURTAIN IS BROKEN", COLORS.cyan) end
    if typeof(event.position) ~= "Vector3" then return end
    local position = event.position
    local distinctSpecial = kind == "Attack" and event.action == "Special"
    if distinctSpecial then distinctSpecial = startSpecial(position, event.hero, tonumber(event.direction) or 1, event.playerUserId) end
    if not distinctSpecial and (kind == "Hit" or kind == "Attack" or kind == "Dash") then combatSound(kind, position) end
    local color = HERO_COLORS[event.hero] or (event.enemy and COLORS.red or COLORS.cyan)
    if kind == "BossPhase" then
        local bossName = event.enemyName or event.name or (type(snapshot.boss) == "table" and snapshot.boss.name) or "BOSS"
        toast(string.upper(bossName) .. " / PHASE " .. tostring(event.phase or 2), COLORS.red)
        burst(position, typeof(event.color) == "Color3" and event.color or COLORS.red, true, 1)
        cameraKick = math.max(cameraKick, 0.8)
    elseif kind == "BossStagger" then
        toast(string.upper(event.enemyName or "CURSE") .. " / EXPOSED — PUNISH NOW", COLORS.green)
        if typeof(event.targetModel) == "Instance" and event.targetModel:IsA("Model") then
            clearBodyTell(event.targetModel)
            presentation.cancelWarnings(event.targetModel)
            for part, owner in pairs(hazardOwners) do
                if owner == event.targetModel then part:Destroy(); hazardOwners[part] = nil end
            end
        end
        burst(position, COLORS.green, false, 1)
    elseif kind == "ShareStock" then
        toast(string.upper(event.donorName or "TEAMMATE") .. " SHARED A STOCK / " .. string.upper(event.targetName or "ALLY") .. " RETURNS", COLORS.green)
        burst(position, COLORS.green, false, 1)
    elseif kind == "Checkpoint" then
        toast(event.title or "CHECKPOINT REACHED", COLORS.cyan)
    elseif kind == "GuardBreak" then
        toast("GUARD BROKEN / EVADE", COLORS.orange)
        burst(position, COLORS.orange, true, 1)
    elseif kind == "Telegraph" then
        if event.tellStyle == "Body" then bodyTell(event)
        else
            hazardFootprint(event, false)
            if typeof(event.targetModel) == "Instance" and event.targetModel:IsA("Model") then
                local actor = registerActor(event.targetModel)
                if actor then actor.tellStart = os.clock(); actor.tellUntil = actor.tellStart + math.max(.30, event.duration or .35); actor.moveId = event.moveId end
            end
        end
        presentation.telegraph(event)
    elseif kind == "EnemyFeint" then
        bodyTell(event)
    elseif kind == "EnemyCancel" then
        if typeof(event.targetModel) == "Instance" and event.targetModel:IsA("Model") then
            clearBodyTell(event.targetModel)
            local actor = actorPoses[event.targetModel]
            if actor then actor.moveId = nil; actor.action = nil end
            presentation.cancelWarnings(event.targetModel)
        end
    elseif kind == "EnemyImpact" then
        if typeof(event.targetModel) == "Instance" and event.targetModel:IsA("Model") then clearBodyTell(event.targetModel) end
        if event.tellStyle ~= "Body" then hazardFootprint(event, true) end
        bossEffects.Emit(event)
        if root and (root.Position - position).Magnitude < 35 then cameraKick = math.max(cameraKick, 0.45) end
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
    local wasDowned = snapshot.downed
    for key, value in pairs(state) do snapshot[key] = value end
    actionCapabilities:Update(snapshot, localBlocking or blockInput ~= nil)
    desperationControl:Update(snapshot)
    if snapshot.downed and not wasDowned then focusGuard:Reset("downed") end
    local hero = snapshot.hero
    local color = HERO_COLORS[hero] or COLORS.cyan
    heroLabel.Text = string.upper((Config.Characters[hero] or Config.Characters[HEROES[1]]).Name); heroLabel.TextColor3 = color
    local percent = math.floor(snapshot.percent or 0)
    percentLabel.Text = tostring(percent) .. "%"
    percentLabel.TextColor3 = percent >= 100 and COLORS.red or (percent >= 60 and COLORS.orange or COLORS.text)
    local stocks = math.clamp(math.floor(snapshot.stocks or 0), 0, 9)
    stocksLabel.Text = stocks > 0 and string.rep("● ", stocks) or "OUT"
    damageHint.Text = snapshot.downed and "WAITING FOR YOUR TEAM" or (snapshot.blocking and "GUARDING / WATCH YOUR BACK" or "HIGHER % = BIGGER LAUNCH")
    chapterLabel.Text = string.format("%02d / %s", snapshot.stage or 1, string.upper(snapshot.stageName or "VEIL OVER THE CITY"))
    waveLabel.Text = string.format("WAVE %d / %d · %s", snapshot.wave or 0, snapshot.waves or 4, string.upper(snapshot.encounterKind or "CO-OP"))
    enemyLabel.Text = tostring(snapshot.enemiesRemaining or 0) .. ((snapshot.enemiesRemaining or 0) == 1 and " CURSE REMAINS" or " CURSES REMAIN")
    local total = math.max(1, snapshot.waves or 3)
    local progress = math.clamp(((snapshot.stage or 1) - 1) / 3 + (snapshot.wave or 0) / total / 3, 0, 1)
    TweenService:Create(progressFill, TweenInfo.new(0.3), {Size = UDim2.fromScale(progress, 1)}):Play()
    moveName.Text = HERO_MOVES[hero] or "SPECIAL"
    for name, button in pairs(heroButtons) do button.BackgroundTransparency = name == hero and 0 or 0.65 end
    local status = snapshot.status
    objectiveLabel.Text = (status == "StageClear" or status == "Advance" or status == "Traverse") and "MOVE RIGHT / RALLY TOGETHER →" or (status == "Intermission" and "BREATHE / NEXT WAVE APPROACHING" or "Clear the wave to open the curtain")
    ending.Visible = status == "Defeat" or status == "Victory"
    if ending.Visible then
        endingTitle.Text = status == "Victory" and "CURTAIN BROKEN" or "THE CITY GOES DARK"
        endingTitle.TextColor3 = status == "Victory" and COLORS.cyan or COLORS.red
        endingDetail.Text = status == "Victory" and "Three districts reclaimed. Your squad made it through."
            or "Your squad ran out of stocks. Guard, recover, and stay together on the next run."
    elseif status ~= previousStatus and (status == "StageClear" or status == "Advance") then toast("DISTRICT CLEARED  /  ADVANCE →", COLORS.cyan) end
    if status == "Traverse" and previousStatus ~= status then toast("NEXT ENCOUNTER / MOVE RIGHT TOGETHER →", COLORS.cyan) end
    if status == "Intermission" and previousStatus ~= status then toast((snapshot.wave or 0) == 0 and "ENTER THE CURTAIN / GET READY" or "WAVE CLEARED / REGROUP", COLORS.cyan) end
    if (snapshot.wave or 0) == 0 and status == "Intermission" then waveLabel.Text = "ENTER THE CURTAIN"; enemyLabel.Text = "GET READY" end
    if status ~= previousStatus then resize() end
    presentation.updateSnapshot(snapshot)
    stageAudio.Update(snapshot)
    previousStatus = status
end)

local renderAccum = 0
local partyAccum = 0
local cameraTarget = Vector3.new(60, 5, 0)
local cameraDistance = 52
-- Sample original imported R6 KeyframeSequence data cosmetically; damage stays server-owned.
local function applyHeroPose(joints: any, poses: any, dt: number)
    for joint, neutral in pairs(joints) do
        if joint.Parent and joint.Part1 then
            joint.C0 = joint.C0:Lerp(neutral * (poses[joint.Part1.Name] or CFrame.identity), math.min(1, dt * 24))
            joint.Transform = CFrame.identity
        end
    end
end
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
        local specialPose = chosen == "Special" and HeroSpecials.Pose(snapshot.hero, now - poseStart)
        if chosen == "Special" and not specialPose then poseAction = nil; chosen = nil end
        if specialPose then
            applyHeroPose(rigJoints, specialPose, dt)
        else
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
            if now < hitPoseHoldUntil then poseStart += dt; locomotionStart += dt
            else applyToolboxPose(rigJoints, data, time, dt) end
        end
        end
    end
    for model, actor in pairs(actorPoses) do
        if not model.Parent or actor.humanoid.Health <= 0 then clearBodyTell(model); actorPoses[model] = nil
        elseif actor.tellUntil and now < actor.tellUntil and toolboxData.Heavy then
            -- Hold the imported heavy anticipation, never play its strike during the warning.
            local progress = math.clamp((now - actor.tellStart) / math.max(.30, actor.tellUntil - actor.tellStart), 0, 1)
            local tellPose = EnemyPresentation.Pose(actor.moveId, progress, true)
            if tellPose then applyHeroPose(actor.joints, tellPose, dt)
            else applyToolboxPose(actor.joints, toolboxData.Heavy, toolboxData.Heavy.duration * (.08 + progress * .12), dt) end
        elseif actor.moveId and now - actor.start <= (actor.moveDuration or .45) then
            local attackPose = EnemyPresentation.Pose(actor.moveId, (now - actor.start) / (actor.moveDuration or .45), false)
            if attackPose then applyHeroPose(actor.joints, attackPose, dt) end
        else
            actor.moveId = nil
            local specialPose = actor.action == "Special" and HeroSpecials.Pose(model:GetAttribute("Hero"), now - actor.start)
            if actor.action == "Special" and not specialPose then actor.action = nil end
            if specialPose then applyHeroPose(actor.joints, specialPose, dt)
            else
            local data = actor.action and toolboxData[actor.action]
            if data and now - actor.start > math.max(0.05, data.duration) then actor.action = nil; data = nil end
            local actionPose = data ~= nil
            if not data then
                local actorRoot = model:FindFirstChild("HumanoidRootPart")
                local moving = actorRoot and actorRoot:IsA("BasePart") and Vector3.new(actorRoot.AssemblyLinearVelocity.X, 0, actorRoot.AssemblyLinearVelocity.Z).Magnitude > 2
                data = toolboxData[model:GetAttribute("Blocking") and "Block" or moving and "Walk" or "Idle"]
            end
            if data then
                local duration = math.max(0.05, data.duration)
                if now < (actor.poseHoldUntil or 0) then actor.start += dt
                else applyToolboxPose(actor.joints, data, actionPose and math.clamp(now - actor.start, 0, duration) or now % duration, dt) end
            end
        end
        end
    end
end
RunService.PreSimulation:Connect(sampleToolbox)
-- Input is resolved after PlayerModule input, before physics/camera presentation.
-- This callback never writes character CFrame or camera state.
RunService:BindToRenderStep("NightfallMovement", Enum.RenderPriority.Input.Value + 1, function()
    if humanoid and root and humanoid.Health > 0 then
        local keyboard = Vector2.new((heldKeys[Enum.KeyCode.D] and 1 or 0) - (heldKeys[Enum.KeyCode.A] and 1 or 0),
            (heldKeys[Enum.KeyCode.S] and 1 or 0) - (heldKeys[Enum.KeyCode.W] and 1 or 0))
        local movement = keyboard + (gamepadMove.Magnitude > 0.15 and gamepadMove or Vector2.zero) + touchMove
        if movement.Magnitude > 1 then movement = movement.Unit end
        if UserInputService:GetFocusedTextBox() or ending.Visible or player:GetAttribute("MenuOpen") or player:GetAttribute("SettingsOpen") then movement = Vector2.zero end
        if math.abs(movement.X) > 0.1 then
            local nextFacing = movement.X > 0 and 1 or -1
            if nextFacing ~= facing and localBlocking then actionRemote:FireServer("Block", {held = true, direction = nextFacing}) end
            facing = nextFacing
        end
        -- Stop walking into the server's hard bounds before prediction/correction can oscillate.
        -- Only outward input is filtered. Launch velocity and all root transforms remain untouched.
        local stageMin = ((snapshot.stage or 1) - 1) * 180
        local forwardLimit = type(snapshot.walkingMaxX) == "number" and snapshot.walkingMaxX or stageMin + 176
        local x, z = movement.X, movement.Y
        local position = root.Position
        if (x < 0 and position.X <= stageMin + 4.4) or (x > 0 and position.X >= forwardLimit - .4) then x = 0 end
        if (z < 0 and position.Z <= -13.6) or (z > 0 and position.Z >= 13.6) then z = 0 end
        humanoid:Move(Vector3.new(x, 0, z * 0.7), false)
    end
end)
-- Single camera owner: a fixed viewing angle translated with one smoothed center.
RunService:BindToRenderStep("NightfallPresentation", Enum.RenderPriority.Camera.Value + 1, function(dt)
    local camera = workspace.CurrentCamera
    if not camera then return end
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
    end
    -- Camera subjects are sampled every render, never on the 10 Hz HUD/discovery timer.
    local localX = root and root.Position.X or 60
    if snapshot.downed then
        for _, teammate in ipairs(Players:GetPlayers()) do
            local character = teammate.Character
            local teammateRoot = character and character:FindFirstChild("HumanoidRootPart")
            if teammateRoot and teammateRoot:IsA("BasePart") and not character:GetAttribute("Downed") then localX = teammateRoot.Position.X; break end
        end
    end
    local minX, maxX = localX, localX
    for _, teammate in ipairs(Players:GetPlayers()) do
        local character = teammate.Character
        local teammateRoot = character and character:FindFirstChild("HumanoidRootPart")
        local teammateHumanoid = character and character:FindFirstChildOfClass("Humanoid")
        if teammateRoot and teammateRoot:IsA("BasePart") and teammateHumanoid and teammateHumanoid.Health > 0 and not character:GetAttribute("Downed")
            and math.abs(teammateRoot.Position.X - localX) < 170 then
            minX = math.min(minX, teammateRoot.Position.X); maxX = math.max(maxX, teammateRoot.Position.X)
        end
    end
    local stageStart = ((snapshot.stage or 1) - 1) * 180
    local midpoint = math.clamp((minX + maxX) / 2, stageStart + 38, stageStart + 142)
    cameraTarget = Vector3.new(midpoint, 5, 0)
    local aspect = camera.ViewportSize.X / math.max(1, camera.ViewportSize.Y)
    local desiredDistance = math.clamp((maxX - minX + 54) / (2 * math.tan(math.rad(22)) * aspect), 52, 140)
    camera.CameraType = Enum.CameraType.Scriptable; camera.FieldOfView = 44
    local alpha = 1 - math.exp(-6 * math.max(0, dt))
    if cameraCenter then
        cameraCenter = cameraCenter:Lerp(cameraTarget, alpha)
        cameraDistance += (desiredDistance - cameraDistance) * alpha
    else
        cameraCenter = cameraTarget; cameraDistance = desiredDistance
    end
    cameraKick = math.max(0, cameraKick - dt * 3)
    local now = os.clock()
    local shake = Vector3.new(math.noise(now * 28, 0), math.noise(0, now * 28), 0) * cameraKick * preferences.shake
    local focus = cameraCenter + shake
    local eye = focus + Vector3.new(0, cameraDistance * 0.37, cameraDistance)
    -- Eye and focus share the same smoothed center: movement cannot introduce yaw snaps.
    camera.CFrame = CFrame.lookAt(eye, focus)
    camera.Focus = CFrame.new(focus)
    desperationHUD.Render(desperationTouchMode())
    renderAccum += dt
    if renderAccum > 0.1 then
        renderAccum = 0
        presentation.updateSpatial(camera, root)
        local now = workspace:GetServerTimeNow()
        if snapshot.status == "Intermission" and type(snapshot.nextWaveAt) == "number" then
            objectiveLabel.Text = string.format("NEXT WAVE IN %.1fs / REGROUP", math.max(0, snapshot.nextWaveAt - now))
        end
        for name, text in pairs(abilityLabels) do
            local finish = (snapshot.cooldowns or {})[name]
            local remaining = type(finish) == "number" and math.max(0, finish - now) or 0
            actionCapabilities:RenderButton(abilityButtons[name], text, name, remaining, COLORS)
        end
        if desperationControl:Available() and not desperationTouchMode() then
            desperationHintActive = true
            local controller = string.find(UserInputService:GetLastInputType().Name, "Gamepad") ~= nil
            abilityKeyLabels.Special.Text = controller and "HOLD B + Y" or "HOLD L + K"
            abilityLabels.Special.Text = "+"..tostring(snapshot.desperationCost).."% SELF"
            abilityLabels.Special.TextColor3 = COLORS.orange
        elseif desperationHintActive then desperationHintActive = false; inputLabels() end
    end
end)
if workspace.CurrentCamera then workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(resize) end
workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
    if workspace.CurrentCamera then workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(resize) end
    resize()
end)
canvas:GetPropertyChangedSignal("AbsoluteSize"):Connect(resize)
player:GetAttributeChangedSignal("TravelPanelVisible"):Connect(resize)
player:GetAttributeChangedSignal("RescuePanelVisible"):Connect(resize)
UserInputService:GetPropertyChangedSignal("TouchEnabled"):Connect(function() resize(); inputLabels() end)
resize()
toast("STAY TOGETHER. BREAK THE CURTAIN.", COLORS.cyan)
