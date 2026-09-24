# Combat, encounter and checkpoint design

## Playable campaign

The lobby has no countdown: each connected player chooses a hero and presses Ready. All connected players must be ready; a solo player can begin immediately. New players joining an active run enter at the current checkpoint.

The game is a controlled 2.5D co-op brawler: move right through three 180-stud districts while clearing four encounters in each. The lane is z=-14..14 and the continuous floor top is y=0. Players build damage percent and launch curses with stronger knockback as percent rises. Each hero has three stocks, a three-hit light chain, heavy launcher, a distinct special, directional guard, dodge dash, and one airborne recovery.

| District | Waves | Miniboss at +75 | Boss at +135 |
| --- | --- | --- | --- |
| Ashgate Crossing, x0..180 | Crossing Under Curse / miniboss / The Alarms Awaken / boss | Crosswalk Executioner | Siren Marshal |
| Abandoned Station, x180..360 | Last Service / miniboss / Platform Zero / boss | Platform Widow | The Last Conductor |
| Abandoned Factory, x360..540 | Cold Furnace / miniboss / Pressure Rising / boss | Furnace Hound | Kiln Sovereign |

Each miniboss and boss has an original R6 silhouette in EnemyFactory and its own deterministic attack pattern in EnemyMoves. No anime character models or animations were copied for the enemies. Reviewed Toolbox keyframes animate the common R6 skeletons. The original launch heroes retain wind rushdown, mechanical long reach and wide blade archetypes under stable IDs Gale, Piston and Tide. Current art and acceptance status are tracked separately.

## Six encounter identities

- **Crosswalk Executioner:** traffic-signal helmet, striped road armor and giant sign cleaver. Alternates a forward cleave with a wide low crossing sweep. The sweep is jumpable; standing in front and trading attacks is punished.
- **Siren Marshal:** navy armor, paired warning beacons and glowing baton. A narrow beam tracks the target lane at warning start, then locks. Alarm pulses are jumpable. Phase two adds two outer-lane beams with a safe center.
- **Platform Widow:** white veiled mask, six rail ribs and a cyan ticket blade. A narrow rail lunge has a fixed route and endpoint; step into another lane. Close ticket cuts and a phase-two ground mark prevent stationary play.
- **The Last Conductor:** peaked cap, long coat and clock staff. A ghost train covers one entire lane through the station. Players change depth rather than outrun its length. Phase two attacks the outer platforms together; the central platform remains safe. A low bell pulse can be jumped.
- **Furnace Hound:** metal carapace, furnace maw, large claws and glowing spine. A marked pounce lands at the player's old position; move after the warning. A narrow cinder lane and close bite alternate with the pounce.
- **Kiln Sovereign:** broad furnace torso, glowing heart behind an iron grate, smokestacks and forge gauntlets. Forge marks appear at separated party positions, encouraging players to spread. Vents deny one side of the lane. Phase two combines outer vents with a local jumpable pressure wave, leaving distant central space safe.

All elite phase changes occur at 52% of their defeat threshold and change the move pattern rather than healing or greatly inflating resilience. Solo thresholds are 190/280, 205/305 and 220/340 percent. Party scaling is fixed at spawn: +28% per additional player for elites and +18% for normal waves. Existing enemies never regain resilience when somebody joins.

## Telegraph fairness and hitstun

EnemyMoves.Build returns immutable attack footprints captured before the warning begins. The same exact center, box dimensions or circle radius drive the client warning and server hit test. The impact never follows a target after they have dodged. Ground-warning height is 3 studs for jumpable attacks and 16 for other attacks. Contains tests the player's root minus 2.5 studs against that height; a low warning is cleared once rootY exceeds 5.5. Non-jumpable warnings must be sidestepped or dashed. Multiple volumes in one move hit each player at most once.

Elite windups have visible armor. Armor reduces damage by only 10%, limits displacement and prevents light-hit stun chains. Heavy and special attacks build the poise-break meter at full base damage; light hits build it at half damage. Breaking poise cancels that windup and creates a two-second punish window. Normal recovery windows are 0.9-1.45 seconds. Bosses remain damageable throughout. Outside armor, elite hitstun is capped at 0.16 seconds, so one player cannot indefinitely lock a boss by repeating light attacks.

A player gets 0.38 seconds of damage invulnerability after a received hit to prevent several simultaneous enemies from trapping them. A dash can escape hitstun after 0.16 seconds if its cooldown is ready. Up to two enemy warnings may overlap against one or two players, and at most three against larger groups. Enemies prefer recently untargeted nearby players. Normal melee enemies align their lane before committing to an attack.

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
