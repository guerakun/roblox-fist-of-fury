-- Build deterministically before accepting gameplay requests.
local WorldBuilder = require(script.Parent.WorldBuilder)
local AssetInstaller = require(script.Parent.AssetInstaller)
if not workspace:FindFirstChild('Enemies') then
 local enemies=Instance.new('Folder'); enemies.Name='Enemies'; enemies.Parent=workspace
end
AssetInstaller.Install()
local Art = require(script.Parent.ArtAssetsInstaller)
Art.InstallMaterials()
WorldBuilder.Build()
Art.DressWorld()
local Progression = require(script.Parent.ProgressionService)
local Combat = require(script.Parent.CombatService)
local Encounters = require(script.Parent.EncounterService)
Progression.Init()
require(script.Parent.CampaignSession).Init(Combat, Progression)
Combat.Init()
Encounters.Init(Combat)
print('[Curtain Break] City, Toolbox assets and co-op encounter server ready.')
