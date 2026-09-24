-- Test a real scheduler + AI decision with mocked movement, not live actors.
return function()
    local AI=require(game.ServerScriptService.NightfallServer.EnemyAI)
    local D=require(game.ServerScriptService.NightfallServer.AttackDirector)
    local target={Character={}}
    local actor={SetAttribute=function()end}
    local root={Position=Vector3.new(104,3,0),CFrame=CFrame.new(104,3,0)}
    local targetRoot={Position=Vector3.new(100,3,0)}
    local moves,attacks={},0
    local h={Health=100,Move=function()end,MoveTo=function(_,position)table.insert(moves,position)end}
    local data={spec={Role="Grunt",Reach=7,Speed=12},stunnedUntil=0,launchedUntil=0,recoveryUntil=0,
        phase=1,moveIndex=0,targetHistory={},attackAt=0,attacking=false,attackSerial=0}
    local director=D.New()
    -- Occupy the near-right slot so our actor owns the opposite side, despite starting right.
    local anchor={SetAttribute=function()end}
    D.Assign(director,anchor,target,Vector3.new(105,3,0),targetRoot.Position)
    local slot=D.Assign(director,actor,target,root.Position,targetRoot.Position)
    assert(slot.offset.X<0,"fixture owns opposite-side slot")
    local anchoredData={spec={Role="Grunt"},stunnedUntil=100,launchedUntil=0,recoveryUntil=0,attacking=false,phase=1}
    local context={director=director,enemies={[actor]=data,[anchor]=anchoredData},records={[target]={facing=1}},
        Combat={GetAlivePlayers=function()return{target}end},arena={MinX=0,MaxX=180},Config={BlastMargin=20},
        encounter={status="Combat"},CombatMath={InBlastZone=function()return false end},
        root=function(model)if model==target.Character then return targetRoot else return root end end,
        humanoid=function()return h end,knockOut=function()error("unexpected KO")end,
        fx=function()end,attributes=function()end,now=function()return 10 end,
        beginEnemyAttack=function()attacks+=1;data.attacking=true end}
    AI.Step(10,context)
    assert(attacks==0 and director.tokens[actor],"grant reserves approach; no wrong-side strike")
    AI.Step(10.1,context)
    assert(attacks==0 and data.aiState=="Engage" and moves[#moves].X<100,"existing token crosses before attacking")
    root.Position=Vector3.new(96,3,0);root.CFrame=CFrame.new(root.Position)
    AI.Step(10.2,context)
    assert(attacks==1,"attack begins only after reaching assigned side")
    return "PASS: same-side actor must cross into its opposite slot before either immediate or reserved attack"
end
