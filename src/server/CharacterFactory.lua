-- Authored R6 silhouettes. Toolbox keyframes animate the canonical R6 joints.
local Factory = {}
local function rgb(r,g,b) return Color3.fromRGB(r,g,b) end
function Factory.Create(hero)
	local model = Instance.new('Model'); model.Name = hero
	local skin = rgb(239,192,157)
	local function part(name,size,color,pos)
		local p=Instance.new('Part'); p.Name=name; p.Size=size; p.Color=color
		p.CFrame=CFrame.new(pos); p.TopSurface=Enum.SurfaceType.Smooth; p.BottomSurface=Enum.SurfaceType.Smooth
		p.CanCollide=false; p.Massless=true; p.Parent=model; return p
	end
	local root=part('HumanoidRootPart',Vector3.new(2,2,1),skin,Vector3.new(0,3,0)); root.Transparency=1; root.Massless=false
	local torso=part('Torso',Vector3.new(2,2,1),hero=='Naruto' and rgb(246,133,36) or hero=='Luffy' and rgb(175,35,47) or rgb(22,36,42),Vector3.new(0,3,0)); torso.CanCollide=true
	local head=part('Head',Vector3.new(2,1,1),skin,Vector3.new(0,4.5,0))
	local mesh=Instance.new('SpecialMesh',head); mesh.MeshType=Enum.MeshType.Head; mesh.Scale=Vector3.new(1.05,1.05,1.05)
	local armColor=hero=='Luffy' and skin or hero=='Naruto' and rgb(28,37,63) or rgb(26,41,44)
	local ra=part('Right Arm',Vector3.new(1,2,1),armColor,Vector3.new(1.5,3,0))
	local la=part('Left Arm',Vector3.new(1,2,1),armColor,Vector3.new(-1.5,3,0))
	local legColor=hero=='Luffy' and rgb(49,83,141) or hero=='Naruto' and rgb(239,123,30) or rgb(24,32,43)
	local rl=part('Right Leg',Vector3.new(1,2,1),legColor,Vector3.new(.5,1,0))
	local ll=part('Left Leg',Vector3.new(1,2,1),legColor,Vector3.new(-.5,1,0))
	local function joint(name,p0,p1,c0,c1)
		local m=Instance.new('Motor6D'); m.Name=name; m.Part0=p0;m.Part1=p1;m.C0=c0;m.C1=c1;m.Parent=p0
	end
	local rot=CFrame.Angles(-math.pi/2,0,math.pi)
	joint('RootJoint',root,torso,rot,rot)
	joint('Neck',torso,head,CFrame.new(0,1,0)*rot,CFrame.new(0,-.5,0)*rot)
	joint('Right Shoulder',torso,ra,CFrame.new(1,.5,0)*CFrame.Angles(0,math.pi/2,0),CFrame.new(-.5,.5,0)*CFrame.Angles(0,math.pi/2,0))
	joint('Left Shoulder',torso,la,CFrame.new(-1,.5,0)*CFrame.Angles(0,-math.pi/2,0),CFrame.new(.5,.5,0)*CFrame.Angles(0,-math.pi/2,0))
	joint('Right Hip',torso,rl,CFrame.new(1,-1,0)*CFrame.Angles(0,math.pi/2,0),CFrame.new(.5,1,0)*CFrame.Angles(0,math.pi/2,0))
	joint('Left Hip',torso,ll,CFrame.new(-1,-1,0)*CFrame.Angles(0,-math.pi/2,0),CFrame.new(-.5,1,0)*CFrame.Angles(0,-math.pi/2,0))
	local function detail(name,size,color,body,offset,shape)
		local p=part(name,size,color,Vector3.zero); if shape then p.Shape=shape end
		p.CFrame=body.CFrame*offset
		local w=Instance.new('WeldConstraint'); w.Part0=body;w.Part1=p;w.Parent=p;return p
	end
	for _,x in ipairs({-.3,.3}) do
		detail('Eye',Vector3.new(.17,.14,.05),rgb(20,25,36),head,CFrame.new(x,.03,-.5))
		detail('Brow',Vector3.new(.29,.055,.055),rgb(37,28,28),head,CFrame.new(x,.19,-.5)*CFrame.Angles(0,0,x>0 and -.12 or .12))
	end
	detail('Mouth',Vector3.new(.25,.035,.045),rgb(96,49,39),head,CFrame.new(0,-.23,-.5))
	for _,leg in ipairs({rl,ll}) do detail('Boot',Vector3.new(1.03,.38,1.08),rgb(21,28,37),leg,CFrame.new(0,-.81,-.03)) end
	if hero=='Naruto' then
		detail('JacketPanel',Vector3.new(1.3,1.45,.08),rgb(26,36,62),torso,CFrame.new(0,.25,-.53))
		detail('Zip',Vector3.new(.055,1.9,.09),rgb(220,220,210),torso,CFrame.new(0,0,-.58))
		detail('Headband',Vector3.new(1.65,.28,1.05),rgb(23,34,53),head,CFrame.new(0,.27,0))
		detail('MetalPlate',Vector3.new(.83,.24,.07),rgb(164,187,203),head,CFrame.new(0,.27,-.56))
		for i=-3,3 do detail('GoldenSpike',Vector3.new(.32,.6,.68),rgb(255,199,41),head,CFrame.new(i*.2,.65+(.1-math.abs(i)*.025),.06)*CFrame.Angles(0,0,-i*.15)) end
		for _,side in ipairs({-1,1}) do for n=1,2 do detail('Whisker',Vector3.new(.25,.025,.03),rgb(97,66,50),head,CFrame.new(side*.51,-.04-n*.09,-.51)*CFrame.Angles(0,0,side*.13)) end end
	elseif hero=='Luffy' then
		detail('OpenVest',Vector3.new(.68,1.72,.07),skin,torso,CFrame.new(0,.05,-.54))
		detail('Sash',Vector3.new(2.07,.28,1.07),rgb(246,192,46),torso,CFrame.new(0,-.78,0))
		detail('HatBrim',Vector3.new(.16,2.6,2.6),rgb(222,177,91),head,CFrame.new(0,.66,.02)*CFrame.Angles(0,0,math.pi/2),Enum.PartType.Cylinder)
		detail('HatCrown',Vector3.new(.48,1.65,1.65),rgb(222,177,91),head,CFrame.new(0,.94,.02)*CFrame.Angles(0,0,math.pi/2),Enum.PartType.Cylinder)
		detail('HatRibbon',Vector3.new(.16,1.7,1.7),rgb(180,35,43),head,CFrame.new(0,.75,.02)*CFrame.Angles(0,0,math.pi/2),Enum.PartType.Cylinder)
	else
		for row=0,3 do for col=0,3 do
			local color=(row+col)%2==0 and rgb(40,155,111) or rgb(20,32,35)
			detail('HaoriCheck',Vector3.new(.48,.47,.07),color,torso,CFrame.new(-.75+col*.5,.72-row*.48,-.55))
		end end
		for i=-3,3 do detail('BurgundyHair',Vector3.new(.34,.51,.7),rgb(72,30,39),head,CFrame.new(i*.19,.56,0)*CFrame.Angles(0,0,-i*.14)) end
		for _,x in ipairs({-.77,.77}) do detail('Earring',Vector3.new(.13,.38,.1),rgb(237,224,199),head,CFrame.new(x,-.39,-.15)) end
		detail('Scabbard',Vector3.new(.17,3.4,.19),rgb(21,28,34),torso,CFrame.new(-.25,.05,.69)*CFrame.Angles(0,0,-.52))
		detail('SwordHandle',Vector3.new(.2,.64,.2),rgb(236,218,193),torso,CFrame.new(.65,1.62,.69)*CFrame.Angles(0,0,-.52))
	end
	local hum=Instance.new('Humanoid'); hum.Name='Humanoid';hum.RequiresNeck=true;hum.DisplayDistanceType=Enum.HumanoidDisplayDistanceType.None;hum.Parent=model
	Instance.new('Animator',hum)
	local fill=Instance.new('PointLight');fill.Name='CharacterFill';fill.Brightness=1.4;fill.Range=11;fill.Color=rgb(227,232,255);fill.Shadows=false;fill.Parent=root
	model.PrimaryPart=root
	return model
end
return Factory
