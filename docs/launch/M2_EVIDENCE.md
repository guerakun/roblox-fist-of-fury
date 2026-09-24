# M2 engineering evidence — acceptance remains open

Recorded 2026-09-24. Root owns Studio execution and the dated commit ledger in [PROGRESS](../PROGRESS.md). This document consolidates observed results, source reviews and remaining gates. The final five-session HumanBot series on frozen gameplay source `9f29012` is **complete**: all five cleared. World independently reconciled the raw reports and aggregate below. M2 acceptance remains open for ordinary-archetype diversity, the required human run and the outstanding broader device/visual gates; the final crowd/CPU checkpoint is recorded separately below. No result below closes the human or device requirements.

## Baseline and campaign diagnostics

The [baseline measurement contract](HUMANBOT_BASELINE.md) fixes seeds 1101–1105, imperfect reaction/action policy, solo practice profile and no automatic retries. Damage below is the floored client snapshot value; fractional server counters are retained in raw reports. Idle/flank percentages pool their own eligible ticks/windows, not per-run percentages.

| Campaign evidence | Clears | Mean/run seconds | Stocks lost | Snapshot damage | Eligible idle | Qualified flank | Cap breaches |
|---|---:|---:|---:|---:|---:|---:|---:|
| M0 five-run baseline | 5/5 | 278.27 | 0.80 mean | 543 mean | 593/3684 = 16.10% | 15/33 = 45.45% | 0 |
| Extraction diagnostic, seed 1101 | 1/1 | 265.15 | 1 | 448 | Not used as final M2 comparison | Not used as final M2 comparison | See raw report |
| Director diagnostic, seed 1101 | 1/1 | 292.37 | 0 | 430 | 10.58% | 90.91% | 0 |
| Pre-camera-reposition M2 diagnostic, seed 1101 | 1/1 | 422.93 | 3 | 926 | 255/1784 = 14.29% | 23/23 = 100% | 0 |
| Final frozen-build M2 series, seeds 1101-1105 | 5/5 | 398.56 | 2.80 mean | 830.4 mean | 795/8299 = 9.58% | 108/112 = 96.43% | 0 |

Sources: [baseline summary](evidence/baseline-summary.json), [extraction](evidence/extraction-seed1101.json), [director](evidence/director-seed1101.json), [pre-camera diagnostic](evidence/m2-initial-seed1101.json). Baseline gameplay is `v0-overnight` (`ca00266`); its completed measurement checkpoint is `be91f0f`. Intermediate diagnostics use different source revisions and are not an aggregate five-run result or a controlled estimate of one isolated change.

The pre-camera diagnostic recorded 81 client Hit projections and zero outside projections, but its initial fixture used a 1x1 viewport. Its end viewport was 2508x879, and per-hit sizes were not recorded by that observer revision. Preserve that limitation; do not use it to close the actual-camera gate. Its diversity report contains only one complete eligible window, for an elite, and 128 partial windows. It therefore does not establish ordinary-archetype diversity, despite its successful campaign clear. Baseline rank and frustum are unavailable, not zero.

### Final frozen-build comparison and independent reconciliation

The [final summary](evidence/m2-final-summary.json) contains exactly seeds 1101–1105. Every report records gameplay source `9f29012`, unchanged bot policy `b21b807` and audit revision `a129630`. World separately recomputed sums/means from each raw report and matched all summary values within 1e-9, rather than relying only on the summary generator.

| Metric | M0 baseline, five solo runs | Final M2, same five seeds |
|---|---:|---:|
| Clears | 5/5 | 5/5 |
| Mean seconds | 278.267885 | 398.561898 |
| Mean stocks lost | 0.80 | 2.80 |
| Mean floored snapshot damage | 543.0 | 830.4 |
| Eligible grunt idle | 593/3684 = 16.10% | 795/8299 = 9.57947% |
| Qualified solo flank windows | 15/33 = 45.45% | 108/112 = 96.42857% |
| Token-cap breaches | 0 | 0 |
| Accepted hits reconciled to actual-camera observations | Unavailable | 351/351; zero outside and zero invalid |
| Minimum recorded enemy warning | See baseline reports | 0.40 seconds in each run |
| Ordinary archetype complete 30-second diversity windows | Unavailable | None; inconclusive |

| Seed / raw report | Outcome | Seconds | Stocks lost D1 / D2 / D3 | Snapshot damage | Idle ticks / eligible | Flanked / eligible | Server hits = audited events |
|---|---|---:|---|---:|---|---|---:|
| [1101](evidence/m2-final-1101.json) | Victory | 430.9641 | 1 / 1 / 2 | 991 | 146 / 1734 | 20 / 20 | 80 |
| [1102](evidence/m2-final-1102.json) | Victory | 404.0812 | 0 / 1 / 2 | 946 | 182 / 1750 | 24 / 25 | 79 |
| [1103](evidence/m2-final-1103.json) | Victory | 382.1833 | 0 / 1 / 1 | 683 | 162 / 1438 | 21 / 22 | 59 |
| [1104](evidence/m2-final-1104.json) | Victory | 395.5810 | 1 / 1 / 1 | 840 | 146 / 1709 | 21 / 21 | 71 |
| [1105](evidence/m2-final-1105.json) | Victory | 379.9998 | 0 / 1 / 1 | 692 | 159 / 1668 | 22 / 24 | 62 |

For every run, client district stock losses equal both server per-player district counters and summed encounter losses. Fractional server damage exceeds its floored snapshot by less than 1.01. **351 accepted server hits = 351 retained audited client events + zero invalid-viewport hits**; the equality holds separately for every run, so missing observations cannot cancel across runs. Each event is marked visible, has positive depth and X/Y inside its recorded 2508×879 viewport. Each valid-viewport fixture passes. Outside and invalid counts are both zero.

This measures the attacker position through the victim camera at Hit receipt, not a reconstruction of the server-time camera or proof across all aspect ratios, latency, devices or future attacks. The reported .40-second minimum is server warning-duration telemetry, not measured human perception or end-to-end visual lead time. Source policy still enforces the .30-second floor and conservative bounds independently.

All seven eligible 30-second diversity windows pass, but **all seven belong to elites**: FurnaceHound two, SirenMarshal two, KilnSovereign one, LastConductor one and Executioner one. Their minimum distinct counts are four, five, four, five and three respectively. There are 284 partial windows, which remain ineligible. These runs therefore cannot establish the required two-action diversity for ordinary archetypes. Do not aggregate elite success into an ordinary-enemy pass.

The pooled campaign idle and solo-flank targets pass in this series, and there are no cap breaches. Every campaign still clears, so this is not evidence that M3's intended Normal 60–80% clear curve is achieved; M3 changes and its separate tier/rank measurements remain pending. The longer runs, higher stock loss and higher damage describe the combined M2 build, not an isolated causal effect of any one tactic or a human difficulty rating.

## Four-client, twelve-enemy crowd diagnostics

These are stationary-input Studio server scenarios with two of each ordinary archetype. They measure crowd behavior and CPU work separately from HumanBot campaign balance.

| Run | Idle ticks | Passing complete diversity windows | Flank windows | Cap breaches |
|---|---:|---:|---:|---:|
| [Initial](evidence/m2-crowd-initial.json) | 4500/8244 = 54.59% | 6/24 = 25.00% | 39/39 = 100% | 0 |
| [Scheduling correction](evidence/m2-crowd-fairness.json) | 5251/9768 = 53.76% | 11/35 = 31.43% | 57/57 = 100% | 0 |
| [Settled party and camera-safe movement](evidence/m2-crowd-camera-safe.json) | 2154/8164 = 26.38% | 20/33 = 60.61% | 48/76 = 63.16% | 0 |
| [Final bounded footwork build](evidence/m2-crowd-final.json) | 364/7638 = 4.76565% | 21/31 = 67.74% | 41/48 = 85.42% | 0 |

The first three crowd runs fail the under-15% idle target. The final 94.13-second frozen-build run passes idle at 4.76565% but still fails universal two-action coverage: 21 of 31 complete windows pass. A four-player flanking result does not directly satisfy the plan's solo-player criterion. Partial/pending diversity windows are ineligible, and zero eligible windows are insufficient coverage. `passed` in the strengthened harness means requested orchestration completion; it is not a behavior-acceptance flag.

The scheduling diagnostic shows one player stationary near checkpoint X=28 while the others occupy approximately X=86–118. Camera centers near X=65–73 reject most right-side enemy attacks. Source inspection supports an initialization race: a model can satisfy `GetAlivePlayers` before its deferred character setup resets it. That explanation is an inference, not a captured callback trace. The fixture now settles for two seconds, repositions the group, then verifies stable character identity and X=90±2 after another second before spawning enemies. The corrected run changes both fixture placement and production movement; their individual causal contributions are not isolated.

The final crowd's per-kind diversity is Warden 3/5 (minimum one distinct action), Pitcher 5/5 (two), Leaper 3/5 (zero), Strider 4/5 (zero), Grappler 2/5 (zero) and Husk 4/6 (zero). These are measured failures for some complete windows, not merely missing samples. Diagnostics at approximately 60 seconds show the four players spread from X=64.21 to X=170.00 after combat displacement, with camera checks suppressing some attacks. No forced mid-capture repositioning was used. The spread is observed; it does not erase failed diversity or prove a single cause. The completed harness records 2581 population checks with zero mismatches. TelemetryPlayer aliases and diagnostic Player labels have separate anonymization mappings, so no cross-label identity association is claimed. Actual-camera frustum was not measured in this crowd run; the 351-hit actual-camera result belongs to the separate solo series.

Production corrections preserve attack visibility and token limits: bounded rear priority with aging on reservation, feasible arena/camera slots, release of offscreen reservations, and camera-safe walking goals. The subsequent source-reviewed footwork change uses meaningful bounded Hold waypoints and resolved-attack spacing sequences. Its Retreat action observer requires actual velocity away from the target, making that diversity rule stricter. Exact tuning and preserved prior behavior are in [COMBAT](../COMBAT.md).

## Frozen MicroProfiler captures

Measurements include complete `CurtainBreakEnemyAI` / `aiStep` CPU scopes, excluding adjacent telemetry collection. They are not whole-Heartbeat duration, GPU timing, phone FPS or peak-effects certification.

| Capture | Complete calls | Mean ms | Maximum ms | Population evidence | Interpretation |
|---|---:|---:|---:|---|---|
| [Initial](evidence/m2-microprofiler.json) | 38 | 0.2856 | 0.5051 | Half-second samples and completion check | Numerical mean below 1.5 ms; interval validity limitation |
| [Scheduling correction](evidence/m2-microprofiler-valid.json) | 39 | 0.26599 | 0.43663 | 1134 checks, zero mismatches | Numerical and observed-population checks pass |
| [Camera-safe movement](evidence/m2-microprofiler-camera-safe.json) | 39 | 0.41560 | 0.64892 | 1069 checks, zero mismatches | Numerical and observed-population checks pass |
| [Final bounded footwork build](evidence/m2-microprofiler-final.json) | 39 | 0.460667 | 0.642442 | 2273 checks, zero mismatches at snapshot | Numerical and observed-population checks pass |

The final capture covers regular frames 2375-2630 / absolute frames 5913-6168; world independently recomputed the mean and maximum from all 39 retained calls. Its snapshot population validity has 2273 checks; the later completed harness has 2581, so these are different observation endpoints rather than conflicting totals. The second capture covers regular frames 1228–1483 / absolute frames 6288–6543. The third covers regular frames 1069–1324 / absolute frames 6521–6776. Population validity latches mismatches on observed Heartbeats and capture-barrier changes/removal. Scope entries before the selected first frame are excluded. Numerical mean success, population validity and combined CPU success are separate fields. Suppressed attack activity in these scenarios limits inference about peak combat workload; retain that caveat even when the numeric target passes.

## Actual policy and runtime checks

Root reports the following 19-spec Studio regression: CameraBoundsAI, EnemyAISlots, EnemyArchetypesAI, EnemyWaveAI, EnemyMoves, HeroMigration, DifficultyAI, DifficultyReactionAI, EliteSelectionAI, CombatTelemetry, TelemetryDiversityAI, CampaignAdmission, ReturnParty, Matchmaking, TeleportCoordinator, DeparturePreparation, ProfileStore, ProfileConcurrency and AnalyticsJournal. The first pass produced 18 passes and one missing-fixture failure in HeroMigration. Root restored the test-only `LegacyHeroFixtures.lua`, then HeroMigration passed on rerun. World independently confirmed its exact compatibility bytes map to Config's expected fingerprints, both production project trees exclude tests, and the IP gate passes. This was a fixture repair; it must not be described as an uninterrupted 19/19 initial pass.

Root also reports fresh Studio passes for EnemyFootworkAI, EnemyAISlots, CameraRepositionAI (18 geometry cases plus AI regressions), EnemyArchetypesAI, DifficultyReactionAI, AttackDirectorAI, DirectorFairnessAI and ActionDiversityAI. The separate actual Studio physical-footwork fixture passed with 24.6827 studs of measured travel, ten Hold samples and a jab-then-jump sequence. Its first jab is seeded by the fixture; the follow-up is selected after server resolution. Travel sums the whole observation interval; ten Hold samples do not attribute every traveled stud exclusively to Hold. This is scoped movement/sequence evidence, not a crowd idle or diversity result. The final five campaign outcomes and final crowd/CPU run are recorded above.

Earlier actual scoped evidence remains available: [grab/rescue](evidence/archetype-grab-rescue.json), [elite phases](evidence/elites-runtime.json), [entries/pulses](evidence/entrances-runtime.json), [difficulty](evidence/difficulty-runtime.json). Their scripted/structural scope is not human gameplay certification.

## Remaining gates and next evidence

- The five-run frozen-source comparison is complete above. Preserve those raw reports and source/policy hashes when recording later M3 comparisons; intermediate diagnostics are not substitutes.
- Ordinary-archetype diversity remains a measured crowd failure (21/31 complete windows pass); the campaign sample cannot replace it because its complete windows are elite-only. Investigate and retest this gate while preserving every failed run. Campaign and final-crowd idle targets now pass their observed scenarios.
- Final five-run camera observation coverage is complete: 351 audited, zero outside, zero invalid. Retain the observer from `a129630`, valid viewport fixtures and per-event dimensions in subsequent tests; broaden actual aspect/latency/device and human evidence instead of treating one desktop viewport as universal proof.
- Retain server warning-floor/cap checks, actual-camera coverage and the required human run as separate fairness evidence. Server conservative bounds are not actual-frustum proof.
- Complete owner human Normal/Hard and device/performance gates before launch approval. Studio results do not remove those requirements.

Root may checkpoint engineering and bot evidence before further source implementation; that sequencing decision does not claim full M2 acceptance. The launch plan and current PROGRESS table remain the scope/status authority.
