-- Session-locked single-document profiles. A failed load is never saved as defaults.
-- DataStore adapter is injected so locking/retries can be tested without live player data.
local HttpService = game:GetService("HttpService")
local Config = require(game.ReplicatedStorage.Nightfall.Shared.ProgressionConfig)
local Heroes = require(game.ReplicatedStorage.Nightfall.Shared.Config)
local AchievementConfig = require(game.ReplicatedStorage.Nightfall.Shared.AchievementConfig)
local ProfileStore = {}
ProfileStore.__index = ProfileStore
local LEASE_SECONDS = 180
local function clone(value)
    if type(value) ~= "table" then return value end
    local result = {}
    for key, child in pairs(value) do result[key] = clone(child) end
    return result
end
local function integer(value, cap)
    if type(value) ~= "number" or value ~= value or value == math.huge or value == -math.huge then return 0 end
    return math.clamp(math.floor(value), 0, cap)
end
function ProfileStore.Default()
    return {version = Config.SchemaVersion, hero = "Gale", coins = 0, xp = 0, clears = 0,
        owned = {None = true}, claimed = {}, premiumClaimed = {}, completedTiers = {}, achievements = {}, trail = "None", title = "None", boon = "Guardian"}
end
function ProfileStore.Sanitize(raw)
    local data = ProfileStore.Default()
    if type(raw) ~= "table" then return data end
    data.hero = Heroes.NormalizeHeroId(raw.hero)
    data.coins = integer(raw.coins, 100000000)
    data.xp = integer(raw.xp, 100000000)
    data.clears = integer(raw.clears, 10000000)
    if type(raw.completedTiers)=='table' then
        for _,id in ipairs({'Normal','Hard','Nightmare'})do if raw.completedTiers[id]==true then data.completedTiers[id]=true end end
    end
    if type(raw.achievements)=='table' then
        for id in pairs(AchievementConfig.Badges)do if raw.achievements[id]==true then data.achievements[id]=true end end
    end
    if type(raw.owned) == "table" then
        for id, owned in pairs(raw.owned) do if type(id) == "string" and owned == true and Config.FindCosmetic(id) then data.owned[id] = true end end
    end
    for _, key in ipairs({"claimed", "premiumClaimed"}) do
        if type(raw[key]) == "table" then
            for tier, claimed in pairs(raw[key]) do
                local n = tonumber(tier)
                if n and n % 1 == 0 and n >= 1 and n <= #Config.Tiers and claimed == true then data[key][tostring(n)] = true end
            end
        end
    end
    local trail = type(raw.trail) == "string" and Config.FindCosmetic(raw.trail)
    if trail and trail.Kind == "Trail" and data.owned[trail.Id] then data.trail = trail.Id end
    local title = type(raw.title) == "string" and Config.FindCosmetic(raw.title)
    if title and title.Kind == "Title" and data.owned[title.Id] then data.title = title.Id end
    local boon = type(raw.boon) == "string" and Config.FindBoon(raw.boon)
    if boon and data.xp >= boon.XP then data.boon = boon.Id end
    return data
end
function ProfileStore.new(adapter, options)
    options = options or {}
    return setmetatable({adapter = adapter, clock = options.clock or os.time, wait = options.wait or task.wait,
        token = options.token or HttpService:GenerateGUID(false), ephemeral = options.ephemeral == true}, ProfileStore)
end
function ProfileStore:_request(callback)
    for attempt = 1, 3 do
        local ok, result = pcall(callback)
        if ok then return true, result end
        if attempt < 3 then self.wait(0.5 * 2 ^ (attempt - 1)) end
    end
    return false, nil
end
function ProfileStore:Load(userId)
    local profile = {key = "player_" .. tostring(userId), data = ProfileStore.Default(), mode = "Unavailable",
        revision = 0, dirty = false, saving = false, closing = false, leaseUntil = 0,
        token = self.token .. ":" .. HttpService:GenerateGUID(false)}
    if self.ephemeral then profile.mode = "Practice"; return profile end
    local rejected
    local ok, document = self:_request(function()
        return self.adapter:UpdateAsync(profile.key, function(old)
            rejected = nil
            if type(old) == "table" and type(old.data or old) == "table" and type((old.data or old).version) == "number" and (old.data or old).version > Config.SchemaVersion then rejected = "NewerVersion"; return nil end
            local lock = type(old) == "table" and old.lock
            if type(lock) == "table" and lock.token ~= profile.token and type(lock.expires) == "number" and lock.expires > self.clock() then rejected = "Locked"; return nil end
            local raw = type(old) == "table" and (old.data or old) or nil
            return {data = ProfileStore.Sanitize(raw), lock = {token = profile.token, expires = self.clock() + LEASE_SECONDS}}
        end)
    end)
    if ok and document and not rejected and document.lock and document.lock.token == profile.token then
        profile.data = ProfileStore.Sanitize(document.data)
        profile.mode = "Saved"
        profile.leaseUntil = document.lock.expires
    else profile.reason = rejected or "LoadFailed" end
    return profile
end
function ProfileStore:CanMutate(profile)
    if not profile or profile.closing then return false end
    if profile.mode == "Practice" then return true end
    if profile.mode ~= "Saved" then return false end
    if self.clock() >= profile.leaseUntil then profile.mode = "Unavailable"; profile.reason = "LeaseExpired"; return false end
    return true
end
function ProfileStore:MarkChanged(profile)
    profile.revision += 1
    profile.dirty = true
end
function ProfileStore:Save(profile, release)
    if profile.mode == "Practice" then profile.dirty = false; return true end
    if profile.mode ~= "Saved" or profile.saving then return false end
    if self.clock() >= profile.leaseUntil then profile.mode = "Unavailable"; profile.reason = "LeaseExpired"; return false end
    profile.saving = true
    local revision, snapshot = profile.revision, clone(profile.data)
    local lostLock = false
    local ok, document = self:_request(function()
        return self.adapter:UpdateAsync(profile.key, function(old)
            if type(old) ~= "table" or type(old.lock) ~= "table" or old.lock.token ~= profile.token then lostLock = true; return nil end
            return {data = snapshot, lock = not release and {token = profile.token, expires = self.clock() + LEASE_SECONDS} or nil}
        end)
    end)
    profile.saving = false
    if lostLock then profile.mode = "Unavailable"; profile.reason = "LostLock"; return false end
    if ok and document then
        profile.reason = nil
        profile.dirty = profile.revision ~= revision
        if release then profile.mode = "Released" else profile.leaseUntil = document.lock.expires end
        return true
    end
    profile.reason = "SaveFailed"
    return false
end
function ProfileStore:Release(profile)
    profile.closing = true
    -- Keep the final save queued behind any older snapshot, including during slow requests.
    -- The outer shutdown budget limits server shutdown; a player leave must not abandon dirty state.
    while profile.saving do self.wait(0.05) end
    return self:Save(profile, true)
end
return ProfileStore
