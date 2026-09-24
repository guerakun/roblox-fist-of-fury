# AGENTS.md: Curtain Break launch program

Codex reads this file automatically. It governs every agent working in this repository until the launch program in `docs/launch/LAUNCH_PLAN.md` is closed.

## Mission
Take Curtain Break from "playable development slice" to a publicly launchable Roblox experience. The owner (Faisal) approved four directions on 2026-09-23:

1. **Fully original heroes.** Remove every Naruto / One Piece / Demon Slayer name, likeness, mesh and reference. Keep the three move archetypes.
2. **Bare Knuckle-grade enemy AI.** Enemies must surround, flank, feint, retreat, grab, jump in and punish, not queue up and stand still.
3. **Lobby + matchmaking multiplayer.** A hub place with parties and quick match that teleports groups of 1 to 4 into reserved campaign servers, plus the unrun co-op test harnesses.
4. **Real challenge and risk/reward.** Stakes that carry between encounters, opt-in difficulty with better rewards, and score/rank that pays for skillful risk.

Read `docs/launch/LAUNCH_PLAN.md` before starting any work order. Work orders are numbered (WO-1.1, WO-2.3, ...). Do them in milestone order unless the plan marks them parallel.

## Team and file ownership
Keep the overnight structure. One owner per file at a time; ask the owner before editing their file.

| Role | Owns |
|---|---|
| **root** (integrator) | `Config.lua`, `ProgressionService`, `ProfileStore`, `Bootstrap`, new `src/hub/**`, `src/server/Matchmaking*`, place builds, GitHub, Studio validation |
| **combat** | `CombatService`, `EncounterService`, `EnemyMoves`, new `EnemyAI.lua`, `AttackDirector.lua`, `CombatTelemetry.lua`, `tests/*AI*` |
| **presentation** | `src/client/**`, `CharacterFactory`, `CharacterArt`, animations, VFX, HUD, telegraphs |
| **world** | `WorldBuilder`, `DestructionService`, `EnemyFactory` visuals, story/docs text, IP scrub of docs, independent review |

`CombatService.lua` is the collision hotspot. WO-2.1 extracts enemy AI into its own modules first so combat and presentation stop colliding.

## Non-negotiable rules
- **No franchise IP anywhere**: names, likeness (hair, outfits, scars, whisker marks, straw hat, checkered haori, headband plates), move names, story text, thumbnails, keywords, commit messages. Grep gate in WO-1.5 must return zero hits.
- **Server authority stays.** Clients request actions; the server decides hits, rewards, matchmaking and teleports. Never trust TeleportData alone; the match record in MemoryStore is the source of truth.
- **Money never buys power.** Coins are earned only. Heat/difficulty rewards are coins, XP, cosmetics, badges and leaderboard score.
- **Fairness contract for enemies**: every enemy attack is telegraphed (pose + flash or floor marker) for at least 0.30 s, and no enemy attacks from outside the camera view.
- **Evidence policy (unchanged from overnight):** record actual tests separately from planned tests. "Implemented in source" is not "verified". Each work order closes only with the evidence listed in its acceptance block, appended to `docs/PROGRESS.md` with date, commit hash and numbers.
- **Numbers in the plan are starting points.** Tune them, but record final values and why in `docs/COMBAT.md`.
- **Keep history.** Don't delete design ideas; move superseded material to a "Preserved ideas" section.
- Commit per work order: `WO-x.y: <summary>`. Rebuild `places/CurtainBreak.rbxl` from source at each milestone end.

## Definition of done for the whole program
All gates in `docs/launch/LAUNCH_PLAN.md` section 8 are checked with evidence, the owner has played one full human co-op session on Normal and one on Hard, and the owner has approved the hero names and art.
