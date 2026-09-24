# Multiplayer lifecycle regression harness

Unless a case explicitly selects Heat, run Normal with no Heat in a fresh unmanaged Studio campaign. Run a Studio local server with two clients using stable test UserIds A and B. These are manual/multi-client integration checks; no production remote or debug endpoint is added. Both clients must receive their characters before assertions. Keep B connected so the campaign is not intentionally retired when A leaves.

## 1. Damage retention across same-campaign reconnect

1. Ready both clients and begin the first encounter.
2. Let A take damage, then record `Combat.GetSnapshot(A).percent`, `stocks`, and `hero` in the Studio server. Percent is floored in the snapshot; compare the displayed value consistently.
3. Disconnect A while B remains alive in the same encounter. Reconnect A with the same UserId.
4. Assert A returns at the current checkpoint with the recorded percent/stocks/hero. The two-second spawn protection is allowed; damage and stocks must not refresh. Existing special/dash cooldown deadlines must also survive if they have not elapsed.

## 2. A downed teammate cannot buy stocks by reconnecting

1. Keep B alive. Exhaust all three of A's stocks by actual enemy hits or a server-only test call to Combat.ApplyHit with a real registered enemy as attacker. Allow the 1.15-second respawn and two-second protection between each KO.
2. Assert A's snapshot has stocks=0 and downed=true.
3. Disconnect/reconnect A while B continues fighting.
4. Assert stocks remains0, downed=true, the new root remains anchored at its bounded downed position and cannot attack; the original twelve-second channel deadline is preserved, never renewed. A real first-time late joiner C receives the selected run stock cap: three by default, one with One Life.

## 3. Disconnect during an already-paid stock respawn

1. With A at three stocks, trigger one KO and disconnect A during the 1.15-second respawn delay.
2. Rejoin while B keeps the campaign alive.
3. Assert A has two stocks and zero percent: the stock cost already paid must remain, and the pending respawn's normal healing must complete. A must not get another KO from stale 200-percent damage or be charged twice.

## 4. A legitimate checkpoint retry restores disconnected players too

1. Defeat the miniboss so the checkpoint is stageMin+92 and the retry wave is3.
2. Down A, then disconnect A while B remains. Wipe B and press Retry on B.
3. Wait for the stage restart and reconnect A.
4. Assert A gets two stocks and zero percent at the mid-district checkpoint, and the encounter resumes wave3 rather than repeating the miniboss. This differs intentionally from case2 because a real checkpoint reset occurred.
5. Complete an already-rewarded encounter on a retry. Verify the same campaign:stage:wave key grants no additional coins/XP, including if A disconnected and rejoined.

## 5. New district and new campaign boundaries

1. Complete a district: each player receives minus15 percent (clamped at0) and plus1 stock (maximum3), exactly once. An eliminated or already-respawning teammate gets a fresh life at0 percent when the earned stock restores them; living teammates keep their remaining percent minus15. Rally at the exit; the next district preserves these values. Replaying the clear callback grants no extra healing/stock. One Life clamps this benefit to1 and also caps campaign start/retry at1; the default Normal/no-Heat cases below use3 start/2 retry.
2. Complete the full campaign and select a fresh run. Assert damage, stocks and run statistics reset, and the new campaign may legitimately award the same stage/wave content again under new reward keys.
3. In a reusable Studio server, disconnect every client while in district2 or3, then connect a new client before closing the server. Assert Waiting starts in district1 at its entrance, all curtains are closed, readyCount=0, and no prior campaign survival state is applied. A normal live server may shut down when empty; that is also valid.

## 6. Ready membership and late joining

1. In a fresh lobby, ready A but leave B unready: the encounter must not start.
2. Cancel A's readiness, ready B, and verify the lobby remains Waiting.
3. Ready A: one campaign starts, with one set of enemies.
4. Alternatively, with only A ready, disconnect unready B: the remaining ready party may begin.
5. Join C during a boss. The boss's current PercentLimit must remain unchanged. C gets the current checkpoint; the next wave uses the new party size.

## Expected retention bounds

Disconnected survival state is kept only within the current server campaign, capped at256 inactive UserIds with oldest-inactive eviction. Active players stay in the ordinary combat records and are never evicted. BeginRun clears the previous campaign's survival cache. RetryCheckpoint restores both connected and cached survival to2 stocks/0 percent; EnterDistrict preserves survival; a new campaign ResetPlayers starts3/0. Reward histories are independent, keyed by stable campaign:stage:wave strings, and must not be reset on ordinary disconnect or checkpoint retry.


## 7. Timed channel revive (WO-3.2)

At zero stocks, verify a12-second downed window at reachable ground height. Hold V/L3/contextual touch within8 studs for2.5 seconds; restore1 stock/60 percent without spending a donor stock. Movement beyond1.5 studs, distance beyond8, accepted damage, release/focus/menu cancellation, departure or life replacement interrupts. Two rescuers cannot restore twice. At expiry, channel attempts fail; an available instant stock share remains separate. Preserve the original deadline across reconnect. One Life disables instant share while retaining this channel. Source fixtures and physical-device evidence must be recorded separately.


## Final-M3 fixture audit and rerun queue (2026-09-24)

**Prepared, not rerun evidence.** Prior WO-5.5 results remain historical results for their saved source. These corrections do not retroactively validate final M3. Root is the only Studio operator. Production and HumanBot are frozen during the15-trial tier series; these files are test-only and outside both production projects.

Install only the listed server script and companion in each fresh disposable session. Pass the actual frozen production `sourceCommit` string in every argument table. Test scripts call `EndTest` themselves, including deadlines; remove them before the next campaign or tier trial. No fixture here writes live persistence, bypasses published join validation or proves actual same-account reconnect. Use the existing unpublished Studio practice profile configuration.

| Run | Server / client | ExecuteMultiplayerTestAsync arguments after client count | Scope |
|---|---|---|---|
| Fixed2 clients | `MultiplayerCampaign.server.lua` / `MultiplayerDriver.client.lua` | `2, {test="NightfallMultiplayerCampaign", initialPlayers=2, latePlayers=0, timeout=600, sourceCommit="<frozen-source-commit>"}` |12 encounters, immutable ranks and separate receipts for each participant, actual coins+XP reconciliation |
| Fixed3 clients | Same | `3, {test="NightfallMultiplayerCampaign", initialPlayers=3, latePlayers=0, timeout=600, sourceCommit="<frozen-source-commit>"}` | Same, three connected clients |
| Fixed4 clients | Same | `4, {test="NightfallMultiplayerCampaign", initialPlayers=4, latePlayers=0, timeout=600, sourceCommit="<frozen-source-commit>"}` | Same, four connected clients |
| Late2→4 | Same | `2, {test="NightfallMultiplayerCampaign", initialPlayers=2, latePlayers=2, timeout=600, sourceCommit="<frozen-source-commit>"}` | Active miniboss threshold frozen; late participation starts in district1; both initial and late players must obtain all three district results |
| Connected stock/travel + real departure | `MultiplayerLifecycle.server.lua` / `MultiplayerDriver.client.lua` | `2, {test="CurtainBreakLifecycle", sourceCommit="<frozen-source-commit>"}` | Registered accepted hits, stock-share conservation, one-time clear reward, survival-preserving district travel, actual disconnect/replacement; same-ID branch only if Studio actually reuses the identity |
| Checkpoint/reward/new run | `CheckpointLifecycle.server.lua` / `LobbyLifecycle.client.lua` | `2, {test="CheckpointLifecycle", sourceCommit="<frozen-source-commit>"}` | Scripted full wipe, retry2/0 with meter reset and completed-wave best retention, no duplicate coins orXP on replay, all district receipts, fresh campaign resets style/results and pays new keys |
| Ready/empty server | `LobbyLifecycle.server.lua` / `LobbyLifecycle.client.lua` | `2, {test="LobbyLifecycle", sourceCommit="<frozen-source-commit>"}` | Real ready/cancel/leave, unmanaged empty lobby resets results/style/gates/options; explicitly not the published admitted-server sticky-lock path |

The campaign driver retains its prior movement and action policy. It is a strong deterministic integration driver, **not HumanBot and not challenge-curve evidence**. A defeat or deadline on the final source must be recorded; do not silently grant stocks, heal actors or weaken enemies to produce a green integration result. No client driver implements the newer channel revive here; dedicated SurvivalRuntimeAI evidence covers actual channel intents, while human co-op remains open.

M3-specific audit corrections:

- Retired assertion preserved: the old lifecycle script called `ResetPlayers` at a new district and expected3 stocks/0 percent. That was valid baseline behavior before WO-3.2. The revised fixture exercises `CompleteDistrict` once (+1 stock/-15 percent), rejects a duplicate, then calls `EnterDistrict` and requires the earned values to persist.
- Lifecycle fixtures settle initial character setup and keep registered test enemies within the party camera region. A rejected hit is awaited with a bounded deadline; the shared production visibility/invulnerability guards stay enabled.
- The checkpoint fixture fixes its tier/Heat before readiness; checks retry stock count from the current survival rules; verifies multiplier/progress reset and completed-wave score retention; checks coins **andXP** on duplicate encounter clears. It does not claim real reconnect or human difficulty.
- Full campaign assertions require three result/receipt pairs per player, immutable rank fields, nondecreasing receipt revisions, and actual paid base+rank+bounty totals matching balance deltas and the coin observer. Missing receipts can no longer count as a pass. This checks the normal no-spending fixture; it is not a live DataStore test.
- Older latency reports used a tell key without enemy identity and attempted cancellation cleanup with the wrong key type. Those numbers remain recorded with this limitation. The new `owner-footprint-v2` observer keys tells by actual owner plus move/footprint, removes the owner's tells on cancel/stagger, and reports its revision. The input decisions are unchanged. Receipt-time tell/impact deltas do not prove physical-device timing or cover projectile contact before the endpoint impact event.

Managed admission and Heat coverage remain separate: CombatAdmissionAI/CampaignAdmission verify arrival gates; HeatRuntimeAI verifies the sticky admission selection after ResetLobby, all six actual effects, and One Life revive/share rules. The unmanaged Ready tests must not be interpreted as permission for a published admitted client to bypass all-arrived/30s readiness.

Still missing from these automated fixtures: same UserId reconnect across real servers, client-loaded profile failure recovery in published servers, real human co-op on each tier, physical gamepad/touch inputs, and ordinary play under combined Heat. Existing dedicated scripted Heat/boon/survival evidence does not close those gates.
