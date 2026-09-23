-- Adapted from Skyz Hitbox Module v1.0211, Creator Store asset 117986110024473.
-- Original is preserved in vendor/SkyzHitbox.lua. Uses the same spatial-query
-- technique with bounded one-shot queries rather than one Heartbeat per box.
local Hitbox = {}
function Hitbox.Query(cframe, size, exclude)
	local params = OverlapParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = exclude or {}
	params.MaxParts = 128
	return workspace:GetPartBoundsInBox(cframe, size, params)
end
return Hitbox
