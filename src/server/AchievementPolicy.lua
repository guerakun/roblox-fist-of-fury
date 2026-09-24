-- Pure predicates for server-finalized completed districts, never client result input.
local Policy = {}
local ranks = {D=true,C=true,B=true,A=true,S=true}
local function finite(n) return type(n)=="number" and n==n and n>=0 and n<math.huge end
function Policy.Evaluate(result,heatPoints,fullParticipation)
    if type(result)~="table" or not finite(result.stage) or result.stage%1~=0 or result.stage<1 or result.stage>3
        or not ranks[result.rank] or type(result.campaignId)~="string" or #result.campaignId==0
        or result.id~=result.campaignId..":"..result.stage
        or not finite(heatPoints) or heatPoints%1~=0 or heatPoints>15
        or (fullParticipation~=nil and type(fullParticipation)~="boolean") then return {} end
    if result.bossDamageTaken~=nil and not finite(result.bossDamageTaken) then return {} end
    local earned={"District"..result.stage}
    if result.rank=="S" then table.insert(earned,"RankS") end
    if result.stage==3 and fullParticipation==true then
        for _,threshold in ipairs({5,10,15}) do
            if heatPoints>=threshold then table.insert(earned,"Heat"..threshold) end
        end
    end
    if result.bossDamageTaken==0 then table.insert(earned,"NoHitBoss") end
    return earned
end
return Policy
