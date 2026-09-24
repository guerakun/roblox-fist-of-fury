-- Display state only. No reward math or gameplay intent is sent by this model.
local Model={}
Model.__index=Model
local function copy(value)
    local result={}
    for key,item in pairs(value)do result[key]=item end
    return result
end
local function number(value)
    return type(value)=="number"and value==value and value>=0 and value<math.huge
end
function Model.new()
    return setmetatable({result=nil,receipt=nil,seen={},order={},reveals=0},Model)
end
function Model:Apply(state)
    local incoming=state.districtResult
    local reveal=false
    if incoming==false then self.result=nil self.receipt=nil end
    if type(incoming)=="table"and type(incoming.id)=="string"and type(incoming.campaignId)=="string"
        and number(incoming.stage)and incoming.stage>=1 and incoming.stage<=3 then
        local older=self.result and incoming.campaignId==self.result.campaignId and incoming.stage<self.result.stage
        if older then return false end
        if not self.result or incoming.id~=self.result.id then
            self.result=copy(incoming)self.receipt=nil
            if not self.seen[incoming.id]then
                self.seen[incoming.id]=true table.insert(self.order,incoming.id)
                if #self.order>32 then self.seen[table.remove(self.order,1)]=nil end
                self.reveals+=1 reveal=true
            end
        end
    end
    local receipt=state.districtReceipt
    if receipt==false then self.receipt=nil end
    if self.result and type(receipt)=="table"and receipt.resultId==self.result.id
        and number(receipt.revision)and receipt.revision%1==0
        and(not self.receipt or receipt.revision>self.receipt.revision)then self.receipt=copy(receipt)end
    return reveal
end
local statusText={pending="REWARDS PENDING",paid="REWARDS RECEIVED",readOnly="SAVE UNAVAILABLE / REWARDS NOT SETTLED",
    capped="REWARD CAP REACHED",capacity="REWARD JOURNAL FULL / NOT SETTLED"}
function Model:Lines()
    local receipt=self.receipt
    if not receipt then return {status="REWARDS PENDING",base="BASE RECEIVED / --",bonus="BONUS RECEIVED / --",multipliers="Reward factors pending"}end
    local function amount(value)return number(value)and tostring(math.floor(value))or "--"end
    local function factor(value)return number(value)and string.format("x%.2f",value)or "pending"end
    return {status=statusText[receipt.status]or "REWARDS PENDING",
        base="BASE RECEIVED / "..amount(receipt.basePaidCoins).." COINS + "..amount(receipt.basePaidXP).." XP",
        bonus="BONUS RECEIVED / "..amount(receipt.coins).." COINS + "..amount(receipt.xp).." XP",
        multipliers="RANK "..factor(receipt.rankMultiplier).."  /  HEAT "..factor(receipt.heatMultiplier).."  /  TIER "..factor(receipt.difficultyMultiplier)}
end
function Model.Style(style)
    if type(style)~="table"then return {score=0,multiplier=1,progress=0}end
    return {score=number(style.score)and math.floor(style.score)or 0,
        multiplier=number(style.multiplier)and math.clamp(style.multiplier,1,4)or 1,
        progress=number(style.progress)and math.clamp(style.progress,0,1)or 0}
end
return Model
