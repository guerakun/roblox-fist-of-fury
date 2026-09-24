--!strict
-- Reviewed Toolbox sound references. Permission/load success must still be checked in the live experience.
-- Audio is presentation only; one short-lived envelope ticker handles transitions and then disconnects.
local SoundService = game:GetService("SoundService")
local RunService = game:GetService("RunService")
local Audio = {}
local AMBIENCE = {
    {name = "CityNight", id = "9112759731", volume = .12},
    {name = "AbandonedStation", id = "9112772977", volume = .11},
    {name = "FactoryConveyors", id = "9112890492", volume = .10},
}
function Audio.new(preferences: any): any
    local folder = Instance.new("Folder")
    folder.Name = "NightfallStageAudio"
    folder.Parent = SoundService
    local channels: {any} = {}
    local currentStage, currentStatus = 1, "Waiting"
    local connection: RBXScriptConnection? = nil
    local api: any = {}
    local function add(name: string, id: string, volume: number, kind: string, stage: number?)
        local sound = Instance.new("Sound")
        sound.Name, sound.SoundId, sound.Volume, sound.Looped = name, "rbxassetid://" .. id, 0, true
        sound.Parent = folder
        local channel = {sound = sound, base = volume, kind = kind, stage = stage, weight = 0, target = 0, started = false, paused = false}
        table.insert(channels, channel)
        return channel
    end
    for index, spec in ipairs(AMBIENCE) do add(spec.name, spec.id, spec.volume, "Ambience", index) end
    add("BattleActionScore", "1844978927", .09, "Music", nil)
    local function volume(channel: any): number
        return channel.base * channel.weight * math.clamp(preferences.volume or 0, 0, 1)
            * math.clamp(channel.kind == "Music" and (preferences.music or 0) or (preferences.ambience or 0), 0, 1)
    end
    local function apply(channel: any)
        channel.sound.Volume = volume(channel)
        if channel.target > 0 then
            if not channel.started then channel.sound:Play(); channel.started = true; channel.paused = false
            elseif channel.paused then channel.sound:Resume(); channel.paused = false end
        elseif channel.weight <= 0 and channel.started and not channel.paused then channel.sound:Pause(); channel.paused = true end
    end
    local function tick()
        if connection then return end
        connection = RunService.Heartbeat:Connect(function(dt)
            local moving = false
            for _, channel in ipairs(channels) do
                local amount = math.min(dt, .1) / (channel.kind == "Music" and .7 or 1.1)
                if channel.weight < channel.target then channel.weight = math.min(channel.target, channel.weight + amount)
                elseif channel.weight > channel.target then channel.weight = math.max(channel.target, channel.weight - amount) end
                if math.abs(channel.weight - channel.target) > .0001 then moving = true end
                apply(channel)
            end
            if not moving and connection then connection:Disconnect(); connection = nil end
        end)
    end
    local function targets()
        local moving = false
        local masterEnabled = (preferences.volume or 0) > 0
        for _, channel in ipairs(channels) do
            if channel.kind == "Music" then
                channel.target = masterEnabled and (preferences.music or 0) > 0 and currentStatus == "Combat" and 1 or 0
            else channel.target = masterEnabled and (preferences.ambience or 0) > 0 and channel.stage == currentStage and 1 or 0 end
            if math.abs(channel.weight - channel.target) > .0001 then moving = true end
            apply(channel)
        end
        if moving then tick() end
    end
    function api.Update(snapshot: any)
        currentStage = math.clamp(math.floor(tonumber(snapshot.stage) or 1), 1, #AMBIENCE)
        currentStatus = tostring(snapshot.status or "Waiting")
        targets()
    end
    function api.UpdatePreferences()
        targets()
    end
    function api.Destroy()
        if connection then connection:Disconnect(); connection = nil end
        for _, channel in ipairs(channels) do channel.sound:Stop() end
        folder:Destroy()
    end
    return api
end
return Audio