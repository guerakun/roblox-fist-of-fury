# M4 authored drop inventory - candidate only

Prepared during the M3 frozen tier trials on 2026-09-24. **Proposed and unimplemented; distribution is not accepted tuning.** This document inventories existing source and proposes one inspectable table for WO-4.2/4.3. It does not change gameplay, finalize a new runtime schema, run Studio or supply M4 acceptance evidence. The frozen trials receive no food, coin bags or weapons from these props.

## Source inventory and candidate identity

Source inspected: `src/server/WorldBuilder.lua` at the frozen gameplay revision `dfb2ae3bbb04d1408613e3e28b1f37fcc3f2b6f4`, its `destructible` helper and seven authored prop families; `src/server/DestructionService.lua`; and district limits in `src/shared/Config.lua`. The 34 models are all under `NightfallCity/StreetDetails`: one signal, four luggage, five drums, four crates, five vending machines, nine utility boxes and six benches. District totals are 8 / 12 / 14. Current attributes are Destructible, PropKind, Health and Broken; **the candidate IDs below are not current attributes**.

Candidate IDs use district, family and a zero-padded authored-X label, such as `D1.Vending.033`. Assign them explicitly if implementation is released. The number is a mnemonic from today's authored position, not a future spatial lookup rule: moving or renaming that same authored prop must preserve its ID. Never derive IDs from enumeration order, Random, Instance identity or a rebuilt model's generated identifier. A genuinely different new prop needs a new ID and an intentional table review. All candidate IDs below fit within 22 ASCII characters and contain only letters, digits and dots. Combat noted the existing reward key budget leaves 22 characters after a maximum-length campaign plus the proposed pickup separator; validate the eventual composed key length and delimiter safety before integration rather than truncating IDs. District eligibility must come from trusted authored metadata, not only parsing an ID prefix. Runtime field names and module/API shapes remain for owner coordination.

X/Z values locate the current primary geometry, not the future pickup sensor. All rows must be mapped explicitly, including None; unknown IDs must not acquire an implicit random/default drop. Food/coins are player-only; Husk competition is limited to weapons under the separate combat contract.

## Inspectable per-prop table

Small food removes up to 15 percent and large food up to 35, floored at zero. Coin bag means the root's proposal of 25 earned coins / 0 XP. Pipe, blade and bottle here identify a candidate type only; durability, damage, motion and event fields are not finalized by this inventory. None is an intentional no-drop entry.

### District 1 - Ashgate Crossing (8)

| Candidate stable ID | Existing model name | X / Z | Candidate drop | Placement rationale |
|---|---|---:|---|---|
| D1.Utility.025 | UtilityAssembly_25 | 25 / 11.8 | None | Opening dressing remains breakable without guaranteeing loot. |
| D1.Vending.033 | VendingAssembly_33 | 33 / -12.1 | Small food (15) | Early visible food source; already-undamaged players cannot gain healing. |
| D1.Bench.044 | BenchAssembly_44 | 44 / -12.2 | Pipe | Optional early melee pickup from broken furniture. |
| D1.Signal.075 | CrossingSignalAssembly | 75 / -15 | None | Tall edge landmark is not a reward target outside the lane. |
| D1.Utility.115 | UtilityAssembly_115 | 115 / 11.8 | Coin bag (25 / 0 XP) | Small optional reward on the opposite lane edge. |
| D1.Vending.129 | VendingAssembly_129 | 129 / -12.1 | Large food (35) | Later survival choice before the boss rather than an automatic clear refill. |
| D1.Bench.151 | BenchAssembly_151 | 151 / -12.2 | Bottle | Later fragile-weapon opportunity. |
| D1.Utility.166 | UtilityAssembly_166 | 166 / 11.8 | None | Exit-side scenery provides no additional guaranteed resource. |

### District 2 - Abandoned Station (12)

| Candidate stable ID | Existing model name | X / Z | Candidate drop | Placement rationale |
|---|---|---:|---|---|
| D2.Utility.203 | UtilityAssembly_203 | 203 / 11.8 | None | Entrance dressing. |
| D2.Vending.215 | VendingAssembly_215 | 215 / -12.1 | Small food (15) | Consistent recognizable food source. |
| D2.Luggage.220 | LostLuggage_220 | 220 / 11.8 | None | Avoid making every suitcase a reward. |
| D2.Bench.246 | BenchAssembly_246 | 246 / -12.2 | Pipe | Early platform weapon opportunity. |
| D2.Luggage.264 | LostLuggage_264 | 264 / 11.8 | None | Retains a meaningful search cost. |
| D2.Utility.281 | UtilityAssembly_281 | 281 / 11.8 | None | No second coin source. |
| D2.Luggage.294 | LostLuggage_294 | 294 / 11.8 | Coin bag (25 / 0 XP) | Optional luggage reward, independent of rank. |
| D2.Vending.303 | VendingAssembly_303 | 303 / -12.1 | Large food (35) | Mid/late-stage resource before the final platform fight. |
| D2.Bench.323 | BenchAssembly_323 | 323 / -12.2 | None | Prevent stacked resources beside the late food. |
| D2.Utility.336 | UtilityAssembly_336 | 336 / 11.8 | None | Boss-area dressing. |
| D2.Luggage.337 | LostLuggage_337 | 337 / 11.8 | Blade | Late optional weapon from abandoned equipment. |
| D2.Vending.347 | VendingAssembly_347 | 347 / -12.1 | None | No extra recovery merely for reaching the exit. |

### District 3 - Abandoned Factory (14)

| Candidate stable ID | Existing model name | X / Z | Candidate drop | Placement rationale |
|---|---|---:|---|---|
| D3.Crate.372 | ShippingCrate_372 | 372 / -12.1 | Blade | Early packed-tool opportunity; behind the spawn but within the district. |
| D3.Utility.380 | UtilityAssembly_380 | 380 / 11.8 | None | Entrance dressing. |
| D3.Drum.382 | ChemicalDrum_382 | 382 / 11.8 | None | Chemical drums are not food containers. |
| D3.Drum.407 | ChemicalDrum_407 | 407 / 11.8 | None | No early loot cluster. |
| D3.Bench.412 | BenchAssembly_412 | 412 / -12.2 | None | Breakable furniture without another weapon. |
| D3.Crate.420 | ShippingCrate_420 | 420 / -12.1 | Small food (15) | Packed supplies; early damaged actors may benefit. |
| D3.Utility.443 | UtilityAssembly_443 | 443 / 11.8 | None | Keep one coin bag per district. |
| D3.Drum.446 | ChemicalDrum_446 | 446 / 11.8 | Coin bag (25 / 0 XP) | Optional cache in industrial clutter; no healing implication. |
| D3.Crate.456 | ShippingCrate_456 | 456 / -12.1 | Large food (35) | Supply crate reachable before the final escalation; spend now or preserve it. |
| D3.Drum.469 | ChemicalDrum_469 | 469 / 11.8 | Bottle | Breakable bottle weapon, not a drink or food reward. |
| D3.Bench.480 | BenchAssembly_480 | 480 / -12.2 | None | No automatic weapon refresh for escalation. |
| D3.Drum.522 | ChemicalDrum_522 | 522 / 11.8 | None | Boss-side dressing. |
| D3.Utility.528 | UtilityAssembly_528 | 528 / 11.8 | None | Right-edge prop does not justify reaching past the walking gate. |
| D3.Crate.532 | ShippingCrate_532 | 532 / -12.1 | None | Avoid placing assumed boss healing beyond the current boss walking limit. |

## Budget and tuning rationale

| District | Props | Small / large food | Maximum food healing, party total | Coin bags / earned coins / XP | Weapons | None |
|---|---:|---:|---:|---:|---|---:|
| City | 8 | 1 / 1 | 50 percent | 1 / 25 / 0 | Pipe + bottle | 3 |
| Station | 12 | 1 / 1 | 50 percent | 1 / 25 / 0 | Pipe + blade | 7 |
| Factory | 14 | 1 / 1 | 50 percent | 1 / 25 / 0 | Blade + bottle | 9 |
| Campaign | 34 | 3 / 3 | 150 percent | 3 / 75 / 0 | 6: two of each type | 19 |

This candidate creates 15 possible emissions from 34 props, with no random rerolls and the same fixed party budget for 1-4 players. Fifty percent per district is a maximum cumulative reduction for the whole party, not 50 for every player, not damage prevention, and not a stock. Actual benefit is lower if the claimant has less percent, a drop expires, the prop is never broken, or another teammate wins the first eligible touch. Zero-percent food eligibility remains the earlier proposed exclusion, not implemented policy.

The equal district budget is deliberately modest and inspectable; it does not compensate for factory difficulty by granting a larger late heal. This is a proposed starting point without measured survival impact. Root's frozen M3 Normal/Hard/Nightmare trials must retain their original no-M4 interpretation. Nothing here establishes that food fixes the observed final-boss defeats or predicts new clear rates.

Players must choose to break and approach the prop using accepted combat actions; incidental accepted Heavy/Special breaks may also expose a drop. Merely moving to an encounter or clearing it does not grant food. The ten-second ground lifetime starts on emission, so intentionally leaving a prop intact differs from breaking it early and expecting food to wait. Side-edge locations create a retrieval choice, but camera visibility, current walking bounds and reachable floor placement require actual tests before calling the choice fair or readable.

Coin bags use one independent earned-only pickup payment of 25 coins / 0 XP. **Exclude them from encounter nominal base, rank bonus, bounty bonus and Heat/difficulty multipliers.** They must not inflate a later district bonus. A root-owned deduplicated pending/paid receipt may expose them separately; this document does not select receipt fields or bypass profile read-only behavior. No currency purchases or power sales are introduced.

## One budget through the whole campaign

Proposed invariant: one deterministic drop emission at most for a candidate prop ID within the authoritative campaign ID. The consumption ledger must survive Instance replacement and remain outside the WorldBuilder models. A campaign-wide prop-to-claimant binding is necessary: separate per-player payment journals alone cannot prevent two different players receiving the same prop budget.

- Reserve the prop's campaign budget once a valid current-district/current-walking-area accepted break emits its assigned item. No-drop entries remain explicitly empty on every break. Reject out-of-context gameplay emission before spending a future valid budget; cosmetic break behavior and its 20-second restoration remain separate.
- Claim, ten-second expiry, district-close cleanup, a missed pickup, a cosmetic restore/rebreak, checkpoint retry, player reconnect and a same-campaign world rebuild must never reopen the budget or reroll the item. Preserve the original ten-second lifetime through same-district Intermission/Traverse; clear leftovers at district close, stage change, retry or run reset, as specified in the proposed M4 reward contract. Do not copy score-orb cleanup at every transition out of Combat.
- A coin claim stays reserved to its original claimant through a pending/ambiguous payment. Neither retry nor a second toucher creates another payment. Root owns payment persistence and receipt details.
- A dropped held weapon retains its existing identity and remaining durability; this is a transfer of the emitted item, not a fresh prop reward. Weapon expiry, disarm and final-strike behavior remain in the separate M4 plan.
- Only a genuinely new server-authorized campaign resets the authored budget. Old delayed restore/expiry/claim callbacks must not operate on a new campaign or replacement record.

The table does not authorize dropping past a closed walking gate. Reject ineligible future-area emission; clamp a valid pickup's eventual floor location inside the current arena/lane without moving the player, moving the gate or altering the camera. Near-edge props and all candidate pickups still need an actual reachable-position fixture.

## Review and implementation gates still open

This document is source-derived inventory and a proposal, not 34 runtime-ID assertions. Before implementation, combat/root must agree exact stable-ID attachment, accepted-break context and ledger integration; presentation must agree readable kind labels/geometry. None of those interface fields is finalized here. Existing `WorldLifetime` evidence concerns cosmetic prop lifetimes, not these absent loot IDs or budgets.

After release, require a pure inventory check for 34 unique known models/IDs and exact 8/12/14 distribution, candidate amount/kind validation, actual accepted-break plus two-client first-touch tests, expiry/restore/retry/rebuild/new-run budget cases, coin receipt non-multiplication, and usable player/Husk weapon tests. Capture shared visuals and physical touch/gamepad behavior. Re-run measured campaign tuning with implemented pickups while preserving the frozen no-M4 series for comparison; any future bot-policy change must be explicit and separately versioned.

Preserved alternatives: more late factory food, party-scaled resource counts, random loot, personal copies and equal coin splitting remain unselected ideas. They are not silently removed from design history and must not be mixed into this fixed first-touch candidate without a documented decision.
