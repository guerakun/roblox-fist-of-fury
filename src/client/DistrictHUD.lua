-- Style and district receipts are observational UI; all numbers originate on the server.
local Players=game:GetService("Players")
local UserInputService=game:GetService("UserInputService")
local ContextActionService=game:GetService("ContextActionService")
local GuiService=game:GetService("GuiService")
local RunService=game:GetService("RunService")
local CompactHUDLayout=require(script.Parent.CompactHUDLayout)
local Model=require(script.Parent.DistrictResultModel)
local HUD={}
function HUD.new(options)
    local player=options.player or Players.LocalPlayer
    local colors=options.colors
    local model=Model.new()
    local connections={}
    local function connect(signal,fn)table.insert(connections,signal:Connect(fn))end
    local function make(class,properties,parent)
        local item=Instance.new(class)
        for key,value in pairs(properties)do item[key]=value end
        item.Parent=parent return item
    end
    local function text(parent,name,size,color,pos,dimensions)
        return make("TextLabel",{Name=name,BackgroundTransparency=1,Text="",Font=Enum.Font.GothamBold,
            TextSize=size,TextColor3=color,Position=pos,Size=dimensions,TextXAlignment=Enum.TextXAlignment.Left,
            TextTruncate=Enum.TextTruncate.AtEnd},parent)
    end
    local function round(item)make("UICorner",{CornerRadius=UDim.new(0,8)},item)end
    local style=make("Frame",{Name="StyleMeter",Visible=false,BackgroundColor3=colors.ink,BorderSizePixel=0,
        Size=UDim2.fromOffset(178,28)},options.parent)round(style)
    local multiplier=text(style,"StyleMultiplier",15,colors.cyan,UDim2.fromOffset(8,1),UDim2.fromOffset(36,22))
    local score=text(style,"StyleScore",10,colors.text,UDim2.fromOffset(48,1),UDim2.new(1,-56,0,22))
    local fill=make("Frame",{Name="StyleProgress",BorderSizePixel=0,BackgroundColor3=colors.cyan,
        Position=UDim2.new(0,0,1,-3),Size=UDim2.new(0,0,0,3)},style)
    local shade=make("Frame",{Name="DistrictRankShade",Visible=false,BackgroundColor3=colors.ink,BackgroundTransparency=.35,
        BorderSizePixel=0,Active=false,Size=UDim2.fromScale(1,1),ZIndex=25},options.parent)
    local card=make("Frame",{Name="DistrictRank",AnchorPoint=Vector2.new(.5,.5),Position=UDim2.fromScale(.5,.5),
        Size=UDim2.fromOffset(420,280),BackgroundColor3=colors.ink,BorderSizePixel=0,Active=true,ZIndex=26},shade)round(card)
    make("UIStroke",{Color=colors.cyan,Thickness=1},card)
    local title=text(card,"RankTitle",24,colors.cyan,UDim2.fromOffset(16,12),UDim2.new(1,-82,0,36))
    title.ZIndex=27
    local close=make("TextButton",{Name="CloseRank",Text="CLOSE",Font=Enum.Font.GothamBold,TextSize=10,
        TextColor3=colors.text,BackgroundColor3=colors.panel,BorderSizePixel=0,Size=UDim2.fromOffset(52,44),
        Position=UDim2.new(1,-60,0,8),ZIndex=28,Selectable=true},card)round(close)
    local scroll=make("ScrollingFrame",{Name="RankDetails",BackgroundTransparency=1,BorderSizePixel=0,
        Position=UDim2.fromOffset(16,58),Size=UDim2.new(1,-32,1,-70),CanvasSize=UDim2.fromOffset(0,0),AutomaticCanvasSize=Enum.AutomaticSize.Y,
        ScrollBarThickness=4,ScrollingDirection=Enum.ScrollingDirection.Y,ZIndex=27},card)
    make("UIListLayout",{SortOrder=Enum.SortOrder.LayoutOrder,Padding=UDim.new(0,4)},scroll)
    local labels={}
    for index,key in ipairs({"Performance","Damage","Factors","Base","Bonus","Bounty","Payment","Hint"})do
        local label=text(scroll,key,index==1 and 14 or 11,index==7 and colors.cyan or colors.text,
            UDim2.fromOffset(0,(index-1)*27),UDim2.new(1,-8,0,25))
        label.ZIndex=28 label.LayoutOrder=index label.Position=UDim2.new()
        label.TextTruncate=Enum.TextTruncate.None label.TextWrapped=true label.AutomaticSize=Enum.AutomaticSize.Y
        labels[key]=label
    end
    local toggle=make("TextButton",{Name="ViewDistrictRank",Text="DISTRICT RANK / N",Visible=false,
        AnchorPoint=Vector2.new(.5,1),Position=UDim2.new(.5,0,1,-104),Size=UDim2.fromOffset(194,44),
        BackgroundColor3=colors.panel,BorderSizePixel=0,TextColor3=colors.cyan,Font=Enum.Font.GothamBold,
        TextSize=12,Selectable=true,ZIndex=24},options.parent)round(toggle)
    local snapshot={}local panelOpen=false local pendingReveal=false local focusSerial=0
    local function blocked()
        return UserInputService:GetFocusedTextBox()~=nil or player:GetAttribute("MenuOpen")==true or player:GetAttribute("SettingsOpen")==true
    end
    local function safeStatus()
        return snapshot.status=="Advance"or snapshot.status=="Intermission"or snapshot.status=="Victory"or snapshot.status=="Defeat"
    end
    local function setOpen(value)
        if value and(not model.result or not safeStatus()or blocked())then return end
        panelOpen=value
        focusSerial+=1 local serial=focusSerial
        if string.find(UserInputService:GetLastInputType().Name,"Gamepad")then
            task.spawn(function()
                RunService.RenderStepped:Wait()
                if serial~=focusSerial or blocked()then return end
                if value and shade.Visible then GuiService.SelectedObject=close
                elseif toggle.Visible then GuiService.SelectedObject=toggle end
            end)
        end
    end
    connect(close.Activated,function()setOpen(false)end)
    connect(toggle.Activated,function()setOpen(true)end)
    local actionName=options.actionName or "NightfallRankControls"
    ContextActionService:BindActionAtPriority(actionName,function(_,state,input)
        if blocked()or not model.result or not safeStatus()then return Enum.ContextActionResult.Pass end
        local accepted=input.KeyCode==Enum.KeyCode.N or (input.KeyCode==Enum.KeyCode.ButtonB and panelOpen)
            or (input.KeyCode==Enum.KeyCode.ButtonA and (GuiService.SelectedObject==close or GuiService.SelectedObject==toggle))
        if not accepted then return Enum.ContextActionResult.Pass end
        if state==Enum.UserInputState.Begin then setOpen(not panelOpen)end
        return Enum.ContextActionResult.Sink
    end,false,3102,Enum.KeyCode.N,Enum.KeyCode.ButtonA,Enum.KeyCode.ButtonB)
    local api={model=model,card=card,style=style,toggle=toggle,shade=shade,labels=labels,SetOpen=setOpen}
    function api.Update(state)
        snapshot=state
        if model:Apply(state)then pendingReveal=true end
        if not model.result then panelOpen=false pendingReveal=false end
        if model.result then
            local result=model.result
            title.Text="DISTRICT "..tostring(result.stage).." / RANK "..tostring(result.rank or "--")
            local function time(value)local n=math.max(0,tonumber(value)or 0)return string.format("%02d:%02d",math.floor(n/60),math.floor(n%60))end
            labels.Performance.Text=tostring(math.floor(tonumber(result.score)or 0)).." SCORE / "..time(result.duration).." / PAR "..time(result.parTime)
            labels.Damage.Text=string.format("%.0f%% DAMAGE TAKEN / %s",tonumber(result.damageTaken)or 0,string.upper(result.difficulty or "Normal"))
            local lines=model:Lines()
            labels.Factors.Text=lines.multipliers labels.Base.Text=lines.base labels.Bonus.Text=lines.bonus labels.Bounty.Text=lines.bounty labels.Payment.Text=lines.status
            labels.Hint.Text="Base, rank bonus and bounty are separate."
        end
        local current=Model.Style(state.style)
        multiplier.Text=string.format("x%.0f",current.multiplier)
        score.Text=tostring(current.score).." STYLE SCORE"
        fill.Size=UDim2.new(current.progress,0,0,3)
    end
    function api.Render(width,height,touch,health)
        local hidden=blocked()
        if pendingReveal and safeStatus()and not hidden then setOpen(true)pendingReveal=false end
        local show=model.result~=nil and safeStatus()and not hidden
        shade.Visible=show and panelOpen
        toggle.Visible=show and not panelOpen
        local reserve=player:GetAttribute(options.travelAttribute or "TravelPanelVisible")==true and 96 or 0
        shade.Size=UDim2.new(1,0,1,-reserve)
        card.Size=UDim2.fromOffset(math.min(420,width-24),math.min(280,math.max(120,height-reserve-24)))
        toggle.Position=UDim2.new(.5,0,1,-math.max(104,reserve+8))
        toggle.Text=touch and "VIEW DISTRICT RANK"or "DISTRICT RANK / N"
        local origin=options.parent.AbsolutePosition
        local healthY=health and health.AbsolutePosition.Y-origin.Y or height-190
        local healthX=health and health.AbsolutePosition.X-origin.X or 16
        local compact=CompactHUDLayout.Compute(width,height,touch and "Touch"or "Keyboard",false,player:GetAttribute("CompactHeroChoicesVisible")==true)
        style.Size=UDim2.fromOffset(178,28)
        style.Position=UDim2.fromOffset(healthX,healthY-34)
        if compact then CompactHUDLayout.Place(style,compact.style)end
        style.Visible=type(snapshot.style)=="table"and snapshot.status~="Waiting"and not hidden and not shade.Visible and (compact~=nil or healthY>=94)
            and snapshot.status~="Defeat"and snapshot.status~="Victory"
        if not show and (GuiService.SelectedObject==close or GuiService.SelectedObject==toggle)then GuiService.SelectedObject=nil end
    end
    function api.Destroy()
        focusSerial+=1
        ContextActionService:UnbindAction(actionName)
        if GuiService.SelectedObject==close or GuiService.SelectedObject==toggle then GuiService.SelectedObject=nil end
        for _,connection in ipairs(connections)do connection:Disconnect()end
        style:Destroy()shade:Destroy()toggle:Destroy()
    end
    return api
end
return HUD
