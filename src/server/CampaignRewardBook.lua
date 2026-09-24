-- Current-run journals survive same-server reconnects; old asynchronous grants fail closed.
local Book = {}
Book.__index = Book
function Book.new(Ledger, Policy)
    return setmetatable({Ledger=Ledger,Policy=Policy,current=nil,retired={},players={},count=0},Book)
end
function Book:Begin(id)
    if type(id)~='string' or #id==0 or #id>130 or self.retired[id] then return false end
    if self.current==id then return true end
    if self.current then self.retired[self.current]=true end
    self.current=id self.players={} self.count=0
    return true
end
function Book:Get(userId,campaign)
    if campaign==nil or campaign~=self.current or type(userId)~='number' or userId%1~=0 or userId==0 then return nil end
    if self.players[userId] then return self.players[userId] end
    -- Published admission has at most four match members. Bound open Studio churn too.
    if self.count>=256 then return nil end
    local ledger=self.Ledger.new(campaign,self.Policy)
    self.players[userId]=ledger self.count+=1
    return ledger
end
return Book
