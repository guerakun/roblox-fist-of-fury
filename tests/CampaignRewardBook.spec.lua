return function(Book,Ledger,Policy)
    local b=Book.new(Ledger,Policy)
    assert(b:Get(1,'a')==nil and b:Begin('a'))
    local ledger=b:Get(1,'a')
    assert(ledger:Record(1,1,25,35))
    local data={coins=0,xp=0}
    local _,paid=ledger:PayEncounter(data,1,1)
    assert(paid and data.coins==25 and data.xp==35)
    assert(b:Begin('a') and b:Get(1,'a')==ledger,'same-run reconnect lost journal')
    _,paid=b:Get(1,'a'):PayEncounter(data,1,1)
    assert(not paid and data.coins==25 and data.xp==35)
    assert(b:Begin('b') and b:Get(1,'a')==nil and not b:Begin('a'),'stale callback reopened old campaign')
    local nextLedger=b:Get(1,'b')
    assert(nextLedger~=ledger and nextLedger:Record(1,1,25,35))
    _,paid=nextLedger:PayEncounter(data,1,1)
    assert(paid and data.coins==50 and data.xp==70,'fresh campaign reused old keys')
    assert(b:Get(0,'b')==nil and b:Get(1,'forged')==nil)
    local capacity=Book.new(Ledger,Policy) assert(capacity:Begin('capacity'))
    local first
    for id=1,256 do local item=capacity:Get(id,'capacity');assert(item);if id==1 then first=item end end
    assert(capacity:Get(257,'capacity')==nil and capacity.count==256,'campaign user bound')
    assert(capacity:Get(1,'capacity')==first,'capacity evicted existing reconnect journal')
    assert(capacity:Get(0/0,'capacity')==nil and capacity:Get(math.huge,'capacity')==nil and capacity:Get(1.5,'capacity')==nil)
    assert(capacity:Begin('next') and capacity:Get(257,'next') and capacity.count==1,'new campaign did not reset capacity')
    assert(not capacity:Begin('capacity') and capacity:Get(1,'capacity')==nil,'retired campaign reopened')
    return {passed=true,scope='campaign rotation, same-run journal identity, stale lookup rejection, 256-user bound, new-run reward eligibility; Progression must revalidate captured callbacks'}
end
