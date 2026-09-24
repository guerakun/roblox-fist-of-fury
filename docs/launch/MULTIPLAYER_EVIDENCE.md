# Multiplayer execution evidence — WO-5.5

Actual StudioTestService server/client processes, 2026-09-24. Core gameplay is WO-2.1 extraction + WO-1.1 IDs; later 3/4 and lag sessions include native original art. No M2 AI behavior tuning is included. Drivers use normal movement and action remotes; lifecycle fixtures explicitly use server test hits. Nothing is installed into production projects.

| Session | Result | Elapsed | Evidence |
|---|---|---:|---|
| Initial2 + late2 | PASS,15assertions,12encounters |152.07s|evidence/multiplayer-baseline-2to4.json|
| Fixed2 | PASS,12encounters,allclientsVictory |147.44s|evidence/multiplayer-fixed2.json|
| Fixed3 | PASS,12encounters,allclientsVictory |140.46s|evidence/multiplayer-fixed3.json|
| Fixed4 | PASS,12encounters,allclientsVictory |144.94s|evidence/multiplayer-fixed4.json|
| Fixed2,150ms incoming lag | PASS,allclientsVictory |158.80s|evidence/multiplayer-lag150.json|
| Fixed2,250ms incoming lag | PASS,allclientsVictory |167.15s|evidence/multiplayer-lag250.json|
| Lifecycle/stock-share | PASS14assertions;partialcoverage | — |evidence/multiplayer-lifecycle.json|

Lag setting was read as0 before testing, set to0.15/0.25seconds and restored to0 afterward. At250ms, each client paired11 Telegraph/EnemyImpact geometry events. Receipt interval minus advertised duration ranged -2.16ms to+34.81ms across22pairs; zero impacts arrived more than50ms early. This measures event arrival spacing, **not actual hit-frame alignment or visible camera-frustum fairness**. The150ms first timing probe saw zero pairs because the baseline impact packet lacks an actor reference; campaign convergence passed but desync is unmeasured there. Background Studio clients often run around15fps; these are not mobile/performance certifications.

## Lifecycle case coverage

| Existing case | Actual coverage / remaining work |
|---|---|
|1 Damage reconnect|Real client left and replacement joined. Studio AddPlayers assigned a different UserId; same-identity retention cannot be asserted. Requires test-account reconnection or supported identity reuse.|
|2 Downed reconnect|Actual server hits consumed3stocks; zero-stockdowned/anchored state verified. Same-identity reconnect remains blocked as above.|
|3 Paid respawn reconnect|EachKO chargedexactlyone stock; disconnect during paidrespawn and same-identity restoration unverified.|
|4 Checkpointretry/rewards|Not run as a complete multiplayer scenario. Existing profile/reward source protections are not substituted for this evidence. Retained as next lifecycle test after rules change inM3.|
|5 Boundaries|Baseline districtResetPlayers restores3stocks/0percent verified. Freshcampaign stats and empty-server district2/3 retirement/rejoin still unverified.|
|6 Ready/late membership|One-readywait, exactlyoneinitialwave, real2→4 latejoin and unchangedactivebosshealth verified. Explicit readycancel/unreadymemberdeparture scenarios still unverified.|

Stock share: valid rescue accepted, donor+recipient total conserved3→3, recipient1stock/0percent/unanchored, duplicate/NaN/unknown recipient rejected. This is automated baseline behavior; M3's new revive/persistent-stakes rules require another pass.

All reports use synthetic Studio names or anonymous Player keys. Root alone started/stopped sessions. Combat independently reviewed generalized client-count/convergence logic; world reviewed lifecycle fixtures. The work order is **partially verified**, not closed: the remaining lifecycle scenarios, visual desync inspection and actual account reconnects are recorded rather than implied passed.


## Additional lobby lifecycle pass, 2026-09-24

`LobbyLifecycle.server.lua` and its normal-input companion passed ten assertions on travel-integrated campaign behavior (66f5e10): ready/cancel ordering, an unready member leaving starts the remaining ready party, actual encounter progression to district two, every player leaving resets Waiting, and a verified new identity joins district one with fresh stocks/percent/statistics. Combat clearing and traversal were scripted; this is lifecycle evidence only. The first fixture raced cross-client readiness messages and legitimately started the campaign; waiting for cancellation acknowledgments fixed the fixture. See [anonymous report](evidence/lobby-lifecycle.json). Cases 1�4 requiring the same identity, complete checkpoint reward retry, and a fresh run after victory are still not certified.
