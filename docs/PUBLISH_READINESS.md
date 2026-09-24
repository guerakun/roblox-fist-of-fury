# Publish readiness — Curtain Break

Drafted 2026-09-23 from the current source and recorded Studio evidence. **This is a development build with specific shipping checks still open.** A successful local preview, source build or mocked persistence test does not certify public-server behavior or parity with Jujutsu Shenanigans. The integration owner should append the final revision and runtime evidence below before marking release gates complete.

## Current build facts

- The source campaign has exactly **three stages and twelve encounters**: a skirmish, miniboss, escalation and boss in each stage. City streets contains Crosswalk Executioner and Siren Marshal; the abandoned station contains Platform Widow and The Last Conductor; the abandoned factory contains Furnace Hound and Kiln Sovereign. Kiln Sovereign is the finale.
- WorldBuilder preserves the continuous floor, controlled lane and three encounter gates. It creates 34 whole destructible prop assemblies. The destruction service caps active fragments at 30 and restores props after 20 seconds. The expanded world also includes reviewed/generated scenic mesh and material references.
- Naruto, Luffy and Tanjiro are playable fan-theme R6 kits, with authored face/clothing details and reviewed static hair/hat mesh references in `src/shared/CharacterArt.lua`. This is an unofficial anime fan project. Do not present its characters, city fiction or store artwork as an official franchise release.
- Actual Toolbox-derived movement/combat keyframes, hitbox adaptation, particles and audio are documented in the asset register. The final asset inventory must also include the newer character art and generated foundry-pump/material assets.
- All current heroes/stages are free to play. Coins and chapter XP are earned from server-authorized encounter rewards. The twelve-tier chapter track has no expiry. Combat boons are earned through XP and one is equipped at a time; the proposed paid pass contains cosmetic trails/titles only.
- Current shipping controls are **SalesEnabled=false**, **ChapterPassId=0**, **StudioPersistence=false** in `src/shared/ProgressionConfig.lua`. Keep these values until the corresponding checks are complete. Studio practice progression intentionally resets.
- `default.project.json` maps server/client/shared source and the station MaterialVariant. Rojo is the reproducible build path; the editable Studio place and repository source must be synchronized for the final deliverable.

## What the existing evidence establishes

| Evidence | Established scope | Does not establish |
| --- | --- | --- |
| `docs/VALIDATION.md`, initial smoke runs | Earlier build's basic hit validation, cooldown/rate handling, stocks, restart and forced gate transitions | Final twelve-encounter campaign balance or updated character/world performance |
| `docs/media/coop-studio.jpg` and two-client notes | Two actual local clients joined the earlier slice and observed replicated fighters/damage | Four-player latency, complete co-op campaign, reconnect coverage or the final expansion |
| Earlier 21-prop destruction stress | Whole-assembly hiding, 30-fragment cap and restoration in the then-current server build | New 34-prop two-client/latency behavior |
| `tests/ProfileStore.spec.lua` and integration-owner PASS report | Injected-adapter checks for lock contention, reconnect sessions, expiry, lost lock, failed loads, schema guard, sanitation and warning recovery | Roblox production DataStore permissions, real throttling, reconnect across live servers or durable live saves |
| `tests/ProfileConcurrency.spec.lua` | Regression test exists for a final release queued behind a slow autosave | A live DataStore shutdown test unless its execution is separately recorded |
| Station/factory screenshots and later art revisions | Distinct chapter composition has been previewed and refined | Final source-matched visual approval, minimum-device frame time or controller ergonomics |

Older counts and timings remain historical evidence. They must not be silently relabeled as results for the expanded release candidate. `tests/Autoplay.client.lua` is a test harness; completing with it is not a human playtest.

## Journal behavior implemented in source — runtime acceptance pending

The journal is a separate DisplayOrder 30 modal over the lobby/HUD. Opening and remaining open now require the server's `canEquipBoon` safe-state flag, including loading snapshots. The initial unsynchronized client state denies opening until eligibility arrives. Intermission and traversal allow the journal; a combat snapshot closes it and restores gameplay input. Settings and journal remain mutually exclusive through their menu attributes.

`ProgressionUI` now rebuilds stacked/wide rows when the width breakpoint changes, retaining scroll position and the selected controller button by stable key. Short panels use smaller header/tab chrome and reserve at least 102 px for scrolling content at the minimum 230 px panel height. Permanent cosmetic purchase information remains in the scrollable chapter rows when the repeated bottom slogan is hidden. This is source-level behavior, not a claim that 320×568 or 568×320 has already passed visual inspection.

The server and client both restrict a real pass purchase to `purchaseAllowed` in Waiting, Defeat or Victory. Intermission/traversal still permit earned progression management, while the pass button directs players to lobby/results. `salesEnabled` remains a separate requirement and is currently false. This prevents starting a Roblox purchase modal just before an encounter countdown ends; cancellation and ownership refresh still require the live tests in Gate 4.

## Gate 1 — Freeze and reproduce the release candidate

- [ ] Record Git revision, build time, Rojo version, place filename and final universe/place IDs in the release record.
- [ ] Build the latest `default.project.json`, open the resulting source-built place, and confirm all modules initialize without client/server errors.
- [ ] Rebuild the editable city, install intended edit-time materials, save the final place, and confirm it matches the source revision. A beautiful edit-time preview is not enough if the source build omits it.
- [ ] Remove runtime-only validation/autoplay scripts, temporary preview rigs, raw Toolbox quarantine models and test clients before saving the playable artifact.
- [ ] Update README, asset register, controls and validation notes to the actual three-stage/twelve-encounter/factory-finale/34-prop build. Preserve older evidence under explicit historical headings.
- [ ] Keep a known-good rollback place and source revision before publishing the candidate.

## Gate 2 — Final-owner asset access and presentation

- [ ] Reconcile every external mesh, texture, audio and material ID from CharacterArt, AssetInstaller, ArtAssetsInstaller and Main.client with the asset register, including source, creator/owner and actual use.
- [ ] Confirm intended final-owner use of the fan-character assets and public-facing anime names/art. Record the decision for each asset or substitute original assets before public release. Toolbox insertion alone is not an ownership record.
- [ ] Launch the **published test universe** under its intended owner/group and verify all hair/hat meshes, foundry-pump textures, station material maps, particles and sounds load without permission or moderation errors.
- [ ] Listen to the actual audio mix and inspect all three characters from front/side/back in every chapter under final lighting. Verify weapons/hair do not enlarge queryable hit targets.
- [ ] Retain the sampled keyframe route if it is the shipping implementation. If converting to uploaded Animator assets, publish them to the final experience owner and test permissions before removing the working fallback.

Roblox checks access for restricted assets at load time; audio has its own sharing workflow. See [asset permissions and Creator Store behavior](https://create.roblox.com/docs/production/creator-store) and [audio assets](https://create.roblox.com/docs/audio/assets).

## Gate 3 — Real persistence in an isolated test universe

- [ ] Use a separate published test universe/DataStore namespace with test accounts. Keep Studio API access off for production data; Roblox recommends a separate test version when enabling Studio access.
- [ ] Confirm live load, autosave, leave/rejoin and fresh-server join preserve coins, XP, owned cosmetics, equipped items, claimed tiers and boon selection.
- [ ] Exercise overlapping leave/rejoin, delayed saves, lease expiry, lost lock, throttling and server shutdown. Verify failed loads never write defaults and the latest revision is saved before releasing the session lock.
- [ ] Verify repeat requests, checkpoint retries and reconnects do not duplicate encounter/tier rewards or charge coins twice.
- [ ] Confirm failure/recovery messages accurately reflect state: practice, loading, saved, retrying and unavailable. A failed load should not trap players behind an unclosable journal.
- [ ] Record actual DataStore test results separately from injected-adapter PASS results, then decide whether the candidate is ready to persist player progress.

Reference: [Roblox Data stores — Studio access and testing](https://create.roblox.com/docs/cloud-services/data-stores).

## Gate 4 — Voluntary cosmetic sales, only if enabled

- [ ] Keep sales disabled for any release that has not passed live persistence and asset checks. The game can ship a free test without paid products.
- [ ] If enabling the pass, configure the correct owner-controlled game-pass ID, current price and sale availability; verify price lookup retry and server ownership checks in the test universe.
- [ ] Test cancel, already owned, successful purchase, delayed ownership refresh and relaunch. Earlier earned premium tiers must remain claimable after obtaining the pass.
- [ ] Ensure the Roblox purchase prompt cannot persist into active combat from the end of a short intermission; use a safe non-expiring lobby/result window or an explicitly protected flow.
- [ ] Confirm no combat power, hero, stage, revive or random roll became purchasable as a side effect of product setup. Public shop descriptions must match the six cosmetic rewards actually delivered.

## Gate 5 — Campaign and device acceptance

- [ ] Complete all twelve encounters with normal player inputs, solo and with two cooperating players; then run four players through the campaign. Record completion time, deaths, retries and where instructions were unclear.
- [ ] Verify each of the six elites has visible warnings, correct hit-area/impact timing, fair jump/dodge responses and a clear defeat payoff. Test overlapping warnings under four simultaneous specials.
- [ ] Verify ready lobby, intermission, traversal, checkpoint retry, full-party wipe, late join, disconnect and final victory. Slow teammates must not be stranded by a gate or incorrectly knocked out by stage bounds.
- [ ] Test 34-prop destruction and restoration from two clients, including simultaneous breaks and a world rebuild. Check the 30-fragment cap and intact floor/gates.
- [ ] Run real mobile touch and hardware-controller tests, including journal/settings/ready screens, gamepad focus, hold-guard release and orientation changes. Studio emulation at **320×568** and **568×320** is a layout check, not a real-device performance pass.
- [ ] Verify the journal closes when combat begins even if profile loading is still pending. Opening the journal must not accidentally ready the lobby or overlap the settings modal.
- [ ] Run a representative public-server latency test and record both one-way input feedback and authoritative hit results. A localhost two-client session is not latency evidence.
- [ ] Profile final four-player peak effects on the chosen minimum device. Record device, graphics quality, resolution, frame-time distribution, memory and session duration. Test reduced shake/effect settings and high-contrast warnings.

## Gate 6 — Creator Dashboard publication setup

- [ ] Select the intended experience owner/group, final name/description/icon/thumbnails, supported devices, access audience and maximum party size. Verify the public page describes the actual co-op game and unofficial fan theme.
- [ ] Complete the current **content maturity & compliance questionnaire** using the build's actual combat, fear imagery, audiovisual content and interaction features. Confirm the resulting audience/access configuration in Creator Dashboard; do not infer it from the intended audience alone.
- [ ] Verify account/experience publishing eligibility and any current Dashboard requirements. Keep test access restricted until the relevant gates above pass; change audience/access deliberately as part of release.
- [ ] Perform a final published-client smoke test from a non-owner test account and verify joins, assets, save/rejoin and the first boss encounter.

Reference: [Roblox create and publish games and places](https://create.roblox.com/docs/production/publishing/publish-games-and-places).

## Final integration evidence — owner to complete

| Field | Value |
| --- | --- |
| Release candidate revision | Pending |
| Build / editable-place artifact | Pending final source synchronization |
| Test universe / final universe | Pending |
| Updated module and gameplay test log | Pending; append to VALIDATION.md |
| Final 320×568 / 568×320 captures | Pending |
| Final two-/four-player campaign run | Pending |
| Live DataStore and published-asset verification | Pending |
| Sales enabled? | No — current source false / pass ID 0 |
| Approved access audience and maturity result | Pending Creator Dashboard setup |
## Handoff status
Account usage limits interrupted work around 03:31 EDT. See PROGRESS.md and the final VALIDATION.md section for the latest actual evidence. The public repository is a development handoff, not a public Roblox launch. The main place is a clean Rojo source build whose world is generated on Play. Latest stock-sharing and expanded multiplayer regressions remain open; paid sales are disabled.
