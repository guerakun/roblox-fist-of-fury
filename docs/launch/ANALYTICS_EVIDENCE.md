# Analytics source and limits

2026-09-24, WO-6.2. Server observation uses Roblox's current [`LogFunnelStepEvent`, `LogCustomEvent` and `LogEconomyEvent` APIs](https://create.roblox.com/docs/reference/engine/classes/AnalyticsService). Economy observation occurs after accepted mutations, following the [event timing guidance](https://create.roblox.com/docs/production/analytics/event-types).

Implemented campaign funnel: deployment joined, district one, district two, district three, victory. Campaign IDs distinguish repeat runs, including late joiners. Refuge joins are a separate custom event. A DojoCompleted custom-event function is prepared for the tutorial work order; it is not called before a tutorial exists. These are **not one continuous cross-place onboarding funnel**. Skipped steps in Roblox's funnel charts can imply intermediate progression, so raw event interpretation must account for late joins.

Coin sources record the actual capped balance delta after a successful server reward or tier claim. Cosmetic sinks record the accepted price and ending balance. Zero deltas, nonfinite values and invalid keys are rejected. No purchased power or client-submitted amounts are introduced. Telemetry failure cannot alter rewards or throw from a sender into gameplay.

The observer suppresses duplicate attempts within each player's most recent 512 keys; it is deliberately a bounded in-memory history, **not durable exactly-once analytics**. An evicted key may be observed again. Reward idempotency remains the responsibility of progression, independently of analytics. Failed analytics attempts are not retried because delivery may be uncertain.

Actual Studio `AnalyticsJournal.spec.lua` passed 16 policy cases: distinct players/runs, duplicate source/sink handling, actual amount/balance, invalid values/keys, sender failure containment, player cleanup and the explicit eviction boundary. Presentation independently reviewed the implementation. Studio exits before any AnalyticsService submission; **published delivery and Dashboard visibility are unverified**. Those checks remain in LAUNCH_REPORT.md. No Dashboard or live analytics operation was performed.
