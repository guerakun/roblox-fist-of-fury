-- Pure earned-reward arithmetic. Callers supply only server-owned results and ledgers.
local Policy = {}
Policy.Ranks = {D = 1, C = 1, B = 1.15, A = 1.30, S = 1.50}
Policy.Tiers = {Normal = 1, Hard = 1.15, Nightmare = 1.30}
Policy.Cap = 100000000
local function integer(n, cap)
    return type(n) == 'number' and n == n and n >= 0 and n <= (cap or Policy.Cap) and n % 1 == 0
end
function Policy.Bonus(base, rank, difficulty, heatPercent)
    if type(base) ~= 'table' or not integer(base.coins) or not integer(base.xp)
        or not Policy.Ranks[rank] or not Policy.Tiers[difficulty]
        or not integer(heatPercent) or heatPercent > 105 then return nil end
    local rankMultiplier, difficultyMultiplier = Policy.Ranks[rank], Policy.Tiers[difficulty]
    local heatMultiplier = 1 + heatPercent / 100
    local multiplier = rankMultiplier * difficultyMultiplier * heatMultiplier
    return {coins = math.floor(base.coins * (multiplier - 1) + 1e-7),
        xp = math.floor(base.xp * (multiplier - 1) + 1e-7),
        rankMultiplier = rankMultiplier, heatMultiplier = heatMultiplier,
        difficultyMultiplier = difficultyMultiplier}
end
function Policy.Grant(data, keys, order, key, coins, xp)
    if type(key) ~= 'string' or #key < 1 or #key > 160 or not integer(coins, Policy.Cap * 4) or not integer(xp, Policy.Cap * 4) then return nil, 'invalid' end
    if keys[key] then return nil, 'duplicate' end
    if not integer(data.coins) or not integer(data.xp) then return nil, 'invalid balance' end
    if #order >= 1024 then return nil, 'capacity' end
    keys[key] = true
    table.insert(order, key)
    local beforeCoins, beforeXP = data.coins, data.xp
    data.coins = math.min(Policy.Cap, beforeCoins + coins)
    data.xp = math.min(Policy.Cap, beforeXP + xp)
    return {coins = data.coins - beforeCoins, xp = data.xp - beforeXP,
        status = (data.coins - beforeCoins < coins or data.xp - beforeXP < xp) and 'capped' or 'paid'}
end
return Policy
