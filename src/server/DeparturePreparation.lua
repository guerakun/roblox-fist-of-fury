-- Resume a partially completed profile-release batch without stranding released members.
local D={}D.__index=D
function D.new(adapter)return setmetatable({a=adapter,owned={}},D)end
function D:Prepare(players,token)
    -- Validate the entire batch before making any irreversible release attempt.
    for _,p in ipairs(players)do
        local profile=self.a.profile(p)local own=self.owned[p]
        assert(profile,'profile unavailable')
        assert((own and own.token==token and own.profile==profile)or self.a.canMutate(profile),'profile is read-only')
    end
    for _,p in ipairs(players)do
        local profile=self.a.profile(p)local own=self.owned[p]
        if not own then own={token=token,profile=profile,released=false}self.owned[p]=own end
        assert(own.token==token and own.profile==profile,'different deployment already preparing')
        if not own.released then
            -- Keep ownership across a failed release: closing profiles can safely retry Release.
            local ok=self.a.release(profile)
            assert(ok,'profile release deferred')own.released=true
        end
    end
    return true
end
function D:Clear(player)self.owned[player]=nil end
return D
