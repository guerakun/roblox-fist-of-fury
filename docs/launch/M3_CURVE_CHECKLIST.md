# M3 difficulty and rank validation checklist

Prepared 2026-09-24. This is a validation plan, not completed game evidence. Root alone runs Studio. It follows launch-plan sections 5 and 9 and the existing [HumanBot measurement contract](HUMANBOT_BASELINE.md).

## Fixed comparison

- Freeze a committed gameplay revision after the required M3 effects/restrictions are integrated and their scoped fixtures pass. Record the bot policy revision separately from observer-only changes. Do not mix tuning revisions within an acceptance series.
- Run **15 fresh solo practice sessions**: seeds **1101-1105** once each on Normal, Hard and Nightmare. Use the same first original hero, fresh Guardian/default practice profile and **no Heat contracts** for the tier curve. Record those settings; no earned upgrade or paid ownership should silently change a trial.
- Set the requested difficulty through the server test setup while Waiting, before the bot can ready. Confirm the resulting tier and empty Heat in the server/client observations. A test setup is not proof of production unlock/admission enforcement; those have separate fixtures.
- Keep the established action policy unchanged: 170-330 ms scheduled reaction, 75% tell recognition, 60/25/15 light/heavy/special attempts subject to range/cooldown, 40% recognized melee block choice, 30% AOE dash choice, and a mistake about every 5-7 seconds. Actual reaction delay may exceed the requested delay during frame stalls. Do not retrofit perfect defense, paid-risk gestures or targeting changes mid-series to reach a preferred result.
- No forced damage, character teleport, artificial kills, automatic retry or intervention during a trial. End at first Victory/Defeat; retain a 1200-second Timeout as a failed/incomplete observation, not a rerun to replace unfavorable evidence. A corrected infrastructure failure starts a separately labeled run/series and preserves the failed artifact.

## Capture and reconcile each run

- Save the final bot report plus server telemetry and the district observer. Collector wrapper fields are `difficulty`, `sourceCommit`, `botPolicyRevision`, and `bot` (the unmodified report). Keep provenance tied to the actual run, not a later working tree.
- Retain outcome, seed, first-Combat duration and wall time, stock losses by district, damage, all district results and receipt revisions, action choices, actual/scheduled reaction means, and telemetry. Missing values are unavailable, never zero or PASS.
- Include completed districts from a campaign that later loses. A Defeat in district 2 still contributes its district-1 rank. Deduplicate each frozen district identity; repeated receipt updates are not extra clears. Victory requires all three results/receipts.
- Reconcile stock totals against server per-player/per-encounter counters, and floored snapshot damage against the fractional server sum. Reconcile actual coin changes with the reward observer and separate base, rank bonus and bounty receipts. Timestamps can have documented report-delay differences.
- Attach the actual-camera frustum audit when claiming that fairness gate; the bot report alone does not contain it. Preserve invalid viewport samples, coverage counts and unavailable values. AI diversity windows shorter than 30 seconds remain ineligible. A solo run does not replace the separate 4-player/12-enemy MicroProfiler fixture.
- Before public evidence is committed, replace account identifiers with run-local aliases. Preserve numerical values and keep private originals in the existing ignored evidence directory.

## Measured acceptance

| Gate | Five-run interpretation |
|---|---|
| Normal clear rate 60-80% | 3/5 or 4/5 clears |
| Hard clear rate 30-50% | 2/5 clears (40% is the only representable value in range) |
| Nightmare clear rate below 20% | 0/5 clears; 1/5 is exactly20% and fails the strict target |
| Normal mean stocks lost at least2 | Sum losses from all five attempts /5 is at least2 |
| S ranks below25% of district clears | Count every completed district across all trials, including earlier clears in defeated campaigns; strict fraction below.25 |

Report per-tier S counts/fractions as well as the pooled fraction so one tier cannot conceal another's distribution. Zero completed districts has no measured rank frequency. Five trials give coarse 20-percentage-point resolution and do not establish statistical confidence. District-1 stock loss should be rare and the district-3 boss should be the most likely wipe; inspect district/encounter counters and report the observed distribution without inventing a numeric threshold absent from the plan.

`tools/summarize_tier_curve.py` accepts the 15 saved wrappers, verifies seeds/revision consistency, retains missing/invalid trial errors, and reports measured curve gates plus existing M0/M2 before numbers. Its exit0 means only the complete bot curve passed, exit1 means unmet/incomplete evidence, and exit2 indicates a CLI/file error. Synthetic tool checks belong under ignored `build/`, never the public gameplay evidence directory.

## Closure and tuning

Record before/after numbers side by side in PROGRESS: M0 Normal five-run baseline, frozen M2 Normal five-run series, and the new M3 tiers. Label the previous single seed1101 M3 diagnostic separately; its A/A/A result is not a five-run acceptance series. If tuning changes, commit the exact values/reason in COMBAT and rerun all affected acceptance comparisons on a consistent revision rather than pooling old and new outcomes.

This checklist does not add new feature scope. Bot acceptance does not close human/device, full multiplayer lifecycle, latency, real reconnect, live badge/persistence or publication gates. Record one human playtest per tier; the owner's full Normal/Hard co-op sessions and hero approval remain required. Human findings can override bot tuning, with both records retained.

## Public export integrity checkpoint

The known-schema collector now replaces generated run GUIDs as well as numeric account identifiers with run-local aliases. Matching result/receipt IDs retain the same alias; numbers, booleans and source/bot revisions are preserved. It rejects identity/credential fields, addresses, key collisions and any aliasing that would change protected provenance. `python -B tests/CurveReportPrivacy.spec.py` passed26 synthetic cases; five real Normal reports also passed root in-memory reconciliation/privacy checks. World independently reproduced rejection of both provenance collisions and all three telemetry-map collisions. The first four public files were refreshed with aliases only and all numerical/boolean measurements compared unchanged; raw originals remain ignored. This is validation of the inspected report schema, not a general arbitrary-data anonymizer or gameplay acceptance.

Two automatic approval checks paused public-evidence conversion/saving until these privacy checks were supplied. The tightened export was approved and proceeded; the separate SEC03 security-fixture restriction remains open. A temporary diagnostic-field name triggered the older privacy checker and was renamed before the final successful run. No failed gameplay attempt was discarded.


## Future encounter-entry observer (prepared, unrun)

After all15 frozen trials finish, install `tests/StyleCampaignEntryObserver.lua` as a sibling ModuleScript named `StyleCampaignEntryObserver` beside `StyleCampaignAI` in the test-only server tree. Install its spec as another ModuleScript and run `require(spec)(require(observer))`; only then replace the server observer with the prepared source and run an ordinary campaign with unchanged HumanBot actions. Presentation independently reviewed the reducer/integration and root inspected the diff; runtime remains unverified. Do not install any of these three changed files during the frozen series.

The new observer revision is `style-with-entry-elite-samples-v1`. It reuses the existing nominal0.2s snapshot pass, retaining at most64 first-observed Combat entries with stage/wave/observed attempt, stocks, floored percent, damage total, prior status and sampling gap. Exports identify truncation and unavailable values. The terminal elite is the last listed actor from the matching encounter, with sample age and whether it was actually present in the terminal snapshot. A first-observed state is not exact pre-hit entry; retries or transitions shorter than sampling can be missed, and last-observed elite percent is not lethal-hit percent. This adds no gameplay actions or extra polling; observer overhead is still unmeasured. Validate unchanged receipts/ranks as well as the new fields before using them to explain tuning outcomes.
