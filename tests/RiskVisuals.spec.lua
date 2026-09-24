-- Root-only geometry/invariant fixture; does not establish visual polish or physical pickup claims.
return function()
    local server=game.ServerScriptService.NightfallServer
    local Factory=require(server.EnemyFactory)
    local Visuals=require(server.PickupVisuals)
    local Config=require(game.ReplicatedStorage.Nightfall.Shared.Config)
    local holder=Instance.new("Folder");holder.Name="RiskVisualFixture";holder.Parent=workspace
    local ok,result=xpcall(function()
        local function count(model,class)
            local n=0
            for _,item in ipairs(model:GetDescendants())do if item:IsA(class)then n+=1 end end
            return n
        end
        local husk=Factory.Create("Husk",Config.Enemies.Husk);husk.Parent=holder
        local core={}
        for _,item in ipairs(husk:GetDescendants())do
            if item:IsA("BasePart")and item.CanQuery then
                core[item]={size=item.Size,collide=item.CanCollide,massless=item.Massless}
            end
        end
        local motors=count(husk,"Motor6D")
        local oldCosmetics=husk:GetAttribute("CosmeticPartCount")
        local marked=Factory.MarkBounty(husk);assert(marked)
        assert(Factory.MarkBounty(husk)==marked and #marked:GetChildren()==6,"Bounty marking duplicated geometry")
        assert(husk:GetAttribute("CosmeticPartCount")==oldCosmetics+6 and husk:GetAttribute("BountyVisual"))
        for _,item in ipairs(marked:GetChildren())do
            assert(item:IsA("BasePart")and not item.CanQuery and not item.CanTouch and not item.CanCollide and item.Massless and not item.Anchored)
            local weld=item:FindFirstChildOfClass("WeldConstraint")
            assert(weld and weld.Part1==item and weld.Part0:IsDescendantOf(husk))
        end
        local queried=0
        for _,item in ipairs(husk:GetDescendants())do
            if item:IsA("BasePart")and item.CanQuery then
                queried+=1;local old=assert(core[item],"Added queryable bounty geometry")
                assert(item.Size==old.size and item.CanCollide==old.collide and item.Massless==old.massless)
            end
        end
        assert(queried==7 and count(husk,"Motor6D")==motors and motors==6)
        local other=Factory.Create("Strider",Config.Enemies.Strider);other.Parent=holder
        assert(Factory.MarkBounty(other)==nil and not other:FindFirstChild("BountyVisuals"))
        local position=Vector3.new(90,2,0)
        local orb=Visuals.ScoreOrb(holder,position,"fixture-orb",123)
        assert(orb.PrimaryPart and orb.PrimaryPart.Position==position and orb:GetAttribute("PickupId")=="fixture-orb")
        assert(orb:GetAttribute("ExpiresAt")==123 and count(orb,"BasePart")==9)
        assert(orb.PrimaryPart.StyleLabel.MaxDistance>=200 and not orb.PrimaryPart.StyleLabel.AlwaysOnTop)
        for _,item in ipairs(orb:GetDescendants())do
            if item:IsA("BasePart")then assert(item.Anchored and not item.CanQuery and not item.CanTouch and not item.CanCollide)end
            assert(not item:IsA("LuaSourceContainer")and not item:IsA("MeshPart"),"Unexpected imported or executable content")
        end
        return {passed=true,bountyParts=6,orbParts=9,coreQueryable=queried,motors=motors,idempotent=true,
            sourceOnlyGeometry=true,physicalTouchVerified=false,visualReadabilityVerified=false}
    end,debug.traceback)
    holder:Destroy();assert(ok,result);return result
end
