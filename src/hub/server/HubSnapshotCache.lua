-- Presentation-only cache. Never use this data to authorize party mutations or travel.
local Cache={}
Cache.__index=Cache
function Cache.new(options)
    return setmetatable({entries={},load=options.load,now=options.now or os.clock,ttl=options.ttl or 5},Cache)
end
function Cache:Get(key)
    local entry=self.entries[key]
    if not entry then entry={expires=0}self.entries[key]=entry end
    if entry.loading or self.now()<entry.expires then
        if entry.error and not entry.loaded then error(entry.error)end
        return entry.value
    end
    entry.loading=true entry.expires=self.now()+self.ttl
    local ok,value=pcall(self.load,key)
    entry.loading=false entry.expires=self.now()+self.ttl
    if ok then entry.value=value entry.loaded=true entry.error=nil
    else entry.error=tostring(value)end
    if not ok and not entry.loaded then error(entry.error)end
    return entry.value
end
function Cache:Remove(key)self.entries[key]=nil end
return Cache
