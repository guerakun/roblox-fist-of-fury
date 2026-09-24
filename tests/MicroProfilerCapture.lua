-- Run through Studio MCP/command bar after enabling capture and allowing the scenario to run.
-- Uses the documented LibMP snapshot API; does not expose a production remote.
local LibMP=require('@rbx/LibMP')
LibMP.Control:SetFrameLimit(256)
local session=assert(LibMP.Session.OpenFromBuffer(LibMP.Control:CaptureToBufferSync()),'MicroProfiler snapshot unavailable')
local iterator
local ok,result=xpcall(function()
    local timer=session:FindTimerId('CurtainBreakEnemyAI',true)
    assert(timer~=0,'AI profile annotation absent in captured data')
    local minId,maxId=session:GetFrameIdMin(),session:GetFrameIdMax()
    local firstAbsolute=assert(workspace:GetAttribute('PerfFirstAbsoluteFrame'),'capture-start barrier missing')
    while minId<=maxId and session:FetchFrameDesc(minId).FrameAbsoluteId<firstAbsolute do minId+=1 end
    assert(minId<=maxId,'no frames after populated capture barrier')
    local factor=session:FetchGlobalDesc().TickToMsCpu
    local minFrame,maxFrame=session:FetchFrameDesc(minId),session:FetchFrameDesc(maxId)
    local out={scope='CurtainBreakEnemyAI',measurement='complete inclusive AI-step CPU scope durations from frozen MicroProfiler snapshot',
        firstFrame={id=minId,absoluteId=minFrame.FrameAbsoluteId},lastFrame={id=maxId,absoluteId=maxFrame.FrameAbsoluteId},calls={},totalMs=0,maxMs=0}
    iterator=session:CreateLogIterator()
    iterator:Configure({TimerIds={timer},SkipGpuThreads=true,SkipPausedFrames=true})
    iterator:RewindTo(minId,maxId)
    local state=iterator:GetState()
    while iterator:Step()do
        if state:IsExit()and state:TimerId()==timer and not state:ThreadStackIsUnderflowed()and not state:ThreadStackWasOverflowed()then
            local element=iterator:GetCurrentThreadStackElement(state:ThreadStackDepth())
            if element and element:EnterFrameId()>=minId then
                local ms=(state:Timestamp()-element:EnterTimestamp())*factor
                if ms>=0 then
                    table.insert(out.calls,{frame=state:FrameId(),absoluteFrame=state:FrameAbsoluteId(),enterFrame=element:EnterFrameId(),ms=ms})
                    out.totalMs+=ms out.maxMs=math.max(out.maxMs,ms)
                end
            end
        end
    end
    assert(#out.calls>0,'No complete AI scopes found')
    out.meanMs=out.totalMs/#out.calls out.targetMeanMs=1.5 out.meanTargetPassed=out.meanMs<1.5
    out.population=game.HttpService:JSONDecode(workspace:GetAttribute('PerfPopulation'))
    local checks=workspace:GetAttribute('PerfPopulationChecks')or 0
    local mismatches=workspace:GetAttribute('PerfPopulationMismatchCount')or 0
    local mismatch=workspace:GetAttribute('PerfPopulationFirstMismatch')
    out.populationValidity={firstAbsoluteFrame=workspace:GetAttribute('PerfPopulationBarrier'),checks=checks,mismatches=mismatches,
        firstMismatch=mismatch and game.HttpService:JSONDecode(mismatch)or nil,
        method='Heartbeat plus barrier-change observations; mismatch latched from populated capture barrier'}
    out.populationValidity.valid=checks>0 and mismatches==0 and workspace:GetAttribute('PerfPopulationValid')==true
        and out.populationValidity.firstAbsoluteFrame==firstAbsolute and out.population.alive==4 and out.population.enemies==12
    out.cpuTargetPassed=out.meanTargetPassed and out.populationValidity.valid
    out.passMeaning='cpuTargetPassed requires numerical mean and capture population validity; not an overall launch gate'
    out.limit='Desktop Studio server CPU only; boundary-partial scopes excluded, no GPU/phone/frame-rate certification.'
    return out
end,debug.traceback)
local iteratorDisposed,iteratorError=true,nil
if iterator then iteratorDisposed,iteratorError=pcall(function()iterator:Dispose()end)end
local sessionDisposed,sessionError=pcall(function()session:Dispose()end)
assert(iteratorDisposed,iteratorError)assert(sessionDisposed,sessionError)
assert(ok,result)
return game.HttpService:JSONEncode(result)
