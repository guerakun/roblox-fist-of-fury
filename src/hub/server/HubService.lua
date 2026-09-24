local H={}
local Players=game.Players
local Shared=game.ReplicatedStorage.Nightfall.Shared
local Config=require(Shared.Config)
local Places=require(Shared.PlaceIds)
local ProfileConfig=require(Shared.ProgressionConfig)
local ProfileStore=require(script.Parent.ProfileStore)
local Matchmaking=require(script.Parent.MatchmakingService)
local Adapter=require(script.Parent.MatchmakingAdapter)
local Transport=require(script.Parent.TeleportCoordinator)
local Preparation=require(script.Parent.DeparturePreparation)
local ReturnParty=require(script.Parent.ReturnPartyService)
local Analytics=require(script.Parent.LaunchAnalytics)
local SnapshotCache=require(script.Parent.HubSnapshotCache)
local InvitationCache=require(script.Parent.InvitationCache)
local studio=game:GetService('RunService'):IsStudio()
local profiles,messages,rates,busy,dispatching={},{},{},{},{}
local invitations=InvitationCache.new()
local service,adapter,store,transport,remotes,preparation,returnParty
local partySnapshots
local stopping=false
local recovering={} local restoring={}
local recoverMember
local function report(p,message)if p.Parent then messages[p]=message end end
local function unlocked(p,difficulty)
    if difficulty=='Normal'then return true end
    local profile=profiles[p]local tiers=profile and profile.data.completedTiers or {}
    return difficulty=='Hard' and tiers.Normal==true or difficulty=='Nightmare' and tiers.Hard==true
end
local function snapshot(p)
    local raw=partySnapshots:Get(p.UserId)local party
    if raw then
        party={id=raw.id,leader=raw.leader,members={},status=raw.status,queuedAt=raw.queueAt,difficulty=raw.difficulty or 'Normal',heat=raw.heat or {}}
        for _,uid in ipairs(raw.members)do local q=Players:GetPlayerByUserId(uid)table.insert(party.members,{userId=uid,name=q and q.DisplayName or 'Rejoining member'})end
    end
    local available={}for _,q in ipairs(Players:GetPlayers())do table.insert(available,{userId=q.UserId,name=q.DisplayName})end
    local invites={}for id,info in pairs(invitations:List(p.UserId))do table.insert(invites,{partyId=id,leaderName=info.name})end
    local profile=profiles[p]
    return {kind='HubState',party=party,invites=invites,players=available,message=messages[p],selectedHero=profile and profile.data.hero or 'Gale',
        unlocks={Normal=true,Hard=unlocked(p,'Hard'),Nightmare=unlocked(p,'Nightmare')},studio=studio,saveStatus=profile and profile.mode or 'Loading',deploymentHeld=preparation.owned[p]~=nil or recovering[p]~=nil or restoring[p]~=nil}
end
local function publish(p)
    local ok,value=pcall(snapshot,p)
    if p.Parent then if ok then remotes.State:FireClient(p,value)else report(p,'Party service is reconnecting. Your queue entry is retained.')end end
end
local function failMember(p,matchId)
    -- A failed member returns to an independent hub party; the campaign can start without them.
    local party=service:PartyFor(p.UserId)
    adapter:Update('Match:'..matchId,function(m)if m then m.failed=m.failed or {}m.failed[tostring(p.UserId)]=true end return m end,600)
    if party and party.matchId==matchId then
        adapter:Update('Party:'..party.id,function(old)
            if old and old.matchId==matchId then local i=table.find(old.members,p.UserId)if i then table.remove(old.members,i)end if old.leader==p.UserId then old.leader=old.members[1]end end return old
        end,600)
        adapter:Update('Member:'..p.UserId,function(old)if old and old.partyId==party.id then return {partyId=false}end return old end,600)
    end
    service:Create(p.UserId)
end
local function ready(matchId)
    if dispatching[matchId]then return end dispatching[matchId]=true
    task.spawn(function()
        local localMembers={}
        local ok,err=pcall(function()
            local m=adapter:Get('Match:'..matchId)if not m or m.status~='Ready'then return end
            local group={}
            for _,uid in ipairs(m.members)do local p=Players:GetPlayerByUserId(uid)if p then table.insert(localMembers,p)end end
            for _,uid in ipairs(m.members)do
                local p=Players:GetPlayerByUserId(uid)
                if p and not transport.pending[p] and not recovering[p] and not (m.failed and m.failed[tostring(uid)])then
                    if studio then
                        report(p,'Deployment simulation passed. Real travel requires the configured test universe.')
                        local party=service:PartyFor(p.UserId)
                        if party then adapter:Update('Party:'..party.id,function(old) if old and old.matchId==matchId then old.status='Idle' old.matchId=nil old.revision+=1 old.queueAt=nil end return old end,600)end
                    else
                        table.insert(group,p)
                    end
                end
            end
            if #group>0 then
                assert(Places.Campaign>0,'Campaign destination is not configured.')
                preparation:Prepare(group,matchId)
                local options=Instance.new('TeleportOptions')options.ReservedServerAccessCode=m.accessCode options:SetTeleportData({matchId=m.id})
                transport:Start(group,Places.Campaign,options,m.id)
            end
        end)
        if not ok then
            warn('[Hub] Deployment deferred: '..tostring(err))
            for _,p in ipairs(localMembers)do
                local profile=profiles[p]
                if profile and profile.mode=='Unavailable' then
                    report(p,'Your save session expired. Progress remains read-only. Rejoin the refuge to restore your save connection.')
                else report(p,'Deployment is held while your progress is saved. Retrying safely.')end
            end
            for p,owned in pairs(preparation.owned)do
                if owned.token==matchId then
                    if owned.profile.mode=='Unavailable' then
                        report(p,'Your save session expired. Progress remains read-only. Rejoin the refuge to restore your save connection.')
                        -- Preserve the unavailable object; never replace it with writable defaults.
                        task.spawn(function()pcall(function()failMember(p,matchId)end)end)
                    else report(p,'Deployment is held while your progress is saved. Retrying safely.')end
                end
            end
        end
        dispatching[matchId]=nil
    end)
end
recoverMember=function(p)
    local recovery=recovering[p]
    if not recovery or recovery.working or not p.Parent or os.clock()<recovery.nextTry then return end
    recovery.working=true
    local ok=pcall(function()
        failMember(p,recovery.matchId)
        local profile=profiles[p]
        if not profile or profile.mode=='Released' or profile.closing or profile.mode=='Unavailable' then
            local loaded=store:Load(p.UserId)
            if p.Parent~=Players or recovering[p]~=recovery then store:Release(loaded)return end
            profiles[p]=loaded
        end
        assert(store:CanMutate(profiles[p]),'profile recovery pending')
        preparation:Clear(p)
    end)
    recovery.working=false
    if p.Parent~=Players or recovering[p]~=recovery then return end
    if ok then recovering[p]=nil report(p,'Travel failed. You are safe in the refuge and can queue again.')
    else recovery.backoff=math.min(30,recovery.backoff*2)recovery.nextTry=os.clock()+recovery.backoff report(p,'Party service is recovering. Your progress is protected; please wait.')end
    publish(p)
end
local allowedRequests={SelectHero=true,Invite=true,Accept=true,Leave=true,Cancel=true,Queue=true,Refresh=true}
local function request(p,action,payload)
    if not allowedRequests[action]then return end
    if type(action)~='string' or (payload~=nil and type(payload)~='table') or busy[p]then return end
    local rate=rates[p]or{at=os.clock(),count=0}rates[p]=rate
    if os.clock()-rate.at>2 then rate.at=os.clock()rate.count=0 end rate.count+=1 if rate.count>10 then return end
    if transport.pending[p] or preparation.owned[p] or recovering[p] or restoring[p]then return end
    if action=='Refresh'then publish(p)return end
    payload=payload or{}busy[p]=true
    local ok,err=pcall(function()
        if action=='SelectHero'then
            assert(Config.Characters[payload.hero],'unknown hero')local profile=profiles[p]
            assert(store:CanMutate(profile),'profile is read-only')profile.data.hero=payload.hero store:MarkChanged(profile)
        elseif action=='Invite'then
            local target=type(payload.userId)=='number' and Players:GetPlayerByUserId(payload.userId)
            assert(target,'Choose a player in this refuge.')assert(service:Invite(p.UserId,target.UserId),'Invite unavailable.')
            local party=service:PartyFor(p.UserId)invitations:Add(target.UserId,party.id,p.DisplayName)
        elseif action=='Accept'then assert(service:Accept(p.UserId,payload.partyId),'Invite expired or party unavailable.')
            invitations:Accept(p.UserId,payload.partyId)
        elseif action=='Leave'then assert(service:Leave(p.UserId),'Deployment already starting.')service:Create(p.UserId)
        elseif action=='Cancel'then assert(service:Cancel(p.UserId),'Only the leader can cancel a queued deployment.')
        elseif action=='Queue'then
            local difficulty=payload.difficulty or 'Normal'local heat=payload.heat or{}
            assert(type(heat)=='table' and #heat<=6,'Invalid contract selection.')
            local seen={}for _,id in ipairs(heat)do assert(type(id)=='string' and Config.HeatContracts and Config.HeatContracts[id] and not seen[id],'Contract unavailable.')seen[id]=true end
            local party=assert(service:PartyFor(p.UserId),'Party unavailable.')assert(party.leader==p.UserId,'Only the party leader can deploy.')
            for _,uid in ipairs(party.members)do local member=Players:GetPlayerByUserId(uid)assert(member and unlocked(member,difficulty),'Every member must be here and have this difficulty unlocked.')assert(store:CanMutate(profiles[member]),'Every member needs a loaded, writable save session before deployment.')end
            assert(service:Queue(p.UserId,difficulty,heat,payload.mode,party.revision),'Queue unavailable.')report(p,'Deployment queued.')
        elseif action=='Refresh'then return
        else error('Unknown request.')end
    end)
    busy[p]=nil if not ok then report(p,tostring(err):gsub('^.-:%d+: ',''))elseif action~='Queue' and action~='Refresh'then messages[p]=nil end
    for _,member in ipairs(Players:GetPlayers())do publish(member)end
end
function H.Init()
    remotes=game.ReplicatedStorage.HubRemotes
    store=ProfileStore.new(not studio and game:GetService('DataStoreService'):GetDataStore(ProfileConfig.DataStoreName)or nil,{ephemeral=studio})
    adapter=Adapter.new({onReady=ready})service=Matchmaking.new(adapter)returnParty=ReturnParty.new(adapter)
    partySnapshots=SnapshotCache.new({ttl=5,load=function(id)return service:PartyFor(id)end})
    preparation=Preparation.new({profile=function(p)return profiles[p]end,canMutate=function(profile)return store:CanMutate(profile)end,release=function(profile)return store:Release(profile)end})
    transport=Transport.new({send=function(place,group,options)game:GetService('TeleportService'):TeleportAsync(place,group,options)end,delay=task.delay,
        exhausted=function(p,matchId)
            recovering[p]={matchId=matchId,nextTry=0,backoff=1}
            report(p,'Travel failed after three attempts. Recovering your refuge party safely.')
            task.spawn(recoverMember,p)
        end})
    game:GetService('TeleportService').TeleportInitFailed:Connect(function(p,_,message,place)transport:Failed(p,place,message)end)
    remotes.Request.OnServerEvent:Connect(request)
    local function joined(p)
        Analytics.HubJoin(p)
        local loaded=store:Load(p.UserId)
        if p.Parent~=Players then store:Release(loaded)return end
        profiles[p]=loaded
        restoring[p]=true
        task.spawn(function()
            local delay=1
            while p.Parent==Players and restoring[p]do
                local ok=pcall(function()
                    local join=p:GetJoinData()local returned,_,note=false,nil,nil
                    if not studio and join.SourcePlaceId==Places.Campaign then returned,_,note=returnParty:Restore(p.UserId,join)end
                    if not returned then assert(service:Create(p.UserId),'party creation deferred')end
                    if note then report(p,note)end
                end)
                if p.Parent~=Players then pcall(function()service:Leave(p.UserId)end)restoring[p]=nil break end
                if ok then restoring[p]=nil publish(p)break end
                report(p,'Restoring your refuge party. Your progress is protected; please wait.')publish(p)
                task.wait(delay)delay=math.min(30,delay*2)
            end
        end)
        if p.Parent~=Players then pcall(function()service:Leave(p.UserId)end)return end
        publish(p)
    end
    Players.PlayerAdded:Connect(joined)
    Players.PlayerRemoving:Connect(function(p)
        local wasTeleporting=transport.pending[p]~=nil transport:Remove(p)preparation:Clear(p)
        if not wasTeleporting then pcall(function()service:Leave(p.UserId)end)end
        local profile=profiles[p]profiles[p]=nil if profile and profile.mode~='Released'then task.spawn(function()store:Release(profile)end)end
        rates[p],busy[p],messages[p],recovering[p],restoring[p]=nil,nil,nil,nil,nil
        invitations:Remove(p.UserId)partySnapshots:Remove(p.UserId)
    end)
    for _,p in ipairs(Players:GetPlayers())do task.spawn(joined,p)end
    task.spawn(function()
        local backoff=2 local subscribed=studio
        while not stopping do
            invitations:Sweep()
            local ok=pcall(function()
                if not subscribed then adapter:Subscribe()subscribed=true end
                for _,difficulty in ipairs({'Normal','Hard','Nightmare'})do service:Step(difficulty)end
            end)
            backoff=ok and 2 or math.min(30,backoff*2)
            for _,p in ipairs(Players:GetPlayers())do publish(p)if recovering[p]then task.spawn(recoverMember,p)end end
            task.wait(backoff)
        end
    end)
    task.spawn(function()
        while not stopping do
            task.wait(30)
            for p,profile in pairs(profiles)do
                pcall(function()service:Refresh(p.UserId)end)
                if profile.mode=='Saved'then task.spawn(function()store:Save(profile,false)end)end
            end
        end
    end)
    game:BindToClose(function()
        stopping=true local outstanding=0
        for _,profile in pairs(profiles)do if profile.mode~='Released'then outstanding+=1 task.spawn(function()store:Release(profile)outstanding-=1 end)end end
        local deadline=os.clock()+25 while outstanding>0 and os.clock()<deadline do task.wait(.1)end
    end)
end
return H
