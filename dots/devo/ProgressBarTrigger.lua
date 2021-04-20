function(event, spellId, destGuid, snapTable)
    --only care about events for the current target
    if spellId == aura_env.spellId and destGuid == UnitGUID("target") then 
        if event == "MOREDOTS_DOT_REMOVED" 
        or event == "MOREDOTS_DOT_APPLIED" MOREDOTS_DOT_REMOVED 
        or event == "MOREDOTS_DOT_REFRESHED" then
            if snapTable["Shadow Visions"] then
                aura_env.changeNumberOfTicks(12)
            else
                aura_env.changeNumberOfTicks(8)
            end

            MoreDots.bars.updateSnapshots(aura_env.spellId, destGuid, aura_env.snapshots, aura_env.globHeight, aura_env.this)
        end
    end
    
    return true
end