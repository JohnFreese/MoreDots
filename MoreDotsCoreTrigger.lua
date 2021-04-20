-- MoreDots trigger 1
-- COMBAT_LOG_EVENT_UNFILTERED, PLAYER_REGEN_ENABLED, PLAYER_REGEN_DISABLED, PLAYER_ENTERING_WORLD
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
    
    local timestamp, type, sourceGuid, sourceName, sourceFlags, destGuid, destName, destFlags, spellId, spellName, spellSchool, spellType = select(1, ...)

    -- reject event if not dealing with relevant stuff
    if not MoreDots.snapshot.relevantEvents[type] then
        return
    end

    if not MoreDots.auras.allAuras[spellId] and not MoreDots.dots.allDots[spellId] then
        return
    end
    
    -- need to only worry about a few auras that are not sourced from the player
    if sourceGuid ~= MoreDots.playerGuid then
        -- we don't have anything to do with this event... carry on
        if destGuid ~= MoreDots.playerGuid then
            return
        end

        if (type == "SPELL_AURA_APPLIED" or type == "SPELL_AURA_REFRESH") and MoreDots.auras.allAuras[spellId] then
            --print("aura applied: "..spellId);
            MoreDots.auras.onBuffApplied(spellId)
            return
        elseif type == "SPELL_AURA_REMOVED" and MoreDots.auras.allAuras[spellId] then
            MoreDots.auras.onBuffRemoved(spellId)
            return
        end
    end
    
    --print("type: ", type)
    --print("spell id: ", spellId)
    --print("spell name: ", spellName)
    
    -- buff changes on player that affect snapshots
    if destGuid == MoreDots.playerGuid then
        if (type == "SPELL_AURA_APPLIED" or type == "SPELL_AURA_REFRESH") and MoreDots.auras.allAuras[spellId] then
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
        MoreDots.snapshot.onDotApplied(spellId, destGuid)
        return
    end
    
    -- clear snapshot for target when DoT expires or is removed
    if type == "SPELL_AURA_REMOVED" and MoreDots.dots.allDots[spellId] then
        print("REMOVING SNAPSHOT")
        MoreDots.snapshot.onDotRemoved(spellId, destGuid)
        return
    end
    
    -- change snapshot table for dots when they are refreshed
    if type == "SPELL_AURA_REFRESH" and MoreDots.dots.allDots[spellId] then
        print("REFRESHING SNAPSHOT")
        MoreDots.snapshot.onDotRefreshed(spellId, destGuid)
        return
    end
    
    --tracking to see if corruption and swp were cast and if they were if they missed or were re-applied
    if type == "SPELL_CAST_SUCCESS" and MoreDots.dots.refreshDots[spellId] then
        MoreDots.snapshot.updateRefreshCast(spellId, destGuid, true)
        return
    end
    
    if type == "SPELL_MISSED" and MoreDots.dots.refreshDots[spellId] then
        MoreDots.snapshot.updateRefreshCast(spellId, destGuid, false)
        return
    end
    
    if type == "SPELL_PERIODIC_DAMAGE" and MoreDots.dots.refreshDots[spellId] then
        MoreDots.snapshot.updateTickTimer(spellId, destGuid)
        return
    end
end