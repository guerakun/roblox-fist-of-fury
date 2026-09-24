-- Actual two-client fixture. Server controls test orchestration, never party membership directly.
if not game:GetService('RunService'):IsStudio()then return end
local T=game:GetService('StudioTestService')local ok,args=pcall(function()return T:GetTestArgs()end)
if not ok or type(args)~='table'or args.test~='HubParty'then return end
local qa=Instance.new('RemoteEvent')qa.Name='HubPartyQA'qa.Parent=game.ReplicatedStorage
local states={}qa.OnServerEvent:Connect(function(p,kind,value)if kind=='State'then states[p]=value end end)
local result={assertions={},passed=false}local started=os.clock()local finished=false
local function finish(err)if finished then return end finished=true result.passed=err==nil result.error=err result.elapsed=os.clock()-started T:EndTest(result)end
task.delay(100,function()finish('deadline')end)
local function await(label,fn,seconds)
    local deadline=os.clock()+(seconds or 15)
    repeat if fn()then table.insert(result.assertions,label)return end task.wait(.1)until os.clock()>deadline
    error(label..' timed out')
end
local worked,err=xpcall(function()
    await('two initialized hub clients',function()
        local ps=game.Players:GetPlayers()if #ps~=2 then return false end
        for _,p in ipairs(ps)do if not states[p]or not states[p].party then return false end end return true
    end,50)
    local ps=game.Players:GetPlayers()table.sort(ps,function(a,b)return a.UserId<b.UserId end)local a,b=ps[1],ps[2]
    qa:FireClient(a,'Invite',{userId=b.UserId})
    await('invite appears to recipient',function()return #states[b].invites==1 end)
    qa:FireClient(b,'Accept',{partyId=states[a].party.id})
    await('both clients share two-member party',function()return states[a].party.id==states[b].party.id and #states[a].party.members==2 and #states[b].party.members==2 end)
    qa:FireClient(b,'Queue',{mode='QuickMatch',difficulty='Normal',heat={}})
    await('nonleader deployment rejected',function()return states[b].message and string.find(states[b].message,'Only the party leader',1,true)and states[a].party.status=='Idle'end)
    qa:FireClient(a,'Queue',{mode='QuickMatch',difficulty='Normal',heat={}})
    await('both clients observe queued party',function()return states[a].party.status=='Queued'and states[b].party.status=='Queued'end)
    qa:FireClient(a,'Cancel',{})
    await('leader cancels queue for whole party',function()return states[a].party.status=='Idle'and states[b].party.status=='Idle'end)
    qa:FireClient(b,'SelectHero',{hero='Tide'})
    await('member hero selection accepted',function()return states[b].selectedHero=='Tide'end)
    local partyId=states[a].party.id
    qa:FireClient(a,'Queue',{mode='Solo',difficulty='Normal',heat={}})
    await('private party simulation finishes together',function()
        return states[a].message and string.find(states[a].message,'simulation passed',1,true)and states[b].message and string.find(states[b].message,'simulation passed',1,true)
            and states[a].party.status=='Idle'and states[b].party.status=='Idle'and states[a].party.id==partyId and states[b].party.id==partyId
            and #states[a].party.members==2 and #states[b].party.members==2
    end,20)
end,debug.traceback)
if worked then finish()else finish(tostring(err))end
