-- Deterministic event-sequence policy fixture; no physical input or camera claim.
return function(Guard)
    if not Guard then
    local module=game.ServerScriptService:FindFirstChild("FocusGuard")
    if not module then module=game.Players.LocalPlayer.PlayerScripts.NightfallClient.FocusGuard end
    Guard=require(module)
    end
    local function signal()
        local callbacks={}
        return {Connect=function(_,fn)
            local key={}callbacks[key]=fn
            return {Disconnect=function()callbacks[key]=nil end}
        end,Fire=function(_,...)for _,fn in pairs(callbacks)do fn(...)end end}
    end
    local attrs,signals={},{}
    local player={CharacterRemoving=signal()}
    function player:GetAttribute(name)return attrs[name]end
    function player:GetAttributeChangedSignal(name)signals[name]=signals[name]or signal()return signals[name]end
    local input={WindowFocusReleased=signal(),WindowFocused=signal(),TextBoxFocused=signal(),text=nil}
    function input:GetFocusedTextBox()return self.text end
    local held,block,releases,clears=true,true,0,0
    local guard=Guard.new({input=input,player=player,clearHeld=function()held=false clears+=1 end,
        releaseBlock=function()block=false releases+=1 end})
    assert(not guard:Blocked() and guard:CanReturn(true,false,true))
    input.text={}input.TextBoxFocused:Fire(input.text)
    assert(not held and not block and guard:Blocked() and not guard:CanReturn(true,false,true))
    assert(guard:ReleaseInput("Block",Enum.UserInputState.End),'Text focus must not swallow release')
    assert(guard:ReleaseInput("Block",Enum.UserInputState.Cancel),'Cancel must release too')
    assert(not guard:ReleaseInput("Special",Enum.UserInputState.End),'Release must not submit another action')
    input.text=nil
    for _,name in ipairs({"MenuOpen","SettingsOpen"})do
        held=true block=true attrs[name]=true signals[name]:Fire()
        assert(not held and not block and guard:Blocked() and not guard:CanReturn(true,false,true))
        attrs[name]=false signals[name]:Fire()
        assert(not guard:Blocked() and not held and not block,'Closing modal must not restore old input')
    end
    held=true block=true input.WindowFocusReleased:Fire()
    assert(not held and not block and guard:Blocked())
    input.WindowFocused:Fire()
    assert(not guard:Blocked() and not held,'Window focus must require fresh movement input')
    held=true block=true player.CharacterRemoving:Fire()
    assert(not held and not block)
    assert(not guard:CanReturn(false,false,true) and not guard:CanReturn(true,true,true) and not guard:CanReturn(true,false,false))
    guard:Destroy()
    local before=clears input.TextBoxFocused:Fire()signals.MenuOpen:Fire()
    assert(clears==before,'Destroyed guard connections survived')
    return {passed=true,textRelease=true,endCancel=true,modalReset=true,windowReset=true,characterReset=true,
        returnGates=true,disconnect=true,releases=releases,physicalInputVerified=false}
end
