return function()
    local B=require(game.ReplicatedStorage.Nightfall.Shared.CameraBounds)
    local center,span=B.Party({Vector3.new(90,3,0)},0)
    assert(span==0 and center==Vector3.new(90,5,0),"shared party focus")
    assert(B.Visible(Vector3.new(90,3,0),center,span),"center actor admitted")
    assert(not B.Visible(Vector3.new(150,3,0),center,span),"offscreen side rejected")
    assert(not B.Visible(Vector3.new(90,80,0),center,span),"offscreen high actor rejected")
    assert(not B.Visible(Vector3.new(90,3,0),nil,span),"unknown camera fails closed")
    local portrait=B.MinimumAspect
    local distance=B.Distance(span,portrait)
    local frame=B.Frame(center,distance)
    local edge=center+Vector3.new(26,0,0)
    assert(B.InFrame(edge,frame,distance,portrait,0),"actual projection inside-edge fixture")
    assert(not B.Visible(edge,center,span),"conservative margin intentionally rejects inside-edge fixture")
    assert(not B.InFrame(center+Vector3.new(60,0,0),frame,distance,portrait,0),"actual projection outside fixture")
    local near=B.Party({Vector3.new(4,3,0)},0)
    assert(near.X==38,"stage start camera clamp")
    return "PASS: shared projection, center/side/high/unknown, conservative inside-edge rejection, true outside, stage clamp; actual viewport audit remains separate"
end
