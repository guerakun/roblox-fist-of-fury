# M6 input mode and short-landscape readability proposal

Status: **NOT IMPLEMENTED. Production is frozen for the 15 fresh M3 tier runs.** Prepared 2026-09-24 by presentation from an actual city combat still and read-only source review. This proposal does not authorize camera changes or imply physical-device validation.

## Observed evidence

[Actual Normal1102 city wave-three combat capture](evidence/m3-live-city-combat.jpg), supplied by root during the frozen run, shows keyboard captions J/K/L/Q/HOLD F/E alongside a large virtual joystick, standalone Jump button and six large touch action tiles. The percent/stock counter and enemy labels remain readable, but the lower controls and top title/settings/progress/encounter panels consume substantial space in the short landscape viewport. The small player silhouette crosses the brightest cyan road area. A center-screen incoming-wave toast overlaps the action; bright windows and crossing stripes compete with characters for attention.

This is one city-wave still. It cannot establish motion comfort, all-stage quality, four-player readability or physical phone/controller behavior. The exact screenshot dimensions and run metadata belong to root's evidence; the layout matrix below deliberately includes a 749x361 short-landscape test case. The screenshot is preserved unchanged.

## Source diagnosis at art checkpoint dfb2ae3

- [Main input labels](../../src/client/Main.client.lua#L229) use recent input, with a touch-capability/no-keyboard fallback. The `LastInputTypeChanged` listener updates labels only.
- [Main responsive layout](../../src/client/Main.client.lua#L250), especially line256, uses raw `TouchEnabled` to select the touch layout and show the pad/Jump control. Thus a touch-capable host can retain large controls while showing keyboard captions.
- [CombatHUD layout](../../src/client/CombatHUD.lua#L423), especially line426, also uses raw touch capability. Its last-input listener calls resize but does not change that underlying rule.
- [Desperation touch mode](../../src/client/Main.client.lua#L431) uses `TouchEnabled` unless the latest input is gamepad. A keyboard user on a touch-capable host can therefore receive the touch hold control instead of the keyboard chord hint.
- In the existing Main label expression, a paired controller on a phone with `KeyboardEnabled=false` can lose caption priority to the touch fallback even though controller input is active. CombatHUD already has another recent-input helper, increasing the chance of divergent rules.

Line numbers identify this reviewed source revision and may shift later. Device capability means an input is available; it does not identify which input mode the player is currently using.

## Bounded proposed change

Presentation owns a shared local input-mode helper and its use in Main, CombatHUD, rescue controls and Desperation HUD. No server eligibility, combat timing, hitbox, reward, camera transform, camera smoothing or camera framing changes belong to this work order.

Use one active mode: keyboard/mouse, controller or touch. Explicit meaningful input selects it; capability flags provide initial/fallback behavior only. Active controller input takes priority over a no-keyboard touch fallback. Mouse-movement noise and controller-stick drift must not repeatedly switch the layout. A proposed controller threshold should reuse the current movement deadzone rather than add an untested competing rule.

A current touch pointer owns its gesture until End/Cancel. Defer a layout transition while that pointer owns movement, guard, revive or desperation, then cancel/reset stale held state safely before changing mode. Never synthesize a press or turn a held normal action into a paid action. If an explicit user input requires a forced transition, release the previous ownership first. Focus/modal/life cleanup must continue to release held guard/revive and clear movement. Controller disconnect falls back to an available device without trapping focus; returning to controller restores a visible, selectable focus target.

Update layout and captions together. Keyboard/controller mode hides the virtual joystick and standalone touch Jump button, retaining the existing action/cooldown row and normal keyboard/controller bindings. The first meaningful Touch restores touch affordances immediately; touch controls and contextual revive/stock-share controls retain at least44px targets and the established rescue-footer spacing. Desperation chooses its keyboard/controller chord or deliberate touch hold from the same mode, preserving the explicit cost label and one-action-per-gesture contract.

Add an explicit short-height layout rule instead of depending on viewport width alone. Keep percent/stocks, enemy count, critical warnings and action feedback legible; avoid overlapping these with contextual rescue/return rows. A smaller keyboard/controller layout must not shrink the subsequently restored touch controls below44px. Do not use an input-mode fix to move the camera or alter world scale.

## Proposed verification and acceptance

1. Pure mode-policy cases: keyboard on touch-capable host; mouse-button activation; meaningful Touch; controller with no keyboard; controller drift; mouse-move noise; touch ownership deferral; End/Cancel; controller departure; focus/modal/life resets; reenabling a mode without synthesizing an action.
2. Actual client widget fixtures with the same representative server snapshots at749x361,320x320,360x640 and1280x720. Exercise normal combat, available desperation, revive/share footer, district results and return strip. Assert captions agree with mode, hidden controls do not capture input, visible HUD groups do not intersect, touch targets remain at least44px, and controller focus never remains on a hidden control.
3. Hybrid transitions keyboard-to-touch-to-keyboard and controller-to-touch-to-controller must restore both geometry and captions, with no cumulative offsets or stuck holds. Re-run existing FocusGuard, ReviveControl/HUD, DesperationControl/HUD and capability-widget fixtures as appropriate to changed paths.
4. Root captures matching before/after short-landscape combat views and performs actual client dispatch checks where tools permit. Test fixtures and desktop captures do not substitute for physical phone/gamepad input; retain that owner gate explicitly.
5. A different agent reviews authority, fairness, paid-action gesture safety, touch reachability and evidence scope before root commits. Root alone runs Studio, builds and pushes.

No tests listed here have been run for this proposal; no production fix is implemented. Frozen HumanBot action policy and source remain unchanged.

## Separate visual follow-up, not part of mode logic

Coordinate with world on a separate bounded scene-contrast review: crossing/window brightness should support rather than obscure character and tell readability. Assess the incoming-wave toast against actual action and telegraph locations; a still cannot prove the best placement or timing. Preserve critical warning visibility and compare representative city, station and factory combat, including multiple players. These changes require their own captures/review and must not be bundled into the input helper or camera work.

## Preserved scope and next step

The original touch-first layout, rescued-footer offset, cost-labeled desperation hold and controller captions remain valuable. This proposal reconciles their activation rules instead of discarding those controls. After root releases the tier-run freeze, implement this bounded M6 work order, run its scoped checks, record actual outcomes and unresolved physical-device gates, and commit separately from combat tuning.
