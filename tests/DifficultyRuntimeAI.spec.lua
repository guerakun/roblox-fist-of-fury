-- Root-only Studio fixture. Server options and actual spawned threshold; no tier unlock claim.
return function()
    assert(game:GetService("RunService"):IsStudio(),"Studio only")
    local C=require(game.ServerScriptService.NightfallServer.CombatService)
    local Config=require(game.ReplicatedStorage.Nightfall.Shared.Config)
    local ok,err=xpcall(function()
        C.ClearEnemies();C.SetEncounterState({status="Waiting"})
        assert(not C.SetRunOptions("Forged",{}),"Unknown profile accepted")
        assert(not C.SetRunOptions("Hard",{"Fast"}),"Unimplemented Heat accepted")
        assert(C.SetRunOptions("Hard",{}),"Hard server selection")
        C.SetEncounterState({status="Combat",wave=1})
        assert(C.SetRunOptions("Hard",{}) and not C.SetRunOptions("Normal",{}),"Late arrivals may match but not mutate active options")
        local model=C.SpawnEnemy("Executioner",Vector3.new(75,0,0),1.28)
        local expected=Config.Enemies.Executioner.Threshold*1.28*Config.Difficulties.Hard.EliteHealthScale
        assert(math.abs(C.GetEnemies()[model].threshold-expected)<.001,"Elite tier and frozen party HP compose")
        local grunt=C.SpawnEnemy("Husk",Vector3.new(65,0,0),1.18)
        assert(math.abs(C.GetEnemies()[grunt].threshold-Config.Enemies.Husk.Threshold*1.18)<.001,"Elite HP does not leak into grunt stats")
        for _,player in ipairs(game.Players:GetPlayers())do local s=C.GetSnapshot(player);if s then assert(s.difficulty=="Hard" and #s.heat==0,"Snapshot tier")end end
    end,debug.traceback)
    C.ClearEnemies();C.ResetLobby();C.SetEncounterState({status="Waiting",wave=0,enemiesRemaining=0})
    assert(C.GetRunOptions().difficulty=="Normal","Fresh lobby default")
    assert(ok,err)
    return {invalidRejected=2,activeOptionsImmutable=true,eliteHp=true,gruntHp=true,lobbyReset=true}
end
