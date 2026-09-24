-- Original Roblox-generated scenic mesh and material. Static visual data only.
local Installer={}
local pump={
 {Name="Base",Mesh="86636771757111",Texture="109121361954379",Size=Vector3.new(2.85394,1.13964,4.07204),Position=Vector3.new(0,.569767,-.030049)},
 {Name="Gauge",Mesh="76795478278087",Texture="107421068394595",Size=Vector3.new(2.11153,3.22431,1.00690),Position=Vector3.new(-.002747,4.82449,2.03471)},
 {Name="Pipes",Mesh="140159118360520",Texture="101025669073439",Size=Vector3.new(2.69265,.811049,5.84512),Position=Vector3.new(-.003487,.490256,-.077439)},
 {Name="Motor",Mesh="115650030808677",Texture="139561435818528",Size=Vector3.new(2.27728,3.29184,5.91289),Position=Vector3.new(-.001724,1.91890,.043556)}
}
function Installer.InstallMaterials()
 local service=game:GetService("MaterialService")
 local material=service:FindFirstChild("NightfallStationTile")
 if material then return end
 if game:GetService("RunService"):IsRunning() then return end -- BaseMaterial is edit-time only.
 material=Instance.new("MaterialVariant")
 material.Name="NightfallStationTile";material.BaseMaterial=Enum.Material.Concrete;material.StudsPerTile=8
 material.ColorMap="rbxassetid://114981869241823";material.NormalMap="rbxassetid://133333203349103"
 material.RoughnessMap="rbxassetid://118428319587116";material.MetalnessMap="rbxassetid://86148575515928"
 material.Parent=service
end
function Installer.DressWorld()
 local city=workspace:FindFirstChild("NightfallCity");if not city then return end
 local old=city:FindFirstChild("AuthoredMeshDetails");if old then old:Destroy() end
 local folder=Instance.new("Folder");folder.Name="AuthoredMeshDetails";folder.Parent=city
 local floor=city.Streets:FindFirstChild("StationLaneSurface")
 if floor then floor.Material=Enum.Material.Concrete;floor.MaterialVariant="" end -- Keep combat telegraphs on a quiet surface.
 for _,part in ipairs(city.Architecture:GetChildren()) do
  if part:IsA("BasePart") and (part.Name=="StationDado" or part.Name=="StationBackPlatform") then part.Material=Enum.Material.Concrete;part.MaterialVariant="NightfallStationTile" end
 end
 for index,placement in ipairs({{393,0,-23,1.05,math.rad(25)},{468,0,-22,1.15,math.rad(-20)},{523,0,-26,.9,math.rad(15)}}) do
  local model=Instance.new("Model");model.Name="FoundryPump"..index;model:SetAttribute("OriginalAssetId","130740920499312");model.Parent=folder
  local scale=placement[4];local origin=CFrame.new(placement[1],placement[2],placement[3])*CFrame.Angles(0,placement[5],0)
  for _,spec in ipairs(pump) do
   local p=Instance.new("Part");p.Name=spec.Name;p.Size=spec.Size*scale;p.CFrame=origin*CFrame.new(spec.Position*scale)
   p.Anchored=true;p.CanCollide=false;p.CanTouch=false;p.CanQuery=false;p.CastShadow=true;p.Color=Color3.new(1,1,1)
   local mesh=Instance.new("SpecialMesh");mesh.MeshType=Enum.MeshType.FileMesh;mesh.MeshId="rbxassetid://"..spec.Mesh;mesh.TextureId="rbxassetid://"..spec.Texture;mesh.Scale=Vector3.one*scale;mesh.Parent=p;p.Parent=model
  end
 end
end
return Installer
