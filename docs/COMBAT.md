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

Root recorded actual WO-2.5 checks at checkpoint `97590bc`: 48 wave/party budget cases and four pulse triggers passed; rebuilt-world structure passed with twelve groups, 48 markers and 60 doorway parts; fresh Play passed four entry kinds, mid-arena rear placement, initial grace and Drop grounding; client checks passed thirty poses and four entry cues. The anchored Drop fixture required restoring server network ownership after unanchoring; its initial fixture failure and corrected fresh run are preserved in `docs/launch/evidence/entrances-runtime.json`. These are separate structural, policy and scripted runtime results. Full campaign pulse behavior, five-run comparisons, actual camera-frustum results, visible composition and human acceptance remain open in PROGRESS.


## Difficulty profiles and action-diversity measurement (WO-2.6)

These are implemented starting values, pending the milestone's measured difficulty curve. Difficulty is a server-owned campaign option. Unknown tier names and all nonempty Heat requests are rejected until M3 implements Heat. Once the encounter leaves Waiting, a late arrival may confirm the same difficulty but cannot change it. A fresh empty-server lobby resets to Normal; checkpoint retries preserve the current run option. Tier availability in the hub still requires the separate earned-unlock work.

| Tier | Aggression | Extra tokens | Reaction delay | Evade quota | Initial windup scale | Elite threshold scale |
|---|---:|---:|---:|---:|---:|---:|
| Normal | 1.00 | 0 | 0.35 s | 1/3 | 1.00 | 1.00 |
| Hard | 1.20 | 1 | 0.22 s | 0.45 | 0.85 | 1.15 |
| Nightmare | 1.40 | 2 | 0.18 s | 0.60 | 0.72 | 1.30 |

Aggression divides the authored base cooldown. Resolution and recovery still impose their existing lower bound, so it does not shorten every attack cycle by that full ratio. Initial enemy warnings are scaled and then clamped to at least 0.30 seconds; authored follow-up warnings and harmless feints retain their own timing. Attack reservations use living players +1 plus the tier token bonus, consistently at grant, cap shrink and telemetry checks. Elite resilience composes with frozen party scaling; it does not increase ordinary-enemy thresholds. These knobs affect challenge only and are not sold.

Leaper evade probability is implemented as a deterministic accumulated quota over observed heavies, preserving Normal's every-third-heavy behavior. Hard and Nightmare use their configured quotas; they do not gain immediate knowledge of an unobserved player action. The changed reaction delay is still sampled through the AI update cadence. No human fairness, tier clear-rate or difficulty acceptance is inferred from these numeric settings.

Action-diversity telemetry adds per-actor 30-second windows while an enemy is sampled within 28 horizontal studs of a living player, excluding Enter. Sampling occurs at the AI's approximately 10 Hz cadence, so this is a sampled engagement definition, not continuous-position proof. Stun and recovery time remain part of an otherwise engaged window. Leaving range, removal or inactive combat closes the window using its last observed time; intermission time is not added. Partial and still-pending windows are reported separately and never treated as passing coverage.

A window's action set records actual windup starts, elite feints, held Warden block, evade, retreat and the attempted delayed throw. Grab windups and successful captures share the single action label Grab, so one grab cannot gain two distinct actions from its windup and capture hooks. Approach, Hold, Engage and Enter labels do not count as distinct actions. Repeated uses of the same action count once. Results include eligible/passing windows, minimum distinct actions and the underlying action lists by kind. At least two distinct actions qualifies one eligible window. Zero eligible windows means insufficient observation, not a passing archetype; short-lived enemies need additional observed engagements before claiming that acceptance gate.

Prepared specs cover the final warning floor across three tiers and three hypothetical Heat scales (54 cases), twelve party/tier token caps, nine Normal evade decisions, invalid options and full/partial action-window reporting. The runtime fixture checks active-option immutability and actual elite/ordinary threshold composition. Root must record their actual results and the five-run HumanBot comparisons in PROGRESS. These source/spec descriptions do not replace actual camera-frustum evidence, human testing or the four-player/twelve-enemy MicroProfiler capture.


### M2 crowd diagnostic follow-up (2026-09-24, acceptance still open)

The first four-client/twelve-enemy stationary crowd capture recorded 38 complete AI-step scopes averaging approximately 0.2856 ms, with a 0.5051 ms maximum, below the 1.5 ms numerical target. This is inclusive `aiStep` CPU work, excluding the adjacent telemetry sampler; it is not whole-Heartbeat time, phone frame rate or a human challenge result. That initial report checked population at half-second intervals and at capture completion. It therefore retains a sampled-population limitation; it did not verify the capture population requirement. The later Heartbeat-latched rerun below addresses that limitation. Raw timings are preserved in `docs/launch/evidence/m2-microprofiler.json`.

The same stationary crowd diagnostic reported approximately 54.6% idle ticks and multiple engaged windows without enough distinct actions. Those behavior targets failed in that diagnostic even though the numerical CPU target passed. This does not replace the required five campaign HumanBot runs or human run.

The follow-up director source reduces the rear priority bonus from 20 to 4, permits waiting age up to 30 seconds, and resets the scheduling age on each token grant as well as an actual attack. Previously, a rear bonus of 20 plus a waiting-age cap of 20 could indefinitely outrank front attackers; a reservation that never reached attack range did not count as service. Stable slots now revalidate their side against arena bounds so an actor does not repeatedly pursue a clamped destination that cannot satisfy the required side of its target. Cap enforcement, warning floors and camera checks remain authoritative. Dedicated scheduling and arena-edge specs are prepared; reduced idle time and adequate action variety require new runtime evidence.

The updated profiling harness records population on every observed Heartbeat after the explicit absolute-frame capture barrier and permanently records any mismatch for that run. A barrier change also invalidates the run. Capture analysis rejects scope entries before its selected first frame and reports numerical mean success separately from population validity and combined CPU-target success. Harness completion is only an orchestration result. Crowd snapshots at 10, 30 and 60 seconds use run-local `PlayerN` labels to inspect positions, movement intent, slots, reservations and camera eligibility without publishing account IDs.


The scheduling-fix crowd rerun still failed the behavior targets. Evidence files retain both runs rather than replacing the initial failure:

| Stationary crowd diagnostic | Idle ticks | Complete action windows meeting two distinct actions | Meaning |
|---|---:|---:|---|
| Initial | 4,500 / 8,244 = 54.59% | 6 / 24 = 25.00% | Behavior targets failed; population sampled every 0.5 seconds |
| Scheduling-fix rerun | 5,251 / 9,768 = 53.76% | 11 / 35 = 31.43% | Behavior targets still failed; Heartbeat population validity passed |
| Settled-party, camera-safe movement rerun | 2,154 / 8,164 = 26.38% | 20 / 33 = 60.61% | Improved but idle remains above 15%, and action-window coverage is incomplete |

The later frozen CPU snapshot contains 39 complete calls averaging **0.26599 ms**, maximum **0.43663 ms**, with 1,134 population checks and zero mismatches. Its regular frames are 1228-1483 (absolute frames 6288-6543). Both the numerical CPU target and observed-Heartbeat population validity passed in `docs/launch/evidence/m2-microprofiler-valid.json`. These timings describe this stationary scenario, whose suppressed attack activity makes it insufficient evidence of peak combat workload; phone performance and the full M2 acceptance remain open.

Snapshots at 10, 30 and 60 seconds in `docs/launch/evidence/m2-crowd-fairness.json` show one player at the checkpoint near X=28, while the other three are near X=86-118. The resulting camera center near X=65-73 rejects attacks by most enemies on the party's right. Source inspection supports a fixture initialization race: `GetAlivePlayers` can observe a newly assigned living model before its `CharacterAdded` setup resets its position. The fixture's early reposition may then be overwritten by that setup. This is a supported explanation, not an observed event trace or permission to discard the failed measurements. The revised fixture now allows two seconds for setup, repositions the party, then verifies unchanged character identities and every player within two studs of X=90 after another second before creating enemies. This fixture change was source-reviewed and used in the corrected runtime scenario described below. The separately reviewed camera-safe movement source now projects walking goals into the intersection of the existing goal and smoothed camera envelopes, without widening attack permissions. Offscreen actors release attack reservations while repositioning; an impossible melee approach cannot reserve capacity merely because its actor is visible. Stable slots refresh approach feasibility, and Hold shuffle measures distance to the projected goal. Reposition is explicitly excluded from distinct-action counts. Root recorded passing Studio results for eighteen geometry cases, AI entry/impossible-approach checks and the director/action-diversity regressions. The corrected crowd results below still leave behavior acceptance open; the actual-camera audit remains a separate gate.


The settled-party, camera-safe movement run is preserved in `docs/launch/evidence/m2-crowd-camera-safe.json`. Idle improved to 26.38%, while 20 of 33 complete action-diversity windows passed. Both remain short of the behavior targets; a bounded Hold-movement improvement is being evaluated separately. The diagnostic recorded 48 of 76 flanking windows (63.16%) and zero token-cap violations. This four-client result does not directly satisfy the plan's solo-player flanking criterion. Comparing these runs also includes a fixture-placement correction, so it does not isolate the causal effect of the camera movement change alone.

Its latest frozen CPU snapshot, `docs/launch/evidence/m2-microprofiler-camera-safe.json`, contains 39 complete calls with a **0.41560 ms mean** and **0.64892 ms maximum**, with 1,069 population checks and zero mismatches. The analyzed regular frames are 1069-1324 (absolute frames 6521-6776). Numerical CPU and observed-population checks passed, separately from the still-failing behavior targets and all human/device gates.

At checkpoint `a129630`, the client frustum observer now waits for a viewport larger than 1x1 and refreshes its geometry fixture at every received enemy Hit. Invalid current viewports increment `invalidViewportHits` and return before adding an audited hit, so an earlier valid fixture cannot silently certify an invalid later projection. Each accepted event records its actual width and height. This test-only change passed source review; it does not certify prior runs that used the old startup fixture. A complete audit must report invalid-sample count alongside outside hits and audited hits. Measurement remains attacker position through the victim's actual camera at Hit receipt, not an instrumented server-time camera reconstruction.

Root will save the M2 engineering and five-run bot checkpoint before continuing source implementation. That sequencing decision does not close M2 acceptance: unmet telemetry targets, actual-camera coverage, the human run and device checks must remain visible in PROGRESS and the launch checklist. No milestone should be described as fully accepted from a source checkpoint alone.


The next bounded source tuning replaces tiny continuously changing Hold destinations with four fixed offsets: (+2.5,+3), (-2.5,-3), (+2.5,-3), (-2.5,+3) in X/Z. Waypoints refresh on arrival within 0.8 studs, after 1.2 seconds or when the slot center moves more than three studs; selection prefers at least 2.5 studs of travel when the constraints permit it. Hold enters within five studs and retains its state within eight to reduce state oscillation. Only Hold uses direct Humanoid movement toward the waypoint; destinations remain lane/arena bounded and camera projected. These are physical movement changes, not a redefinition of idle time.

After a valid resolved attack, ordinary roles receive these spacing sequences:

| Role | Resolved move | Spacing/follow-up |
|---|---|---|
| Husk | Jab | Backstep for 0.85 s toward a 12-stud offset, then jump kick; jump kick queues jab |
| Strider | Jab | Backstep 0.75 s toward 13 studs, then slide; slide backsteps 1.2 s toward 15 studs and queues jab |
| Leaper | Jab | Backstep 0.65 s toward 12 studs, then vault kick; vault kick queues jab |
| Pitcher | Throw | Backpedal 0.65 s toward 20 studs; shove backpedals 1.3 s toward 17 studs and queues throw |

Offsets are movement goals, not guaranteed traveled distances; arena/camera constraints and interruption still apply. The next move is assigned only after valid resolution and consumed at the next real attack start. Warden and Grappler keep their reactive policies. Retreat enters the diversity set only when actual X velocity away from the target exceeds 0.5 studs/second; merely naming a stationary state Retreat no longer counts. Source and independent review passed. Root's actual Studio physical-footwork fixture measured 24.6827 studs of travel, ten Hold samples and a jab-then-jump sequence; its initial jab is test-seeded, while the follow-up comes from resolved server policy. The travel sum covers the observation interval, not only samples labeled Hold. Crowd idle/diversity improvement still requires the next evidence. Source is frozen at `9f29012` for the five-run bot series.


### Final frozen M2 HumanBot comparison (2026-09-24)

Five solo sessions on gameplay `9f29012`, bot policy `b21b807`, seeds 1101–1105 and actual-camera observer `a129630` all cleared. World independently reconciled raw reports against [M2_EVIDENCE](launch/M2_EVIDENCE.md) and its linked aggregate: mean 398.561898 seconds, 2.8 stocks lost and 830.4 floored snapshot damage, versus baseline 278.267885 seconds, .8 stocks and 543 damage. Pooled eligible idle is 795/8299 = 9.57947% versus 593/3684 = 16.10%; qualified solo flanking is 108/112 = 96.42857% versus 15/33 = 45.45%. Token-cap breaches remain zero. No gameplay tuning changed during this five-run series.

All 351 server-accepted enemy hits reconcile one-for-one to retained visible client events with valid 2508×879 dimensions; outside and invalid-viewport counts are zero, with passing fixtures. This is victim-camera projection at Hit receipt, not server-time reconstruction or cross-device proof. Minimum server-recorded warning is .40 seconds in each run; end-to-end visual lead time still needs latency/human evidence.

Seven complete action-diversity windows pass but all are elites; 284 partial windows remain ineligible, and ordinary-archetype diversity is inconclusive. The campaign idle/flank measurements pass their numerical targets; the separate final four-client crowd also passes idle at 364/7638 = 4.76565%, but only 21/31 complete diversity windows pass, so that requirement remains a measured failure. All five clears also mean the planned M3 Normal 60–80% target is not yet achieved. M2 human acceptance, physical-device/visual checks and M3 tier/rank tuning remain open; this checkpoint does not close the launch program.

Final crowd evidence on the same frozen source lasts 94.13 seconds, with four living players and twelve enemies, 41/48 flank windows and zero token-cap breaches. Complete diversity by kind is Warden3/5, Pitcher5/5, Leaper3/5, Strider4/5, Grappler2/5 and Husk4/6. Later diagnostics show combat displacement spreading the party across X=64.21-170.00; camera-safe suppression remains active and there is no mid-capture forced regroup. This observation does not waive failed action diversity. Telemetry and diagnostic aliases are separate and must not be cross-matched as identities.

The final MicroProfiler snapshot contains 39 complete inclusive AI scopes, mean .460666828 ms and maximum .642442393 ms; world independently recomputed both. Snapshot population validity has 2273 checks/zero mismatches, while the later completed harness has 2581/zero. Regular frames2375-2630 map to absolute5913-6168. This passes the observed desktop AI CPU numerical target, excluding adjacent telemetry and without phone FPS, GPU, peak-effects or human certification. Raw reports and limits remain in [M2_EVIDENCE](launch/M2_EVIDENCE.md).


### WO-3.1 pressure starting values (source implemented; runtime pending)

The shared difficulty-profile pressure settings are .15 seconds of protection after an accepted incoming hit, with three accepted hits inside an inclusive 1.5-second window granting .8 seconds and clearing that cluster. Rejected/invulnerable hits do not enter history; a new life clears it. Accepted block chip currently counts. The later perfect-block path must bypass both damage and this counter.

Dash during hitstun retains the .16-second minimum since the accepted hit, adds eight self-percent and starts a separate four-second Burst cooldown. Cost applies only after ordinary dash eligibility/busy checks pass; the existing 1.4-second Dash cooldown still applies. Ordinary Dash outside hitstun remains free even while Burst is locked. A cost reaching the 200-percent limit processes KO before any dash impulse. Dash preserves the later of existing protection and its .24-second iframe instead of shortening an active .8-second combo breaker.

Ordinary-wave solo base budgets, ordered district1/wave1, district1/wave3, district2/wave1, district2/wave3, district3/wave1, district3/wave3, become **5, 6, 6, 6, 7, 8**. Frozen party scaling adds exactly two total enemies per extra player, distributed cyclically across sorted authored archetype IDs; it no longer adds independently per kind. Existing two/three-pulse thresholds, entry fairness and party-size freezing remain. Initial elite waves retain their one elite and existing phase adds. The updated planner spec covers all 48 wave/party combinations, including 24 ordinary-wave cases; this is a prepared assertion scope, not a runtime result here.

Grunt-role base cooldown is capped at 1.8 seconds before difficulty aggression scaling; the final recovery-plus-.15-second lower bound still prevents overlapping actor attacks. Existing enemy warning geometry, .30-second final floor, camera checks and attack-token authority remain. These choices increase pressure without simultaneously retuning tactics; final M3 curve/rank measurements may justify later documented adjustments. World source review passed the policy/scaling after the breaker-preserving Dash fix; the strengthened real-client fixture checks accepted free/Burst requests and rejected Burst deadlines, including Burst during an active breaker. Root runtime evidence and before/after M3 measurements remain pending at this recording.
