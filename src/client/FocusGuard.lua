-- Shared client focus policy. This module grants no gameplay authority.
local Guard={}
Guard.__index=Guard
function Guard.new(options)
    local self=setmetatable({input=options.input,player=options.player,clear=options.clearHeld or function()end,
        release=options.releaseBlock or function()end,focused=true,connections={}},Guard)
    local function connect(signal,callback)table.insert(self.connections,signal:Connect(callback))end
    connect(self.input.WindowFocusReleased,function()self.focused=false self:Reset("window")end)
    connect(self.input.WindowFocused,function()self.focused=true end)
    connect(self.input.TextBoxFocused,function()self:Reset("text")end)
    for _,attribute in ipairs({"MenuOpen","SettingsOpen"})do
        connect(self.player:GetAttributeChangedSignal(attribute),function()
            if self.player:GetAttribute(attribute)then self:Reset(attribute)end
        end)
    end
    connect(self.player.CharacterRemoving,function()self:Reset("character")end)
    return self
end
function Guard:Blocked()
    return not self.focused or self.input:GetFocusedTextBox()~=nil
        or self.player:GetAttribute("MenuOpen")==true or self.player:GetAttribute("SettingsOpen")==true
end
function Guard:Reset(reason)
    self.clear(reason)
    self.release()
end
function Guard:ReleaseInput(action,state)
    if action=="Block" and (state==Enum.UserInputState.End or state==Enum.UserInputState.Cancel)then
        self.release()
        return true
    end
    return false
end
function Guard:CanReturn(canReturn,busy,visible)
    return canReturn==true and busy~=true and visible==true and not self:Blocked()
end
function Guard:Destroy()
    self:Reset("destroy")
    for _,connection in ipairs(self.connections)do connection:Disconnect()end
    self.connections={}
end
return Guard
