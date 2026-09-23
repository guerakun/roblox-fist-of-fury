-- All combat numbers are owned and enforced by the server.
local Config = {}
Config.Title = "NIGHTFALL // CURSED CROSSING"
Config.MaxPlayers = 4
Config.Stocks = 3
Config.WalkSpeed = 22
Config.JumpPower = 52
Config.LaneMin = -14
Config.LaneMax = 14
Config.BlastMargin = 24
Config.PlayerPercentLimit = 200
Config.Stages = {
	{Name = "SHIBUYA CROSSING", MinX = 0, MaxX = 180, CenterX = 90, SpawnX = 28,
		Waves = {{Grunt = 3}, {Grunt = 3, Runner = 1}, {Grunt = 2, Brute = 1}}},
	{Name = "NEON BACKSTREETS", MinX = 180, MaxX = 360, CenterX = 270, SpawnX = 208,
		Waves = {{Runner = 3, Grunt = 2}, {Brute = 2, Runner = 2}, {Grunt = 3, Brute = 1, Runner = 2}}},
	{Name = "STATION VEIL", MinX = 360, MaxX = 540, CenterX = 450, SpawnX = 388,
		Waves = {{Grunt = 3, Runner = 2}, {Brute = 2, Runner = 2}, {Boss = 1, Grunt = 2}}},
}
Config.Attacks = {
	Light = {Damage = 8, Knockback = 15, Growth = 0.24, Lift = 8, Range = 7, Width = 7, Windup = 0.10, Cooldown = 0.32, Stun = 0.30},
	Heavy = {Damage = 19, Knockback = 38, Growth = 0.52, Lift = 26, Range = 9, Width = 8, Windup = 0.30, Cooldown = 0.95, Stun = 0.55},
}
Config.Characters = {
	Naruto = {Name = "Naruto", Title = "WIND DISCIPLE", Color = Color3.fromRGB(255, 158, 54), Speed = 23,
		SpecialName = "SPIRAL BURST", Special = {Damage = 27, Knockback = 44, Growth = 0.56, Lift = 18, Range = 15, Width = 11, Windup = 0.22, Cooldown = 6, Stun = 0.65}},
	Luffy = {Name = "Luffy", Title = "RUBBER VANGUARD", Color = Color3.fromRGB(244, 77, 87), Speed = 21,
		SpecialName = "ELASTIC CANNON", Special = {Damage = 31, Knockback = 51, Growth = 0.65, Lift = 20, Range = 23, Width = 7, Windup = 0.38, Cooldown = 7, Stun = 0.7}},
	Tanjiro = {Name = "Tanjiro", Title = "TIDE SWORDSMAN", Color = Color3.fromRGB(61, 220, 192), Speed = 24,
		SpecialName = "TIDAL ARC", Special = {Damage = 23, Knockback = 40, Growth = 0.50, Lift = 29, Range = 12, Width = 19, Windup = 0.18, Cooldown = 5.5, Stun = 0.6}},
}
Config.Enemies = {
	Grunt = {Name = "Veil Husk", Color = Color3.fromRGB(119, 83, 172), Speed = 12, Weight = 1, Threshold = 72, Damage = 10, Reach = 6, Windup = 0.65, Cooldown = 1.65, Scale = 1},
	Runner = {Name = "Hollow Strider", Color = Color3.fromRGB(96, 176, 191), Speed = 20, Weight = 0.85, Threshold = 58, Damage = 8, Reach = 6, Windup = 0.42, Cooldown = 1.25, Scale = 0.9},
	Brute = {Name = "Concrete Warden", Color = Color3.fromRGB(174, 94, 113), Speed = 9, Weight = 1.65, Threshold = 125, Damage = 18, Reach = 8, Windup = 1.05, Cooldown = 2.25, Scale = 1.35},
	Boss = {Name = "THE SIGNAL EATER", Color = Color3.fromRGB(194, 67, 247), Speed = 11, Weight = 2.8, Threshold = 380, Damage = 23, Reach = 13, Windup = 1.1, Cooldown = 2.4, Scale = 1.8},
}
return Config
