return function()
    local S=require(game.ServerScriptService.NightfallServer.MatchmakingService)
    local function clone(v)if type(v)~='table'then return v end local r={}for k,x in pairs(v)do r[k]=clone(x)end return r end
    local function fixture()
        local a={records={},queue={},dispatches={},now=0,counter=0,reserves=0}
        function a:Fail(op,key)if self.fail==op..':'..tostring(key) then self.fail=nil error('injected throttle')end end
        function a:Get(k)self:Fail('get',k)return clone(self.records[k])end
        function a:Set(k,v)self:Fail('set',k)self.records[k]=clone(v)end
        function a:Update(k,fn)self:Fail('update',k)local v=fn(clone(self.records[k])) if v~=nil then self.records[k]=clone(v)end return clone(self.records[k])end
        function a:Remove(k)self.records[k]=nil end
        function a:PutQueue(d,v)self:Fail('putqueue',d)self.queue[d]=self.queue[d]or{} self.queue[d][v.partyId]=clone(v)end
        function a:ListQueue(d,count)local r={}for _,v in pairs(self.queue[d]or{})do table.insert(r,clone(v))end table.sort(r,function(x,y)return x.queuedAt==y.queuedAt and x.partyId<y.partyId or x.queuedAt<y.queuedAt end)while #r>(count or 40) do table.remove(r)end return r end
        function a:RemoveQueue(d,id,rev)self:Fail('removequeue',id)if self.queue[d] and self.queue[d][id] and self.queue[d][id].revision==rev then self.queue[d][id]=nil end end
        function a:Reserve()self:Fail('reserve','')self.reserves+=1 if self.onReserve then local f=self.onReserve self.onReserve=nil f()end return 'access'..self.reserves,'private'..self.reserves end
        function a:Dispatch(m)self:Fail('dispatch','')self.dispatches[m.id]=clone(m)end
        local options={clock=function()return a.now end,guid=function()a.counter+=1 return 'id'..a.counter end,server='hubA'}
        return a,S.new(a,options),S.new(a,options)
    end
    local count=0 local function check(v,label)assert(v,label)count+=1 end
    local function party(s,ids)
        local p=s:Create(ids[1])for i=2,#ids do assert(s:Invite(ids[1],ids[i]))assert(s:Accept(ids[i],p.id))end return s:PartyFor(ids[1])
    end
    do local a,s,t=fixture()
        local p=party(s,{1,2,3}) local q=party(s,{4,5}) s:Queue(1,'Normal',{})s:Queue(4,'Normal',{})
        a.now=21 a.onReserve=function()local other=t:Step('Normal')check(other==nil,'two matchmakers cannot double claim')end
        local m=s:Step('Normal')check(m and #m.members==3,'never split a party to fill four')
        check(s:PartyFor(4).status=='Queued','overflow party retained')
        check(s:ValidateJoin(1,m.id,m.privateServerId)~=nil,'listed member accepted')
        check(s:ValidateJoin(99,m.id,m.privateServerId)==nil,'forged membership rejected')
        check(s:ValidateJoin(1,m.id,'wrong')==nil,'wrong reserved server rejected')
        local m2=t:Step('Normal')check(m2 and #m2.members==2 and m2.id~=m.id,'next whole party launches separately')
    end
    do local a,s=fixture()party(s,{1,2})s:Queue(1,'Normal',{})check(s:Step('Normal')==nil,'waits before20seconds')a.now=20 check(s:Step('Normal')~=nil,'timeout launches incomplete party')end
    do local a,s=fixture()party(s,{1,2,3})s:Queue(1,'Normal',{})check(s:Leave(1),'leader leaves queued party')local p=s:PartyFor(2)check(p.leader==2 and p.status=='Idle' and #p.members==2,'leader reassigned and queue invalidated')a.now=25 check(s:Step('Normal')==nil,'stale ticket cannot launch')end
    do local a,s=fixture()party(s,{1,2})s:Queue(1,'Normal',{})check(s:Leave(2),'member leaves queued party')check(#s:PartyFor(1).members==1 and s:PartyFor(1).status=='Idle','member departure invalidates roster')end
    do local a,s=fixture()s:Create(1)a.fail='putqueue:Normal'check(not pcall(function()s:Queue(1,'Normal',{})end),'queue throttle surfaced')check(s:PartyFor(1).status=='Queued','throttle retains visible queued state')s:Refresh(1)a.now=21 check(s:Step('Normal')~=nil,'refresh repairs missing queue ticket')end
    do local a,s=fixture()s:Create(1)s:Queue(1,'Normal',{})a.now=21 a.fail='reserve:'check(s:Step('Normal')==nil,'reserve failure returns no match')check(s:PartyFor(1).status=='Queued','reserve failure rolls back claim')a.now=52 check(s:Step('Normal')~=nil,'reserve retry succeeds')end
    do local a,s=fixture()local p=s:Create(1)s:Queue(1,'Normal',{})a.now=21 a.fail='removequeue:'..p.id local m=s:Step('Normal')check(m~=nil,'Ready survives postcommit cleanup throttle')s:Refresh(1)check(s:PartyFor(1).status=='Matched' and a.dispatches[m.id]~=nil,'durable Ready recovery dispatches')end
    do local a,s=fixture()s:Create(1)s:Queue(1,'Normal',{})a.now=21 a.fail='dispatch:'local m=s:Step('Normal')check(m~=nil and a.dispatches[m.id]==nil,'dispatch failure retains durable match')s:Refresh(1)check(a.dispatches[m.id]~=nil,'refresh retries dispatch')end
    do local a,s=fixture()a.fail='set:Party:id1'check(not pcall(function()s:Create(1)end),'party create throttle surfaced')check(s:Create(1)~=nil,'failed create retry has no orphan member')end
    do local a,s=fixture()local p=s:Create(1)s:Invite(1,2)a.fail='update:Party:'..p.id check(not s:Accept(2,p.id),'accept throttle compensated')check(s:Create(2)~=nil,'failed accept membership released')end
    do local a,s=fixture()local p=s:Create(1)s:Queue(1,'Normal',{})local r=a.records['Party:'..p.id]r.status='Matching'r.matchId='missing'a.now=21 s:Step('Normal')check(s:PartyFor(1).status=='Queued','missing match claim repaired')end
    do local a,s=fixture()s:Create(1)s:Queue(1,'Normal',{})s:Queue(1,'Hard',{})check(#a:ListQueue('Hard',40)==0,'requeue cannot change bucket')a.now=21 local m=s:Step('Normal')check(m and m.difficulty=='Normal','queued difficulty remains authoritative')end
    do local a,s=fixture()
        for i=1,40 do s:Create(i)s:Queue(i,'Normal',{})s:Cancel(i)end
        a.now=1 s:Create(41)s:Queue(41,'Normal',{})a.now=22
        s:Step('Normal')local m=s:Step('Normal')check(m and m.members[1]==41,'forty stale tickets cannot starve a valid party')
    end
    do local a,s=fixture()local p=s:Create(1)s:Invite(1,2)local update=a.Update
        function a:Update(k,fn,ttl)local v=update(self,k,fn,ttl)if k=='Party:'..p.id and table.find(v.members,2)and not self.ambiguous then self.ambiguous=true error('committed but reply failed')end return v end
        check(s:Accept(2,p.id),'ambiguous acceptance reads back committed roster')check(s:PartyFor(2).id==p.id,'ambiguous acceptance preserves membership')
    end
    do local a,s=fixture()s:Create(1)s:Queue(1,'Normal',{})a.now=21 local update=a.Update
        function a:Update(k,fn,ttl)local v=update(self,k,fn,ttl)if string.sub(k,1,6)=='Match:' and v.status=='Ready'and not self.uncertainReady then self.uncertainReady=true error('Ready committed but reply failed')end return v end
        local m=s:Step('Normal')check(m and m.status=='Ready','uncertain Ready is recovered as committed')
        check(s:PartyFor(1).status=='Matched','uncertain Ready never requeues claimed party')a.now=60 check(s:Step('Normal')==nil,'uncertain Ready cannot double match')
    end
    do local a,s=fixture()
        party(s,{1,2})s:Queue(1,'Normal',{},'Solo')local m=s:Step('Normal')
        a.records['Match:'..m.id]=nil s:Refresh(1)
        check(s:PartyFor(1).status=='Idle' and s:PartyFor(1).matchId==nil,'missing match released despite removed queue ticket')
        check(s:Queue(1,'Normal',{},'Solo'),'expired deployment can requeue')
    end
    do local a,s=fixture()
        local Heat=require(game.ReplicatedStorage.Nightfall.Shared.HeatConfig)
        if not Heat.Enabled then
            s:Create(1)
            check(not pcall(function()s:Queue(1,'Normal',{'Frenzy'},'Solo')end),'unimplemented Heat rejected at queue authority')
            check(s:PartyFor(1).status=='Idle','rejected Heat leaves party idle')
            s:Queue(1,'Normal',{},'Solo');local m=s:Step('Normal')
            a.records['Match:'..m.id].heat={'Frenzy'}
            check(s:ValidateJoin(1,m.id,m.privateServerId)==nil,'unimplemented Heat match rejected at admission')
        else
            s:Create(1)
            check(s:Queue(1,'Normal',{'OneLife','Frenzy'},'Solo'),'enabled Heat queues')
            local m=s:Step('Normal')
            check(m.heat[1]=='Frenzy' and m.heat[2]=='OneLife' and #m.heat==2,'match stores canonical Heat')
            check(m.heatPoints==6 and m.heatRewardPercent==45,'match derives points and reward from authoritative metadata')
            check(s:ValidateJoin(1,m.id,m.privateServerId)~=nil,'enabled canonical Heat admitted')
            a.records['Match:'..m.id].heat={'Forged'}
            check(s:ValidateJoin(1,m.id,m.privateServerId)==nil,'enabled rollout still rejects unknown contracts')
        end
    end
    return 'PASS: '..count..' party, lease, timeout, forgery, membership and injected-throttle assertions'
end
