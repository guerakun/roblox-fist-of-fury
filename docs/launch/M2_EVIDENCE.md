# M2 engineering evidence — acceptance remains open

Recorded 2026-09-24. Root owns Studio execution and the dated commit ledger in [PROGRESS](../PROGRESS.md). This document consolidates observed results, source reviews and remaining gates. The final five-session HumanBot series on frozen source `9f29012` is **in progress**; seed 1101 is running and no final result is recorded here yet. No result below closes the human or device requirements.

## Baseline and campaign diagnostics

The [baseline measurement contract](HUMANBOT_BASELINE.md) fixes seeds 1101–1105, imperfect reaction/action policy, solo practice profile and no automatic retries. Damage below is the floored client snapshot value; fractional server counters are retained in raw reports. Idle/flank percentages pool their own eligible ticks/windows, not per-run percentages.

| Campaign evidence | Clears | Mean/run seconds | Stocks lost | Snapshot damage | Eligible idle | Qualified flank | Cap breaches |
|---|---:|---:|---:|---:|---:|---:|---:|
| M0 five-run baseline | 5/5 | 278.27 | 0.80 mean | 543 mean | 593/3684 = 16.10% | 15/33 = 45.45% | 0 |
| Extraction diagnostic, seed 1101 | 1/1 | 265.15 | 1 | 448 | Not used as final M2 comparison | Not used as final M2 comparison | See raw report |
| Director diagnostic, seed 1101 | 1/1 | 292.37 | 0 | 430 | 10.58% | 90.91% | 0 |
| Pre-camera-reposition M2 diagnostic, seed 1101 | 1/1 | 422.93 | 3 | 926 | 255/1784 = 14.29% | 23/23 = 100% | 0 |
| Final frozen-build M2 series, seeds 1101–1105 | Pending | Pending | Pending | Pending | Pending | Pending | Pending |

Sources: [baseline summary](evidence/baseline-summary.json), [extraction](evidence/extraction-seed1101.json), [director](evidence/director-seed1101.json), [pre-camera diagnostic](evidence/m2-initial-seed1101.json). Baseline gameplay is `v0-overnight` (`ca00266`); its completed measurement checkpoint is `be91f0f`. Intermediate diagnostics use different source revisions and are not an aggregate five-run result or a controlled estimate of one isolated change.

The pre-camera diagnostic recorded 81 client Hit projections and zero outside projections, but its initial fixture used a 1x1 viewport. Its end viewport was 2508x879, and per-hit sizes were not recorded by that observer revision. Preserve that limitation; do not use it to close the actual-camera gate. Its diversity report contains only one complete eligible window, for an elite, and 128 partial windows. It therefore does not establish ordinary-archetype diversity, despite its successful campaign clear. Baseline rank and frustum are unavailable, not zero.

## Four-client, twelve-enemy crowd diagnostics

These are stationary-input Studio server scenarios with two of each ordinary archetype. They measure crowd behavior and CPU work separately from HumanBot campaign balance.

| Run | Idle ticks | Passing complete diversity windows | Flank windows | Cap breaches |
|---|---:|---:|---:|---:|
| [Initial](evidence/m2-crowd-initial.json) | 4500/8244 = 54.59% | 6/24 = 25.00% | 39/39 = 100% | 0 |
| [Scheduling correction](evidence/m2-crowd-fairness.json) | 5251/9768 = 53.76% | 11/35 = 31.43% | 57/57 = 100% | 0 |
| [Settled party and camera-safe movement](evidence/m2-crowd-camera-safe.json) | 2154/8164 = 26.38% | 20/33 = 60.61% | 48/76 = 63.16% | 0 |
| Final bounded footwork build | Pending | Pending | Pending | Pending |

All three observed crowd runs fail the under-15% idle target and leave incomplete two-action coverage. A four-player flanking result does not directly satisfy the plan's solo-player criterion. Partial/pending diversity windows are ineligible, and zero eligible windows are insufficient coverage. `passed` in the strengthened harness means requested orchestration completion; it is not a behavior-acceptance flag.

The scheduling diagnostic shows one player stationary near checkpoint X=28 while the others occupy approximately X=86–118. Camera centers near X=65–73 reject most right-side enemy attacks. Source inspection supports an initialization race: a model can satisfy `GetAlivePlayers` before its deferred character setup resets it. That explanation is an inference, not a captured callback trace. The fixture now settles for two seconds, repositions the group, then verifies stable character identity and X=90±2 after another second before spawning enemies. The corrected run changes both fixture placement and production movement; their individual causal contributions are not isolated.

Production corrections preserve attack visibility and token limits: bounded rear priority with aging on reservation, feasible arena/camera slots, release of offscreen reservations, and camera-safe walking goals. The subsequent source-reviewed footwork change uses meaningful bounded Hold waypoints and resolved-attack spacing sequences. Its Retreat action observer requires actual velocity away from the target, making that diversity rule stricter. Exact tuning and preserved prior behavior are in [COMBAT](../COMBAT.md).

## Frozen MicroProfiler captures

Measurements include complete `CurtainBreakEnemyAI` / `aiStep` CPU scopes, excluding adjacent telemetry collection. They are not whole-Heartbeat duration, GPU timing, phone FPS or peak-effects certification.

| Capture | Complete calls | Mean ms | Maximum ms | Population evidence | Interpretation |
|---|---:|---:|---:|---|---|
| [Initial](evidence/m2-microprofiler.json) | 38 | 0.2856 | 0.5051 | Half-second samples and completion check | Numerical mean below 1.5 ms; interval validity limitation |
| [Scheduling correction](evidence/m2-microprofiler-valid.json) | 39 | 0.26599 | 0.43663 | 1134 checks, zero mismatches | Numerical and observed-population checks pass |
| [Camera-safe movement](evidence/m2-microprofiler-camera-safe.json) | 39 | 0.41560 | 0.64892 | 1069 checks, zero mismatches | Numerical and observed-population checks pass |

The second capture covers regular frames 1228–1483 / absolute frames 6288–6543. The third covers regular frames 1069–1324 / absolute frames 6521–6776. Population validity latches mismatches on observed Heartbeats and capture-barrier changes/removal. Scope entries before the selected first frame are excluded. Numerical mean success, population validity and combined CPU success are separate fields. Suppressed attack activity in these scenarios limits inference about peak combat workload; retain that caveat even when the numeric target passes.

## Actual policy and runtime checks

Root reports the following 19-spec Studio regression: CameraBoundsAI, EnemyAISlots, EnemyArchetypesAI, EnemyWaveAI, EnemyMoves, HeroMigration, DifficultyAI, DifficultyReactionAI, EliteSelectionAI, CombatTelemetry, TelemetryDiversityAI, CampaignAdmission, ReturnParty, Matchmaking, TeleportCoordinator, DeparturePreparation, ProfileStore, ProfileConcurrency and AnalyticsJournal. The first pass produced 18 passes and one missing-fixture failure in HeroMigration. Root restored the test-only `LegacyHeroFixtures.lua`, then HeroMigration passed on rerun. World independently confirmed its exact compatibility bytes map to Config's expected fingerprints, both production project trees exclude tests, and the IP gate passes. This was a fixture repair; it must not be described as an uninterrupted 19/19 initial pass.

Root also reports fresh Studio passes for EnemyFootworkAI, EnemyAISlots, CameraRepositionAI (18 geometry cases plus AI regressions), EnemyArchetypesAI, DifficultyReactionAI, AttackDirectorAI, DirectorFairnessAI and ActionDiversityAI. The separate actual Studio physical-footwork fixture passed with 24.6827 studs of measured travel, ten Hold samples and a jab-then-jump sequence. Its first jab is seeded by the fixture; the follow-up is selected after server resolution. Travel sums the whole observation interval; ten Hold samples do not attribute every traveled stud exclusively to Hold. This is scoped movement/sequence evidence, not a crowd idle or diversity result. Next crowd/bot outcomes remain pending at this recording.

Earlier actual scoped evidence remains available: [grab/rescue](evidence/archetype-grab-rescue.json), [elite phases](evidence/elites-runtime.json), [entries/pulses](evidence/entrances-runtime.json), [difficulty](evidence/difficulty-runtime.json). Their scripted/structural scope is not human gameplay certification.

## Remaining gates and next evidence

- Freeze the final source revision and run five fresh HumanBot seeds 1101–1105 with unchanged policy; record individual outcomes and a pooled before/after table. Do not silently substitute intermediate diagnostics.
- Record enough complete ordinary-archetype windows and corrected crowd data to assess still-unmet idle/diversity targets. Preserve every failed run.
- Use the updated client frustum observer from `a129630`: valid viewport fixture at each Hit, per-event dimensions and separate `invalidViewportHits`. Invalid samples do not count as audited hits. Report all three totals: audited, outside and invalid. Measurement is through the victim camera at receipt, not reconstructed server-time camera state.
- Retain server warning-floor/cap checks, actual-camera coverage and the required human run as separate fairness evidence. Server conservative bounds are not actual-frustum proof.
- Complete owner human Normal/Hard and device/performance gates before launch approval. Studio results do not remove those requirements.

Root may checkpoint engineering and bot evidence before further source implementation; that sequencing decision does not claim full M2 acceptance. The launch plan and current PROGRESS table remain the scope/status authority.
