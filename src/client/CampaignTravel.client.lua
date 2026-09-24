--!strict
-- Return intent only; the server selects destinations and the complete traveling party.
local Players=game:GetService("Players")
local ReplicatedStorage=game:GetService("ReplicatedStorage")
local ContextActionService=game:GetService("ContextActionService")
local UserInputService=game:GetService("UserInputService")
local GuiService=game:GetService("GuiService")
local player=Players.LocalPlayer
local focusGuard=require(script.Parent:WaitForChild("FocusGuard")).new({input=UserInputService,player=player})
local travel=ReplicatedStorage:WaitForChild("Nightfall"):WaitForChild("Remotes"):WaitForChild("Travel") :: RemoteEvent
local gui=Instance.new("ScreenGui")
gui.Name="CampaignTravel"; gui.ResetOnSpawn=false; gui.IgnoreGuiInset=false; gui.DisplayOrder=25
 gui.ScreenInsets=Enum.ScreenInsets.CoreUISafeInsets; gui.Parent=player:WaitForChild("PlayerGui")
local safe=Instance.new("Frame")
safe.Name="SafeCanvas"; safe.Size=UDim2.fromScale(1,1); safe.BackgroundTransparency=1; safe.Parent=gui
local panel=Instance.new("Frame")
panel.Name="TravelPanel"; panel.AnchorPoint=Vector2.new(.5,1); panel.Position=UDim2.new(.5,0,1,-8)
panel.Size=UDim2.new(1,-24,0,88); panel.BackgroundColor3=Color3.fromRGB(14,22,33); panel.BackgroundTransparency=.05
panel.BorderSizePixel=0; panel.Visible=false; panel.Parent=safe
local constrain=Instance.new("UISizeConstraint"); constrain.MaxSize=Vector2.new(460,88); constrain.Parent=panel
local corner=Instance.new("UICorner"); corner.CornerRadius=UDim.new(0,9); corner.Parent=panel
local message=Instance.new("TextLabel")
message.Name="TravelMessage"; message.Position=UDim2.fromOffset(10,4); message.Size=UDim2.new(1,-20,0,30)
message.BackgroundTransparency=1; message.TextColor3=Color3.fromRGB(236,240,244); message.TextSize=11
message.Font=Enum.Font.Gotham; message.TextWrapped=true; message.Parent=panel
local button=Instance.new("TextButton")
button.Name="ReturnToRefuge"; button.Position=UDim2.fromOffset(8,36); button.Size=UDim2.new(1,-16,0,44)
button.BackgroundColor3=Color3.fromRGB(111,222,217); button.TextColor3=Color3.fromRGB(14,22,33)
button.Font=Enum.Font.GothamBold; button.TextSize=13; button.BorderSizePixel=0; button.Selectable=true; button.Parent=panel
local buttonCorner=Instance.new("UICorner"); buttonCorner.CornerRadius=UDim.new(0,7); buttonCorner.Parent=button
local canReturn,busy=false,false
local lastRequest=0
local function returnToRefuge()
    if not focusGuard:CanReturn(canReturn,busy,panel.Visible) or os.clock()-lastRequest<.8 then return end
    lastRequest=os.clock()
    travel:FireServer("Return")
end
local function labelButton()
    button.Text=busy and "RETURNING TO THE REFUGE..." or (string.find(UserInputService:GetLastInputType().Name,"Gamepad") and "RETURN PARTY TO REFUGE / Y" or UserInputService.TouchEnabled and "RETURN PARTY TO REFUGE" or "RETURN PARTY TO REFUGE / T")
end
button.Activated:Connect(returnToRefuge)
ContextActionService:BindActionAtPriority("CampaignReturnToRefuge",function(_,input)
    if not focusGuard:CanReturn(canReturn,busy,panel.Visible) then return Enum.ContextActionResult.Pass end
    if input==Enum.UserInputState.Begin then returnToRefuge() end
    return Enum.ContextActionResult.Sink
end,false,3200,Enum.KeyCode.T,Enum.KeyCode.ButtonY)
UserInputService.LastInputTypeChanged:Connect(labelButton)
travel.OnClientEvent:Connect(function(state: any)
    if type(state)~="table" or state.kind~="TravelState" then return end
    canReturn=state.canReturn==true; busy=state.busy==true
    local text=type(state.message)=="string" and state.message or ""
    panel.Visible=canReturn or busy or text~=""
    message.Text=text~="" and text or "Return together. Your party leader chooses when to leave."
    button.Visible=canReturn or busy; button.Active=canReturn and not busy; button.Selectable=button.Active
    message.Size=UDim2.new(1,-20,0,button.Visible and 30 or 78)
    button.BackgroundColor3=busy and Color3.fromRGB(71,101,111) or Color3.fromRGB(111,222,217)
    gui:SetAttribute("CanReturn",canReturn); gui:SetAttribute("Busy",busy)
    player:SetAttribute("TravelPanelVisible",panel.Visible)
    if GuiService.SelectedObject==button and not button.Selectable then GuiService.SelectedObject=nil end
    labelButton()
end)
player:SetAttribute("TravelPanelVisible",false)
labelButton()
