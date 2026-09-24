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

Agreed server integration: Combat.FinalizeDistrict returns per-player immutable results; root Progression.AwardDistrict/GetDistrictReceipt owns the receipt; Combat includes the latest receipt in each snapshot. Agreed snapshot field names are districtResult and districtReceipt. Display split:

- `districtResult`: immutable identity `campaignId:stage`, rank, score, duration/par time, damage taken and earned multiplier factors.
- Per-player eligible nominal base ledger: only that player's accepted encounter participation, never the whole district's theoretical total for a late arrival.
- `districtReceipt`: resultId plus monotonically increasing revision, pending/paid/readOnly/capped status, baseCoins/baseXP as nominal eligible base, basePaidCoins/basePaidXP as actual base already paid, and coins/xp as actual BONUS ONLY. Multiplier fields explain server arithmetic but never prove payment.

The distinct reward dedupe key has the literal suffix `:rank`, not the achieved rank letter. Only root/server calculates grants. A result panel opens once per result identity; later receipt revisions update amounts/status in place without replaying the rank reveal. A late old receipt or lower revision cannot replace a newer district/result. Pending/read-only states never say paid, and zero actual grant at the cap must remain zero. Display basePaidCoins/basePaidXP separately from bonus-only coins/xp to avoid suggesting that base paid twice. If showing an actual district total, sum those actual paid fields; never show nominal multiplied totals as paid. Keep final campaign totals separate from one district's receipt.

Required fixtures: same-ID pending→paid, same-ID capped zero, read-only failure, late/duplicate/out-of-order revision, next-district clearing, retry same identity, late-join base ledger and complete reward formatting. Root verifies actual grants/coin+XP dedupe independently. Layout reserves the CampaignTravel strip and preserves active combat warning space; result presentation must not silently pause authoritative combat.

## WO-3.5: desperation and skill feedback

Use one explicit server `Desperation` intent and server canDesperation/desperationCost/desperationCooldown fields (cooldown tuning still pending). To preserve ordinary attack responsiveness, combat and presentation agreed the gesture is ordered and clearly labeled: **HOLD SPECIAL + HEAVY** when Special is unavailable and server says desperation is eligible. During that state, Special Begin arms a local modifier without sending ordinary Special; Heavy Begin while armed sends one Desperation and suppresses Heavy. Release/cancel clears the modifier. Repeating Heavy while still armed must not fire repeatedly; require a fresh arm. Reverse-order input is an ordinary Heavy, not an implicit double-action chord. Combat accepted this ordered gesture during planning; implementation and device evidence remain pending.

A separate touch control visibly states the current self-percent cost and uses an explicit short hold/confirmation gesture; it never piggybacks on accidental double taps. Exact hold time is an accessibility/UX choice still to finalize. Menus/focus loss, death, character change, loss of eligibility and server rejection clear the local arm. Normal attacks outside this eligibility state retain current immediate timing. Server still validates cooldown exception, cost, restrictions and action state.

Perfect block, bounty and greed feedback consume server events only. Critical danger cues remain visible at low VFX settings; score feedback cannot cover attack warnings. Required tests distinguish one gesture/one request from normal Special/Heavy, held repeats, cancellation, stale canDesperation and touch/controller paths. Costs must come from final Config/snapshot, not a second hardcoded economy.

## WO-3.6: Heat selection and reward disclosure

Replace Deploy's provisional six-entry descriptions/rewards with Shared.HeatConfig directly: Order and Contracts, with contract fields Id, Name, Description, Points and RewardPercent. Root owns Normalize/Rules and will expose Config.HeatContracts as the same Contracts table after combat's Config pressure edit finishes. Display Heat points and earned reward percentage as different values. Root's proposal totals fifteen points and +105% before other factors; assert that against actual final Config rather than trusting this document. Unsupported entries remain unavailable. Party-leader selection, uniqueness, tier unlocks and immutable campaign options remain server checks.

Hub exists already, so use its deployment picker; add a temporary campaign picker only if root explicitly needs a local test fallback. Show server rejection/held-deployment messages. Do not promise badge awards with unconfigured IDs: source unlock predicates and actual live badge issuance have separate status. UI tests cover zero/all selections, one toggled entry, selected party snapshot, nonleader view, queued immutability, unknown entries and final reward-description agreement.

## WO-3.7: earned trade-off boons

Root owns Config/progression and combat enforces `canBlock`, `canDash`, damage/weight/style modifiers. Presentation reads final descriptions, XP thresholds, restrictions and selected-boon snapshot; no client attribute establishes entitlement. Existing saved selection remains until a server-accepted change. Make the downside visible before equipping and keep unavailable actions visibly explained. The source restriction remains authoritative even if a malicious client calls the remote directly.

## Closing evidence and handoff

Each work order needs independent source review, root's scoped fixture output, PROGRESS evidence and a separate commit/push. M2 baseline comparisons must remain untouched; M3 numbers are captured after authoritative systems and matching HUD contracts land. No source/static UI fixture substitutes for human Normal/Hard/Nightmare playtests, owner art approval, physical input or published permission tests. No publication, sales, live settings or v1.1 backlog is part of this client sequence.


## WO-3.2 client implementation checkpoint — 2026-09-24

After root released the M2 freeze and saved M6 focus cleanup as `ee39b9c`, presentation implemented `ReviveControl` and `ReviveHUD`, integrated through CombatHUD. The exact server snapshot is `revive=false` or `{targetUserId,name,canStart,channeling,progress,remaining}`, with `downedRemaining` for the recipient; both remaining values are relative seconds, not clocks to interpolate. Controls are V/L3/contextual pointer hold. Begin sends only held=true and the selected target ID; cancellation sends held=false. Display progress never completes the action locally. Repeated Begin/End, changed target, channel interruption, expired window, downed/end/lobby state, focus/modal changes and character lifecycle cancel the hold. Stock sharing now labels its target `TO`, preserving its separate R/R3 intent.

The rescue controls share the existing bottom HUD row; each is 50 pixels high, with width bounded for a 320-pixel safe frame. Server warning placement and camera calculations are unchanged. `tests/ReviveControl.spec.lua` covers intent/clear/cancellation policy; `tests/ReviveHUDClient.spec.lua` covers actual widgets at 320/360/650/1280 safe widths, touch/desktop layout, modal release, server progress and recipient expiry. These tests are queued for root Studio execution, not yet recorded as passed. Physical touch/controller hold, full-scene occlusion and human co-op readability remain separate gates.


### WO-3.2 narrow-touch review correction

World's source review found that the first rescue row overlapped the existing joystick and attack pad on narrow touch viewports. That version was preserved as WIP, not accepted. Presentation added a contextual 60-pixel footer reservation: the shared `RescueTouchLayout` shifts existing touch controls above the rescue row, and Main retains a compact percent/stocks strip above the joystick on short landscape screens. The fixture now includes actual GUI widgets for the legacy joystick/attack/jump bounds and applies the same layout helper, in addition to checking rescue siblings. This is an isolated geometric fixture; full-scene screenshots and physical input remain separate. `travelLocked` is now an explicit local eligibility rejection in addition to the authoritative server rejection. Studio reruns and independent final review remain queued.


## WO-3.3 client implementation checkpoint — 2026-09-24

Root saved the tested revive work as `00f701a` before presentation began the style/result UI. `DistrictResultModel` accepts server `style={score,multiplier,progress}`, freezes the first performance record for each active result ID, and accepts only matching, newer receipt revisions. Explicit false clears the active result/receipt; replayed same-ID results do not replay entrance. The bounded entrance history retains 32 result IDs. Lower-stage snapshots from the same campaign cannot replace the active district. Receipt formatting uses actual `basePaidCoins/basePaidXP` separately from bonus-only `coins/xp`; it never computes an intended multiplied amount. False multipliers display pending. Pending, read-only, capped, and journal-capacity states have separate labels.

`DistrictHUD` shows a compact style meter above the health card. Its rank card opens once in Advance/Intermission/Victory/Defeat and is hidden during Combat; subsequent reward revisions update the dismissed/open state in place. The scrollable card reserves the existing 96-pixel return strip when active. The close target is at least 44 pixels; N toggles on keyboard, pointer activation handles touch, and focused A/B handles the contextual controller card. Main only passes its existing health-card reference; no camera or combat authority changed.

Queued root fixtures: `DistrictResultModel.spec.lua` for immutable performance, actual-vs-nominal amounts, bonus-only formatting, pending-to-paid revisions, stale/duplicate/foreign receipts, cap/read-only/capacity states, retry/false clearing and style bounds; `DistrictHUDClient.spec.lua` for actual widgets at 320x320, 360x640, 650x320 and 1280x720 with/without return reservation, pending-to-paid updates without another reveal, modal hiding, combat hiding and clear state. Independent world review and Studio results are pending at this checkpoint. Physical input, complete shared-scene occlusion and human readability remain separate.


### WO-3.3 independent review and actual Studio evidence

World independently reviewed the final client source and passed the receipt identity/revision rules, actual base/bonus separation, failure labels, status gating, return reservation and close target. Root then reported actual Studio PASS: `DistrictResultModel.spec.lua` **25 checks**; `DistrictHUDClient.spec.lua` **4 viewports x 2 return-reservation cases**, minimum close target **44 pixels**, actual payment labels, receipt updates without a repeated reveal, and rank hidden during Combat. Separate root server evidence: Style **54 pure cases** and an actual one-client StyleQA accepted score **1900**, rank **B**, **264 actual coins**, exact reward-observer accounting, retry deduplication and persistent boss damage. These are scoped tests, not a human difficulty/rank acceptance run. Physical A/B/N dispatch, touch scrolling, controller focus and shared-scene readability remain unverified.

For the prior WO-3.2 checkpoint, the persisted raw [m3-survival evidence](evidence/m3-survival.json) records Survival **39** pure cases, ReviveControl **24** requests, actual two-client channel/hit/movement/release-throttle/expiry/travel/retry/clear cases, and the client **4 widths x 2 layouts**, **44-pixel minimum** and rescue-vs-existing-control bounds. That work was saved as `00f701a`; the earlier failed Registered enemy KO fixture is retained in progress history.


## Separate WO-3.6/3.7 disabled UI checkpoints — 2026-09-24

While the campaign WO-3.3 source remains fixed for root's ordinary bot, root authorized changes to the separate hub picker and progression affordances. Hub `HeatDisplay`/Deploy now read Shared.HeatConfig.Enabled, Order and Contracts. The disabled gate removes selected IDs from requests and makes controls unavailable; it is not activated by these changes. Enabled-mode test copies verify all six definitions total **15 Heat points** and **+105% earned reward**, kept as separate quantities. Leader/queued checks run again on activation. Tests are `HeatDisplay.spec.lua` and actual hub `HeatUIClient.spec.lua`; fixture copies never mutate the production flag.

`BoonDisplay`/ProgressionUI list enabled boons first, show disabled entries as NOT AVAILABLE despite XP or a stale equipped ID, and recheck the current server snapshot before sending an equip intent. The existing between-fight gate remains. Boon buttons are 44 pixels tall, and focus restoration skips unselectable entries. Server enforcement is independent. The new Glass Cannon/Berserker/Anchor definitions remain disabled; nothing is sold or enabled here. World independent source review passed both UI changes. Root reported **17 pure BoonDisplay cases passed**; isolated actual widget rendering is queued with injected modules/config to avoid mutating the active bot's production configuration. Widget tests do not establish full journal layout, physical gamepad/touch activation, or enabled server effects.


## WO-3.5 client implementation checkpoint — 2026-09-24

Root saved WO-3.3 as `bc4c870` before releasing these client changes. `DesperationControl` accepts the ordered Special-then-Heavy gesture only while the server advertises eligibility, a finite self-percent cost and zero relative desperation cooldown. Ordinary actions remain immediate; an earlier normal Special press cannot become a paid modifier when the snapshot later changes. Repeated Heavy while the same modifier is held emits at most one Desperation intent. Special release/cancel, focus/menu/life reset, travel, downed state and lost eligibility clear it. The only request payload in Main is direction; no amount or result is submitted.

On touch, a separate orange HOLD / DESPERATION / +cost SELF button occupies the existing Special tile while eligible. It requires a new pointer press held for **.35 seconds**, with local confirmation progress; that progress has no server-cost authority. It does not inherit a finger that cast normal Special. The minimum existing .8 ability scale yields a **48-pixel**-tall target. The cost comes from the snapshot. Switching away from touch cancels a pending touch hold without clearing an independently armed keyboard chord. No camera interpolation, framing, damage volume or combat timing changed.

`RiskFeedback` consumes the combat agent's accepted PerfectBlock, Desperation, BountySpawn/BountyEscape and ScoreOrbClaim events. It uses bounded, duplicate-replacing native Highlights, an occluded bounty marker and local notices; it submits no hit/score/reward. Flash lifetimes are .35-.45 seconds and the bounty marker has a 35-second maximum life plus normal model destruction/escape cleanup. Orb notices throttle to .4 seconds. Existing original Special poses/Toolbox animation sampling remain intact.

District receipts now include a third BOUNTY RECEIVED line from actual `bountyCoins/bountyXP`, separate from actual base and rank bonus. Missing old-schema bounty fields default to zero; negative/nonfinite/nonnumeric values display unknown instead of a fabricated payment. No client multiplier touches bounty amounts. Tests queued for root: DesperationControl, actual DesperationHUDClient widget/hold geometry, RiskFeedbackClient cue cleanup and extended DistrictResultModel/DistrictHUDClient receipt cases. World independent review is requested; no runtime or physical-input pass is claimed yet.

Separately, root reported the disabled-boon actual widget fixture passed all **six items** with a **44-pixel** minimum, saved with `c6b48a3`. That fixture remains narrower than full journal geometry or physical input and does not enable the new modifiers. Heat hub integration tests remain with root.


### WO-3.5 source review follow-up

Combat and world independently passed the final client gesture, replacement-tile layout, accepted-event feedback and separate bounty receipt display. A gamepad used on a touch-capable device now retains the B+Y chord caption. The bounty marker's maximum distance is 200 studs to cover the authored camera's wider co-op framing; world made the same correction to the native STYLE orb label. Both remain occluded by world geometry. These are display corrections, not camera changes. New gesture/widget/FX fixtures remain queued for root; actual hardware dispatch is still unverified.

The separate disabled Heat UI checkpoint is saved as `48c85af`. Root's [m3-heat-ui evidence](evidence/m3-heat-ui.json) records **35 pure checks**, **six actual hub buttons** and **18 metadata renderer cases**, with production Heat disabled. Presentation independently inspected the corrected JPEG artifact: the short-landscape view shows the unavailable heading, first disabled Frenzy row, separate zero-point/zero-reward disclosure and match button. It does not show all six contracts or establish physical scrolling/controller interaction.


### WO-3.7 client capability guards (2026-09-24, source implemented; runtime queued)

`ActionCapabilities` consumes server `canBlock`/`canDash` booleans; omitted legacy fields default to allowed. Main rejects disabled guard begins and Dash before held state, remote requests or optimistic action poses. The touch guard cannot capture a disabled hold. Revoking an existing guard releases it once; normal release remains unconditional through focus/modal gates. Reenabling a capability does not synthesize a press. Jump and Recovery retain their ordinary paths, so an unavailable guard cannot create local blocking and suppress jumping. The server separately clears acknowledged Blocking and enforces restrictions; the client never computes boon damage, style, weight or reward modifiers.

Ability widgets use NO GUARD / NO DASH captions and disable activation/selection while restricted, then restore normal names/cooldowns. Existing XP/rollout boon UI stays unchanged. `ActionCapabilities.spec.lua` exercises policy/defaults/cancellation; `ActionCapabilitiesClient.spec.lua` checks real widgets at 0.8/1 scale with a minimum 44px target. These fixtures do not prove physical-key/touch/gamepad dispatch. Actual Studio execution is queued with root, and the rollout flags remain unchanged.

The separately staged WO-3.6 `MutatedCrossfire` mapping reuses the authored Swing pose for anticipation/strike; it does not change server floor footprints. The enemy presentation fixture now includes 16 move IDs, 32 pose cases. Unknown IDs previously had Heavy anticipation but no strike pose, so the explicit mapping avoids that gap. Root owns runtime evidence and independent review precedes saving.


WO-3.7 client evidence update, 2026-09-24: root reports actual Studio capability policy **18 checks PASS** and actual widgets **3 controls x 2 scales PASS**. Combat and world independent source review passed the Main gate/cancellation placement. Physical input dispatch remains unverified. Root also reports the separately saved WO-3.6 enemy presentation fixture **32 poses PASS** (Heat checkpoint `5a97e94`). The earlier queued wording is retained as history; these results supersede that queue state without claiming boon server enforcement before its separate integration tests.
