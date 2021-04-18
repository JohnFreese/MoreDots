function(event, spellId, destGuid, snapTable, tick)
    --only care about events for the current target
    if spellId == 34917 and destGuid == UnitGUID("target") then 
        if event == "MOREDOTS_DOT_REMOVED" or event == "MOREDOTS_DOT_APPLIED" then
            aura_env.deltas[destGuid] = 0
            aura_env.updateSnapshots(destGuid)
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
                = UnitDebuff("target", "Vampiric Touch", "Rank 3")
                
                local baseWidth = aura_env.globWidth
                --working as ascended this is the duration the dot SHOULD have
                local actualDuration = math.floor(MoreDots.haste.calculateNewDuration(spellId) * 1000) / 1000
                local snappedDuration = duration
                local newWidth = (actualDuration/snappedDuration) * baseWidth
                
                local pos0 = (1 - ((previousTickTime - start)/snappedDuration)) * aura_env.oldWidth
                local pos1 = (1 - ((now - start)/snappedDuration)) * aura_env.oldWidth
                local pos2 = (1 - ((nextTickTime - start)/snappedDuration)) * aura_env.oldWidth
                print("offset: ", pos1 - pos2)
                local oldTickWidth = aura_env.oldWidth/5
                local newTickWidth = newWidth/5
                --local refreshOffset = (pos2 - pos1) - (pos2 - pos0)
                local refreshOffset = newTickWidth - (1 - decimalCompletion) * oldWidth
                local moveAmount = refreshOffset - (newWidth - baseWidth)
                
                aura_env.deltas[destGuid] = moveAmount
                --MoreDots.snapshot.updateTickTimer(spellId, destGuid)
                aura_env.updateSnapshots(destGuid)
                aura_env.startTime = GetTime()
                aura_env.oldWidth = newWidth
            end
        end
    end
    
    return true
end

