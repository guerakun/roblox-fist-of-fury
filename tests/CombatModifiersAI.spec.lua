return function()
    local M=require(game.ServerScriptService.NightfallServer.CombatModifiers)
    local checks=0;local function check(v,message)assert(v,message);checks+=1 end
    local neutral=M.Normalize(nil)
    check(neutral.canBlock and neutral.canDash and M.Incoming(10,neutral)==10 and M.Weight(nil,neutral)==1)
    local glass=M.Normalize({damageMultiplier=1.2,damageTakenMultiplier=1.2})
    check(glass.damageMultiplier==1.2 and M.Incoming(10,glass)==12)
    local anchor=M.Normalize({weightMultiplier=1.3,canDash=false})
    check(M.Weight(1,anchor)==1.3 and not anchor.canDash and anchor.canBlock)
    local berserk=M.Normalize({canBlock=false,styleGainMultiplier=2})
    check(not berserk.canBlock and berserk.canDash and berserk.styleGainMultiplier==2)
    for _,field in ipairs({"damageMultiplier","knockbackMultiplier","moveSpeedBonus","damageReduction","damageTakenMultiplier","styleGainMultiplier","weightMultiplier"})do
        for _,invalid in ipairs({false,"bad",0/0,math.huge,-math.huge})do
            local bad=M.Normalize({[field]=invalid})
            check(bad[field]==neutral[field],"Invalid modifier did not fall back: "..field)
        end
    end
    local bounded=M.Normalize({damageMultiplier=99,knockbackMultiplier=99,moveSpeedBonus=99,damageReduction=99,damageTakenMultiplier=99,weightMultiplier=99})
    check(bounded.damageMultiplier==1.5 and bounded.knockbackMultiplier==1.5 and bounded.moveSpeedBonus==6)
    check(bounded.damageReduction==.3 and bounded.damageTakenMultiplier==1.5 and bounded.weightMultiplier==1.5)
    check(math.abs(M.Incoming(10,M.Normalize({damageReduction=.2,damageTakenMultiplier=1.2}))-9.6)<.000001,"Incoming composition")
    return {passed=true,checks=checks,neutralFallback=true,bounds=true,tradeoffMath=true}
end
