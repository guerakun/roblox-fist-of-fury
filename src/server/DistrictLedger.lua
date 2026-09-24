-- Disconnected WO-3.4 draft; not in Rojo. One ledger per player/run survives same-run reconnect.
-- Root rejects stale campaigns, owns rotation, and supplies normalized server-only result.heat.
-- Receipt status is current profile state supplied per read; it is not a sticky grant failure.
local Ledger = {}
Ledger.__index = Ledger
local function finite(n) return type(n)=='number' and n==n and n>=0 and n<math.huge end
local function stageId(n) return finite(n) and n%1==0 and n>=1 and n<=3 end
local function waveId(n) return finite(n) and n%1==0 and n>=1 and n<=4 end
local function copy(t)
    if type(t)~='table' then return t end
    local out={} for k,v in pairs(t) do out[k]=copy(v) end return out
end
local function frozen(t)
    for _,v in pairs(t) do if type(v)=='table' then frozen(v) end end
    return table.freeze(t)
end
local function equal(a,b)
    if not a then return false end
    for k,v in pairs(a) do if b[k]~=v then return false end end
    for k,v in pairs(b) do if a[k]~=v then return false end end
    return true
end
function Ledger.new(campaignId,policy)
    assert(type(campaignId)=='string' and #campaignId>0 and #campaignId<=130,'invalid campaign')
    assert(type(policy)=='table' and type(policy.Bonus)=='function' and type(policy.Grant)=='function','invalid policy')
    return setmetatable({campaignId=campaignId,policy=policy,stages={},keys={},order={}},Ledger)
end
function Ledger:_stage(stage)
    if not stageId(stage) then return nil end
    if not self.stages[stage] then self.stages[stage]={waves={},baseCoins=0,baseXP=0,paidCoins=0,paidXP=0,revision=0} end
    return self.stages[stage]
end
function Ledger:Record(stage,wave,coins,xp)
    if not stageId(stage) or not waveId(wave) or not finite(coins) or not finite(xp)
        or coins%1~=0 or xp%1~=0 or coins>self.policy.Cap or xp>self.policy.Cap then return false,'invalid' end
    local s=self:_stage(stage)
    local prior=s.waves[wave]
    if prior then
        if prior.coins~=coins or prior.xp~=xp then return false,'conflicting record' end
        return true,'duplicate'
    end
    if s.result then return false,'completed' end
    if s.baseCoins+coins>self.policy.Cap or s.baseXP+xp>self.policy.Cap then return false,'base capacity' end
    s.waves[wave]={coins=coins,xp=xp}
    s.baseCoins+=coins s.baseXP+=xp
    return true
end
function Ledger:Base(stage)
    local s=self:_stage(stage) if not s then return nil end
    return {coins=s.baseCoins,xp=s.baseXP}
end
function Ledger:Paid(stage)
    local s=self:_stage(stage) if not s then return nil end
    return {coins=s.paidCoins,xp=s.paidXP}
end
function Ledger:FullParticipation()
    for stage=1,3 do
        local s=self.stages[stage]
        if not s or not s.result then return false end
        for wave=1,4 do if not s.waves[wave] then return false end end
    end
    return true
end
function Ledger:Complete(result,heatPercent)
    if type(result)~='table' or not stageId(result.stage) or result.campaignId~=self.campaignId
        or result.id~=self.campaignId..':'..result.stage or not self.policy.Ranks[result.rank]
        or not self.policy.Tiers[result.difficulty] or not finite(result.score) or not finite(result.duration)
        or not finite(result.parTime) or result.parTime<=0 or not finite(result.damageTaken) then return nil,'invalid result' end
    local s=self:_stage(result.stage)
    if s.result then return s.result,s.bonus end
    local bonus=self.policy.Bonus({coins=s.baseCoins,xp=s.baseXP},result.rank,result.difficulty,heatPercent)
    if not bonus then return nil,'invalid reward policy' end
    s.result=frozen({id=result.id,campaignId=result.campaignId,stage=result.stage,rank=result.rank,
        difficulty=result.difficulty,score=result.score,duration=result.duration,parTime=result.parTime,
        damageTaken=result.damageTaken,heat=copy(result.heat),heatPercent=heatPercent})
    s.bonus=frozen(copy(bonus))
    return s.result,s.bonus
end
function Ledger:Receipt(stage,status)
    local s=self:_stage(stage) if not s then return nil,'invalid stage' end
    if status~=nil and status~='pending' and status~='readOnly' and status~='paid' and status~='capped' and status~='capacity' then return nil,'invalid status' end
    local allBase=true
    for _,w in pairs(s.waves) do if not w.payment then allBase=false end end
    local inferred=s.districtPayment and allBase and (s.anyCapped and 'capped' or 'paid') or 'pending'
    -- A caller cannot advertise paid/capped before the ledger has actually settled.
    if status=='paid' or status=='capped' then status=inferred end
    local payload={resultId=self.campaignId..':'..stage,baseCoins=s.baseCoins,baseXP=s.baseXP,
        basePaidCoins=s.paidCoins,basePaidXP=s.paidXP,
        coins=s.districtPayment and s.districtPayment.coins or 0,xp=s.districtPayment and s.districtPayment.xp or 0,
        rankMultiplier=s.bonus and s.bonus.rankMultiplier or false,
        difficultyMultiplier=s.bonus and s.bonus.difficultyMultiplier or false,
        heatMultiplier=s.bonus and s.bonus.heatMultiplier or false,status=status or inferred}
    if not equal(s.lastPayload,payload) then s.revision+=1 s.lastPayload=copy(payload) end
    payload.revision=s.revision
    return payload
end
local function paidReceipt(self,stage,payment,key)
    local receipt=self:Receipt(stage)
    receipt.paymentCoins=payment.coins receipt.paymentXP=payment.xp receipt.paymentKey=key
    return receipt
end
function Ledger:PayEncounter(data,stage,wave)
    if not stageId(stage) or not waveId(wave) then return nil,false,'invalid encounter' end
    local s=self:_stage(stage) local w=s.waves[wave]
    if not w then return nil,false,'unrecorded encounter' end
    if w.payment then return copy(w.receipt),false end
    if data==nil then return self:Receipt(stage,'readOnly'),false,'readOnly' end
    local key=self.campaignId..':'..stage..':'..wave
    local payment,reason=self.policy.Grant(data,self.keys,self.order,key,w.coins,w.xp)
    if not payment then return self:Receipt(stage,reason=='capacity' and 'capacity' or 'pending'),false,reason end
    w.payment=payment s.paidCoins+=payment.coins s.paidXP+=payment.xp
    s.anyCapped=s.anyCapped or payment.status=='capped'
    w.receipt=paidReceipt(self,stage,payment,key)
    return copy(w.receipt),true
end
function Ledger:PayDistrict(data,stage)
    local s=self:_stage(stage) if not s or not s.result then return nil,false,'not completed' end
    if s.districtPayment then return copy(s.districtReceipt),false end
    if data==nil then return self:Receipt(stage,'readOnly'),false,'readOnly' end
    local key=self.campaignId..':'..stage..':rank'
    local payment,reason=self.policy.Grant(data,self.keys,self.order,key,s.bonus.coins,s.bonus.xp)
    if not payment then return self:Receipt(stage,reason=='capacity' and 'capacity' or 'pending'),false,reason end
    s.districtPayment=payment s.anyCapped=s.anyCapped or payment.status=='capped'
    s.districtReceipt=paidReceipt(self,stage,payment,key)
    return copy(s.districtReceipt),true
end
return Ledger
