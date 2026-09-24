# Movement-origin authority plan — proposed, not implemented

Prepared 2026-09-24 against the frozen M2 engineering checkpoint `9f29012`. This is the proposed remediation for SEC-03 in [SECURITY_REVIEW.md](SECURITY_REVIEW.md), within the launch security work. It changes no production code, ownership setting, place configuration or live service. There is no reproduced exploit or validated movement envelope yet. M2's five-run comparison must finish against its frozen source before implementation begins.

## Problem and intended result

Current player attacks use the character's replicated root as the hitbox origin. The server supplies attack parameters and checks cooldown, life, battle epoch and state; it also clamps stage/lane bounds and sets humanoid speed. Those checks do not establish that a position reached inside the bounds was plausible. Destruction queries also use the current root. SEC-03 therefore remains a source-level authority gap.

The proposed result is an accepted server movement history that gates gameplay effects. An implausible in-bounds teleport must not become a melee origin, break nearby props, collect a pickup, complete a revive or advance a rally. Ordinary client-predicted movement should remain responsive. An anomaly first suppresses the associated effect; it does not create a new per-frame root correction loop or automatically punish the account.

Roblox documents that client network ownership gives control over an assembly's physics, including position, and that movement validation must account for mechanics and latency. Its guidance discusses accumulated movement budgets rather than a universal speed check. This design applies those principles to this game's own authored movement. [Roblox movement security](https://create.roblox.com/docs/scripting/security/network-ownership)

## Source contracts that must survive

| Current path | Required treatment |
|---|---|
| `Main.client.lua` movement callback | Continue client-predicted humanoid movement. No camera or character CFrame writes added to this callback. |
| Grounded Jump in `Main.client.lua:send` | **Currently predicted locally without a Jump remote.** A server-intent-only exemption would reject legitimate jumps. See the vertical policy below. |
| Accepted Dash | Server writes X velocity 74 and a 0.18-second launched interval; the physics tail must be measured, not assumed to stop at 0.18 seconds. |
| Recovery | Server permits one air recovery, writes X velocity 26 and Y velocity 58, and resets eligibility after landing. |
| Accepted damage/launch | `CombatMath.Knockback` computes a server value, capped at 155 before later multipliers; the actual final impulse in `ApplyHit` is the grant source. Do not infer entitlement from the subsequently replicated velocity. |
| Spawn, retry, district transfer, stock sharing, reconnect, hero replacement | Rebase from the server's intended destination and life/character generation. A raw current root must not be laundered into a trusted destination through hero replacement or reconnect preservation. |
| Grab, downed, respawn, departure/travel lock | Distinct motion states. Cancel incompatible movement grants and action tickets. M3 revive and M4 throws must supply their own grants when implemented. |
| Existing bounds enforcement and camera | Keep behavior unchanged during the initial observer phase. Validate their ordering and later corrections explicitly; do not add a second competing bounds/camera controller. |

The listed values describe `9f29012`, not future permanent tuning. Read Config and actual accepted server actions at runtime; M3 may change Burst, stocks and movement restrictions.

## Proposed server module and ownership

Combat would own `src/server/MovementAuthority.lua`, its pure specs and CombatService/EncounterService integration. Root would own configuration flags, progression/rally consumers that cross its ownership, all Studio runs and the integration checkpoint. Presentation would own a short resynchronization notice and camera/input regression review. World would review trusted support/obstacle geometry and independently review the security diff. One owner per file remains mandatory.

Proposed API, internal to server modules only:

```lua
BeginLife(player, character, lifeSerial, serverDestination, serverTime)
AuthorizeMotion(player, serverGrant) -- issued only after a real server action is accepted
Observe(player, character, observedRoot, serverTime, serverState)
ValidateOrigin(player, character, lifeSerial, serverTime) -- accepted origin or rejection reason
EndLife(player, character, lifeSerial)
```

No remote accepts an origin, velocity entitlement, exemption name, destination, elapsed time or movement budget. Direction and action intents retain their existing allowlists and cooldown checks. Server grant IDs are never reusable client capabilities.

Keep a bounded history per living character: accepted positions/times, horizontal budget, supported-ground samples, vertical phase, active authored grants and a rejection summary. A proposed starting limit is three seconds of history at 20 Hz plus a small fixed grant ring. These are implementation candidates, not tested limits. Grant and history cleanup must occur on life replacement, player removal, reset and teardown.

## Horizontal acceptance and authored grants

1. Reject non-finite positions, impossible instance/life identities and unauthorized stage transitions before geometry work. Sample with a server monotonic clock. Client timestamps, `WalkSpeed`, humanoid states and current root velocity are observations, not permission to move faster.
2. Ground movement spends an accumulated path-length budget refilled from the **server-authorized** hero speed, earned modifiers and block/stun state. Use a bounded reservoir for replication bursts. Do not add a fresh two-stud tolerance on every Heartbeat: that would permit a sustained speed exploit proportional to the sample frequency. Do not bank minutes of standing still into a later teleport.
3. Validate both a short burst envelope and a longer sustained-distance window. Reversals spend traveled distance rather than canceling to net displacement. Diagonal motion must consume one combined horizontal budget, not one full allowance per axis. The current slower Z movement can inform a measured elliptical envelope; do not assume client input itself is trusted.
4. A server-authored dash/launch/recovery grant contains its issuing life, start anchor, start time, direction/final impulse, bounded expiry and remaining allowance. It admits the measured directional displacement/physics tail, not arbitrary movement in every direction for the entire stun window. Grant consumption must not multiply the ordinary walking allowance or stack duplicate grants. New accepted knockback replaces or composes with the actual current server-authored impulse through one documented rule.
5. Once a grant expires, unexplained motion cannot renew it from a replicated high velocity. Replayed intents, canceled windups, blocked/denied actions and old-life callbacks create no allowance. A legitimate collision can shorten actual travel; grants permit an envelope rather than requiring an exact trajectory.
6. A rejected sample does not replace the accepted anchor. It cannot be accepted later merely by feeding the same unauthorized coordinate for several frames. Recovery requires a plausible path back to the accepted envelope or an explicit server-controlled resynchronization destination.

Latency slack should be measured from server-observed behavior under the test matrix below, with a hard upper bound. It must never come from a client-supplied ping. Exact reservoir size, long-window threshold, grant tails and interpolation tolerances remain **TBD from traces**; shipping arbitrary numeric guesses as enforcement would be unsafe.

## Vertical movement and support

XZ validation alone leaves flying and height-based attacks open. Track vertical motion relative to server-observed world support and authored jump/recovery/launch grants. Cast against trusted arena support, excluding characters, VFX and nonphysical decoration. Do not treat a client-reported grounded state as proof of landing.

Because normal grounded jumps currently have no server intent, the initial observer must recognize one bounded upward transition from a recently validated, server-supported position using Config's jump capability and gravity. It must not issue repeated new jump allowances while airborne. Landing requires both a plausible accepted path and trusted support. Recovery remains its separately accepted server action. Suspended hovering beyond the measured ballistic/support envelope must not authorize air hits.

Before enforcement, presentation and combat should decide whether to add a rate-limited Jump intent alongside local prediction. Such an intent would improve attribution, but would not itself prove that the client was grounded, and the local jump must not wait for a round trip. Do not silently make that client contract change during M2.

Ramps, steps, ledges, collision impulses, changing gravity and future moving platforms need explicit support cases. Unknown world geometry should produce a diagnosed inconclusive/suspended state, not a confident cheating allegation. M4 player throws and air attacks must be registered before their enforcement gates turn on.

## Gameplay consumers and delayed attacks

Validate at action admission and again immediately before each delayed effect. Existing model, life, battle epoch, cooldown and cancellation checks remain required. A valid request must not authorize a later teleported hitbox.

For a valid release, supply the accepted current origin and server-reduced facing to `doHitbox` and the same release context to `Destruction.BreakNearby`. Preserve the present ability to move legitimately during a windup. If the origin fails, cancel the effect; do not silently attack from an old accepted position while the client's character is displayed elsewhere. Repeated resolve checks do not charge the same observation twice.

Apply the same origin validator to planned grab/throw, revive range, pickup claims and stage rally/traversal checks. Touch events alone must not grant a future weapon/coin pickup. Root's rank/par-time work must not reward a traversal performed through rejected origins. These dependencies are part of closing SEC-03; securing melee alone leaves the other movement-derived benefits unprotected.

Targets are a separate boundary: enemy hits against a displaced player must not simply skip all damage and create an invulnerability exploit. The response policy needs a coherent authoritative target/recovery state. The initial feature should withhold movement-derived benefits while retaining ordinary server KO/bounds/life processing, then use explicit resynchronization for persistent divergence. This proposal does **not** claim that source-origin checks alone solve avoidance of incoming hits, collision flinging, or every client-physics exploit.

## Avoiding camera jitter and recovery deadlocks

Begin in Studio observer mode. Compare decisions with expected fixture outcomes without changing hits or movement. Production enforcement is a separate reviewed step after evidence passes.

Do not continually write the player's CFrame, change network ownership each frame, or modify the camera target from the validator. Roblox warns that forcing server ownership can produce jitter for clients; wholesale player ownership migration is outside this bounded proposal. [Roblox network ownership](https://create.roblox.com/docs/physics/network-ownership)

Under ordinary tolerated lag, accept the measured envelope and leave the established render-time camera smoothing untouched. If a long interruption exceeds the bounded envelope, stop granting positional benefits, show a short resynchronization message and initiate a **single server-owned recovery** to a safe accepted/checkpoint position. Tie it to a generation, cooldown and completion handshake. Any client acknowledgement may confirm display/recovery generation only; it cannot authorize a destination, budget, life state or completion of server validation. The server owns the actual recovery transition; do not let retries create oscillating teleports or replenish stocks, percent, rewards, pickups or score. The raw rejected destination must not become the recovery anchor. A recovery is not a fresh campaign or save mutation.

A positional-effect denial must have bounded duration and a clear recovery path. Never leave a legitimate player permanently unable to fight after one packet stall. Exact long-gap thresholds and ownership handoff mechanics require the test traces; no automatic ban or durable penalty is proposed. Roblox's server-side enforcement guidance favors proportional responses and server decisions. [Roblox detection guidance](https://create.roblox.com/docs/scripting/security/server-side-detection)

## Required evidence before enforcement

| Test group | Required assertions and artifact |
|---|---|
| Pure clock/budget specs | Normal/diagonal walks pass; long idle cannot bank a teleport; repeated just-under-threshold jumps and out-and-back motion exhaust the sustained budget; rejected points never re-anchor; duplicate observations are idempotent; non-finite values fail closed. |
| Grant lifecycle | Every current dash, hit launch, jump, recovery, stock-share spawn, hero replacement and reconnect path; duplicate/replayed/expired grants; old model/life callbacks; launch interrupted by grab/KO; combined modifiers and maximum actual final impulses. |
| Delayed combat | A valid startup followed by an implausible in-bounds move cannot hit or break props; ordinary walking during every hero's windup still works; rejected effects consume no reward/drop eligibility; cancellation cannot be reversed by returning after the deadline. |
| Height and terrain | Local predicted ground jump without remote, valid air recovery, landing on real support, sustained hover, fake grounded state, stage ledges and lane boundaries. No false extra-air-jump grants. |
| Lag and device simulation | Actual one/four-client runs at 0/150/250 ms incoming lag, then variable delay, packet bursts, low frame rate and a long replication stall. Record settings and restore them afterward. Studio delay is not a substitute for real device/network testing. |
| Camera/input regression | Continuous forward/back travel, dash, launch, recovery, stage transition, portrait/landscape and changed viewport; record root/camera deltas and visible clips. Include a single large server recovery displacement: the existing camera center resets on CharacterAdded, not an ordinary reposition, so a same-character recovery needs its own visual regression. No recurring corrective CFrame/ownership writes or recreated movement-camera feedback loop. |
| Adversarial Studio fixtures | Scripted in-bounds teleport, teleport during windup, sustained excessive speed, oscillating movement, fake high replicated velocity, attempt to launder the origin through hero replacement/reconnect, future pickup/rally/revive exploits. Use disposable local test clients; distinguish a reproduced engine exploit from direct unit injection. |
| Economy/lifecycle | Resynchronization preserves percent, stocks, score and reward keys; does not refill pickup/drop budgets; reconnect cannot erase outstanding validation state through untrusted saved position. No live DataStore needed. |
| Cost and recovery | Bounded histories/grants with departure cleanup; four-player peak Heartbeat and MicroProfiler evidence; a long stall recovers control and effects without a repeated teleport loop. |

Proposed acceptance: zero successful unauthorized positional effects in the deterministic adversarial fixtures; zero rejected legitimate effects in the specified finite lag/ability suite; no recurring camera correction loop in recorded runs; bounded memory/CPU; independently reviewed resynchronization and reward preservation. These are finite-test criteria, not a claim of universal detection or zero false positives. Human co-op and physical-device review remain owner gates.

## Implementation sequence and current handoff

1. Combat builds the pure budget/grant module and deterministic tests in a separate work order; world reviews the math and trust boundaries.
2. Add Studio observer hooks and traces at all intended consumers. Root runs authored movement and lag fixtures; presentation compares camera behavior. Tune from recorded false rejections, not from a desire to hide failing telemetry.
3. Integrate accepted origins, cancellation and a tested recovery state behind a server-owned flag. Re-audit M3/M4 contracts that have landed since `9f29012`.
4. Root runs the complete adversarial, multiplayer, latency, camera and economy suites; a different agent reviews the diff before commit/build. Only then consider source enforcement enabled. Publication/live settings are separate owner work.

**Current status:** proposed design only. No implementation, exploit reproduction, movement trace calibration or enforcement test has occurred in this task. SEC-03 remains open. Combat owns the next implementation; root must schedule it around the M3/M4 integration freeze and retain all existing launch evidence limitations.
