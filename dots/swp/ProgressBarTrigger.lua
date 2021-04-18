function(event, spellId, destGuid, snapTable, tick)
    --only care about events for the current target
    if spellId == 25368 and destGuid == UnitGUID("target") then 
        if event == "MOREDOTS_DOT_REMOVED" or event == "MOREDOTS_DOT_APPLIED" then
            aura_env.deltas[destGuid] = 0
            aura_env.resetMarkers()
            aura_env.updateSnapshots(destGuid)
            aura_env.resetSMarkers()
            aura_env.startTime = GetTime()
            aura_env.oldWidth = aura_env.globWidth
        elseif event == "MOREDOTS_DOT_REFRESHED" then    
            if MoreDots.dots.refreshDotTickTime ~= nil and MoreDots.dots.refreshDotTickTime[destGuid] ~= nil and MoreDots.dots.refreshDotTickTime[destGuid][spellId] ~= nil then
                local now = GetTime()
                local start = aura_env.startTime
                local previousTickTime = MoreDots.dots.refreshDotTickTime[destGuid][spellId]
                local nextTickTime = MoreDots.dots.refreshDotNextTickTime[destGuid][spellId]
                local delta = now - previousTickTime
                local tickDuration = nextTickTime - previousTickTime
                local decimalCompletion = delta/tickDuration
                
                local name, rank, icon, count, debuffType, duration, expirationTime, unitCaster, isStealable, shouldConsolidate, spellId 
                = UnitDebuff("target", "Shadow Word: Pain", "Rank 10")
                
                local baseWidth = aura_env.globWidth
                --working as ascended this is the duration the dot SHOULD have
                local actualDuration = math.floor(MoreDots.haste.calculateNewDuration(spellId) * 1000) / 1000
                local snappedDuration = duration
                local newWidth = (actualDuration/snappedDuration) * baseWidth
                
                print("old width: ", aura_env.oldWidth)
                print("start: ", start)
                print("now: ", now)
                print("nextTickTime: ", nextTickTime)
                print("decimal completion: ", decimalCompletion)
                print("actual duration: ", actualDuration)
                print("snapped duration: ", snappedDuration)
                print("haste: ", MoreDots.playerHaste)
                local pos0 = (1 - ((previousTickTime - start)/snappedDuration)) * aura_env.oldWidth
                local pos1 = (1 - ((now - start)/snappedDuration)) * aura_env.oldWidth
                local pos2 = (1 - ((nextTickTime - start)/snappedDuration)) * aura_env.oldWidth
                print("offset: ", pos1 - pos2)
                local oldTickWidth = aura_env.oldWidth/6
                local newTickWidth = newWidth/6
                --local refreshOffset = (pos2 - pos1) - (pos2 - pos0)
                local refreshOffset = newTickWidth - (1 - decimalCompletion) * oldWidth
                local moveAmount = refreshOffset - (newWidth - baseWidth)
                
                aura_env.deltas[destGuid] = moveAmount
                aura_env.moveMarkers(moveAmount, newWidth)
                --MoreDots.snapshot.updateTickTimer(spellId, destGuid)
                aura_env.updateSnapshots(destGuid)
                aura_env.resetSMarkers()
                aura_env.startTime = GetTime()
                aura_env.oldWidth = newWidth
            end
        elseif event == "MOREDOTS_DOT_TICKED" then
            local name, rank, icon, count, debuffType, duration, expirationTime, unitCaster, isStealable, shouldConsolidate, spellId 
            = UnitDebuff("target", "Shadow Word: Pain", "Rank 10")
            
            local ratio = (tick - aura_env.startTime)/duration
            local pos = (1 - ratio) * aura_env.globWidth
            print("actual: ", pos)
            aura_env.moveSMarker(pos)
        end
    end
    
    return true
end