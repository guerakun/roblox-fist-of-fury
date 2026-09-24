-- Prices and rewards are server-owned. No combat power is purchasable with Robux.
local P = {}
P.DataStoreName = "CurtainBreakProfiles_v1"
P.SchemaVersion = 1
P.StudioPersistence = false
P.SalesEnabled = false
P.ChapterPassId = 0 -- Configure an owned game pass only after live persistence/asset validation.
P.ChapterName = "AFTER THE LAST TRAIN"
P.XPPerTier = 150
P.Rewards = {Wave = {Coins = 25, XP = 35}, Miniboss = {Coins = 60, XP = 75}, Boss = {Coins = 120, XP = 120}}
P.Boons = {
    -- Disabled until authoritative restrictions and actual combat checks are integrated.
    {Id="GlassCannon",Name="GLASS CANNON",XP=600,Enabled=false,Description="Deal 20% more damage and take 20% more damage.",DamageMultiplier=1.2,DamageTakenMultiplier=1.2},
    {Id="Berserker",Name="BERSERKER",XP=800,Enabled=false,Description="Gain style twice as fast. Blocking is unavailable.",StyleGainMultiplier=2,CanBlock=false},
    {Id="Anchor",Name="ANCHOR",XP=1000,Enabled=false,Description="30% heavier against knockback. Dash and Burst are unavailable.",WeightMultiplier=1.3,CanDash=false},
    {Id = "Guardian", Name = "GUARDIAN", XP = 0, Description = "Take 8% less damage. A forgiving first choice.", DamageReduction = 0.08},
    {Id = "Focus", Name = "FOCUS", XP = 200, Description = "Deal 8% more damage. Earned through chapter XP.", DamageMultiplier = 1.08},
    {Id = "Haste", Name = "HASTE", XP = 400, Description = "+2 movement speed. Reposition around telegraphs.", MoveSpeedBonus = 2},
}
P.Cosmetics = {
    {Id = "Heat5", Name = "EMBER CONTRACTOR", Kind = "Title", Price = 0, TrackOnly = true, Color = Color3.fromRGB(255,196,102)},
    {Id = "Heat10", Name = "INFERNO CONTRACTOR", Kind = "Title", Price = 0, TrackOnly = true, Color = Color3.fromRGB(255,135,100)},
    {Id = "Heat15", Name = "CURTAIN INFERNO", Kind = "Title", Price = 0, TrackOnly = true, Color = Color3.fromRGB(214,136,255)},
    {Id = "None", Name = "CLEAN SILHOUETTE", Kind = "Trail", Price = 0, Color = Color3.fromRGB(180,200,220)},
    {Id = "BlueHour", Name = "BLUE HOUR", Kind = "Trail", Price = 150, Color = Color3.fromRGB(91,220,255)},
    {Id = "Ember", Name = "EMBER LINE", Kind = "Trail", Price = 250, Color = Color3.fromRGB(255,149,66)},
    {Id = "Orchid", Name = "ORCHID SIGNAL", Kind = "Trail", Price = 350, Color = Color3.fromRGB(204,117,255)},
    {Id = "FirstResponder", Name = "FIRST RESPONDER", Kind = "Title", Price = 200, Color = Color3.fromRGB(107,235,200)},
    {Id = "LastPassenger", Name = "LAST PASSENGER", Kind = "Title", Price = 350, Color = Color3.fromRGB(171,192,230)},
    {Id = "Dawn", Name = "DAYBREAK", Kind = "Trail", Price = 0, TrackOnly = true, Color = Color3.fromRGB(255,209,130)},
    {Id = "CurtainBreaker", Name = "CURTAIN BREAKER", Kind = "Title", Price = 0, TrackOnly = true, Color = Color3.fromRGB(123,248,236)},
    {Id = "Platinum", Name = "PLATINUM RAIL", Kind = "Trail", Price = 0, Premium = true, Color = Color3.fromRGB(230,238,255)},
    {Id = "Crimson", Name = "CRIMSON HORIZON", Kind = "Trail", Price = 0, Premium = true, Color = Color3.fromRGB(255,102,135)},
    {Id = "Jade", Name = "JADE ECHO", Kind = "Trail", Price = 0, Premium = true, Color = Color3.fromRGB(100,255,170)},
    {Id = "Nightwatch", Name = "NIGHTWATCH", Kind = "Title", Price = 0, Premium = true, Color = Color3.fromRGB(190,199,255)},
    {Id = "NeonSoul", Name = "NEON SOUL", Kind = "Title", Price = 0, Premium = true, Color = Color3.fromRGB(255,155,236)},
    {Id = "Afterlight", Name = "AFTERLIGHT", Kind = "Trail", Price = 0, Premium = true, Color = Color3.fromRGB(245,220,255)},
}
P.Tiers = {
    {Coins = 50}, {Coins = 50, Premium = "Nightwatch"}, {Cosmetic = "BlueHour"},
    {Coins = 75, Premium = "Platinum"}, {Coins = 75}, {Cosmetic = "FirstResponder", Premium = "Crimson"},
    {Coins = 100}, {Coins = 100, Premium = "NeonSoul"}, {Cosmetic = "Dawn"},
    {Coins = 125, Premium = "Jade"}, {Coins = 150}, {Cosmetic = "CurtainBreaker", Premium = "Afterlight"},
}
function P.FindCosmetic(id)
    for _, item in ipairs(P.Cosmetics) do if item.Id == id then return item end end
end
function P.FindBoon(id)
    for _, item in ipairs(P.Boons) do if item.Id == id then return item end end
end
return P
