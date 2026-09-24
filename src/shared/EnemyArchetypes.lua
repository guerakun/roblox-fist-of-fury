-- Original enemy identities and move policy. The server owns all reaction decisions.
local A={}
A.Specs={
    Husk={Name="Veil Husk",Role="Grunt",Archetype="Husk",Color=Color3.fromRGB(119,83,172),Speed=12,Weight=1,Threshold=56,Damage=9,Reach=7,Windup=.55,Cooldown=1.85,Scale=1},
    Strider={Name="Hollow Strider",Role="Grunt",Archetype="Strider",Color=Color3.fromRGB(96,176,191),Speed=18,Weight=.85,Threshold=48,Damage=8,Reach=16,Windup=.55,Cooldown=1.6,Scale=.92},
    Grappler={Name="Iron Clasp",Role="Grunt",Archetype="Grappler",Color=Color3.fromRGB(198,131,75),Speed=10,Weight=1.45,Threshold=82,Damage=12,Reach=7,Windup=.65,Cooldown=2.1,Scale=1.15},
    Pitcher={Name="Shard Courier",Role="Grunt",Archetype="Pitcher",Color=Color3.fromRGB(112,176,129),Speed=13,Weight=.85,Threshold=50,Damage=10,Reach=20,Windup=.45,Cooldown=1.9,Scale=.95},
    Warden={Name="Ward Sentinel",Role="Grunt",Archetype="Warden",Color=Color3.fromRGB(110,135,197),Speed=10,Weight=1.25,Threshold=72,Damage=11,Reach=8,Windup=.55,Cooldown=1.95,Scale=1.05},
    Leaper={Name="Rift Acrobat",Role="Grunt",Archetype="Leaper",Color=Color3.fromRGB(189,126,192),Speed=16,Weight=.8,Threshold=54,Damage=9,Reach=17,Windup=.6,Cooldown=1.8,Scale=.92},
}
A.Moves={
    Husk={"HuskJab","HuskJumpKick"},Strider={"StriderSlide","StriderJab"},
    Grappler={"GrapplerGrab","GrapplerThrow"},Pitcher={"PitcherThrow","PitcherShove"},
    Warden={"WardenCounter","WardenKick"},Leaper={"LeaperVaultKick","LeaperJab"},Brute={"BruteFlop","BruteSwing"},
}
A.Aliases={Grunt="Husk",Runner="Strider"}
function A.Id(kind,spec) return spec.Archetype or A.Aliases[kind] or kind end
function A.Select(id,distance,observed,index)
    observed=observed or {};index=index or 0
    if id=="Husk" then return distance>9 and "HuskJumpKick" or "HuskJab" end
    if id=="Strider" then return distance>=9 and "StriderSlide" or "StriderJab" end
    if id=="Grappler" then return observed.blocking and "GrapplerGrab" or (index%2==0 and "GrapplerGrab" or "GrapplerThrow")end
    if id=="Pitcher" then return distance>=10 and "PitcherThrow" or "PitcherShove" end
    if id=="Warden" then return observed.action=="Light" and observed.combo==3 and "WardenCounter" or "WardenKick" end
    if id=="Leaper" then return (distance>7 or index%2==0) and "LeaperVaultKick" or "LeaperJab" end
    if id=="Brute" then return (distance>8 or index%2==0) and "BruteFlop" or "BruteSwing" end
    return "Melee"
end
return A
