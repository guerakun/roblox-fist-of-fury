-- Injected service events; not physical-device dispatch.
return function(Mode)
    Mode=Mode or require(game.Players.LocalPlayer.PlayerScripts.NightfallClient.InputMode)
    local n=0
    local function check(v,m)n+=1 assert(v,m)end
    local function signal()
        local listeners={}
        return {Connect=function(_,fn)local token={}listeners[token]=fn return {Disconnect=function()listeners[token]=nil end}end,
            Fire=function(_,...)for _,fn in pairs(listeners)do fn(...)end end}
    end
    local input={KeyboardEnabled=true,TouchEnabled=true,GamepadEnabled=true,properties={}}
    for _,name in ipairs({"InputBegan","InputChanged","InputEnded","WindowFocusReleased","TextBoxFocused","GamepadDisconnected"})do input[name]=signal()end
    function input:GetLastInputType()return Enum.UserInputType.Keyboard end
    function input:GetPropertyChangedSignal(name)if not self.properties[name]then self.properties[name]=signal()end return self.properties[name]end
    local function item(kind,key,magnitude,state)return {UserInputType=kind,KeyCode=key or Enum.KeyCode.Unknown,
        Position=Vector3.new(magnitude or 0,0,0),UserInputState=state or Enum.UserInputState.Begin}end
    local mode=Mode.Attach(input)
    check(mode:Get()=="Keyboard","Initial hybrid host")
    local touch=item(Enum.UserInputType.Touch)
    input.InputBegan:Fire(touch)check(mode:Get()=="Touch","Begin mode")
    local keyboard=item(Enum.UserInputType.Keyboard,Enum.KeyCode.J)
    input.InputBegan:Fire(keyboard)check(mode:Get()=="Touch","Deferred while touch is held")
    touch.UserInputState=Enum.UserInputState.Cancel input.InputChanged:Fire(touch)
    check(mode:Get()=="Keyboard"and next(mode.pointers)==nil,"Cancel releases pending layout")
    input.InputChanged:Fire(item(Enum.UserInputType.MouseMovement,nil,1000))check(mode:Get()=="Keyboard","Mouse movement ignored")
    input.InputChanged:Fire(item(Enum.UserInputType.Gamepad1,Enum.KeyCode.Thumbstick1,.1))check(mode:Get()=="Keyboard","Stick noise ignored")
    input.InputChanged:Fire(item(Enum.UserInputType.Gamepad1,Enum.KeyCode.Thumbstick1,.2))check(mode:Get()=="Gamepad","Stick threshold")
    input.InputChanged:Fire(item(Enum.UserInputType.Gamepad1,Enum.KeyCode.ButtonL2,0))check(mode:Get()=="Gamepad","Released trigger is noise")
    input.GamepadEnabled=false input.GamepadDisconnected:Fire(Enum.UserInputType.Gamepad1)
    check(mode:Get()=="Keyboard","Disconnect fallback")
    input.InputBegan:Fire(touch)input.InputBegan:Fire(keyboard)input.WindowFocusReleased:Fire()
    check(mode.pending==nil and next(mode.pointers)==nil,"Window reset")
    input.InputBegan:Fire(touch)input.TextBoxFocused:Fire()check(next(mode.pointers)==nil,"Text reset")
    input.TouchEnabled=false input:GetPropertyChangedSignal("TouchEnabled"):Fire()check(mode:Get()=="Keyboard","Capability fallback")
    mode:Destroy()input.InputBegan:Fire(touch)check(mode:Get()=="Keyboard","Destroyed adapter disconnected")
    return {passed=true,checks=n,syntheticServiceEvents=true,physicalInputVerified=false}
end
