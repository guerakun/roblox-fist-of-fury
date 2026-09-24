return function()
    local C=require(game.ServerScriptService.NightfallServer.TeleportCoordinator)
    local tasks,calls,failures={},{},{}
    local fail=true
    local c=C.new({send=function(place,players,options)table.insert(calls,{place=place,players=players,options=options})if fail then error('injected')end end,
        delay=function(seconds,fn)table.insert(tasks,{seconds=seconds,fn=fn})end,
        exhausted=function(player,token)table.insert(failures,{player=player,token=token})end})
    local a,b={},{}local options={matchId='only-record-id'}
    assert(c:Start({a,b},123,options,'match'))
    assert(not c:Start({a},123,options,'match'),'duplicate dispatch suppressed')
    assert(#tasks==2 and tasks[1].seconds==1)
    c:Failed(a,999,'unrelated')assert(#tasks==2,'unrelated destination ignored')
    while #tasks>0 do local task=table.remove(tasks,1)task.fn()end
    assert(#calls==5 and #failures==2,'initial group plus two retries per member')
    assert(not c.pending[a] and not c.pending[b],'exhausted entries cleared')
    fail=false c:Start({a},123,options,'next')c:Failed(a,123,'late init failure')c:Remove(a)
    local before=#calls while #tasks>0 do table.remove(tasks,1).fn()end
    assert(#calls==before,'departed players never retried')
    return 'PASS: group dispatch, duplicate suppression, three-attempt cap, backoff, unrelated failure rejection, departed cleanup'
end
