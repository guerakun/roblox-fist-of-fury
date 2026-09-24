# Player controls and presentation

The game uses controlled side-view stages. Walk along X and use a small amount of foreground/background depth along Z. Clear each wave to move right into the next district. The server owns damage, hit detection, cooldowns, knockback, stocks, and encounter progression.

| Action | Keyboard | Gamepad | Touch |
| --- | --- | --- | --- |
| Move / lane depth | A D / W S | Left stick | Left thumb pad |
| Jump / air recovery | Space | A | Jump |
| Light attack | J | X | Light |
| Heavy attack | K | Y | Heavy |
| Hero special | L | B | Special |
| Dash | Q | Left trigger | Dash |
| Hold guard | F | Left bumper | Hold Block |
| Air recovery | E | Right bumper | Recovery |
| Select Rook Calder / Bo Marlowe / Isla Veyra (candidate names) | 1 / 2 / 3 | D-pad left / right cycles | Hero name |
| Ready in the lobby | Enter | Start | Ready |
| Restart after end screen | R | Start | Play Again |

The first grounded jump uses Roblox Humanoid jumping. A second airborne press requests server-authorized Recovery. This is the prototype's shared double-jump/recovery resource, not an extra unlimited jump. High damage percentage means larger launches. Stocks are lives; guard and recover before your squad runs out. Hero selection availability and cooldowns are enforced by the server.

## Camera and accessibility

- Scripted side-view camera follows the party with smooth movement and stage bounds. Party discovery runs at 10 Hz; camera target and eye sample and follow living party positions together every render frame. Movement runs separately after input. See CAMERA_REGRESSION.md.
- Health is represented by readable damage percentage and discrete stock marks. Cooldown buttons show numeric time remaining.
- Buttons support mouse activation in addition to keyboard, gamepad, and touch inputs. Input resets when the app loses focus.
- The custom controller replaces Roblox default controls so keyboard, thumbstick, and touch directions stay aligned with the authored lane.
- Settings (O / gamepad Back) provide camera shake, effect density, master volume, stage ambience, combat music, and high-contrast warnings. Setting shake to 0 disables camera kick. Critical telegraphs remain visible even at 0 effect density. Settings last for the current play session.

## Imported asset contract

The client actually samples imported Toolbox R6 pose data from `Nightfall.Shared.ToolboxAnimations`: Combat Animations **14578890309** by PixellDaZuera and Dash **109267687059124** by z0efx63. Light/alternate light/heavy/guard/dash plus idle/walk are interpolated from their original keyframes. Bespoke original hero special poses are scheduled in WO-1.3; the historical baseline reused Heavy. Teammates and enemies are sampled on each client; server combat timing remains authoritative.

The installed Hit VFX template is cloned for impacts. Enemy attacks show red ground footprints during windup; boss overload has a distinct banner and burst. Toolbox audio references are Punch Impact1 **132504023010884**, whoosh **135315310485417**, and City Night Ambience3 **9112759731**. Impacts are deduplicated and limited to eight concurrent transient sounds. Audio still depends on Roblox asset availability/permissions in the published experience.

Audited imported templates live in `ReplicatedStorage.Nightfall.Assets`:

- `Animations/<Hero>/<Action>` (an `Animation` with an authorized published `AnimationId`). Flat `<Hero>_<Action>` or `<Action>` names also work. Current actions: Light, Heavy, Special, Block. These use action animation priority.
- `VFX/<Hero>/<Event>` (Model, BasePart, Attachment, or ParticleEmitter). Flat hero-prefixed or event names also work. Events: Hit, KO, Attack, Special, Dash, Recovery. The client places the clone at the replicated event location, emits particles, and cleans up after three seconds. ParticleEmitters may carry numeric `BurstCount` or `EmitCount` attributes, clamped to 1–60.
- The client removes script descendants from VFX clones as an additional precaution. This is not a substitute for inspecting imported assets in Studio before they enter the project.

When no compatible effect exists, bounded neon impact particles make attacks visible. Non-R6 rigs use temporary shoulder/waist pose fallbacks. The imported clips and authored effects are **prototype presentation**, not an assertion of production animation quality. Rig compatibility, timing, readability, audio permission, and multiplayer visibility need Studio playtesting. Distinct cinematic special animations and a fully mixed soundtrack remain unfinished.

## Required hands-on QA

The source implementation should not be labeled on par with the requested Roblox combat-quality benchmark until these are observed in a running Roblox client:

1. Solo and 2–4 player Studio sessions: every hit confirms once, party framing remains readable, and stocks/restarts agree for all clients.
2. Keyboard, Xbox-style controller, and phone landscape: movement, guard release, hero selection, ability labels, and restart remain usable with safe-area insets.
3. Every hero has distinct permission-cleared animation and VFX sets, readable windup/contact/recovery, and convincing audio.
4. Low-end mobile stress test: effect bursts remain below budget during four concurrent specials. Verify frame time with MicroProfiler.
5. Review camera kick, touch thumb-pad placement, UI text size, and color-independent combat readability with players.

Current limitations: no input rebinding, no dedicated portrait-phone layout, no cross-session settings persistence, and no split-screen camera. HUD and touch controls adapt for landscape; a real-device pass remains necessary. Camera party fit has a finite zoom limit. Offscreen teammates get stock/percentage markers and offscreen attacks get directional warnings, but a deliberately scattered squad is not guaranteed to fit in one camera view.

## Hero special presentation

WO-1.3 replaces the retired special visuals with the following original languages. See PROGRESS.md for implementation and runtime evidence; these are not acceptance claims:

- **Gale / Cyclone Drive:** corkscrew kick and forearm wind ribbons.
- **Piston / Recoil Cannon:** mechanical gauntlet, piston/chain extension and recoil steam.
- **Tide / Undertow Arc:** rotating glaive sweep and broad water crescent.

These are authored procedural visual effects layered onto imported Toolbox combat animation/audio. They are not additional imported Toolbox assets. Bespoke skeletal poses and VFX coverage must be checked against each server-defined windup, range and width.

The effect scheduler caps concurrent hero specials at eight, uses one temporary render connection, and removes all parts in approximately one second. Parts are anchored, non-colliding, and non-queryable. Release sound and camera kick happen after windup. The visuals do not create hitboxes, move characters, apply damage, or freeze simulation; authoritative server attacks remain unchanged. Visual travel is stylized and is not a simulated projectile collision test.
## Three-chapter encounter HUD

The HUD reads stage names directly from the server: city streets, abandoned station, and abandoned factory. Four waves per stage comprise skirmish, miniboss, skirmish, and boss. A chapter title introduces each district and is dismissed as soon as a critical attack warning arrives. The top-center boss meter shows the active miniboss/boss name, phase, and remaining break threshold; the delayed pale segment helps damage read clearly.

Server telegraphs specify exact locked box or circle footprints. Red/orange warnings say **DODGE** and jumpable cyan warnings say **JUMP**. Ground labels, a textual local-danger banner, and offscreen directional markers remain enabled with cosmetic effects disabled. The local warning uses X/Z footprint membership and does not claim that being airborne is safe. It is instructional presentation, not hit detection. Enemy impacts briefly flash the same footprint.

Run results show server-reported defeats, damage dealt, damage taken, and elapsed time. Missing values show a dash. Currency/progression comes from the separate progression menu; the combat HUD does not invent rewards.

## Input and accessibility updates

- **O / gamepad Back:** open settings. **B** closes settings while it is open. Gamepad focus navigates between rows; minus/plus buttons adjust sliders by 25%, and mouse/touch can drag slider tracks.
- Settings have a scrolling content area on short screens so controls retain useful size. The co-op simulation keeps running while menus are open; the menu says this explicitly.
- The gameplay client suppresses movement/actions while `MenuOpen` (progression) or `SettingsOpen` is true and releases guard when settings open.
- Touch actions use a two-row, three-column cluster, with a separate jump button above. Action hints adapt to the latest keyboard/controller/touch input.
- Positive damage can hold only the sampled cosmetic attack/victim pose for 45–60 ms and briefly highlight the victim. This never freezes the Humanoid, physics, server damage, cooldowns, or other players. Cosmetic flash intensity is suppressed when effects are off.

## Integration contracts

`CombatHUD.lua` consumes the main combat snapshot, including optional `boss={name,kind,percent,threshold,phase,role}`, `encounterKind`, `nextWaveAt`, `checkpointLabel`, and `runStats={kills,damageDealt,damageTaken,duration}`. `boss=false` hides its meter. Telegraph/EnemyImpact fields are `position`, `shape`, `size`, `radius`, `duration`, `mechanic`, `color`, and `jumpable`; legacy directional range packets remain supported. Exact hit feedback uses `targetModel` or `targetUserId` from the server, while `playerUserId` still identifies the attacker.

Main initializes the separate root-owned `ProgressionUI` module once when available. `NightfallHUD.Canvas` is named for integration. Settings and progression share a top-center utility row and independent player attributes so they do not clear each other's modal state. No client code awards currency or changes saved progression.
## Ready lobby and controlled traversal

The initial lobby has no forced countdown. Choose a hero, review the movement/combat lesson, inspect progression/settings if needed, then press **Ready / Enter / gamepad Start**. The HUD shows how many connected players are ready. Solo starts when its one player readies; co-op starts once everyone is ready. Before the final ready, a player can cancel their ready state. The four-second chapter introduction begins only after the server starts the campaign.

Between encounters, the server may enter `Traverse`. A cyan world marker and objective banner show where the living squad must rally and the current count at the destination. The next wave does not spawn until the squad reaches it. The same guidance marks the district exit during `Advance`. A faint red curtain and amber floor line display the currently unlocked forward limit during combat; these guides are non-colliding, and the server owns the actual movement bounds.

Boss HUD now shows armor/exposure status and a separate poise strip. **EXPOSED — PUNISH NOW** marks a recovery opening. A server `BossStagger` cancels that enemy's outstanding floor and UI warnings, so a successfully interrupted attack is no longer presented as imminent. Guard direction updates when the player changes horizontal facing while holding guard. Downed teammates no longer force the active squad's camera to remain near a checkpoint; a downed local player frames surviving teammates.

Additional optional state fields: `ready`, `readyCount`, `playersTotal`, `targetX`, `objective`, and `walkingMaxX`. Ready input is `Action("Ready", {ready=true/false})`. The journal uses **P / left-stick click**; settings uses **O / gamepad Back**.
## Elite impact identity and stage sound

`BossEffects.lua` responds only to server `EnemyImpact` packets, after damage resolves. Executioner cleaves leave amber shards; Siren Marshal impacts use red/blue beams and pulse fragments; Platform Widow leaves rail ribbons and spectral tickets; Last Conductor produces a short train afterimage or departure-clock flash; Furnace Hound leaves cinder claws and scorching fragments; Kiln Sovereign releases furnace columns and steam.

These are original cosmetic additions. They do not replace the imported Toolbox animation/hit VFX pipeline and do not create damage. Each uses the locked packet position/size/radius. The train crosses its lane in 0.26 seconds after the instantaneous full-footprint impact flash; it is not a traveling hitbox or an extra dodge opportunity. The module caps six concurrent effects and 24 BaseParts per effect, uses one temporary render ticker, and cleans all effects in under one second. Zero effect density suppresses these ornaments while the critical telegraphs remain.

`StageAudio.lua` switches looping ambience by chapter with 1.1-second envelopes: city **9112759731**, abandoned station **9112772977**, factory **9112890492**. A quiet combat score **1844978927** fades in/out over 0.7 seconds around Combat state. Master volume affects all audio; stage ambience and combat music have separate settings, and either can be muted independently. Silent channels pause, and the envelope ticker disconnects when levels settle. Permission failure does not create a per-frame play/retry loop.

The supplied IDs were verified as loadable in the root's Studio edit session. The live published universe's audio permissions and final four-player mix still require verification. No anime soundtrack was added.
## Phone safe area

Main and presentation GUIs use CoreUISafeInsets, which includes device cutouts and the Roblox top bar. Layout reads the resulting canvas size. Touch capability changes refresh the thumb pad and jump visibility. Phone combat uses compact headers and a 70-pixel health plate, a narrow boss/warning stack, and six action buttons with at least 48-pixel height. The full hero selector remains in the ready lobby; in-run hero quick-switch buttons hide on short landscape screens. Initial wave-zero intermission says ENTER THE CURTAIN / GET READY. Overlapping hazard text prioritizes the soonest impact. Physical-phone play and four-player overlap still require final validation.

## Voluntary co-op stock sharing

When a living player has at least two stocks and a connected ally is downed, a contextual GIVE 1 STOCK prompt identifies the ally. Press R, click the right stick (R3), or tap that prompt. The server selects/validates the target, transfers exactly one stock, preserves the donor's damage, and revives the ally with one stock, zero damage, and two seconds of protection. There is a ten-second donor cooldown. This uses no coins or purchases. The prompt disappears when unavailable and never becomes a persistent seventh combat button. R still retries on the results screen. Journal/settings suppress rescue input. This interaction requires multiplayer runtime validation.
