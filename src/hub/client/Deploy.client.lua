--!strict
-- Hub presentation sends intents only. The server owns parties, unlocks, queue state and teleports.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GuiService = game:GetService("GuiService")
local UserInputService = game:GetService("UserInputService")
local ContextActionService = game:GetService("ContextActionService")
local ProximityPromptService = game:GetService("ProximityPromptService")
local SocialService = game:GetService("SocialService")
local player = Players.LocalPlayer
local Config = require(ReplicatedStorage:WaitForChild("Nightfall"):WaitForChild("Shared"):WaitForChild("Config"))
local remotes = ReplicatedStorage:WaitForChild("HubRemotes")
local request = remotes:WaitForChild("Request") :: RemoteEvent
local stateRemote = remotes:WaitForChild("State") :: RemoteEvent
local ink = Color3.fromRGB(14, 22, 33)
local panelColor = Color3.fromRGB(27, 40, 55)
local light = Color3.fromRGB(235, 245, 247)
local muted = Color3.fromRGB(160, 181, 196)
local teal = Color3.fromRGB(111, 222, 217)
local gold = Color3.fromRGB(238, 187, 95)
local state: any = {players = {}, invites = {}, unlocks = {Normal = true}, message = "Connecting to the refuge..."}
local difficulty = "Normal"
local selectedHeat: {[string]: boolean} = {}
local selectedHero = Config.CharacterOrder[1]
local mode = "QuickMatch"
local heatDefinitions = {
    {id="Frenzy",name="FRENZY",description="One extra attack token",reward=10},
    {id="ShortFuse",name="SHORT FUSE",description="Faster enemy warnings",reward=15},
    {id="IronHide",name="IRON HIDE",description="Tougher ordinary enemies",reward=10},
    {id="NoSafetyNet",name="NO SAFETY NET",description="No mid-district checkpoint",reward=20},
    {id="OneLife",name="ONE LIFE",description="One stock; revive stays available",reward=35},
    {id="MutatedElites",name="MUTATED ELITES",description="An extra phase-two boss move",reward=15},
}
local function make(class: string, properties: any, parent: Instance): any
    local object = Instance.new(class)
    for key, value in pairs(properties) do (object :: any)[key] = value end
    object.Parent = parent
    return object
end
local gui = make("ScreenGui", {Name="CurtainBreakDeploy", ResetOnSpawn=false, DisplayOrder=20,
    IgnoreGuiInset=false, ZIndexBehavior=Enum.ZIndexBehavior.Sibling}, player:WaitForChild("PlayerGui"))
gui.ScreenInsets = Enum.ScreenInsets.CoreUISafeInsets
local safe = make("Frame", {Name="SafeCanvas", BackgroundTransparency=1, Size=UDim2.fromScale(1,1)}, gui)
local function label(parent: Instance, text: string, size: number, color: Color3): TextLabel
    return make("TextLabel", {BackgroundTransparency=1, Text=text, TextSize=size, TextColor3=color,
        Font=Enum.Font.GothamBold, TextXAlignment=Enum.TextXAlignment.Left, TextWrapped=true}, parent)
end
local function button(parent: Instance, text: string): TextButton
    local b = make("TextButton", {Text=text, TextSize=13, TextColor3=light, Font=Enum.Font.GothamBold,
        BackgroundColor3=panelColor, BorderSizePixel=0, AutoButtonColor=true, TextWrapped=true,
        Selectable=true, Size=UDim2.new(1,0,0,48)}, parent)
    make("UICorner", {CornerRadius=UDim.new(0,8)}, b)
    make("UIStroke", {Color=teal, Transparency=.72, Thickness=1}, b)
    return b
end
local openButton = button(safe, "DEPLOY & PARTY")
openButton.Name="OpenDeploy"; openButton.Position=UDim2.fromOffset(16,16); openButton.Size=UDim2.fromOffset(180,48)
local shade = make("Frame", {Name="DeployShade", BackgroundColor3=Color3.new(), BackgroundTransparency=.3,
    Size=UDim2.fromScale(1,1), Visible=true}, safe)
local panel = make("Frame", {Name="DeployPanel", BackgroundColor3=ink, BorderSizePixel=0,
    AnchorPoint=Vector2.new(.5,.5), Position=UDim2.fromScale(.5,.5)}, shade)
make("UICorner", {CornerRadius=UDim.new(0,12)}, panel)
local heading = label(panel,"ASHGATE REFUGE",22,light)
heading.Position=UDim2.fromOffset(16,10); heading.Size=UDim2.new(1,-80,0,28)
local subtitle = label(panel,"BUILD YOUR SQUAD. CHOOSE YOUR CHALLENGE.",10,teal)
subtitle.Position=UDim2.fromOffset(17,39); subtitle.Size=UDim2.new(1,-80,0,22)
local close = button(panel,"×"); close.Name="CloseDeploy"; close.Position=UDim2.new(1,-60,0,12); close.Size=UDim2.fromOffset(44,44); close.TextSize=25
local scroll = make("ScrollingFrame", {Name="DeployChoices", BackgroundTransparency=1, BorderSizePixel=0,
    Position=UDim2.fromOffset(14,74), Size=UDim2.new(1,-28,1,-190), CanvasSize=UDim2.new(),
    AutomaticCanvasSize=Enum.AutomaticSize.Y, ScrollBarThickness=5, ScrollBarImageColor3=teal,
    ScrollingDirection=Enum.ScrollingDirection.Y}, panel)
make("UIListLayout", {Padding=UDim.new(0,14),SortOrder=Enum.SortOrder.LayoutOrder}, scroll)
make("UIPadding", {PaddingRight=UDim.new(0,8),PaddingBottom=UDim.new(0,12)}, scroll)
local order=0
local function section(title: string, height: number): Frame
    order += 1
    local frame=make("Frame",{Name=title,BackgroundTransparency=1,Size=UDim2.new(1,0,0,height),LayoutOrder=order},scroll)
    local titleLabel=label(frame,title,12,muted); titleLabel.Size=UDim2.new(1,0,0,23)
    return frame
end
local heroSection=section("YOUR FIGHTER",82)
local heroButtons: {[string]: TextButton}={}
for index,id in ipairs(Config.CharacterOrder) do
    local b=button(heroSection,Config.Characters[id].Name.."\n"..Config.Characters[id].Title)
    b.Name="Hero_"..id; b.Position=UDim2.new((index-1)/3,3,0,28); b.Size=UDim2.new(1/3,-6,0,52); b.TextSize=11
    heroButtons[id]=b
    b.Activated:Connect(function() request:FireServer("SelectHero",{hero=id}) end)
end
local partySection=section("PARTY",140)
local partyText=label(partySection,"Your squad: just you",13,light); partyText.Position=UDim2.fromOffset(0,26); partyText.Size=UDim2.new(1,0,0,56)
local leave=button(partySection,"LEAVE PARTY"); leave.Name="LeaveParty"; leave.Position=UDim2.new(.5,3,0,88); leave.Size=UDim2.new(.5,-6,0,48); leave.TextSize=10
leave.Activated:Connect(function() if leave.Active then request:FireServer("Leave",{}) end end)
local friends=button(partySection,"INVITE FRIENDS"); friends.Name="InviteFriends"; friends.Position=UDim2.new(0,3,0,88); friends.Size=UDim2.new(.5,-6,0,48); friends.TextSize=10
friends.Activated:Connect(function()
    local ok=pcall(function() SocialService:PromptGameInvite(player) end)
    if not ok then state.message="Friend invitations are unavailable here. Invite someone in this refuge below." end
end)
local rosterSection=section("IN THIS REFUGE / PARTY INVITES",28)
local roster=make("Frame",{BackgroundTransparency=1,Position=UDim2.fromOffset(0,28),Size=UDim2.new(1,0,0,0),AutomaticSize=Enum.AutomaticSize.Y},rosterSection)
local rosterLayout=make("UIListLayout",{Padding=UDim.new(0,6),SortOrder=Enum.SortOrder.LayoutOrder},roster)
rosterLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function() rosterSection.Size=UDim2.new(1,0,0,28+rosterLayout.AbsoluteContentSize.Y) end)
local matchSection=section("DEPLOYMENT",82)
local solo=button(matchSection,"SOLO RUN"); solo.Name="SoloMode"; solo.Position=UDim2.new(0,3,0,28); solo.Size=UDim2.new(.5,-6,0,48)
local quick=button(matchSection,"QUICK MATCH / PARTY"); quick.Name="QuickMatchMode"; quick.Position=UDim2.new(.5,3,0,28); quick.Size=UDim2.new(.5,-6,0,48)
solo.Activated:Connect(function() if solo.Active then mode="Solo" end end); quick.Activated:Connect(function() if quick.Active then mode="QuickMatch" end end)
local difficultySection=section("DIFFICULTY",82)
local difficultyButtons: {[string]: TextButton}={}
for index,id in ipairs({"Normal","Hard","Nightmare"}) do
    local b=button(difficultySection,string.upper(id)); b.Name="Difficulty_"..id
    b.Position=UDim2.new((index-1)/3,3,0,28); b.Size=UDim2.new(1/3,-6,0,48); b.TextSize=11
    difficultyButtons[id]=b
    b.Activated:Connect(function() if b.Active and state.unlocks and state.unlocks[id] then difficulty=id end end)
end
local heatSection=section("HEAT CONTRACTS / OPTIONAL RISK",28+#heatDefinitions*55)
local heatButtons: {[string]: TextButton}={}
for index,definition in ipairs(heatDefinitions) do
    local b=button(heatSection,definition.name.."  +"..definition.reward.."%\n"..definition.description)
    b.Name="Heat_"..definition.id; b.Position=UDim2.fromOffset(3,28+(index-1)*55); b.Size=UDim2.new(1,-6,0,49); b.TextSize=11
    heatButtons[definition.id]=b
    b.Activated:Connect(function() if b.Active and Config.HeatContracts and Config.HeatContracts[definition.id] then selectedHeat[definition.id]=not selectedHeat[definition.id] end end)
end
local status=label(panel,"Connecting...",11,light); status.Name="QueueStatus"
status.Position=UDim2.new(0,16,1,-109); status.Size=UDim2.new(1,-32,0,39)
local deploy=button(panel,"QUICK MATCH"); deploy.Name="DeployRequest"; deploy.Position=UDim2.new(0,16,1,-61); deploy.Size=UDim2.new(1,-32,0,48); deploy.BackgroundColor3=teal; deploy.TextColor3=ink
local function leader(): boolean
    return not state.party or state.party.leader==player.UserId
end
local function queued(): boolean
    return state.party and (state.party.status=="Queued" or state.party.status=="Matching" or state.party.status=="Matched" or state.party.status=="Teleporting") or false
end
local function heatArray(): {string}
    local result={}
    for _,definition in ipairs(heatDefinitions) do if selectedHeat[definition.id] then table.insert(result,definition.id) end end
    return result
end
deploy.Activated:Connect(function()
    if not leader() then return end
    if state.party and state.party.status=="Queued" then request:FireServer("Cancel",{})
    elseif queued() then return
    else request:FireServer("Queue",{mode=mode,difficulty=difficulty,heat=heatArray()}) end
end)
local function setOpen(value: boolean)
    shade.Visible=value; openButton.Visible=not value
    if value and string.find(UserInputService:GetLastInputType().Name,"Gamepad") then GuiService.SelectedObject=deploy.Selectable and deploy or close
    elseif not value and GuiService.SelectedObject and GuiService.SelectedObject:IsDescendantOf(panel) then GuiService.SelectedObject=nil end
end
openButton.Activated:Connect(function() setOpen(true) end); close.Activated:Connect(function() setOpen(false) end)
UserInputService.LastInputTypeChanged:Connect(function(inputType)
    if string.find(inputType.Name,"Gamepad") and not GuiService.SelectedObject then
        GuiService.SelectedObject=shade.Visible and (deploy.Selectable and deploy or close) or openButton
    end
end)
ProximityPromptService.PromptTriggered:Connect(function(prompt, who)
    if (not who or who==player) and prompt:GetAttribute("HubAction")=="Deploy" then setOpen(true) end
end)
ContextActionService:BindActionAtPriority("HubDeployPanel",function(_,input)
    if UserInputService:GetFocusedTextBox() then return Enum.ContextActionResult.Pass end
    if input==Enum.UserInputState.Begin then setOpen(not shade.Visible) end
    return Enum.ContextActionResult.Sink
end,false,2500,Enum.KeyCode.M,Enum.KeyCode.ButtonSelect)
local rosterSignature=""
local function updateRoster()
    local entries={}
    for _,invite in ipairs(state.invites or {}) do table.insert(entries,{key="invite"..invite.partyId,text="ACCEPT INVITE / "..invite.leaderName,action="Accept",payload={partyId=invite.partyId}}) end
    local members={}
    if state.party then for _,member in ipairs(state.party.members or {}) do members[member.userId]=true end end
    for _,other in ipairs(state.players or {}) do
        if other.userId~=player.UserId and not members[other.userId] then
            table.insert(entries,{key=tostring(other.userId),text="INVITE "..other.name,action="Invite",payload={userId=other.userId}})
        end
    end
    local keys={tostring(leader()),tostring(queued())}
    for _,entry in ipairs(entries) do table.insert(keys,entry.key..entry.text) end
    local signature=table.concat(keys,"|")
    if signature==rosterSignature then return end
    rosterSignature=signature
    local selected=GuiService.SelectedObject
    if selected and selected:IsDescendantOf(roster) then GuiService.SelectedObject=deploy end
    for _,child in ipairs(roster:GetChildren()) do if child:IsA("GuiObject") then child:Destroy() end end
    if #entries==0 then
        local empty=label(roster,"Friends can join from your profile. Solo and quick match are always available.",11,muted)
        empty.Size=UDim2.new(1,0,0,48)
    end
    for index,entry in ipairs(entries) do
        local b=button(roster,entry.text); b.LayoutOrder=index; b.Name=entry.key
        b.Active=(entry.action=="Accept" or leader()) and not queued(); b.Selectable=b.Active
        b.Activated:Connect(function() if b.Active then request:FireServer(entry.action,entry.payload) end end)
    end
end
local function refresh()
    if not gui.Parent then return end
    local isLeader,isQueued=leader(),queued()
    local party=state.party
    local names={}
    if party then for _,member in ipairs(party.members or {}) do table.insert(names,member.name..(member.userId==party.leader and " ★" or "")) end end
    partyText.Text=#names>0 and table.concat(names," · ") or "Your squad: just you"
    leave.Visible=party~=nil; friends.Visible=true
    leave.Active=not isQueued; leave.Selectable=leave.Active
    for id,b in pairs(heroButtons) do b.BackgroundColor3=id==selectedHero and Config.Characters[id].Color or panelColor; b.TextColor3=id==selectedHero and ink or light end
    for id,b in pairs(difficultyButtons) do
        local unlocked=state.unlocks and state.unlocks[id]
        b.Text=string.upper(id)..(unlocked and "" or " / LOCKED")
        b.Active=unlocked and isLeader and not isQueued or false; b.Selectable=b.Active
        b.BackgroundColor3=id==difficulty and teal or panelColor; b.TextColor3=id==difficulty and ink or (unlocked and light or muted)
    end
    local bonus=0
    for _,definition in ipairs(heatDefinitions) do
        local b=heatButtons[definition.id]
        local available=Config.HeatContracts and Config.HeatContracts[definition.id]~=nil
        if not available then selectedHeat[definition.id]=nil end
        b.Active=available and isLeader and not isQueued or false; b.Selectable=b.Active
        b.Text=definition.name..(available and ("  +"..definition.reward.."%\n"..definition.description) or " / NOT AVAILABLE")
        b.BackgroundColor3=selectedHeat[definition.id] and gold or panelColor; b.TextColor3=selectedHeat[definition.id] and ink or light
        if selectedHeat[definition.id] then bonus+=definition.reward end
    end
    local partySize=party and #(party.members or {}) or 1
    solo.Text=partySize>1 and "PRIVATE PARTY RUN" or "SOLO RUN"
    solo.Active=isLeader and not isQueued; solo.Selectable=solo.Active; quick.Active=solo.Active; quick.Selectable=solo.Active
    solo.BackgroundColor3=mode=="Solo" and teal or panelColor; solo.TextColor3=mode=="Solo" and ink or light
    quick.BackgroundColor3=mode=="QuickMatch" and teal or panelColor; quick.TextColor3=mode=="QuickMatch" and ink or light
    local canCancel=party and party.status=="Queued"
    deploy.Active=isLeader and (not isQueued or canCancel); deploy.Selectable=deploy.Active
    local elapsed=party and type(party.queuedAt)=="number" and math.max(0,os.time()-party.queuedAt) or 0
    deploy.Text=not isLeader and "PARTY LEADER CHOOSES DEPLOYMENT" or (isQueued and not canCancel) and "PREPARING YOUR CAMPAIGN..." or isQueued and ("CANCEL QUEUE / "..elapsed.."s") or mode=="Solo" and (partySize>1 and "DEPLOY PRIVATE PARTY" or "DEPLOY SOLO") or "FIND A MATCH"
    status.Text=(isQueued and not canCancel) and "YOUR MATCH IS READY\nStay with your squad while deployment completes." or isQueued and ("FINDING YOUR SQUAD · "..elapsed.."s\nKeep your party together. You can cancel.") or (tostring(state.message or "")~="" and tostring(state.message) or (difficulty.." / HEAT BONUS +"..bonus.."% · Earned coins and XP"))
    local authoritativeMessage=tostring(state.message or "")
    -- A held save or deployment failure must remain visible even while a match is preparing.
    if authoritativeMessage~="" and (state.messagePriority=="Attention" or authoritativeMessage~="Deployment queued.") then
        status.Text=authoritativeMessage
        status.TextColor3=gold
    else status.TextColor3=light end
    gui:SetAttribute("QueueActive",isQueued); gui:SetAttribute("SelectedDifficulty",difficulty); gui:SetAttribute("SelectedHeatCount",#heatArray())
    updateRoster()
    local selected=GuiService.SelectedObject
    if selected and selected:IsDescendantOf(panel) and not selected.Selectable then GuiService.SelectedObject=close end
end
stateRemote.OnClientEvent:Connect(function(nextState: any)
    if type(nextState)~="table" or nextState.kind~="HubState" then return end
    state=nextState
    selectedHero=Config.Characters[state.selectedHero] and state.selectedHero or selectedHero
    if state.party and (not leader() or queued()) then
        difficulty=state.party.difficulty or difficulty
        selectedHeat={}
        for _,id in ipairs(state.party.heat or {}) do selectedHeat[id]=true end
    end
    if not state.unlocks or not state.unlocks[difficulty] then difficulty="Normal" end
    refresh()
end)
local function resize()
    local size=safe.AbsoluteSize
    panel.Size=UDim2.fromOffset(math.max(280,math.min(780,size.X-20)),math.max(240,math.min(690,size.Y-20)))
end
safe:GetPropertyChangedSignal("AbsoluteSize"):Connect(resize)
resize(); refresh(); setOpen(true)
request:FireServer("Refresh",{})
task.spawn(function() while gui.Parent do task.wait(.25); refresh() end end)
