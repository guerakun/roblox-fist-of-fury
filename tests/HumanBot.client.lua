-- Studio-only, imperfect action driver; NOT included in either production project.
-- Same seeds and policy must be used before/after tuning. No damage, CFrame, or reward writes.
local Players=game:GetService("Players")
local RunService=game:GetService("RunService")
if not RunService:IsStudio() then return end
local Http=game:GetService("HttpService")
local player=Players.LocalPlayer
local R=game.ReplicatedStorage:WaitForChild("Nightfall"):WaitForChild("Remotes")
local Config=require(game.ReplicatedStorage.Nightfall.Shared.Config)
local seed=script:GetAttribute("Seed") or 1101
local rng=Random.new(seed)
local state={status="Waiting",stage=1,wave=0,cooldowns={}}
local began,combatBegan=os.clock(),nil
local pending,decisions,transitions={},{},{}
local seenTells={}
local districtResults,districtById={},{} -- Observation only; does not enter action policy.
local responseMovement,responseUntil=Vector3.zero,0
local scheduledTotal=0
local movement=Vector3.zero
local nextThink,nextAction,nextReady,nextReport=0,0,0,0
local nextMistake,mistakeUntil,blockUntil=os.clock()+6,0,0
local lastState,done="",false
local choices={Light=0,Heavy=0,Special=0,Block=0,Dash=0,Jump=0,Mistake=0,recognized=0,telegraphs=0}
local delayTotal,delayCount=0,0
local previousStocks,stocksLost=3,{["1"]=0,["2"]=0,["3"]=0}
local function send(action,packet)
    R.Action:FireServer(action,packet or {})
    if choices[action] and (action~="Block" or (packet and packet.held==true)) then choices[action]+=1 end
end
R.State.OnClientEvent:Connect(function(packet)
    if packet.kind~="Snapshot" then return end
    if packet.stocks and previousStocks and packet.stocks<previousStocks then
        local key=tostring(packet.stage or 1);stocksLost[key]=(stocksLost[key] or 0)+previousStocks-packet.stocks
    end
    previousStocks=packet.stocks or previousStocks
    state=packet
    local district=packet.districtResult
    if type(district)=="table"and type(district.id)=="string"then
        local observed=districtById[district.id]
        if not observed then
            observed=table.clone(district);districtById[district.id]=observed;table.insert(districtResults,observed)
        end
        if type(packet.districtReceipt)=="table"then observed.receipt=table.clone(packet.districtReceipt)end
    end
    if packet.status=="Combat" and not combatBegan then combatBegan=os.clock() end
end)
R.FX.OnClientEvent:Connect(function(packet)
    if packet.kind~="Telegraph" or typeof(packet.position)~="Vector3" then return end
    local now=os.clock()
    local owner=packet.targetModel or packet.enemy or "unknown"
    local previous=seenTells[owner]
    if previous and now-previous.received<.05 then table.insert(previous.packets,packet);return end
    choices.telegraphs+=1
    local tell={received=now,packets={packet},finish=now+(packet.duration or .6)}
    seenTells[owner]=tell
    -- Deduplicate multi-volume attacks, then perceive one tell with 75% probability.
    if rng:NextNumber()>.75 then return end
    choices.recognized+=1
    local delay=rng:NextNumber(.17,.33)
    scheduledTotal+=delay
    tell.at=now+delay
    table.insert(pending,tell)
end)
local function threatened(packet,pos)
    local delta=pos-packet.position
    local size=packet.size or Vector3.new(9,6,6)
    if packet.shape=="Circle" then return Vector2.new(delta.X,delta.Z).Magnitude<(packet.radius or size.X/2)+.5 end
    return math.abs(delta.X)<size.X/2+.5 and math.abs(delta.Z)<size.Z/2+.5
end
local function report(finished)
    local telemetry=workspace:GetAttribute("CombatTelemetry")
    local parsed=false
    if telemetry then local ok,value=pcall(Http.JSONDecode,Http,telemetry);if ok then parsed=value end end
    local result={schema=1,seed=seed,done=finished,clear=state.status=="Victory",outcome=state.status,
        seconds=os.clock()-(combatBegan or began),wallSeconds=os.clock()-began,stage=state.stage,wave=state.wave,
        stocksLostByDistrict=stocksLost,damageTaken=state.runStats and state.runStats.damageTaken or 0,
        rank=type(state.districtResult)=="table"and state.districtResult.rank or "no current district result",
        districtResults=districtResults,reportRevision="M3 rank observer",runStats=state.runStats,choices=choices,
        reactionMean=delayCount>0 and delayTotal/delayCount or false,scheduledReactionMean=choices.recognized>0 and scheduledTotal/choices.recognized or false,transitions=transitions,telemetry=parsed}
    player:SetAttribute("HumanBotReport",Http:JSONEncode(result))
    if finished then print("HUMANBOT_RESULT "..Http:JSONEncode(result)) end
end
RunService:BindToRenderStep("HumanBotQA",Enum.RenderPriority.Last.Value+50,function()
    if done then return end
    local now=os.clock()
    local key=tostring(state.stage)..":"..tostring(state.wave)..":"..state.status
    if key~=lastState then table.insert(transitions,{seconds=now-began,state=key});lastState=key end
    if state.status=="Victory" or state.status=="Defeat" or now-began>1200 then
        done=true
        if state.status~="Victory" and state.status~="Defeat" then state.status="Timeout" end
        send("Block",{held=false})
        local h=player.Character and player.Character:FindFirstChildOfClass("Humanoid");if h then h:Move(Vector3.zero,false) end
        task.delay(.3,function()report(true)end)
        RunService:UnbindFromRenderStep("HumanBotQA")
        return
    end
    if now>=nextReport then nextReport=now+2;report(false)end
    local model=player.Character
    local root=model and model:FindFirstChild("HumanoidRootPart")
    local h=model and model:FindFirstChildOfClass("Humanoid")
    if not root or not h then return end
    if state.status=="Waiting" and now>=nextReady then nextReady=now+2;send("Ready",{ready=true}) end
    if now>=nextThink then
        nextThink=now+rng:NextNumber(.17,.33)
        movement=Vector3.zero
        if blockUntil>0 and now>=blockUntil then send("Block",{held=false});blockUntil=0 end
        if state.status=="Traverse" or state.status=="Advance" then
            movement=Vector3.new((state.targetX or state.stage*180-8)-root.Position.X+1,0,-root.Position.Z*.3)
        elseif state.status=="Combat" and not state.downed then
            local target,distance
            local folder=workspace:FindFirstChild("Enemies")
            for _,enemy in ipairs(folder and folder:GetChildren() or {}) do
                local er=enemy:FindFirstChild("HumanoidRootPart")
                if er then local d=(er.Position-root.Position).Magnitude;if not distance or d<distance then target=er;distance=d end end
            end
            if target then
                local delta=target.Position-root.Position
                local direction=delta.X>=0 and 1 or -1
                movement=Vector3.new(math.abs(delta.X)>4 and delta.X-direction*3.5 or 0,0,delta.Z)
                if now>=nextMistake then
                    nextMistake=now+rng:NextNumber(5,7);mistakeUntil=now+.6;choices.Mistake+=1
                    decisions.mistake=Vector3.new(rng:NextNumber(-1,1),0,rng:NextNumber(-1,1))
                end
                if now<mistakeUntil then movement=decisions.mistake
                elseif now>=nextAction and blockUntil==0 then
                    nextAction=now+rng:NextNumber(.28,.44)
                    local roll=rng:NextNumber()
                    local action=roll<.6 and "Light" or roll<.85 and "Heavy" or "Special"
                    local hero=Config.Characters[state.hero] or Config.Characters[(Config.CharacterOrder or {})[1]]
                    local attack=action=="Special" and hero and hero.Special or Config.Attacks[action]
                    if attack and math.abs(delta.X)<attack.Range and math.abs(delta.Z)<attack.Width/2
                        and workspace:GetServerTimeNow()>=(state.cooldowns[action] or 0) then send(action,{direction=direction}) end
                end
            end
        end
        if movement.Magnitude>1 then movement=movement.Unit end
    end
    -- Execute perceived tells on the first frame after their reaction deadline, not the think timer.
    for i=#pending,1,-1 do
        local tell=pending[i]
        if now>=tell.at then
            table.remove(pending,i)
            delayTotal+=now-tell.received;delayCount+=1
            if now<=tell.finish and state.status=="Combat" and now>=mistakeUntil then
                local packet
                for _,volume in ipairs(tell.packets) do if threatened(volume,root.Position) then packet=volume;break end end
                if packet then
                    local direction=-(packet.direction or 1)
                    local aoe=#tell.packets>1 or packet.shape=="Circle" or (packet.size and packet.size.X>18)
                    if not aoe and rng:NextNumber()<.4 then
                        send("Block",{held=true,direction=direction});blockUntil=tell.finish+.1
                    elseif aoe and rng:NextNumber()<.3 then send("Dash",{direction=-direction})
                    elseif packet.jumpable and rng:NextNumber()<.65 then send("Jump",{direction=direction})
                    else responseMovement=Vector3.new(0,0,root.Position.Z>=0 and -1 or 1);responseUntil=now+.35 end
                end
            end
        end
    end
    h:Move(now<responseUntil and responseMovement or movement,false)
end)
