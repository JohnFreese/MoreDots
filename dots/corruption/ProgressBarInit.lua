aura_env.this = WeakAuras.regions[aura_env.id].region
aura_env.spellId = 27216
aura_env.globWidth = aura_env.this.bar:GetWidth()
aura_env.globHeight= aura_env.this.bar:GetHeight()
aura_env.snapshots = {}
aura_env.snapshotWidth = aura_env.globHeight/2
aura_env.snapshotHeight = aura_env.globHeight/2
aura_env.snapshotBarLength = 4
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

aura_env.specialSnapshots = {
    [965900] = "Shadow Visions"
}

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

aura_env.updateSnapshots = function(destGuid, snapTable)  
    aura_env.hideSnapshots()
    local i = 0
    for k,v in pairs(snapTable) do
        if v and not aura_env.specialSnapshots[k] then
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

aura_env.hideSnapshots = function()
    for k,v in pairs(aura_env.snapshots) do
        aura_env.snapshots[k]:Hide()
    end
end

aura_env.createSnapshots()