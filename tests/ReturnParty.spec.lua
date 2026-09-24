return function()
    local R=require(game.ServerScriptService.NightfallServer.ReturnPartyService)
    local records={}local n=0 local now=100
    local adapter={Get=function(_,k)return records[k]end,Set=function(_,k,v)records[k]=v end,Update=function(_,k,fn)local v=fn(records[k])if v then records[k]=v end return records[k]end}
    local function make(server)return R.new(adapter,{server=server,clock=function()return now end,guid=function()n+=1 return 'id'..n end})end
    local r=make('hub1')
    local m={id='match',members={1,2,3},parties={{id='old',leader=1,members={1,2}},{id='other',leader=3,members={3}}}}
    records['Member:1']={partyId='old'}records['Member:2']={partyId='old'}records['Member:3']={partyId='other'}
    local returned=r:Create(m,{1,2,3})local join={TeleportData={returnId=returned.id,members={99}}}
    assert(not r:Restore(99,join),'forged return rejected')
    local ok,p=r:Restore(2,join)assert(ok and #p.members==1 and p.members[1]==2 and p.leader==2,'first arrival usable, missing leader not blocking')
    local ok2,p2=r:Restore(1,join)assert(ok2 and #p2.members==2 and p2.leader==1 and p.id==p2.id,'original party leader restored')
    r:Restore(1,join)assert(#p2.members==2,'idempotent arrival')
    local ok3,p3=r:Restore(3,join)assert(ok3 and p3.id~=p.id,'quickmatch strangers not merged into party')
    local moved,solo=make('hub2'):Restore(2,join)assert(not moved,'newer restored membership cannot be stolen across hubs')
    records['Member:1']={partyId='newer'}assert(not r:Restore(1,join),'replayed return cannot overwrite newer party')
    local r2=make('hub1')local again=r2:Create(m,{1,2,3})local join2={TeleportData={returnId=again.id}}
    records['Member:1']={partyId='old'}records['Member:2']={partyId='old'}
    local first,party=r2:Restore(1,join2)assert(first,'new return initializes')
    party.status='Queued'
    local late,separate=r2:Restore(2,join2)assert(late and separate.id~=party.id and #party.members==1,'late return cannot mutate queued roster')
    local retryRecord=r2:Create(m,{1})local retryJoin={TeleportData={returnId=retryRecord.id}}
    records['Member:1']={partyId='old'}
    local update=adapter.Update local injected=false
    function adapter:Update(k,fn)
        return update(self,k,function(old)
            local v=fn(old)
            if not injected and string.sub(k,1,6)=='Party:' and v and #v.members>0 then injected=true error('injected append throttle')end
            return v
        end)
    end
    assert(not pcall(function()r2:Restore(1,retryJoin)end),'append throttle reported for retry')
    assert(records['Member:1'].partyId==false,'failed append compensates only owned claim')
    assert(r2:Restore(1,retryJoin),'retry completes after append throttle')
    local ambiguous=r2:Create(m,{3})records['Member:3']={partyId='other'}local uncertain=false
    adapter.Update=update
    function adapter:Update(k,fn)local v=update(self,k,fn)if not uncertain and string.sub(k,1,6)=='Party:'and v and #v.members>0 then uncertain=true error('reply lost after commit')end return v end
    assert(r2:Restore(3,{TeleportData={returnId=ambiguous.id}}),'ambiguous append reads back successful membership')
    now=701 assert(not r:Restore(2,join),'expired return rejected')
    assert(not pcall(function()r:Create(m,{99})end),'foreign departure rejected')
    return {assertions=16,partyRestoration=true,forgeryRejected=true}
end
