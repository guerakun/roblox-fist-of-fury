-- Root-only: install with the client companion, ExecuteMultiplayerTestAsync(1,{test="CombatAdmissionQA"}).
-- Adds and denies two disposable Studio clients. No published server or owner account is kicked.
local RunService=game:GetService("RunService")
if not RunService:IsStudio() or not RunService:IsServer() then return end
local Test=game:GetService("StudioTestService")
local okArgs,args=pcall(function()return Test:GetTestArgs()end)
if not okArgs or type(args)~="table" or args.test~="CombatAdmissionQA" then return end
local Players=game:GetService("Players")
local qa=Instance.new("RemoteEvent");qa.Name="CombatAdmissionQA";qa.Parent=game.ReplicatedStorage
local hellos,acks={},{}
qa.OnServerEvent:Connect(function(player,kind,serial)
    if kind=="Hello" then hellos[player]=true elseif kind=="Ack" then acks[serial]=player end
end)
local C,result
local function await(label,predicate,seconds)
    local deadline=os.clock()+seconds
    repeat if predicate()then return end;task.wait(.03)until os.clock()>deadline
    error("Timed out: "..label)
end
local ok,err=xpcall(function()
    local server=game.ServerScriptService:WaitForChild("NightfallServer",30)
    C=require(server:WaitForChild("CombatService"))
    await("one initialized client",function()
        local ps=Players:GetPlayers();return #ps==1 and hellos[ps[1]] and C.GetSnapshot(ps[1])~=nil
    end,40)
    local owner=Players:GetPlayers()[1]
    assert(C.GetRunStatus()=="Waiting","fresh waiting session required")
    local function probe(serial)
        qa:FireClient(owner,{kind="ReadyProbe",serial=serial})
        await("client probe acknowledged",function()return acks[serial]==owner end,5)
        task.wait(.35)
        assert(not C.GetSnapshot(owner).ready and C.GetRunStatus()=="Waiting","client bypassed arrival/travel gate")
    end
    C.SetAdmissionValidator(function()return true end)
    probe(1)
    result={managedClientReadyRejected=true}
    for _,mode in ipairs({"false","error"})do
        local rejected
        C.SetAdmissionValidator(function(player)
            rejected=player
            if mode=="error" then error("intentional admission fixture failure")end
            return false
        end)
        Test:AddPlayers(1)
        await("denial evaluated",function()return rejected~=nil end,25)
        await("denied client removed",function()return rejected.Parent~=Players end,15)
        assert(C.GetSnapshot(rejected)==nil and C.GetPlayerCount()==1,"denied player acquired a combat record")
        result[mode=="false" and "falseDenied" or "errorDenied"]=true
    end
    C.SetAdmissionValidator(nil);C.SetTravelLocked(true)
    probe(2)
    assert(C.GetSnapshot(owner).travelLocked,"travel lock replicated")
    result.travelReadyRejected=true
    C.SetAdmissionValidator(function()return true end);C.SetTravelLocked(false)
    assert(C.ReadyForMatch({owner}),"server arrival completion accepted")
    await("server readiness starts campaign",function()return C.GetRunStatus()~="Waiting" end,5)
    result.serverReadyAccepted=true;result.passed=true
end,debug.traceback)
if C then C.SetAdmissionValidator(nil);C.SetTravelLocked(false)end
if not ok then result={passed=false,error=tostring(err)}end
print("COMBAT_ADMISSION_QA "..game:GetService("HttpService"):JSONEncode(result))
Test:EndTest(result)
