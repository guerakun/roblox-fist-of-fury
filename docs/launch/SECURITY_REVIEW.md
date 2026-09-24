# Remote and authority review — 2026-09-24

Presentation independently inspected the working tree based on `7268dba56769b3c7b7afc84b5399856f4f7691c7` during the idle M6 lane. Line references describe the source at review time; concurrent M2 changes may move them. This is a bounded source audit, not a penetration test or security certification. No live requests, published services, account data, purchases, or source changes were made. Future M3/M4 actions require another review.

## Actionable findings

### SEC-01 — hub request fanout amplifies persistent-service reads (P2, source remediation reviewed; cache spec passed; hub regression pending)

`src/hub/server/HubService.lua:124` allows ten accepted requests per player per two-second window. `Refresh` returns from the protected callback at line 147, then falls through the all-player publish loop at line 151. Unknown actions also reach that loop after an error. Each `publish` invokes `snapshot`/`PartyFor` at lines 26-39. `src/server/MatchmakingService.lua:13` performs a member lookup and, for an existing party, a party lookup; `src/server/MatchmakingAdapter.lua:17` maps each to `GetAsync` outside Studio.

At a populated 30-player hub, one accepted refresh can therefore cause about 60 record reads. Ten such requests allow about 600 reads per two-second window from one caller, in addition to the ordinary polling loop (roughly 30 reads/second at 30 players before service latency). These are static upper-work estimates, not measured throughput; the per-player busy guard and yielded service calls may reduce throughput. Multiple callers and concurrent snapshots still share service budgets. Throttling can delay legitimate party/deployment operations.

Recommended: make Refresh publish only to its requester, reject unknown actions before persistent work, cache authoritative party snapshots briefly, and coalesce broadcasts after actual party changes. Add a fake-adapter operation-count test with 30 participants and repeated Refresh/invalid actions. Keep authorization checks server-side even when caching.

### SEC-02 — invitation display cache retains expired/disconnected entries (P2, source remediation reviewed; cache spec passed; hub regression pending)

`src/hub/server/HubService.lua:33` filters expired invitations from display without deleting them. Line 136 adds keys by party ID, while the `PlayerRemoving` cleanup at lines 191-195 does not clear `invitations[p.UserId]`. A player can repeatedly leave/recreate a solo party and invite the same target, creating new expired keys in a long-lived hub. MemoryStore records expire separately; that does not prune this Lua cache.

Recommended: delete expired entries during maintenance, remove disconnected-target caches, cap outstanding invitations per target, and add a fake-clock repeated-party/expiry cleanup test. This finding concerns bounded resources, not unauthorized party acceptance: the service independently validates invitations.

### SEC-03 — player movement is not validated as a hitbox origin (P2, source gap; exploit untested)

`src/server/CombatService.lua:448` constructs player hitboxes from the character's current root position. Character setup at line 789 establishes no server movement-history envelope. The Heartbeat at lines 900-913 clamps lane and encounter bounds and assigns humanoid speed; it does not validate displacement or sustained height within those bounds. Only enemy roots explicitly receive server network ownership (`:552`).

Consequently, authority over attack configuration does not establish authority over every possible replicated player position. If a client-controlled character replicates an implausible in-bounds displacement, source has no motion-history rejection before the attack query. Actual exploitability and replication behavior were not tested. A suitable follow-up is a server movement envelope that permits authored dash, launch, recovery, spawn and travel transitions, paired with adversarial Studio tests and high-latency regression. Do not introduce unconditional hard corrections that revive the camera jitter issue. This requires combat ownership and separate validation.

## Reviewed controls and limits

| Boundary | Source evidence | Source conclusion |
|---|---|---|
| Combat intent | `CombatService.lua:485-545` | Allowlisted action names and table payloads; 30 accepted actions per one-second fixed window per player; server cooldown, busy, stun, downed and encounter checks. Direction is reduced to ±1 by `CombatMath.lua:5`. Attack damage/range come from server Config, not client amounts or a target list. Fixed windows permit boundary bursts; not a global server budget. |
| Player hit resolution | `CombatService.lua:369-480` | Server query and same-team rejection; delayed attack checks battle epoch, life serial, character identity and stun. Enemy hits also check server camera eligibility. Movement-origin limitation remains SEC-03. |
| Stock transfer | `CombatService.lua:81-99,286-308` | Validates finite integral target ID, donor/recipient states, donor stock minimum, same-server record and ten-second cooldown. Both stock changes happen before spawn work. Client cannot nominate an amount. Current transfer deliberately has no proximity requirement; do not confuse it with planned channel revive. |
| Progression intent | `ProgressionService.lua:149-211` | Eight requests per one-second fixed window. ClaimTier checks integral bounded index, earned XP and claimed flags. Cosmetic price is server config; premium/track items cannot be bought with coins. Equip requires ownership; boon requires earned XP and safe state. No remote grants arbitrary coins, XP or rewards. |
| Reward grants | `ProgressionService.lua:112-141` | Server encounter participants/kind/key select fixed grants. Keys deduplicate in memory with a 128-key history; this is not unlimited or durable cross-server idempotency. No client reward-key submission path observed. Re-audit M3 retry/rank rewards before claiming farming resistance. |
| Save authority | `ProfileStore.lua:63-118`; `ProgressionService.lua:157` | Session token and lease guard mutations/saves; failed load stays unavailable. This is source evidence; published failure/rejoin/BindToClose behavior remains an owner gate. |
| Hub intent | `HubService.lua:124-151` | Ten requests/two seconds, per-player busy serialization, and travel/recovery lock. Queue requires authoritative leader, present roster, each member's unlock and writable profile. Heat IDs are known-config, unique and at most six array entries; unsupported nonempty Heat currently rejected. Unknown/dictionary extras do not become grants. Resource fanout remains SEC-01. |
| Party acceptance | `MatchmakingService.lua:35-64` | Invite server, TTL, Idle state, capacity and atomic member/party claims checked. Client party ID is a lookup key, not an accepted roster. |
| Match admission | `CampaignAdmission.lua:7-20`; `MatchmakingService.lua:211-218`; `CampaignSession.lua:64-76` | TeleportData carries match lookup only. Server record must be Ready, fresh, contain player and match actual private server ID; failed members rejected. Admission initialized before Combat in `Bootstrap.server.lua:15-17`. No access code is put in HubState. |
| Return travel | `CampaignSession.lua:78-82` | Only `Return` intent accepted; server terminal-state and leader check, then busy latch before asynchronous dispatch. No explicit time bucket, but valid requests become one pending operation and invalid requests perform no service lookup. Destination/options/roster are constructed server-side. |
| Return restoration | `ReturnPartyService.lua:24-68`; `HubService.lua:176` | Server source-place check plus fresh authoritative return membership; party bound to one hub, newer membership preserved. TeleportData alone does not authorize roster changes. Real cross-place behavior remains untested. |
| Messaging | `MatchmakingAdapter.lua:62-74`; `HubService.lua:51-57` | Notification contains a bounded lookup ID; recipient refetches Ready record rather than trusting message-supplied match content. |
| Client contracts | `Deploy.client.lua:87,138-140,255`; `CampaignTravel.client.lua:35`; `ProgressionUI.lua:72` | Clients send selections/intents. Travel sends no destination/roster. These client guards are convenience only; above server checks enforce authority. |

## Money never buys power

`src/shared/ProgressionConfig.lua:6-7` keeps sales disabled and pass ID zero. Config lines 11-15 define boons using earned XP; premium track entries only grant cosmetic identifiers. `ProgressionService.lua:178-180` adds an owned cosmetic for premium claims without coins, XP or a combat modifier. `:91-101` computes combat modifiers from the earned boon and XP only. Pass ownership is confirmed through the server MarketplaceService query (`:143-147`), not a client claim. There is no developer-product receipt/coin-sale path in the inspected source. This supports the current source contract; any future paid catalog needs its own review.

## Remaining evidence

- Root should record SEC-01/02 runtime regression results; presentation reviewed the source remediation and made no gameplay/service edits.
- Combat should triage SEC-03 with latency-aware motion tests; there is no reproduced movement exploit in this audit.
- All new M3/M4 remotes, revive cancellation, score/rank/retry grants, Heat arithmetic, badges and leaderboard writes still need review when implemented.
- Published teleport failures, MemoryStore budgets under load, asset script quarantine, account entitlement behavior and live persistence were not exercised here. Existing unit/runtime evidence must remain separately attributed.


## SEC-01/02 remediation review

Root added `src/hub/server/HubSnapshotCache.lua` and changed `HubService.lua` after the above findings. Presentation independently read the diff on 2026-09-24: source PASS. Refresh now publishes only to its requester; unknown selectors return before service work. Display snapshots use a five-second cache with one loader per user and a retry cooldown, including after failures. The retry deadline is measured after the loader completes, so a slow failed read cannot consume its own cooldown. Party mutations, queue eligibility, save validation and travel still use authoritative fresh reads; cached UI data never authorizes them.

Under healthy service responses, the cache introduces roughly five seconds of display staleness plus polling latency. During an outage, a previous successful display value can remain stale longer; this does not relax server validation. A concurrent cold read can temporarily display no party until a later snapshot. Root also prunes expired invites on reads and maintenance, caps each recipient at 32 cached invitations, and clears accepted/disconnected entries. Original findings above are retained as historical descriptions of the pre-fix source.

`tests/HubSnapshotCache.spec.lua` now covers repeated reads, expiration, failed-load cooldown, in-flight coalescing, removal and a loader that advances the clock eight seconds before failing. Presentation reviewed those assertions without running Studio. Root reported the actual isolated Studio cache spec PASS, including 100 repeated reads, 100 calls after slow failure, in-flight coalescing and cleanup; the latest slow-failure module passed in two fresh loads. The actual two-client hub regression remains pending. A 30-client remote-load test has not been performed; isolated cache coverage is not a substitute for it.


### Extracted invitation cache and expanded isolated tests

Root extracted ephemeral display invitations to `src/hub/server/InvitationCache.lua`; presentation independently reviewed the module, HubService integration and tests on 2026-09-24: source PASS. Acceptance still invokes fresh `MatchmakingService:Accept` before removing the display entry. Listing and maintenance prune expired keys; same-party replacement does not evict another entry; each recipient remains capped at 32. Player departure clears both invitation and display-party cache entries. This module does not authorize invitations or membership.

Root reported actual Studio `InvitationCache.spec.lua` PASS for 1,000 new-party additions, cap 32, same-key replacement, accepted-entry removal, expiry and disconnected-recipient cleanup. The expanded `HubSnapshotCache.spec.lua` also passed 30 simulated participants receiving 100 refresh rounds (3,000 cache requests) with 60 simulated underlying read operations, plus slow-failure retry cooldown. Those 60 operations are a test loader's two-per-party accounting, not observed cloud traffic. Actual remote integration and the two-client hub regression are still pending; no live load test was performed.
