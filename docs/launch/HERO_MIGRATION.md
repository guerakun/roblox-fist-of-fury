# Retired hero identifier migration

Candidate names remain pending owner approval. Stable IDs are Gale/Piston/Tide; display labels are Rook Calder/Bo Marlowe/Isla Veyra and live only in Config character metadata.

The retired prototype identifiers Naruto/Luffy/Tanjiro may exist in old local records or a previously saved profile. `Config.NormalizeHeroId` maps their lowercase DJB2 fingerprints to the stable IDs. This is compatibility parsing, not retained character content: old display labels and likenesses are removed from production code/art. The historical strings are retained only in this exempt launch documentation and `LegacyHeroFixtures.lua`, which is excluded from the production project. The automated gate still rejects these strings everywhere it scans.

`ProfileStore.Sanitize` normalizes `raw.hero` and adds a Gale default when absent or invalid. Combat must normalize its default and reconnect record as part of the atomic ID cutover. This does not touch live DataStores tonight, rename the DataStore, alter combat values, or grant purchases. No imported retired hero assets are licensed or retained by this migration.

The migration spec tests each old value, current IDs, malformed/default cases, profile coin preservation, distinct display labels and unchanged kit numbers. Executed in fresh Studio play after the extraction comparison: PASS. ProfileStore (11 adapter calls) and EnemyMoves (38 patterns) also passed. Ordinary client SelectCharacter request produced a Tide snapshot. This validates identifier routing, not final original artwork.
