-- Pure ledger tests; root injects the production modules.
return function(Ledger,Policy)
    local checks=0 local function check(v)assert(v)checks+=1 end
    local function result(campaign,stage,rank)
        return {id=campaign..':'..stage,campaignId=campaign,stage=stage,rank=rank or 'S',difficulty='Normal',score=1234,duration=100,parTime=120,damageTaken=42,heat={}}
    end
    local c='server-guid:run:7' local l=Ledger.new(c,Policy)
    check(l:Record(1,4,120,120)) check(l:Record(1,4,120,120))
    check(not l:Record(1,4,121,120)) check(l:Base(1).coins==120)
    local r,bonus=l:Complete(result(c,1),0)
    check(r.rank=='S' and bonus.coins==60 and bonus.xp==60)
    check(not pcall(function()r.rank='D'end))
    local replay,b=l:Complete(result(c,1,'D'),105)
    check(replay==r and b==bonus and replay.rank=='S')
    check(not l:Record(1,1,50,50)) check(l:Record(1,4,120,120))
    local readOnly,new=l:PayEncounter(nil,1,4)
    check(readOnly.status=='readOnly' and not new and #l.order==0 and l:Paid(1).coins==0)
    readOnly,new=l:PayDistrict(nil,1)
    check(readOnly.status=='readOnly' and not new and #l.order==0)
    local data={coins=0,xp=0}
    local base,baseNew=l:PayEncounter(data,1,4)
    check(baseNew and base.paymentCoins==120 and base.basePaidCoins==120 and base.coins==0)
    local paid,paidNew=l:PayDistrict(data,1)
    check(paidNew and paid.status=='paid' and paid.coins==60 and paid.paymentCoins==60)
    check(paid.baseCoins==120 and paid.basePaidCoins==120 and data.coins==180 and data.xp==180)
    check(paid.paymentKey==c..':1:rank')
    local again,againNew=l:PayDistrict(data,1)
    check(not againNew and again.revision==paid.revision and again.coins==paid.coins)
    again.coins=999 check(l:Receipt(1).coins==60)
    local oldBase,oldNew=l:PayEncounter(data,1,4)
    check(not oldNew and oldBase.revision==base.revision and oldBase.coins==0 and data.coins==180)
    local current=l:Receipt(1) check(l:Receipt(1).revision==current.revision)
    check(current.revision>=paid.revision and current.status=='paid')
    local cap=Ledger.new('cap',Policy) check(cap:Record(1,1,120,120)) cap:Complete(result('cap',1),0)
    local cappedData={coins=Policy.Cap-2,xp=Policy.Cap-1}
    local cappedBase=cap:PayEncounter(cappedData,1,1)
    local capped,cappedNew=cap:PayDistrict(cappedData,1)
    check(cappedBase.paymentCoins==2 and cappedBase.paymentXP==1)
    check(cappedNew and capped.status=='capped' and capped.coins==0 and capped.xp==0 and capped.basePaidCoins==2)
    check(cap:Base(1).coins==120 and cappedData.coins==Policy.Cap)
    local p=Ledger.new('pending',Policy) check(p:Record(1,1,100,80)) p:Complete(result('pending',1),0)
    local pd={coins=0,xp=0} local early=p:PayDistrict(pd,1)
    check(early.status=='pending' and early.coins==50 and pd.coins==50)
    p:PayEncounter(pd,1,1) check(p:Receipt(1).status=='paid' and pd.coins==150)
    check(p:Receipt(1).revision>early.revision)
    for _,field in ipairs({'score','duration','parTime','damageTaken'}) do
        local malformed=result('bad',1) malformed[field]=0/0
        check(Ledger.new('bad',Policy):Complete(malformed,0)==nil)
    end
    for _,change in ipairs({{id='forged'},{campaignId='other'},{stage=4},{rank='forged'},{difficulty='forged'},{parTime=0}}) do
        local malformed=result('bad',1) for k,v in pairs(change)do malformed[k]=v end
        check(Ledger.new('bad',Policy):Complete(malformed,0)==nil)
    end
    check(Ledger.new('bad',Policy):Complete(result('bad',1),106)==nil)
    check(not l:Record(0,1,1,1) and not l:Record(1,5,1,1) and not l:Record(2,1,-1,1))
    local full=Ledger.new('full',Policy) check(not full:FullParticipation())
    for stage=1,3 do
        for wave=1,4 do check(full:Record(stage,wave,10,10)) end
        check(not full:FullParticipation())
        full:Complete(result('full',stage),0)
    end
    check(full:FullParticipation() and not l:FullParticipation())
    -- Root supplies current profile status on every read, including after a failed payment.
    local profileReadOnly=Ledger.new('readonly',Policy) profileReadOnly:Record(1,1,10,10)
    profileReadOnly:PayEncounter(nil,1,1)
    check(profileReadOnly:Receipt(1,'readOnly').status=='readOnly')
    local mutable={coins=0,xp=0} profileReadOnly:PayEncounter(mutable,1,1)
    check(profileReadOnly:Receipt(1).status=='pending' and mutable.coins==10)
    return {passed=true,checks=checks,scope='pure player/run ledger; not ProfileStore persistence, campaign rotation or Studio integration'}
end
