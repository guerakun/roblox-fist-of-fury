-- Observational only: bounded attempts (duplicates suppressed within the most recent 512 keys) cannot change rewards or block play.
local Journal={}Journal.__index=Journal
function Journal.new(send)return setmetatable({send=send,players={}},Journal)end
function Journal:Emit(player,key,event)
    if type(key)~='string'or #key>200 then return false end
    local history=self.players[player]or{keys={},order={}}self.players[player]=history
    if history.keys[key]then return false end
    history.keys[key]=true table.insert(history.order,key)
    if #history.order>512 then history.keys[table.remove(history.order,1)]=nil end
    return pcall(self.send,player,event)
end
function Journal:Funnel(player,session,step,name)
    if type(session)~='string'or #session>100 or type(step)~='number'or step%1~=0 or step<1 or step>100 then return false end
    return self:Emit(player,'f:'..session..':'..step,{kind='Funnel',session=session,step=step,name=name})
end
function Journal:Economy(player,key,flow,amount,balance,sku)
    if type(key)~='string'or #key>198 then return false end
    if flow~='Source'and flow~='Sink'then return false end
    if type(amount)~='number'or amount~=amount or amount<=0 or amount==math.huge then return false end
    if type(balance)~='number'or balance~=balance or balance<0 or balance==math.huge then return false end
    return self:Emit(player,'e:'..key,{kind='Economy',flow=flow,amount=amount,balance=balance,sku=sku})
end
function Journal:Forget(player)self.players[player]=nil end
return Journal
