function(event, spellId, destGuid, snapTable, tick)
    --only care about events for the current target
    if spellId == aura_env.spellId and destGuid == UnitGUID("target") then 
        if event == "MOREDOTS_DOT_REMOVED" 
        or event == "MOREDOTS_DOT_APPLIED" MOREDOTS_DOT_REMOVED 
        or event == "MOREDOTS_DOT_REFRESHED" then
            MoreDots.bars.updateSnapshots(aura_env.spellId, destGuid, aura_env.snapshots, aura_env.globHeight, aura_env.this)
        end
    end
    
    return true
end