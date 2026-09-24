return function(Ledger,Policy)
    local n=0 local function check(v)assert(v)n+=1 end
    local l=Ledger.new('bounty-run',Policy);local data={coins=0,xp=0}
    check(l:Record(1,1,100,100))check(l:PayEncounter(data,1,1))
    check(l:RecordBounty(1,1,25,0))check(l:RecordBounty(1,1,25,0))
    check(not l:RecordBounty(1,1,999,0))
    local r,fresh=l:PayBounty(data,1,1)
    check(fresh and data.coins==125 and data.xp==100 and r.paymentKey=='bounty-run:1:1:bounty')
    check(r.bountyCoins==25 and r.basePaidCoins==100 and r.coins==0)
    r,fresh=l:PayBounty(data,1,1)check(not fresh and data.coins==125)
    local result={campaignId='bounty-run',id='bounty-run:1',stage=1,rank='S',difficulty='Normal',score=100,duration=100,parTime=120,damageTaken=10,heat={}}
    local frozen,bonus=l:Complete(result,0)
    check(frozen and bonus.coins==50 and bonus.xp==50)
    l:PayDistrict(data,1);r=l:Receipt(1)
    check(data.coins==175 and data.xp==150 and r.status=='paid' and r.bountyCoins==25 and r.coins==50)
    check(not l:RecordBounty(1,2,25,0))check(l:RecordBounty(1,1,25,0))
    local pending=Ledger.new('pending',Policy)
    check(pending:RecordBounty(2,3,25,0))
    r,fresh=pending:PayBounty(nil,2,3)check(r.status=='readOnly' and not fresh and #pending.order==0)
    local capped={coins=Policy.Cap-5,xp=Policy.Cap}
    r,fresh=pending:PayBounty(capped,2,3)check(fresh and r.bountyCoins==5 and capped.coins==Policy.Cap)
    r,fresh=pending:PayBounty(capped,2,3)check(not fresh and r.bountyCoins==5)
    for _,v in ipairs({0,5,1.5,0/0,math.huge,'1'})do check(not pending:RecordBounty(1,v,25,0))end
    check(not pending:RecordBounty(1,1,-1,0))check(not pending:RecordBounty(1,1,25,0/0))
    local capacity=Ledger.new('capacity',Policy);capacity:RecordBounty(1,1,25,0)
    for i=1,1024 do capacity.order[i]='taken'..i end
    r,fresh=capacity:PayBounty({coins=0,xp=0},1,1)check(not fresh and r.status=='capacity')
    return {passed=true,checks=n,scope='pure bounty journal; actual remote/Progression integration separate'}
end
