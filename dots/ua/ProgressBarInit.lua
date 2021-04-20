aura_env.this = WeakAuras.regions[aura_env.id].region
aura_env.spellId = 30405
aura_env.globWidth = aura_env.this.bar:GetWidth()
aura_env.globHeight= aura_env.this.bar:GetHeight()
aura_env.markers = {}
aura_env.snapshots = {}

--create tick markers and snapshot frames
MoreDots.bars.createMarkers(aura_env.spellId, aura_env.markers, aura_env.globHeight, aura_env.this)
MoreDots.bars.createSnapshots(aura_env.id, aura_env.snapshots, aura_env.globWidth, aura_env.globHeight, aura_env.this)