-- Pure cache/reward seam. This does not simulate real same-account Studio reconnect.
return function()
    local server=game.ServerScriptService.NightfallServer
    local S=require(server.StylePolicy)
    local Ledger=require(server.DistrictLedger)
    local Reward=require(server.RewardPolicy)
    local campaign="cached-style"
    local ledger=Ledger.new(campaign,Reward)
    local state=S.New(campaign,1,10)
    assert(S.BeginWave(state,1,1,"Wave",10))
    assert(S.Award(state,{id="early",kind="Hit",damage=50}))
    assert(S.CommitWave(state,1,true));assert(ledger:Record(1,1,100,80))
    local balance={coins=0,xp=0};assert(ledger:PayEncounter(balance,1,1))
    assert(S.BeginWave(state,4,1,"Boss",40))
    assert(S.Award(state,{id="before-departure",kind="Hit",damage=25}))
    -- Combat retains this same state in its bounded same-campaign disconnected cache.
    local cached={styleDistricts={[1]=state}}
    assert(S.CommitWave(cached.styleDistricts[1],4,false))
    local frozen=S.Finalize(cached.styleDistricts[1],80,{difficulty="Normal",heat={}})
    assert(frozen.score==300 and frozen.eligibleWaves==2,"Earned cached attempt score was lost")
    assert(frozen.bossDamageTaken==nil,"Absent boss clear cannot claim a no-hit boss")
    local complete,bonus=ledger:Complete(frozen,0)
    assert(complete and bonus and ledger:Base(1).coins==100,"Absent wave minted nominal base")
    local receipt,new=ledger:PayDistrict(balance,1)
    assert(new and receipt.baseCoins==100 and balance.coins==100+bonus.coins)
    local same,newAgain=ledger:PayDistrict(balance,1)
    assert(not newAgain and same.coins==receipt.coins,"Reconnect repeated bonus")
    assert(Ledger.new("new-campaign",Reward):Complete(frozen,0)==nil,"Old cache entered new campaign")
    return {passed=true,cachedAttemptPreserved=true,cachedFinalResult=true,absentBaseExcluded=true,
        absentBossBadgeExcluded=true,rejoinSettlementIdempotent=true,staleCampaignRejected=true,realReconnectVerified=false}
end
