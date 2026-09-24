# Asset quarantine and input review — 2026-09-24

Presentation independently inspected source during the frozen M2 five-run comparison (`9f29012`). This is a read-only source/dependency review. No Studio session, live permission request, asset import, gameplay edit or physical input test was performed. Root authorized documenting fixes now and implementing the input corrections after the fixed comparison; the campaign remains frozen until that handoff.

## Asset paths and quarantine

The two production Rojo projects map authored `src` trees and selected shared server modules. Neither maps `vendor`, `tests`, raw Toolbox review folders nor a ServerStorage import container. Source `require` sites resolve local project modules or Roblox's PlayerModule; no numeric asset require, loadstring, runtime asset insertion, GetObjects or HTTP source loader was found. MatchmakingAdapter's GetAsync is a server MemoryStore record read, not executable code fetching. This is inspection of source/project mappings, not a binary-place or hidden Studio-instance inventory.

The original hitbox module remains archived at `vendor/SkyzHitbox.lua` and is not mapped into either production place. Runtime uses reviewed `src/shared/ToolboxHitbox.lua`: a bounded spatial query with exclusions and `MaxParts=128`. This is authored executable adaptation, not a claim that every Toolbox-derived file is non-executable. The client requires the local exported ToolboxAnimations module containing pose data and CFrame constructors.

Toolbox motion remains integrated: source data contains Idle 3 frames, Walk 7, Block 3, Light 24, Light2 25, Heavy 31 and Dash 86. Combat pack 14578890309 and movement pack 109267687059124 are attributed in the module and asset register. Those seven active exported clips do not imply all eleven sequences in the originally reviewed combat pack are used. Main samples local pose data, including fallback attacks and block; no current AnimationId upload is required for that path. Main retains an optional local Animation-instance path; any future populated animation folder must receive another provenance/permission review.

`AssetInstaller.lua:1-52` reconstructs particles from the reviewed pack with zero emit rates, disabled continuous emission and a noncolliding/nonqueryable holder. It does not import the rejected pack scripts. `Main.client.lua:505-529` additionally strips LuaSourceContainer descendants before parenting a cloned effect, limits concurrent imported effects to 24 and gives them a three-second lifetime. This does not certify an arbitrary future pack: the reviewed fixed reconstruction remains the trusted source.

`ArtAssetsInstaller.lua` references four generated pump mesh/texture pairs and four station material maps; every ID matches ASSET_REGISTER. The generated model's aggregate ID is provenance only; code reconstructs static visual pieces, not imported executable descendants. Hero art currently uses native parts and the separate original-art approval gate remains open.

### Active audio and particle dependency map

| Runtime reference | Asset ID | Source/register result |
|---|---:|---|
| Hit impact | 132504023010884 | Main client / Punch Impact 1, registered |
| Attack/dash whoosh | 135315310485417 | Main client / Sword swing whoosh, registered |
| City ambience | 9112759731 | StageAudio / City Night Ambience 3, registered |
| Station ambience | 9112772977 | StageAudio / Dock Ambience 3, registered |
| Factory ambience | 9112890492 | StageAudio / Ups Sorting Facility 2, registered |
| Combat score | 1844978927 | StageAudio / Battle Action, registered |
| ImpactCross texture | 16004095914 | AssetInstaller; child of reviewed pack 92765511929343 |
| ImpactSparks texture | 13644087339 | AssetInstaller; child of reviewed pack 92765511929343 |
| ImpactRing texture | 7216847656 | AssetInstaller; child of reviewed pack 92765511929343 |

All six runtime sound IDs explicitly matched the existing register. The three child particle IDs were absent as individual entries, although their parent pack and reconstruction were recorded. World added the authorized explicit texture table on 2026-09-24; presentation read and confirmed all three IDs and the unchanged permission gate. The original rejected-script history is retained. No new assets are being imported. Published-universe loading for a non-owner account, ownership/permission state, actual audible mix and physical-device performance remain unverified by this audit.

StageAudio uses four persistent local Sound channels, an envelope Heartbeat connection only while weights change, and pause/resume for inactive channels. Its Destroy method disconnects the ticker and stops/destroys the folder, but Main treats it as a session-lifetime object. One-shot combat sounds use short Debris cleanup. Source lifecycle shape is bounded for one normal client initialization; GUI/script recreation and repeated initialization are not certified here.

## Input findings and exact follow-up plan

### INPUT-01: Block release is suppressed by text focus (P2, open)

`Main.client.lua:373-377` returns from send before processing a Block release whenever a TextBox has focus. The ContextAction handler at `:406-409` also returns before End/Cancel under text focus. Holding block, focusing chat and releasing the key can therefore leave the server guarding until a later release/action clears it. WindowFocusReleased directly sends a release, but text-box focus is a different path.

After the freeze: centralize a releaseBlock helper that clears localBlocking and sends only the release intent. Route Block End/Cancel before all focus/menu gates. TextBoxFocused, window focus loss and modal opening should use the same cleanup. Tests should assert exactly one effective release path and no new attack on End/Cancel, covering keyboard/controller and synthetic touch sequence fixtures. A real chat/gamepad/touch session remains separately required.

### INPUT-02: Modal transitions and focus loss leave input state behind (P2, open)

CombatHUD's settings-open handler at `:281-291` sends server Block false but does not reset Main's localBlocking. Main's Jump guard at `:380` checks that local flag, so a previous block can inhibit the next jump after closing settings until another action resets it. Journal opening also sets MenuOpen without a unified Main input-state reset. Main does suppress movement while modal/text focus is active, but held state can resume when it closes.

`Main.client.lua:440-443` resets keyboard/gamepad/touch vectors on window focus loss but leaves touchInput and its knob position intact. That touch object is declared below the current handler. `CombatHUD.lua:308-313` clears sliderDrag only on InputEnded or settings close, not window focus loss; resumed pointer motion can continue a stale drag.

After the freeze: move touch ownership into a scope visible to a single clearHeldInput helper; clear held keys, gamepad vector, touch vector, touchInput and knob position; call it on focus loss, text entry, MenuOpen/SettingsOpen opening and character replacement. Ensure server guard release accompanies local cleanup. Clear sliderDrag on focus loss and modal close. Preserve the established camera and movement math. Fixture cases: hold then open/close menu, hold then focus text, touch drag then lose focus, settings slider then lose focus, and character replacement while holding. Verify controls work again after each reset and no movement resumes without fresh input.

### INPUT-03: Return shortcut ignores modal menus (P2, open)

`CampaignTravel.client.lua:32-45` checks server availability/busy/visibility in its shared button callback. Its shortcut additionally checks text focus, but the button callback does not; neither path checks MenuOpen/SettingsOpen. Its T/Y binding has priority 3200, above settings bindings; pressing Y while a results menu is open can request the whole party's return. This is an unintended UX transition, not a server authority bypass: the server still requires the terminal-state leader.

After the freeze: add a shared modal/text-focus guard to both button activation and shortcut handler. Keep server canReturn and busy checks and return only the existing intent. Test T/Y/touch activation while each modal is open produces zero requests, closing the modal restores access, and hiding/disabling the button clears selected focus.

## Existing source controls retained

- Main handles Block End and Cancel outside text focus, clears basic movement vectors on window focus loss and suppresses movement during text/modal/results states. Fix the gaps rather than replacing the camera/controller.
- CombatHUD stock share uses R/R3, server snapshot availability and text/menu guards. Proposed M3 V/L3 revive remains a separate unimplemented action, with release/cancellation requirements in M3_UI_CONTRACT.
- CampaignTravel uses safe insets, a 44-pixel control, local cooldown and server state; terminal return intentionally overrides ordinary Heavy's Y shortcut only when available.
- Hub Deploy uses M/Select, skips text entry, provides gamepad selection fallback and clears selection when closing or rebuilding controls. It is a separate place, so its Select binding does not compete with campaign settings. Queue/selection security remains server-owned.
- Settings/journal maintain their own close/focus paths. Static ContextAction bindings live for the normal client session; most modules have no comprehensive Destroy/unbind lifecycle. Repeated Init or hot-reload is not a supported verified scenario.

## Evidence required before closing

Root should run the deterministic focus/modal fixtures after implementation and rerun the camera regression plus affected UI bounds/input fixtures. Capture readable UI evidence when Studio rendering permits. Physical keyboard/chat, controller and touch checks remain owner/device gates; synthesized callback tests do not close them. Published asset/audio permissions require the configured test universe and a non-owner account, which this overnight review does not access. M2 five-bot source must stay unchanged until root releases it.


## M6 focus correction implementation checkpoint

After root released the M2 comparison freeze, presentation implemented INPUT-01/02/03 in the owned client files. New FocusGuard connects window/text/modal/character interruptions to held-input reset, handles Block End/Cancel before focus gates, and supplies the common return eligibility predicate. Main clears local guarding, keyboard/gamepad/touch vectors, touch ownership and knob position; death/downed/character transitions also reset state. CombatHUD clears slider drag on focus interruptions. CampaignTravel uses the same text/menu guard for both button and shortcut. Camera smoothing, framing and movement math were not changed.

`tests/FocusGuard.spec.lua` exercises event-order policy with deterministic signals; `tests/FocusGuardClient.spec.lua` exercises actual local TextBox focus and player-attribute signals. Presentation ran source diff/whitespace checks only; root's Studio results and independent source review are pending at this writing. These fixtures cannot certify physical controller/touch handling. The original frozen five-bot reports remain tied to their prior source revision.


### Recorded M6 source review and actual Studio results

Combat independently reviewed FocusGuard/Main/CombatHUD/CampaignTravel and the fixtures: source PASS. Root ran the deterministic FocusGuard spec in Studio: PASS for text-focus release, End/Cancel, modal/window/life cleanup, connection disposal and return gating, with eight release callbacks. Root also ran the isolated actual-client TextBox plus MenuOpen/SettingsOpen signal fixture: PASS with three release callbacks. Both results explicitly report physicalInputVerified=false. These exercise helper policy and real local focus/attribute signals; they do not certify physical controller/touch sequences or a new visible camera regression. The patch changes no camera calculations. Root owns the saved runtime artifacts and commit evidence in PROGRESS.
