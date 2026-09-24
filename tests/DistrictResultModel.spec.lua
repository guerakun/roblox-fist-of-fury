-- Client receipt-state contract; never submits rewards or derives intended grants.
return function()
    local module=game.ServerScriptService:FindFirstChild("DistrictResultModel")
    if not module then module=game.Players.LocalPlayer.PlayerScripts.NightfallClient.DistrictResultModel end
    local Model=require(module)local model=Model.new()local checks=0
    local function check(value,message)assert(value,message)checks+=1 end
    local function result(stage)return {id="run:"..stage,campaignId="run",stage=stage,rank="A",score=1400,duration=91,parTime=120,damageTaken=44}end
    local function receipt(stage,revision,status)
        return {resultId="run:"..stage,revision=revision,status=status,baseCoins=200,baseXP=120,
            basePaidCoins=150,basePaidXP=100,coins=60,xp=36,rankMultiplier=1.3,heatMultiplier=1,difficultyMultiplier=1}
    end
    local pending=receipt(1,1,"pending")pending.coins=0 pending.xp=0 pending.rankMultiplier=false
    check(model:Apply({districtResult=result(1),districtReceipt=pending}),"First result should reveal")
    check(model.reveals==1 and model:Lines().status=="REWARDS PENDING")
    check(string.find(model:Lines().base,"150 COINS + 100 XP",1,true)~=nil,"Use actual eligible base, not nominal200")
    check(string.find(model:Lines().bonus,"0 COINS + 0 XP",1,true)~=nil)
    check(string.find(model:Lines().multipliers,"RANK pending",1,true)~=nil)
    local modified=result(1)modified.rank="S"modified.score=99999
    check(not model:Apply({districtResult=modified,districtReceipt=receipt(1,2,"paid")}))
    check(model.result.rank=="A" and model.result.score==1400 and model.reveals==1,"Performance must stay immutable")
    check(model.receipt.revision==2 and model:Lines().status=="REWARDS RECEIVED")
    check(string.find(model:Lines().bonus,"60 COINS + 36 XP",1,true)~=nil,"Bonus only, not multiplied total")
    model:Apply({districtResult=result(1),districtReceipt=pending})check(model.receipt.revision==2)
    local duplicate=receipt(1,2,"paid")duplicate.coins=99999
    model:Apply({districtReceipt=duplicate})check(model.receipt.coins==60,"Duplicate revision cannot replace current payment")
    model:Apply({districtReceipt=receipt(2,99,"paid")})check(model.receipt.resultId=="run:1")
    local capped=receipt(1,3,"capped")capped.coins=0 capped.xp=0
    model:Apply({districtReceipt=capped})check(model.receipt.coins==0 and model:Lines().status=="REWARD CAP REACHED")
    for index,status in ipairs({"readOnly","capacity"})do
        model:Apply({districtReceipt=receipt(1,3+index,status)})
        check(string.find(model:Lines().status,"NOT SETTLED",1,true)~=nil)
    end
    check(model:Apply({districtResult=result(2),districtReceipt=receipt(1,99,"paid")}))
    check(model.receipt==nil and model.result.stage==2 and model.reveals==2)
    model:Apply({districtReceipt=receipt(2,1,"paid")})
    model:Apply({districtResult=result(1),districtReceipt=false})check(model.result.stage==2 and model.receipt~=nil,"Old district cannot clear current receipt")
    model:Apply({districtResult=false,districtReceipt=false})check(model.result==nil and model.receipt==nil)
    check(not model:Apply({districtResult=result(2),districtReceipt=receipt(2,2,"paid")})and model.reveals==2,"Retry must not replay rank entrance")
    check(model:Lines().bounty=="BOUNTY RECEIVED / 0 COINS + 0 XP","Old receipt must default missing bounty to zero")
    local bounty=receipt(2,3,"paid")bounty.bountyCoins=25 bounty.bountyXP=0
    model:Apply({districtReceipt=bounty})check(model:Lines().bounty=="BOUNTY RECEIVED / 25 COINS + 0 XP")
    check(model.receipt.coins==60 and model.receipt.basePaidCoins==150,"Bounty cannot merge into base or rank bonus")
    local malformed=receipt(2,4,"paid")malformed.bountyCoins=-1 malformed.bountyXP=0/0
    model:Apply({districtReceipt=malformed})check(model:Lines().bounty=="BOUNTY RECEIVED / -- COINS + -- XP")
    local invalid=receipt(2,-1,"paid")model:Apply({districtReceipt=invalid})check(model.receipt.revision==4)
    for _,style in ipairs({false,{}, {score=0/0,multiplier=math.huge,progress=-3}})do
        local display=Model.Style(style)check(display.score==0 and display.multiplier==1 and display.progress==0)
    end
    local style=Model.Style({score=312.7,multiplier=7,progress=2})check(style.score==312 and style.multiplier==4 and style.progress==1)
    return {passed=true,checks=checks,revealCount=model.reveals,immutablePerformance=true,actualBaseAndBonusSeparate=true,
        revisionOrdering=true,expiredClear=true,noRewardAuthority=true}
end
