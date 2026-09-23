# Validation record — 2026-09-23

## Completed in Roblox Studio
- Edit-time build: 2,162 authored city descendants after prop grouping. All three district gates and continuous lane generated.
- Rojo 7.7.0 builds `default.project.json` successfully.
- Integrated play starts without game-script console errors after enemy-container initialization fix.
- `tests/StudioSmoke.lua`: PASS world, increasing percent knockback, weight resistance, NaN direction fallback, blast boundaries, imported Toolbox clips, sanitized VFX and all three R6 hero rigs.
- Actual client Action remote Light hit: enemy percent 0 → 8.
- Burst of 100 Light requests: enemy percent 8 → 16, exactly one additional accepted hit. Invalid action/NaN direction produced no console error.
- Hero select changed Naruto → Tanjiro and instantiated R6 model.
- Blast boundary test: stocks 3 → 2 → 1 → 0; zero stocks produced Downed=true and Defeat.
- Actual client Restart remote restored three stocks and encounter play.
- Forced progression harness traversed all 9 waves and 3 stages to Victory. Gates 1/2 reported Opened=true and Transparency=1. This forced enemy KOs/rally positioning; it proves transition logic, not normal-input completion or balance.
- Runtime-only validation scripts were discarded when Play stopped. None is in the saved playable scene.
- Editable scene saved as `build/CurtainBreak-Editable.rbxl`.
- Separate Server & Clients session launched. Two actual local clients (Player1 and Player2) joined and received hero/stock replication; further observations below.

## Limits
A normal-input complete campaign, 4-player latency tests, mobile touch ergonomics, hardware-controller testing, long-run performance, disconnect/rejoin permutations and published-universe asset permissions are not certified. Imported audio playback is wired and generated no console errors; listening/mix review remains. No measured claim of Jujutsu Shenanigans parity is made.

## How to repeat
Use [Roblox's Server & Clients mode](https://create.roblox.com/docs/studio/testing-modes), 2 clients, then follow `QUALITY_REVIEW.md`. To repeat pure smoke assertions, load `tests/StudioSmoke.lua` as a ModuleScript and call its returned function in a server session after Bootstrap starts.

## Two-client observation
Player1 and Player2 simultaneously present in a separate local server. Screenshot in docs/media/coop-studio.jpg shows both replicated fighters, enemy warnings and HUD. Both players accrued enemy damage and lost stocks; no client console errors were returned. This is a smoke test of real client replication, not a completed co-op campaign or latency certification.

## Final polish verification
- Actual Space input: root Y 3.00 to peak 11.20. Explicit Humanoid jump transition fixes the input bug.
- Actual client Heavy request broke UtilityAssembly_115 after server windup.
- Destruction stress: all 21 props hidden completely, 30 debris cap respected, every fragment non-collidable/non-touchable/non-queryable. Zero fragments after 2 seconds; all 21 assemblies restored after 21 seconds. This is server testing, not a new two-client destruction test.
- NarutoSpecial, LuffySpecial and TanjiroSpecial instantiated from cosmetic FX events without script errors.
- Automated client action driver defeated all first-district waves in 55 seconds using normal attack requests, no forced KOs: 3 stocks, 18% damage, Advance state. Actual D movement subsequently reached the rally and advanced to district 2. This is not a human-input full campaign.
- One-desktop sample: 3,311 frames; mean 16.666 ms; maximum 42.815 ms. Not a mobile/latency/production certification.
- Updated Rojo build passed. Runtime-only harnesses discarded before final editable-place save.
- Independent combat-agent review of the final client/world changes found no material blocking bugs; no new multiplayer verification claimed.
