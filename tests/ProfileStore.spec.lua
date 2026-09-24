-- Memory adapter test: never touches live data.
return function()
 local P=require(game.ServerScriptService.NightfallServer.ProfileStore)
 local documents,current,writes={},1000,0
 local adapter={}
 function adapter:UpdateAsync(key,transform)
  writes+=1;local result=transform(documents[key])
  if result~=nil then documents[key]=result end
  return result
 end
 local a=P.new(adapter,{token="server-A",clock=function()return current end,wait=function()end})
 local b=P.new(adapter,{token="server-B",clock=function()return current end,wait=function()end})
 local p=a:Load(123);assert(p.mode=="Saved","new load")
 p.data.coins=250;a:MarkChanged(p);assert(a:Save(p,false),"save")
 local same=a:Load(123)
 assert(same.mode=="Unavailable" and same.reason=="Locked","same-server rapid reconnect must wait for old release")
 assert(same.token~=p.token,"per-load token")
 local blocked=b:Load(123)
 assert(blocked.mode=="Unavailable" and blocked.reason=="Locked","cross-server lock")
 blocked.data.coins=9999;assert(not b:Save(blocked,false),"failed load never saves")
 assert(documents.player_123.data.coins==250,"data preserved")
 assert(a:Release(p),"release")
 local resumed=b:Load(123)
 assert(resumed.mode=="Saved" and resumed.data.coins==250,"rejoin")
 resumed.data.coins=175;b:MarkChanged(resumed)
 current+=181
 local recovered=a:Load(123);assert(recovered.mode=="Saved","expired lock reclaimed")
 assert(not b:Save(resumed,false),"expired session cannot overwrite")
 assert(documents.player_123.data.coins==250,"stale save rejected")
 documents.player_123.lock={token="server-C",expires=current+180}
 assert(not a:Save(recovered,false) and recovered.reason=="LostLock","lost lock frozen")
 local bad=P.Sanitize({coins=0/0,xp=math.huge,owned={Fake=true,BlueHour=true},claimed={['500']=true,['1']=true},boon="Haste",trail="BlueHour"})
 assert(bad.coins==0 and bad.xp==0 and bad.boon=="Guardian","sanitize numbers and boon")
 assert(not bad.owned.Fake and bad.owned.BlueHour and bad.trail=="BlueHour","cosmetic allowlist")
 assert(bad.claimed['1'] and not bad.claimed['500'],"tier bounds")
 local failing={UpdateAsync=function()error("offline")end}
 assert(P.new(failing,{wait=function()end}):Load(999).mode=="Unavailable","failed load read-only")
 assert(P.new(nil,{ephemeral=true}):Load(-1).mode=="Practice","Studio ephemeral")
 documents.player_456={data={version=999,coins=432}}
 assert(a:Load(456).reason=="NewerVersion" and documents.player_456.data.coins==432,"future schema protected")
 local retry=a:Load(789);retry.reason="SaveFailed"
 assert(a:Save(retry,false) and retry.reason==nil,"successful save clears old warning")
 return "PASS: lock contention, same-server reconnect race, expiry, lost lock, failed-load protection, schema guard, sanitation, save recovery ("..writes.." adapter calls)"
end