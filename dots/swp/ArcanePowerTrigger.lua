function(event, spellId, destGuid, snap)
    if snap ~= nil and snap["Arcane Power"] and MoreDots.dots.allDots[spellId] == "Shadow Word: Pain" then
        return true
    end
    
    return false
end