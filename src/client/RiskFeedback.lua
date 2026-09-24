-- Accepted risk/reward event feedback. No client hit, cost, score or coin mutation.
local Debris=game:GetService("Debris")
local TweenService=game:GetService("TweenService")
local Feedback={}
function Feedback.new(options)
    local player=options.player local colors=options.colors local clock=options.clock or os.clock
    local lastOrbNotice=-math.huge
    local function model(value)return typeof(value)=="Instance"and value:IsA("Model")and value.Parent~=nil end
    local function flash(target,color,duration)
        if not model(target)then return end
        local prior=target:FindFirstChild("RiskRewardFlash")if prior then prior:Destroy()end
        local highlight=Instance.new("Highlight")highlight.Name="RiskRewardFlash"highlight.Adornee=target
        highlight.DepthMode=Enum.HighlightDepthMode.Occluded highlight.FillColor=color highlight.OutlineColor=color
        highlight.FillTransparency=.8 highlight.OutlineTransparency=.1 highlight.Parent=target
        TweenService:Create(highlight,TweenInfo.new(duration),{FillTransparency=1,OutlineTransparency=1}):Play()
        Debris:AddItem(highlight,duration+.05)
    end
    local api={}
    function api.Emit(event)
        if type(event)~="table"then return nil end
        local kind=event.kind
        if kind=="PerfectBlock"then
            flash(event.targetModel,colors.cyan,.45)
            if event.targetModel==player.Character then return "PERFECT BLOCK / STYLE UP",colors.cyan end
        elseif kind=="Desperation"then
            flash(event.targetModel,colors.orange,.35)
            if event.playerUserId==player.UserId and type(event.cost)=="number"and event.cost==event.cost and event.cost>=0 and event.cost<math.huge then
                return "DESPERATION / +"..tostring(event.cost).."% SELF",colors.orange
            end
        elseif kind=="BountySpawn"then
            local target=event.targetModel
            local root=model(target)and target:FindFirstChild("HumanoidRootPart")
            if root and root:IsA("BasePart")then
                local prior=target:FindFirstChild("BountyTarget")if prior then prior:Destroy()end
                local billboard=Instance.new("BillboardGui")billboard.Name="BountyTarget"billboard.Adornee=root
                billboard.Size=UDim2.fromOffset(132,26)billboard.StudsOffset=Vector3.new(0,4.8,0)
                billboard.AlwaysOnTop=false billboard.MaxDistance=200 billboard.Parent=target
                local label=Instance.new("TextLabel")label.BackgroundTransparency=.15 label.BackgroundColor3=colors.ink
                label.Size=UDim2.fromScale(1,1)label.Text="BOUNTY / RUNNER"label.Font=Enum.Font.GothamBold
                label.TextSize=11 label.TextColor3=colors.orange label.Parent=billboard
                Debris:AddItem(billboard,35)
                flash(target,colors.orange,.4)
            end
            return "BOUNTY / STOP THE RUNNER",colors.orange
        elseif kind=="BountyEscape"then
            if model(event.targetModel)then
                local marker=event.targetModel:FindFirstChild("BountyTarget")if marker then marker:Destroy()end
            end
            return "BOUNTY ESCAPED",colors.muted
        elseif kind=="ScoreOrbClaim"and event.playerUserId==player.UserId and type(event.score)=="number"
            and event.score>0 and event.score<math.huge and clock()-lastOrbNotice>=.4 then
            lastOrbNotice=clock()return "STYLE +"..tostring(math.floor(event.score)),colors.cyan
        end
        return nil
    end
    return api
end
return Feedback
