# Independent quality review — Curtain Break

Review date: 2026-09-23. Reviewer: separate world/review subagent. Scope: read-only source review of the current shared files and official Roblox API/testing documentation. This reviewer did not operate Studio, capture a running client, complete a combat run, or run a two-client session. The implementation was still being integrated during review. Findings reported below need final-source recheck and runtime verification; a review item is not closed by adding a comment or an asset register entry.

## Verdict

This historical review concerns an early playable slice, not a quality certification. It has a controlled three-stage city route, server-owned combat calculations, character kits, stocks, UI and a documented Toolbox provenance workflow. The most substantial gap is moment-to-moment combat presentation and multiplayer proof, not the number of buildings or named abilities. Do not describe it as a finished original-cast experience or claim benchmark parity from source inspection.

## Findings reported during integration

| Priority | Source location / trigger | Consequence | Required resolution and evidence |
| --- | --- | --- | --- |
| P1 | `Main.client.lua`, FX event handler; server emits `Telegraph` and `BossPhase` | In the reviewed snapshot neither event was handled. Enemies wait before attacking, but the player cannot see the intended attack warning or phase change. Large boss hitboxes become difficult to predict. | Draw telegraphs with dimensions and direction matching the actual attack, visibly distinguish boss phase two, and verify from the final camera with simultaneous specials. Every enemy attack must have a warning visible before damage. |
| P1 / integration watch | `CombatService.lua`, Heartbeat X clamp; encounter progression across an opened gate | Players are clamped to `arena.MaxX - 4` when not launched. An encounter controller that waits for players to cross the old MaxX without first relaxing/changing that clamp will deadlock progression despite an open gate. `EncounterService.lua` was not yet available at initial review. | Confirm stage-clear flow deliberately permits forward transition. Play all three stages with both players; the slowest player must not be stranded or instantly KO'd by a new arena's blast bounds. |
| P2 | `CombatService.lua`, `aiStep`, server writes to `Motor6D.Transform` | Transform is not replicated. A server-only procedural walk cycle does not prove clients see enemy limb animation. Static sliding enemies substantially weaken polish and combat readability. | Animate enemy rigs on each client or use server-created Animator tracks with tested permissions; inspect the enemy from both client windows. [Roblox Motor6D documentation](https://create.roblox.com/docs/reference/engine/classes/Motor6D/Transform). |
| P2 / integration watch | `ToolboxAnimations.lua` and `ToolboxHitbox.lua` exist, but initial client/server snapshots did not require them | An asset inventory could claim adoption while gameplay still uses fallback poses and inline hitbox code. | Trace actual runtime callers of both modules; verify imported combat and dash motion in the running client. The final source must use the adopted implementation rather than merely ship unused files. |
| P2 | `AssetInstaller.lua` sets `EmitCount`; initial `importedEffect` reads `BurstCount` | Impact emitters default to 16 particles each, ignoring the intended 2/14/1 counts. This changes the VFX composition and multiplies transient particle cost. | Use one shared attribute contract and verify all three emitter counts at runtime. |
| P2 | Client procedural pose playback changes only the local character in the initial snapshot | Other players may see hit particles but no matching teammate attack motion. | On every client, route server attack events to the correct character using playerUserId, and animate accepted attacks consistently. Validate one attack by client A while observing only client B. |
| P2 | R6-only pose data with no explicit R6 guarantee in the initial project configuration | Imported sequences may fail to apply to a default R15 avatar or leave body parts moving incorrectly. | Supply a known compatible rig or enforce R6 and verify respawns preserve the rig and animator state. |

### Integration recheck

A later read of CharacterFactory.lua, EncounterService.lua, CombatService.lua and Main.client.lua found these changes:

- **Fixed in source, runtime check pending:** Toolbox animation data is loaded and sampled; combat calls ToolboxHitbox.Query; authored R6 hero rigs provide compatible joints; particle playback accepts EmitCount; Telegraph, BossPhase and GuardBreak have visible handlers. These are no longer missing-implementation blockers.
- **P1 progression deadlock not present:** the encounter director automatically resets/transports players into each next stage. However, it never references the physical Gates folder and uses StageClear between waves. **P2 remains:** the HUD says the curtain is open and asks players to advance while a closed curtain and arena clamp remain; the mission advances by automatic teleport instead of walking the authored route. Resolve with deliberate gate opening/advance flow, or accurately communicate checkpoint transition and inter-wave state.
- **P2 warning accuracy remains:** the server sends radius = spec.Reach but attacks use Range = spec.Reach + 2. The shown rectangle understates actual reach by two studs on each attacked side. Send actual attack dimensions; verify warning and damage overlap.
- **Still open in source:** remote teammate attack-pose playback and enemy motion replication. Sampled Toolbox poses apply only to the local humanoid; server enemy motion still writes the non-replicated Transform property.
- **Historical character-art pass (retired):** the prototype added recognizable accessory/outfit motifs. The original-IP launch direction supersedes this pass completely; changing labels does not satisfy the replacement requirement. Its runtime art observations do not validate the new cast.

No runtime behavior is marked passed by this source recheck. Keep subsequent fixes and actual Studio observations in the final test report.

## Measurable production polish gaps

1. **Character identity.** Authored R6 silhouettes now distinguish the heroes, while special behavior remains largely shared with different numbers. Deliver at least one visually unique special for Gale, Piston and Tide. Acceptance: testers identify each selected hero from a silent gameplay screenshot without reading its name. This does not require claiming that present prototype names are completed character assets.
2. **Audio.** The reviewed source contains no gameplay Sound playback. Add original or permission-cleared impacts, whooshes, guard feedback, KO cues, station ambience and an appropriately mixed music layer. Acceptance: a tester can distinguish hit, block, whiff and KO by sound; four simultaneous attacks do not clip or drown out warnings.
3. **Move readability.** Present kit differences are mostly range/damage/width differences. Add per-kit pose and effect language: forward spiral charge, elastic long-range strike and broad sword/water sweep. Acceptance: each special's visible reach agrees with server hit coverage and contact time within an agreed frame budget.
4. **Smash-inspired loop.** Percentage scaling and recovery exist, but percent-limit KOs make combat primarily threshold attrition. Continuous floors and closed physical gates prevent many ring-outs. Decide and document the intended hybrid. Acceptance: if launch-and-recovery mastery is promised, demonstrate meaningful recoverable launches and fair blast-zone KOs in every stage, not only automatic defeat at a damage cap.
5. **Cooperative purpose.** More concurrent players alone is not a developed co-op experience. The story preserves rescue/relay objectives, but those are future work until playable. Acceptance: one encounter rewards teammate coordination beyond both attacking the nearest enemy; downed/exhausted players have clear feedback and an intentional re-entry rule.
6. **Enemy/boss variety.** The initial AI is chase-nearest-target then perform a facing hitbox; boss phase two increases speed and repeats a wider strike. Acceptance: at least three recognizable enemy roles and a boss with two distinct, fair response patterns; simultaneous enemies do not keep an isolated player in unavoidable stun loops.
7. **Environmental interaction.** Whole prop assemblies and bounded server destruction are now implemented; see the destruction follow-up below. Runtime and two-client behavior remain unverified by this reviewer. Acceptance: breaking a prop removes or transforms its full visual assembly consistently for both clients, with bounded debris and no collision remnants.
8. **Performance and interface.** The city deliberately uses many repeated Parts and SurfaceGuis. Acceptance target: maintain at least 30 FPS on the chosen minimum-spec mobile device during four-player peak effects; record actual hardware, resolution and profile results. Test 1280×720 desktop and phone landscape for unclipped buttons and telegraphs. These are proposed targets, not measured results.
9. **Accessibility.** Add reduced camera shake and effect intensity options, and encode warnings using shape/motion as well as red color. Acceptance: attack danger remains clear with shake disabled and under a color-vision simulation.

## Two-player Studio test route

Use Studio's **Server & Clients** testing mode and set the local player count to **2**. This creates separate server and client simulations. It is the correct test for peer-visible animation, shared stage state, server-owned hit results and respawn behavior; solo Play is insufficient. See [official Studio testing modes](https://create.roblox.com/docs/studio/testing-modes).

Keep server and both client Output panels available. Record the source revision and a short result log for each step:

1. Start both clients. Confirm both spawn in the first lane and see the same wave/stage/remaining-enemy state. Select different heroes and observe each from the other client.
2. Have A attack while B watches, then reverse. Check combat/dash animations, hit particles, percent changes, audio and facing. Each contact should apply damage once, and teammate attacks should not damage allies.
3. Hold guard on A while B draws enemy pressure; release guard, lose window focus and regain focus. Guard must not remain stuck. Test specials together during an enemy telegraph.
4. Clear the first stage with A near the exit and B near the entrance. Move A through the open gate. Verify transition does not strand, teleport into damage, or incorrectly KO B. Repeat with the positions reversed at the second gate.
5. Deliberately lose one stock, then all stocks on A. Verify B's view of the KO, A's spectator state, enemy target selection, remaining stocks and the intended re-entry/checkpoint behavior.
6. Let both players exhaust stocks. Restart from each client in separate runs, then attempt simultaneous restart. Confirm one clean reset, exactly one city/enemy folder, no duplicated UI/connections and consistent stocks.
7. Complete all waves and the boss. Confirm the final win state appears once on both clients. Restart and repeat a short encounter to catch stale cooldowns, gate state and delayed callbacks.
8. Disconnect one client during a wave. Check scaling/count state and defeat/victory progression. Start a late-joining client if supported and verify safe stage positioning.

## What cannot be established by this review or a solo test

Actual enjoyment, benchmark parity, party coordination, latency fairness, peer animation replication, reliable two-player progression, mobile GPU/memory behavior, published-experience particle/animation permissions and accessibility quality all require additional evidence. A successful server simulation or forced victory command establishes only the exercised state transitions; it does not establish that normal player inputs can finish the game or that the combat feels polished.

## Final root integration and runtime verification
Earlier source findings above describe the reviewed snapshots. Final implementation now opens gates and waits for all living players at the exit; Intermission differs from Advance. Telegraph reach matches attacks. Real Toolbox animation data is sampled on each client for local, peer and enemy R6 rigs; server joint animation was removed to avoid competing writes. Three reviewed audio assets are wired. Runtime hit, rate-limit, stock/wipe/retry and forced full progression tests passed; see VALIDATION.md. Remaining production polish and multiplayer stress targets remain open.

### Destruction implementation follow-up

The world/review agent subsequently implemented complete prop assemblies and a server-side DestructionService in response to the integration owner's explicit follow-up. This section is an implementation disclosure, not an independent claim of visual quality: the same agent authored the environment and this destruction service.

- Five vending machines, nine utility boxes, six benches and one signal are each grouped with every decorative part. Heavy/special integration can call BreakNearby(position, radius, direction); light hits need not break props.
- Break state and full visual restoration are server-replicated. A 20-second restore timer preserves original transparency, collision, touch/query and shadow settings. Destroyed/rebuilt city models cause old restore callbacks to exit.
- At most four debris pieces spawn per prop, with a global 30-piece cap and 1.5-second lifetime. Debris has no collisions, touch or spatial-query participation. Only tagged Models under the current NightfallCity are eligible; structural lane geometry is excluded.
- Source-level checks confirm API bounds and whole-assembly ownership. Actual trigger behavior, remote-client disappearance/restoration, latency under simultaneous breaks, peak frame time and attractiveness of the effect require Studio tests. No two-client destruction result is claimed here.
- Required test: trigger one vending-machine break, confirm all bottles/glass/body disappear on both clients, verify Broken suppresses repeat breaks, exceed 30 requested fragments without exceeding the cap, wait 20 seconds for full restoration, and repeat after a city rebuild. Verify roads/gates/rails survive an overlapping blast.

Client owner also reported peer/NPC pose sampling and combat audio integration. Those reports supersede the earlier missing-feature snapshots once confirmed by the final source/runtime check; this review did not independently verify their running appearance or latency.
### Final root and independent review
Integrated Heavy/Special attacks invoke destruction after accepted server windup. Studio verified actual Heavy triggering, all 21 props hidden, global 30-debris cap, cleanup and full restoration. Three distinct hero specials instantiate without errors and grounded jump input works. Independent combat-agent read-only review found no material blocking bugs in client/world additions. See VALIDATION.md for exact results; two-client destruction under latency remains open.
