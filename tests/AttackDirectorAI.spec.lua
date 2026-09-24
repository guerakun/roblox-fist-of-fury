-- Server scheduling contract, independent of live players or combat records.
return function()
    local D=require(game.ServerScriptService.NightfallServer.AttackDirector)
    local state=D.New()
    local p={Name="Target"}
    local enemies,models={},{}
    for i=1,8 do
        local model={Name="Enemy"..i};table.insert(models,model)
        enemies[model]={spec={Role="Grunt"},stunnedUntil=0,launchedUntil=0,attacking=false,engaging=false,resolveAt=0,attackSerial=0}
    end
    local first=D.Assign(state,models[1],p,Vector3.new(12,0,0),Vector3.zero)
    local second=D.Assign(state,models[2],p,Vector3.new(12,0,0),Vector3.zero)
    assert(first.offset.X*second.offset.X<0,"two same-side entrants assigned opposite sides")
    local occupied={[first.index]=true,[second.index]=true}
    for i=3,6 do
        local slot=D.Assign(state,models[i],p,Vector3.new(10,0,0),Vector3.zero)
        assert(not occupied[slot.index],"six unique engagement slots");occupied[slot.index]=true
    end
    local stable=D.Assign(state,models[1],p,Vector3.new(-30,0,0),Vector3.zero)
    assert(stable==first,"positions remain stable as actors move")
    assert(D.Assign(state,models[7],p,Vector3.zero,Vector3.zero).index>6,"overflow safely waits outside primary slots")
    D.Request(state,models[1],p,false,9,10)
    D.Request(state,models[2],p,true,9,10)
    D.Request(state,models[3],p,false,0,10)
    local granted=D.Grant(state,10,2)
    assert(#granted==2 and granted[1]==models[2] and granted[2]==models[3],"rear priority, then least recent attacker")
    for _,m in ipairs(granted)do enemies[m].engaging=true end
    D.Request(state,models[4],p,true,0,10)
    assert(#D.Grant(state,10,2)==0,"reserved approach counts against cap")
    D.Sync(state,enemies,{p},11)
    assert(state.tokens[models[2]] and state.tokens[models[3]],"approach reservation survives next tick")
    enemies[models[2]].engaging=false;enemies[models[2]].attacking=true;enemies[models[2]].stunnedUntil=12
    D.Sync(state,enemies,{p},11.1)
    assert(not state.tokens[models[2]],"stagger returns token")
    D.Request(state,models[4],p,false,0,11.1)
    assert(#D.Grant(state,11.1,2)==1,"returned token can be reused")
    enemies[models[4]].engaging=true
    D.Sync(state,enemies,{p},13)
    assert(not state.tokens[models[3]],"reservation expires at three seconds")
    D.Sync(state,enemies,{},13.1)
    assert(next(state.slots)==nil and next(state.tokens)==nil,"departed target releases slots and tokens")
    D.Assign(state,models[1],p,Vector3.zero,Vector3.zero)
    D.Request(state,models[1],p,false,0,20);D.Grant(state,20,2)
    D.Reset(state)
    assert(next(state.slots)==nil and next(state.tokens)==nil and next(state.requests)==nil,"wave reset clears scheduler")
    -- Beginning near the approach lease deadline must not let a live windup exceed the cap.
    D.Assign(state,models[1],p,Vector3.zero,Vector3.zero)
    D.Request(state,models[1],p,false,0,30);D.Grant(state,30,1)
    enemies[models[1]].attacking=true;enemies[models[1]].stunnedUntil=0;enemies[models[1]].resolveAt=33.6
    D.BeginAttack(state,models[1],32.9,34.2)
    D.Sync(state,enemies,{p},33.1)
    D.Assign(state,models[2],p,Vector3.zero,Vector3.zero)
    D.Request(state,models[2],p,true,0,33.1)
    assert(#D.Grant(state,33.1,1)==0 and state.tokens[models[1]],"late-started windup retains token past approach deadline")
    D.Release(state,models[1]);assert(not state.tokens[models[1]],"attack end explicitly returns renewed token")
    D.Reset(state)
    for i=1,4 do D.Assign(state,models[i],p,Vector3.zero,Vector3.zero);D.Request(state,models[i],p,false,0,40)end
    assert(#D.Grant(state,40,4)==4,"four fixture reservations")
    local trimmed=D.Trim(state,2)
    local retained=0;for _ in pairs(state.tokens)do retained+=1 end
    assert(#trimmed==2 and retained==2 and state.tokens[models[1]] and state.tokens[models[2]],"cap drop removes newest reservations deterministically")
    D.Reset(state)
    local departed={Name="Departed"};local survivor={Name="Survivor"}
    D.Assign(state,models[1],departed,Vector3.zero,Vector3.zero)
    D.Request(state,models[1],departed,false,0,50);D.Grant(state,50,1)
    local capturedSerial=9
    enemies[models[1]].attackSerial=capturedSerial;enemies[models[1]].attacking=true
    enemies[models[1]].resolveAt=51;enemies[models[1]].stunnedUntil=0
    D.BeginAttack(state,models[1],50,52)
    local cancelled=D.Sync(state,enemies,{survivor},50.2)
    assert(#cancelled==1 and cancelled[1]==models[1],"departed target emits warning cancellation")
    assert(not enemies[models[1]].attacking and enemies[models[1]].attackSerial~=capturedSerial,"captured old resolver invalidated before token reuse")
    D.Assign(state,models[2],survivor,Vector3.zero,Vector3.zero)
    D.Request(state,models[2],survivor,false,0,50.2)
    assert(#D.Grant(state,50.2,1)==1,"survivor's cap reused only after old attack cancelled")
    for n=1,4 do assert(D.Cap(n)==n+1,"Normal party cap")end
    return "PASS: opposite-side/unique/stable/overflow slots; priority; reservation cap; stagger/expiry/leave/reset cleanup; 2–5 Normal tokens"
end
