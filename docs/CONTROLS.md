# Player controls and presentation

The game uses controlled 3D arenas with full XZ floor movement. Each city, station and factory district has four areas: enemy group, enemy group, miniboss, boss. Clear an area to open its physical exit, then rally right together before the next area locks. The server owns damage, hit detection, cooldowns, knockback, stocks, and encounter progression.

| Action | Mouse / keyboard | Gamepad | Touch |
| --- | --- | --- | --- |
| Move across arena floor | A D / W S | Left stick | Left thumb pad |
| Jump / air recovery | Space | A | Jump |
| Light combo | Left mouse button / J | X | Light |
| Heavy attack | Right mouse tap / K | Y | Heavy |
| Hero special | E / L | B | Special |
| Dash | Q | Left trigger | Dash |
| Hold guard | F | Left bumper | Hold Block |
| Air recovery | Space while airborne | Right bumper | Recovery |
| Select Rook Calder / Bo Marlowe / Isla Veyra (candidate names) | 1 / 2 / 3 | D-pad left / right cycles | Hero name |
| Ready in the lobby | Enter | Start | Ready |
| Restart after end screen | R | Start | Play Again |

Right mouse drag remains native camera orbit; Heavy is requested only by a short tap, not a drag. The source tap threshold is at most0.28seconds with at most6pixels of cumulative movement and release offset. Menu/UI focus and cancellation suppress combat gestures. J / K / L remain keyboard alternatives. When Special is cooling down and the server offers Desperation, hold E then tap the right mouse button to request it; holding L then pressing K remains the legacy chord. E normally requests Special when available. Physical mouse/controller/touch validation remains separate from source implementation.

The first grounded jump uses Roblox Humanoid jumping. A second airborne press requests server-authorized Recovery. This is the prototype's shared double-jump/recovery resource, not an extra unlimited jump. High damage percentage means larger launches. Stocks are lives; guard and recover before your squad runs out. Hero selection availability and cooldowns are enforced by the server.

## Camera and accessibility

- Roblox's normal third-person camera follows the character and can rotate/zoom using native camera controls: hold the right mouse button and drag to rotate, and scroll the mouse wheel to zoom. The camera subject is the local Humanoid. Keyboard, stick and touch movement follow the camera's horizontal forward/right axes. Source requests Classic camera mode, FOV70 and zoom8-28; actual device interaction and camera collision remain validation gates. See [3D conversion](launch/ARENA_3D_CONVERSION.md).
- Health is represented by readable damage percentage and discrete stock marks. Cooldown buttons show numeric time remaining.
- Buttons support mouse activation in addition to keyboard, gamepad, and touch inputs. Input resets when the app loses focus.
- The custom controller replaces Roblox default controls so keyboard, thumbstick, and touch directions stay aligned with the current camera view. Cardinal speeds are equal and diagonal input is normalized. The Humanoid controls ordinary locomotion yaw; attacks and guard use a horizontal facing vector.
- Settings (O / gamepad Back) provide effect density, master volume, stage ambience, combat music, and high-contrast warnings. The obsolete scripted-camera shake control is removed; native camera behavior is not driven by combat camera kicks. Critical telegraphs remain visible even at 0 effect density. Settings last for the current play session.

## Imported asset contract

The client actually samples imported Toolbox R6 pose data from `Nightfall.Shared.ToolboxAnimations`: Combat Animations **14578890309** by PixellDaZuera and Dash **109267687059124** by z0efx63. Light/alternate light/heavy/guard/dash plus idle/walk are interpolated from their original keyframes. Authored original special poses/effects are implemented alongside these imported clips; the historical baseline reused Heavy. Teammates and enemies are sampled on each client; server combat timing remains authoritative.

The installed Hit VFX template is cloned for impacts. Enemy attacks use anticipation poses/flash or oriented floor footprints during windup; boss overload has a distinct banner and burst. Toolbox audio references are Punch Impact1 **132504023010884**, whoosh **135315310485417**, and City Night Ambience3 **9112759731**. Impacts are deduplicated and limited to eight concurrent transient sounds. Audio still depends on Roblox asset availability/permissions in the published experience.

Audited imported templates live in `ReplicatedStorage.Nightfall.Assets`:

- The current authored R6 cast uses the serialized Toolbox keyframes and authored special poses through one joint sampler. Optional published `AnimationId` playback is no longer a parallel animation path; this avoids competing writers for the same joints.
- `VFX/<Hero>/<Event>` (Model, BasePart, Attachment, or ParticleEmitter). Flat hero-prefixed or event names also work. Events: Hit, KO, Attack, Special, Dash, Recovery. The client places the clone at the replicated event location, emits particles, and cleans up after three seconds. ParticleEmitters may carry numeric `BurstCount` or `EmitCount` attributes, clamped to 1–60.
- The client removes script descendants from VFX clones as an additional precaution. This is not a substitute for inspecting imported assets in Studio before they enter the project.

When no compatible effect exists, bounded neon impact particles make attacks visible. The current renderer targets the authored R6 rigs; non-R6 compatibility is not promised. The imported clips and authored effects are **prototype presentation**, not an assertion of production animation quality. Rig compatibility, timing, readability, audio permission, and multiplayer visibility need Studio playtesting. Distinct cinematic special animations and a fully mixed soundtrack remain unfinished.

## Required hands-on QA

The source implementation should not be labeled on par with the requested Roblox combat-quality benchmark until these are observed in a running Roblox client:

1. Solo and 2–4 player Studio sessions: every hit confirms once, each player's own camera view remains readable, and stocks/restarts agree for all clients.
2. Keyboard, Xbox-style controller, and phone landscape: movement, guard release, hero selection, ability labels, and restart remain usable with safe-area insets.
3. Every hero has distinct permission-cleared animation and VFX sets, readable windup/contact/recovery, and convincing audio.
4. Low-end mobile stress test: effect bursts remain below budget during four concurrent specials. Verify frame time with MicroProfiler.
5. Review native camera rotation/zoom, touch thumb-pad placement, UI text size, and color-independent combat readability with players.

Current limitations: no input rebinding, no dedicated portrait-phone layout, no cross-session settings persistence, and no split-screen camera. HUD and touch controls adapt for landscape; a real-device pass remains necessary. Each player has an individual third-person camera; there is no automatic party-fit zoom. A scattered squad is not expected to share one view. Co-op awareness, native occlusion and warning readability need a representative multiplayer/device pass.

## Hero special presentation

WO-1.3 replaces the retired special visuals with the following original languages. See PROGRESS.md for implementation and runtime evidence; these are not acceptance claims:

- **Gale / Cyclone Drive:** corkscrew kick and forearm wind ribbons.
- **Piston / Recoil Cannon:** mechanical gauntlet, piston/chain extension and recoil steam.
- **Tide / Undertow Arc:** rotating glaive sweep and broad water crescent.

These are authored procedural visual effects layered onto imported Toolbox combat animation/audio. They are not additional imported Toolbox assets. Bespoke skeletal poses and VFX coverage must be checked against each server-defined windup, range and width.

The effect scheduler caps concurrent hero specials at eight, uses one temporary render connection, and removes all parts in approximately one second. Parts are anchored, non-colliding, and non-queryable. Release sound happens after windup; the previous scripted camera kick is retired with the fixed camera. The visuals do not create hitboxes, move characters, apply damage, or freeze simulation; authoritative server attacks remain unchanged. Visual travel is stylized and is not a simulated projectile collision test.
## Three-chapter encounter HUD

The HUD reads stage names directly from the server: city streets, abandoned station, and abandoned factory. Four areas per stage comprise enemy group, enemy group, miniboss, and boss. A chapter title introduces each district and is dismissed as soon as a critical attack warning arrives. The top-center boss meter shows the active miniboss/boss name, phase, and remaining break threshold; the delayed pale segment helps damage read clearly.

Server telegraphs specify exact locked box or circle footprints. Red/orange warnings say **DODGE** and jumpable cyan warnings say **JUMP**. Ground labels, a textual local-danger banner, and offscreen directional markers remain enabled with cosmetic effects disabled. The local warning uses X/Z footprint membership and does not claim that being airborne is safe. It is instructional presentation, not hit detection. Enemy impacts briefly flash the same footprint.

Run results show server-reported defeats, damage dealt, damage taken, and elapsed time. Missing values show a dash. Currency/progression comes from the separate progression menu; the combat HUD does not invent rewards.

## Input and accessibility updates

- **O / gamepad Back:** open settings. **B** closes settings while it is open. Gamepad focus navigates between rows; minus/plus buttons adjust sliders by 25%, and mouse/touch can drag slider tracks.
- Settings have a scrolling content area on short screens so controls retain useful size. The co-op simulation keeps running while menus are open; the menu says this explicitly.
- The gameplay client suppresses movement/actions while `MenuOpen` (progression) or `SettingsOpen` is true and releases guard when settings open.
- Touch actions use a two-row, three-column cluster, with a separate jump button above. Action hints adapt to the latest keyboard/controller/touch input.
- Positive damage can hold only the sampled cosmetic attack/victim pose for 45–60 ms and briefly highlight the victim. This never freezes the Humanoid, physics, server damage, cooldowns, or other players. Cosmetic flash intensity is suppressed when effects are off.

## Integration contracts

`CombatHUD.lua` consumes the main combat snapshot, including optional `boss={name,kind,percent,threshold,phase,role}`, `encounterKind`, `nextWaveAt`, `checkpointLabel`, and `runStats={kills,damageDealt,damageTaken,duration}`. `boss=false` hides its meter. Telegraph/EnemyImpact fields are `position`, oriented `cframe`, `shape`, `size`, `radius`, `duration`, `mechanic`, `color`, and `jumpable`; legacy directional range packets remain supported. Exact hit feedback uses `targetModel` or `targetUserId` from the server, while `playerUserId` still identifies the attacker.

Main initializes the separate root-owned `ProgressionUI` module once when available. `NightfallHUD.Canvas` is named for integration. Settings and progression share a top-center utility row and independent player attributes so they do not clear each other's modal state. No client code awards currency or changes saved progression.
## Ready lobby and controlled traversal

The initial lobby has no forced countdown. Choose a hero, review the movement/combat lesson, inspect progression/settings if needed, then press **Ready / Enter / gamepad Start**. The HUD shows how many connected players are ready. Solo starts when its one player readies; co-op starts once everyone is ready. Before the final ready, a player can cancel their ready state. The four-second chapter introduction begins only after the server starts the campaign.

Between encounters, the server may enter `Traverse`. A cyan world marker and objective banner show where the living squad must rally and the current count at the destination. The next wave does not spawn until the squad reaches it. The same guidance marks the district exit during `Advance`. Physical gates and server-owned rectangular bounds contain each fight. The prior exit remains open during traversal; an unexpired downed teammate outside the next area delays its rear seal so the party can return to rescue. This does not extend the revive deadline or restore stocks.

Boss HUD now shows armor/exposure status and a separate poise strip. **EXPOSED — PUNISH NOW** marks a recovery opening. A server `BossStagger` cancels that enemy's outstanding floor and UI warnings, so a successfully interrupted attack is no longer presented as imminent. Guard direction updates from horizontal movement intent while held. The camera follows the local Humanoid through Roblox's normal camera controller. Downed-camera behavior and co-op rescue readability require an actual play check.

Additional optional state fields: `ready`, `readyCount`, `playersTotal`, `targetX`, `objective`, `arena={MinX,MaxX,MinZ,MaxZ}`, and walking limits on both axes. Ready input is `Action("Ready", {ready=true/false})`. The journal uses **P / left-stick click**; settings uses **O / gamepad Back**.
## Elite impact identity and stage sound

`BossEffects.lua` responds only to server `EnemyImpact` packets, after damage resolves. Executioner cleaves leave amber shards; Siren Marshal impacts use red/blue beams and pulse fragments; Platform Widow leaves rail ribbons and spectral tickets; Last Conductor produces a short train afterimage or departure-clock flash; Furnace Hound leaves cinder claws and scorching fragments; Kiln Sovereign releases furnace columns and steam.

These are original cosmetic additions. They do not replace the imported Toolbox animation/hit VFX pipeline and do not create damage. Each uses the locked packet position/cframe/size/radius. The train crosses its lane in 0.26 seconds after the instantaneous full-footprint impact flash; it is not a traveling hitbox or an extra dodge opportunity. The module caps six concurrent effects and 24 BaseParts per effect, uses one temporary render ticker, and cleans all effects in under one second. Zero effect density suppresses these ornaments while the critical telegraphs remain.

`StageAudio.lua` switches looping ambience by chapter with 1.1-second envelopes: city **9112759731**, abandoned station **9112772977**, factory **9112890492**. A quiet combat score **1844978927** fades in/out over 0.7 seconds around Combat state. Master volume affects all audio; stage ambience and combat music have separate settings, and either can be muted independently. Silent channels pause, and the envelope ticker disconnects when levels settle. Permission failure does not create a per-frame play/retry loop.

The supplied IDs were verified as loadable in the root's Studio edit session. The live published universe's audio permissions and final four-player mix still require verification. No anime soundtrack was added.
## Phone safe area

Main and presentation GUIs use CoreUISafeInsets, which includes device cutouts and the Roblox top bar. Layout reads the resulting canvas size. Touch capability changes refresh the thumb pad and jump visibility. Phone combat uses compact headers and a 70-pixel health plate, a narrow boss/warning stack, and six action buttons with at least 48-pixel height. The full hero selector remains in the ready lobby; compact safe-state hero tiles retain at least44-pixel targets even on short screens; action/rescue layouts have separate reserved rows. Initial wave-zero intermission says ENTER THE CURTAIN / GET READY. Overlapping hazard text prioritizes the soonest impact. Physical-phone play and four-player overlap still require final validation.

## Voluntary co-op stock sharing

When a living player has at least two stocks and a connected ally is downed, a contextual GIVE 1 STOCK prompt identifies the ally. Press R, click the right stick (R3), or tap that prompt. The server selects/validates the target, transfers exactly one stock, preserves the donor's damage, and revives the ally with one stock, zero damage, and two seconds of protection. There is a ten-second donor cooldown. This uses no coins or purchases. The prompt disappears when unavailable and never becomes a persistent seventh combat button. R still retries on the results screen. Journal/settings suppress rescue input. This interaction requires multiplayer runtime validation.


## Preserved side-view direction and evidence limits

Before the owner's 2026-10-02 conversion, the stages used a narrow Z lane, party-following side-view camera and skirmish/miniboss/skirmish/boss order. CAMERA_REGRESSION.md and the earlier HumanBot reports describe that version; they remain historical evidence. The new arena policy/geometry, scripted locomotion and route checks are scoped in [ARENA_3D_CONVERSION](launch/ARENA_3D_CONVERSION.md). They do not certify physical keyboard/controller/touch use, camera comfort, ordinary fights or co-op rescue/retry. Any unresolved action check remains open in the linked evidence. No launch acceptance is implied by this controls reference.

The first 3D prototype used a fixed elevated camera and48-stud-deep arenas. WO-3D.2 supersedes that with native rotatable third-person follow and72-stud depth plus surrounding scenery. The custom controller now maps movement relative to the camera, preserving server-owned arena bounds and attack rules. Fixed-camera motion checks do not certify this revision.

## WO-3D.3 attack timing and preserved controls

The owner selected left mouse Light, right mouse tap Heavy, Q Dash, E Special, Space Jump / airborne Recovery, and F hold Guard. Right mouse drag continues to orbit the native camera. The previous E Recovery / L primary Special layout is superseded; J / K / L attack aliases and gamepad/touch actions remain.

Source tuning reduces Gale / Piston / Tide base movement speeds to21 / 19 / 22 studs per second. An accepted attack scales movement to35% and holds its facing through the action. Light has a0.40-second presentation/action duration and0.44-second cooldown; Heavy lasts0.55seconds, while each special lasts its windup plus0.48seconds. The accepted dash drives58 studs per second for0.16seconds, then spends0.08seconds braking toward walking input. These are configured timings, not measured travel distances or a smoothness claim. Damage, combo acceptance, cooldowns and hit detection remain server-owned. Local anticipation must reconcile accepted events without replaying the same pose; rejected spam must not restart an active accepted animation.

These source changes address the observed repeated pose starts and residual dash motion. Runtime timing, latency, cancellation, mouse tap-versus-drag and human control feel remain separate evidence gates in PROGRESS. Historical tests on the previous timing do not verify this revision.

Preserved presentation paths: earlier builds could load optional `Animations/<Hero>/<Action>` published AnimationId assets and tween shoulders/waist on unsupported rigs. WO-3D.3 retires those parallel paths for the current R6 cast in favor of one sampled joint-pose writer. The imported Toolbox clip data and provenance remain in use.
