aura_env.this = WeakAuras.regions[aura_env.id].region
aura_env.spellId = 30405
aura_env.shadowVisionsId = 965900
aura_env.globWidth = aura_env.this.bar:GetWidth()
aura_env.globHeight= aura_env.this.bar:GetHeight()
aura_env.markers = {}
aura_env.markerWidth = 2
aura_env.snapshots = {}

--creating 12 markers since the shadow visions buff gives 4 extra ticks
aura_env.createMarkers = function()
    for i=0,11 do
        aura_env.createMarker.createMarker(i)
    end
end

aura_env.createMarker = function(n)
    aura_env.markers[n] =_G[aura_env.spellId.."_marker"..n] or CreateFrame("Frame" ,aura_env.spellId.."_marker"..n, aura_env.this)
    aura_env.markers[n]:SetWidth(aura_env.markerWidth)
    aura_env.markers[n]:SetHeight(aura_env.globHeight)
    local pos = width*n/(8) - 2
    aura_env.markers[n]:SetPoint("CENTER", aura_env.this.bar, "LEFT", pos, 0)
    aura_env.markers[n]:SetFrameStrata("HIGH")
    
    local t = aura_env.markers[n]:CreateTexture(nil,"HIGH")
    t:SetTexture(MoreDots.bars.markersTexture)
    t:SetAllPoints(aura_env.markers[n])
    aura_env.markers[n].texture = t
    
    if pos < 0 or pos > aura_env.globWidth then
        aura_env.markers[n]:Hide()
    else
        aura_env.markers[n]:Show()
    end
end

--should be 8 or 12
aura_env.changeNumberOfTicks = function(ticks)
    for k,v in pairs(aura_env.markers) do
        local pos = width*k/(ticks) - 2
        aura_env.markers[n]:SetPoint("CENTER", aura_env.this.bar, "LEFT", pos, 0)

        if pos < 0 or pos > aura_env.globWidth then
            aura_env.markers[n]:Hide()
        else
            aura_env.markers[n]:Show()
        end
    end
end

--create tick markers and snapshot frames
aura_env.createMarkers()
MoreDots.bars.createSnapshots(aura_env.id, aura_env.snapshots, aura_env.globWidth, aura_env.globHeight, aura_env.this)