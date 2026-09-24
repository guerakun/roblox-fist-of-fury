# Client work sequence after M2 freeze — proposed, not implemented

Prepared by presentation on 2026-09-24 while seeds 1104/1105 complete on frozen source `9f29012`. This document plans already-authorized M6 input corrections and M3 presentation. It does not change production behavior or close any work order. Root releases the source freeze, owns Studio execution and commits each independently reviewed work order. Presentation owns client code and tests; root owns shared Config and progression/travel contracts; combat owns action/state contracts. Do not combine all work into one unsaved diff.

## First checkpoint: M6 focus and modal fixes

Use the three findings in [ASSET_INPUT_REVIEW](ASSET_INPUT_REVIEW.md) as the exact scope. Add a small local input-lifecycle module only if it makes the real cleanup paths testable; do not create an abstract input framework. Main owns its held-key/vector/touch/guard state; CombatHUD owns settings drag state; CampaignTravel owns its intent gating.

1. Centralize Block release and held-input reset in Main. Process Block End/Cancel before text/menu gates. Reset local guard and movement ownership on text focus, window focus loss, modal opening and character replacement. Move touchInput/knob references into accessible scope, clear the input object and recenter the knob. Send the existing release intent; do not change combat timings, camera smoothing or server authority.
2. Clear CombatHUD slider drag on window/text focus loss and menu closure. Existing navigation restoration stays intact.
3. CampaignTravel uses the same text/menu eligibility predicate for both shortcut and button activation, retaining server availability/busy and local request cooldown. An open journal/settings panel consumes no return intent. Keep T/Y and the 44-pixel touch control.
4. Root executes deterministic event-sequence tests against actual helper/UI hooks: Block→text focus→End, Block→settings→close→Jump, movement/touch→focus loss→resume, slider→focus loss, character replacement and return while either modal is open. Assert no extra action requests and fresh input works after reset. Run affected UI bounds and camera regression. Physical chat/controller/touch remains a separate gate.

A different agent reviews the diff, fixes land, and root commits this M6 correction before any M3 UI edit. Test-only callback injection must not be exposed through a production remote.

## WO-3.2: revive input and persistent-stakes presentation

Combat's proposed single `Revive` action carries `{held=true/false,targetUserId=optional}`. Server chooses/validates the target, range, channel time, interruption and revived state. Presentation sends Begin once and release/cancel once; its helper clears the hold on focus/menu transitions, death, replacement and loss of availability. Never send client progress, completion, duration or revived stocks.

Proposed controls: V / L3 / a separate contextual touch hold. Existing instant R/R3 transfer becomes visibly `GIVE 1 STOCK`; do not label both actions simply Revive. Show a server progress bar and downed countdown, with elapsed display derived from server deadlines only if their clock basis is supplied. If no channel is available, explicitly hide/reset old progress. One Life disables stock sharing through server snapshot authority while preserving the channel action.

Required contract: exact `revive` fields, clock basis and false-clearing rules, downed expiry, canShareStock and stock cap. UI fixtures cover target change mid-hold, interruption, touch cancel, focus loss and short landscape safe areas. Root's two-client runtime fixture owns actual interruption/revival evidence.

## WO-3.3/3.4: style, immutable result and evolving receipt

Keep the continuous style meter compact in CombatHUD and away from boss tells. Server snapshots supply score, multiplier and progress; clients display them and never submit skill events or reward claims. Explicit `false` clears expired optional fields because Main currently merges snapshots.

Agreed server integration: Combat.FinalizeDistrict returns per-player immutable results; root Progression.AwardDistrict/GetDistrictReceipt owns the receipt; Combat includes the latest receipt in each snapshot. Final snapshot field names remain to be confirmed before wiring. Proposed display split:

- `combatResult`: immutable identity `campaignId:stage`, rank, score, duration/par time, damage taken and earned multiplier factors.
- Per-player eligible nominal base ledger: only that player's accepted encounter participation, never the whole district's theoretical total for a late arrival.
- `rewardReceipt`: matching result ID plus monotonically increasing revision, pending/paid/readOnly/capped status, nominal eligible base and actual capped base/bonus coin and XP deltas as needed for the displayed breakdown.

The distinct reward dedupe key has the literal suffix `:rank`, not the achieved rank letter. Only root/server calculates grants. A result panel opens once per result identity; later receipt revisions update amounts/status in place without replaying the rank reveal. A late old receipt or lower revision cannot replace a newer district/result. Pending/read-only states never say paid, and zero actual grant at the cap must remain zero. Display already-paid encounter base separately from the new district bonus to avoid suggesting that base paid twice. Keep final campaign totals separate from one district's receipt.

Required fixtures: same-ID pending→paid, same-ID capped zero, read-only failure, late/duplicate/out-of-order revision, next-district clearing, retry same identity, late-join base ledger and complete reward formatting. Root verifies actual grants/coin+XP dedupe independently. Layout reserves the CampaignTravel strip and preserves active combat warning space; result presentation must not silently pause authoritative combat.

## WO-3.5: desperation and skill feedback

Use one explicit server `Desperation` intent and server eligibility/cost. To preserve ordinary attack responsiveness, proposed gesture is ordered and clearly labeled: **HOLD SPECIAL + HEAVY** when Special is unavailable and server says desperation is eligible. During that state, Special Begin arms a local modifier without sending ordinary Special; Heavy Begin while armed sends one Desperation and suppresses Heavy. Release/cancel clears the modifier. Repeating Heavy while still armed must not fire repeatedly; require a fresh arm. Reverse-order input is an ordinary Heavy, not an implicit double-action chord. Final gesture needs combat/root agreement before implementation.

A separate touch control visibly states the current self-percent cost and uses an explicit short hold/confirmation gesture; it never piggybacks on accidental double taps. Exact hold time is an accessibility/UX choice still to finalize. Menus/focus loss, death, character change, loss of eligibility and server rejection clear the local arm. Normal attacks outside this eligibility state retain current immediate timing. Server still validates cooldown exception, cost, restrictions and action state.

Perfect block, bounty and greed feedback consume server events only. Critical danger cues remain visible at low VFX settings; score feedback cannot cover attack warnings. Required tests distinguish one gesture/one request from normal Special/Heavy, held repeats, cancellation, stale canDesperation and touch/controller paths. Costs must come from final Config/snapshot, not a second hardcoded economy.

## WO-3.6: Heat selection and reward disclosure

Replace Deploy's provisional six-entry descriptions/rewards with final shared Config metadata and explicit stable ordering. Display Heat points and earned reward percentage as different values. Root's proposal totals fifteen points and +105% before other factors; assert that against actual final Config rather than trusting this document. Unsupported entries remain unavailable. Party-leader selection, uniqueness, tier unlocks and immutable campaign options remain server checks.

Hub exists already, so use its deployment picker; add a temporary campaign picker only if root explicitly needs a local test fallback. Show server rejection/held-deployment messages. Do not promise badge awards with unconfigured IDs: source unlock predicates and actual live badge issuance have separate status. UI tests cover zero/all selections, one toggled entry, selected party snapshot, nonleader view, queued immutability, unknown entries and final reward-description agreement.

## WO-3.7: earned trade-off boons

Root owns Config/progression and combat enforces `canBlock`, `canDash`, damage/weight/style modifiers. Presentation reads final descriptions, XP thresholds, restrictions and selected-boon snapshot; no client attribute establishes entitlement. Existing saved selection remains until a server-accepted change. Make the downside visible before equipping and keep unavailable actions visibly explained. The source restriction remains authoritative even if a malicious client calls the remote directly.

## Closing evidence and handoff

Each work order needs independent source review, root's scoped fixture output, PROGRESS evidence and a separate commit/push. M2 baseline comparisons must remain untouched; M3 numbers are captured after authoritative systems and matching HUD contracts land. No source/static UI fixture substitutes for human Normal/Hard/Nightmare playtests, owner art approval, physical input or published permission tests. No publication, sales, live settings or v1.1 backlog is part of this client sequence.
