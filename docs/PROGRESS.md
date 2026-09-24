# Morning summary

M0 closed (be91f0f): five fresh HumanBot runs, 5/5 clears, mean 278.27s, 0.80 stocks, 543 damage. WO-2.1 extraction passed 25 deterministic traces, nine token caps, EnemyMoves and one live campaign: 265.15s, one stock, 448 damage versus same-seed baseline 273.32s, one stock, 497 damage. Timing/combat noise remains; deterministic equivalence is the behavior evidence. WO-1.1 hero metadata/profile migration integrated and Studio specs passed; WO-1.4 original story/docs and Ashgate signage saved; WO-1.2 native original art instantiated with valid rigs; visible likeness/screenshots blocked by blank capture output. First 2-to-4-client campaign passed 15 assertions; fixed 2/3/4 and lifecycle/lag cases remain. Names/art and human testing need owner review. No live settings/sales/publication changed. Next: WO-1.3 specials, WO-2.2 director, WO-5.5 fixed3/4/lifecycle/latency tests. Names/art approval and human runs remain owner gates. Hub source built/instantiated (WO-5.1), IDs remain zero; party/deploy functionality is next in WO-5.2. Fixed 2/3-client runs passed. WO-2.2 director/body tells saved after scheduler/AI specs and independent review; M2 campaign telemetry is pending. WO-5.5 fixed4 passed144.94s; lifecycle14assertions passed but same-identity rejoin blocked (Studio assigns fresh IDs). 150ms passed158.80s;250ms passed167.15s. Lag restored0. All remaining lifecycle coverage is itemized in MULTIPLAYER_EVIDENCE.md; WO-5.5 is partially verified, not closed. WO-1.3 original specials passed client geometry/pose/lifetime checks. WO-2.2 seed1101 campaign comparison is running.

## Launch program status

| WO | Owner | Status | Evidence | Next step |
|---|---|---|---|---|
| WO-0.1 | root | closed | 2026-09-24: ca00266 tagged v0-overnight; EnemyMoves 38 patterns, ProfileStore 11 adapter calls, ProfileConcurrency 16.224 s and StudioSmoke PASS; 4/4 specs, clean startup; commit ebd49d4, tag pushed | baseline preserved; tag is rollback reference |
| WO-0.2 | root | closed | 2026-09-24: five fresh seeds 1101-1105; 5/5 clears; mean278.27s, 0.80 stocks, 543 damage; anonymous reports; closing commit be91f0f | release Phase B; compare WO-2.1 extraction seed1101 before syncing M1 changes |
| WO-0.3 | root (combat handoff after M0) | closed | 2026-09-24: observer/spec PASS including idle/flank fixtures; combat independent review PASS; no gameplay mutations; commit c1a037d | hand off telemetry ownership to combat for M2 |
| WO-1.1 | presentation | closed | 2026-09-24: Studio HeroMigration spec PASS (stable IDs, old keys/case/defaults, coins and kit values); ProfileStore11calls and EnemyMoves38patterns PASS; world independent review; normal client selection Tide snapshot confirmed; commit3b41a0f | WO-1.2 original art and WO-1.3 specials; names pending owner approval |
| WO-1.2 | presentation | implemented; visual gate blocked | 2026-09-24: Studio Gale35/Piston44/Tide39parts, each7queryable/6motors/0external meshes; world source review PASS. Native capture unavailable; Studio capture twice blank. ORIGINAL_ART_EVIDENCE.md; commitd5364f2 | continue1.3; retry gameplay screenshots; owner art approval pending |
| WO-1.3 | presentation | implemented; visual gate pending | 2026-09-24: actualStudioClientspecPASS6directionalcoverage/3poses/126cosmeticparts/effectcap8/cleanup; worldsourcePASS; networktimingnotexact; captureUIworksbut3Dblank | WO-1.5 grep; retry3Dcapture; ownerartapproval |
| WO-1.4 | world | closed | 2026-09-24: presentation independent review PASS; scoped docs/signs prohibited scan zero; two obsolete screenshots removed; retired ideas preserved without identities; commit8cda482 | WO-1.5 whole-repo gate after art replacement; owner names/art review pending |
| WO-1.5 | root | queued | not run | follow launch phase dependencies |
| WO-2.1 | combat | closed | 2026-09-24: 25 legacy/extracted traces, nine caps, clock boundary and EnemyMoves PASS; source structural equivalence reviewed by presentation/world; extraction-seed1101.json Victory265.15s/1stock/448damage (baseline273.32s/1/497); commit b38e04b | WO-1.1 Combat defaults, then WO-2.2 slots/tokens |
| WO-2.2 | combat | implemented; aggregate telemetry pending | 2026-09-24: fresh Studio AttackDirectorAI+EnemyAISlots PASS; world finalreview PASS; front/back slots, nonidleHold,2-5tokens, renewal/capshrink/targetdeparture invalidation, bodytell client contract; commit3bbc5cc | WO-2.3 archetypes; five-run aggregate M2 telemetry/frustum/human gates remain open |
| WO-2.3 | combat | queued | not run | follow launch phase dependencies |
| WO-2.4 | combat | queued | not run | follow launch phase dependencies |
| WO-2.5 | combat | queued | not run | follow launch phase dependencies |
| WO-2.6 | combat | queued | not run | follow launch phase dependencies |
| WO-3.1 | combat | queued | not run | follow launch phase dependencies |
| WO-3.2 | combat | queued | not run | follow launch phase dependencies |
| WO-3.3 | combat | queued | not run | follow launch phase dependencies |
| WO-3.4 | root | queued | not run | follow launch phase dependencies |
| WO-3.5 | combat | queued | not run | follow launch phase dependencies |
| WO-3.6 | root | queued | not run | follow launch phase dependencies |
| WO-3.7 | root | queued | not run | follow launch phase dependencies |
| WO-4.1 | combat | queued | not run | follow launch phase dependencies |
| WO-4.2 | combat | queued | not run | follow launch phase dependencies |
| WO-4.3 | combat | queued | not run | follow launch phase dependencies |
| WO-4.4 | combat | queued | not run | follow launch phase dependencies |
| WO-4.5 | root | queued | not run | follow launch phase dependencies |
| WO-4.6 | root | queued | not run | follow launch phase dependencies |
| WO-5.1 | root | closed (source place) | 2026-09-24: hub Rojo build PASS; Studio Build returns23children with arrivalspawn/deployterminal; world independent review PASS; PlaceIds0; commit1283949 | WO-5.2 fake-adapter matchmaking;5.3 functioningUI; no publishedplaceclaim |
| WO-5.2 | root | queued | not run | follow launch phase dependencies |
| WO-5.3 | root | queued | not run | follow launch phase dependencies |
| WO-5.4 | root | queued | not run | follow launch phase dependencies |
| WO-5.5 | root | partially verified; remaining cases recorded | 2026-09-24: fixed2/3/4 and2-to-4 PASSall12encounters;150/250msPASS;14lifecycle/stockshare assertionsPASS;22timingpairs250ms zero>50ms early; MULTIPLAYER_EVIDENCE.md; commit981232a | same-IDreconnect blocked by Studio identity reuse; retry/freshcampaign/emptyserver/readycancel scenarios pending; rerun afterM3 |
| WO-5.6 | root | queued | not run | follow launch phase dependencies |

<!-- launch-status-end -->

# Overnight development log — 2026-09-23

## Current objective
Work toward a publishable three-stage cooperative campaign by 07:00 America/New_York. Stage 1: city streets; stage 2: abandoned station; stage 3: abandoned factory. Every stage needs a distinct miniboss and boss. Do not erase previous world/story ideas; retain them as backlog.

## Team coordination
Agents can message each other directly. Combat, client and world owners exchange encounter names, locations, FX shapes and state contracts. Root integrates, tests in Studio, reviews economy/persistence and saves/pushes milestones. Agents work on separate files. A later review should be performed by someone who did not author the feature.

## 02:26 EDT — expansion started
- Existing slice committed as `92c7c12`; three city districts, one boss, Toolbox ingredients, co-op smoke test.
- World owner: rebuild districts 2/3 as distinct station/factory; preserve lane and gate contracts.
- Combat owner: six encounter identities, telegraphed mechanics, checkpoint flow, co-op fairness.
- Client owner: boss UI, accessibility, clearer feedback, results and mobile/controller layout.
- Root: progression, earned coins, free chapter reward track, cosmetic shop, fair earned combat boons, integration/testing.
- Shipping claim remains development slice until evidence supports stronger wording. Published-universe asset permissions, live persistence and device coverage remain explicit gates.

## Monetization direction
Keep every stage and hero playable free. Earn coins through encounters. Sell optional cosmetics and an evergreen cosmetic chapter pass only after live product IDs and persistence have been verified. Combat boons are earned through play, one equipped at a time; money does not raise combat power. No paid revives, loot boxes, streak penalties or expiring earned rewards.

## Evidence policy
Record actual tests separately from planned tests. Forced progression verifies transitions; it does not prove normal-input campaign balance. Local two-client testing does not certify public-server latency or mobile performance.

## 03:18 EDT — first expanded campaign completion
- Three distinct stages, 12 encounters and six elite identities implemented. Physical rally travel, all-player ready lobby and miniboss checkpoints replace automatic wave teleporting.
- Normal-action automated client completed all 12 encounters and reached Victory in 183.59 seconds of driver time: 27 KOs, 2,974 damage dealt, 690 encounter coins, final three stocks / 50%. This driver reads telegraphs perfectly and is not human balance certification. Server run duration/damage includes a pre-driver idle defeat and is not a clean benchmark.
- One-desktop sample during that run: 11,003 frames, mean 16.687 ms, maximum 67.785 ms at Studio rendering quality 21. No mobile or network performance claim.
- EnemyMoves tests passed six elite rigs, 38 pattern entries, punish windows, lane gaps, jump thresholds, party mark deduplication and all 12 wave definitions.
- ProfileStore fake-adapter tests passed load/save/rejoin, unique per-load session tokens, contention, expiry, failed-load protection, schema handling and save warning recovery. A separate 16.2-second delayed-save test verified latest mutation persisted before release and lease was cleared.
- Practice economy tests passed duplicate reward/claim rejection, cosmetic purchase/equip, earned Haste, rejection of premium-for-coins forgery and invalid tier values. Live DataStore is not tested.
- Actual keyboard P toggled the journal; Return readied and began the first fight.
- Retired prototype character meshes previously supplemented the heroes; that historical face/clothing pass is superseded by the original-cast launch work. Original generated pump and station material added. Background art has a second abandonment/readability pass.
- Review caught runtime MaterialVariant.BaseMaterial security failure; fixed with serialized MaterialService metadata and Edit-only fallback. Rojo build passes.
- Remaining immediate integration: latest hero/UI fixes, boss-specific cosmetic effects, stage audio, compact journal/loading-state fixes. Then fresh solo and expanded co-op tests, saved-place sync and GitHub milestone.
- Current paid sales remain disabled. Fair economy rationale and exact reward numbers preserved in MONETIZATION.md.
- A 30-minute continuation heartbeat runs until 07:00 EDT. It should remain quiet unless something meaningful changes; work continues in this task.

## Overnight interruption and handoff
- Around 03:31 EDT, the account usage limit interrupted the agents. Scheduled wake-ups did not produce additional completed work. The remaining overnight window was not development time used.
- Before interruption, latest Studio integration started without game-script errors. Stage ambience/music assets loaded. The fresh iPhone 7 simulator lobby fit its safe area; the journal had a 606x158 content area and 44px touch controls. An open loading journal correctly closed when its server eligibility changed to combat.
- Six elite rigs instantiated with 39-49 cosmetic parts each. Phase-two signature-first sequencing and reconnect survival retention were implemented in source.
- Voluntary stock sharing was added in source/client UI, but final integration and conservation scenarios were NOT run.
- The two-to-four-client campaign harness was written but NOT executed. Earlier two-client smoke and single-client expanded campaign results remain the actual evidence. Rendering/memory analysis was prepared but NOT executed.
- At the user's later public-repository handoff, all overnight source, test harnesses and notes are committed. The main place was rebuilt from source and generates its world on Play. It excludes test harnesses. The earlier editable-world milestone remains recoverable from Git history.
- Remaining release gates: latest-feature regression, expanded co-op/reconnect/stock sharing, human feel and hardware controls, final-universe assets and live persistence. Paid sales remain disabled.

## Camera correction and Bare Knuckle III review — 2026-09-23
- User paused feature expansion to prioritize movement-camera jitter and a reference-game comparison. All three agents contributed: client fixed/reviewed camera, combat audited actions and middle-video sequences, world reviewed early-video sequences and assembled the research record; root integrated, reviewed the late campaign and ran Studio tests.
- Fixed mismatched 10 Hz look-target versus smoothed-eye updates. Camera now samples party positions every render and moves eye/focus together with one smoothed center; movement runs separately after input. Outward input near movement bounds is filtered without writing character transforms or cancelling launch velocity.
- Actual Studio keyboard walking: old yaw range 2.44618 degrees, fixed yaw range 0. Boundary/depth/jump test settled without X oscillation; a brief 1.014-stud boundary overshoot remains documented. See CAMERA_REGRESSION.md for measurements and limits. This is not a full networked co-op or mobile regression.
- Camera edits applied to the open Studio Edit model and retained in source. The distributable source-built place was rebuilt. Studio's other existing scripts were preserved; its prior stock-sharing UI integration difference remains outside this camera task.
- Reviewed sampled frames throughout the exact 74:30 reference upload plus dense combat sequences. Preserved timestamps, evidence limits and present/partial/missing mechanics in research/BARE_KNUCKLE_3_VIDEO_REVIEW.md. No reference gameplay additions were implemented; selection remains with the user.
- Local reference video and temporary analysis dependencies are ignored by Git and excluded from the game/repository.
