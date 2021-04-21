aura_env.this = WeakAuras.regions[aura_env.id].region
aura_env.spellId = 25467
aura_env.shadowVisionsId = 965900
aura_env.globWidth = aura_env.this.bar:GetWidth()
aura_env.globHeight= aura_env.this.bar:GetHeight()
aura_env.markers = {}
aura_env.markerWidth = 2
aura_env.snapshots = {}
aura_env.snapshotBarLength = 4
aura_env.markerWidth = 2
aura_env.markersTexture = "Interface\\AddOns\\WeakAuras\\Media\\Textures\\Square_Smooth_Border2.tga"
aura_env.snapshotTextures = {
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

--creating 12 markers since the shadow visions buff gives 4 extra ticks
aura_env.createMarkers = function()
    for i=0,11 do
        aura_env.createMarker(i)
    end
end

aura_env.createMarker = function(n)
    aura_env.markers[n] =_G[aura_env.spellId.."_marker"..n] or CreateFrame("Frame" ,aura_env.spellId.."_marker"..n, aura_env.this)
    aura_env.markers[n]:SetWidth(aura_env.markerWidth)
    aura_env.markers[n]:SetHeight(aura_env.globHeight)
    local pos = aura_env.globWidth*(n/8)
    aura_env.markers[n]:SetPoint("CENTER", aura_env.this.bar, "LEFT", pos, 0)
    aura_env.markers[n]:SetFrameStrata("HIGH")
    
    local t = aura_env.markers[n]:CreateTexture(nil,"HIGH")
    t:SetTexture(aura_env.markersTexture)
    t:SetAllPoints(aura_env.markers[n])
    aura_env.markers[n].texture = t
    
    if pos < 0 or pos >= aura_env.globWidth then
        aura_env.markers[n]:Hide()
    else
        aura_env.markers[n]:Show()
    end
end

aura_env.createSnapshots = function()
    for k,v in pairs(aura_env.snapshotTextures) do
        aura_env.snapshots[k] = _G[aura_env.id.."_snapshot_"..k] or CreateFrame("Frame", aura_env.id.."_snapshot_"..k, aura_env.this)
        aura_env.snapshots[k]:SetWidth(aura_env.globHeight/2)
        aura_env.snapshots[k]:SetHeight(aura_env.globHeight/2)
        aura_env.snapshots[k]:SetPoint("TOPRIGHT", aura_env.this.bar, "TOPRIGHT", 0, 0)
        
        local t = aura_env.snapshots[k]:CreateTexture(nil,"HIGH")
        t:SetTexture(v)
        t:SetAllPoints(aura_env.snapshots[k])
        aura_env.snapshots[k].texture = t
        
        aura_env.snapshots[k]:Hide()
    end
end

aura_env.updateSnapshots = function(destGuid)
    if MoreDots.snapshot.state ~= nil and MoreDots.snapshot.state[aura_env.spellId] ~= nil and MoreDots.snapshot.state[aura_env.spellId][destGuid] ~= nil then
        aura_env.hideSnapshots()
        local snapTable = MoreDots.snapshot.state[aura_env.spellId][destGuid]
        local i = 0
        for k,v in pairs(snapTable) do
            if v then
                if i < aura_env.snapshotBarLength then
                    aura_env.snapshots[k]:SetPoint("TOPRIGHT", aura_env.this.bar, "TOPRIGHT", (i + 1) * aura_env.globHeight/2, 0)
                    aura_env.snapshots[k]:Show()
                elseif i < aura_env.snapshotBarLength * 2 then
                    aura_env.snapshots[k]:SetPoint("TOPRIGHT", aura_env.this.bar, "TOPRIGHT", (i + 1 - MoreDots.bars.snapshotBarLength) * aura_env.globHeight/2, -aura_env.globHeight/2)
                    aura_env.snapshots[k]:Show()
                else
                    -- only show a certain amount of snapshots
                end
                i = i + 1
            end
        end
    end
end

aura_env.hideSnapshots = function()
    for k,v in pairs(aura_env.snapshots) do
        aura_env.snapshots[k]:Hide()
    end
end

--should be 8 or 12
aura_env.changeNumberOfTicks = function(ticks)
    for k,v in pairs(aura_env.markers) do
        local pos = aura_env.globWidth*k/(ticks) - 2
        aura_env.markers[n]:SetPoint("CENTER", aura_env.this.bar, "LEFT", pos, 0)
        
        if pos < 0 or pos > aura_env.globWidth then
            aura_env.markers[n]:Hide()
        else
            aura_env.markers[n]:Show()
        end
    end
end

aura_env.createMarkers()
aura_env.createSnapshots()