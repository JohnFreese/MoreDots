aura_env.this = WeakAuras.regions[aura_env.id].region
aura_env.globWidth = aura_env.this.bar:GetWidth()
aura_env.globHeight= aura_env.this.bar:GetHeight()
aura_env.oldWidth = aura_env.globWidth
aura_env.startTime = 0
aura_env.markers = {}
aura_env.sMarkers = {}
aura_env.sMarkersCount = 0
aura_env.snapshots = {}
aura_env.deltas = {}
aura_env.markerC = {r = 1, g = 1, b = 1, a = 1}
aura_env.markerT = "Interface\\AddOns\\WeakAuras\\Media\\Textures\\Square_Smooth_Border2.tga"
aura_env.markerST = "Interface\\RED.tga"
aura_env.snapshotTextures = {
    ["Arcane Potency"] = "Interface\\Icons\\Spell_Arcane_ArcanePotency",
    ["Eradication"] = "Interface\\Icons\\Ability_Warlock_Eradication",
    ["Power Infusion"] = "Interface\\Icons\\Spell_Holy_PowerInfusion",
    ["Bloodlust"] = "Interface\\Icons\\Spell_Nature_BloodLust",
    ["Arcane Power"] = "Interface\\Icons\\Spell_Nature_Lightning",
    ["Soul Fragment"] = "Interface\\Icons\\INV_Enchant_VoidCrystal",
    ["Divine Illumination"] = "Interface\\Icons\\Spell_Holy_DivineIllumination",
    ["Hunger for Blood"] = "Interface\\Icons\\Ability_Rogue_HungerforBlood",
    ["Blood Fury"] = "Interface\\Icons\\Racial_Orc_BerserkerStrength",
    ["Blessing of the Silver Crescent"] = "Interface\\Icons\\INV_Trinket_Naxxramas06",
    ["Lesser Spell Blasting"] = "Interface\Icons\Spell_Lightning_LightningBolt01"
}

aura_env.visableSnapshots = {
    ["Arcane Potency"] = false,
    ["Eradication"] = false,
    ["Power Infusion"] = false,
    ["Bloodlust"] = false,
    ["Arcane Power"] = false,
    ["Soul Fragment"] = false,
    ["Divine Illumination"] = false,
    ["Hunger for Blood"] = false,
    ["Blood Fury"] = false,
    ["Blessing of the Silver Crescent"] = false
}

aura_env.snapshotWidth = aura_env.globHeight/2
aura_env.snapshotHeight = aura_env.globHeight/2
aura_env.snapshotBarLength = 4
aura_env.markerWidth = 2

aura_env.createMarker = function(n)
    aura_env.markers[n] =_G[aura_env.id.."_marker"..n] or CreateFrame("Frame", aura_env.id.."_marker"..n, aura_env.this)
    aura_env.markers[n]:SetWidth(aura_env.markerWidth)
    aura_env.markers[n]:SetHeight(aura_env.globHeight)
    local pos = aura_env.globWidth*n/5 - 2
    aura_env.markers[n]:SetPoint("CENTER", aura_env.this.bar, "LEFT", pos, 0)
    aura_env.markers[n]:SetFrameStrata("HIGH")
    
    local t = aura_env.markers[n]:CreateTexture(nil,"HIGH")
    t:SetTexture(aura_env.markerT)
    t:SetAllPoints(aura_env.markers[n])
    aura_env.markers[n].texture = t
    
    aura_env.markers[n]:Show()
end

aura_env.createSnapshots = function()
    for k,v in pairs(aura_env.snapshotTextures) do
        aura_env.snapshots[k] = _G[aura_env.id.."_snapshot_"..k] or CreateFrame("Frame", aura_env.id.."_snapshot_"..k, aura_env.this)
        aura_env.snapshots[k]:SetWidth(aura_env.snapshotWidth)
        aura_env.snapshots[k]:SetHeight(aura_env.snapshotHeight)
        aura_env.snapshots[k]:SetPoint("TOPRIGHT", aura_env.this.bar, "TOPRIGHT", 0, 0)
        
        local t = aura_env.snapshots[k]:CreateTexture(nil,"HIGH")
        t:SetTexture(v)
        t:SetAllPoints(aura_env.snapshots[k])
        aura_env.snapshots[k].texture = t
        
        aura_env.snapshots[k]:Hide()
    end
end

aura_env.updateSnapshots = function(destGuid)
    if MoreDots.snapshot.state ~= nil and MoreDots.snapshot.state["Vampiric Touch"] ~= nil and MoreDots.snapshot.state["Vampiric Touch"][destGuid] ~= nil then
        aura_env.hideSnapshots()
        local snapTable = MoreDots.snapshot.state["Vampiric Touch"][destGuid]
        local i = 0
        for k,v in pairs(snapTable) do
            if v then
                if i < aura_env.snapshotBarLength then
                    aura_env.snapshots[k]:SetPoint("TOPRIGHT", aura_env.this.bar, "TOPRIGHT", (i + 1) * aura_env.snapshotWidth, 0)
                    aura_env.snapshots[k]:Show()
                elseif i < aura_env.snapshotBarLength * 2 then
                    aura_env.snapshots[k]:SetPoint("TOPRIGHT", aura_env.this.bar, "TOPRIGHT", (i + 1 - aura_env.snapshotBarLength) * aura_env.snapshotWidth, -aura_env.snapshotHeight)
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


aura_env.moveSMarker = function(dest)
    aura_env.sMarkers[aura_env.sMarkersCount]:SetPoint("CENTER", aura_env.this.bar, "LEFT", dest, 0)
    aura_env.sMarkers[aura_env.sMarkersCount]:Show()
    aura_env.sMarkersCount = aura_env.sMarkersCount + 1
end

aura_env.resetSMarkers = function()
    for k,v in pairs(aura_env.sMarkers) do
        aura_env.sMarkers[k]:SetPoint("CENTER", aura_env.this.bar, "LEFT", 0, 0)
        aura_env.sMarkers[k]:Hide()
    end
    aura_env.sMarkersCount = 0
end


--Create Markers
aura_env.createMarker(0)
aura_env.createMarker(1)
aura_env.createMarker(2)
aura_env.createMarker(3)
aura_env.createMarker(4)
aura_env.createSnapshots()