-- Root-only pre-run difficulty selection and provenance. Outside production projects.
-- Does not change HumanBot actions, timing, damage, movement, rewards or RNG.
if not game:GetService("RunService"):IsStudio()then return end
local C=require(game.ServerScriptService:WaitForChild("NightfallServer"):WaitForChild("CombatService"))
local tier=script:GetAttribute("Difficulty")
assert(tier=="Normal"or tier=="Hard"or tier=="Nightmare","Set fixture Difficulty before Play")
assert(C.GetRunStatus()=="Waiting","Tier fixture must initialize before campaign readiness")
for _,key in ipairs({"SourceCommit","BotPolicyRevision"})do
    local value=script:GetAttribute(key)
    assert(type(value)=="string"and #value>0,"Nonempty fixture provenance required: "..key)
end
assert(C.SetRunOptions(tier,{}),"Tier selection must precede campaign readiness")
local report={difficulty=tier,heat={},sourceCommit=script:GetAttribute("SourceCommit"),
    botPolicyRevision=script:GetAttribute("BotPolicyRevision"),selectedBeforeRun=true,configurationStable=true}
local Http=game:GetService("HttpService")
workspace:SetAttribute("TierCampaignProvenance",Http:JSONEncode(report))
while task.wait(.2)do
    local options=C.GetRunOptions()
    if options.difficulty~=tier or #options.heat~=0 then
        report.configurationStable=false
        workspace:SetAttribute("TierCampaignProvenance",Http:JSONEncode(report))
        error("Campaign options changed during fixed-tier observation")
    end
end
