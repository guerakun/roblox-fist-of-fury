# M3 Normal tuning review — diagnostic proposals

Status: **diagnostic/proposed only; no tuning accepted or implemented**. Prepared 2026-09-24 while the final15-trial source freeze is running. Finish all five seeds per tier on the frozen build before changing production. This note preserves candidate values and rejected alternatives; it does not close M3 or M2 acceptance.

## Evidence and provenance

Read artifacts: [Normal1101](evidence/m3-final-normal-1101.json), [Normal1102](evidence/m3-final-normal-1102.json), [Normal1103](evidence/m3-final-normal-1103.json). All identify production `dfb2ae3bbb04d1408613e3e28b1f37fcc3f2b6f4`, the unchanged M0 HumanBot action policy (current observer-file SHA256 `176df37700c74a7b6e0d2489402bc84c22c8e6032e4cf43880c870c30a38c19a`), one Gale with Guardian, fresh Practice profile0 coins/0 XP, Normal/no Heat, and stable options. Numeric damage below is accepted server telemetry, not the floored UI snapshot. Time is the bot's reported `seconds`.

| Seed | Outcome | Bot seconds | Server damage | Accepted hits | Stocks lost city / station / factory | Cleared district ranks |
|---|---|---:|---:|---:|---|---|
|1101 | Defeat3:4 |472.015 |1104.7544 |100 |1 /1 /3 |A /A |
|1102 | Defeat3:4 |469.614 |1067.9544 |92 |1 /1 /3 |A /A |
|1103 | Defeat3:4 |461.028 |1093.7420 |94 |1 /2 /2 |A /A |
| Mean of these three only |0/3 clear |467.552 |1088.8169 |95.333 |1 /1.333 /2.667 |0 S among6 clears |

The required five-seed Normal60–80% target is already unreachable for this frozen set: even wins on1104 and1105 would produce2/5, below the required3–4/5. This is a deterministic statement about this acceptance sample, not an estimate that every human or future bot run will fail. Continue the full baseline and report both remaining runs.

All three records reconcile stock counts and floored damage. Across286 accepted hits, the actual receipt-time attacker projection audit records0 outside and0 invalid-viewport hits; all three viewport fixtures passed. Server token cap violations are0 and minimum recorded primary warning is.40s. This does not prove subjective readability, evade quality or every world-space camera edge; it does make a measured cap overrun/offscreen-hit regression an unsupported explanation for these particular failures. Full M2 action-diversity and human/device gates remain open.

## Where pressure accumulates

| District |1101 damage / lost stocks |1102 damage / lost stocks |1103 damage / lost stocks | Mean damage |
|---|---:|---:|---:|---:|
| City |250.2768 /1 |268.5480 /1 |384.1460 /1 |300.9903 |
| Station |292.4496 /1 |303.0204 /1 |425.3528 /2 |340.2743 |
| Factory, ending in defeat |562.0280 /3 |496.3860 /3 |284.2432 /2 |447.5524 |

Every run loses exactly five stocks overall: three starting stocks plus the one-stock benefit earned at each of the first two district clears. With the current max-three clamp, the factory starts on3/3/2 stocks for1101/1102/1103. Subtracting the recorded factory wave1 and wave3 losses leaves **one stock entering the final boss in all three runs**. This is inferred from the authoritative loss counters plus the implemented clear rules; the artifacts do not contain direct wave-start stock/percent snapshots. Remaining percent at boss entry is unknown.

| Encounter | Mean accepted damage | Mean accepted hits | Total stock losses across3 runs | Mean Combat→next-state seconds |
|---|---:|---:|---:|---:|
| City wave1 |49.573 |6.667 |0 |24.064 |
| City miniboss |81.604 |7.000 |0 |28.065 |
| City wave3 |42.087 |7.667 |0 |32.892 |
| City boss |127.727 |8.000 |3 |36.342 |
| Station wave1 |51.195 |6.333 |1 |32.597 |
| Station miniboss |53.639 |5.333 |0 |29.074 |
| Station wave3 |119.263 |10.333 |2 |38.703 |
| Station boss |116.178 |7.000 |1 |40.804 |
| Factory wave1 |103.347 |7.667 |3 |35.319 |
| Factory miniboss |92.212 |8.000 |0 |33.348 |
| Factory wave3 |140.944 |15.667 |2 |52.214 |
| Factory boss, incomplete |111.050 |5.667 |3 |25.503 |

Factory wave3 is the longest ordinary encounter and highest ordinary-wave damage in this sample. Its unchanged source budget is eight enemies: two each Strider, Grappler, Warden and Brute. Factory wave1 is seven enemies: two Pitchers, three Leapers and two Brutes; it consumes a stock in every run. City loses a stock at its boss in every run, so the plan's “district1 rarely loses a stock” target also lacks support. None of these correlations identifies a particular enemy as the damage source: encounter counters aggregate every actor, including elite summons.

The terminal fight lasts21.683–29.313 seconds from Combat to Defeat; that includes the existing empty-party defeat grace. It is not a complete boss duration. In1103 the final fight deals only49.1832 accepted damage before the last stock is lost. This is consistent with carried pressure or a launch KO, but neither cause is proven without entry percent and KO cause. Nerfing only the final boss assumes causality the artifacts do not establish. Likewise factory mean damage cannot be directly compared as equal exposure:1103 entered with fewer stocks and terminated earlier.

All six completed district results are A with rating85. Their score and pace factors reach the current60+25 cap while accepted district damage exceeds150, making the defense contribution zero. Zero S among six observed clears is a small censored sample, not full S-frequency acceptance; no rank-threshold change is proposed. The earlier single WO-3.3 seed1101 victory is preserved in COMBAT.md, but it is not a controlled comparison that attributes these defeats to any one later feature or proves a regression's cause.

## Smallest first experiment after the freeze

**Candidate A, preferred first controlled change: Normal `WindupScale`1.00→1.10; keep Hard.85 and Nightmare.72.** Change only this existing Normal profile scalar in Config. Do not stack health, damage, stocks or wave-budget changes into the same trial.

Reason: pressure is distributed across encounters, already consumes the first district's stock and exhausts reserves before the last boss. A modest extension to the existing warning scalar offers more response time across that exposure, while preserving the new enemy count, flanking, attack variety, two-token solo cap and persistent stakes. It also lengthens resolver/recovery-relative cadence where that bound applies. This is a proposed intervention, not a claim that10% more warning means10% fewer hits or achieves60–80% clears.

| Representative warning | Current Normal | Proposed Normal1.10 | Proposed Normal +Short Fuse |
|---|---:|---:|---:|
| Warden Counter / Pitcher Shove |.400 |.440 |.352 |
| Pitcher Throw |.450 |.495 |.396 |
| Husk Jab primary |.480 |.528 |.4224 |
| Husk Jab followup |.460 |.506 |.4048 |
| Strider Slide |.550 |.605 |.484 |
| Husk Jump Kick / Leaper Vault Kick |.600 |.660 |.528 |
| Mutated Crossfire |.950 |1.045 |.836 |

The shared final.30s floor remains after difficulty and Heat composition. Table values are source arithmetic only. Reaction delay remains.35, hit protection.15, combo breaker.8 after three hits/1.5s, Burst+8 with4s cooldown, Desperation+12 with4s cooldown, starting/max stocks3, retry2 and clear heal15. Earned boons and prices stay unchanged. Existing tests that assert the old **Normal** warning numbers must be updated to the explicit new profile expectation and rerun; their earlier results remain historical evidence.

Why this candidate precedes alternatives: it is one already-supported per-tier scalar, addresses the measured distributed exposure, and avoids inventing a new damage/stock exception. The observed reaction means are.2565/.2590/.2612s, consistent with the unchanged intended policy; no bot action improvement is proposed. Additional warning may help recognized tells but cannot fix unrecognized mistakes or guarantee escape from a locked footprint. If it barely changes accepted damage, reject that causal hypothesis instead of repeatedly raising the scalar without evidence.

## Preserved alternatives, not combined or accepted

- **Candidate B: Normal `EliteHealthScale`1.00→.90**, only after Candidate A has a complete measured result or if it is explicitly rejected before testing. Six solo elite thresholds would become171/252/184.5/274.5/198/306 instead of190/280/205/305/220/340. This shortens elite exposure without changing tells or player defense. It is less directly supported as the first fix because ordinary factory waves account for substantial attrition and final boss remaining percent is not recorded. Ten-percent less health is not ten-percent less damage, and earlier phase-two entry can alter summons/timing. Keep it as a separate experiment.
- **Factory wave3 eight→seven enemies on Normal**, removing one Warden while retaining all four role types, is a narrowly targeted later candidate if that wave remains the longest ordinary damage spike. It needs an explicit Normal-only budget/roster contract; directly changing the shared roster would also nerf Hard and Nightmare. The current data cannot show that Wardens rather than Grapplers/Brutes caused the pressure, so this is not selected now.
- **ClearHeal15→25 on Normal** would add at most20 extra healing before the final district across two clears, depending on low-percent clamps. It cannot address first-district stock loss and would need per-tier survival plumbing to avoid altering every tier. Do not combine it with Candidate A or treat it as an extra stock.
- Increasing starting stocks, restoring full stocks/percent on district travel, reverting the hit iframe to.38, reducing the solo token cap, weakening offscreen/tell guards, or improving HumanBot inputs would obscure the approved persistent-risk design or change multiple acceptance variables. These are not proposed first-line changes.
- **M4 food is absent.** Planned small15/large35 healing pickups are not evidence that current Normal is acceptable. Do not credit hypothetical pickup collection, automatic healing or future weapons in this baseline. Once implemented and physically validated, food will require a new campaign curve with its real collection policy and opportunity cost recorded.

## Decision and validation sequence

1. Complete the frozen15 trials, preserving defeats and all per-tier counts. Do not edit code or HumanBot to rescue remaining seeds. This note's three-run aggregates remain a dated diagnostic subset; append rather than replace later findings.
2. Root chooses one candidate after reviewing the full baseline. Implement under the appropriate WO-3.1 tuning checkpoint with an independent reviewer; record the exact scalar and source commit. This note itself grants no accepted tuning value.
3. Keep solo Gale/Guardian, fresh Practice profiles, no Heat, same five seed values and unchanged bot action policy. Run all five Normal seeds on the candidate; include all defeats. Paired seeds improve comparability but are not perfect deterministic replays: physics scheduling affects trajectories and bounty selection includes a fresh campaign GUID. Record those limits and actual bounty events if adding passive instrumentation.
4. Compare clear count (target3–4/5), mean stocks lost (target at least2), each district's loss/damage distribution, boss-entry stock/percent where newly observed, encounter duration, ranks/S frequency, caps, warning floor and actual frustum audits. Do not infer survival gains by simply subtracting10% from the old damage totals. Zero losses in district1 is not itself a required five-seed exact count; preserve the broader “rarely” human-facing target.
5. Rerun the changed Normal warning/Heat composition and actual tell fixtures, plus relevant multiplayer and lifecycle regressions. Hard/Nightmare math must remain unchanged for a Normal-only scalar. If source changes affect their behavior indirectly, rerun their campaign suite too. Do not merge old-build tiers into a new-build acceptance claim without clear provenance.
6. If Candidate A still misses the Normal target, preserve its result and choose the next isolated experiment. A passing five-seed sample still needs human Normal/Hard/Nightmare sessions, a full human co-op run on Normal and Hard, and the open M2/device gates. It is not almost-publish-ready certification.

## Measurement gaps to preserve

Current aggregates do not record stock and percent at each wave start, stock-loss reason (percent limit versus ringout), target boss percent at defeat, accepted damage by attacker/move, or actual bounty spawn/escape totals. Windup/action counts are not accepted-hit attribution. If root wants a stronger second diagnosis, add observation-only fields in a separate post-freeze telemetry checkpoint and retain the original bot inputs; do not label the missing values as zero. Existing camera motion observers measure passive desktop behavior, not nausea or physical-device comfort.
