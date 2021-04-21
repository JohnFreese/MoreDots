function(event, spellId, destGuid, snapTable)
    --only care about events for the current target
    if spellId == aura_env.spellId and destGuid == UnitGUID("target") then 
        if event == "MOREDOTS_DOT_REMOVED" 
        or event == "MOREDOTS_DOT_APPLIED" 
        or event == "MOREDOTS_DOT_REFRESHED" then
            if snapTable and snapTable[965900] then
                aura_env.changeNumberOfTicks(12)
            else
                aura_env.changeNumberOfTicks(8)
            end
            
            aura_env.updateSnapshots(destGuid, snapTable)
        end
    end
    
    return true
end