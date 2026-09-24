--!strict
-- Presentation-only combat HUD. Server snapshots supply encounter and run values.
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local ContextActionService = game:GetService("ContextActionService")
local GuiService = game:GetService("GuiService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local Config = require(game:GetService("ReplicatedStorage"):WaitForChild("Nightfall"):WaitForChild("Shared"):WaitForChild("Config"))
local HUD = {}
local function make(class: string, properties: any, parent: Instance?): any
    local item = Instance.new(class)
    for key, value in pairs(properties) do (item :: any)[key] = value end
    item.Parent = parent
    return item
end
local function corners(item: Instance, radius: number)
    make("UICorner", {CornerRadius = UDim.new(0, radius)}, item)
end
function HUD.new(options: any): any
    local player = Players.LocalPlayer
    local function gamepadActive()
        return string.find(UserInputService:GetLastInputType().Name, "Gamepad") ~= nil
    end
    local function touchActive()
        return UserInputService:GetLastInputType() == Enum.UserInputType.Touch or (UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled)
    end
    local function visiblySelectable(target: GuiObject?): boolean
        if not target or not target.Parent or not target.Selectable or not target:IsDescendantOf(player:WaitForChild("PlayerGui")) then return false end
        local current: Instance? = target
        while current do
            if current:IsA("GuiObject") and not current.Visible then return false end
            if current:IsA("ScreenGui") and not current.Enabled then return false end
            current = current.Parent
        end
        return target.AbsoluteSize.X > 0 and target.AbsoluteSize.Y > 0
    end
    local function focusWhenRendered(target: GuiObject?)
        task.spawn(function()
            RunService.RenderStepped:Wait()
            if gamepadActive() and visiblySelectable(target) then GuiService.SelectedObject = target end
        end)
    end
    local colors = options.colors
    local settings = options.settings
    local gui = make("ScreenGui", {Name = "NightfallPresentation", ResetOnSpawn = false, IgnoreGuiInset = false,
        DisplayOrder = 20, ZIndexBehavior = Enum.ZIndexBehavior.Sibling}, player:WaitForChild("PlayerGui"))
    gui.ScreenInsets = Enum.ScreenInsets.CoreUISafeInsets
    local safeCanvas = make("Frame", {Name = "SafeCanvas", BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1)}, gui)
    local function text(parent: Instance, value: string, size: number, color: Color3, position: UDim2, dimensions: UDim2): TextLabel
        return make("TextLabel", {Text = value, BackgroundTransparency = 1, Font = Enum.Font.GothamBold,
            TextSize = size, TextColor3 = color, Position = position, Size = dimensions,
            TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Center}, parent)
    end
    local function button(parent: Instance, value: string, position: UDim2, dimensions: UDim2): TextButton
        local result = make("TextButton", {Text = value, Font = Enum.Font.GothamBold, TextSize = 13,
            TextColor3 = colors.text, BackgroundColor3 = colors.panel, BorderSizePixel = 0,
            Position = position, Size = dimensions, AutoButtonColor = true, Selectable = true}, parent)
        corners(result, 7)
        return result
    end
    local api: any = {}
    local snapshot: any = {}
    local previousStage = 0
    local previousStatus = ""
    local pendingWarnings: {any} = {}
    local partyMarkers: {[Player]: any} = {}
    local dangerMarkers: {any} = {}
    local settingsRows: {any} = {}
    local rememberedSelection: GuiObject? = nil
    local lastBossIdentity = ""
    local cardSerial = 0
    local cardTweens: {Tween} = {}
    local cardExpires = 0
    local touch = UserInputService.TouchEnabled

    local bossPanel = make("Frame", {Name = "BossMeter", Visible = false, AnchorPoint = Vector2.new(0.5, 0),
        Position = UDim2.new(0.5, 0, 0, 112), Size = UDim2.fromOffset(448, 77),
        BackgroundColor3 = colors.ink, BackgroundTransparency = 0.1, BorderSizePixel = 0}, safeCanvas)
    corners(bossPanel, 8)
    local bossStroke = make("UIStroke", {Color = colors.red, Transparency = 0.15, Thickness = 1}, bossPanel)
    local bossRole = text(bossPanel, "BOSS", 10, colors.orange, UDim2.fromOffset(14, 7), UDim2.fromOffset(280, 14))
    local bossName = text(bossPanel, "", 19, colors.text, UDim2.fromOffset(14, 22), UDim2.fromOffset(350, 25))
    bossName.TextTruncate = Enum.TextTruncate.AtEnd
    local bossPhase = text(bossPanel, "PHASE 01", 10, colors.muted, UDim2.fromOffset(353, 12), UDim2.fromOffset(82, 18))
    bossPhase.TextXAlignment = Enum.TextXAlignment.Right
    local bossValue = text(bossPanel, "", 10, colors.muted, UDim2.fromOffset(345, 31), UDim2.fromOffset(90, 18))
    bossValue.TextXAlignment = Enum.TextXAlignment.Right
    local bossTrack = make("Frame", {BackgroundColor3 = colors.panel, BorderSizePixel = 0,
        Position = UDim2.fromOffset(14, 57), Size = UDim2.new(1, -28, 0, 8)}, bossPanel)
    corners(bossTrack, 4)
    local bossTrail = make("Frame", {BackgroundColor3 = colors.text, BackgroundTransparency = 0.28,
        BorderSizePixel = 0, Size = UDim2.fromScale(1, 1)}, bossTrack)
    corners(bossTrail, 4)
    local bossFill = make("Frame", {BackgroundColor3 = colors.red, BorderSizePixel = 0, Size = UDim2.fromScale(1, 1)}, bossTrack)
    corners(bossFill, 4)
    local poiseTrack = make("Frame", {BackgroundColor3 = colors.panel, BorderSizePixel = 0,
        Position = UDim2.fromOffset(14, 70), Size = UDim2.new(1, -28, 0, 3)}, bossPanel)
    local poiseFill = make("Frame", {BackgroundColor3 = colors.orange, BorderSizePixel = 0,
        Size = UDim2.fromScale(0, 1)}, poiseTrack)
    local bossFillTween: Tween? = nil
    local bossTrailTween: Tween? = nil

    local rallyBanner = make("Frame", {Name = "RallyObjective", Visible = false, AnchorPoint = Vector2.new(0.5, 0),
        Position = UDim2.new(0.5, 0, 0, 112), Size = UDim2.fromOffset(448, 64),
        BackgroundColor3 = colors.ink, BackgroundTransparency = 0.08, BorderSizePixel = 0}, safeCanvas)
    corners(rallyBanner, 8)
    make("UIStroke", {Color = colors.cyan, Thickness = 1, Transparency = 0.35}, rallyBanner)
    local rallyTitle = text(rallyBanner, "MOVE RIGHT / RALLY TOGETHER", 15, colors.cyan,
        UDim2.fromOffset(14, 8), UDim2.new(1, -28, 0, 23))
    rallyTitle.TextTruncate = Enum.TextTruncate.AtEnd
    local rallyDetail = text(rallyBanner, "", 10, colors.muted, UDim2.fromOffset(14, 37), UDim2.new(1, -28, 0, 17))
    local guideFolder = make("Folder", {Name = "NightfallLocalGuides"}, workspace)
    local function guidePart(name: string, size: Vector3, color: Color3): BasePart
        return make("Part", {Name = name, Size = size, Color = color, Anchored = true, CanCollide = false,
            CanTouch = false, CanQuery = false, CastShadow = false, Material = Enum.Material.Neon, Transparency = 1}, guideFolder)
    end
    local rallyDisc = guidePart("RallyPoint", Vector3.new(0.08, 5.5, 5.5), colors.cyan)
    rallyDisc.Shape = Enum.PartType.Cylinder
    local rallyBillboard = make("BillboardGui", {Enabled = false, AlwaysOnTop = true,
        Size = UDim2.fromOffset(138, 29), StudsOffsetWorldSpace = Vector3.new(0, 2.5, 0)}, rallyDisc)
    local rallyWorldLabel = text(rallyBillboard, "↓ RALLY HERE", 14, colors.cyan, UDim2.fromScale(0, 0), UDim2.fromScale(1, 1))
    rallyWorldLabel.TextXAlignment = Enum.TextXAlignment.Center; rallyWorldLabel.TextStrokeTransparency = 0.15
    local walkingBoundary = guidePart("CurrentEncounterBoundary", Vector3.new(0.14, 11, 28), colors.red)
    local walkingFloor = guidePart("CurrentEncounterFloorLine", Vector3.new(0.3, 0.09, 28), colors.orange)
    local stageCard = make("Frame", {Name = "StageIntroduction", Visible = false, AnchorPoint = Vector2.new(0.5, 0),
        Position = UDim2.new(0.5, 0, 0.27, 0), Size = UDim2.fromOffset(540, 108),
        BackgroundColor3 = colors.ink, BackgroundTransparency = 0.1, BorderSizePixel = 0}, safeCanvas)
    corners(stageCard, 8)
    local cardChapter = text(stageCard, "CHAPTER 01", 12, colors.cyan, UDim2.fromOffset(22, 12), UDim2.fromOffset(496, 18))
    local cardTitle = text(stageCard, "CITY STREETS", 29, colors.text, UDim2.fromOffset(22, 34), UDim2.fromOffset(496, 37))
    local cardSubtitle = text(stageCard, "", 11, colors.muted, UDim2.fromOffset(22, 79), UDim2.fromOffset(496, 18))
    cardTitle.TextTruncate = Enum.TextTruncate.AtEnd
    local cardScale = make("UIScale", {Scale = 1}, stageCard)
    local subtitles = {"Break the street blockade. Hunt the curse behind the crossing.",
        "Descend below the city. Follow the signal through the empty platforms.",
        "Enter the abandoned works. Shut down the heart of the curtain."}
    local function introduceStage(stage: number, name: string)
        cardSerial += 1
        local serial = cardSerial
        for _, tween in ipairs(cardTweens) do tween:Cancel() end
        cardTweens = {}
        stageCard.Visible = true; stageCard.BackgroundTransparency = 0.1
        for _, label in ipairs({cardChapter, cardTitle, cardSubtitle}) do label.TextTransparency = 0 end
        cardChapter.Text = string.format("CHAPTER %02d / 03", stage)
        cardTitle.Text = string.upper(name)
        cardSubtitle.Text = subtitles[stage] or "Stay together. Break the curtain."
        cardExpires = os.clock() + 3.3
        task.delay(2.5, function()
            if serial ~= cardSerial then return end
            local tween = TweenService:Create(stageCard, TweenInfo.new(0.65), {BackgroundTransparency = 1})
            table.insert(cardTweens, tween); tween:Play()
            for _, label in ipairs({cardChapter, cardTitle, cardSubtitle}) do
                local fade = TweenService:Create(label, TweenInfo.new(0.65), {TextTransparency = 1})
                table.insert(cardTweens, fade); fade:Play()
            end
            task.delay(0.7, function() if serial == cardSerial then stageCard.Visible = false end end)
        end)
    end

    local warning = make("Frame", {Name = "AttackWarning", Visible = false, AnchorPoint = Vector2.new(0.5, 1),
        Position = UDim2.new(0.5, 0, 1, -181), Size = UDim2.fromOffset(382, 48),
        BackgroundColor3 = colors.ink, BackgroundTransparency = 0.08, BorderSizePixel = 0}, safeCanvas)
    corners(warning, 8)
    local warningStroke = make("UIStroke", {Color = colors.red, Thickness = 2}, warning)
    local warningLabel = text(warning, "DODGE", 16, colors.text, UDim2.fromOffset(14, 5), UDim2.new(1, -28, 0, 23))
    warningLabel.TextXAlignment = Enum.TextXAlignment.Center; warningLabel.TextTruncate = Enum.TextTruncate.AtEnd
    local warningDetail = text(warning, "", 10, colors.muted, UDim2.fromOffset(14, 28), UDim2.new(1, -28, 0, 14))
    warningDetail.TextXAlignment = Enum.TextXAlignment.Center
    for index = 1, 4 do
        local marker = make("Frame", {Visible = false, AnchorPoint = Vector2.new(0.5, 0.5), Size = UDim2.fromOffset(124, 43),
            BackgroundColor3 = colors.ink, BackgroundTransparency = 0.1, BorderSizePixel = 0}, safeCanvas)
        corners(marker, 7)
        local stroke = make("UIStroke", {Color = colors.red, Thickness = 1.5}, marker)
        local title = text(marker, "! INCOMING", 12, colors.red, UDim2.fromOffset(7, 3), UDim2.fromOffset(110, 20))
        title.TextXAlignment = Enum.TextXAlignment.Center
        local detail = text(marker, "", 9, colors.text, UDim2.fromOffset(7, 25), UDim2.fromOffset(110, 13))
        detail.TextXAlignment = Enum.TextXAlignment.Center
        dangerMarkers[index] = {frame = marker, title = title, detail = detail, stroke = stroke}
    end

    local rescueButton = button(safeCanvas, "", UDim2.new(0.5, 0, 1, -104), UDim2.fromOffset(204, 50))
    rescueButton.Name = "ShareStock"; rescueButton.AnchorPoint = Vector2.new(0.5, 1); rescueButton.Visible = false
    make("UIStroke", {Color = colors.green, Thickness = 1, Transparency = .15}, rescueButton)
    local rescueLabel = text(rescueButton, "GIVE 1 STOCK / R", 12, colors.green, UDim2.fromOffset(8, 3), UDim2.new(1, -16, 0, 22))
    rescueLabel.TextXAlignment = Enum.TextXAlignment.Center
    local rescueName = text(rescueButton, "", 10, colors.text, UDim2.fromOffset(8, 27), UDim2.new(1, -16, 0, 18))
    rescueName.TextXAlignment = Enum.TextXAlignment.Center; rescueName.TextTruncate = Enum.TextTruncate.AtEnd
    local lastRescueRequest = 0
    local function shareStock()
        if not snapshot.canShareStock or type(snapshot.rescueTarget) ~= "table" then return end
        if UserInputService:GetFocusedTextBox() or player:GetAttribute("MenuOpen") or player:GetAttribute("SettingsOpen") then return end
        if os.clock() - lastRescueRequest < .4 then return end
        lastRescueRequest = os.clock()
        options.actionRemote:FireServer("ShareStock", {targetUserId = snapshot.rescueTarget.userId})
    end
    rescueButton.Activated:Connect(shareStock)
    ContextActionService:BindActionAtPriority("NightfallShareStock", function(_, state)
        if snapshot.status == "Defeat" or snapshot.status == "Victory" or not snapshot.canShareStock then return Enum.ContextActionResult.Pass end
        if UserInputService:GetFocusedTextBox() or player:GetAttribute("MenuOpen") or player:GetAttribute("SettingsOpen") then return Enum.ContextActionResult.Pass end
        if state == Enum.UserInputState.Begin then shareStock() end
        return Enum.ContextActionResult.Sink
    end, false, 3000, Enum.KeyCode.R, Enum.KeyCode.ButtonR3)

    local settingsButton = button(safeCanvas, "SETTINGS  O", UDim2.new(0.5, -54, 0, 20), UDim2.fromOffset(96, 32))
    settingsButton.AnchorPoint = Vector2.new(0.5, 0)
    local shade = make("Frame", {Name = "SettingsModal", Visible = false, Active = true,
        BackgroundColor3 = Color3.new(0, 0, 0), BackgroundTransparency = 0.34, BorderSizePixel = 0,
        Size = UDim2.fromScale(1, 1), ZIndex = 50}, safeCanvas)
    local menu = make("Frame", {BackgroundColor3 = colors.ink, BorderSizePixel = 0,
        AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(456, 424)}, shade)
    corners(menu, 12)
    make("UIStroke", {Color = colors.cyan, Transparency = 0.45, Thickness = 1}, menu)
    text(menu, "MAKE IT YOURS", 24, colors.text, UDim2.fromOffset(24, 18), UDim2.fromOffset(352, 36))
    text(menu, "CO-OP KEEPS RUNNING WHILE THIS MENU IS OPEN", 10, colors.orange,
        UDim2.fromOffset(24, 54), UDim2.fromOffset(406, 19))
    local close = button(menu, "×", UDim2.fromOffset(386, 18), UDim2.fromOffset(46, 42))
    close.TextSize = 23
    local menuScale = make("UIScale", {Scale = 1}, menu)
    local menuContent = make("ScrollingFrame", {Name = "SettingsOptions", BackgroundTransparency = 1, BorderSizePixel = 0,
        Position = UDim2.fromOffset(0, 80), Size = UDim2.new(1, 0, 1, -118), CanvasSize = UDim2.fromOffset(0, 349),
        ScrollBarThickness = 4, ScrollBarImageColor3 = colors.cyan, ScrollingDirection = Enum.ScrollingDirection.Y}, menu)
    local definitions = {
        {key = "shake", name = "CAMERA SHAKE", hint = "0% turns off camera movement", toggle = false},
        {key = "effects", name = "EFFECT DENSITY", hint = "Attack warnings always stay visible", toggle = false},
        {key = "volume", name = "MASTER VOLUME", hint = "Impacts, ambience, and music", toggle = false},
        {key = "ambience", name = "STAGE AMBIENCE", hint = "City, station, and factory sound", toggle = false},
        {key = "music", name = "COMBAT MUSIC", hint = "Score volume; 0% mutes it", toggle = false},
        {key = "highContrast", name = "HIGH-CONTRAST WARNINGS", hint = "Bright outlines; text labels remain", toggle = true},
    }
    local sliderDrag: any = nil
    local function changed()
        if options.onSettingsChanged then options.onSettingsChanged(settings) end
        for _, row in ipairs(settingsRows) do
            local value = settings[row.key]
            if row.toggle then row.value.Text = value and "ON" or "OFF"
            else row.value.Text = string.format("%d%%", math.floor(value * 100 + 0.5)); row.fill.Size = UDim2.fromScale(value, 1) end
        end
    end
    for index, definition in ipairs(definitions) do
        local y = 5 + (index - 1) * 57
        text(menuContent, definition.name, 12, colors.text, UDim2.fromOffset(24, y), UDim2.fromOffset(267, 18))
        text(menuContent, definition.hint, 9, colors.muted, UDim2.fromOffset(24, y + 24), UDim2.fromOffset(226, 16))
        local value = text(menuContent, "", 12, colors.cyan, UDim2.fromOffset(252, y), UDim2.fromOffset(72, 18))
        value.TextXAlignment = Enum.TextXAlignment.Center
        if definition.toggle then
            local toggle = button(menuContent, "TOGGLE", UDim2.fromOffset(352, y - 1), UDim2.fromOffset(80, 42))
            toggle.Activated:Connect(function() settings[definition.key] = not settings[definition.key]; changed() end)
            table.insert(settingsRows, {key = definition.key, toggle = true, value = value, first = toggle, last = toggle})
        else
            local minus = button(menuContent, "−", UDim2.fromOffset(336, y - 1), UDim2.fromOffset(44, 44))
            local plus = button(menuContent, "+", UDim2.fromOffset(388, y - 1), UDim2.fromOffset(44, 44))
            minus.Activated:Connect(function() settings[definition.key] = math.max(0, settings[definition.key] - 0.25); changed() end)
            plus.Activated:Connect(function() settings[definition.key] = math.min(1, settings[definition.key] + 0.25); changed() end)
            local track = button(menuContent, "", UDim2.fromOffset(253, y + 25), UDim2.fromOffset(71, 14))
            track.Selectable = false
            local fill = make("Frame", {BackgroundColor3 = colors.cyan, BorderSizePixel = 0, Size = UDim2.fromScale(1, 1)}, track)
            corners(fill, 4)
            local function drag(input: InputObject)
                local fraction = math.clamp((input.Position.X - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
                settings[definition.key] = math.floor(fraction * 20 + 0.5) / 20; changed()
            end
            track.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
                    sliderDrag = {input = input, drag = drag}; drag(input)
                end
            end)
            table.insert(settingsRows, {key = definition.key, toggle = false, value = value, fill = fill, first = minus, last = plus})
            minus.NextSelectionRight = plus; plus.NextSelectionLeft = minus
        end
    end
    for index, row in ipairs(settingsRows) do
        row.first.NextSelectionUp = index > 1 and settingsRows[index - 1].first or close
        row.last.NextSelectionUp = index > 1 and settingsRows[index - 1].last or close
        row.first.NextSelectionDown = index < #settingsRows and settingsRows[index + 1].first or close
        row.last.NextSelectionDown = index < #settingsRows and settingsRows[index + 1].last or close
    end
    close.NextSelectionDown = settingsRows[1].first
    text(menu, "Settings are remembered for this play session.  O / Back to open.", 10, colors.muted,
        UDim2.new(0, 24, 1, -37), UDim2.fromOffset(406, 23))
    local function setSettingsOpen(open: boolean)
        if open and player:GetAttribute("MenuOpen") then return end
        shade.Visible = open; player:SetAttribute("SettingsOpen", open)
        if open then
            options.actionRemote:FireServer("Block", {held = false})
            rememberedSelection = GuiService.SelectedObject
            if gamepadActive() then focusWhenRendered(settingsRows[1].first) end
        else
            sliderDrag = nil
            if GuiService.SelectedObject and GuiService.SelectedObject:IsDescendantOf(menu) then
                GuiService.SelectedObject = nil
                if visiblySelectable(rememberedSelection) then focusWhenRendered(rememberedSelection) end
            end
        end
    end
    close.Activated:Connect(function() setSettingsOpen(false) end)
    settingsButton.Activated:Connect(function() setSettingsOpen(not shade.Visible) end)
    ContextActionService:BindActionAtPriority("NightfallSettingsToggle", function(_, state)
        if UserInputService:GetFocusedTextBox() then return Enum.ContextActionResult.Pass end
        if state == Enum.UserInputState.Begin then setSettingsOpen(not shade.Visible) end
        return Enum.ContextActionResult.Sink
    end, false, 3000, Enum.KeyCode.O, Enum.KeyCode.ButtonSelect)
    ContextActionService:BindActionAtPriority("NightfallSettingsBack", function(_, state)
        if not shade.Visible then return Enum.ContextActionResult.Pass end
        if state == Enum.UserInputState.Begin then setSettingsOpen(false) end
        return Enum.ContextActionResult.Sink
    end, false, 3001, Enum.KeyCode.ButtonB)
    UserInputService.InputChanged:Connect(function(input)
        if sliderDrag and (input == sliderDrag.input or input.UserInputType == Enum.UserInputType.MouseMovement) then sliderDrag.drag(input) end
    end)
    UserInputService.InputEnded:Connect(function(input)
        if sliderDrag and (input == sliderDrag.input or input.UserInputType == Enum.UserInputType.MouseButton1) then sliderDrag = nil end
    end)
    UserInputService.WindowFocusReleased:Connect(function() sliderDrag = nil end)
    UserInputService.TextBoxFocused:Connect(function() sliderDrag = nil end)
    player:GetAttributeChangedSignal("MenuOpen"):Connect(function() if player:GetAttribute("MenuOpen") then setSettingsOpen(false) end end)
    changed()

    local lobbyShade = make("Frame", {Name = "ReadyLobby", Visible = false, Active = false, ZIndex = 35,
        BackgroundColor3 = colors.ink, BackgroundTransparency = 0.32, BorderSizePixel = 0, Size = UDim2.fromScale(1, 1)}, safeCanvas)
    local lobby = make("Frame", {BackgroundColor3 = colors.ink, BackgroundTransparency = 0.04, BorderSizePixel = 0,
        AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(680, 490)}, lobbyShade)
    corners(lobby, 14)
    make("UIStroke", {Color = colors.cyan, Transparency = 0.32, Thickness = 1}, lobby)
    local lobbyScale = make("UIScale", {Scale = 1}, lobby)
    text(lobby, "CURTAIN BREAK", 31, colors.text, UDim2.fromOffset(24, 15), UDim2.fromOffset(470, 40))
    text(lobby, "PICK A FIGHTER. BREAK THE CURTAIN TOGETHER.", 12, colors.cyan, UDim2.fromOffset(25, 57), UDim2.fromOffset(575, 18))
    local lobbySettings = button(lobby, "SETTINGS", UDim2.new(1, -121, 0, 22), UDim2.fromOffset(97, 39))
    lobbySettings.Activated:Connect(function() setSettingsOpen(true) end)
    local lobbyContent = make("ScrollingFrame", {BackgroundTransparency = 1, BorderSizePixel = 0,
        Position = UDim2.fromOffset(20, 86), Size = UDim2.new(1, -40, 1, -174),
        CanvasSize = UDim2.fromOffset(0, 309), ScrollBarThickness = 4, ScrollBarImageColor3 = colors.cyan,
        ScrollingDirection = Enum.ScrollingDirection.Y}, lobby)
    local heroDefinitions = {}
    for _, id in ipairs(Config.CharacterOrder) do
        local spec = Config.Characters[id]
        table.insert(heroDefinitions, {id = id, name = spec.Name, role = spec.Title,
            special = spec.SpecialName, tip = spec.Tip, color = spec.Color})
    end
    local lobbyHeroButtons: {[string]: any} = {}
    local lobbyAccept: {[GuiObject]: () -> ()} = {}
    for index, hero in ipairs(heroDefinitions) do
        local card = button(lobbyContent, "", UDim2.fromOffset((index - 1) * 212, 0), UDim2.fromOffset(204, 133))
        local stroke = make("UIStroke", {Color = hero.color, Transparency = 0.7, Thickness = 2}, card)
        local title = text(card, hero.name:upper(), 18, hero.color, UDim2.fromOffset(13, 12), UDim2.fromOffset(181, 26))
        text(card, hero.role, 9, colors.muted, UDim2.fromOffset(14, 43), UDim2.fromOffset(180, 17))
        text(card, hero.special, 10, colors.text, UDim2.fromOffset(14, 67), UDim2.fromOffset(180, 19))
        local tip = text(card, hero.tip, 10, colors.muted, UDim2.fromOffset(14, 89), UDim2.fromOffset(175, 31))
        tip.TextWrapped = true
        local function choose() options.actionRemote:FireServer("SelectCharacter", {hero = hero.id}) end
        card.Activated:Connect(choose); lobbyAccept[card] = choose
        lobbyHeroButtons[hero.id] = {button = card, stroke = stroke, title = title}
    end
    text(lobbyContent, "HOW TO SURVIVE", 13, colors.text, UDim2.fromOffset(3, 152), UDim2.fromOffset(300, 21))
    local instructions = text(lobbyContent, "MOVE  A/D + W/S   ·   JUMP  SPACE\nLIGHT  J   ·   HEAVY  K   ·   SPECIAL  L\nDASH  Q   ·   HOLD GUARD  F   ·   RECOVER  E", 11, colors.cyan,
        UDim2.fromOffset(3, 180), UDim2.fromOffset(345, 73))
    instructions.TextYAlignment = Enum.TextYAlignment.Top
    local lesson = text(lobbyContent, "Higher damage % means bigger launches.\nStocks are lives. Stay near your squad.\nRed markers: move out. Cyan markers: jump.", 11, colors.muted,
        UDim2.fromOffset(353, 180), UDim2.fromOffset(280, 73))
    lesson.TextWrapped = true; lesson.TextYAlignment = Enum.TextYAlignment.Top
    text(lobbyContent, "3 CHAPTERS   /   CITY → STATION → FACTORY   /   6 ELITE CURSES", 11, colors.text,
        UDim2.fromOffset(3, 275), UDim2.fromOffset(628, 24))
    local readyCount = text(lobby, "0 / 1 READY", 18, colors.text, UDim2.new(0, 26, 1, -77), UDim2.fromOffset(400, 26))
    local readyHint = text(lobby, "Everyone must ready up. No forced timer.", 10, colors.muted,
        UDim2.new(0, 26, 1, -47), UDim2.fromOffset(390, 18))
    local readyButton = button(lobby, "READY / ENTER", UDim2.new(1, -230, 1, -78), UDim2.fromOffset(204, 51))
    readyButton.BackgroundColor3 = colors.cyan; readyButton.TextColor3 = colors.ink; readyButton.TextSize = 16
    local function ready()
        if snapshot.status ~= "Waiting" or player:GetAttribute("MenuOpen") or player:GetAttribute("SettingsOpen") then return end
        options.actionRemote:FireServer("Ready", {ready = not snapshot.ready})
    end
    readyButton.Activated:Connect(ready); lobbyAccept[readyButton] = ready
    lobbyAccept[lobbySettings] = function() setSettingsOpen(true) end
    ContextActionService:BindActionAtPriority("NightfallReady", function(_, state)
        if snapshot.status ~= "Waiting" or player:GetAttribute("MenuOpen") or player:GetAttribute("SettingsOpen") or UserInputService:GetFocusedTextBox() then return Enum.ContextActionResult.Pass end
        if state == Enum.UserInputState.Begin then ready() end
        return Enum.ContextActionResult.Sink
    end, false, 3100, Enum.KeyCode.Return, Enum.KeyCode.ButtonStart)
    ContextActionService:BindActionAtPriority("NightfallLobbyAccept", function(_, state)
        if snapshot.status ~= "Waiting" or player:GetAttribute("MenuOpen") or player:GetAttribute("SettingsOpen") then return Enum.ContextActionResult.Pass end
        local selected = GuiService.SelectedObject
        local accept = selected and lobbyAccept[selected]
        if not accept then return Enum.ContextActionResult.Pass end
        if state == Enum.UserInputState.Begin then accept() end
        return Enum.ContextActionResult.Sink
    end, false, 3101, Enum.KeyCode.ButtonA)
    for index, hero in ipairs(heroDefinitions) do
        local card = lobbyHeroButtons[hero.id].button
        card.NextSelectionLeft = lobbyHeroButtons[heroDefinitions[(index - 2) % #heroDefinitions + 1].id].button
        card.NextSelectionRight = lobbyHeroButtons[heroDefinitions[index % #heroDefinitions + 1].id].button
        card.NextSelectionDown = readyButton; card.NextSelectionUp = lobbySettings
    end
    readyButton.NextSelectionUp = lobbyHeroButtons[Config.CharacterOrder[1]].button
    lobbySettings.NextSelectionDown = lobbyHeroButtons[Config.CharacterOrder[#Config.CharacterOrder]].button
    local results = make("Frame", {Name = "RunStatistics", BackgroundColor3 = colors.panel, BorderSizePixel = 0,
        Position = UDim2.fromOffset(24, 139), Size = UDim2.fromOffset(372, 108)}, options.ending)
    corners(results, 8)
    local statLabels: {[string]: TextLabel} = {}
    local statDefinitions = {{"kills", "CURSES DEFEATED"}, {"damageDealt", "DAMAGE DEALT"}, {"damageTaken", "DAMAGE TAKEN"}, {"duration", "RUN TIME"}}
    for index, entry in ipairs(statDefinitions) do
        local x = (index - 1) % 2 * 181 + 14
        local y = math.floor((index - 1) / 2) * 51 + 6
        text(results, entry[2], 9, colors.muted, UDim2.fromOffset(x, y), UDim2.fromOffset(166, 17))
        statLabels[entry[1]] = text(results, "—", 20, colors.text, UDim2.fromOffset(x, y + 17), UDim2.fromOffset(165, 26))
    end
    local resultCheckpoint = text(options.ending, "", 10, colors.muted, UDim2.fromOffset(24, 252), UDim2.fromOffset(372, 22))
    resultCheckpoint.TextXAlignment = Enum.TextXAlignment.Center

    local function safeDimensions(camera: Camera): (number, number)
        local size = safeCanvas.AbsoluteSize
        return size.X > 100 and size.X or camera.ViewportSize.X, size.Y > 100 and size.Y or camera.ViewportSize.Y
    end
    local function project(camera: Camera, position: Vector3): (Vector3, boolean)
        local point, visible = camera:WorldToViewportPoint(position)
        local origin = safeCanvas.AbsolutePosition
        return Vector3.new(point.X - origin.X, point.Y - origin.Y, point.Z), visible
    end
    function api.resize()
        local camera = workspace.CurrentCamera
        if not camera then return end
        local width, height = safeDimensions(camera)
        touch = UserInputService.TouchEnabled
        local compact = width < 650
        lobbyScale.Scale = math.min(1, (width - 24) / 680)
        lobby.Size = UDim2.fromOffset(680, math.min(490, (height - 24) / lobbyScale.Scale))
        settingsButton.Position = UDim2.new(0.5, -54, 0, touch and 12 or (compact and 92 or 20))
        settingsButton.Size = UDim2.fromOffset(96, touch and 44 or 32)
        rescueButton.Position = UDim2.new(0.5, 0, 1, touch and -18 or -104)
        rescueLabel.Text = gamepadActive() and "GIVE 1 STOCK / R3" or touch and "GIVE 1 STOCK" or "GIVE 1 STOCK / R"
        bossPanel.Position = UDim2.new(0.5, 0, 0, touch and 64 or (compact and 134 or 112))
        bossPanel.Size = UDim2.fromOffset(math.min(touch and 260 or 448, width - 28), touch and 57 or 77)
        rallyBanner.Position = bossPanel.Position
        rallyBanner.Size = UDim2.fromOffset(math.min(touch and 260 or 448, width - 28), touch and 50 or 64)
        rallyTitle.TextSize = touch and 11 or 15; rallyTitle.Position = UDim2.fromOffset(14, touch and 4 or 8)
        rallyDetail.TextSize = touch and 9 or 10; rallyDetail.Position = UDim2.fromOffset(14, touch and 29 or 37)
        bossName.Size = UDim2.new(1, -126, 0, 25); bossName.TextSize = touch and 14 or 19
        bossName.Position = UDim2.fromOffset(14, touch and 14 or 22)
        bossRole.TextSize = touch and 8 or 10; bossRole.Position = UDim2.fromOffset(14, touch and 2 or 7)
        bossRole.Size = UDim2.new(1, -28, 0, 14); bossRole.TextTruncate = Enum.TextTruncate.AtEnd
        bossPhase.Position = UDim2.new(1, -96, 0, touch and 14 or 12)
        bossValue.Position = UDim2.new(1, -104, 0, touch and 28 or 31)
        bossTrack.Position = UDim2.fromOffset(14, touch and 43 or 57)
        bossTrack.Size = UDim2.new(1, -28, 0, touch and 5 or 8)
        poiseTrack.Position = UDim2.fromOffset(14, touch and 51 or 70)
        poiseTrack.Size = UDim2.new(1, -28, 0, touch and 2 or 3)
        menuScale.Scale = math.min(1, (width - 20) / 456)
        menu.Size = UDim2.fromOffset(456, math.min(424, (height - 20) / menuScale.Scale))
        cardScale.Scale = math.min(1, (width - 28) / 540)
        warning.Size = UDim2.fromOffset(math.min(touch and 260 or 382, width - 28), touch and 38 or 48)
        warning.Position = touch and UDim2.new(0.5, 0, 0, bossPanel.Visible and 163 or 106) or UDim2.new(0.5, 0, 1, -181)
        warningLabel.TextSize = touch and 12 or 16; warningLabel.Position = UDim2.fromOffset(14, touch and 1 or 5)
        warningDetail.TextSize = touch and 8 or 10; warningDetail.Position = UDim2.fromOffset(14, touch and 22 or 28)
        settingsButton.Text = gamepadActive() and "SETTINGS BACK" or touch and "SETTINGS" or "SETTINGS  O"
    end
    function api.updateSnapshot(state: any)
        snapshot = state
        local stage = tonumber(state.stage) or 1
        if state.status ~= "Waiting" and (stage ~= previousStage or previousStatus == "Waiting" or previousStatus == "Defeat" or previousStatus == "Victory") then
            introduceStage(stage, state.stageName or ({"CITY STREETS", "ABANDONED STATION", "ABANDONED FACTORY"})[stage] or "CURTAIN BREAK")
            previousStage = stage
        end
        local enteringLobby = state.status == "Waiting" and previousStatus ~= "Waiting"
        lobbyShade.Visible = state.status == "Waiting"
        if lobbyShade.Visible then
            stageCard.Visible = false
            local controller = gamepadActive()
            readyCount.Text = string.format("%d / %d READY", state.readyCount or 0, math.max(1, state.playersTotal or 1))
            readyButton.Text = state.ready and "READY / CANCEL" or (controller and "READY / START" or "READY / ENTER")
            readyButton.BackgroundColor3 = state.ready and colors.green or colors.cyan
            readyHint.Text = state.ready and "Waiting for the rest of your squad..." or "Everyone must ready up. No forced timer."
            if controller then instructions.Text = "MOVE  LEFT STICK   ·   JUMP  A\nLIGHT  X   ·   HEAVY  Y   ·   SPECIAL  B\nDASH  LT   ·   HOLD GUARD  LB   ·   RECOVER  RB"
            elseif touchActive() then instructions.Text = "MOVE  LEFT THUMB PAD   ·   JUMP BUTTON\nTAP  LIGHT / HEAVY / SPECIAL\nDASH TO EVADE   ·   HOLD BLOCK TO GUARD"
            else instructions.Text = "MOVE  A/D + W/S   ·   JUMP  SPACE\nLIGHT  J   ·   HEAVY  K   ·   SPECIAL  L\nDASH  Q   ·   HOLD GUARD  F   ·   RECOVER  E" end
            for name, card in pairs(lobbyHeroButtons) do
                local selected = name == state.hero
                card.stroke.Transparency = selected and 0 or 0.7
                card.button.BackgroundColor3 = selected and Color3.fromRGB(35, 51, 64) or colors.panel
                card.title.Text = string.upper(Config.Characters[name].Name) .. (selected and "  ✓" or "")
            end
            if enteringLobby and controller and not player:GetAttribute("MenuOpen") and not player:GetAttribute("SettingsOpen") then focusWhenRendered(readyButton) end
        elseif GuiService.SelectedObject and GuiService.SelectedObject:IsDescendantOf(lobby) then GuiService.SelectedObject = nil end
        previousStatus = state.status
        local boss = state.boss
        bossPanel.Visible = type(boss) == "table" and state.status ~= "Victory" and state.status ~= "Defeat"
        if bossPanel.Visible then
            local ratio = math.clamp(1 - (boss.percent or 0) / math.max(1, boss.threshold or 1), 0, 1)
            local identity = tostring(boss.name) .. tostring(stage)
            local role = boss.role == "Miniboss" and "MINIBOSS" or "STAGE BOSS"
            local color = settings.highContrast and colors.orange or (boss.role == "Miniboss" and colors.orange or colors.red)
            bossRole.Text = boss.exposed and (role .. " / EXPOSED — PUNISH NOW") or boss.armored and (role .. " / ARMORED — BUILD STAGGER") or (role .. " / BREAK THE CURSE")
            bossRole.TextColor3 = boss.exposed and colors.green or colors.orange
            poiseFill.Size = UDim2.fromScale(math.clamp((boss.poise or 0) / math.max(1, boss.poiseLimit or 1), 0, 1), 1)
            bossName.Text = string.upper(boss.name or boss.kind or "CURSE")
            bossPhase.Text = string.format("PHASE %02d", boss.phase or 1)
            bossValue.Text = string.format("%d / %d", math.max(0, math.ceil((boss.threshold or 0) - (boss.percent or 0))), math.ceil(boss.threshold or 0))
            bossFill.BackgroundColor3 = color; bossStroke.Color = color
            if bossFillTween then bossFillTween:Cancel() end
            if bossTrailTween then bossTrailTween:Cancel() end
            if identity ~= lastBossIdentity then bossFill.Size = UDim2.fromScale(ratio, 1); bossTrail.Size = bossFill.Size
            else
                bossFillTween = TweenService:Create(bossFill, TweenInfo.new(0.12), {Size = UDim2.fromScale(ratio, 1)})
                bossTrailTween = TweenService:Create(bossTrail, TweenInfo.new(0.6), {Size = UDim2.fromScale(ratio, 1)})
                bossFillTween:Play(); bossTrailTween:Play()
            end
            lastBossIdentity = identity
        end
        local stats = state.runStats or {}
        for key, label in pairs(statLabels) do
            local value = stats[key]
            if type(value) ~= "number" then label.Text = "—"
            elseif key == "duration" then label.Text = string.format("%02d:%02d", math.floor(value / 60), math.floor(value % 60))
            else label.Text = tostring(math.floor(value)) end
        end
        resultCheckpoint.Text = state.status == "Victory" and "ALL THREE CHAPTERS COMPLETE" or string.upper(state.checkpointLabel or state.stageName or "")
        if state.status == "Defeat" or state.status == "Victory" then
            warning.Visible = false; pendingWarnings = {}; stageCard.Visible = false
            setSettingsOpen(false)
        end
    end
    function api.cancelWarnings(targetModel: Model)
        for index = #pendingWarnings, 1, -1 do
            if pendingWarnings[index].event.targetModel == targetModel then table.remove(pendingWarnings, index) end
        end
    end
    function api.telegraph(event: any)
        if typeof(event.position) ~= "Vector3" then return end
        local duration = math.clamp(tonumber(event.duration) or 0.6, 0.1, 5)
        if #pendingWarnings >= 12 then table.remove(pendingWarnings, 1) end
        table.insert(pendingWarnings, {event = event, finish = os.clock() + duration, duration = duration})
        -- Critical attack warnings immediately dismiss the decorative stage title.
        stageCard.Visible = false
    end
    function api.updateSpatial(camera: Camera, localRoot: BasePart?)
        local width, height = safeDimensions(camera)
        local now = os.clock()
        rescueButton.Visible = snapshot.canShareStock == true and type(snapshot.rescueTarget) == "table"
            and not player:GetAttribute("MenuOpen") and not player:GetAttribute("SettingsOpen")
        if rescueButton.Visible then rescueName.Text = "REVIVE " .. string.upper(snapshot.rescueTarget.name or "TEAMMATE") end
        local rallyActive = (snapshot.status == "Traverse" or snapshot.status == "Advance") and type(snapshot.targetX) == "number"
        rallyBanner.Visible = rallyActive
        rallyDisc.Transparency = rallyActive and 0.45 or 1; rallyBillboard.Enabled = rallyActive
        if rallyActive then
            rallyDisc.CFrame = CFrame.new(snapshot.targetX, 0.2, 0) * CFrame.Angles(0, 0, math.pi / 2)
            rallyTitle.Text = snapshot.status == "Advance" and "CHAPTER CLEAR / RALLY AT THE EXIT" or "MOVE RIGHT / RALLY FOR THE NEXT FIGHT"
            local readyAtTarget, living = 0, 0
            for _, teammate in ipairs(Players:GetPlayers()) do
                local character = teammate.Character
                local part = character and character:FindFirstChild("HumanoidRootPart")
                if part and part:IsA("BasePart") and not character:GetAttribute("Downed") then
                    living += 1
                    if part.Position.X >= snapshot.targetX then readyAtTarget += 1 end
                end
            end
            local distance = localRoot and math.max(0, math.ceil(snapshot.targetX - localRoot.Position.X)) or 0
            rallyDetail.Text = string.format("%d / %d AT THE MARKER  ·  %s", readyAtTarget, math.max(1, living), distance > 0 and (tostring(distance) .. " STUDS RIGHT →") or "WAIT FOR YOUR SQUAD")
        end
        local boundaryVisible = snapshot.status == "Combat" and type(snapshot.walkingMaxX) == "number"
        walkingBoundary.Transparency = boundaryVisible and 0.94 or 1; walkingFloor.Transparency = boundaryVisible and 0.4 or 1
        if boundaryVisible then
            walkingBoundary.Position = Vector3.new(snapshot.walkingMaxX, 5.5, 0)
            walkingFloor.Position = Vector3.new(snapshot.walkingMaxX, 0.14, 0)
        end
        if cardExpires > 0 and now > cardExpires then stageCard.Visible = false end
        local highest: any = nil
        local highestFinish = math.huge
        local markerIndex = 0
        for index = #pendingWarnings, 1, -1 do
            local item = pendingWarnings[index]
            if now >= item.finish then table.remove(pendingWarnings, index)
            elseif localRoot then
                local event = item.event
                local position = event.position
                local delta = localRoot.Position - position
                local radius = tonumber(event.radius) or 6
                local size = event.size
                local danger = false
                if event.shape == "Circle" then danger = Vector2.new(delta.X, delta.Z).Magnitude <= radius + 1.5
                elseif typeof(size) == "Vector3" then danger = math.abs(delta.X) <= size.X / 2 + 1.5 and math.abs(delta.Z) <= size.Z / 2 + 1.5
                else
                    local centerX = position.X + (event.heavy and 0 or (event.direction or 1) * radius * 0.5)
                    danger = math.abs(localRoot.Position.X - centerX) <= (event.heavy and radius or radius * 0.5) + 1.5 and math.abs(delta.Z) <= (event.heavy and 12.5 or 3.5) + 1.5
                end
                local distance = Vector2.new(delta.X, delta.Z).Magnitude
                if danger and item.finish < highestFinish then highest = item; highestFinish = item.finish end
                local screen, visible = project(camera, position)
                if (not visible or screen.X < 20 or screen.X > width - 20) and markerIndex < #dangerMarkers and distance < 130 then
                    markerIndex += 1
                    local marker = dangerMarkers[markerIndex]
                    local right = position.X >= localRoot.Position.X
                    marker.frame.Visible = true
                    marker.frame.Position = UDim2.fromOffset(right and width - 76 or 76, math.clamp(screen.Y, 170, math.max(171, height - 180)))
                    marker.title.Text = right and "INCOMING  >" or "<  INCOMING"
                    marker.detail.Text = string.format("%s / %.1fs", event.jumpable and "JUMP" or "DODGE", math.max(0, item.finish - now))
                    local color = settings.highContrast and colors.orange or (event.jumpable and colors.cyan or colors.red)
                    marker.title.TextColor3 = color; marker.stroke.Color = color
                end
            end
        end
        for index = markerIndex + 1, #dangerMarkers do dangerMarkers[index].frame.Visible = false end
        if touch then warning.Position = UDim2.new(0.5, 0, 0, bossPanel.Visible and 163 or 106) end
        warning.Visible = highest ~= nil and snapshot.status ~= "Defeat" and snapshot.status ~= "Victory"
        if highest then
            local event = highest.event
            local action = event.jumpable and "JUMP" or "DODGE"
            local mechanic = tostring(event.mechanic or event.enemy or "INCOMING ATTACK"):gsub("_", " ")
            warningLabel.Text = action .. " / " .. string.upper(mechanic)
            warningDetail.Text = string.format(event.jumpable and "GROUND HAZARD / STAY ABOVE IT · %.1fs" or "LEAVE THE MARKED AREA · %.1fs", math.max(0, highest.finish - now))
            warningStroke.Color = settings.highContrast and colors.orange or (event.jumpable and colors.cyan or colors.red)
        end
        for teammate, marker in pairs(partyMarkers) do
            if not teammate.Parent then marker.frame:Destroy(); partyMarkers[teammate] = nil else marker.frame.Visible = false end
        end
        for _, teammate in ipairs(Players:GetPlayers()) do
            if teammate ~= player and teammate.Character then
                local character = teammate.Character
                local part = character:FindFirstChild("HumanoidRootPart")
                local hum = character:FindFirstChildOfClass("Humanoid")
                if part and part:IsA("BasePart") and hum and hum.Health > 0 then
                    local marker = partyMarkers[teammate]
                    if not marker then
                        local frame = make("Frame", {Visible = false, AnchorPoint = Vector2.new(0.5, 0.5), Size = UDim2.fromOffset(122, 39),
                            BackgroundColor3 = colors.ink, BackgroundTransparency = 0.18, BorderSizePixel = 0}, safeCanvas)
                        corners(frame, 6)
                        local name = text(frame, "", 11, colors.cyan, UDim2.fromOffset(7, 1), UDim2.fromOffset(108, 18))
                        name.TextTruncate = Enum.TextTruncate.AtEnd; name.TextXAlignment = Enum.TextXAlignment.Center
                        local info = text(frame, "", 9, colors.text, UDim2.fromOffset(7, 19), UDim2.fromOffset(108, 16))
                        info.TextXAlignment = Enum.TextXAlignment.Center
                        marker = {frame = frame, name = name, info = info}; partyMarkers[teammate] = marker
                    end
                    local screen, visible = project(camera, part.Position + Vector3.new(0, 4, 0))
                    local offscreen = not visible or screen.X < 35 or screen.X > width - 35
                    marker.frame.Visible = offscreen
                    if offscreen then
                        local right = not localRoot or part.Position.X > localRoot.Position.X
                        marker.frame.Position = UDim2.fromOffset(right and width - 75 or 75, math.clamp(screen.Y + 45, 213, math.max(214, height - 134)))
                        marker.name.Text = (right and "" or "< ") .. teammate.DisplayName .. (right and " >" or "")
                        marker.info.Text = string.format("%d%% / %d STOCKS", math.floor(character:GetAttribute("Percent") or 0), character:GetAttribute("Stocks") or 0)
                    end
                end
            end
        end
    end
    UserInputService.LastInputTypeChanged:Connect(function()
        api.resize()
        if snapshot.status == "Waiting" then api.updateSnapshot(snapshot) end
        if gamepadActive() then
            if shade.Visible then focusWhenRendered(settingsRows[1].first)
            elseif lobbyShade.Visible and not player:GetAttribute("MenuOpen") then focusWhenRendered(readyButton) end
        else
            local selected = GuiService.SelectedObject
            if selected and (selected:IsDescendantOf(menu) or selected:IsDescendantOf(lobby)) then GuiService.SelectedObject = nil end
        end
    end)
    api.resize()
    safeCanvas:GetPropertyChangedSignal("AbsoluteSize"):Connect(api.resize)
    UserInputService:GetPropertyChangedSignal("TouchEnabled"):Connect(api.resize)
    return api
end
return HUD