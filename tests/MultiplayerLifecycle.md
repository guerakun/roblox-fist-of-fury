# Multiplayer lifecycle regression harness

Run a Studio local server with two clients using stable test UserIds A and B. These are manual/multi-client integration checks; no production remote or debug endpoint is added. Both clients must receive their characters before assertions. Keep B connected so the campaign is not intentionally retired when A leaves.

## 1. Damage retention across same-campaign reconnect

1. Ready both clients and begin the first encounter.
2. Let A take damage, then record `Combat.GetSnapshot(A).percent`, `stocks`, and `hero` in the Studio server. Percent is floored in the snapshot; compare the displayed value consistently.
3. Disconnect A while B remains alive in the same encounter. Reconnect A with the same UserId.
4. Assert A returns at the current checkpoint with the recorded percent/stocks/hero. The two-second spawn protection is allowed; damage and stocks must not refresh. Existing special/dash cooldown deadlines must also survive if they have not elapsed.

## 2. A downed teammate cannot buy stocks by reconnecting

1. Keep B alive. Exhaust all three of A's stocks by actual enemy hits or a server-only test call to Combat.ApplyHit with a real registered enemy as attacker. Allow the 1.15-second respawn and two-second protection between each KO.
2. Assert A's snapshot has stocks=0 and downed=true.
3. Disconnect/reconnect A while B continues fighting.
4. Assert stocks remains0, downed=true, the new root remains anchored at its bounded downed position and cannot attack; the original twelve-second channel deadline is preserved, never renewed. A real first-time late joiner C must still receive three stocks.

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

1. Complete a district: each player receives minus15 percent (clamped at0) and plus1 stock (maximum3), exactly once. An eliminated teammate returns with1 stock. Rally at the exit; the next district preserves these values. Replaying the clear callback grants no extra healing/stock. One Life later clamps this benefit to1.
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

At zero stocks, verify a12-second downed window at reachable ground height. Hold V/L3/contextual touch within8 studs for2.5 seconds; restore1 stock/60 percent without spending a donor stock. Movement beyond1.5 studs, distance beyond8, accepted damage, release/focus/menu cancellation, departure or life replacement interrupts. Two rescuers cannot restore twice. At expiry, channel attempts fail; an available instant stock share remains separate. Preserve the original deadline across reconnect. One Life later disables instant share while retaining this channel. Source fixtures and physical-device evidence must be recorded separately.
