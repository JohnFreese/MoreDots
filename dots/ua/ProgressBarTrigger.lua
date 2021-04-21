function(event, spellId, destGuid, snapTable)
    --only care about events for the current target
    if spellId == aura_env.spellId and destGuid == UnitGUID("target") then 
        if event == "MOREDOTS_DOT_REMOVED" 
        or event == "MOREDOTS_DOT_APPLIED"
        or event == "MOREDOTS_DOT_REFRESHED" then
            aura_env.updateSnapshots(destGuid)
        end
    end
    
    return true
end