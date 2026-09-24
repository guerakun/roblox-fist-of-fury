-- Earned achievements; zero IDs intentionally disable external badge issuance.
local Config = {}
Config.Order = {"District1", "District2", "District3", "RankS", "Heat5", "Heat10", "Heat15", "NoHitBoss"}
Config.Badges = {
    District1 = {BadgeId=0, Name="CROSSING CLEARED", Description="Clear the first district."},
    District2 = {BadgeId=0, Name="LAST DEPARTURE", Description="Clear the abandoned station."},
    District3 = {BadgeId=0, Name="FACTORY SILENCED", Description="Clear the abandoned factory."},
    RankS = {BadgeId=0, Name="S RANK", Description="Earn an S district rank."},
    Heat5 = {BadgeId=0, Name="HEAT 5", Description="Participate in a full campaign clear with at least 5 Heat points."},
    Heat10 = {BadgeId=0, Name="HEAT 10", Description="Participate in a full campaign clear with at least 10 Heat points."},
    Heat15 = {BadgeId=0, Name="HEAT 15", Description="Participate in a full campaign clear with 15 Heat points."},
    NoHitBoss = {BadgeId=0, Name="UNTOUCHED", Description="Clear a district with explicitly recorded zero boss damage taken."},
}
return Config
