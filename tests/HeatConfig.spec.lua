return function(Heat)
    local n=0 local function check(v)assert(v)n+=1 end
    local empty=Heat.Rules({})
    check(empty.points==0 and empty.stockCap==3 and empty.stockSharing)
    local all=Heat.Rules(Heat.Order)
    check(all.points==15 and all.rewardPercent==105 and all.stockCap==1 and not all.stockSharing)
    check(all.tokenBonus==1 and all.windupScale==.8 and all.gruntHealthScale==1.3 and not all.midCheckpoint and all.mutatedElites)
    for _,value in ipairs({{'OneLife','OneLife'},{'Forged'},{[2]='Frenzy'},{foo='Frenzy'},{[1]='Frenzy',[7]='OneLife'},'Frenzy'}) do check(Heat.Normalize(value)==nil)end
    local normal=Heat.Normalize({'OneLife','Frenzy'})
    check(normal[1]=='Frenzy' and normal[2]=='OneLife')
    check(Heat.Unlocked({},'Normal') and not Heat.Unlocked({},'Hard') and not Heat.Unlocked({},'Nightmare'))
    check(Heat.Unlocked({Normal=true},'Hard') and not Heat.Unlocked({Normal=true},'Nightmare'))
    check(Heat.Unlocked({Hard=true},'Nightmare') and not Heat.Unlocked({Hard=true},'forged'))
    local base={TokenBonus=2,WindupScale=.72,EliteHealthScale=1.3}
    local profile=Heat.ApplyDifficulty(base,Heat.Order)
    check(profile.TokenBonus==3 and math.abs(profile.WindupScale-.576)<1e-9 and profile.EliteHealthScale==1.3)
    check(base.TokenBonus==2 and base.WindupScale==.72)
    check(math.max(.3,.4*profile.WindupScale)==.3)
    return {passed=true,checks=n,scope='pure selection/rules; not combat enforcement or badge service'}
end
