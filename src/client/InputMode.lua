-- Shared meaningful-input policy. No gameplay actions, camera or server state.
local Mode={}
Mode.__index=Mode
local function fallback(c)
    if c.keyboard then return "Keyboard" end
    if c.touch then return "Touch" end
    if c.gamepad then return "Gamepad" end
    return "Keyboard"
end
function Mode.new(capabilities,last)
    local self=setmetatable({capabilities=capabilities or {},listeners={},pointers={},pending=nil},Mode)
    self.mode=(last=="Touch"or last=="Gamepad"or last=="Keyboard")and last or fallback(self.capabilities)
    return self
end
function Mode:Get()return self.mode end
function Mode:CanBegin(kind)
    return kind=="Touch"or next(self.pointers)==nil
end
function Mode:Captions()
    if self.mode=="Touch"then return {"TAP","TAP","TAP","TAP","HOLD","TAP"}end
    if self.mode=="Gamepad"then return {"X","Y","B","LT","HOLD LB","RB"}end
    return {"J","K","L","Q","HOLD F","E"}
end
function Mode:Subscribe(callback)
    local token={}self.listeners[token]=callback
    return {Disconnect=function()self.listeners[token]=nil end}
end
function Mode:Request(mode)
    if mode==self.mode then self.pending=nil return false end
    if next(self.pointers)~=nil then self.pending=mode return false end
    local previous=self.mode self.mode=mode self.pending=nil
    for _,callback in pairs(self.listeners)do callback(mode,previous)end
    return true
end
function Mode:Observe(kind,key,magnitude,pointer)
    if kind=="Touch"then
        self:Request("Touch")
        if pointer then self.pointers[pointer]=true end
    elseif kind=="Keyboard"or kind=="MouseButton1"or kind=="MouseButton2"or kind=="MouseButton3"or kind=="MouseWheel"then
        self:Request("Keyboard")
    elseif string.find(kind,"Gamepad",1,true)then
        if key=="Thumbstick1"or key=="Thumbstick2"or key=="ButtonL2"or key=="ButtonR2"then
            if (magnitude or 0)<=.15 then return end
        end
        self:Request("Gamepad")
    end
end
function Mode:EndPointer(pointer)
    self.pointers[pointer]=nil
    if next(self.pointers)==nil and self.pending then self:Request(self.pending)end
end
function Mode:ClearPointers()
    -- Focus/life resets cancel intent, not replay a deferred input from an old gesture.
    self.pointers={}self.pending=nil
end
function Mode:Capabilities(capabilities)
    self.capabilities=capabilities
    if self.mode=="Gamepad"and not capabilities.gamepad or self.mode=="Touch"and not capabilities.touch then
        self:ClearPointers()self:Request(fallback(capabilities))
    end
end
function Mode.Attach(input)
    local function capabilities()return {keyboard=input.KeyboardEnabled,touch=input.TouchEnabled,gamepad=input.GamepadEnabled}end
    local last=input:GetLastInputType().Name
    local initial=string.find(last,"Gamepad",1,true)and "Gamepad"or last=="Touch"and "Touch"or nil
    local self=Mode.new(capabilities(),initial)
    local connections={}
    local function connect(signal,fn)table.insert(connections,signal:Connect(fn))end
    local function observe(item)
        local key=item.KeyCode.Name
        self:Observe(item.UserInputType.Name,key,item.Position.Magnitude,item)
    end
    connect(input.InputBegan,observe)
    connect(input.InputChanged,function(item)
        if item.UserInputState==Enum.UserInputState.Cancel then self:EndPointer(item)return end
        if item.UserInputType~=Enum.UserInputType.Touch then observe(item)end
    end)
    connect(input.InputEnded,function(item)self:EndPointer(item)end)
    connect(input.WindowFocusReleased,function()self:ClearPointers()end)
    connect(input.TextBoxFocused,function()self:ClearPointers()end)
    for _,property in ipairs({"TouchEnabled","KeyboardEnabled","GamepadEnabled"})do
        connect(input:GetPropertyChangedSignal(property),function()self:Capabilities(capabilities())end)
    end
    connect(input.GamepadDisconnected,function()self:Capabilities(capabilities())end)
    function self:Destroy()
        self:ClearPointers()self.listeners={}
        for _,connection in ipairs(connections)do connection:Disconnect()end
    end
    return self
end
return Mode
