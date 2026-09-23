-- Build deterministically before accepting gameplay requests.
local WorldBuilder = require(script.Parent.WorldBuilder)
local AssetInstaller = require(script.Parent.AssetInstaller)
if not workspace:FindFirstChild('Enemies') then
 local enemies=Instance.new('Folder'); enemies.Name='Enemies'; enemies.Parent=workspace
end
AssetInstaller.Install()
WorldBuilder.Build()
local Combat = require(script.Parent.CombatService)
local Encounters = require(script.Parent.EncounterService)
Combat.Init()
Encounters.Init(Combat)
print('[Curtain Break] City, Toolbox assets and co-op encounter server ready.')
