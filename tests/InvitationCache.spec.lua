return function()
    local Cache=require(game.ServerScriptService.InvitationCache)
    local now=100 local c=Cache.new(function()return now end)
    local function count(list)local n=0 for _ in pairs(list)do n+=1 end return n end
    for i=1,1000 do c:Add(1,'party'..i,'Leader')end
    assert(count(c:List(1))==32,'Party churn stays bounded')
    c:Add(1,'party1000','Leader')assert(count(c:List(1))==32,'Overwrite does not evict another invite')
    c:Accept(1,'party1000')assert(count(c:List(1))==31)
    now=160 c:Sweep()assert(c.entries[1]==nil,'Expired entries removed, not just hidden')
    c:Add(2,'party','Leader')c:Remove(2)assert(c.entries[2]==nil,'Disconnected recipients cleaned up')
    c:Add(3,'party','Leader')now=221 assert(next(c:List(3))==nil and c.entries[3]==nil)
    return {passed=true,churn=1000,cap=32,expiry=true,accepted=true,departure=true}
end
