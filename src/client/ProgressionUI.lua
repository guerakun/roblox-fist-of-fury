-- Earned progression and voluntary cosmetic shopping. No automatic purchase prompts.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local MarketplaceService = game:GetService("MarketplaceService")
local GuiService = game:GetService("GuiService")
local ContextActionService = game:GetService("ContextActionService")
local Config = require(ReplicatedStorage.Nightfall.Shared.ProgressionConfig)
local UI = {}
local initialized = false
local C = {ink=Color3.fromRGB(11,17,28),panel=Color3.fromRGB(23,33,49),text=Color3.fromRGB(237,242,252),muted=Color3.fromRGB(155,172,195),cyan=Color3.fromRGB(102,235,218),gold=Color3.fromRGB(255,197,100),red=Color3.fromRGB(255,130,147)}
local function make(class, props, parent)
    local item = Instance.new(class)
    for key,value in pairs(props) do item[key]=value end
    item.Parent=parent
    return item
end
local function corners(item, radius) make("UICorner",{CornerRadius=UDim.new(0,radius or 8)},item) end
local function text(parent,value,size,color,position,dimensions)
    return make("TextLabel",{Text=value,TextSize=size,TextColor3=color or C.text,Font=Enum.Font.GothamMedium,
        BackgroundTransparency=1,TextXAlignment=Enum.TextXAlignment.Left,TextWrapped=true,Position=position,Size=dimensions},parent)
end
local function button(parent,value,position,dimensions,callback)
    if UserInputService.TouchEnabled and dimensions.Y.Scale==0 then dimensions=UDim2.new(dimensions.X.Scale,dimensions.X.Offset,0,math.max(44,dimensions.Y.Offset)) end
    local b=make("TextButton",{Text=value,TextSize=12,TextColor3=C.text,Font=Enum.Font.GothamBold,
        BackgroundColor3=C.panel,AutoButtonColor=true,BorderSizePixel=0,Position=position,Size=dimensions,Selectable=true},parent)
    corners(b); b.Activated:Connect(callback)
    return b
end
function UI.Init()
    if initialized then return end
    initialized=true
    local player=Players.LocalPlayer
    local remote=ReplicatedStorage.Nightfall.Remotes:WaitForChild("Progression",30)
    if not remote then warn("Progression menu unavailable: missing server service");return end
    local gui=make("ScreenGui",{Name="NightfallProgression",ResetOnSpawn=false,IgnoreGuiInset=false,DisplayOrder=30,ZIndexBehavior=Enum.ZIndexBehavior.Sibling},player:WaitForChild("PlayerGui"))
    gui.ScreenInsets=Enum.ScreenInsets.CoreUISafeInsets
    local snapshot={loading=true,coins=0,xp=0,status="Loading",owned={},claimed={},premiumClaimed={},trail="None",title="None",boon="Guardian"}
    local activeTab="Chapter"
    local noticeSerial=0
    local priceText=nil
    local render, setOpen
    local compactLayout=false
    local renderRevision=0
    local openButton=button(gui,"PROGRESS  [P]",UDim2.new(.5,54,0,20),UDim2.fromOffset(96,32),function() setOpen(true) end)
    openButton.AnchorPoint=Vector2.new(.5,0)
    local overlay=make("Frame",{Name="Overlay",Visible=false,BackgroundColor3=Color3.new(0,0,0),BackgroundTransparency=.24,Size=UDim2.fromScale(1,1),Active=true},gui)
    local panel=make("Frame",{Name="Journal",AnchorPoint=Vector2.new(.5,.5),Position=UDim2.fromScale(.5,.5),Size=UDim2.fromOffset(800,570),BackgroundColor3=C.ink,BorderSizePixel=0},overlay)
    corners(panel,14)
    make("UIStroke",{Color=C.cyan,Transparency=.55,Thickness=1},panel)
    local heading=text(panel,"NIGHTFALL JOURNAL",16,C.text,UDim2.fromOffset(24,18),UDim2.new(1,-94,0,30))
    local balance=text(panel,"Loading progress…",13,C.cyan,UDim2.fromOffset(24,53),UDim2.new(1,-48,0,23))
    local closeButton=button(panel,"CLOSE",UDim2.new(1,-83,0,20),UDim2.fromOffset(61,30),function()setOpen(false)end)
    local tabButtons={}
    for index,tab in ipairs({"Chapter","Collection","Boons"}) do
        tabButtons[tab]=button(panel,tab:upper(),UDim2.new((index-1)/3,16,0,88),UDim2.new(1/3,-22,0,35),function()activeTab=tab;render()end)
    end
    local scroll=make("ScrollingFrame",{Name="Content",Position=UDim2.fromOffset(18,137),Size=UDim2.new(1,-36,1,-209),CanvasSize=UDim2.new(),AutomaticCanvasSize=Enum.AutomaticSize.Y,ScrollBarThickness=5,ScrollBarImageColor3=C.cyan,BackgroundTransparency=1,BorderSizePixel=0},panel)
    local list=make("UIListLayout",{Padding=UDim.new(0,9),SortOrder=Enum.SortOrder.LayoutOrder},scroll)
    make("UIPadding",{PaddingRight=UDim.new(0,9),PaddingBottom=UDim.new(0,6)},scroll)
    local footer=text(panel,"Earn power through play. Cosmetics never change damage.",11,C.muted,UDim2.new(0,24,1,-60),UDim2.new(1,-48,0,22))
    local saveLabel=text(panel,"",10,C.muted,UDim2.new(0,24,1,-34),UDim2.new(1,-48,0,19))
    local toast=make("Frame",{Visible=false,AnchorPoint=Vector2.new(.5,0),Position=UDim2.new(.5,0,0,60),Size=UDim2.fromOffset(390,38),BackgroundColor3=C.panel,BorderSizePixel=0},gui)
    corners(toast)
    local toastText=text(toast,"",12,C.cyan,UDim2.fromOffset(12,4),UDim2.new(1,-24,1,-8))
    local function notify(message)
        noticeSerial+=1
        local serial=noticeSerial
        toastText.Text=message;toast.Visible=true
        task.delay(3.8,function()if serial==noticeSerial then toast.Visible=false end end)
    end
    local function send(action,value) remote:FireServer(action,value) end
    local function row(height)
        local item=make("Frame",{BackgroundColor3=C.panel,BackgroundTransparency=.2,BorderSizePixel=0,Size=UDim2.new(1,0,0,height or 86)},scroll)
        corners(item)
        return item
    end
    local function copyLine(value,color,height)
        local item=row(height or 44)
        text(item,value,12,color or C.muted,UDim2.fromOffset(13,4),UDim2.new(1,-26,1,-8))
        return item
    end
    local function itemName(id)
        local cosmetic=Config.FindCosmetic(id)
        return cosmetic and cosmetic.Name or id
    end
    local lastRenderedTab
    local pendingScrollPosition, pendingSelectionKey
    render=function()
        renderRevision+=1
        local revision=renderRevision
        local sameTab=lastRenderedTab==activeTab
        local scrollPosition=sameTab and (pendingScrollPosition or scroll.CanvasPosition) or Vector2.zero
        local selected=GuiService.SelectedObject
        local selectionKey=selected and selected:IsDescendantOf(scroll) and selected:GetAttribute("SelectionKey")
        if not selectionKey and sameTab then selectionKey=pendingSelectionKey end
        pendingScrollPosition,pendingSelectionKey=scrollPosition,selectionKey
        lastRenderedTab=activeTab
        for _,child in ipairs(scroll:GetChildren()) do if child:IsA("Frame") then child:Destroy() end end
        task.defer(function()
            if revision~=renderRevision then return end
            scroll.CanvasPosition=scrollPosition
            pendingScrollPosition,pendingSelectionKey=nil,nil
            if selectionKey and overlay.Visible then
                for _,child in ipairs(scroll:GetDescendants()) do
                    if child:IsA("GuiButton") and child:GetAttribute("SelectionKey")==selectionKey then GuiService.SelectedObject=child;break end
                end
            end
        end)
        local compact=compactLayout
        balance.Text=tostring(snapshot.coins or 0).." COINS  /  "..tostring(snapshot.xp or 0).." CHAPTER XP"
        saveLabel.Text=snapshot.status=="Practice" and "STUDIO PRACTICE • Resets after this test session."
            or snapshot.status=="Saved" and (snapshot.saveWarning and "Save retry pending. Please stay connected." or "Progress autosaves. Chapter rewards do not expire.")
            or snapshot.loading and "Loading your journal…" or "Progress unavailable. Existing saved data is protected."
        saveLabel.TextColor3=(snapshot.status=="Unavailable" or snapshot.saveWarning) and C.red or C.muted
        for tab,b in pairs(tabButtons) do b.BackgroundColor3=activeTab==tab and Color3.fromRGB(40,87,90) or C.panel;b.TextSize=compact and 10 or 12 end
        if snapshot.loading then copyLine("Loading your journal…",C.cyan);return end
        if activeTab=="Chapter" then
            copyLine(Config.ChapterName.." • 12 tiers • No expiry",C.cyan,compact and 58 or 44)
            copyLine("Earn XP together by clearing encounters. Claim the free track below. Premium rewards are cosmetics only; earlier earned tiers remain claimable.",C.muted,compact and 92 or 57)
            local pass=row(compact and 134 or 67)
            text(pass,snapshot.premium and "CHAPTER PASS • OWNED" or "COSMETIC CHAPTER PASS",12,C.gold,UDim2.fromOffset(13,6),UDim2.new(1,compact and -26 or -165,0,compact and 32 or 23))
            text(pass,"Six optional trails and titles. No stat boosts.",11,C.muted,UDim2.fromOffset(13,compact and 37 or 31),UDim2.new(1,compact and -26 or -165,0,compact and 36 or 26))
            local sale=button(pass,snapshot.premium and "OWNED" or (not snapshot.salesEnabled and "NOT ON SALE" or not snapshot.purchaseAllowed and "LOBBY / RESULTS" or (priceText or "CHECK PRICE")),compact and UDim2.fromOffset(13,85) or UDim2.new(1,-143,0,18),UDim2.fromOffset(130,31),function()
                if snapshot.premium then return end
                if not snapshot.salesEnabled then notify("Paid cosmetics are not on sale in this build.");return end
                if snapshot.purchaseAllowed~=true then notify("Purchase from the lobby or results screen.");return end
                if not priceText then
                    if UI.RefreshPrice then UI.RefreshPrice() end
                    notify("Checking the current Roblox price. Try again shortly.");return
                end
                send("PurchasePass")
            end)
            sale.AutoButtonColor=not snapshot.premium and snapshot.salesEnabled==true and snapshot.purchaseAllowed==true
            sale.TextColor3=C.gold;sale:SetAttribute("SelectionKey","PurchasePass")
            for tier,reward in ipairs(Config.Tiers) do
                local unlocked=(snapshot.xp or 0)>=tier*Config.XPPerTier
                local key=tostring(tier)
                local freeClaimed=snapshot.claimed and snapshot.claimed[key]
                local premiumClaimed=not reward.Premium or not snapshot.premium or (snapshot.premiumClaimed and snapshot.premiumClaimed[key])
                local claimed=freeClaimed and premiumClaimed
                local item=row(compact and 137 or 83)
                text(item,string.format("%02d",tier),24,unlocked and C.cyan or C.muted,UDim2.fromOffset(12,8),UDim2.fromOffset(40,35))
                local freeText=reward.Cosmetic and itemName(reward.Cosmetic) or tostring(reward.Coins).." COINS"
                text(item,freeText,12,C.text,UDim2.fromOffset(59,8),UDim2.new(1,compact and -72 or -192,0,compact and 36 or 24))
                text(item,reward.Premium and ("PASS • "..itemName(reward.Premium)) or "FREE CHAPTER REWARD",10,reward.Premium and C.gold or C.muted,UDim2.fromOffset(59,compact and 46 or 34),UDim2.new(1,compact and -72 or -192,0,compact and 30 or 19))
                text(item,tostring(tier*Config.XPPerTier).." XP",10,C.muted,UDim2.fromOffset(compact and 13 or 59,compact and 93 or 56),UDim2.new(1,-126,0,18))
                local claim=button(item,claimed and "CLAIMED" or unlocked and "CLAIM" or "LOCKED",UDim2.new(1,-113,0,compact and 92 or 25),UDim2.fromOffset(100,32),function()if unlocked and not claimed then send("ClaimTier",tier) end end)
                claim.TextColor3=unlocked and not claimed and C.cyan or C.muted;claim:SetAttribute("SelectionKey","Tier"..tier)
            end
        elseif activeTab=="Collection" then
            copyLine("Fixed prices. Coins are earned in encounters; no random rolls. Trails and titles are cosmetic.",C.muted,compact and 76 or 52)
            local clear=row(compact and 92 or (UserInputService.TouchEnabled and 58 or 46))
            text(clear,"Title: "..(snapshot.title~="None" and itemName(snapshot.title) or "NONE"),11,C.muted,UDim2.fromOffset(13,5),UDim2.new(1,compact and -26 or -126,0,35))
            local clearTitle=button(clear,"CLEAR TITLE",UDim2.new(1,-113,0,compact and 43 or 7),UDim2.fromOffset(100,31),function()send("EquipCosmetic","ClearTitle")end)
            clearTitle:SetAttribute("SelectionKey","ClearTitle")
            for _,cosmetic in ipairs(Config.Cosmetics) do
                local owned=snapshot.owned and snapshot.owned[cosmetic.Id]
                local equipped=(cosmetic.Kind=="Trail" and snapshot.trail==cosmetic.Id) or (cosmetic.Kind=="Title" and snapshot.title==cosmetic.Id)
                local item=row(compact and 130 or 75)
                local swatch=make("Frame",{Position=UDim2.fromOffset(13,16),Size=UDim2.fromOffset(5,42),BackgroundColor3=cosmetic.Color,BorderSizePixel=0},item);corners(swatch,3)
                text(item,cosmetic.Name,12,C.text,UDim2.fromOffset(29,9),UDim2.new(1,compact and -42 or -164,0,compact and 34 or 24))
                local desc=cosmetic.Kind:upper().." • "..(owned and "OWNED" or cosmetic.Premium and "CHAPTER PASS" or cosmetic.TrackOnly and "FREE CHAPTER TRACK" or tostring(cosmetic.Price).." COINS")
                text(item,desc,10,C.muted,UDim2.fromOffset(29,compact and 46 or 35),UDim2.new(1,compact and -42 or -164,0,compact and 30 or 25))
                local available=not cosmetic.Premium and not cosmetic.TrackOnly and cosmetic.Price>0
                local b=button(item,equipped and "EQUIPPED" or owned and "EQUIP" or available and "UNLOCK" or "TRACK",UDim2.new(1,-113,0,compact and 85 or 22),UDim2.fromOffset(100,32),function()
                    if owned then send("EquipCosmetic",cosmetic.Id)
                    elseif available then send("BuyCosmetic",cosmetic.Id)
                    else activeTab="Chapter";render() end
                end)
                b.TextColor3=equipped and C.cyan or C.text;b:SetAttribute("SelectionKey","Cosmetic"..cosmetic.Id)
            end
        else
            copyLine("ONE BOON • EARNED THROUGH PLAY",C.cyan,compact and 55 or 44)
            copyLine("Choose one small combat bonus. Unlocks use lifetime chapter XP, never money. Change between encounters; bonuses do not stack.",C.muted,compact and 90 or 58)
            if not snapshot.canEquipBoon then copyLine("Encounter in progress. Change your boon during the next break.",C.gold,compact and 68 or 50) end
            for _,boon in ipairs(Config.Boons) do
                local unlocked=(snapshot.xp or 0)>=boon.XP
                local equipped=snapshot.boon==boon.Id
                local item=row(compact and 163 or 106)
                text(item,boon.Name,15,C.cyan,UDim2.fromOffset(13,9),UDim2.new(1,compact and -26 or -146,0,24))
                text(item,boon.Description,12,C.text,UDim2.fromOffset(13,36),UDim2.new(1,compact and -26 or -146,0,compact and 51 or 39))
                text(item,boon.XP==0 and "AVAILABLE TO EVERYONE" or tostring(boon.XP).." LIFETIME XP",10,C.muted,UDim2.fromOffset(13,compact and 90 or 79),UDim2.new(1,compact and -26 or -146,0,18))
                local b=button(item,equipped and "EQUIPPED" or unlocked and "EQUIP" or "LOCKED",UDim2.new(1,-113,0,compact and 118 or 36),UDim2.fromOffset(100,32),function()if unlocked and not equipped then send("EquipBoon",boon.Id) end end)
                b:SetAttribute("SelectionKey","Boon"..boon.Id)
            end
        end
    end
    setOpen=function(open)
        if open and player:GetAttribute("SettingsOpen") then return end
        if open and snapshot.canEquipBoon~=true then notify("Clear this encounter to open your journal safely.");return end
        overlay.Visible=open
        player:SetAttribute("MenuOpen",open)
        if open then
            ContextActionService:BindActionAtPriority("JournalBack",function(_,state) if state==Enum.UserInputState.Begin then setOpen(false) end return Enum.ContextActionResult.Sink end,false,4000,Enum.KeyCode.ButtonB)
            send("Request");render()
            if UserInputService:GetLastInputType().Name:match("Gamepad") then task.defer(function()if overlay.Visible then GuiService.SelectedObject=closeButton end end) end
        else
            ContextActionService:UnbindAction("JournalBack")
            if GuiService.SelectedObject and GuiService.SelectedObject:IsDescendantOf(gui) then GuiService.SelectedObject=nil end
        end
    end
    local function resize()
        local camera=workspace.CurrentCamera
        if not camera then return end
        local view=gui.AbsoluteSize
        if view.X < 1 or view.Y < 1 then view=camera.ViewportSize end
        local insetTop=0
        local height=math.max(160,math.min(600,view.Y-insetTop-16))
        local touch=UserInputService.TouchEnabled
        local width=math.max(280,math.min(820,view.X-24))
        local nextCompact=width<560
        local layoutChanged=compactLayout~=nextCompact
        compactLayout=nextCompact
        panel.Size=UDim2.fromOffset(width,height)
        -- On short landscape screens, reserve at least 102 px for the list.
        -- The permanent purchase copy stays inside the scrolling chapter rows.
        local short=height<400
        heading.Position=UDim2.fromOffset(short and 16 or 24,short and 8 or 18)
        heading.Size=UDim2.new(1,-94,0,short and 24 or 30)
        heading.TextSize=short and 14 or 16
        balance.Position=UDim2.fromOffset(short and 16 or 24,short and 36 or 53)
        balance.Size=UDim2.new(1,short and -32 or -48,0,short and 19 or 23)
        balance.TextSize=short and 11 or 13
        closeButton.Position=UDim2.new(1,short and -72 or -83,0,short and 9 or 20)
        closeButton.Size=UDim2.fromOffset(short and 56 or 61,touch and 44 or (short and 28 or 30))
        for index,tab in ipairs({"Chapter","Collection","Boons"}) do
            tabButtons[tab].Position=UDim2.new((index-1)/3,16,0,short and 60 or 88)
            tabButtons[tab].Size=UDim2.new(1/3,-22,0,touch and 44 or (short and 30 or 35))
        end
        local scrollTop=short and (touch and 112 or 98) or (touch and 144 or 137)
        scroll.Position=UDim2.fromOffset(18,scrollTop)
        scroll.Size=UDim2.new(1,-36,1,-scrollTop-(short and 30 or 72))
        footer.Visible=not short
        saveLabel.Position=UDim2.new(0,short and 16 or 24,1,short and -25 or -34)
        saveLabel.Size=UDim2.new(1,short and -32 or -48,0,19)
        -- Compute row mode from the requested width, not a stale AbsoluteSize.
        -- render() preserves the active tab's scroll position and selection key.
        if layoutChanged and overlay.Visible then render() end
        openButton.Position=UDim2.new(.5,54,0,touch and view.X>=550 and 10 or view.X<650 and 100 or 20)
        openButton.Size=UDim2.fromOffset(96,touch and 44 or 32)
        toast.Size=UDim2.fromOffset(math.max(250,math.min(440,view.X-28)),42)
        toast.Position=UDim2.new(.5,0,0,view.X<650 and 136 or 60)
    end
    UserInputService.InputBegan:Connect(function(input,processed)
        if processed or UserInputService:GetFocusedTextBox() then return end
        if input.KeyCode==Enum.KeyCode.P or input.KeyCode==Enum.KeyCode.ButtonL3 then setOpen(not overlay.Visible)
        elseif input.KeyCode==Enum.KeyCode.ButtonB and overlay.Visible then setOpen(false) end
    end)
    local priceRequested=false
    UI.RefreshPrice=function()
        if priceRequested or not snapshot.salesEnabled or not snapshot.passId or snapshot.passId<=0 then return end
        priceRequested=true
        task.spawn(function()
            local ok,info=pcall(MarketplaceService.GetProductInfo,MarketplaceService,snapshot.passId,Enum.InfoType.GamePass)
            if ok and info.IsForSale and type(info.PriceInRobux)=="number" then priceText=tostring(info.PriceInRobux).." ROBUX" end
            priceRequested=false
            if overlay.Visible then render() end
        end)
    end
    remote.OnClientEvent:Connect(function(packet)
        if type(packet)~="table" then return end
        if packet.kind=="Notice" then notify(tostring(packet.message or ""))
        elseif packet.kind=="Snapshot" then
            snapshot=packet
            if overlay.Visible and snapshot.canEquipBoon~=true then setOpen(false);notify("Encounter starting. Journal closed.") end
            if overlay.Visible then render() end
            if not priceText then UI.RefreshPrice() end
        end
    end)
    if workspace.CurrentCamera then workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(resize) end
    workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
        if workspace.CurrentCamera then workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(resize) end
        resize()
    end)
    gui.Destroying:Connect(function()player:SetAttribute("MenuOpen",false)end)
    gui:GetPropertyChangedSignal("AbsoluteSize"):Connect(resize)
    UserInputService:GetPropertyChangedSignal("TouchEnabled"):Connect(function()resize();if overlay.Visible then render() end end)
    resize();send("Request")
end
return UI
