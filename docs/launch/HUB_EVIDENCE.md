# Hub deployment evidence

2026-09-24, WO-5.3. Two actual Studio clients exercised the ordinary HubRemotes request path. All eight assertions passed in 8.152 seconds: initialization, invitation receipt, shared two-person membership, rejection of nonleader deployment, queued state, leader cancellation, hero selection, and private-party simulated travel. See [report](evidence/hub-party.json), `tests/HubParty.server.lua` and `tests/HubPartyDriver.client.lua`.

The client layout fixture passed with 19 buttons, a minimum 44-pixel button height, scrolling, and a 780 by 690 panel inside the observed safe viewport. A server-held deployment warning remained visible in matched state. [Actual Studio capture](../media/hub-deploy.jpg) records the interface; this capture pipeline renders the interface but its 3D view is blank. It does not establish environment/art quality or physical touch/gamepad usability.

`TeleportCoordinator.spec.lua` passed group dispatch, duplicate suppression, three-attempt limit, 1/2-second backoff, and departed-player cleanup. `DeparturePreparation.spec.lua` passed whole-party preflight, partial release failure/resumption, no duplicate release of successful members, and conflicting ownership rejection. Matchmaking's 37 fake-adapter assertions were separately recorded in MATCHMAKING_DESIGN.md.

Hub saves are ephemeral in Studio. Production travel releases profiles before teleporting, holds input while saving, and retries failed travel before restoring a usable party/profile. Configured destination IDs remain zero. Live persistence, engine teleport failures, real cross-server queueing, and published round trips are **not verified** and must be completed in the owner test universe. No publication, sales, or live data changes were made.
