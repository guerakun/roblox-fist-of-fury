-- Actual local widgets/layout and receipt revision fixture. No hardware or reward-grant claim.
return function()
    local player=game.Players.LocalPlayer
    local HUD=require(player.PlayerScripts.NightfallClient.DistrictHUD)
    local gui=Instance.new("ScreenGui")gui.Name="DistrictFixture"gui.Parent=player.PlayerGui
    local frame=Instance.new("Frame")frame.Size=UDim2.fromOffset(650,320)frame.Parent=gui
    local health=Instance.new("Frame")health.Position=UDim2.new(0,16,1,-220)health.Size=UDim2.fromOffset(178,70)health.Parent=frame
    local colors={ink=Color3.fromRGB(12,20,30),panel=Color3.fromRGB(25,35,45),cyan=Color3.fromRGB(60,220,230),text=Color3.new(1,1,1)}
    local hud=HUD.new({player=player,parent=frame,colors=colors,actionName="DistrictFixtureControls",travelAttribute="DistrictFixtureTravel"})
    local menu,settings=player:GetAttribute("MenuOpen"),player:GetAttribute("SettingsOpen")
    player:SetAttribute("MenuOpen",false)player:SetAttribute("SettingsOpen",false)
    local ok,result=xpcall(function()
        local state={status="Advance",style={score=1300,multiplier=3,progress=.65},
            districtResult={id="fixture:1",campaignId="fixture",stage=1,rank="A",score=1300,duration=95,parTime=120,damageTaken=30,difficulty="Hard"},
            districtReceipt={resultId="fixture:1",revision=1,status="pending",baseCoins=999,baseXP=999,basePaidCoins=120,basePaidXP=80,
                coins=0,xp=0,rankMultiplier=false,heatMultiplier=false,difficultyMultiplier=false}}
        hud.Update(state)
        for _,size in ipairs({Vector2.new(320,320),Vector2.new(360,640),Vector2.new(650,320),Vector2.new(1280,720)})do
            frame.Size=UDim2.fromOffset(size.X,size.Y)
            for _,reserve in ipairs({false,true})do
                player:SetAttribute("DistrictFixtureTravel",reserve)
                hud.Render(size.X,size.Y,true,health)
                game:GetService("RunService").RenderStepped:Wait()
                local top=hud.card.AbsolutePosition-frame.AbsolutePosition
                assert(top.X>=0 and top.Y>=0 and top.X+hud.card.AbsoluteSize.X<=size.X+.1)
                assert(top.Y+hud.card.AbsoluteSize.Y<=size.Y-(reserve and 96 or 0)+.1,"Rank card covers reserved return area")
                assert(hud.card.CloseRank.AbsoluteSize.Y>=44 and hud.card.CloseRank.AbsoluteSize.X>=44)
                assert(hud.card.RankDetails.AbsoluteSize.Y>0 and hud.labels.Factors.TextWrapped)
            end
        end
        assert(hud.model.reveals==1 and hud.labels.Payment.Text=="REWARDS PENDING")
        assert(string.find(hud.labels.Base.Text,"120 COINS + 80 XP",1,true))
        state.districtReceipt={resultId="fixture:1",revision=2,status="paid",basePaidCoins=120,basePaidXP=80,coins=39,xp=26,
            rankMultiplier=1.3,heatMultiplier=1,difficultyMultiplier=1.15}
        hud.Update(state)assert(hud.model.reveals==1 and string.find(hud.labels.Bonus.Text,"39 COINS + 26 XP",1,true))
        hud.SetOpen(false)hud.Render(1280,720,false,health)assert(hud.toggle.Visible and not hud.shade.Visible)
        hud.Update(state)hud.Render(1280,720,false,health)assert(not hud.shade.Visible,"Receipt refresh must not reopen dismissed panel")
        player:SetAttribute("SettingsOpen",true)hud.Render(1280,720,false,health)assert(not hud.toggle.Visible)
        player:SetAttribute("SettingsOpen",false)
        state.status="Combat"hud.Update(state)hud.Render(1280,720,false,health)
        assert(not hud.shade.Visible and not hud.toggle.Visible and hud.style.Visible,"Rank panel must not cover combat")
        assert(math.abs(hud.style.StyleProgress.Size.X.Scale-.65)<.0001)
        state.districtResult=false state.districtReceipt=false hud.Update(state)
        assert(hud.model.result==nil and hud.model.receipt==nil)
        return {passed=true,viewports=4,returnReserveCases=2,minimumCloseTarget=44,receiptRefreshWithoutReveal=true,
            rankHiddenDuringCombat=true,actualPaymentLabels=true,physicalInputVerified=false}
    end,debug.traceback)
    hud.Destroy()gui:Destroy()player:SetAttribute("MenuOpen",menu)player:SetAttribute("SettingsOpen",settings)player:SetAttribute("DistrictFixtureTravel",nil)
    assert(ok,result)return result
end
