-- Root owns admission/travel. Published behavior requires configured places and a reserved match record.
local Session={}
local Players=game.Players
local Places=require(game.ReplicatedStorage.Nightfall.Shared.PlaceIds)
local studio=game:GetService('RunService'):IsStudio()
local Adapter=require(script.Parent.MatchmakingAdapter)
local Matchmaking=require(script.Parent.MatchmakingService)
local Admission=require(script.Parent.CampaignAdmission)
local Return=require(script.Parent.ReturnPartyService)
local Transport=require(script.Parent.TeleportCoordinator)
local Preparation=require(script.Parent.DeparturePreparation)
function Session.Init(combat,progression)
    local adapter=Adapter.new()
    local admission=Admission.new(Matchmaking.new(adapter),{privateId=game.PrivateServerId,timeout=Places.ArrivalTimeout or 30})
    local returning=Return.new(adapter)
    local remotes=game.ReplicatedStorage.Nightfall.Remotes
    local remote=Instance.new('RemoteEvent')remote.Name='Travel'remote.Parent=remotes
    local started=false local busy=false local working=false local message='' local token,accessCode,returnRecord
    local recovering={} local recovered={}
    local preparation=Preparation.new({profile=progression.GetTravelProfile,canMutate=progression.CanMutateTravelProfile,release=progression.ReleaseTravelProfile})
    local function leader()
        local match=admission.match
        if match then
            for _,party in ipairs(match.parties)do local p=Players:GetPlayerByUserId(party.leader)if p then return p end end
        end
        local ps=Players:GetPlayers()table.sort(ps,function(a,b)return a.UserId<b.UserId end)return ps[1]
    end
    local function terminal()local status=combat.GetRunStatus()return status=='Victory'or status=='Defeat'end
    local function publish()
        for _,p in ipairs(Players:GetPlayers())do
            remote:FireClient(p,{kind='TravelState',canReturn=not studio and terminal() and leader()==p,busy=busy,
                message=terminal() and (studio and 'Refuge travel is simulated in Studio; published travel is not configured.'or message)or message})
        end
    end
    local transport=Transport.new({send=function(place,group,options)game:GetService('TeleportService'):TeleportAsync(place,group,options)end,delay=task.delay,
        exhausted=function(p)
            recovering[p]=true
            message='Return travel failed after three attempts. Recovering your save session safely.'
        end})
    local function dispatch()
        if working then return end working=true
        local ok,err=pcall(function()
            assert(Places.Hub>0,'Refuge destination is not configured.')
            local group={}for _,p in ipairs(Players:GetPlayers())do if not transport.pending[p] and not recovering[p] and not recovered[p]then table.insert(group,p)end end
            if #group==0 then return end
            if not returnRecord then
                local match=assert(admission.match,'deployment record unavailable')
                returnRecord=returning:Create(match,match.members)
                token=returnRecord.id
            end
            if not accessCode then accessCode=game:GetService('TeleportService'):ReserveServerAsync(Places.Hub)end
            preparation:Prepare(group,token)
            local options=Instance.new('TeleportOptions')options.ReservedServerAccessCode=accessCode options:SetTeleportData({returnId=token})
            transport:Start(group,Places.Hub,options,token)
            message='Returning your party to the refuge...'
        end)
        if not ok then
            message='Return is held while your progress is saved. Retrying safely.'
            for _,p in ipairs(Players:GetPlayers())do local profile=progression.GetTravelProfile(p)
                if profile and profile.mode=='Unavailable'then message='A save session expired. Progress remains read-only; rejoin the refuge to restore the save connection.'end
            end
            warn('[Campaign travel] '..tostring(err))
        end
        working=false publish()
    end
    if not studio then
        combat.SetAdmissionValidator(function(p)
            if Places.Campaign<=0 or game.PrivateServerId==''then p:Kick('Join a deployment from the refuge.')return false end
            local ok,accepted,reason=pcall(function()return admission:Admit(p.UserId,p:GetJoinData())end)
            if not ok or not accepted then p:Kick('Deployment validation failed. Rejoin the refuge to queue again.')return false end
            local match=admission.match
            if combat.SetRunOptions then
                if not combat.SetRunOptions(match.difficulty,match.heat,true)then admission:Remove(p.UserId)p:Kick('This deployment configuration is unavailable.')return false end
            elseif match.difficulty~='Normal'or #match.heat>0 then admission:Remove(p.UserId)p:Kick('This deployment configuration is unavailable.')return false end
            return true
        end)
    end
    remote.OnServerEvent:Connect(function(p,action)
        if action~='Return'or studio or busy or not terminal()or leader()~=p then return end
        recovered={} busy=true combat.SetTravelLocked(true)message='Saving party progress...'
        task.spawn(dispatch)
    end)
    game:GetService('TeleportService').TeleportInitFailed:Connect(function(p,_,reason,place)transport:Failed(p,place,reason)end)
    Players.PlayerRemoving:Connect(function(p)admission:Remove(p.UserId)transport:Remove(p)preparation:Clear(p)recovering[p]=nil recovered[p]=nil if not next(admission.arrived)then started=false end end)
    task.spawn(function()
        while true do
            task.wait(2)
            if not busy and not terminal()and not next(transport.pending)and not next(recovering)then
                returnRecord=nil accessCode=nil token=nil recovered={} message=''
            end
            if not studio and not started and admission:Ready()then
                local present={}local expected=0 for _,p in ipairs(Players:GetPlayers())do if admission.arrived[p.UserId]then expected+=1 if combat.GetSnapshot(p) and p.Character and p.Character:FindFirstChild('HumanoidRootPart')then table.insert(present,p)end end end
                if #present>0 and #present==expected then started=true combat.ReadyForMatch(present)end
            end
            local recoveringAny=next(recovering)~=nil
            for p in pairs(recovering)do
                local ok,restored=pcall(progression.ResumeAfterTravelFailure,p)
                if ok and restored then recovering[p]=nil recovered[p]=true preparation:Clear(p)end
            end
            if next(recovered) and not next(recovering)and not next(transport.pending)then
                busy=false combat.SetTravelLocked(false)message='Travel failed. Your progress is safe; the leader can retry.'
            elseif busy and not recoveringAny then dispatch()end
            publish()
        end
    end)
    return admission
end
return Session
