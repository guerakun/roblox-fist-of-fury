return function()
 local P=require(game.ServerScriptService.NightfallServer.ProfileStore)
 local document,calls=nil,0
 local adapter={}
 function adapter:UpdateAsync(_,transform)
  calls+=1
  if calls==2 then task.wait(16.2) end
  local value=transform(document)
  if value then document=value end
  return value
 end
 local store=P.new(adapter,{token="slow-save-regression"})
 local p=store:Load(42);p.data.coins=10;store:MarkChanged(p)
 task.spawn(function()assert(store:Save(p,false),"slow autosave")end)
 task.wait(.15)
 p.data.coins=99;store:MarkChanged(p)
 local start=os.clock()
 assert(store:Release(p),"queued final release")
 assert(os.clock()-start>15,"exercise prior 15-second cutoff")
 assert(document.data.coins==99 and document.lock==nil,"final revision saved and lease released")
 return "PASS: release waited behind >15s autosave, saved newest mutation and released lock"
end