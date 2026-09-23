local CombatMath = {}
function CombatMath.Knockback(percent, attack, weight)
	return math.clamp((attack.Knockback + percent * attack.Growth) / math.max(weight or 1, 0.5), 8, 155)
end
function CombatMath.Direction(value, fallback)
	if type(value) == "number" and value == value and math.abs(value) > 0.1 then
		return value > 0 and 1 or -1
	end
	return fallback or 1
end
function CombatMath.InBlastZone(position, stage, margin)
	return position.X < stage.MinX - margin or position.X > stage.MaxX + margin or position.Y < -22 or position.Y > 115
end
return CombatMath
