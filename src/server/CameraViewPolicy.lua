-- Camera reports gate eligibility symmetrically; reports never specify combat targets, damage or rewards.
-- Bounded native-camera reports cannot prove what an untrusted client actually rendered.
local Policy={Freshness=.8,Interval=.1}
function Policy.Receive(data,payload,t,subject,life,visibility)
    if t<(data.nextCameraReportAt or -math.huge)then return false,"RateLimited"end
    data.nextCameraReportAt=t+Policy.Interval
    if type(payload)~="table" or not visibility.Validate(payload.frame,payload.fov,payload.aspect,subject)then
        data.cameraView=nil
        return false,"Invalid"
    end
    data.cameraView={frame=payload.frame,fov=payload.fov,aspect=payload.aspect,receivedAt=t,life=life}
    return true
end
function Policy.Read(data,t,subject,life,visibility)
    local view=data and data.cameraView
    if not view or view.life~=life or t<view.receivedAt or t-view.receivedAt>Policy.Freshness then return nil end
    if not visibility.Validate(view.frame,view.fov,view.aspect,subject)then return nil end
    return view
end
return Policy
