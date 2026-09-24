# Campaign admission and return evidence

2026-09-24, WO-5.4. Source reviewed independently by world; combat supplied and reviewed the admission hooks, presentation supplied the travel interface. Destination IDs remain zero. No place was published and no live service was exercised.

Actual Studio results:

- `CampaignAdmission.spec.lua`: 12 assertions, server record authority, forged/direct entry rejection, reserved-server binding, failed members, 30-second arrival timeout, and a fresh window after the server becomes empty.
- `ReturnParty.spec.lua`: 16 assertions, original-party restoration, separate quick-match parties, forged/expired authorization rejection, no overwrite of newer membership, late arrival cannot alter a queued roster, partial-write compensation/retry, and readback after an ambiguous committed write.
- `Matchmaking.spec.lua`: 39 assertions, including recovery of a matched party whose match expired after its queue ticket was removed.
- `CombatAdmissionAI.server.lua` with its ordinary-remote client companion: actual Studio multiplayer session passed managed-client Ready rejection, false/throwing admission denial before combat record creation, travel-lock Ready rejection, and trusted server readiness. Two disposable synthetic clients were denied; no owner account was kicked.
- `CampaignTravelUI.spec.lua`: ready and busy states passed with visible messages, safe-area containment, 44-pixel target, and no overlap with the visible campaign results. The first warning-only fixture raced the controller's periodic state broadcast and failed its message comparison. Repeated warning fixtures passed three times. This was a fixture scheduling collision; it is preserved here rather than reported as an uninterrupted test pass.
- Both source projects built with Rojo; IP scan passed 105 files.

The campaign consumes only a match lookup key from join data, then checks the server record and reserved server. Client Ready is disabled for managed deployments; the server waits for arrivals and initialized characters. Return travel is leader requested from terminal states, releases profiles before departure, retries three times, and restores failed travelers safely. Permanent unavailable profiles stay read-only with explicit rejoin guidance. Return records preserve original parties and never add a late arrival to a roster already deploying. A reserved refuge destination keeps group retries aimed at the same server.

Published engine teleports, cross-server MemoryStore behavior, five consecutive real-account round trips, median hub-to-fight timing, and physical touch/gamepad controls remain **implemented but unverified**. WO-5.6 requires the owner's test universe and permission to publish. It was not attempted because the overnight instructions prohibit publishing.
