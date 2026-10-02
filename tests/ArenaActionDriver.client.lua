-- Paired with ArenaActions.server.lua; root installs a disabled-by-location template in ServerStorage.
local remote=game.ReplicatedStorage.Nightfall.Remotes.Action
local last=0
while script.Parent do
 local id=workspace:GetAttribute("ArenaActionCase")or 0
 if id>last then last=id;remote:FireServer(workspace:GetAttribute("ArenaActionName"),{direction=workspace:GetAttribute("ArenaActionDirection")})end
 task.wait(.02)
end
