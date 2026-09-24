# M4 action contract — proposed, not implemented

Prepared 2026-09-24 during the frozen M3 tier trials. This file is a design agreement record for WO-4.1/4.3/4.4 and their presentation dependencies. **No production, remote schema, test driver or runtime behavior changes accompany it.** Combat and presentation agreed the proposal below by message on 2026-09-24. Combat independently reviewed the final full document, including cancellation and pending-strike reservation, and passed the proposed contract on 2026-09-24. Agreement settles the intended interface, not implementation, runtime evidence or final balance tuning.

Read with [LAUNCH_PLAN section 6](LAUNCH_PLAN.md#6-m4-missing-features-that-fit-roblox), [M4_PICKUP_WEAPON_PLAN](M4_PICKUP_WEAPON_PLAN.md), [M4_CLIENT_READINESS](M4_CLIENT_READINESS.md), [M4_REWARD_CONTRACT](M4_REWARD_CONTRACT.md) and [M6 input-mode proposal](M6_INPUT_READABILITY_PLAN.md). Existing launch scope is contextual player grab/directional throw, three durable weapons and offensive air attack/juggle finisher. No manual weapon inventory, ranged-bottle extension, team cinematic or extra mobile grab button is added.

## Ground truth and protected behavior

Current Main sends Light, Heavy, Special, Dash, Block and Recovery intents through the existing action remote. Ground Jump is local humanoid jumping, with Recovery requested while airborne. Existing enemy Grappler events concern an enemy holding a player; they are not player grab/throw. Existing airborne hit scoring does not implement an offensive jump kick or finisher.

Server CombatService owns action eligibility, busy/cooldown state, facing normalization, hitboxes, enemy damage, launches, survival and rewards. Clients supply input intent and validated facing only, not selected victims, damage, durability, launch vectors, score or grant amounts. M4 presentation must not write root transforms or change camera ownership/smoothing/framing.

The explicit hold-Special-then-Heavy desperation gesture remains ahead of ordinary Heavy/contextual attack handling and may fire at most once per deliberate gesture. Touch desperation remains its separately labeled held cost control. V/L3/touch revive and R/R3 stock sharing remain distinct. Block/Revive release must still pass through focus/modal/life resets even when other input is rejected. Earned Berserker/Anchor restrictions continue to apply. Existing normal attacks must not gain a chord-detection delay.

## Agreed input resolution

Keep the existing `Light` and `Heavy` action intent names and validated facing payload. No target or weapon ID comes from the client. The server reevaluates context at acceptance; snapshot hints can be stale and cannot authorize a move.

| Intent/context | Server resolution and client label |
|---|---|
| Light with a valid current player-held enemy | Throw that captured target in current validated ±X facing; label THROW. |
| Otherwise Light, grounded and holding a weapon | WeaponLight; label the weapon kind and remaining durability. |
| Otherwise Light, airborne and air-attack eligible | AirAttack, a directional unarmed jump kick; label AIR KICK. An armed actor retains its mounted weapon but spends no durability. |
| Otherwise Light, grounded | Existing normal Light chain. |
| Otherwise Light, airborne but ineligible | Reject; do not silently spend weapon durability or perform a ground Light. |
| Heavy while holding an enemy | Release the hold only after ordinary Heavy eligibility succeeds, then perform ordinary Heavy. This press cannot also become a finisher. |
| Otherwise Heavy with current server finisher eligibility | JuggleFinisher against the target captured at acceptance; label AIR FINISH. |
| Otherwise Heavy | Existing ordinary Heavy. |

The explicit desperation chord remains higher priority than ordinary Heavy routing when eligible. **Holding an enemy makes canDesperation false and rejects paid Desperation server-side without cost or release.** An eligible normal Special may release the hold and cast without being reinterpreted as paid desperation. This resolves the earlier considered alternative of allowing paid desperation to release a hold; that alternative is retained below, not selected.

## Agreed contextual grab and throw

The server may auto-grab when a grounded, unarmed, free, nonblocking, nonreviving and nonbusy player walks toward a stunned ordinary enemy whose role is Grunt. Elites and armed players cannot auto-grab. Select the nearest eligible target in front within proposed starting bounds 3 studs in XZ and 2 vertically; the first valid server claim owns it. Mobile requires no new grab button: approach, then the existing Light tile becomes THROW. Current directional movement/facing chooses left or right.

A hold lasts at most 1.25 seconds, with a .75-second regrab cooldown after release. These distances/timings are agreed starting values, to be recorded with later tuning evidence. The holder retains normal movement: no player root teleport/anchor, speed rewrite or camera change. The target stays server-owned and follows/poses without being welded into the client-owned player's assembly. A separate grab stun prevents target attacks; ending the hold does not refresh the original stun.

Release without throw damage on timeout, separation beyond 5 XZ or 3 vertical studs, target death/removal, holder becoming airborne/hit/launched/KO/downed, travel, retry, stage/terminal transition or departure. A locally predicted Jump becomes visible to the server as airborne and releases there. After an eligible Heavy, normal Special, Block, Dash or Revive begin passes its existing checks, release before performing that ordinary action. Rejected Anchor Dash, Berserker Block or invalid revive must not alter the hold. Block/Revive release remains unconditional; it does not invent a throw.

A Light throw captures hold ID, both actor lives and attack identity before releasing. The server resolves the thrown target and collateral through its swept path, with one damage application per enemy in that throw. Initial victim and collateral use the ordinary hit/style/reward pipeline; no friendly damage, selected-victim payload or extra currency grant is introduced. If the captured actor/target lifecycle invalidates the move, cancel rather than retargeting.

## Agreed weapon and air interactions

Pipe, blade and bottle retain the pickup plan's proposed melee interpretation and five/four/one starting durability; final attack stats/tuning still require root/combat configuration before implementation. Grounded accepted WeaponLight captures ID, kind, pre-decrement durability, actor life and attack serial before debiting one durability, including an accepted miss. Rejected requests spend nothing. The last legal strike may render/resolve from its captured context after held state becomes false; cancellation, transfer or invalid actor life invalidates it. Even after the snapshot becomes weapon=false, retain a private pending-weapon-action reservation until that captured strike resolves or cancels; refuse a new weapon pickup or transfer during that reservation. Never create a transferable zero-durability ground drop. AirAttack does not use or consume the held weapon; aerial weapon swings are not part of this launch contract.

AirAttack is allowed once per player airborne episode, with existing Light cooldown/busy validation and alive/free checks. Landing resets episode eligibility, not the ordinary cooldown. Armed players use the same unarmed kick. Air attack damage/range/windup/launch values remain deliberate root/combat tuning decisions, not inferred from these labels.

JuggleFinisher requires the player airborne and a nearby launched, airborne ordinary Grunt within proposed 6 XZ / 6 vertical studs, with at least two accepted hits from that player in the target's current airborne episode. The initiating accepted launching hit counts as one; the accepted jump-Light hit counts as two, making Heavy-launch → jump-Light → air-Heavy executable. Rejected damage or immune/blocked events do not advance the chain. A target episode permits one finisher; relaunch before landing retains the same episode and cannot refresh the allowance. Capture target model, life, launch episode and the existing attack serial server-side when Heavy is accepted. Either the actor or target landing before impact, replacement or cancellation invalidates the delayed strike; never retarget or fall back to an ordinary hit on another target. Landing, KO, target replacement, stage change or retry resets the applicable episode. Elites are excluded initially. There is no extra self-percent cost or input delay, and invalidating an already accepted finisher does not refund its attack or create a second strike.

## Agreed proposed snapshot and FX fields

These fields do not exist merely because this document names them. Implement atomically with consumers after release and test explicit clearing.

| Local authoritative snapshot field | Proposed shape / meaning |
|---|---|
| actorLife | Positive server actor-life generation for the current player rig. |
| holdingEnemy | Explicit false or `{id,targetModel,remaining,canThrow}`; remaining is relative seconds, not a client-authoritative clock. |
| weapon | Explicit false or `{id,kind,durability}`; actual current held identity and remaining count. |
| lightContext | `Light`, `Throw`, `WeaponLight`, `AirAttack` or `Unavailable`; advisory display only. |
| heavyContext | `Heavy` or `JuggleFinisher`; advisory display only. |
| canAirAttack / canJuggleFinish | Booleans recomputed from current server eligibility. |

Server-authored `CombatLife` on player and enemy models supplies the cosmetic life-matching source. Combine model identity, life generation and run-scoped event IDs. Gameplay always uses private server records/generation; replicated attributes are never entitlement or validation inputs.

Accepted existing `Attack` FX preserves `action='Light'|'Heavy'` and adds `resolvedAction` (`Light`, `Heavy`, `Throw`, `WeaponLight`, `AirAttack`, `JuggleFinisher`), `targetModel` as the acting model, `actorLife`, `attackId`, and `direction`, alongside existing position/hero/player identity where applicable. Optional captured fields are `victimModel`, `victimLife`, `launchEpisode`, `holdId`, `weaponId`, `weaponKind`, `capturedDurability`. The server-generated launchEpisode is cosmetic/diagnostic identity only, never client authorization. Consumers must resolve one pose/effect path, not play both generic Light/Heavy and the contextual action.

New `PlayerHold` FX: `state='Begin'|'End'`, `holderModel`, `holderLife`, `targetModel`, `targetLife`, `holdId`, `remaining`, `reason`. New `WeaponState` FX: `state='Equipped'|'Dropped'|'Exhausted'|'Cleared'`, `actorModel`, `actorLife`, `weaponId`, `weaponKind`, `durability`, `reason`. Reason labels are presentation diagnostics; they do not authorize state. Older End/Cleared events must not erase newer identities. PlayerHold is distinct from existing EnemyGrab/EnemyGrabRelease victim-rescue events, which retain their meanings.

New `ActionCancel` FX for accepted contextual attacks carries `actorModel`, `actorLife`, `attackId`, `reason`. Send it after the authoritative attack serial is canceled; it is a presentation notification, never required for server hit safety. The client cancels only matching life/attack context, so an old cancellation cannot erase a newer action. Stage/life cleanup also clears old state if an event is lost, and every cosmetic action has a bounded captured-duration lifetime. Existing EnemyCancel semantics remain unchanged.

## Shared lifecycle and visual invariants

A held enemy has one server owner. A weapon has one server identity across ground/held/pending-strike/exhausted states, one remaining-durability count and one valid actor life. Final accepted weapon swing captures its attack context before consuming the last durability; a rejected request consumes nothing. An invalidated final strike never produces a zero-durability ground pickup. Damage/launch, perfect block, former-holder repickup lock, retry/travel/departure and campaign cleanup follow the explicit pickup-plan rules rather than duplicating a second registry.

Presentation reconciles authoritative held-state updates and explicit removal, never local counters. It must render another player's action from the accepted event's captured actor/weapon context and discard events for a removed/replaced actor life. Old release/removal events must not erase a newer hold or weapon. World owns ground/enemy native visual templates; presentation owns hero attachments, local HUD and action poses. All mounts remain cosmetic and preserve seven queryable core parts/six motors. Tide's authored glaive and Piston's built-in gauntlet require an intentional per-hero attachment/visibility pass rather than overlapping additional weapon parts blindly.

Food/coin identity, ten-second ground lifetime, first eligible touch and actual LOOT RECEIVED accounting remain in the separate pickup/reward contracts. A player throw or weapon hit must use the existing authoritative hit/style/reward path without a second direct coin grant. No paid power or camera cinematic belongs to these actions.

## Verification required after implementation release

- Pure action-routing cases must establish one resolved action per press, stale-context rejection/fallback behavior, desperation precedence and no ordinary-input delay; include armed/airborne/holding transitions and disabled capabilities.
- Server fixtures must cover auto-grab eligibility/elite rejection/contested ownership, throw direction and enemy-on-enemy hits, hold expiration/interruption, final weapon swing and transfer cancellation, airborne eligibility and finisher target/chain cancellation. Client snapshots alone are not proof of server enforcement.
- Actual two-client shared cues and bounded visual cleanup must cover actor death/replacement, target removal, out-of-order release/attack, weapon exhausted/disarmed/transferred and stage/retry/terminal cleanup. Validate original seven-part/six-motor cores after mounting every weapon on every hero.
- Root records one short clip or screenshot per feature. Inspect normal side-camera poses, readable weapon/durability/context labels and critical enemy tells. Touch/controller reachability, short-height minimum 44px targets and focus restoration remain explicit checks; policy/widget tests do not certify physical hardware.
- Re-run M3 survival/Heat/boon/reward/revive/desperation checks affected by integration, and preserve frozen baseline outputs. HumanBot changes, if needed to exercise M4, require an explicit new policy revision; do not silently alter the 15 frozen trials.

## Preserved alternatives

Dedicated grab/throw buttons, manual weapon swap/drop, aerial weapon attacks, paid desperation releasing a hold, armed auto-grabs, a ranged bottle and shared cinematic team finishers remain alternatives outside the selected launch contract. The selected routing above supersedes the earlier explicit-Throw-remote and air-Light-before-grounded-weapon suggestions without deleting those ideas. Keeping those ideas does not imply implementation or owner approval. Any final balance numbers are starting points to be recorded in COMBAT with measured outcomes, not guessed from the reference video.
