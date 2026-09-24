# Validation record — 2026-09-23

## Completed in Roblox Studio
- Edit-time build: 2,162 authored city descendants after prop grouping. All three district gates and continuous lane generated.
- Rojo 7.7.0 builds `default.project.json` successfully.
- Integrated play starts without game-script console errors after enemy-container initialization fix.
- `tests/StudioSmoke.lua`: PASS world, increasing percent knockback, weight resistance, NaN direction fallback, blast boundaries, imported Toolbox clips, sanitized VFX and all three R6 hero rigs.
- Actual client Action remote Light hit: enemy percent 0 → 8.
- Burst of 100 Light requests: enemy percent 8 → 16, exactly one additional accepted hit. Invalid action/NaN direction produced no console error.
- Hero select changed the retired first kit → third kit and instantiated an R6 model. This does not validate the replacement cast.
- Blast boundary test: stocks 3 → 2 → 1 → 0; zero stocks produced Downed=true and Defeat.
- Actual client Restart remote restored three stocks and encounter play.
- Forced progression harness traversed all 9 waves and 3 stages to Victory. Gates 1/2 reported Opened=true and Transparency=1. This forced enemy KOs/rally positioning; it proves transition logic, not normal-input completion or balance.
- Runtime-only validation scripts were discarded when Play stopped. None is in the saved playable scene.
- Editable scene saved as `build/CurtainBreak-Editable.rbxl`.
- Separate Server & Clients session launched. Two actual local clients (Player1 and Player2) joined and received hero/stock replication; further observations below.

## Limits
A normal-input complete campaign, 4-player latency tests, mobile touch ergonomics, hardware-controller testing, long-run performance, disconnect/rejoin permutations and published-universe asset permissions are not certified. Imported audio playback is wired and generated no console errors; listening/mix review remains. No measured claim of the requested Roblox combat-quality benchmark parity is made.

## How to repeat
Use [Roblox's Server & Clients mode](https://create.roblox.com/docs/studio/testing-modes), 2 clients, then follow `QUALITY_REVIEW.md`. To repeat pure smoke assertions, load `tests/StudioSmoke.lua` as a ModuleScript and call its returned function in a server session after Bootstrap starts.

## Two-client observation
Player1 and Player2 simultaneously present in a separate local server. The historical screenshot showed both replicated fighters, enemy warnings and HUD; it was removed from the current tree because it contains retired character art and labels. The image remains recoverable in Git history. Both players accrued enemy damage and lost stocks; no client console errors were returned. This is a smoke test of real client replication, not a completed co-op campaign or latency certification.

## Final polish verification
- Actual Space input: root Y 3.00 to peak 11.20. Explicit Humanoid jump transition fixes the input bug.
- Actual client Heavy request broke UtilityAssembly_115 after server windup.
- Destruction stress: all 21 props hidden completely, 30 debris cap respected, every fragment non-collidable/non-touchable/non-queryable. Zero fragments after 2 seconds; all 21 assemblies restored after 21 seconds. This is server testing, not a new two-client destruction test.
- The three retired special effects instantiated from cosmetic FX events without script errors.
- Automated client action driver defeated all first-district waves in 55 seconds using normal attack requests, no forced KOs: 3 stocks, 18% damage, Advance state. Actual D movement subsequently reached the rally and advanced to district 2. This is not a human-input full campaign.
- One-desktop sample: 3,311 frames; mean 16.666 ms; maximum 42.815 ms. Not a mobile/latency/production certification.
- Updated Rojo build passed. Runtime-only harnesses discarded before final editable-place save.
- Independent combat-agent review of the final client/world changes found no material blocking bugs; no new multiplayer verification claimed.

## Expanded overnight build — three stages / twelve encounters
The sections above describe the earlier 9-wave city-district slice and retain historical evidence. The current source has four encounters per stage, six elites and 34 destructible assemblies; old counts are not current-build measurements.

- Expanded automated action driver reached Victory through all three stages and all 12 encounters with no forced enemy KOs or player teleportation. Driver elapsed 183.59 seconds; 27 kills, 2,974 damage dealt, 690 coins, final 3 stocks / 50%. Bot uses normal server-validated actions and reads telegraphs automatically; this is not a human playtest. Server run timer/damage-taken includes an earlier idle defeat.
- Expanded one-client frame sample: 11,003 frames; mean 16.687 ms; maximum 67.785 ms on this desktop at Studio rendering level 21.
- EnemyMoves.spec: six rigs / 38 pattern entries, lane gaps, height-aware jump avoidance, punish windows, mark deduplication and 12-wave structure passed.
- ProfileStore.spec: failed-load protection, session lease contention, per-load unique tokens, expiry/lost lease, schema/sanitize and recovery checks passed against an injected fake adapter.
- ProfileConcurrency.spec: delayed 16.2-second autosave followed by a newer mutation and Release preserved the newer 99-coin state and released the lock. This does not certify live network/DataStore behavior.
- Practice progression: duplicate encounter rewards and duplicate tier claims rejected; valid cosmetic purchase/equip and earned Haste succeeded; forged premium coin purchase, NaN and out-of-range tiers rejected.
- P journal input and Enter Ready input worked in Studio.
- Generated station MaterialVariant first exposed a PluginSecurity-only BaseMaterial assignment. Fixed by serializing MaterialService configuration and skipping runtime creation; subsequent startup/build succeeded.
- Three new Toolbox audio IDs preloaded successfully in Edit mode. Live experience permissions and audible mix remain unverified.

Raw first expanded campaign report: [test-results/first-expanded-campaign.json](test-results/first-expanded-campaign.json).

## Current validation gaps
Expanded two-/four-player full-campaign completion, actual reconnect lifecycle after the new survival fix, hardware gamepad/touch ergonomics, live persistence and purchase recovery still require evidence. Publication readiness tracks the final gates. Source fixes after the recorded campaign must be synced to Studio and included in a saved-place milestone before they count as the delivered build.

## Handoff verification and untested additions
Before the usage interruption, a fresh integrated phone session started without game-script errors, all four stage/music Sound objects loaded, the journal exposed 44px touch controls and a 606x158 scrolling area on the iPhone 7 preset, and an open loading journal closed on a canEquipBoon=false snapshot. A duplicate free-track cosmetic refund was verified once. These are simulator checks, not hardware certification.

The final ShareStock integration, expanded 2-to-4-client harness, reconnect scenarios and scene memory/rendering checks were not executed. The handoff place was rebuilt successfully with Rojo from source; this does not replace runtime verification of the latest changes.
