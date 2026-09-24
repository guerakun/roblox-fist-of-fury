# M3 server integration proposal — not implemented

Prepared by root during the frozen M2 bot comparison. These are proposed integration decisions for the already-approved M3 work, not claims that M3 exists. The work-order sequence and current status remain in [LAUNCH_PLAN](LAUNCH_PLAN.md) and [PROGRESS](../PROGRESS.md). Combat, root and presentation must reconcile the exact interfaces before source edits.

## Rewards without duplicate base payments

Retain the existing server-owned encounter base rewards and their campaign:stage:wave keys. At district completion, compute a server result with a stable campaign:stage identity and grant only the additional rank/Heat/tier reward under a separate campaign:stage:rank key. A retry must never grant the same base or bonus key again. Record the actual capped coin/XP deltas, including unavailable profile state; do not display an intended grant as paid.

Proposed multiplier composition is rank × Heat × difficulty. Rank starts at D/C=1.00, B=1.15, A=1.30 and S=1.50. Heat is 1 + the sum of selected reward percentages / 100. Proposed earned difficulty bonuses are Normal=1.00, Hard=1.15 and Nightmare=1.30; the launch plan requests better tier rewards without specifying those values, so these are root's starting proposal and require tuning evidence. Track an eligible nominal encounter base ledger separately for each player, so late arrivals cannot receive bonuses for encounters they missed. Keep nominal base separate from actual capped/read-only deltas. The district bonus is floor(eligible nominal base � (total multiplier - 1)), then capped once at grant time. The suffix `:rank` is a literal namespace, never the actual grade; retrying with an improved grade cannot create another payout. No real currency buys any multiplier or combat stat.

Combat/Encounter should finalize an immutable combat result after the boss base reward is known and before district advance. Fields include `id`, `campaignId`, `stage`, `rank`, `score`, `duration`, `parTime`, and `damageTaken`. Keep a separate per-player reward receipt with `resultId`, `revision`, eligible `baseCoins`/`baseXP`, `rankMultiplier`, `heatMultiplier`, `difficultyMultiplier`, actual `coins`/`xp` and `status` (pending/paid/readOnly/capped). A pending receipt may update without changing the combat result. UI must refresh a receipt for the same result ID without replaying the rank entrance, and never display intended rewards as paid. Clients never submit rank, score, amounts or reward keys. Pending profile loads and replayed callbacks retain deduplication.

Bounty reward keys must use a stable campaign:stage:wave:bounty identity, not a newly spawned enemy instance ID on every retry. Score-orb lifetime or collection cannot create a second encounter payment.

## Heat points and rewards

The plan names badge thresholds 5/10/15 but does not assign point weights. The following proposed weights make all three thresholds attainable with six contracts; reward percentages stay at the plan's starting values.

| Contract | Proposed Heat points | Extra earned reward |
|---|---:|---:|
| Frenzy | 1 | 10% |
| Short Fuse | 2 | 15% |
| Iron Hide | 2 | 10% |
| No Safety Net | 3 | 20% |
| One Life | 5 | 35% |
| Mutated Elites | 2 | 15% |

Maximum selection is 15 points and +105% Heat reward before other multipliers. Keep the point score separate from reward percentage in match records, UI, badge checks and leaderboard inputs. The server validates known unique IDs, the authoritative party leader and every member's difficulty unlock before queueing. Campaign options become immutable after admission/start. Client metadata is never the source of truth.

Short Fuse composes with difficulty before the final 0.30-second warning floor. Frenzy adds one token to the same cap used by scheduling, shrink/cancellation and telemetry. Iron Hide applies to ordinary-enemy threshold only. No Safety Net keeps the retry at the district entrance. One Life caps stocks at one and disables instant stock sharing while preserving the planned channel revive; district/retry behavior must honor that cap. Mutated Elites needs a real authored extra phase-two move and explicit tests, not a metadata-only reward switch.

Badge and exclusive-cosmetic predicates can be implemented and tested with fake adapters. Real badge IDs remain zero/unconfigured until the owner's later test-universe action; no live badge creation or award is authorized tonight.

## Boon interface

Root's progression modifiers should expose earned-only `damageMultiplier`, `damageTakenMultiplier`, `styleGainMultiplier`, `weightMultiplier`, `canBlock` and `canDash`, alongside existing values. Proposed new earned-XP thresholds are Glass Cannon=600, Berserker=800 and Anchor=1000. Combat must enforce the restrictions at authoritative action/hit paths; hiding a button is not enforcement. Existing saves retain their current boon until the player makes an allowed selection. These XP thresholds are provisional until implemented and recorded in COMBAT/economy notes.

## Evidence boundary

The proposal does not close WO-3.4, WO-3.6 or WO-3.7. Required next evidence includes pure arithmetic/admission/forgery tests, actual accepted grants, retry deduplication for coins and XP, server options immutability, boon restrictions, UI agreement and the M3 difficulty/rank bot comparisons. Human/device and published-service gates remain separate.
