-- Injectable transport retry policy; engine failure events never trust client payloads.
local C={} C.__index=C
function C.new(adapter)
    return setmetatable({a=adapter,pending={}},C)
end
function C:Start(players,placeId,options,token)
    assert(type(placeId)=='number' and placeId>0,'destination not configured')
    local group={}
    for _,p in ipairs(players)do
        if not self.pending[p] then self.pending[p]={place=placeId,options=options,token=token,attempts=1,retrying=false} table.insert(group,p) end
    end
    if #group==0 then return false end
    local ok,err=pcall(function()self.a.send(placeId,group,options)end)
    if not ok then for _,p in ipairs(group)do self:Failed(p,placeId,tostring(err))end end
    return true
end
function C:Failed(player,placeId,message)
    local item=self.pending[player]
    if not item or item.place~=placeId or item.retrying then return end
    if item.attempts>=3 then
        self.pending[player]=nil
        if self.a.exhausted then self.a.exhausted(player,item.token,message)end
        return
    end
    item.retrying=true
    local delay=2^(item.attempts-1)
    self.a.delay(delay,function()
        if self.pending[player]~=item then return end
        item.retrying=false item.attempts+=1
        local ok,err=pcall(function()self.a.send(placeId,{player},item.options)end)
        if not ok then self:Failed(player,placeId,tostring(err))end
    end)
end
function C:Remove(player)self.pending[player]=nil end
return C
