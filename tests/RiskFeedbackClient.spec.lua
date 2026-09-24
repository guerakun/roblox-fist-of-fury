-- Local cosmetic lifecycle/notice fixture. No cost, score or reward authority is exercised.
return function(Feedback)
    local player=game.Players.LocalPlayer
    Feedback=Feedback or require(player.PlayerScripts.NightfallClient.RiskFeedback)
    local actor=Instance.new("Model")actor.Name="RiskFeedbackFixture"actor.Parent=workspace
    local root=Instance.new("Part")root.Name="HumanoidRootPart"root.Anchored=true root.CanCollide=false root.CanQuery=false root.CanTouch=false root.Parent=actor
    local t=0
    local fx=Feedback.new({player={UserId=42,Character=actor},clock=function()return t end,
        colors={ink=Color3.fromRGB(12,17,29),cyan=Color3.fromRGB(95,232,231),orange=Color3.fromRGB(255,166,76),muted=Color3.fromRGB(158,174,198)}})
    local ok,result=xpcall(function()
        assert(fx.Emit({kind="PerfectBlock",targetModel=actor})=="PERFECT BLOCK / STYLE UP")
        assert(actor:FindFirstChild("RiskRewardFlash"))
        assert(fx.Emit({kind="Desperation",targetModel=actor,playerUserId=42,cost=12})=="DESPERATION / +12% SELF")
        local count=0 for _,child in ipairs(actor:GetChildren())do if child:IsA("Highlight")then count+=1 end end assert(count==1)
        fx.Emit({kind="BountySpawn",targetModel=actor})assert(actor:FindFirstChild("BountyTarget"))
        fx.Emit({kind="BountySpawn",targetModel=actor})count=0 for _,child in ipairs(actor:GetChildren())do if child:IsA("BillboardGui")then count+=1 end end assert(count==1)
        assert(fx.Emit({kind="ScoreOrbClaim",playerUserId=43,score=20})==nil)
        assert(fx.Emit({kind="ScoreOrbClaim",playerUserId=42,score=20})=="STYLE +20")
        assert(fx.Emit({kind="ScoreOrbClaim",playerUserId=42,score=20})==nil)
        t=.5 assert(fx.Emit({kind="ScoreOrbClaim",playerUserId=42,score=20})=="STYLE +20")
        assert(fx.Emit({kind="BountyEscape",targetModel=actor})=="BOUNTY ESCAPED"and not actor:FindFirstChild("BountyTarget"))
        task.wait(.7)assert(not actor:FindFirstChild("RiskRewardFlash"))
        return {passed=true,acceptedEventNotices=true,duplicateCuesBounded=true,flashCleanup=true,orbNoticeRateLimit=true,noPhysicalPartsAdded=true}
    end,debug.traceback)
    actor:Destroy()assert(ok,result)return result
end
