-- Native CameraModule is the sole camera transform writer. Configure only subject/mode/zoom.
local Native={}
function Native.new(player,runService)
    local api={seeded=false,camera=nil}
    player.CameraMode=Enum.CameraMode.Classic
    player.CameraMinZoomDistance=8;player.CameraMaxZoomDistance=28
    function api:Subject(camera,humanoid)
        if not camera or not humanoid then return end
        player.CameraMode=Enum.CameraMode.Classic
        camera.CameraType=Enum.CameraType.Custom
        camera.CameraSubject=humanoid
        if self.camera~=camera then camera.FieldOfView=70;self.camera=camera end
        if not self.seeded then
            self.seeded=true
            -- Let native CameraModule select the initial distance, then restore normal scrolling/pinch zoom.
            player.CameraMinZoomDistance=16;player.CameraMaxZoomDistance=16
            task.spawn(function()
                runService.RenderStepped:Wait();runService.RenderStepped:Wait()
                player.CameraMinZoomDistance=8;player.CameraMaxZoomDistance=28
            end)
        end
    end
    return api
end
return Native
