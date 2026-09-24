return function()
    local A=require(game.ServerScriptService.NightfallServer.CampaignAdmission)
    local now=100
    local match={id='m',members={1,2,3},difficulty='Normal',heat={'Frenzy'},privateServerId='private',created=100,status='Ready'}
    local service={ValidateJoin=function(_,uid,id,private)
        if id~='m' or private~='private' or not table.find(match.members,uid)then return nil,'rejected'end return match
    end}
    local a=A.new(service,{clock=function()return now end,privateId='private'})
    assert(not a:Admit(1,{}),'direct entry rejected')
    assert(not a:Admit(9,{TeleportData={matchId='m'}}),'forged membership rejected')
    local ok,record=a:Admit(1,{TeleportData={matchId='m',difficulty='Nightmare',heat={'Injected'}}})
    assert(ok and record.difficulty=='Normal' and record.heat[1]=='Frenzy','record is authoritative')
    assert(not a:Ready(),'wait for arrivals')
    a:Admit(2,{TeleportData={matchId='m'}})
    now=129 assert(not a:Ready(),'full arrival window')
    now=130 assert(a:Ready(),'timeout starts with present members')
    a:Remove(1)a:Remove(2)assert(not a:Ready(),'empty cannot start')
    local b=A.new(service,{privateId='wrong'})assert(not b:Admit(1,{TeleportData={matchId='m'}}),'reserved server bound')
    now=110 match.failed={['3']=true}
    assert(not a:Admit(3,{TeleportData={matchId='m'}}),'failed travel cannot reenter')
    a:Admit(1,{TeleportData={matchId='m'}})a:Admit(2,{TeleportData={matchId='m'}})
    assert(a:Ready(),'failed member does not block ready')
    a:Remove(1)a:Remove(2)now=200 a:Admit(1,{TeleportData={matchId='m'}})assert(not a:Ready(),'empty server starts fresh arrival window')
    now=230 assert(a:Ready(),'fresh arrival timeout completes')
    return {assertions=12,authority=true,timeout=30}
end
