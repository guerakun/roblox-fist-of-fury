-- Root-only Studio workflow fixture; clears enemies and positions the party deliberately.
-- This tests12area state/gates, NOT combat skill, difficulty, normal player travel or rewards.
local Run=game:GetService("RunService")
if not Run:IsStudio()then return end
local Server=game.ServerScriptService:WaitForChild("NightfallServer")
local Combat=require(Server.CombatService)
local Config=require(game.ReplicatedStorage.Nightfall.Shared.Config)
local Http=game:GetService("HttpService")
local result={passed=false,areas={},traversals=0,stageTransfers=0,scriptedEnemyClear=true}
local output=Instance.new("StringValue");output.Name="ArenaProgressionResult";output.Parent=game.ServerStorage
local function save()output.Value=Http:JSONEncode(result)end
save()
while not workspace:GetAttribute("RunArenaProgressionFixture")do task.wait(.1)end
local ok,problem=xpcall(function()
 local start=os.clock();local seen={};local transitionSeen={}
 while os.clock()-start<150 do
  local p=game.Players:GetPlayers()[1]
  local state=p and Combat.GetSnapshot(p)
  if state then
   if state.status=="Combat"then
    local key=state.stage..":"..state.wave
    local wave=Config.Stages[state.stage].Waves[state.wave]
    local gate=workspace.NightfallCity.Gates["Stage"..state.stage.."_Area"..state.wave]
    assert(gate.CanCollide and not gate:GetAttribute("Opened"),"active exit must be closed")
    if state.wave>1 then assert(workspace.NightfallCity.Gates["Stage"..state.stage.."_Area"..(state.wave-1)].CanCollide,"rear gate relocks")end
    assert(state.arena.MinX==wave.Bounds.MinX and state.arena.MaxX==wave.Bounds.MaxX,"active area bounds")
    assert(state.walkingMinX==wave.Bounds.MinX+2 and state.walkingMaxX==wave.Bounds.MaxX-2,"legal body inset")
    if not seen[key]then seen[key]=true;table.insert(result.areas,{stage=state.stage,area=state.wave,role=state.encounterKind});save()end
    Combat.ClearEnemies() -- every reserved pulse must still spawn and clear before advance
   elseif state.status=="Traverse"then
    local gate=workspace.NightfallCity.Gates["Stage"..state.stage.."_Area"..state.wave]
    assert(not gate.CanCollide and gate:GetAttribute("Opened"),"cleared exit opens")
    local key=state.stage..":"..state.wave
    if not transitionSeen[key]then transitionSeen[key]=true;result.traversals+=1 end
    for _,player in ipairs(Combat.GetAlivePlayers())do
     player.Character:PivotTo(CFrame.new(state.targetX+1,4,0));player.Character.HumanoidRootPart.AssemblyLinearVelocity=Vector3.zero
    end
   elseif state.status=="Advance"then
    local key="stage"..state.stage
    if not transitionSeen[key]then transitionSeen[key]=true;result.stageTransfers+=1 end
    for _,player in ipairs(Combat.GetAlivePlayers())do player.Character:PivotTo(CFrame.new(state.targetX+1,4,0))end
   elseif state.status=="Victory"then
    assert(#result.areas==12 and result.traversals==9 and result.stageTransfers==2,"complete progression")
    for _,row in ipairs(result.areas)do assert(row.role==({"Wave","Wave","Miniboss","Boss"})[row.area],"role order")end
    result.passed=true;result.seconds=os.clock()-start;return
   elseif state.status=="Defeat"then error("fixture unexpectedly defeated")end
  end
  task.wait(.1)
 end
 error("progression timeout")
end,debug.traceback)
if not ok then result.error=problem end
save()
