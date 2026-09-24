# M2 action-diversity follow-up - proposal only

Prepared 2026-09-24 during the frozen M3 tier series. **No implementation, metric change or new runtime result accompanies this note.** The two-actions-per-30-second requirement remains open. Root alone schedules Studio after the 15 frozen trials; no unfavorable run is replaced or discarded.

## What the saved evidence establishes

The [final M2 crowd report](evidence/m2-crowd-final.json), on gameplay source `9f29012`, covers 94.13 seconds with four players and twelve ordinary enemies. It passes its measured idle target (364/7638 = 4.76565%) but only **21/31 complete action-diversity windows pass**. Ten complete windows fail: six have zero recorded actions and four have one. Seven partial and twelve pending windows are not passing coverage. The harness's overall `passed` means orchestration completed, not behavior acceptance.

| Archetype | Passing complete windows | Minimum distinct actions |
|---|---:|---:|
| Husk | 4/6 | 0 |
| Strider | 4/5 | 0 |
| Grappler | 2/5 | 0 |
| Pitcher | 5/5 | 2 |
| Warden | 3/5 | 1 |
| Leaper | 3/5 | 0 |

World independently recomputed these counts. Eleven of the first twelve complete windows pass; the early failure records only Grappler `Grab`. Nine later failures begin roughly 52-60 seconds into the observed period. This pattern supports investigating lost attack opportunities as well as individual move variety; it does not establish the cause of every failure.

At the approximately 10- and 30-second diagnostic snapshots, all twelve actors report `canAttack=true`. At 60.27 seconds, three report false, the party spans X=64.21-170.00, and only three actors hold tokens. The latter snapshot includes six Hold, two Attack, two Reposition, one Approach and one Recover state. These are sparse snapshots, not continuous opportunity traces. Zero token-cap breaches and low stationary-idle time do not prove that every moving enemy can reach and attack a legal target.

The [M2 evidence record](M2_EVIDENCE.md) preserves earlier failed crowd runs, fixture-placement corrections, the separate solo frustum results and CPU capture. None of those separate passes substitutes for this diversity failure.

## Source-supported diagnosis and limits

`CombatTelemetry.Sample` opens engagement windows at the approximately 10 Hz AI cadence when a living non-Enter enemy is within 28 horizontal studs of any living player. Stun, recovery, blocked camera permission and lack of a reachable attack approach can still occur inside such a window. `ActionDiversity` excludes Approach, Hold, Engage, Enter and Reposition. Actual attack windups, block/evade, measured movement away during Retreat, and the actual delayed throw callback contribute actions. Cosmetic Hold feints do not.

Both Grappler move windups use the single `Grab` label. A successful delayed throw contributes `Throw`; merely choosing differently named grab moves cannot manufacture two actions. An early Grab-only window means there was no recorded completed throw in that window. It does not prove whether attempts missed, were interrupted or lost their target.

Combat's source review identifies a plausible later limitation: target scoring penalizes a hidden approach, but the director tests fixed near-target approach points while short melee moves still need roughly 6-7 studs. Queued follow-up jabs can override distance-selected moves. Conservative shared-camera bounds can leave a legal walking point too far from a displaced target to execute that short attack. The late snapshot's right-side targets and camera geometry are consistent with this mechanism. A leap/slide fallback is not automatically safe: landing or impact can still fail the existing visibility rule. This is a source-derived hypothesis, not a measured duration or a causal attribution for a particular failed window.

**The report has no stable per-actor identifier joining diversity windows to diagnostic actor records.** It has only three diagnostic snapshots. Telemetry player aliases and diagnostic player labels also use separate mappings. Do not join enemies by list order, kind, position guesses or player aliases, and do not claim a quantified fraction of failures was caused by the camera. Keep all ten failed complete windows.

The report predates M3 pressure, cooldown, risk/Heat and other combat changes. Current frozen M3 source is `dfb2ae3bbb04d1408613e3e28b1f37fcc3f2b6f4`. The historical report neither proves the same current failure rate nor demonstrates that later changes fixed it. No current source change is justified solely by assuming the old rate still applies.

## Proposed next diagnostic, before tuning

After the frozen series, run the latest unchanged gameplay in the original settled-start, freely drifting four-player/twelve-enemy scenario. Preserve party displacement; do not repeatedly reposition it to improve the result. A separately labeled reachable-party diagnostic may help distinguish geometry from move selection, but its controlled setup must not replace the original scenario or masquerade as ordinary co-op play.

Add bounded observer-only evidence, subject to root review: run-local sequential enemy aliases shared by diagnostic records and window summaries; per-window counts of visible/feasible approach samples, stun/recovery samples, token requests/grants, attempted grabs, captures and completed throws. Retain sample cadence, scope and missing/truncated fields. These are explanatory side measurements: keep the original 28-stud engagement denominator, 30-second duration, two-action target and ineligible partial windows unchanged. No new action labels or artificial attacks may be added to pass the test. These observers are proposed, not implemented or measured; overhead needs assessment.

If current evidence reproduces a missed-grab recovery problem, combat proposes one bounded candidate: after a resolved Grappler attempt that captured nobody, spend about 0.6 seconds stepping back toward a goal about 3 studs away, projected through the existing camera/arena constraints, then resume ordinary target selection. A successful capture/throw must not trigger it; record whether the attempt ever captured, rather than checking only an already-cleared grab pointer. Only actual away velocity above the existing 0.5-stud/second threshold may count as Retreat. Do not reset cooldowns or bypass tell duration, tokens, target eligibility or visibility. These are unaccepted starting values, not shipped tuning.

That candidate addresses a specific early failed attempt pattern. It does not fix the six later zero-action windows or prove universal two-action coverage. If no target offers a lawful attack approach, manufacturing defensive activity would hide the problem. Broader party spacing, arena or framing changes require a separate explicit decision and measured camera review.

Any accepted change needs source review, focused actual missed/captured/interrupted-grab fixtures, a rerun of both labeled crowd scenarios, camera/tell/token regression evidence and updated campaign comparison on one committed revision. Human co-op remains required. No metric relaxation, offscreen attacks, forced mid-run regrouping or v1.1 content is proposed.


## Limited observer source checkpoint (after the proposal above)

Root subsequently authorized a bounded observation-only patch on branch source. `EnemyOpportunityDiagnostics.lua` now supplies run-local enemy aliases shared by future diagnostic records and diversity-window summaries. It adds same-tick known/yes counts for existing visibility, fixed-slot feasibility and in-range checks, plus token requests/grants and grab attempts/captures. **Fixed-slot feasibility means the director's existing +/-4 approach check; it is not full move or landing reachability.** Early-return ticks without fresh context remain unavailable. Additional stun/recovery and completed-throw counters suggested above remain proposed, not implemented.

World independently source-reviewed the hooks, boundary attribution, weak actor references, departure cleanup and explicit bounds (1024 aliases, 1024 detailed windows and 64 pending events per actor). Existing diversity eligibility, action sets, duration and pass criteria are unchanged; no additional geometry queries or gameplay decisions were added. Root reports **26 pure injected assertions PASS**, including observed-versus-plain diversity replay. This tests supplied states, not an actual crowd or a performance budget.

This patch is on disk only at this checkpoint. The installed campaign continues the frozen15-trial series on `dfb2ae3bbb04d1408613e3e28b1f37fcc3f2b6f4`; it has not collected these new fields. Actual joined diagnostics, lifecycle observation and overhead remain unverified. Historical windows cannot acquire retroactive actor joins, and the21/31 M2 failure remains open. The proposed Grappler backstep is still unimplemented and unaccepted.
