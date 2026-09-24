# Curtain Break launch report and owner checklist

Prepared 2026-09-24 during the launch program. **This is not a release approval or a claim that the program is complete.** The current work-order ledger and exact resume point are at the top of [PROGRESS.md](PROGRESS.md). This report separates local engineering evidence from the actions that require owner decisions, real devices or a published test universe.

No experience was published, no Creator Dashboard or live place setting was changed, no live player DataStore was exercised, and sales remain off during the authorized overnight work. Future owner actions below are a checklist, not completed actions or permission to perform them tonight.

## Evidence already available

| Area | Recorded evidence | Limit |
|---|---|---|
| Baseline | Five fresh solo HumanBot sessions: 5/5 clears, mean 278.27 s, 0.80 stocks lost, 543 floored damage | Pre-rework gameplay. Five samples are coarse; not a human difficulty result. [Baseline policy and raw reports](launch/HUMANBOT_BASELINE.md) |
| AI extraction | Twenty-five differential traces, cap/clock tests and one comparison campaign recorded by root | Proves the tested extraction paths; it does not close the later AI or challenge milestones. See the work-order ledger. |
| Original hero structure | Gale 35, Piston 44, Tide 39 parts; each seven queryable parts, six motors, no external character meshes | Structural Studio checks and source review. Gameplay captures did not render usable 3D art; visible likeness and owner approval remain open. |
| Original specials | Client tests cover six direction/footprint cases, three pose tables, cosmetic safety, eight-effect cap and cleanup | Replicated-origin and receipt-timed visual estimates; not proof of exact network impact timing or approved animation quality. |
| Multiplayer baseline | Fixed two-, three- and four-client campaign runs; additional late-membership, stock conservation and 150/250 ms cases recorded | Baseline-era tests; incomplete lifecycle coverage and same-identity reconnect limitations are explicit in [the multiplayer record](launch/MULTIPLAYER_EVIDENCE.md). Re-run after changed survival/AI rules. |
| Matchmaking core | Fake-adapter party, lease, timeout, membership, forgery and injected-failure cases | No live MemoryStore, cross-server routing or teleport round-trip certification. |
| Builds and scans | Source build and original-IP text checks are tracked per milestone in PROGRESS | A build is not runtime acceptance. Text scanning does not examine image likeness, published metadata or binary-place contents. |

Later results must be appended with the tested commit and actual numbers; do not silently relabel these baseline observations as launch-candidate results.

## Owner decisions and art acceptance

- [ ] Approve or rename the candidate display names: **Rook Calder (Gale)**, **Bo Marlowe (Piston)** and **Isla Veyra (Tide)**. Stable internal IDs should remain unchanged.
- [ ] Inspect each original hero in silent gameplay at the real campaign camera, then front/side/back under all three chapter lighting setups. Approve silhouettes, faces, outfits, weapons and the three special pose/effect languages.
- [ ] Capture three usable gameplay images, one per hero, without account identifiers or unrelated desktop content. A reviewer who did not author the art records one likeness-review line per hero. Blank captures and source descriptions do not substitute for this step.
- [ ] Review icon, thumbnails, experience title/description, search keywords and loading imagery for original identity. Re-run `python tools/check_ip.py` on the exact release source. Check rebuilt places for stale retired assets as well as source.
- [ ] Select the minimum supported phone and record its model, OS, resolution and target graphics setting before accepting performance results.

## Isolated published test universe — owner action required

- [ ] Create/configure an isolated test universe containing the reviewed hub and campaign builds. Confirm intended owner/group, start place, access audience, hub capacity target of 30 and campaign capacity of four. These are proposed settings; overnight source work did not change them.
- [ ] Enter the actual test Hub/Campaign place IDs in source and rebuild. Production IDs and live player storage must remain separate. Current zero IDs intentionally disable real deployment.
- [ ] Complete and verify the current Maturity & Compliance questionnaire against actual combat, fear imagery, audio and interaction features. Record the resulting audience/access status; do not infer it from the intended age group.
- [ ] With two real accounts, perform **five consecutive** party → quick match → reserved campaign → district-one clear → group return round trips. Record anonymous account labels, match IDs, server IDs, timestamps, arrival count and return count. Target zero orphaned players and median hub-to-fight time below 25 seconds.
- [ ] Exercise Solo, full party, incomplete queue timeout, cancellation, leader departure and member departure. Confirm parties are never split and difficulty/Heat selections are server-owned.
- [ ] Exercise teleport-init failure, retry/backoff and exhausted retries. A failed member receives an actionable message; no player remains silently locked in a matched state.
- [ ] Verify wrong match IDs, nonmember joins and wrong reserved-server destinations fail safely. TeleportData alone must never grant admission, difficulty, rewards or party membership.
- [ ] Verify return restores the party and allows a second deployment. Test an actual same-account reconnect during a wave, after a stock loss, while downed and across a district transition; Studio replacement identities did not establish these cases.

## Live persistence, assets and audio — test universe only

- [ ] Join, earn coins/XP/cosmetics, leave and rejoin on a different server. Record balances, claimed reward keys, owned/equipped cosmetics, difficulty unlocks and tutorial state before/after.
- [ ] Verify failed load and forced storage failure show a read-only/unavailable state and never write fresh defaults over an existing profile. Exercise delayed saves, contention, lease expiry/loss and a server shutdown with an outstanding save. Verify the latest accepted mutation persists after BindToClose.
- [ ] Repeat checkpoint retry, replay reward requests and reconnect requests; no reward key pays twice. Confirm client-supplied rank, score, amount, price or pass ownership is rejected.
- [ ] Under a non-owner account, verify every current Toolbox sound, particle texture, generated pump mesh/texture and station material loads in the published test universe. Reconcile actual IDs with [ASSET_REGISTER.md](ASSET_REGISTER.md).
- [ ] Listen to each stage's ambience, music, attacks, impacts, blocks and KO cues. Test mute sliders and reduced-effects settings; Edit-mode preload success is not an audible mix review or published permission proof.
- [ ] Create/assign the intended badge IDs only after source logic exists. Confirm each badge's real award path, replay deduplication and failure handling. Badge configuration is not an overnight completed action.
- [ ] Verify district score, full-run time and Heat leaderboards write/read correctly, including friends filtering and no client-forged submission. Fake records do not prove OrderedDataStore access.
- [ ] Verify analytics funnel and economy events against real test behavior: hub join, tutorial completion, district clears and victory. Confirm event amounts reflect server-awarded rewards and failed attempts do not double-count.

## Final gameplay, fairness and device acceptance

- [ ] Run the fixed-seed HumanBot suite on the final build and place the baseline and after numbers side by side: clear rate, time, stocks lost per district, damage, rank, idle/flank metrics and windup-cap breaches. Retain raw anonymous reports and the bot/source revisions.
- [ ] Record actual human sessions on **Normal, Hard and Nightmare** after tuning. The owner must personally complete or assess a full co-op Normal session and a full co-op Hard session before overall program closure. Record wins/wipes, time, stocks, unclear instructions and enjoyment separately from bot output.
- [ ] Check the target difficulty curve: Normal 60–80% bot clears with at least two stocks lost on average, Hard 30–50%, Nightmare below 20%, and S rank in fewer than 25% of bot district clears. Five-run resolution is coarse; human feedback can override tuning with a written reason.
- [ ] Verify at least 0.30 s of visible warning on every enemy attack and zero hits from enemies outside the victim's camera view. Exercise stage edges, foreground lanes, portrait/unsupported layouts, party spread, camera lag and overlapping specials. Server proximity estimates alone are not measured camera-frustum evidence.
- [ ] Verify AI token caps, non-idle waiting behavior, surround frequency and each archetype's action diversity against the launch targets. Capture the actual 12-enemy/four-player MicroProfiler sample; average AI heartbeat work must meet the 1.5 ms target.
- [ ] Repeat multiplayer campaign/lifecycle harnesses on the final rules: ready/cancel, late join, downed/revive, stock-share conservation, wipe/retry, progression after departures, empty-server reset and fresh run after victory. Include 150/250 ms replication-lag passes and restore the setting afterward.
- [ ] On the selected minimum phone, run four-player peak effects and measure at least 30 fps, frame-time distribution, memory, thermal/session duration and cleanup after repeated runs. Record an agreed hub-memory budget and measured result; no budget has been approved merely by listing this check.
- [ ] On real touch hardware and a physical controller, reach every action and menu, including contextual grab/throw, weapon use/drop, desperation input, guard release, revival, ready/cancel, deployment and return. Check safe areas, focus navigation, hold/release behavior and orientation changes.
- [ ] Verify the onboarding dojo is skippable, completes with normal inputs, persists completion and teaches the shipped actions. Scenery labels or a scripted completion flag do not certify the lesson.
- [ ] Review every new remote for rate limits, finite/type validation, server membership/range/cooldown checks and safe failure. Money must never purchase power, damage buffs, revives, hero access or difficulty advantage.

## Monetization and release sequence

- [ ] Keep sales disabled for soft launch. Coins are earned only; candidate paid offers are cosmetic and must not alter combat stats or rewards through purchased power.
- [ ] After owner-approved release gates pass, perform the proposed three-day friends-only soft launch before deciding on public access. Watch retention, tutorial completion, first-district clear rate and session length; do not promise outcomes from local tests.
- [ ] Consider cosmetic Chapter Pass/private-server activation only after two weeks of clean persistence and delivery evidence. The proposed pass price is a decision to review, not an enabled product or purchase promise. Verify actual IDs, current price, entitlement refresh, cancellation and previously earned cosmetic claims before enabling anything.

## Morning handoff fields

| Field | Required record |
|---|---|
| Final tested source and place builds | Root to record commit, milestone build, Rojo version and artifact hashes |
| Closed versus implemented-only work | Use the current PROGRESS work-order table; do not infer completion from this checklist |
| Exact next work order | Root's Morning summary at the top of PROGRESS |
| Owner decisions | Candidate hero names/art, minimum device and later test-universe setup |
| Blocked external evidence | Usable art captures, human/device sessions, live permissions/persistence, published round trips and Dashboard setup |
| Publication and paid sales | Not performed overnight; remain disabled/unapproved until the corresponding gates are completed |
