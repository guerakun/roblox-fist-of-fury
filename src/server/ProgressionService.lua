local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DataStoreService = game:GetService("DataStoreService")
local MarketplaceService = game:GetService("MarketplaceService")
local RunService = game:GetService("RunService")
local Config = require(ReplicatedStorage.Nightfall.Shared.ProgressionConfig)
local ProfileStore = require(script.Parent.ProfileStore)
local Analytics = require(script.Parent.LaunchAnalytics)
local Heat = require(ReplicatedStorage.Nightfall.Shared.HeatConfig)
local RewardPolicy = require(script.Parent.RewardPolicy)
local DistrictLedger = require(script.Parent.DistrictLedger)
local RewardBook = require(script.Parent.CampaignRewardBook).new(DistrictLedger, RewardPolicy)
local AchievementConfig=require(ReplicatedStorage.Nightfall.Shared.AchievementConfig)
local AchievementPolicy=require(script.Parent.AchievementPolicy)
local achievementService=require(script.Parent.AchievementService).new({
    Has=function(userId,badgeId)
        assert(not RunService:IsStudio(),'External badges are disabled in Studio')
        return game:GetService('BadgeService'):UserHasBadgeAsync(userId,badgeId)
    end,
    Award=function(userId,badgeId)
        assert(not RunService:IsStudio(),'External badges are disabled in Studio')
        return game:GetService('BadgeService'):AwardBadgeAsync(userId,badgeId)
    end,
},AchievementConfig.Badges)
local rewardObserver
local flushPending
local campaignSessions = {}
local currentCampaign
local Progression = {}
local records = {}
local inFlightLifecycle = 0
local store, remote
local initialized, shuttingDown = false, false
local runStatus, stageIndex = "Waiting", 1
local SAFE_STATES = {Waiting = true, Intermission = true, Advance = true, Traverse = true, Defeat = true, Victory = true}
local PURCHASE_STATES = {Waiting = true, Defeat = true, Victory = true}
local function notice(player, message)
    if remote and player.Parent then remote:FireClient(player, {kind = "Notice", message = message}) end
end
local function applyAppearance(player)
    local record = records[player]
    local model = player.Character
    if not record or not record.profile or not model then return end
    local data = record.profile.data
    local root = model:FindFirstChild("HumanoidRootPart")
    local head = model:FindFirstChild("Head")
    if not root or not head then return end
    for _, object in ipairs(model:GetDescendants()) do
        if object.Name == "EarnedCosmeticTrail" or object.Name == "CosmeticTop" or object.Name == "CosmeticBottom" or object.Name == "EarnedTitle" then object:Destroy() end
    end
    local cosmetic = Config.FindCosmetic(data.trail)
    if cosmetic and cosmetic.Id ~= "None" and data.owned[cosmetic.Id] then
        local top = Instance.new("Attachment"); top.Name = "CosmeticTop"; top.Position = Vector3.new(0,.8,.45); top.Parent = root
        local bottom = Instance.new("Attachment"); bottom.Name = "CosmeticBottom"; bottom.Position = Vector3.new(0,-.7,.45); bottom.Parent = root
        local trail = Instance.new("Trail")
        trail.Name = "EarnedCosmeticTrail"; trail.Attachment0 = top; trail.Attachment1 = bottom
        trail.Color = ColorSequence.new(cosmetic.Color); trail.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0,.55),NumberSequenceKeypoint.new(1,1)})
        trail.Lifetime = .22; trail.MinLength = .2; trail.LightEmission = .4; trail.FaceCamera = true
        trail.Parent = root
    end
    local title = Config.FindCosmetic(data.title)
    if title and title.Kind == "Title" and data.owned[title.Id] then
        local gui = Instance.new("BillboardGui"); gui.Name = "EarnedTitle"; gui.Size = UDim2.fromOffset(170,22)
        gui.StudsOffset = Vector3.new(0,2.2,0); gui.MaxDistance = 70; gui.AlwaysOnTop = false; gui.Parent = head
        local label = Instance.new("TextLabel"); label.Size = UDim2.fromScale(1,1); label.BackgroundTransparency = 1
        label.Text = title.Name; label.Font = Enum.Font.GothamBold; label.TextSize = 10; label.TextColor3 = title.Color
        label.TextStrokeTransparency = .35; label.Parent = gui
    end
end
function Progression.GetSnapshot(player)
    local record = records[player]
    local profile = record and record.profile
    if not profile then
        return {kind = "Snapshot", loading = true, status = "Loading", coins = 0, xp = 0, owned = {}, claimed = {}, premiumClaimed = {},
            canEquipBoon = SAFE_STATES[runStatus] == true, purchaseAllowed = PURCHASE_STATES[runStatus] == true,
            salesEnabled = false, passId = Config.ChapterPassId, stage = stageIndex}
    end
    local data = profile.data
    return {kind = "Snapshot", loading = false, status = profile.mode, saveWarning = profile.reason,
        coins = data.coins, xp = data.xp, clears = data.clears, completedTiers=data.completedTiers, achievements=data.achievements, owned = data.owned, claimed = data.claimed,
        premiumClaimed = data.premiumClaimed, trail = data.trail, title = data.title, boon = data.boon,
        premium = record.premium == true, passId = Config.ChapterPassId, salesEnabled = Config.SalesEnabled and Config.ChapterPassId > 0 and profile.mode == "Saved",
        canEquipBoon = SAFE_STATES[runStatus] == true, purchaseAllowed = PURCHASE_STATES[runStatus] == true, stage = stageIndex}
end
local function publish(player)
    if remote and player.Parent then remote:FireClient(player, Progression.GetSnapshot(player)) end
end
local function changed(player)
    local record = records[player]
    store:MarkChanged(record.profile)
    publish(player)
end
function Progression.GetCombatModifiers(player)
    local defaults = {damageMultiplier = 1, knockbackMultiplier = 1, moveSpeedBonus = 0, damageReduction = 0}
    local record = records[player]
    local profile = record and record.profile
    if not profile then return defaults end
    local boon = Config.FindBoon(profile.data.boon)
    if not boon or profile.data.xp < boon.XP then return defaults end
    defaults.damageMultiplier = boon.DamageMultiplier or 1
    defaults.moveSpeedBonus = boon.MoveSpeedBonus or 0
    defaults.damageReduction = boon.DamageReduction or 0
    return defaults
end
function Progression.SetRunState(status, stage)
    if type(status) ~= "string" then return end
    local wasSafe = SAFE_STATES[runStatus] == true
    local wasPurchasable, previousStage = PURCHASE_STATES[runStatus] == true, stageIndex
    runStatus, stageIndex = status, stage or stageIndex
    if status=="Waiting"then currentCampaign=nil end
    if wasSafe ~= (SAFE_STATES[status] == true) or wasPurchasable ~= (PURCHASE_STATES[status] == true) or previousStage ~= stageIndex then
        for player in pairs(records) do publish(player) end
    end
end
local function ledgerFor(player, campaign)
    if campaign ~= currentCampaign or campaignSessions[player] ~= campaign or not records[player] then return nil end
    return RewardBook:Get(player.UserId, campaign)
end
local function paymentState(record)
    if not record or not record.profile then return 'pending' end
    if not store:CanMutate(record.profile) then return 'readOnly' end
    return nil
end
local function paid(player, receipt, label)
    changed(player)
    local data = records[player].profile.data
    Analytics.Economy(player, receipt.paymentKey, 'Source', receipt.paymentCoins, data.coins, label)
    if rewardObserver then
        local ok, err = pcall(rewardObserver, player, receipt.paymentCoins)
        if not ok then warn('[Progression] Reward observer: '..tostring(err)) end
    end
    if receipt.paymentCoins > 0 or receipt.paymentXP > 0 then
        notice(player, '+'..receipt.paymentCoins..' coins / +'..receipt.paymentXP..' chapter XP')
    end
end
local function grantReward(player, kind, rewardKey)
    local record, reward = records[player], Config.Rewards[kind]
    if not record or not reward or type(rewardKey) ~= 'string' or #rewardKey > 160 then return end
    local campaign, stageText, waveText = rewardKey:match('^(.*):(%d+):(%d+)$')
    local ledger = ledgerFor(player, campaign)
    if not ledger then return end -- A stale delayed callback cannot reopen an old run.
    local stage, wave = tonumber(stageText), tonumber(waveText)
    if not ledger:Record(stage, wave, reward.Coins, reward.XP) then return end
    ledger.kinds = ledger.kinds or {}
    ledger.kinds[stage..':'..wave] = kind
    if paymentState(record) then return nil,false,true end
    local receipt, newlyPaid = ledger:PayEncounter(record.profile.data, stage, wave)
    if newlyPaid then
        if kind == 'Boss' then record.profile.data.clears += 1 end
        paid(player, receipt, 'Encounter_'..kind)
    end
    return receipt, newlyPaid, true
end
function Progression.SetRewardObserver(callback)
    assert(callback==nil or type(callback)=='function')
    rewardObserver=callback
end
function Progression.BeginCampaign(players,campaignId)
    if not RewardBook:Begin(campaignId) then return false end
    currentCampaign=campaignId
    for _,player in ipairs(players) do
        campaignSessions[player]=campaignId
        Analytics.CampaignStart(player,campaignId)
    end
    return true
end
function Progression.AwardEncounterClear(participants, stage, kind, rewardKey)
    if type(participants) ~= 'table' then return end
    for _,player in ipairs(participants) do
        if typeof(player)=='Instance' and player:IsA('Player') then
            local campaign=type(rewardKey)=='string' and rewardKey:match('^(.*):%d+:%d+$')
            local _,_,accepted=grantReward(player,kind,rewardKey)
            if kind=='Boss' and accepted and currentCampaign==campaign and campaignSessions[player]==campaign then
                Analytics.District(player,campaign,stage)
            end
        end
    end
end
local function earnedAchievements(player,ledger,result)
    local record=records[player]
    if ledgerFor(player,result.campaignId)~=ledger or paymentState(record) then return end
    local data=record.profile.data
    local full=ledger:FullParticipation()
    for _,item in pairs(ledger.stages) do
        if item.result and (item.result.difficulty~=result.difficulty or not Heat.SameSelection(item.result.heat,result.heat)) then full=false end
    end
    local rules=Heat.Rules(result.heat)
    if not rules then return end
    local dirty=false
    data.completedTiers=data.completedTiers or {}
    data.achievements=data.achievements or {}
    if result.stage==3 and full and not data.completedTiers[result.difficulty] then
        data.completedTiers[result.difficulty]=true dirty=true
    end
    for _,key in ipairs(AchievementPolicy.Evaluate(result,rules.points,full))do
        if not data.achievements[key] then data.achievements[key]=true dirty=true end
        if (key=='Heat5' or key=='Heat10' or key=='Heat15') and not data.owned[key] then data.owned[key]=true dirty=true end
        if not RunService:IsStudio() and AchievementConfig.Badges[key].BadgeId>0 then
            task.spawn(function()
                -- A queued task may begin after PlayerRemoving has already cleared its cache.
                if records[player]~=record or player.Parent~=Players then return end
                achievementService:Award(player.UserId,key)
                if records[player]~=record or player.Parent~=Players then achievementService:Forget(player.UserId) end
            end)
        end
    end
    if dirty then changed(player) end
end
function Progression.AwardDistrict(player,result)
    if type(result)~='table' then return false end
    local ledger=ledgerFor(player,result.campaignId)
    local rules=Heat.Rules(result.heat)
    if not ledger or not rules then return false end
    local frozen=ledger:Complete(result,rules.rewardPercent)
    if not frozen then return false end
    local record=records[player]
    local state=paymentState(record)
    if state then return ledger:Receipt(result.stage,state) end
    -- Resolve eligible base payments before the bonus, including delayed profile loads.
    for wave in pairs(ledger.stages[result.stage].waves) do
        grantReward(player,ledger.kinds[result.stage..':'..wave],result.campaignId..':'..result.stage..':'..wave)
    end
    -- Re-fetch the current journal immediately before mutation; no captured old journal pays.
    if ledgerFor(player,result.campaignId)~=ledger then return false end
    record=records[player]
    local currentState=paymentState(record)
    if currentState then return ledger:Receipt(result.stage,currentState) end
    local receipt,newlyPaid=ledger:PayDistrict(record.profile.data,result.stage)
    if newlyPaid then paid(player,receipt,'DistrictRank') end
    earnedAchievements(player,ledger,frozen)
    return ledger:Receipt(result.stage,paymentState(record))
end
function Progression.GetDistrictReceipt(player,resultId)
    if type(resultId)~='string' then return false end
    local campaign,stageText=resultId:match('^(.*):(%d+)$')
    local ledger=ledgerFor(player,campaign)
    local stage=tonumber(stageText)
    if not ledger or not stage or not ledger.stages[stage] or not ledger.stages[stage].result then return false end
    return ledger:Receipt(stage,paymentState(records[player]))
end
flushPending=function(player)
    local campaign=currentCampaign
    local ledger=ledgerFor(player,campaign)
    if not ledger or paymentState(records[player]) then return end
    for stage,item in pairs(ledger.stages) do
        for wave in pairs(item.waves) do
            if ledgerFor(player,campaign)~=ledger then return end
            grantReward(player,ledger.kinds[stage..':'..wave],campaign..':'..stage..':'..wave)
        end
    end
    for _,item in pairs(ledger.stages) do
        if ledgerFor(player,campaign)~=ledger then return end
        if item.result then Progression.AwardDistrict(player,item.result) end
    end
end
function Progression.AwardEnemyDefeat() end -- Encounter participation rewards support play equally.
local function checkPass(player)
    local record = records[player]
    if not record or Config.ChapterPassId <= 0 then return end
    local ok, owns = pcall(MarketplaceService.UserOwnsGamePassAsync, MarketplaceService, player.UserId, Config.ChapterPassId)
    if ok and records[player] == record then record.premium = owns == true; publish(player) end
end
local function action(player, actionName, value)
    local record = records[player]
    if not record or type(actionName) ~= "string" then return end
    local now = os.clock()
    if now - record.rateStart > 1 then record.rateStart, record.rateCount = now, 0 end
    record.rateCount += 1
    if record.rateCount > 8 then return end
    if actionName == "Request" then publish(player); return end
    local profile = record.profile
    if not profile or not store:CanMutate(profile) then notice(player, "Progress is unavailable. Your saved data has not been replaced."); return end
    local data = profile.data
    if actionName == "ClaimTier" then
        if type(value) ~= "number" or value ~= value or value % 1 ~= 0 or value < 1 or value > #Config.Tiers then return end
        if data.xp < value * Config.XPPerTier then notice(player, "Keep clearing encounters to unlock this tier."); return end
        local key, tier = tostring(value), Config.Tiers[value]
        local beforeCoins=data.coins
        local granted = false
        if not data.claimed[key] then
            data.claimed[key] = true
            data.coins = math.min(100000000, data.coins + (tier.Coins or 0))
            if tier.Cosmetic then
                local cosmetic = Config.FindCosmetic(tier.Cosmetic)
                if data.owned[tier.Cosmetic] and cosmetic and cosmetic.Price > 0 then
                    data.coins = math.min(100000000, data.coins + cosmetic.Price) -- Refund an earlier earned-coin unlock.
                end
                data.owned[tier.Cosmetic] = true
            end
            granted = true
        end
        if tier.Premium and record.premium and not data.premiumClaimed[key] then
            data.premiumClaimed[key] = true; data.owned[tier.Premium] = true; granted = true
        end
        if granted then changed(player); Analytics.Economy(player,"Tier:"..key,"Source",data.coins-beforeCoins,data.coins,"ChapterTier"); notice(player, "Tier " .. value .. " rewards claimed.") end
    elseif actionName == "BuyCosmetic" then
        if type(value) ~= "string" then return end
        local cosmetic = Config.FindCosmetic(value)
        if not cosmetic or cosmetic.Premium or cosmetic.TrackOnly or cosmetic.Price <= 0 or data.owned[value] then return end
        if data.coins < cosmetic.Price then notice(player, "Earn " .. (cosmetic.Price-data.coins) .. " more coins from encounters."); return end
        data.coins -= cosmetic.Price; data.owned[value] = true
        changed(player); Analytics.Economy(player,"Cosmetic:"..value,"Sink",cosmetic.Price,data.coins,value); notice(player, cosmetic.Name .. " unlocked. Equip it in your collection.")
    elseif actionName == "EquipCosmetic" then
        if type(value) ~= "string" then return end
        if value == "ClearTitle" then data.title = "None"
        else
            local cosmetic = Config.FindCosmetic(value)
            if not cosmetic or not data.owned[value] then return end
            if cosmetic.Kind == "Trail" then data.trail = value else data.title = value end
        end
        changed(player); applyAppearance(player)
    elseif actionName == "EquipBoon" then
        if type(value) ~= "string" then return end
        if not SAFE_STATES[runStatus] then notice(player, "Change your boon between encounters."); return end
        local boon = Config.FindBoon(value)
        if not boon or data.xp < boon.XP then notice(player, "Earn chapter XP to unlock this boon."); return end
        data.boon = value; changed(player); notice(player, boon.Name .. " equipped. One boon at a time.")
    elseif actionName == "PurchasePass" then
        if not PURCHASE_STATES[runStatus] then notice(player, "Purchase from the lobby or results screen, where there is no encounter countdown."); return end
        if not Config.SalesEnabled or Config.ChapterPassId <= 0 or profile.mode ~= "Saved" then notice(player, "Paid cosmetics are not on sale in this build."); return end
        if record.premium or now < record.promptAt then return end
        record.promptAt = now + 10
        -- A voluntary menu action is the only path to a Roblox purchase prompt.
        local ok = pcall(MarketplaceService.PromptGamePassPurchase, MarketplaceService, player, Config.ChapterPassId)
        if not ok then notice(player, "The Roblox shop is unavailable. Please try later.") end
    end
end
local function addPlayer(player)
    if records[player] or shuttingDown then return end
    local record = {profile = nil, premium = false, rateStart = 0, rateCount = 0, promptAt = 0}
    records[player] = record
    if currentCampaign and runStatus~="Waiting"then campaignSessions[player]=currentCampaign Analytics.CampaignStart(player,currentCampaign)end
    player.CharacterAdded:Connect(function(model)
        task.spawn(function()
            model:WaitForChild("HumanoidRootPart", 10)
            if player.Character == model then applyAppearance(player) end
        end)
    end)
    inFlightLifecycle += 1
    task.spawn(function()
        local ok, err = pcall(function()
            local profile = store:Load(player.UserId)
            for attempt = 1, 3 do
                if profile.reason ~= "Locked" or records[player] ~= record or not player.Parent or shuttingDown then break end
                task.wait(attempt * 2)
                profile = store:Load(player.UserId)
            end
            if records[player] ~= record or not player.Parent or shuttingDown then store:Release(profile); return end
            record.profile = profile
            flushPending(player)
            applyAppearance(player); publish(player)
            task.spawn(checkPass, player)
        end)
        inFlightLifecycle -= 1
        if not ok then warn("[Progression] Profile lifecycle failed: " .. tostring(err)) end
    end)
end
-- Server-only travel lifecycle; no client can release or replace a profile.
function Progression.GetPreferredHero(player)
    local deadline=os.clock()+15
    repeat
        local record=records[player]
        if record and record.profile then return require(ReplicatedStorage.Nightfall.Shared.Config).NormalizeHeroId(record.profile.data.hero)end
        task.wait(.1)
    until player.Parent~=Players or os.clock()>deadline
    return "Gale"
end
function Progression.GetTravelProfile(player)local r=records[player]return r and r.profile end
function Progression.CanMutateTravelProfile(profile)return store:CanMutate(profile)end
function Progression.ReleaseTravelProfile(profile)return store:Release(profile)end
function Progression.ResumeAfterTravelFailure(player)
    local record=records[player]if not record then return false end
    local old=record.profile
    if old and store:CanMutate(old)then flushPending(player)return true end
    if old and old.mode~="Released" then
        if old.mode=="Unavailable" then notice(player,"Save session unavailable. Progress is read-only; rejoin to restore it.")return false end
        if not store:Release(old)then return false end
    end
    local loaded=store:Load(player.UserId)
    if records[player]~=record or player.Parent~=Players or shuttingDown then store:Release(loaded)return false end
    record.profile=loaded;flushPending(player);publish(player)
    return store:CanMutate(loaded)
end
function Progression.Init()
    if initialized then return end
    initialized = true
    local folder = ReplicatedStorage.Nightfall.Remotes
    remote = folder:FindFirstChild("Progression") or Instance.new("RemoteEvent")
    remote.Name = "Progression"; remote.Parent = folder
    local practice = RunService:IsStudio() and not Config.StudioPersistence
    local adapter = not practice and DataStoreService:GetDataStore(Config.DataStoreName) or nil
    store = ProfileStore.new(adapter, {ephemeral = practice})
    remote.OnServerEvent:Connect(action)
    Players.PlayerAdded:Connect(addPlayer)
    Players.PlayerRemoving:Connect(function(player)
        local record = records[player]
        records[player] = nil
        campaignSessions[player]=nil
        achievementService:Forget(player.UserId)
        if record and record.profile then
            inFlightLifecycle += 1
            store:Release(record.profile)
            inFlightLifecycle -= 1
        end
    end)
    MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(player, passId, purchased)
        if passId == Config.ChapterPassId and purchased then task.spawn(checkPass, player) end
    end)
    for _, player in ipairs(Players:GetPlayers()) do addPlayer(player) end
    task.spawn(function()
        while not shuttingDown do
            task.wait(45)
            for player, record in pairs(records) do
                if record.profile and record.profile.mode == "Saved" then
                    task.spawn(function() store:Save(record.profile, false); publish(player) end)
                end
            end
        end
    end)
    game:BindToClose(function()
        shuttingDown = true
        local outstanding = 0
        for _, record in pairs(records) do
            if record.profile then
                outstanding += 1
                task.spawn(function() store:Release(record.profile); outstanding -= 1 end)
            end
        end
        local deadline = os.clock() + 25
        while (outstanding > 0 or inFlightLifecycle > 0) and os.clock() < deadline do task.wait(.1) end
    end)
end
return Progression
