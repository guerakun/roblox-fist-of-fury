-- Safe particle-only reconstruction of Creator Store asset 92765511929343.
-- All scripts, GUI and unrelated objects in the source pack were rejected.
local Installer = {}
function Installer.Install()
	local assets = game.ReplicatedStorage.Nightfall.Assets
	local vfx = assets.VFX
	if vfx:FindFirstChild('Hit') then return end
	local host = Instance.new('Part')
	host.Name = 'Hit'
	host.Size = Vector3.one
	host.Transparency = 1
	host.Anchored = true
	host.CanCollide = false
	host.CanTouch = false
	host.CanQuery = false
	host:SetAttribute('SourceAssetId', '92765511929343')
	local attachment = Instance.new('Attachment', host)
	local cross = Instance.new('ParticleEmitter', attachment)
	cross.Name = 'ImpactCross'
	cross.Texture = 'rbxassetid://16004095914'
	cross.Lifetime = NumberRange.new(0.1,0.3)
	cross.Speed = NumberRange.new(0)
	cross.Size = NumberSequence.new(3)
	cross.LightEmission = 0.8
	cross.Rate = 0
	cross.Enabled = false
	cross:SetAttribute('EmitCount', 2)
	local sparks = Instance.new('ParticleEmitter', attachment)
	sparks.Name = 'ImpactSparks'
	sparks.Texture = 'rbxassetid://13644087339'
	sparks.Lifetime = NumberRange.new(0.35,0.7)
	sparks.Speed = NumberRange.new(10,18)
	sparks.SpreadAngle = Vector2.new(180,180)
	sparks.Rotation = NumberRange.new(-180,180)
	sparks.RotSpeed = NumberRange.new(-200,200)
	sparks.Size = NumberSequence.new({NumberSequenceKeypoint.new(0,0),NumberSequenceKeypoint.new(0.5,0.5),NumberSequenceKeypoint.new(1,0)})
	sparks.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0,1),NumberSequenceKeypoint.new(0.2,0),NumberSequenceKeypoint.new(1,1)})
	sparks.LightEmission = 1
	sparks.Rate = 0
	sparks.Enabled = false
	sparks:SetAttribute('EmitCount', 14)
	local ring = Instance.new('ParticleEmitter', attachment)
	ring.Name = 'ImpactRing'
	ring.Texture = 'rbxassetid://7216847656'
	ring.Lifetime = NumberRange.new(0.35)
	ring.Speed = NumberRange.new(0.1)
	ring.RotSpeed = NumberRange.new(-360)
	ring.Size = NumberSequence.new({NumberSequenceKeypoint.new(0,1),NumberSequenceKeypoint.new(1,4)})
	ring.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0,1),NumberSequenceKeypoint.new(0.15,0.3),NumberSequenceKeypoint.new(1,1)})
	ring.Rate = 0
	ring.Enabled = false
	ring:SetAttribute('EmitCount', 1)
	host.Parent = vfx
end
return Installer
