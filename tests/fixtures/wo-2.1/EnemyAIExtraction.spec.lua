-- Differential decision traces against the frozen baseline; no players or combat state are mutated.
-- Install this and LegacyEnemyAI as sibling ModuleScripts in the Studio test folder.
return function()
    local AI = require(game.ServerScriptService.NightfallServer.EnemyAI)
    local Director = require(game.ServerScriptService.NightfallServer.AttackDirector)
    local Legacy = require(script.Parent.LegacyEnemyAI)
    local Http = game:GetService("HttpService")
    local cases = {
        {name="far chase",x=40}, {name="near attack",x=96},
        {name="lane chase",x=96,z=8}, {name="stunned",x=96,stunnedUntil=11},
        {name="launched",x=96,launchedUntil=11}, {name="recovering",x=96,recoveryUntil=11},
        {name="windup",x=96,attacking=true}, {name="cooldown hold",x=96,attackAt=11},
        {name="intermission",x=96,status="Intermission"}, {name="no targets",x=96,noTargets=true},
        {name="dead",x=96,health=0}, {name="missing root",x=96,missingRoot=true},
        {name="blast zone",x=96,blast=true}, {name="clamped arena",x=190,z=20},
        {name="elite phase threshold",x=96,elite=true,percent=52},
        {name="elite below phase",x=96,elite=true,percent=51.99},
        {name="phase while stunned",x=96,elite=true,percent=60,stunnedUntil=11},
        {name="elite distant signature",x=50,elite=true,move="Mark"},
        {name="elite close move chase",x=50,elite=true,move="Bite"},
        {name="opposite facing",x=105}, {name="target focus penalty",x=96,secondTarget=true,recentFirst=true},
        {name="skip respawning target",x=96,secondTarget=true,respawningFirst=true},
        {name="solo cap full",x=96,active=2}, {name="solo cap room",x=96,active=1},
        {name="expired windup",x=96,active=2,expired=true},
    }
    local function run(step, case)
        local traces, roots, humans, enemies, records = {}, {}, {}, {}, {}
        local model={Name="Fixture"}
        local function part(x,z)
            local backing={CFrame=CFrame.new(x,3,z or 0)}
            return setmetatable(backing,{__index=function(self,key)
                if key=="Position" then return rawget(self,"CFrame").Position end
            end})
        end
        local h={Health=case.health or 100}
        function h:Move(v) table.insert(traces,{"Move",v.X,v.Y,v.Z}) end
        function h:MoveTo(v) table.insert(traces,{"MoveTo",v.X,v.Y,v.Z,self.WalkSpeed}) end
        humans[model]=h
        if not case.missingRoot then roots[model]=part(case.x,case.z) end
        local data={spec={Role=case.elite and "Boss" or "Grunt",Reach=8,Speed=12,Name="Fixture",
            Moves={case.move or "Bite"},PhaseMoves={"Mark"}},kind="Fixture",phase=1,
            percent=case.percent or 0,threshold=100,moveIndex=0,facing=1,
            stunnedUntil=case.stunnedUntil or 0,launchedUntil=case.launchedUntil or 0,
            recoveryUntil=case.recoveryUntil or 0,attacking=case.attacking or false,
            attackAt=case.attackAt or 0,resolveAt=12,targetHistory={}}
        enemies[model]=data
        local alive={}
        if not case.noTargets then
            local p={Name="First",Character={}}
            roots[p.Character]=part(100,0);records[p]={respawning=case.respawningFirst or false}
            table.insert(alive,p)
            if case.recentFirst then data.targetHistory[p]=10 end
            if case.secondTarget then
                local other={Name="Second",Character={}}
                roots[other.Character]=part(106,0);records[other]={respawning=false};table.insert(alive,other)
            end
        end
        for i=1,case.active or 0 do
            local extra={Name="Active"..i};roots[extra]=part(90+i,0)
            humans[extra]={Health=100,Move=function() end}
            enemies[extra]={spec={Role="Grunt"},phase=1,stunnedUntil=0,launchedUntil=0,
                recoveryUntil=11,attacking=true,resolveAt=case.expired and 10 or 12}
        end
        local context={enemies=enemies,records=records,arena={MinX=0,MaxX=180},
            encounter={status=case.status or "Combat"},Config={BlastMargin=20},
            root=function(m)return roots[m]end,humanoid=function(m)return humans[m]end,
            now=function()return 10 end,Combat={GetAlivePlayers=function()return alive end},
            CombatMath={InBlastZone=function()return case.blast or false end},
            knockOut=function(m)table.insert(traces,{"KO",m.Name})end,
            attributes=function(_,d)table.insert(traces,{"Attributes",d.phase,d.moveIndex})end,
            fx=function(kind,pos,fields)table.insert(traces,{"FX",kind,pos.X,pos.Z,fields.phase,fields.enemy})end,
            beginEnemyAttack=function(_,d,target,move,players)
                table.insert(traces,{"Attack",target.Name,move,#players,d.facing})
            end}
        step(10,context)
        local r=roots[model]
        table.insert(traces,{"Result",data.phase,data.moveIndex,data.facing,r and r.Position.X or "none",r and r.Position.Z or "none"})
        -- KO order of unrelated fixtures is not relevant to the decision under test.
        if case.blast then table.sort(traces,function(a,b)return Http:JSONEncode(a)<Http:JSONEncode(b)end) end
        return Http:JSONEncode(traces)
    end
    for _,case in ipairs(cases)do
        local before,after=run(Legacy,case),run(AI.Step,case)
        assert(before==after,case.name.." trace changed: "..before.." != "..after)
    end
    for n=0,8 do assert(Director.Cap(n)==math.min(3,math.max(2,n)),"unchanged cap "..n)end
    local clockCalls=0
    local count=Director.CountActive({a={attacking=true,resolveAt=12},b={attacking=false,resolveAt=12},c={attacking=true,resolveAt=10}},function()clockCalls+=1;return 10 end)
    assert(count==1 and clockCalls==2,"preserve strict resolve boundary and short-circuit clock calls")
    return "PASS: "..#cases.." baseline/extracted decision traces; nine caps; active windup boundary/clock sampling"
end
