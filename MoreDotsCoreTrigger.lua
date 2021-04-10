-- MoreDots trigger 1
-- COMBAT_LOG_EVENT_UNFILTERED, PLAYER_REGEN_ENABLED, PLAYER_REGEN_DISABLED, PLAYER_ENTERING_WORLD, ACTIVE_TALENT_GROUP_CHANGED
-- Events related to snapshot tracking

function(event, ...)
    if not MoreDots then
        return false
    end
    
    if event == "PLAYER_ENTERING_WORLD" then
        MoreDots.snapshot.resetSnapshots()
        return
    elseif event == "PLAYER_REGEN_ENABLED" then
        -- left combat, so start a timer to reset snapshot data
        MoreDots.snapshot.startCleanUpTimer()
        return
    elseif event == "PLAYER_REGEN_DISABLED" then
        -- entered combat, so cancel any scheduled reset
        MoreDots.snapshot.cancelCleanUpTimer()
        return
    end
    
    local timestamp, type, sourceGUID, sourceName, sourceFlags, destGUID, destName, destFlags, spellId, spellName, spellSchool, spellType = select(1, ...)
    
    -- only worry about events where player is the source
    -- this includes dispel/expiration of player's bleeds, as one of the events
    -- triggered would be a SPELL_AURA_REMOVED where the source is player.
    if sourceGUID ~= MoreDots.playerGuid then
        return
    end
    
    print("type: ", type)
    print("spell id: ", spellId)
    print("spell name: ", spellName)
    
    -- reject event if not dealing with relevant stuff
    if not MoreDots.snapshot.relevantEvents[type] then
        return
    end
    if not MoreDots.auras.allAuras[spellId] and not MoreDots.dots.allDots[spellId] then
        return
    end
    
    -- buff changes on player that affect snapshots
    if destGUID == MoreDots.playerGuid then
        if type == "SPELL_AURA_APPLIED" and MoreDots.auras.allAuras[spellId] then
            --print("aura applied: "..spellId);
            MoreDots.auras.onBuffApplied(spellId)
            return
        elseif type == "SPELL_AURA_REMOVED" and MoreDots.auras.allAuras[spellId] then
            MoreDots.auras.onBuffRemoved(spellId)
            return
        end
    end
    
    -- record snapshot for target when DoT is applied
    if type == "SPELL_AURA_APPLIED" and MoreDots.dots.allDots[spellId] then
        print("APPLYING SNAPSHOT")
        MoreDots.snapshot.onDotApplied(spellId, destGUID)
        print("SNAP TABLE")
        for k,v in pairs(MoreDots.snapshot.state[spellName][destGUID]) do
            print("TABLE: ", k, v)
        end
        return
    end
    
    if type == "SPELL_AURA_APPLIED" and MoreDots.auras.refreshAuras[spellId] then
        print("REFRESHING SNAPSHOT")
        MoreDots.snapshot.onDotRefreshed(spellId, destGuid)
        return
    end
    
    -- clear snapshot for target when DoT expires or is removed
    if type == "SPELL_AURA_REMOVED" and MoreDots.dots.allDots[spellId] then
        print("REMOVING SNAPSHOT")
        MoreDots.snapshot.onDotRemoved(spellId, destGUID)
        return
    end
    
    if type == "SPELL_AURA_REFRESH" and MoreDots.dots.allDots[spellId] then
        print("REFRESHING SNAPSHOT")
        MoreDots.snapshot.onDotRefreshed(spellId, destGUID)
        return
    end
    
    if type == "SPELL_DAMAGE" and MoreDots.spells.refreshSpells[spellId] then
        print("REFRESHING SNAPSHOT")
        MoreDots.snapshot.onDotRefreshed(spellId, destGuid)
        return
    end
end

