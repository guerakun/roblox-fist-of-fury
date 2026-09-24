-- Actual EnemyAI decision timing with inert movement and a seeded evade quota.
return function()
    local AI=require(game.ServerScriptService.NightfallServer.EnemyAI)
    local D=require(game.ServerScriptService.NightfallServer.AttackDirector)
    local Config=require(game.ReplicatedStorage.Nightfall.Shared.Config)
    local cases=0
    for _,profile in pairs(Config.Difficulties)do
        local target={Character={}};local actor={SetAttribute=function()end}
        local r={Position=Vector3.new(50,3,0),CFrame=CFrame.new(50,3,0)}
        local pr={Position=Vector3.new(66,3,0)}
        local h={Health=100,FloorMaterial=Enum.Material.Concrete,Move=function()end,MoveTo=function()end}
        local data={kind="Leaper",spec=Config.Enemies.Leaper,stunnedUntil=0,launchedUntil=0,recoveryUntil=0,phase=1,
            moveIndex=0,targetHistory={},attackAt=100,attacking=false,attackSerial=0,evadeQuota=1-profile.EvadeChance}
        local c={director=D.New(),difficulty=profile,enemies={[actor]=data},records={[target]={facing=1,lastAction="Heavy",attackStartedAt=10}},
            Combat={GetAlivePlayers=function()return{target}end},arena={MinX=0,MaxX=180},Config=Config,
            encounter={status="Combat"},CombatMath={InBlastZone=function()return false end},
            root=function(model)return model==target.Character and pr or r end,humanoid=function()return h end,
            knockOut=function()error("Unexpected KO")end,fx=function()end,attributes=function()end,
            beginEnemyAttack=function()error("Cooldown fixture attacked")end}
        AI.Step(10,c)
        AI.Step(10+profile.ReactionDelay-.01,c)
        assert(not data.evadeUntil,"Reaction happened before configured delay")
        local observedAt=10+profile.ReactionDelay+.01
        AI.Step(observedAt,c)
        assert(data.evadeUntil and data.evadeUntil>observedAt and data.aiState=="Evade","Configured observation delay not consumed by AI")
        cases+=1
    end
    return {tierReactionCases=cases,earlyReactions=0}
end
