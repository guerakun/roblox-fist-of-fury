local World={}
function World.Build()
    local old=workspace:FindFirstChild('CurtainBreakHub') if old then old:Destroy() end
    local folder=Instance.new('Folder',workspace) folder.Name='CurtainBreakHub'
    local function part(name,size,position,color,material)
        local p=Instance.new('Part') p.Name=name p.Size=size p.Position=position p.Color=color
        p.Anchored=true p.Material=material or Enum.Material.Concrete p.TopSurface=Enum.SurfaceType.Smooth p.Parent=folder
        return p
    end
    local function sign(name,text,position,width,color)
        local p=part(name,Vector3.new(width,7,.5),position,Color3.fromRGB(19,28,39))
        local gui=Instance.new('SurfaceGui',p) gui.Face=Enum.NormalId.Front gui.CanvasSize=Vector2.new(width*45,300)
        local label=Instance.new('TextLabel',gui) label.Size=UDim2.fromScale(1,1) label.BackgroundTransparency=1
        label.Text=text label.Font=Enum.Font.GothamBold label.TextScaled=true label.TextColor3=color or Color3.fromRGB(114,227,218)
        local pad=Instance.new('UIPadding',label) pad.PaddingLeft=UDim.new(0,18) pad.PaddingRight=UDim.new(0,18)
        return p
    end
    part('Plaza',Vector3.new(140,2,120),Vector3.new(0,-1,0),Color3.fromRGB(50,59,68))
    part('BackWall',Vector3.new(140,28,3),Vector3.new(0,13,59),Color3.fromRGB(29,38,51))
    part('LeftWall',Vector3.new(3,18,120),Vector3.new(-69,8,0),Color3.fromRGB(34,45,58))
    part('RightWall',Vector3.new(3,18,120),Vector3.new(69,8,0),Color3.fromRGB(34,45,58))
    sign('Title','CURTAIN BREAK\nASHGATE REFUGE',Vector3.new(0,17,56),52)
    local spawn=Instance.new('SpawnLocation') spawn.Name='RefugeArrival' spawn.Size=Vector3.new(14,1,12)
    spawn.Position=Vector3.new(0,.5,-35) spawn.Anchored=true spawn.Neutral=true spawn.Duration=0 spawn.Color=Color3.fromRGB(77,149,151) spawn.Parent=folder
    local deploy=part('DeployTerminal',Vector3.new(12,7,5),Vector3.new(0,3.5,25),Color3.fromRGB(32,64,69),Enum.Material.Metal)
    sign('DeploySign','DEPLOY\nSOLO / PARTY / QUICK MATCH',Vector3.new(0,10,22),30)
    local prompt=Instance.new('ProximityPrompt',deploy) prompt.ActionText='Plan deployment' prompt.ObjectText='Campaign terminal' prompt.HoldDuration=0 prompt.MaxActivationDistance=16
    prompt:SetAttribute('HubAction','Deploy')
    part('DojoMat',Vector3.new(36,.25,34),Vector3.new(-42,.2,14),Color3.fromRGB(61,98,103))
    sign('DojoSign','TRAINING DOJO',Vector3.new(-42,8,32),25)
    part('LeaderboardBoard',Vector3.new(28,15,1),Vector3.new(43,8,31),Color3.fromRGB(25,36,49))
    sign('LeaderboardSign','DISTRICT RECORDS',Vector3.new(43,18,30),27)
    sign('CosmeticsSign','WARDROBE\nEARNED STYLE',Vector3.new(-43,9,-33),25,Color3.fromRGB(235,185,101))
    for x=-50,50,25 do
        part('LightMast',Vector3.new(.7,15,.7),Vector3.new(x,7.5,-13),Color3.fromRGB(51,68,78),Enum.Material.Metal)
        local lamp=part('Light',Vector3.new(4,.3,2),Vector3.new(x,15,-13),Color3.fromRGB(177,232,223),Enum.Material.Neon)
        local light=Instance.new('PointLight',lamp) light.Range=28 light.Brightness=1.2 light.Color=lamp.Color
    end
    return folder
end
return World
