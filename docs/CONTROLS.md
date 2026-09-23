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
| Select Naruto / Luffy / Tanjiro | 1 / 2 / 3 | D-pad left / right cycles | Hero name |
| Restart after end screen | R | Start | Play Again |

The first grounded jump uses Roblox Humanoid jumping. A second airborne press requests server-authorized Recovery. This is the prototype's shared double-jump/recovery resource, not an extra unlimited jump. High damage percentage means larger launches. Stocks are lives; guard and recover before your squad runs out. Hero selection availability and cooldowns are enforced by the server.

## Camera and accessibility

- Scripted side-view camera follows the party with smooth movement and stage bounds. Camera fitting samples party positions at 10 Hz; effects and movement update per frame.
- Health is represented by readable damage percentage and discrete stock marks. Cooldown buttons show numeric time remaining.
- Buttons support mouse activation in addition to keyboard, gamepad, and touch inputs. Input resets when the app loses focus.
- The custom controller replaces Roblox default controls so keyboard, thumbstick, and touch directions stay aligned with the authored lane.
- Large launch events use a brief camera kick. A reduced-motion settings toggle remains a quality milestone; it is not implemented yet.

## Imported asset contract

The client actually samples imported Toolbox R6 pose data from `Nightfall.Shared.ToolboxAnimations`: Combat Animations **14578890309** by PixellDaZuera and Dash **109267687059124** by z0efx63. Light/alternate light/heavy/guard/dash plus idle/walk are interpolated from their original keyframes. Special uses the imported heavy clip until distinct hero specials are authored. Teammates and enemies are sampled on each client; server combat timing remains authoritative.

The installed Hit VFX template is cloned for impacts. Enemy attacks show red ground footprints during windup; boss overload has a distinct banner and burst. Toolbox audio references are Punch Impact1 **132504023010884**, whoosh **135315310485417**, and City Night Ambience3 **9112759731**. Impacts are deduplicated and limited to eight concurrent transient sounds. Audio still depends on Roblox asset availability/permissions in the published experience.

Audited imported templates live in `ReplicatedStorage.Nightfall.Assets`:

- `Animations/<Hero>/<Action>` (an `Animation` with an authorized published `AnimationId`). Flat `<Hero>_<Action>` or `<Action>` names also work. Current actions: Light, Heavy, Special, Block. These use action animation priority.
- `VFX/<Hero>/<Event>` (Model, BasePart, Attachment, or ParticleEmitter). Flat hero-prefixed or event names also work. Events: Hit, KO, Attack, Special, Dash, Recovery. The client places the clone at the replicated event location, emits particles, and cleans up after three seconds. ParticleEmitters may carry numeric `BurstCount` or `EmitCount` attributes, clamped to 1–60.
- The client removes script descendants from VFX clones as an additional precaution. This is not a substitute for inspecting imported assets in Studio before they enter the project.

When no compatible effect exists, bounded neon impact particles make attacks visible. Non-R6 rigs use temporary shoulder/waist pose fallbacks. The imported clips and authored effects are **prototype presentation**, not an assertion of production animation quality. Rig compatibility, timing, readability, audio permission, and multiplayer visibility need Studio playtesting. Distinct cinematic special animations and a fully mixed soundtrack remain unfinished.

## Required hands-on QA

The source implementation should not be labeled on par with Jujutsu Shenanigans until these are observed in a running Roblox client:

1. Solo and 2–4 player Studio sessions: every hit confirms once, party framing remains readable, and stocks/restarts agree for all clients.
2. Keyboard, Xbox-style controller, and phone landscape: movement, guard release, hero selection, ability labels, and restart remain usable with safe-area insets.
3. Every hero has distinct permission-cleared animation and VFX sets, readable windup/contact/recovery, and convincing audio.
4. Low-end mobile stress test: effect bursts remain below budget during four concurrent specials. Verify frame time with MicroProfiler.
5. Review camera kick, touch thumb-pad placement, UI text size, and color-independent combat readability with players.

Current limitations: no rebinding/settings menu, no reduced-motion switch, no dedicated portrait-phone layout, no per-player offscreen indicator, and no split-screen camera. HUD scales for landscape; a real device pass remains necessary. Camera party fit has a finite zoom limit and does not guarantee framing a squad intentionally spread across an entire district.
