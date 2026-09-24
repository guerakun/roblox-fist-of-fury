return function()
    local C=require(game.ReplicatedStorage.Nightfall.Shared.Config)
    local P=require(game.ServerScriptService.NightfallServer.ProfileStore)
    local fixtures=require(script.Parent.LegacyHeroFixtures)
    local seen={}
    for index,id in ipairs(C.CharacterOrder) do
        assert(C.NormalizeHeroId(id)==id and C.Characters[id],'stable identifier')
        local spec=C.Characters[id]
        assert(type(spec.Name)=='string' and not seen[spec.Name],'unique display names')
        seen[spec.Name]=true
        assert(spec.Speed==({23,21,24})[index],'movement values unchanged')
        assert(spec.Special.Damage==({27,31,23})[index],'special damage unchanged')
        assert(type(spec.Tip)=='string' and #spec.Tip>0,'metadata tips')
    end
    for _,row in ipairs(fixtures) do
        assert(C.NormalizeHeroId(row.old)==row.id,'retired identifier migration')
        assert(C.NormalizeHeroId(string.upper(row.old))==row.id,'case-insensitive migration')
        local data=P.Sanitize({hero=row.old,coins=123,xp=0})
        assert(data.hero==row.id and data.coins==123,'profile migration preserves currency')
    end
    assert(C.NormalizeHeroId(nil)=='Gale' and C.NormalizeHeroId({})=='Gale','malformed default')
    assert(C.NormalizeHeroId('Unknown')=='Gale' and P.Sanitize({}).hero=='Gale','absent default')
    return 'PASS: stable IDs, legacy profile normalization, display metadata and unchanged movement/damage'
end
