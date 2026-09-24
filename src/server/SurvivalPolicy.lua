local Policy={}
function Policy.Reset(mode,stocks,percent,settings,cap)
    cap=cap or settings.MaxStocks
    if mode=="Campaign"then return math.min(cap,settings.StartStocks),0 end
    if mode=="Retry"then return math.min(cap,settings.RetryStocks),0 end
    if mode=="Clear"then return math.min(cap,stocks+1),math.max(0,percent-settings.ClearHeal)end
    assert(mode=="Travel","Unknown survival transition")
    return math.min(cap,stocks),percent
end
function Policy.CanChannel(t,untilTime,distance,moved,hitChanged,alive)
    return alive and t<untilTime and distance<=8 and moved<=1.5 and not hitChanged
end
return Policy
