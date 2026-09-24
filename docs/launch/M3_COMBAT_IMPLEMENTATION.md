# M3 combat implementation handoff — proposed only

Prepared during the M2 production freeze at `9f29012`. No M3 production source has been changed. Root releases implementation after its five-run/crowd checkpoint; root alone runs Studio, commits and pushes. Every order still requires independent review and a separate checkpoint. Human and device gates remain open when unavailable.

## Ownership and sequence

Combat owns WO-3.1, 3.2, 3.3 and 3.5 source; presentation owns their client interfaces. Root owns reward grants (3.4), Heat configuration/rules (3.6), boon progression (3.7). Root temporarily delegates **only pressure and stock scalar edits in Config** for 3.1/3.2 to combat after release. Other Config changes need root coordination. SEC-03 movement enforcement is a separate proposal and must not slip into these orders.

### WO-3.1 pressure

- Extract small pure pressure decisions for accepted-hit protection and Burst eligibility, with table-driven clock cases. Set normal hit protection to .15 s; three accepted hits within 1.5 s produce .8 s protection. Clear the recent-hit cluster after its breaker triggers and on a new life; rejected hits do not add samples. Accepted chip hits count, but the later perfect block path must bypass both damage and this counter.
- Dash during hitstun retains the existing .16 s minimum delay, adds 8 percent and a separate four-second Burst cooldown. Normal dash keeps its existing cooldown. Charge only after every dash eligibility check succeeds, never from a rejected request. Resolve a cost that reaches the percent limit through normal KO processing before any dash impulse. Anchor's later no-dash rule must block Burst too.
- Replace per-enemy-kind extra-player scaling with **two total extra enemies per additional player** on ordinary waves. Keep the frozen party count and pulse planning. Distribute extras deterministically across the authored composition. Root-approved base counts rise to 5–8. Elite waves retain one initial elite and existing phase adds.
- Preserve current post-difficulty .30 s tell floor, tokens, camera checks and all measured M2 observers. Record precise cooldown/wave decisions before changing them. Do not simultaneously retune enemy tactics.

Evidence: pure time-boundary cases, all 24 ordinary-wave/party combinations, actual accepted/rejected Burst requests, cost-triggered KO, no free dash during cooldown, and root HumanBot comparisons. Existing EnemyWave expectations need updating with the new total-scaling policy, not deleting.

### WO-3.2 persistence and rescue

Separate campaign start, district travel, retry and stock respawn. The current `resetPosition` zeros percent and the current `ResetPlayers` refills every district; callers must become explicit rather than attempting to restore values around asynchronous character setup.

Proposed public lifecycle calls:

| Call | Behavior |
|---|---|
| `BeginRun(campaignId)` | New campaign statistics/survival; three stocks and zero percent, modified only by immutable run rules. |
| `EnterDistrict(position, stage)` | Relocate safely while preserving survival, clear obsolete action/revive state and invalidate old life callbacks. |
| `CompleteDistrict(campaignId, stage)` | Exactly once: minus 15 percent and plus one stock up to the run cap, including disconnected survival records. |
| `RetryCheckpoint(position, stage)` | Two stocks and zero percent, clamped by run stock cap; reset multiplier, preserve campaign reward identity. |

Keep compatibility for root test fixtures that call `ResetPlayers` explicitly, but replace production encounter use. Reconnect, hero replacement, dead-character replacement and delayed stock spawns must all carry the correct survival reason. District completion may recover an eliminated teammate with its earned stock; a retry is the only wipe recovery.

At zero stocks create a 12-second downed window at a bounded, reachable ground position; do not retain the old checkpoint-plus-20-stud location for a proximity channel. A teammate within eight horizontal studs holds `Revive {held=true,targetUserId?}` for 2.5 seconds. Server checks both identities/lives, distance, movement, accepted damage, alive state and time throughout. Release, focus/menu cancellation, departure, travel lock and character replacement end the channel. Only one channel can win a target. Restore one stock/60 percent and normal protected setup without a later reset to zero. Expiry ends channel revival; existing instant stock sharing stays a separate costly path, subject to One Life disabling it. Preserve same-campaign reconnect expiry rather than refreshing the 12-second window.

All-player wipe must not defeat early while a viable teammate/channel exists; all players downed with no living rescuer remains a wipe. No Safety Net suppresses the miniboss checkpoint update. One Life clamps initial/retry/clear stocks to one and leaves the channel usable. Root RunRules supplies these immutable decisions once implemented.

Evidence: revise MultiplayerLifecycle cases 3–5; actual two-client success/interruption/expiry/race; solo wipe; repeated retry; district travel; disconnected survival; stock-share conservation; old-life callback rejection; One Life and No Safety Net combinations when root rules land.

### WO-3.3 score, rank and finalization

Server records accepted damage/skill events, not client score. A pure style policy owns x1–x4 progression, hit penalty and rank calculation. Record final thresholds/par times in COMBAT; values require bot tuning. Air/throw events only count when those mechanics exist. Score events need real accepted effects; no placeholder awards for unimplemented actions.

Retry farming needs an explicit score policy in addition to coin keys. Proposed: keep per-wave best completed-attempt score, with transient current-attempt score; retry discards failed-attempt points and resets multiplier. Duration and damage taken accumulate across retries. Replayed resolved effects and a stable enemy/drop identity cannot award twice within an attempt. This proposal must be reviewed against the intended reward curve before implementation.

Reward handoff approved by root for implementation after release (not implemented yet):

1. `Progression.AwardEncounterClear(participants, stage, kind, campaign:stage:wave)` records each player's eligible nominal base and actual capped delta. Progression owns this ledger.
2. After the boss base award, `Combat.FinalizeDistrict(campaignId, stage)` returns frozen per-player performance results keyed by Player: `{id,campaignId,stage,rank,score,duration,parTime,damageTaken,difficulty,heat}`. `id` is the stable campaign:stage identity. Finalization is idempotent and occurs before Advance/Victory.
3. Encounter calls `Progression.AwardDistrict(player,result)`. Root obtains nominal eligible bases internally, grants only the multiplier bonus under a literal `:rank` namespace, and stores a separate payout receipt.
4. Snapshot exposes `districtResult` plus `districtReceipt=Progression.GetDistrictReceipt(player,result.id)` when available. Pending receipt changes never mutate the frozen performance result. Missing/expired fields clear with `false` because Main merges snapshots.

No client supplies a result, key, rank, amount or Heat multiplier. A late joiner receives only bonuses on that player's eligible bases. First completion's result is immutable even if a callback replays with another grade. Cap/read-only/pending statuses show actual outcomes, not promised rewards.

Evidence: style event fixtures, retry/late join/finalize replay, per-player result isolation, timing/damage rank boundaries, visible result/receipt updates. Root owns grant forgery/deduplication tests. S-rank frequency and difficulty curve remain measured acceptance gates.

### WO-3.5 optional paid-in-risk actions

- `Desperation` is a distinct rate-limited server action available only while ordinary Special is on cooldown. It pays 12 percent, respects busy/stun/grab/boon/travel state and uses the real Special hitbox/cancellation path. Bound repeat use with an explicit cooldown decided and documented before implementation. Cost-triggered KO prevents an attack from the dead life. Snapshot exposes `canDesperation`, cost and remaining cooldown.
- Presentation proposes **hold Special, then Heavy**, only during eligible cooldown; Special arms a modifier and Heavy sends one Desperation without a second normal attack. Normal attacks retain immediate dispatch. Touch gets a labeled explicit cost button. Release/focus/menu/death clears the modifier.
- Perfect block timestamps only a server-accepted transition from unblocked to blocked. Held/spammed `true` requests cannot refresh it. Within .12 seconds: zero chip, .6-second attacker stagger, one style level; cancel captured enemy attacks/director tokens consistently, retaining fairness and multi-volume deduplication.
- Bounty selection/escape uses a real enemy lifecycle and server timer; stable campaign:stage:wave:bounty reward identity survives retries. A bounty escaping after eight seconds cannot keep a cleared encounter waiting forever or pay after escape. Root reward API needed before grant integration.
- Score orbs expire after five seconds, are claimed once server-side with bounded range/state checks and share a stable drop identity. No client amount claims. These award score, not an extra encounter payment. SEC-03 origin limitations remain documented rather than claimed solved by range checking.

Evidence: accepted/denied/cost-KO Desperation, true-transition block timing and repeated multi-volume calls, canceled throw/projectile, bounty KO/escape/retry, duplicate/expired/forged orb claim, UI/chord checks and actual runtime artifacts. Physical touch/controller remains an owner gate if unavailable.

## Fixture scaffolding status

`tests/fixtures/m3/PressureCases.lua` contains input/expected-value cases for future pressure policy specs. It is data only: no production imports, no test runner registration and no assertion that the feature exists. Root must run the eventual executable spec and actual request fixture after implementation. The remaining evidence matrix above is planned, not passed.
