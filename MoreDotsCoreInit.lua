--[[
    Events that are created by MoreDots
    MOREDOTS_DOT_APPLIED, destGuid, spellId, snap
    MOREDOTS_DOT_REMOVED, destGuid, spellId
]]
MoreDots = {}

setglobal("MoreDots", MoreDots)

MoreDots.playerGuid = UnitGUID("player")

MoreDots.dots = {}

MoreDots.dots.refreshDots = { 
    [25368] = "Shadow Word: Pain",
    [27216] = "Corruption"
}

MoreDots.dots.hasteDots = { 
    [25467] = "Devouring Plague",
    [25368] = "Shadow Word: Pain",
    [34917] = "Vampiric Touch",
    [27216] = "Corruption"
}

MoreDots.dots.critDots = { 
    [25467] = "Devouring Plague",
    [25368] = "Shadow Word: Pain",
    [34917] = "Vampiric Touch",
    [27216] = "Corruption",
    [30405] = "Unstable Affliction"
}

MoreDots.dots.allDots = {}

for k,v in pairs(MoreDots.dots.critDots) do
    MoreDots.dots.allDots[k] = v
end

MoreDots.auras = {}

MoreDots.auras.damageModifiers = { 
    [12042] = "Arcane Power",
    [63848] = "Hunger For Blood"
}

MoreDots.auras.critModifiers = { 
    --[57531] = "Arcane Potency" special case
    [31842] = "Divine Illumination"
}

MoreDots.auras.hasteModifiers = { 
    [00001] = "Bloodlust",
    [10060] = "Power Infusion",
    [64371] = "Eradication",
    [965899] = "Soul Fragment"
}

MoreDots.auras.spellPowerModifiers = {
    [33697] = "Blood Fury"
    -- add trinket auras here too
}

--[[these auras cannot be tracked as easily since they go away after a spellcast. 
There is no guarentee that these auras will be tracked in the active auras list]]
MoreDots.auras.lostOnApply = {
    [57531] = "Arcane Potency"
}

--[[ this will hold the aura id and a time that it "expires". this time is completely 
arbitrary and only represents an estimate of what spell cast received the benefit of
the aura.
eg.
{
   lostOnApplyExpireTime[57531] = <time the aura was removed + some number>
}
]]
MoreDots.auras.lostOnApplyExpireTime = {}

MoreDots.auras.lostOnApplyExpireTimeInterval = 0.5 -- needs testing

MoreDots.auras.allAuras = {}

for k,v in pairs(MoreDots.auras.damageModifiers) do
    MoreDots.auras.allAuras[k] = v
end

for k,v in pairs(MoreDots.auras.critModifiers) do
    MoreDots.auras.allAuras[k] = v
end

for k,v in pairs(MoreDots.auras.hasteModifiers) do
    MoreDots.auras.allAuras[k] = v
end

MoreDots.auras.activeAuras = {} --state for tracking active auras we care about when applying DoTs

MoreDots.snapshot = {}
--[[state will look something like this:
MoreDots.snapshot.state["spell name"][destGuid]
the value for this will be a table of the tracked auras
eg.
{
    ["Arcane Potency"] = true,
    ["Power Infusion"] = false,
    ...
}
]]
MoreDots.snapshot.state = {}

MoreDots.snapshot.relevantEvents = {
    ["SPELL_AURA_APPLIED"] = true,
    ["SPELL_AURA_REFRESH"] = true,
    ["SPELL_AURA_REMOVED"] = true,
}

MoreDots.snapshot.makeSnapshotTable = 
function(spellId)
    local time = GetTime()
    local snapTable = {}
    
    print("Active Auras: ")
    for k,v in pairs(MoreDots.auras.activeAuras) do
        print("AURA TABLE: ", k, v)
    end
    
    for k,v in pairs(MoreDots.auras.damageModifiers) do
        print("Checking if " .. k .. " is active")
        snapTable[v] = MoreDots.snapshot.buffIsActive(k)    
    end
    
    if MoreDots.dots.critDots[spellId] then 
        for k,v in pairs(MoreDots.auras.critModifiers) do
            snapTable[v] = MoreDots.snapshot.buffIsActive(k)
        end
        
        -- arcane potency is a crit modifier the special case will be handled here
    end
    
    if MoreDots.dots.hasteDots[spellId] then 
        for k,v in pairs(MoreDots.auras.hasteModifiers) do
            snapTable[v] = MoreDots.snapshot.buffIsActive(k)
        end    
    end
    
    return snapTable
end

MoreDots.snapshot.onDotApplied = 
function(spellId, destGuid)
    local spellName = MoreDots.dots.allDots[spellId];
    if not spellName then
        return
    end
    
    local snapTable = MoreDots.snapshot.makeSnapshotTable(spellId)
    
    MoreDots.snapshot.state[spellName] = {}
    MoreDots.snapshot.state[spellName][destGuid] = {}
    MoreDots.snapshot.state[spellName][destGuid] = snapTable
    WeakAuras.ScanEvents("MOREDOTS_DOT_APPLIED", spellId, destGuid, snapTable)
end

MoreDots.snapshot.onDotRemoved =
function (spellId, destGuid)
    local spellName = MoreDots.dots.allDots[spellId];
    if not spellName then
        return
    end
    MoreDots.snapshot.state[spellName][destGuid] = {}
    WeakAuras.ScanEvents("MOREDOTS_DOT_REMOVED", spellId, destGuid)
end

MoreDots.snapshot.onDotRefreshed =
function(spellId, destGuid)
    local spellName = MoreDots.dots.refreshDots[spellId]
    if not spellName then
        MoreDots.snapshot.onDotApply(spellId, destGuid)
        return
    end
    
    --[[ Shadow Word: Pain refreshes everything except spell power
    corruption refreshes everything except spell power and haste]]
end

MoreDots.snapshot.buffIsActive = 
function(auraId)
    return MoreDots.auras.activeAuras ~= nil and MoreDots.auras.activeAuras[auraId] ~= nil and MoreDots.auras.activeAuras[auraId] == true
end

MoreDots.snapshot.resetSnapshots = function()
    MoreDots.snapshot.state = {};
    for k,v in pairs(MoreDots.dots.allDots) do
        MoreDots.snapshot.state[v] = {};
    end
end

MoreDots.snapshot.cleanUpTimer = nil;
MoreDots.snapshot.startCleanUpTimer = function()
    -- cancel existing cleanup first if there is one
    MoreDots.snapshot.cancelCleanUpTimer();
    -- start a 10 second timer, after which we reset snapshots.
    MoreDots.snapshot.cleanUpTimer = C_Timer.NewTimer(10,
        function()
            if not UnitAffectingCombat("player") then
                MoreDots.snapshot.resetSnapshots();
            end
        end
    )
end

MoreDots.snapshot.cancelCleanUpTimer = function()
    if MoreDots.snapshot.cleanUpTimer then
        MoreDots.snapshot.cleanUpTimer:Cancel()
        MoreDots.snapshot.cleanUpTimer = nil
    end
end

MoreDots.auras.onBuffApplied = 
function(auraId)
    local auraName = MoreDots.auras.allAuras[auraId]
    if not auraName then
        return
    end
    MoreDots.auras.activeAuras[auraId] = true
end

MoreDots.auras.onBuffRemoved =
function(auraId)
    local auraName = MoreDots.auras.allAuras[auraId]
    if not auraName then
        return
    end
    MoreDots.auras.activeAuras[auraId] = false
end