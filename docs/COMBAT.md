# Combat, encounter and checkpoint design

## Playable campaign

The lobby has no countdown: each connected player chooses a hero and presses Ready. All connected players must be ready; a solo player can begin immediately. New players joining an active run enter at the current checkpoint.

The game is a controlled 2.5D co-op brawler: move right through three 180-stud districts while clearing four encounters in each. The lane is z=-14..14 and the continuous floor top is y=0. Players build damage percent and launch curses with stronger knockback as percent rises. Each hero has three stocks, a three-hit light chain, heavy launcher, a distinct special, directional guard, dodge dash, and one airborne recovery.

| District | Waves | Miniboss at +75 | Boss at +135 |
| --- | --- | --- | --- |
| Ashgate Crossing, x0..180 | Crossing Under Curse / miniboss / The Alarms Awaken / boss | Crosswalk Executioner | Siren Marshal |
| Abandoned Station, x180..360 | Last Service / miniboss / Platform Zero / boss | Platform Widow | The Last Conductor |
| Abandoned Factory, x360..540 | Cold Furnace / miniboss / Pressure Rising / boss | Furnace Hound | Kiln Sovereign |

Each miniboss and boss has an original R6 silhouette in EnemyFactory and its own authored move family in EnemyMoves. No anime character models or animations were copied for the enemies. Reviewed Toolbox keyframes animate the common R6 skeletons. The original launch heroes retain wind rushdown, mechanical long reach and wide blade archetypes under stable IDs Gale, Piston and Tide. Current art and acceptance status are tracked separately.

## Six encounter identities

- **Crosswalk Executioner:** traffic-signal helmet, striped road armor and giant sign cleaver. Alternates a forward cleave with a wide low crossing sweep. The sweep is jumpable; standing in front and trading attacks is punished.
- **Siren Marshal:** navy armor, paired warning beacons and glowing baton. A narrow beam tracks the target lane at warning start, then locks. Alarm pulses are jumpable. Phase two adds two outer-lane beams with a safe center.
- **Platform Widow:** white veiled mask, six rail ribs and a cyan ticket blade. A narrow rail lunge has a fixed route and endpoint; step into another lane. Close ticket cuts and a phase-two ground mark prevent stationary play.
- **The Last Conductor:** peaked cap, long coat and clock staff. A ghost train covers one entire lane through the station. Players change depth rather than outrun its length. Phase two attacks the outer platforms together; the central platform remains safe. A low bell pulse can be jumped.
- **Furnace Hound:** metal carapace, furnace maw, large claws and glowing spine. A marked pounce lands at the player's old position; move after the warning. A narrow cinder lane and close bite alternate with the pounce.
- **Kiln Sovereign:** broad furnace torso, glowing heart behind an iron grate, smokestacks and forge gauntlets. Forge marks appear at separated party positions, encouraging players to spread. Vents deny one side of the lane. Phase two combines outer vents with a local jumpable pressure wave, leaving distant central space safe.

All elite phase changes occur at 52% of their defeat threshold and change the move pattern rather than healing or greatly inflating resilience. Solo thresholds are 190/280, 205/305 and 220/340 percent. Party scaling is fixed at spawn: +28% per additional player for elites and +18% for normal waves. Existing enemies never regain resilience when somebody joins.

## Telegraph fairness and hitstun

EnemyMoves.Build returns locked attack footprints captured before the warning begins. Floor markers describe the server damage area using its center, box dimensions or circle radius; ordinary body tells instead show the attacker's anticipation pose and flash. A traveling projectile uses swept hit boxes contained within its marked corridor. The impact never follows a target after they have dodged. Ground-warning height is 3 studs for jumpable attacks and 16 for other attacks. Contains tests the player's root minus 2.5 studs against that height; a low warning is cleared once rootY exceeds 5.5. Non-jumpable warnings must be sidestepped or dashed. Multiple volumes in one move hit each player at most once.

Elite windups have visible armor. Armor reduces damage by only 10%, limits displacement and prevents light-hit stun chains. Heavy and special attacks build the poise-break meter at full base damage; light hits build it at half damage. Breaking poise cancels that windup and creates a two-second punish window. Normal recovery windows are 0.9-1.45 seconds. Bosses remain damageable throughout. Outside armor, elite hitstun is capped at 0.16 seconds, so one player cannot indefinitely lock a boss by repeating light attacks.

A player gets 0.38 seconds of damage invulnerability after a received hit to prevent several simultaneous enemies from trapping them. A dash can escape hitstun after 0.16 seconds if its cooldown is ready. The launch director reserves at most living players +1 concurrent attacks, from two solo to five with four living players; a reservation includes its attack and recovery. Enemies prefer recently untargeted nearby players. Normal melee enemies align their lane and assigned side before committing to an attack. The earlier two/three-warning cap is retained as a superseded tuning idea, not the current rule.

## Checkpoints, stocks and rewards

Exceed the x blast margins, fall below the floor, or reach 200 percent to lose one stock. Stock respawns take 1.15 seconds and grant two seconds of protection. Zero stocks makes the player a spectator until a district reset. The current checkpoint moves from the entrance to x=stageMin+92 after the miniboss is defeated. A party wipe retries from that checkpoint's wave: wave1 at the entrance, or wave3 after the miniboss. Three stocks restore on a checkpoint retry or new district, not immediately after every enemy or wave.

After each cleared wave, a four-to-five-second safe intermission permits hero and boon changes. Then Traverse waits until every living player reaches max(stage.SpawnX, nextWave.SpawnX-25), so the next encounter cannot simply rush a party camping at the entrance. The walking ceiling expands to currentWave.SpawnX+30; updating it never pulls an already-forward living player backward. Only retries and district transitions teleport the party.

The curtain is visual and non-solid: server bounds prevent walking past the district while temporary launch windows preserve ringouts. After the district boss is cleared, its curtain opens. Every living teammate must rally within 12 studs of the right edge before the next district begins. Downed spectators do not block the rally. A new arrival gets the current checkpoint and participates immediately; party scaling takes effect on the next wave. Joining does not silently restart a defeated party.

Same-campaign reconnects preserve stocks, percent, hero, cooldown deadlines and run statistics by UserId. A downed teammate remains downed after reconnecting. Leaving during a stock respawn preserves the already-deducted stock and completes its normal zero-percent respawn. Legitimate checkpoint resets restore disconnected teammates too. The cache is capped at256 inactive UserIds and is cleared on a new campaign or empty-server lobby reset. A truly new late joiner still receives three stocks. See tests/MultiplayerLifecycle.md for the two-client regression sequence.

Participation rewards go to players who dealt damage, received damage or blocked an attack in that wave. Stable campaign:stage:wave reward keys survive checkpoint retries, preventing repeat clear rewards for the same encounter. A fresh full campaign gets new keys. ProgressionService owns actual coin/XP grants, saves and safe-area boon changes. Combat only consumes its four bounded modifier fields. Hero switching is also limited to safe periods, preserving percent and cooldowns.

## Runtime mapping and APIs

Map src/shared to ReplicatedStorage.Nightfall.Shared and src/server to ServerScriptService.NightfallServer. Build the world and workspace.Enemies first. Initialize ProgressionService, CombatService, then EncounterService. CharacterFactory.Create(hero) and EnemyFactory.Create(kind,spec) return original R6 models. Player hitboxes use the audited ToolboxHitbox.Query module. Heavy and special impact callbacks retain the DestructionService hook for explicitly tagged cosmetic props.

Combat exports Init, GetSnapshot, BroadcastState, SetEncounterState, SetArena, SetWalkingLimit, SetCheckpoint, ResetPlayers, BeginRun, BeginEncounter, GetParticipants, AddCoinsEarned, GetAlivePlayers, GetPlayerCount, GetEnemies, SpawnEnemy, ClearEnemies, ApplyHit, SetRestartCallback, SetReadyCallback, GetReadyCount, ClearReady and ResetLobby. Encounter exports Init and Restart. There are no client-accessible debugging, spawning or reward functions.

Client Action payloads remain Light/Heavy/Special/Dash/Block/Recovery/Jump/SelectCharacter/Restart/Ready with direction=+1/-1, held=true/false, hero=Gale/Piston/Tide, and ready=true/false. Ready is accepted only in Waiting. The server validates types, action names, damage ownership, cooldowns and a 30-requests-per-second budget. Clients never send targets or damage numbers.

Snapshot adds ready/readyCount/playersTotal, targetX/objective/walkingMaxX, and boss=false or {name,kind,percent,threshold,phase,role,poise,poiseLimit,armored,exposed}, waveTitle, encounterName, encounterKind, nextWaveAt, checkpointLabel, resultReason, and runStats={kills,damageDealt,damageTaken,coinsEarned,duration}. nextWaveAt and cooldowns are workspace:GetServerTimeNow timestamps. Bosses also expose Role/Phase/Poise/PoiseLimit/Armored/Percent/PercentLimit attributes. Hit FX has exact targetModel and targetUserId. New FX include StageIntro, Checkpoint, BossStagger and EnemyImpact. Telegraph and EnemyImpact carry the same footprint fields: position, shape, size, radius, height, jumpable, color and mechanic.

## Verification gates

Run EnemyMoves tests for lane gaps, circle edges, fixed positions, the jump threshold, four-player mark deduplication, and structural move invariants. In Studio test each elite's phase one and phase two, poise breaks, guard direction, recovery, stock respawn, ready cancellation, party-ready departure, both checkpoint retries, each within-district Traverse threshold, stage rally, late join and departure, a full run, and a fresh run after victory. Verify no duplicate rewards after retry. Test actual multiplayer before claiming multiplayer quality or parity with the requested Roblox combat-quality benchmark. Source review and single-client runtime checks do not establish that quality claim.

References: [Roblox spatial queries](https://create.roblox.com/docs/reference/engine/classes/WorldRoot), [Humanoid movement](https://create.roblox.com/docs/reference/engine/classes/Humanoid), [network ownership](https://create.roblox.com/docs/physics/network-ownership).


## Launch director implementation (WO-2.2)

Normal simultaneous attack reservations are living players +1 (2 solo to5 with four). Slots favor opposite X occupancy within35studs. Approach reservations last3s; a started windup extends its lease through recovery. Stagger, target departure, and cap shrink cancel captured attacks before releasing capacity. Grunts reach the assigned side before attacking. Hold shuffles by2.5studs inX and3 inZ rather than standing still. Every real windup is clamped to at least0.30s. Grunts use an anticipation pose and body flash; elite/area floor warnings remain. Cosmetic feints do not apply damage.

Scheduler and mocked movement regressions passed in Studio; five-run campaign telemetry and actual camera-frustum/human verification remain pending. The previous pure extraction comparison is preserved in tests/fixtures/wo-2.1 and is intentionally not a current behavior-equivalence gate after this change.


## Launch archetypes and final starting values (WO-2.3)

These are the implemented values at `f4c32be` on 2026-09-24. They are starting tuning values, not a measured difficulty certification. Six original ordinary-enemy silhouettes replace interchangeable melee behavior; Brute retains a seventh behavior policy. Older `Grunt` and `Runner` keys map to Husk and Strider for compatibility. Wave enemy counts remain unchanged. Husk weapon pickup is explicitly deferred to WO-4.3 rather than claimed here.

| Stable kind | Speed | Defeat percent | Base damage | Base cooldown | Readable behavior |
|---|---:|---:|---:|---:|---|
| Husk | 12 | 56 | 9 | 1.85 s | Close two-part jab; jump kick beyond 9 studs; worn wraps and asymmetric jerkin |
| Strider | 18 | 48 | 8 | 1.60 s | Slide from 9 studs or more; close jab; shin plates and heel boosters |
| Grappler | 10 | 82 | 12 | 2.10 s | Guard-punishing capture and alternating back throw; broad grip gauntlets |
| Pitcher | 13 | 50 | 10 | 1.90 s | Retreat inside 12 studs, seek 17-stud spacing, throw at range and shove when cornered; rod bandolier |
| Warden | 10 | 72 | 11 | 1.95 s | Front light guard and delayed third-chain counter; shield forearms |
| Leaper | 16 | 54 | 9 | 1.80 s | Vault behind the target, alternate close jab, react to observed heavies; arched crest and heels |

Base damage is multiplied by each move's volume multiplier and existing defense rules; the cooldown alone is not the full attack cycle. The next attack also waits for resolution, recovery and the director reservation. Speeds are studs per second. Defeat thresholds receive the existing spawn-time party scaling.

| Move IDs | Warning before launch/hit | Travel or second warning | Recovery |
|---|---:|---:|---:|
| HuskJab | 0.48 s | Second jab warned for 0.46 s | 0.55 s |
| StriderJab / LeaperJab | 0.48 s | None | 0.55 s |
| HuskJumpKick / LeaperVaultKick | 0.60 s | 0.38 s flight; landing marker lasts 0.98 s total | 0.85 s |
| StriderSlide | 0.55 s | 0.32 s travel; jumpable path marker lasts 0.87 s total | 0.75 s |
| GrapplerGrab / GrapplerThrow | 0.65 s | Capture lasts 1.00 s before its throw | 1.25 s |
| PitcherThrow | 0.45 s | Projectile travels for 0.50 s after warning completes | 0.80 s |
| PitcherShove | 0.40 s | None | 0.65 s |
| WardenCounter | 0.40 s | None | 0.70 s |
| WardenKick | 0.60 s | None | 0.70 s |
| BruteFlop | 0.90 s | 0.42 s flight; landing marker lasts 1.32 s total | 1.15 s |
| BruteSwing | 0.90 s | None | 0.95 s |

All real attacks retain the global 0.30-second minimum. Ordinary close attacks use an anticipation pose plus body flash; travel and area attacks use floor markers. Projectile origin and endpoint are captured before the warning, and server Heartbeat damage sweeps the traveled segment. The fixed warning includes the four-stud projectile body in both X and Z, including the diagonal created by clamping a lane-edge endpoint. Damage starts after the 0.45-second warning rather than waiting for the whole projectile flight. Review corrected both early-warning countdown ambiguity and unwarned endpoint/lane padding; the regression covers Z=-12 and Z=12.

The AI samples accepted player actions and block state with a 0.35-second observation delay. Warden blocks front-facing lights for 20% damage; a heavy suppresses its guard for 1.10 seconds. Grappler takes 90% light damage without light-hit stun/launch, preserving heavy/special counterplay. Leaper evades every third observed heavy, with a 0.50-second evade and 0.35-second invulnerability; this delayed response cannot retroactively dodge the already-resolved 0.30-second heavy. Brute armor applies during its committed attack. Strider's post-slide retreat is 1.20 seconds and Pitcher's post-shove retreat is 1.30 seconds after recovery.

Grappler capture is unblockable: the initial grab deals 20% of base damage and a still-valid throw adds 80% after one second. An accepted ally hit on the captor releases the victim immediately. Attack serial, battle epoch and victim life checks prevent a canceled capture from applying its old delayed throw. Enemy removal, campaign clearing and invalidation release held victims; clients cannot declare their own capture or damage.

The server rejects attacks outside a conservative estimate of the campaign camera: 44-degree field of view, supported aspect ratio at least 9:16, four-stud inset, party goal and smoothed center checks, and distance clamped to 52-140 studs. This is an estimated attack-permission envelope, not proof of every client's actual view. `EnemyFrustumAudit.client.lua` separately projects the attacker through the victim's real camera at Hit receipt; no actual zero-offscreen-hit result is claimed by the projection math alone.

Root recorded the following actual Studio evidence for this work order: fourteen moves/seven policies and boundary geometry passed; six enemy rigs contained 19-22 parts with seven queryable core parts and six motors; thirty client pose/cancel/cleanup checks passed; the actual two-client scripted capture fixture passed ally rescue, canceled throw and unrescued timed-throw cases. The rescue fixture applies a server-side ally hit directly, so it is not human input/range validation. Source was independently reviewed. Five-run campaign comparison, actual frustum results, a four-player/twelve-enemy MicroProfiler capture, human readability and device play remain open. See the dated work-order ledger in [PROGRESS.md](PROGRESS.md) for the current acceptance state.


## Elite decisions and phase pressure (WO-2.4)

Implemented at `b37549c`. Elites now select weighted moves rather than repeat the old fixed rotation; those old rotations remain preserved in Config as the source move pools. Close moves start with weight 5 within reach and 0.25 beyond it; ranged/area moves start at 1.5 nearby and 4 beyond reach. Two or more players in the target lane multiply area weight by 1.6. A repeated move receives a 0.25 multiplier. The signature gets double weight when available and an eight-second cooldown; observed airborne state reduces selected jumpable moves to 0.35 weight. Airborne/action observations retain the 0.35-second delay. Server random rolls select from the pool, with deterministic injected rolls used by specs.

Phase two begins at 52% of the defeat threshold and issues a one-time pair of Husk side entrants. During phase two, an eligible ordinary attack has a 20% feint chance, limited by a six-second feint cooldown. A feint lasts 0.40 seconds, deals no damage, recovers for 0.20 seconds and does not count as use of a desperation move. At 80% of the defeat threshold, each elite may select its own desperation once; it bypasses feint selection and retains a long floor warning and punish window.

| Elite desperation | Warning | Recovery |
|---|---:|---:|
| CrossroadRuin | 1.15 s | 1.45 s |
| AlarmCollapse | 1.20 s | 1.50 s |
| WidowSpiral | 1.20 s | 1.40 s |
| FinalDeparture | 1.40 s | 1.60 s |
| CinderHowl | 1.10 s | 1.40 s |
| CoreMeltdown | 1.40 s | 1.65 s |

Root recorded six-elite weighted-policy specs and actual phase-two two-summon, one-shot, entry-grace, harmless-feint and desperation-start fixtures as passing. These fixtures establish those branches; full campaign variety, difficulty and human readability remain M2 acceptance work.

## Wave pulses and authored entries (WO-2.5)

Implemented source keeps the existing per-kind enemy counts and per-kind co-op addition of `floor((partySize-1)*0.5)` for skirmishes. Party size, total spawn budget and resilience scaling freeze when the wave begins, so a late join cannot enlarge a reserved pulse or heal an existing enemy. Skirmishes use two pulses, or three when the frozen budget is at least six. The next reserved pulse arrives when at most one enemy remains or twelve seconds have elapsed since the previous pulse, provided someone is alive. Zero current enemies cannot clear a wave while any planned pulse remains. Campaign-generation checks cancel stale pulse work on resets.

Every wave has the Left/Right/Door/Drop entry list and pulse settings in Config. Skirmish entries cycle through that list; the first entrant is forced to Left for one or two players. Left placement is relative to the leftmost living player, 14 studs behind with a 0/2/4-stud stagger, clamped inside the arena and walking ceiling. Right placement uses the rightmost player plus 18 studs and that stagger. `RearEntryAchieved` records whether the actual spawn is more than three studs behind the party minimum. A player pressed against the arena's left edge prevents this guarantee; source does not claim a rear spawn in that case.

Elite waves begin with a Door entrance and use their one-time phase-two pair as the separate reinforcement group, rather than an ordinary timer pulse. This interprets the elite rear-entry requirement through the phase-two summon. An elite defeated before phase two does not produce that rear entrant, so it is not unconditional every-wave rear-entry evidence.

Door markers are floor coordinates; Drop starts at Y=14 before the rig root-height offset. Every entry has at least 0.60 seconds of attack grace. Drop also waits for actual Humanoid grounding; an `entryComplete` latch prevents later combat launches from replaying the entrance state. Existing attack cooldown and on-screen permission checks still apply after entry. Markers and native non-queryable doorway geometry are documented in [WORLD_BIBLE.md](WORLD_BIBLE.md).

The pure planner spec covers all twelve waves at one through four players, conserving each archetype budget and testing four pulse-trigger cases. The entry runtime fixture is prepared to verify four authored markers, a rear entry at mid-arena, initial grace and Drop grounding. Source review passed; root runtime results and the five-run campaign/frustum/human comparisons must be recorded in PROGRESS before treating these as measured gameplay evidence. The authored-marker structural test is separate from pulse behavior and visible composition approval.
