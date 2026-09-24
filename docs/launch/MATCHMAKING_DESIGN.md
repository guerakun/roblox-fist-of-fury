# Matchmaking implementation and test boundaries

Parties and match records are authoritative server records, refreshed with a 600-second TTL. Invites expire in 60 seconds. Local party membership is limited to one hub server; Quick Match combines whole parties across hubs. Friends on other servers first join the same hub through Roblox's invite flow. No client supplies a roster or reserved access code.

The queue uses a **MemoryStore SortedMap** of durable party tickets ordered by queue time, under an atomic per-difficulty lease, rather than destructive Queue batch reads. This is an intentional implementation choice: after partial cloud failures, individual party tickets can be repaired or removed without dropping unmatched parties in a batch. The 20-second timeout, maximum four members, no party splitting, and shared cross-server matching behavior are preserved. Revision checks invalidate cancelled or changed rosters.

Match creation first writes a Building record, then claims every party. The Building-to-Ready atomic transition fences stale workers. Recovery aborts expired Building records; missing/aborted claims return to the queue. Ready records remain durable through dispatch/cleanup failures, and party refresh retries finalization. Matching never accepts TeleportData as authority. Join validation checks membership, record age/status and exact reserved-server identity.

MemoryStore, MessagingService and TeleportService adapters are inert local simulations in Studio. Published operation is implemented but **not verified**. Every cloud failure surfaces to the controller; retries back off and keep durable queue state. Hub teleport retry code must deduplicate local dispatches and handle TeleportInitFailed individually. No fake-adapter success is a real teleport claim.

Current executable spec covers whole-party packing, two matchmakers, timeout, leader/member departure, forged join membership/server, failed queue writes, failed reservation, post-Ready cleanup/dispatch failures, create/accept compensation and missing-match recovery. Additional failure injection and published round trips remain required before launch.

Official API references: [MemoryStore sorted maps](https://create.roblox.com/docs/cloud-services/memory-stores/sorted-maps), [reserved servers](https://create.roblox.com/docs/reference/engine/classes/TeleportService/ReserveServerAsync), and [teleport failures](https://create.roblox.com/docs/reference/engine/classes/TeleportService/TeleportInitFailed). The owner must configure a test universe before any real teleport test.
