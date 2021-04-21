--[[
    This is the meat and potatoes of the WA

    Events that are created by MoreDots
    MOREDOTS_DOT_APPLIED, spellId, destGuid, snapTable
    MOREDOTS_DOT_REFRESHED, spellId, destGuid, snapTable
    MOREDOTS_DOT_REMOVED, spellId, destGuid, snapTable

    Search ~CONFIG~ to adjust some configuration properties
]]
MoreDots = {}

setglobal("MoreDots", MoreDots)

MoreDots.playerGuid = UnitGUID("player")

--========================================
--= HASTE RELATED CODE
--========================================

MoreDots.haste = {}

-- ~CONFIG~ the value is how many points you have in the talent (this list includes REs too)
MoreDots.haste.selectedTalents = {
    ["Alacrity"] = 3,
    ["Death's Grasp"] = 3,
    ["Arcane Meditation"] = 0,
    ["Celestial Focus"] = 1
}

-- how much haste each point gives
MoreDots.haste.talentValues = {
    ["Alacrity"] = 2,
    ["Death's Grasp"] = 1,
    ["Arcane Meditation"] = 1,
    ["Celestial Focus"] = 2
}

MoreDots.haste.playerHasteRating = GetCombatRatingBonus(20)
MoreDots.haste.hasStaffEquipped = IsEquippedItemType("staves")

MoreDots.haste.calculateHasteFromTalents = function()
    local haste = 0
    for k,v in pairs(MoreDots.haste.selectedTalents) do
        haste = ((1 + haste/100) * (1 + (v * MoreDots.haste.talentValues[k])/100) - 1) * 100
    end
    return haste
end

MoreDots.haste.calculateBaseHaste = function()
    local hasteRating = MoreDots.haste.playerHasteRating
    local staffHaste = 0
    if MoreDots.haste.hasStaffEquipped then
        staffHaste = 10
    end
    
    return ((1 + hasteRating/100) * (1 + staffHaste/100) * (1 + MoreDots.haste.calculateHasteFromTalents()/100) - 1) * 100
end

--haste stacks multiplicatively
MoreDots.haste.addPlayerHaste = function(haste)
    MoreDots.playerHaste = ((1 + MoreDots.playerHaste/100) * (1 + haste/100) - 1) * 100
end

MoreDots.haste.removePlayerHaste = function(haste)
    MoreDots.playerHaste = ((MoreDots.playerHaste/100 + 1)/(1 + haste/100) - 1) * 100
end

MoreDots.haste.calculateNewDuration = function(spellId)
    return MoreDots.dots.baseDurations[spellId] / ((MoreDots.playerHaste)/100 + 1)
end

MoreDots.haste.calculateNextTick = function(spellId, destGuid)
    if MoreDots.dots.refreshDots[spellId] and MoreDots.dots.refreshDotTickTime[destGuid] and MoreDots.dots.refreshDotTickTime[destGuid][spellId] then
        local prevTick = MoreDots.dots.refreshDotTickTime[destGuid][spellId]
        local tickTime = MoreDots.haste.calculateNewDuration(spellId)/(MoreDots.dots.numberOfTicks[spellId])
        return prevTick + tickTime
    end
    
    return 0
end

--manually tracking player haste because the api doesnt support it. this will be the %haste
MoreDots.playerHaste = MoreDots.haste.calculateBaseHaste()

--========================================
--= DOT RELATED CODE
--========================================

MoreDots.dots = {}

MoreDots.dots.refreshDots = { 
    [25368] = "Shadow Word: Pain",
    [27216] = "Corruption"
}

MoreDots.dots.allDotsExceptRefresh = {
    [25467] = "Devouring Plague",
    [34917] = "Vampiric Touch",
    [30405] = "Unstable Affliction"
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
    MoreDots.dots.refreshDotWasCast[spellId] = true/false
]]
MoreDots.dots.refreshDotWasCast = {}

--[[tracking the last time the refresh dot ticked to update the tick timers properly
    MoreDots.dots.refreshDotTickTime[destGuid][spellId] = true/false
]]
MoreDots.dots.refreshDotTickTime = {}

--[[tracking when the next tick will happen so we can track tick timers properly
    MoreDots.dots.refreshDotNextTickTime[destGuid][spellId] = true/false
]]
MoreDots.dots.refreshDotNextTickTime = {}

MoreDots.dots.allDots = {}

for k,v in pairs(MoreDots.dots.critDots) do
    MoreDots.dots.allDots[k] = v
end

MoreDots.dots.baseDurations = {
    [25368] = 18, --swp
    [27216] = 18, --corruption
    [34917] = 15, --vt
    [25467] = 24, --devo
    [30405] = 15 --ua
}

MoreDots.dots.numberOfTicks = {
    [25368] = 6, --swp
    [27216] = 6, --corruption
    [34917] = 5, --vt
    [25467] = 8, --devo (has a variable number of ticks, handle this special case later)
    [30405] = 5 --ua
}

--========================================
--= AURA RELATED CODE
--========================================

MoreDots.auras = {}

-- ~CONFIG~ add any buff modifiers that arent listed in one of these 4 categories
MoreDots.auras.damageModifiers = { 
    [12042] = "Arcane Power",
    [63848] = "Hunger For Blood"
}

MoreDots.auras.critModifiers = { 
    [57531] = "Arcane Potency", --special case
    [31842] = "Divine Illumination"
}

MoreDots.auras.hasteModifiers = { 
    [2825] = "Bloodlust",
    [2895] = "Wrath of Air Totem",
    [10060] = "Power Infusion",
    [64371] = "Eradication",
    [965899] = "Soul Fragment",
    [965900] = "Shadow Visions"
}

MoreDots.auras.spellPowerModifiers = {
    [33697] = "Blood Fury",
    [35163] = "Blessing of the Silver Cescent",
    [32108] = "Lesser Spell Blasting" --spellstrike set
    -- add trinket auras here too
}

--[[these auras cannot be tracked as easily since they go away after a spellcast. 
    There is no guarentee that these auras will be tracked in the active auras list.
    If an aura needs to be added here the makeSnapshotTable function needs to be updated
]]
MoreDots.auras.lostOnApply = {
    [57531] = "Arcane Potency",
    [965900] = "Shadow Visions"
}

-- ~CONFIG~ 
MoreDots.auras.hasteRatings = {
    [2825] = 20, -- lust
    [2895] = 3, --totem
    [10060] = 20, -- PI
    [64371] = 26, --eradication 20 + 6 from REs
    [965899] = 1, --1/stack to a maximum of 8 (9 is when the aura is removed)
    [965900] = 0 --special case for devo plague
}

--[[this will hold the aura id and a time that it "expires". this time is completely 
    arbitrary and only represents an estimate of what spell cast received the benefit of
    the aura.
    lostOnApplyExpireTime[57531] = <time the aura was removed + some number>
]]
MoreDots.auras.lostOnApplyExpireTime = {}
MoreDots.auras.lostOnApplyExpireTimeInterval = 0.25

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
    [SPELL_ID] = true,
    [SPELL_ID] = false
]]
MoreDots.auras.activeAuras = {}

MoreDots.auras.onBuffApplied = function(spellId)
    local auraName = MoreDots.auras.allAuras[spellId]
    if not auraName then
        return
    end
    
    if MoreDots.auras.hasteRatings[spellId] and MoreDots.auras.activeAuras[spellId] ~= true then
        MoreDots.haste.addPlayerHaste(MoreDots.auras.hasteRatings[spellId])
    end
    
    MoreDots.auras.activeAuras[spellId] = true
end

MoreDots.auras.onBuffRemoved = function(spellId)
    local auraName = MoreDots.auras.allAuras[spellId]
    if not auraName then
        return
    end
    
    if MoreDots.auras.lostOnApply[spellId] then
        local time = GetTime()
        MoreDots.auras.lostOnApplyExpireTime[spellId] = time + MoreDots.auras.lostOnApplyExpireTimeInterval
    end
    
    if MoreDots.auras.hasteRatings[spellId] then
        MoreDots.haste.removePlayerHaste(MoreDots.auras.hasteRatings[spellId])
    end
    
    MoreDots.auras.activeAuras[spellId] = false
end

MoreDots.auras.buffIsActive = function(spellId)
    local spellName = MoreDots.auras.allAuras[spellId]
    if not spellName then
        return
    end
    
    name, rank, icon, count, debuffType, duration, expirationTime, unitCaster, isStealable, 
    shouldConsolidate, spellId = UnitBuff("player", spellName)
    
    return name ~= nil
end

--========================================
--= SNAPSHOT RELATED CODE
--========================================

MoreDots.snapshot = {}
--[[state will look something like this:
    MoreDots.snapshot.state[destGuid][spellId]
    the value for this will be a table of the tracked auras.
    [57531] = true, arcane potency
    [10060] = false, PI
    ...
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

-- ~CONFIG~ update this for extra lostOnApply buffs
MoreDots.snapshot.makeSnapshotTable = function(spellId)
    local now = GetTime()
    local snapTable = {}
    
    for k,v in pairs(MoreDots.auras.damageModifiers) do
        snapTable[k] = MoreDots.auras.buffIsActive(k)    
    end
    
    if MoreDots.dots.critDots[spellId] then 
        for k,v in pairs(MoreDots.auras.critModifiers) do
            if not MoreDots.auras.lostOnApply[k] then
                snapTable[k] = MoreDots.auras.buffIsActive(k)
            end
            
            if MoreDots.auras.lostOnApplyExpireTime[k] ~= nil 
            and MoreDots.auras.lostOnApplyExpireTime[k] > now then
                snapTable[k] = true
            elseif MoreDots.auras.lostOnApply[k] ~= nil then
                snapTable[k] = false
            end
        end
        
    end
    
    if MoreDots.dots.hasteDots[spellId] then 
        for k,v in pairs(MoreDots.auras.hasteModifiers) do
            if MoreDots.auras.lostOnApply[k] == nil then
                snapTable[k] = MoreDots.auras.buffIsActive(k)
            end
            
            if MoreDots.auras.lostOnApplyExpireTime[k] ~= nil
            and MoreDots.auras.lostOnApplyExpireTime[k] > now then
                snapTable[k] = true
            elseif MoreDots.auras.lostOnApply[k] ~= nil then
                snapTable[k] = false
            end
        end
    end
    
    return snapTable
end

MoreDots.snapshot.onDotApplied = function(spellId, destGuid)
    if not MoreDots.dots.allDots[spellId] then
        return
    end
    
    if MoreDots.dots.refreshDotWasCast[spellId] ~= nil then
        if MoreDots.dots.refreshDotWasCast[spellId][destGuid] == true then
            MoreDots.snapshot.updateRefreshCast(spellId, destGuid, false)
        end
    end
    
    local snapTable = MoreDots.snapshot.makeSnapshotTable(spellId)
    
    MoreDots.snapshot.state[spellId] = {}
    MoreDots.snapshot.state[spellId][destGuid] = snapTable
    WeakAuras.ScanEvents("MOREDOTS_DOT_APPLIED", spellId, destGuid, snapTable)
end

MoreDots.snapshot.onDotRemoved = function (spellId, destGuid)
    if not MoreDots.dots.allDots[spellId] then
        return
    end
    
    local snapTable = {}
    
    MoreDots.snapshot.state[spellId] = {}
    MoreDots.snapshot.state[spellId][destGuid] = snapTable
    WeakAuras.ScanEvents("MOREDOTS_DOT_REMOVED", spellId, destGuid, snapTable)
end

--only crit and damage% modifiers refresh
MoreDots.snapshot.onDotRefreshed = function(spellId, destGuid)  
    if MoreDots.dots.allDots[spellId] 
    and (MoreDots.dots.refreshDotWasCast[spellId] == nil 
        or MoreDots.dots.refreshDotWasCast[spellId][destGuid] == nil 
        or MoreDots.dots.refreshDotWasCast[spellId][destGuid]) then
        MoreDots.snapshot.onDotApplied(spellId, destGuid)
        return
    end
    
    if not MoreDots.dots.refreshDots[spellId] then
        return
    end
    
    local snapTable = MoreDots.snapshot.state[spellId][destGuid]
    if snapTable ~= nil then
        for k,v in pairs(snapTable) do
            for i,j in pairs (MoreDots.auras.hasteModifiers) do
                if k == i then
                    snapTable[i] = MoreDots.auras.buffIsActive(i)
                    break
                end
            end
            
            for i,j in pairs (MoreDots.auras.spellPowerModifiers) do
                if k == i then
                    snapTable[i] = MoreDots.auras.buffIsActive(i)
                    break
                end
            end
        end
    end
    WeakAuras.ScanEvents("MOREDOTS_DOT_REFRESHED", spellId, destGuid, snapTable)
end

MoreDots.snapshot.updateRefreshCast = function(spellId, destGuid, cast)
    if MoreDots.dots.refreshDots[spellId] then
        if MoreDots.dots.refreshDotWasCast[spellId] == nil then
            MoreDots.dots.refreshDotWasCast[spellId] = {}
        end
        MoreDots.dots.refreshDotWasCast[spellId][destGuid] = cast
    end
end

MoreDots.snapshot.updateTickTimer = function(spellId, destGuid)
    if MoreDots.dots.refreshDots[spellId] then
        if MoreDots.dots.refreshDotTickTime[spellId] == nil then
            MoreDots.dots.refreshDotTickTime[spellId] = {}
        end
        
        if MoreDots.dots.refreshDotNextTickTime[spellId] == nil then
            MoreDots.dots.refreshDotNextTickTime[spellId] = {}
        end
        
        MoreDots.dots.refreshDotTickTime[spellId][destGuid] = GetTime()
        MoreDots.dots.refreshDotNextTickTime[spellId][destGuid] = MoreDots.haste.calculateNextTick(spellId, destGuid)
        
        --WeakAuras.ScanEvents("MOREDOTS_DOT_TICKED", spellId, destGuid, nil, MoreDots.dots.refreshDotTickTime[spellId][destGui])
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

--========================================
--= PROGRESS BAR RELATED CODE
--========================================


MoreDots.bars = {}
-- ~CONFIG~ adjust the values here to your liking then reload
MoreDots.bars.snapshotBarLength = 4
MoreDots.bars.markerWidth = 2
MoreDots.bars.markersTexture = "Interface\\AddOns\\WeakAuras\\Media\\Textures\\Square_Smooth_Border2.tga"
-- ~CONFIG~ add textures here for auras you want to track
MoreDots.bars.snapshotTextures = {
    [57531] = "Interface\\Icons\\Spell_Arcane_ArcanePotency", --arcane potency
    [64371] = "Interface\\Icons\\Ability_Warlock_Eradication", --eradication
    [10060] = "Interface\\Icons\\Spell_Holy_PowerInfusion", --PI
    [2825] = "Interface\\Icons\\Spell_Nature_BloodLust", --lust
    [12042] = "Interface\\Icons\\Spell_Nature_Lightning", --arcane power
    [965899] = "Interface\\Icons\\INV_Enchant_VoidCrystal", --soul fragment
    [31842] = "Interface\\Icons\\Spell_Holy_DivineIllumination", --divine illumination
    [63848] = "Interface\\Icons\\Ability_Rogue_HungerforBlood", --hunger for blood
    [33697] = "Interface\\Icons\\Racial_Orc_BerserkerStrength", --blood fury
    [35163] = "Interface\\Icons\\INV_Trinket_Naxxramas06", --blessing of the silver crescent
    [32108] = "Interface\\Icons\\Spell_Lightning_LightningBolt01" --lesser spell blasting
}

--[[special cases that are not handled by the general bar functions.
currently no use for this, but it is here just in case]]
MoreDots.bars.snapshotTexturesSpecial = {
    [965900] = "Interface\\Icons\\Spell_Shadow_Charm" --shadow visions
}

MoreDots.bars.createMarkers = function(spellId, markerTable, width, height, parent)
    if not MoreDots.dots.numberOfTicks[spellId] then
        return
    end
    
    for i=0,MoreDots.dots.numberOfTicks[spellId] - 1 do
        MoreDots.bars.createMarker(spellId, markerTable, width, height, parent, i)
    end
end

MoreDots.bars.createMarker = function(spellId, markerTable, width, height, parent, n)
    --_G is the global table that holds all frame ids
    markerTable[n] =_G[spellId.."_marker"..n] or CreateFrame("Frame" ,spellId.."_marker"..n, parent)
    markerTable[n]:SetWidth(MoreDots.bars.markerWidth)
    markerTable[n]:SetHeight(height)
    local pos = width*n/(MoreDots.dots.numberOfTicks[spellId]) - 2
    markerTable[n]:SetPoint("CENTER", parent.bar, "LEFT", pos, 0)
    markerTable[n]:SetFrameStrata("HIGH")
    
    local t = markerTable[n]:CreateTexture(nil,"HIGH")
    t:SetTexture(MoreDots.bars.markersTexture)
    t:SetAllPoints(markerTable[n])
    markerTable[n].texture = t
    
    markerTable[n]:Show()
end

MoreDots.bars.createSnapshots = function(weakAuraId, snapshotTable, width, height, parent)
    for k,v in pairs(MoreDots.bars.snapshotTextures) do
        snapshotTable[k] = _G[weakAuraId.."_snapshot_"..k] or CreateFrame("Frame", weakAuraId.."_snapshot_"..k, parent)
        snapshotTable[k]:SetWidth(height/2)
        snapshotTable[k]:SetHeight(height/2)
        snapshotTable[k]:SetPoint("TOPRIGHT", parent.bar, "TOPRIGHT", 0, 0)
        
        local t = snapshotTable[k]:CreateTexture(nil,"HIGH")
        t:SetTexture(v)
        t:SetAllPoints(snapshotTable[k])
        snapshotTable[k].texture = t
        
        snapshotTable[k]:Hide()
    end
end

MoreDots.bars.updateSnapshots = function(spellId, destGuid, snapshotTable, height, parent)
    if MoreDots.snapshot.state ~= nil and MoreDots.snapshot.state[spellId] ~= nil and MoreDots.snapshot.state[spellId][destGuid] ~= nil then
        MoreDots.bars.hideSnapshots(snapshotTable)
        local snapTable = MoreDots.snapshot.state[spellId][destGuid]
        local i = 0
        for k,v in pairs(snapTable) do
            if v then
                if i < MoreDots.bars.snapshotBarLength then
                    snapshotTable[k]:SetPoint("TOPRIGHT", parent.bar, "TOPRIGHT", (i + 1) * height/2, 0)
                    snapshotTable[k]:Show()
                elseif i < MoreDots.bars.snapshotBarLength * 2 then
                    snapshotTable[k]:SetPoint("TOPRIGHT", parent.bar, "TOPRIGHT", (i + 1 - MoreDots.bars.snapshotBarLength) * height/2, -height/2)
                    snapshotTable[k]:Show()
                else
                    -- only show a certain amount of snapshots
                end
                i = i + 1
            end
        end
    end
end

MoreDots.bars.hideSnapshots = function(snapshotTable)
    for k,v in pairs(snapshotTable) do
        snapshotTable[k]:Hide()
    end
end

MoreDots.debug = {}

MoreDots.debug.printObject = function(o)
    if type(o) == 'table' then
        local s = '{ '
        for k,v in pairs(o) do
            if type(k) ~= 'number' then k = '"'..k..'"' end
            s = s..'['..k..'] = '.. MoreDots.debug.printObject(v)..','
        end
        return s..'} '
    else
        return tostring(o)
    end
end