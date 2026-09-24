-- Server-owned tuning. Each district has a skirmish, miniboss, escalation, and boss.
local Config = {}
Config.Title = "CURTAIN BREAK"
Config.MaxPlayers = 4
Config.Stocks = 3
Config.WalkSpeed = 22
Config.JumpPower = 52
Config.LaneMin = -14
Config.LaneMax = 14
Config.BlastMargin = 24
Config.PlayerPercentLimit = 200
Config.Stages = {
    {Name = "ASHGATE CROSSING", Theme = "City", MinX = 0, MaxX = 180, CenterX = 90, SpawnX = 28,
        Waves = {
            {Title = "CROSSING UNDER CURSE", Kind = "Wave", SpawnX = 65, Enemies = {Grunt = 3}},
            {Title = "CROSSWALK EXECUTIONER", Kind = "Miniboss", SpawnX = 75, Enemies = {Executioner = 1}},
            {Title = "THE ALARMS AWAKEN", Kind = "Wave", SpawnX = 116, Enemies = {Runner = 2, Grunt = 2}},
            {Title = "SIREN MARSHAL", Kind = "Boss", SpawnX = 135, Enemies = {SirenMarshal = 1}},
        }},
    {Name = "ABANDONED STATION", Theme = "Station", MinX = 180, MaxX = 360, CenterX = 270, SpawnX = 208,
        Waves = {
            {Title = "LAST SERVICE", Kind = "Wave", SpawnX = 244, Enemies = {Runner = 2, Grunt = 2}},
            {Title = "PLATFORM WIDOW", Kind = "Miniboss", SpawnX = 255, Enemies = {PlatformWidow = 1}},
            {Title = "PLATFORM ZERO", Kind = "Wave", SpawnX = 298, Enemies = {Runner = 2, Brute = 1}},
            {Title = "THE LAST CONDUCTOR", Kind = "Boss", SpawnX = 315, Enemies = {LastConductor = 1}},
        }},
    {Name = "ABANDONED FACTORY", Theme = "Factory", MinX = 360, MaxX = 540, CenterX = 450, SpawnX = 388,
        Waves = {
            {Title = "COLD FURNACE", Kind = "Wave", SpawnX = 424, Enemies = {Grunt = 2, Brute = 1}},
            {Title = "FURNACE HOUND", Kind = "Miniboss", SpawnX = 435, Enemies = {FurnaceHound = 1}},
            {Title = "PRESSURE RISING", Kind = "Wave", SpawnX = 478, Enemies = {Runner = 2, Brute = 2}},
            {Title = "KILN SOVEREIGN", Kind = "Boss", SpawnX = 495, Enemies = {KilnSovereign = 1}},
        }},
}
Config.Attacks = {
    Light = {Damage = 8, Knockback = 15, Growth = 0.24, Lift = 8, Range = 7, Width = 7, Windup = 0.10, Cooldown = 0.32, Stun = 0.26},
    Heavy = {Damage = 19, Knockback = 38, Growth = 0.52, Lift = 26, Range = 9, Width = 8, Windup = 0.30, Cooldown = 0.95, Stun = 0.50},
}
Config.CharacterOrder = {"Gale", "Piston", "Tide"}
Config.HeroNamesPendingApproval = true
Config.Characters = {
    Gale = {Name = "Rook Calder", Tip = "Close distance, then drive through with a wind-wrapped kick.", Title = "GALE RUNNER", Color = Color3.fromRGB(111, 222, 217), Speed = 23,
        SpecialName = "CYCLONE DRIVE", Special = {Damage = 27, Knockback = 44, Growth = 0.56, Lift = 18, Range = 15, Width = 11, Windup = 0.22, Cooldown = 6, Stun = 0.60}},
    Piston = {Name = "Bo Marlowe", Tip = "Line up the piston gauntlet for a long, narrow strike.", Title = "PISTON BRAWLER", Color = Color3.fromRGB(219, 168, 84), Speed = 21,
        SpecialName = "RECOIL CANNON", Special = {Damage = 31, Knockback = 51, Growth = 0.65, Lift = 20, Range = 23, Width = 7, Windup = 0.38, Cooldown = 7, Stun = 0.65}},
    Tide = {Name = "Isla Veyra", Tip = "Sweep a wide lane with the glaive; punish clustered enemies.", Title = "TIDE BLADE", Color = Color3.fromRGB(76, 168, 230), Speed = 24,
        SpecialName = "UNDERTOW ARC", Special = {Damage = 23, Knockback = 40, Growth = 0.50, Lift = 29, Range = 12, Width = 19, Windup = 0.18, Cooldown = 5.5, Stun = 0.55}},
}
Config.Enemies = {
    Grunt = {Name = "Veil Husk", Role = "Grunt", Color = Color3.fromRGB(119, 83, 172), Speed = 12, Weight = 1, Threshold = 56, Damage = 9, Reach = 6, Windup = 0.68, Cooldown = 1.85, Scale = 1},
    Runner = {Name = "Hollow Strider", Role = "Grunt", Color = Color3.fromRGB(96, 176, 191), Speed = 18, Weight = 0.85, Threshold = 48, Damage = 8, Reach = 6, Windup = 0.55, Cooldown = 1.6, Scale = 0.92},
    Brute = {Name = "Concrete Warden", Role = "Grunt", Color = Color3.fromRGB(174, 94, 113), Speed = 9, Weight = 1.6, Threshold = 90, Damage = 16, Reach = 8, Windup = 1.0, Cooldown = 2.3, Scale = 1.25},
    Executioner = {Name = "Crosswalk Executioner", Role = "Miniboss", Color = Color3.fromRGB(244, 177, 59), Speed = 12, Weight = 1.6, Threshold = 190, Damage = 17, Reach = 12, Windup = 0.9, Cooldown = 2.4, Scale = 1.35, Poise = 38, Moves = {"Cleaver", "CrossingSweep", "Cleaver"}, PhaseMoves = {"CrossingSweep", "Cleaver", "CrossingSweep"}},
    SirenMarshal = {Name = "Siren Marshal", Role = "Boss", Color = Color3.fromRGB(252, 81, 109), Speed = 11, Weight = 2.0, Threshold = 280, Damage = 19, Reach = 14, Windup = 1.0, Cooldown = 2.7, Scale = 1.55, Poise = 52, Moves = {"SirenLine", "AlarmRing", "Cleaver"}, PhaseMoves = {"SplitAlarm", "SirenLine", "AlarmRing"}},
    PlatformWidow = {Name = "Platform Widow", Role = "Miniboss", Color = Color3.fromRGB(88, 228, 228), Speed = 17, Weight = 1.4, Threshold = 205, Damage = 16, Reach = 12, Windup = 0.95, Cooldown = 2.3, Scale = 1.3, Poise = 36, Moves = {"RailLunge", "TicketCut", "RailLunge"}, PhaseMoves = {"PlatformMark", "RailLunge", "TicketCut"}},
    LastConductor = {Name = "The Last Conductor", Role = "Boss", Color = Color3.fromRGB(113, 158, 252), Speed = 10, Weight = 2.0, Threshold = 305, Damage = 20, Reach = 14, Windup = 1.2, Cooldown = 2.8, Scale = 1.65, Poise = 52, Moves = {"GhostTrain", "BellStrike", "GhostTrain"}, PhaseMoves = {"DepartureCross", "GhostTrain", "BellStrike"}},
    FurnaceHound = {Name = "Furnace Hound", Role = "Miniboss", Color = Color3.fromRGB(247, 137, 52), Speed = 16, Weight = 1.8, Threshold = 220, Damage = 18, Reach = 12, Windup = 1.0, Cooldown = 2.4, Scale = 1.4, Poise = 42, Moves = {"Pounce", "CinderTrail", "Bite"}, PhaseMoves = {"Pounce", "CinderTrail", "Pounce", "Bite"}},
    KilnSovereign = {Name = "Kiln Sovereign", Role = "Boss", Color = Color3.fromRGB(255, 103, 49), Speed = 9, Weight = 2.4, Threshold = 340, Damage = 22, Reach = 14, Windup = 1.25, Cooldown = 3.0, Scale = 1.8, Poise = 60, Moves = {"ForgeCrush", "FurnaceVent", "SlagPunch"}, PhaseMoves = {"TwinVent", "ForgeCrush", "SlagPunch", "ForgeCrush"}},
}
local eliteDesperation = {Executioner="CrossroadRuin", SirenMarshal="AlarmCollapse", PlatformWidow="WidowSpiral",
    LastConductor="FinalDeparture", FurnaceHound="CinderHowl", KilnSovereign="CoreMeltdown"}
for id, move in pairs(eliteDesperation) do
    local spec = Config.Enemies[id]
    spec.SignatureCooldown, spec.PhaseSummons, spec.FeintChance = 8, 2, .20
    spec.DesperationAt, spec.DesperationMove = .80, move
end
-- Six original combat roles; old aliases remain for fixtures and encounter compatibility.
local Archetypes = require(script.Parent.EnemyArchetypes)
for id, spec in pairs(Archetypes.Specs) do Config.Enemies[id] = table.clone(spec) end
Config.Enemies.Grunt.Archetype = "Husk"
Config.Enemies.Runner.Archetype = "Strider"
Config.Enemies.Brute.Archetype = "Brute"
Config.Stages[1].Waves[1].Enemies = {Husk = 2, Warden = 1}
Config.Stages[1].Waves[3].Enemies = {Strider = 2, Grappler = 1, Husk = 1}
Config.Stages[2].Waves[1].Enemies = {Pitcher = 1, Leaper = 1, Husk = 2}
Config.Stages[2].Waves[3].Enemies = {Warden = 1, Grappler = 1, Brute = 1}
Config.Stages[3].Waves[1].Enemies = {Pitcher = 1, Leaper = 1, Brute = 1}
Config.Stages[3].Waves[3].Enemies = {Strider = 1, Grappler = 1, Warden = 1, Brute = 1}
-- Authored entrance sequence and bounded reinforcement timing; enemy budgets remain unchanged in M2.
for _,stage in ipairs(Config.Stages)do
    for _,wave in ipairs(stage.Waves)do
        wave.Entries={"Left","Right","Door","Drop"}
        wave.Pulse={After=12,AliveThreshold=1}
    end
end
-- One-way legacy-ID fingerprints support retired save records without retaining display labels.
-- Exact compatibility fixtures and provenance live in docs/launch/HERO_MIGRATION.md.
local legacyHeroFingerprints = {[261244702] = "Gale", [266550891] = "Piston", [3479830332] = "Tide"}
function Config.NormalizeHeroId(value)
    if type(value) ~= "string" or #value > 32 then return "Gale" end
    if Config.Characters[value] then return value end
    local hash = 5381
    for i = 1, #value do hash = (hash * 33 + string.byte(string.lower(value), i)) % 4294967296 end
    return legacyHeroFingerprints[hash] or "Gale"
end
return Config
