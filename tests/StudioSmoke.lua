-- Execute as a ModuleScript in a Studio SERVER session; does not alter encounter state.
return function()
 local shared=game.ReplicatedStorage.Nightfall.Shared
 local config=require(shared.Config)
 local mathModule=require(shared.CombatMath)
 local samples=require(shared.ToolboxAnimations)
 assert(#config.Stages==3,'three districts')
 assert(mathModule.Knockback(100,config.Attacks.Heavy,1)>mathModule.Knockback(0,config.Attacks.Heavy,1),'percent scales launch')
 assert(mathModule.Knockback(100,config.Attacks.Heavy,2)<mathModule.Knockback(100,config.Attacks.Heavy,1),'weight resists launch')
 assert(mathModule.Direction(0/0,-1)==-1,'NaN direction fallback')
 assert(mathModule.InBlastZone(Vector3.new(-25,3,0),config.Stages[1],24),'left blast boundary')
 assert(not mathModule.InBlastZone(Vector3.new(90,3,0),config.Stages[1],24),'arena center safe')
 for _,name in {'Light','Heavy','Walk','Idle','Block','Dash'} do assert(samples[name] and #samples[name].frames>1,'missing Toolbox '..name) end
 local city=workspace:FindFirstChild('NightfallCity'); assert(city and city:FindFirstChild('Gates'),'world built')
 assert(workspace:FindFirstChild('Enemies'),'enemy container initialized')
 local hit=game.ReplicatedStorage.Nightfall.Assets.VFX.Hit
 for _,v in hit:GetDescendants() do assert(not v:IsA('LuaSourceContainer'),'VFX contains executable source') end
 local factory=require(game.ServerScriptService.NightfallServer.CharacterFactory)
 for _,hero in {'Naruto','Luffy','Tanjiro'} do
  local rig=factory.Create(hero)
  assert(rig:FindFirstChild('Torso') and rig:FindFirstChild('Right Arm'),'R6 rig')
  assert(rig:FindFirstChildOfClass('Humanoid') and rig.PrimaryPart,'valid character')
  rig:Destroy()
 end
 return 'PASS: world, launch math, direction validation, Toolbox data, sanitized VFX, all three R6 rigs'
end
