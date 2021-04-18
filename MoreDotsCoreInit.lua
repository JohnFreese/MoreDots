--[[
    Events that are created by MoreDots
    MOREDOTS_DOT_APPLIED, spellId, destGuid, snap
    MOREDOTS_DOT_REMOVED, spellId, destGuid
]]
MoreDots = {}

setglobal("MoreDots", MoreDots)

MoreDots.playerGuid = UnitGUID("player")

MoreDots.haste = {}
--the value is how many points you have in the talent
MoreDots.haste.selectedTalents = {
    ["Alacrity"] = 3,
    ["Death's Grasp"] = 3,
    ["Arcane Meditation"] = 0,
    ["Celestial Focus"] = 1
}
--how much haste each point gives
MoreDots.haste.talentValues = {
    ["Alacrity"] = 2,
    ["Death's Grasp"] = 1,
    ["Arcane Meditation"] = 1,
    ["Celestial Focus"] = 2
}
MoreDots.haste.baseDurations = {
    [25368] = 18, --swp
    [27216] = 18, --corruption
    [34917] = 15, --vt
    [25467] = 24 --devo
}
MoreDots.haste.playerHasteRating = GetCombatRatingBonus(20)
MoreDots.haste.hasStaffEquipped = IsEquippedItemType("staves")

MoreDots.haste.calculateHasteFromTalents = 
function()
    local haste = 0
    for k,v in pairs(MoreDots.haste.selectedTalents) do
        haste = ((1 + haste/100) * (1 + (v * MoreDots.haste.talentValues[k])/100) - 1) * 100
    end
    return haste
end

MoreDots.haste.calculateBaseHaste =
function()
    local hasteRating = MoreDots.haste.playerHasteRating
    local staffHaste = 0
    if MoreDots.haste.hasStaffEquipped then
        staffHaste = 10
    end
    
    return ((1 + hasteRating/100) * (1 + staffHaste/100) * (1 + MoreDots.haste.calculateHasteFromTalents()/100) - 1) * 100
end

--haste stacks multiplicatively
MoreDots.haste.addHaste = 
function(haste)
    MoreDots.playerHaste = ((1 + MoreDots.playerHaste/100) * (1 + haste/100) - 1) * 100
end

MoreDots.haste.removeHaste = 
function(haste)
    MoreDots.playerHaste = ((MoreDots.playerHaste/100 + 1)/(1 + haste/100) - 1) * 100
end

MoreDots.haste.calculateNewDuration = 
function(spellId)
    return MoreDots.haste.baseDurations[spellId] / ((MoreDots.playerHaste)/100 + 1)
end

MoreDots.haste.calculateNextTick = 
function(spellId, destGuid)
    if MoreDots.dots.refreshDots[spellId] and MoreDots.dots.refreshDotTickTime[destGuid] and MoreDots.dots.refreshDotTickTime[destGuid][spellId] then
        local prevTick = MoreDots.dots.refreshDotTickTime[destGuid][spellId]
        local tickTime = MoreDots.haste.calculateNewDuration(spellId)/(MoreDots.haste.baseDurations[spellId]/3)
        return prevTick + tickTime
    end
    
    return 0
end

--manually tracking player haste because the api doesnt support it. this will be the %haste
MoreDots.playerHaste = MoreDots.haste.calculateBaseHaste()

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

--[[tracking whether the refresh dot was cast or refreshed
{
    [27216] = false,
    [25368] = false
}
]]
MoreDots.dots.refreshDotWasCast = {}

--[[tracking the last time the refresh dot ticked to update the tick timers properly
{
    [27216] = 0,
    [25368] = 0
}
]]
MoreDots.dots.refreshDotTickTime = {}

--tracking when the next tick will happen so we can track tick timers properly
MoreDots.dots.refreshDotNextTickTime = {}

MoreDots.dots.allDots = {}

for k,v in pairs(MoreDots.dots.critDots) do
    MoreDots.dots.allDots[k] = v
end

--refresh dots need to be treated differently
MoreDots.dots.allDotsExceptRefresh = {
    [25467] = "Devouring Plague",
    [34917] = "Vampiric Touch",
    [30405] = "Unstable Affliction"
}

MoreDots.dots.refreshDots = {
    [27216] = "Corruption",
    [25368] = "Shadow Word: Pain"
}

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
    [2825] = "Bloodlust",
    [10060] = "Power Infusion",
    [64371] = "Eradication",
    [965899] = "Soul Fragment"
}

MoreDots.auras.spellPowerModifiers = {
    [33697] = "Blood Fury",
    [35163] = "Blessing of the Silver Cescent",
    [32108] = "Lesser Spell Blasting" --spellstrike set
    -- add trinket auras here too
}

--[[these auras cannot be tracked as easily since they go away after a spellcast. 
There is no guarentee that these auras will be tracked in the active auras list]]
MoreDots.auras.lostOnApply = {
    [57531] = "Arcane Potency"
}

MoreDots.auras.hasteRatings = {
    [2825] = 20,
    [10060] = 20,
    [64371] = 26,
    [965899] = 1 --1/stack to a maximum of 8 (9 is when the aura is removed)
}

--[[this will hold the aura id and a time that it "expires". this time is completely 
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

for k,v in pairs(MoreDots.auras.spellPowerModifiers) do
    MoreDots.auras.allAuras[k] = v
end

for k,v in pairs(MoreDots.auras.lostOnApply) do
    MoreDots.auras.allAuras[k] = v
end

--[[state for tracking active auras we care about when applying DoTs
{
    [SPELL_ID] = true,
    [SPELL_ID] = false
}
]]
MoreDots.auras.activeAuras = {}

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
    ["SPELL_PERIODIC_DAMAGE"] = true,
    ["SPELL_CAST_SUCCESS"] = true,
    ["SPELL_MISSED"] = true
}

MoreDots.snapshot.makeSnapshotTable = 
function(spellId)
    local now = GetTime()
    local snapTable = {}
    
    print("Active Auras: ", MoreDots.debug.printTable(MoreDots.auras.activeAuras))
    
    for k,v in pairs(MoreDots.auras.damageModifiers) do
        snapTable[v] = MoreDots.snapshot.buffIsActive(k)    
    end
    
    if MoreDots.dots.critDots[spellId] then 
        for k,v in pairs(MoreDots.auras.critModifiers) do
            snapTable[v] = MoreDots.snapshot.buffIsActive(k)
        end
        
        for k,v in pairs(MoreDots.auras.lostOnApply) do
            if MoreDots.auras.lostOnApplyExpireTime[k] ~= nil then
                if MoreDots.auras.lostOnApplyExpireTime[k] > now then
                    snapTable[v] = true
                end
            end
        end
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
    
    if MoreDots.dots.refreshDotWasCast[destGuid] ~= nil then
        if MoreDots.dots.refreshDotWasCast[destGuid][spellId] == true then
            MoreDots.snapshot.updateRefreshCast(spellId, destGuid, false)
        end
    end
    
    local snapTable = MoreDots.snapshot.makeSnapshotTable(spellId)
    
    MoreDots.snapshot.state[spellName] = {}
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

--only crit and damage% modifiers refresh
MoreDots.snapshot.onDotRefreshed =
function(spellId, destGuid)  
    if MoreDots.dots.allDots[spellId] and (MoreDots.dots.refreshDotWasCast[destGuid] == nil or MoreDots.dots.refreshDotWasCast[destGuid][spellId] == nil or MoreDots.dots.refreshDotWasCast[destGuid][spellId]) then
        MoreDots.snapshot.onDotApplied(spellId, destGuid)
        return
    end
    
    local spellName = MoreDots.dots.refreshDots[spellId]
    if not spellName then
        return
    end
    
    local snapTable = MoreDots.snapshot.state[spellName][destGuid]
    if snapTable ~= nil then
        for k,v in pairs(snapTable) do
            for i,j in pairs (MoreDots.auras.hasteModifiers) do
                if k == j then
                    snapTable[k] = MoreDots.snapshot.buffIsActive(i)
                    break
                end
            end
            
            for i,j in pairs (MoreDots.auras.spellPowerModifiers) do
                if k == j then
                    snapTable[k] = MoreDots.snapshot.buffIsActive(i)
                    break
                end
            end
        end
    end
    WeakAuras.ScanEvents("MOREDOTS_DOT_REFRESHED", spellId, destGuid, snapTable)
end

MoreDots.snapshot.buffIsActive = 
function(auraId)
    return MoreDots.auras.activeAuras ~= nil and MoreDots.auras.activeAuras[auraId] ~= nil and MoreDots.auras.activeAuras[auraId] == true
end

MoreDots.snapshot.updateRefreshCast =
function(spellId, destGuid, cast)
    if MoreDots.dots.refreshDots[spellId] then
        if MoreDots.dots.refreshDotWasCast[destGuid] == nil then
            MoreDots.dots.refreshDotWasCast[destGuid] = {}
        end
        MoreDots.dots.refreshDotWasCast[destGuid][spellId] = cast
    end
end

MoreDots.snapshot.updateTickTimer =
function(spellId, destGuid)
    if MoreDots.dots.refreshDots[spellId] then
        if MoreDots.dots.refreshDotTickTime[destGuid] == nil then
            MoreDots.dots.refreshDotTickTime[destGuid] = {}
        end
        
        if MoreDots.dots.refreshDotNextTickTime[destGuid] == nil then
            MoreDots.dots.refreshDotNextTickTime[destGuid] = {}
        end
        
        MoreDots.dots.refreshDotTickTime[destGuid][spellId] = GetTime()
        MoreDots.dots.refreshDotNextTickTime[destGuid][spellId] = MoreDots.haste.calculateNextTick(spellId, destGuid)
        
        WeakAuras.ScanEvents("MOREDOTS_DOT_TICKED", spellId, destGuid, nil, MoreDots.dots.refreshDotTickTime[destGuid][spellId])
        --print("tick time: ", MoreDots.dots.refreshDotTickTime[destGuid][spellId])
        --print("next tick time: ", MoreDots.dots.refreshDotNextTickTime[destGuid][spellId])
    end
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
    
    if MoreDots.auras.hasteRatings[auraId] and MoreDots.auras.activeAuras[auraId] ~= true then
        MoreDots.haste.addHaste(MoreDots.auras.hasteRatings[auraId])
    end
    
    MoreDots.auras.activeAuras[auraId] = true
end

MoreDots.auras.onBuffRemoved =
function(auraId)
    local auraName = MoreDots.auras.allAuras[auraId]
    if not auraName then
        return
    end
    
    if MoreDots.auras.lostOnApply[auraId] then
        local time = GetTime()
        MoreDots.auras.lostOnApplyExpireTime[auraId] = time + MoreDots.auras.lostOnApplyExpireTimeInterval
    end
    
    if MoreDots.auras.hasteRatings[auraId] then
        MoreDots.haste.removeHaste(MoreDots.auras.hasteRatings[auraId])
    end
    
    MoreDots.auras.activeAuras[auraId] = false
end

MoreDots.debug = {}

MoreDots.debug.printTable = 
function(o)
    if type(o) == 'table' then
        local s = '{ '
        for k,v in pairs(o) do
            if type(k) ~= 'number' then k = '"'..k..'"' end
            s = s .. '['..k..'] = ' .. MoreDots.debug.printTable(v) .. ','
        end
        return s .. '} '
    else
        return tostring(o)
    end
end

