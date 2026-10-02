-- A right click is a short, still release. Never consumes native camera input.
local Gesture={};Gesture.__index=Gesture
Gesture.MaxDuration=.28;Gesture.MaxTravel=6
function Gesture.new()return setmetatable({},Gesture)end
function Gesture:Cancel()self.start=nil;self.position=nil;self.travel=0 end
function Gesture:Begin(position,time)self.start=time;self.position=position;self.travel=0 end
function Gesture:Move(delta)if self.start then self.travel+=delta.Magnitude end end
function Gesture:Finish(position,time)
    local fire=self.start~=nil and time-self.start<=Gesture.MaxDuration and time>=self.start
        and self.travel<=Gesture.MaxTravel and (position-self.position).Magnitude<=Gesture.MaxTravel
    self:Cancel();return fire
end
return Gesture
