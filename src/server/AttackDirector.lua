-- WO-2.1 preserves the original global windup budget, including its clock sampling.
local Director = {}
function Director.CountActive(enemies, now)
    local count = 0
    for _, data in pairs(enemies) do if data.attacking and now() < data.resolveAt then count += 1 end end
    return count
end
function Director.Cap(aliveCount)
    return math.min(3, math.max(2, aliveCount))
end
return Director
