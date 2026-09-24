-- Server-only observational counters. Disabled outside Studio; never changes combat decisions.
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local Telemetry = {}
local Diversity=require(script.Parent.ActionDiversity)
local Opportunity=require(script.Parent.EnemyOpportunityDiagnostics)
local enabled = RunService:IsStudio()
Telemetry.Enabled=enabled
local state, windows, diversity, opportunity
local function time() return workspace:GetServerTimeNow() end
function Telemetry.Reset()
    state = {schema=1, started=time(), eligibleGruntTicks=0, idleGruntTicks=0,
        serverBoundsRejected=0, windupPeak=0, capViolations=0, minWindup=false, windups=0, actions={},
        flankWindows=0, flankedWindows=0, hits={}, stocks={}, damage={}, encounters={},
        aiSeconds=0, aiSamples=0, aiPeakSeconds=0, cameraFrustum="not measured", rank="not implemented"}
    windows = {}
    opportunity=Opportunity.New()
    diversity=Diversity.New({
        Begin=function(actor,t)Opportunity.Begin(opportunity,actor,t)end,
        Finish=function(actor,complete)return Opportunity.Finish(opportunity,actor,complete)end,
        Depart=function(actor)Opportunity.Depart(opportunity,actor)end,
    })
end
Telemetry.Reset()
function Telemetry.BeginEncounter(stage, wave)
    if not enabled then return end
    Diversity.Flush(diversity,time())
    state.stage, state.wave = stage, wave
    local key = tostring(stage)..":"..tostring(wave)
    state.encounters[key] = state.encounters[key] or {hits=0, stocks=0, damage=0}
    table.clear(windows)
end
function Telemetry.Hit(player, damage)
    if not enabled or not player then return end
    local id=tostring(player.UserId)
    state.hits[id]=(state.hits[id] or 0)+1
    state.damage[id]=(state.damage[id] or 0)+damage
    local entry=state.encounters[tostring(state.stage)..":"..tostring(state.wave)]
    if entry then entry.hits+=1;entry.damage+=damage end
end
function Telemetry.StockLoss(player)
    if not enabled then return end
    local id=tostring(player.UserId)
    state.stocks[id]=state.stocks[id] or {}
    local stage=tostring(state.stage or 1)
    state.stocks[id][stage]=(state.stocks[id][stage] or 0)+1
    local entry=state.encounters[stage..":"..tostring(state.wave)]
    if entry then entry.stocks+=1 end
end
function Telemetry.BoundsRejected()
    if enabled then state.serverBoundsRejected+=1 end
end
function Telemetry.Windup(kind, move, duration, simultaneous, cap)
    if not enabled then return end
    state.windups+=1
    state.windupPeak=math.max(state.windupPeak,simultaneous)
    if simultaneous>cap then state.capViolations+=1 end
    state.minWindup=state.minWindup and math.min(state.minWindup,duration) or duration
    state.actions[kind]=state.actions[kind] or {}
    state.actions[kind][move]=(state.actions[kind][move] or 0)+1
end
function Telemetry.Action(model,kind,action,t)
    if enabled then Diversity.Action(diversity,model,kind or "Unknown",action,t)end
end
function Telemetry.ActorAlias(model)
    return enabled and Opportunity.Alias(opportunity,model)or false
end
function Telemetry.AIContext(model,t,fields)
    if enabled then Opportunity.Context(opportunity,model,t,fields)end
end
function Telemetry.OpportunityEvent(model,name,t)
    if enabled then Opportunity.Event(opportunity,model,name,t)end
end
function Telemetry.Sample(enemies, alive, now, combatActive)
    if not enabled then return end
    if not combatActive then Diversity.Flush(diversity,now);return end
    local engaged={}
    for model,data in pairs(enemies) do
        local r=model:FindFirstChild("HumanoidRootPart")
        local h=model:FindFirstChildOfClass("Humanoid")
        if r and h and h.Health>0 and data.aiState~="Enter" then
            for _,player in ipairs(alive)do
                local pr=player.Character and player.Character:FindFirstChild("HumanoidRootPart")
                if pr and (Vector2.new(pr.Position.X-r.Position.X,pr.Position.Z-r.Position.Z)).Magnitude<=28 then
                    engaged[model]=true;Diversity.Engage(diversity,model,data.kind or "Unknown",now)
                    Opportunity.Sample(opportunity,model,now);break
                end
            end
        end
        if r and h and h.Health>0 and data.spec.Role=="Grunt" and not data.attacking
            and now>=data.stunnedUntil and now>=data.launchedUntil and now>=data.recoveryUntil then
            state.eligibleGruntTicks+=1
            local v=r.AssemblyLinearVelocity
            if Vector2.new(v.X,v.Z).Magnitude<.5 and h.MoveDirection.Magnitude<.05 then state.idleGruntTicks+=1 end
        end
    end
    local departed={};for actor in pairs(diversity.actors)do if not engaged[actor]then table.insert(departed,actor)end end
    for _,actor in ipairs(departed)do Diversity.Leave(diversity,actor,now)end
    -- A qualified engagement is a continuous five-second window with >=2 nearby grunts.
    for _,player in ipairs(alive) do
        local r=player.Character and player.Character:FindFirstChild("HumanoidRootPart")
        if not r then continue end
        local count,left,right=0,false,false
        for model,data in pairs(enemies) do
            local er=model:FindFirstChild("HumanoidRootPart")
            if er and data.spec.Role=="Grunt" and (er.Position-r.Position).Magnitude<=28 then
                count+=1
                if er.Position.X<r.Position.X-1 then left=true elseif er.Position.X>r.Position.X+1 then right=true end
            end
        end
        if count>=2 then
            local w=windows[player] or {start=now,flanked=false};windows[player]=w
            w.flanked=w.flanked or (left and right)
            if now-w.start>=5 then
                state.flankWindows+=1
                if w.flanked then state.flankedWindows+=1 end
                windows[player]={start=now,flanked=false}
            end
        else windows[player]=nil end
    end
end
function Telemetry.AICost(seconds)
    if not enabled then return end
    state.aiSamples+=1;state.aiSeconds+=seconds;state.aiPeakSeconds=math.max(state.aiPeakSeconds,seconds)
end
function Telemetry.Summary()
    local result=table.clone(state)
    result.elapsed=time()-state.started
    result.actionDiversity=Diversity.Summary(diversity)
    result.opportunityDiagnostics=Opportunity.Summary(opportunity)
    result.idleRatio=state.eligibleGruntTicks>0 and state.idleGruntTicks/state.eligibleGruntTicks or false
    result.flankRatio=state.flankWindows>0 and state.flankedWindows/state.flankWindows or false
    result.aiMeanMs=state.aiSamples>0 and 1000*state.aiSeconds/state.aiSamples or false
    result.aiPeakMs=1000*state.aiPeakSeconds
    return result
end
function Telemetry.Finish(outcome)
    if not enabled then return end
    Diversity.Flush(diversity,time())
    local result=Telemetry.Summary();result.outcome=outcome
    local encoded=HttpService:JSONEncode(result)
    workspace:SetAttribute("CombatTelemetry",encoded)
    print("COMBAT_TELEMETRY "..encoded)
end
return Telemetry
