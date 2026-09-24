-- Authored cosmetic geometry only. Server pickup services own sensors, claims and lifetime.
local Visuals={}
function Visuals.ScoreOrb(parent,position,id,expiresAt)
    local model=Instance.new("Model")
    model.Name="ScoreOrb"
    model:SetAttribute("PickupId",id)
    model:SetAttribute("PickupKind","ScoreOrb")
    model:SetAttribute("ExpiresAt",expiresAt)
    model:SetAttribute("VisualRevision","RiskLoot-1")
    local function part(name,size,cf,color)
        local p=Instance.new("Part")
        p.Name,p.Size,p.CFrame=name,size,cf
        p.Anchored=true;p.CanCollide=false;p.CanTouch=false;p.CanQuery=false
        p.CastShadow=false;p.Material=Enum.Material.Neon;p.Color=color
        p.TopSurface=Enum.SurfaceType.Smooth;p.BottomSurface=Enum.SurfaceType.Smooth
        p.Parent=model
        return p
    end
    local bead=part("StyleBead",Vector3.new(.72,.72,.72),CFrame.new(position),Color3.fromRGB(255,194,85))
    bead.Shape=Enum.PartType.Ball
    model.PrimaryPart=bead
    for i=0,7 do
        local angle=i*math.pi/4
        part("OrbitSegment",Vector3.new(.08,.065,.50),
            CFrame.new(position+Vector3.new(math.cos(angle)*.68,-.30,math.sin(angle)*.68))*CFrame.Angles(0,-angle,0),
            Color3.fromRGB(219,250,241))
    end
    local badge=Instance.new("BillboardGui")
    badge.Name="StyleLabel";badge.Size=UDim2.fromOffset(52,16);badge.StudsOffset=Vector3.new(0,.8,0)
    badge.AlwaysOnTop=false;badge.MaxDistance=200;badge.Adornee=bead;badge.Parent=bead
    local label=Instance.new("TextLabel")
    label.BackgroundTransparency=1;label.Size=UDim2.fromScale(1,1);label.Text="STYLE"
    label.Font=Enum.Font.GothamBold;label.TextSize=10;label.TextColor3=Color3.fromRGB(255,230,172)
    label.TextStrokeTransparency=.35;label.Parent=badge
    model.Parent=parent
    return model
end
return Visuals
