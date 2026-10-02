local ArenaMath=require(script.Parent.ArenaMath)
local CombatMath = {}
function CombatMath.Knockback(percent, attack, weight)
	return math.clamp((attack.Knockback + percent * attack.Growth) / math.max(weight or 1, 0.5), 8, 155)
end
function CombatMath.Direction(value,fallback)return ArenaMath.NormalizeDirection(value,fallback)end
function CombatMath.InBlastZone(position, stage, margin)
	return position.X < stage.MinX - margin or position.X > stage.MaxX + margin or position.Z < (stage.MinZ or -24)-margin or position.Z > (stage.MaxZ or 24)+margin or position.Y < -22 or position.Y > 115
end
return CombatMath
