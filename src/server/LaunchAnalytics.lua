-- Studio never submits analytics. Verify delivery separately in the owner's published test universe.
local Journal=require(script.Parent.AnalyticsJournal)
local studio=game:GetService('RunService'):IsStudio()
local analytics=game:GetService('AnalyticsService')
local journal=Journal.new(function(player,event)
    if studio then return end
    if event.kind=='Funnel'then
        analytics:LogFunnelStepEvent(player,'CurtainBreakCampaign',event.session,event.step,event.name)
    elseif event.kind=='Economy'then
        analytics:LogEconomyEvent(player,Enum.AnalyticsEconomyFlowType[event.flow],'Coins',event.amount,event.balance,
            event.flow=='Source'and 'Gameplay' or 'Shop',event.sku)
    elseif event.kind=='Custom'then analytics:LogCustomEvent(player,event.name,1)end
end)
game.Players.PlayerRemoving:Connect(function(p)journal:Forget(p)end)
return {
    HubJoin=function(p)return journal:Emit(p,'hubjoin',{kind='Custom',name='RefugeJoined'})end,
    TutorialDone=function(p)return journal:Emit(p,'tutorial',{kind='Custom',name='DojoCompleted'})end,
    CampaignStart=function(p,id)return journal:Funnel(p,id,1,'Deployment joined')end,
    District=function(p,id,stage)
        local ok=journal:Funnel(p,id,stage+1,'District '..stage..' cleared')
        if stage==3 then journal:Funnel(p,id,5,'Victory')end return ok
    end,
    Economy=function(p,key,flow,amount,balance,sku)return journal:Economy(p,key,flow,amount,balance,sku)end,
}
