# Frozen M3 combat stills: scene and HUD readability

2026-09-24. Independent world review of three direct root Studio captures from production source `dfb2ae3bbb04d1408613e3e28b1f37fcc3f2b6f4`. No camera, world or action overrides were used for these captures. All three supplied images are775x356 pixels. This is a bounded still-image review, not a motion-comfort, combat fairness, device performance or final-quality verdict. No production change is proposed for the active15-trial freeze.

| Actual scene | Evidence | Scope |
|---|---|---|
| City, Normal1102 wave3 | [City combat](evidence/m3-live-city-combat.jpg) | Two enemies remain; player at103 percent. Keyboard captions appear alongside virtual joystick and touch-sized controls. |
| Station, Normal1105 wave3 | [Station combat](evidence/m3-live-station-combat.jpg) | Two enemies remain; player at114 percent. Central DODGE / GRAPPLERGRAB warning overlaps the nearby character area. |
| Factory, Normal1103 wave1 | [Factory combat](evidence/m3-live-factory-combat.jpg) | Two enemies remain; player at197 percent. The originally intended station capture had already progressed to the factory; the image is correctly labeled factory. |

The city has a clear urban identity through storefronts, signals, street lamps and a crossing. The cyan crossing/windows carry the strongest values in the frame, while the small pale player stands against the crossing. The centered CURSES INCOMING toast intersects the immediate character/action area. Percent, stocks and enemy names/bars are legible in this still, but their panels and the six action tiles leave limited open vertical space. Keyboard captions and the simultaneously visible joystick illustrate the source-diagnosed active-input mismatch described in [the proposed M6 input work](M6_INPUT_READABILITY_PLAN.md).

The factory has a distinct warmer identity: rust-colored walls, a bright furnace, elevated rails, machinery and hazard stripes. Its dark floor gives the pale cyan player outline better local separation than the city crossing does. The large dark enemy beside the hero is identifiable by its body and nameplate, while fine clothing and facial detail remain too small to judge. The197-percent health panel and remaining-enemy counter are readable. STYLE+40 sits directly above the player, and the right-side enemy bar shares a crowded region with the large action controls. The joystick and action row still occupy much of the lower viewport. These observations do not establish the timing or readability of every attack warning, hit effect or incoming wave cue.

The station still completes the three-stage image baseline. Its tiled platform, service-suspension signs, clock, maintenance barriers and departure boards establish a transit setting distinct from the city and factory. The114-percent player panel and two-enemies-remaining counter remain legible. The central red-outlined DODGE / GRAPPLERGRAB banner is conspicuous, but overlaps the upper portions of the nearby player/enemy silhouettes; STYLE+40 occupies the same central action area below it. The warning is visible, while parts of the action it describes are obscured. Background service text, top navigation panels and lower touch controls also compete for the short viewport. This is a placement/readability finding from one instant, not evidence that the warning was absent or too short. In particular, the visible0.0s countdown cannot establish total telegraph duration, reaction opportunity, hit timing or successful avoidance. No fairness failure is inferred from the countdown alone.

After the freeze, compare any proposed contrast changes with these unchanged originals. A separate world/presentation pass may reduce competition from decorative crossing/window/furnace values while preserving stage identity and keeping critical tells dominant. Input-mode and short-height HUD changes have their own scoped proposal; they do not authorize camera reframing. Evaluate toast placement against real action and telegraph locations before choosing a change. Do not weaken or hide critical warnings to make screenshots cleaner.

A representative station combat still is now available alongside city and factory. Required follow-up remains motion/attack sequences, all three heroes in action, miniboss/boss warnings, four-player crowd/effect overlap, actual touch/controller reachability and minimum-device frame time. Still-image character size, a visible outline or a readable counter cannot substitute for those checks. Owner art approval and the original reference-quality target remain open.


## City decoration palette checkpoint - source only

Root authorized a bounded WorldBuilder color pass on disk while the installed M3 trial world remains frozen. Reinspection of the unchanged city image above supports reducing the broad crossing and lit-office-window values that compete with the small pale hero. The exact candidate edits are:

| City decoration | Previous RGB | New RGB | Scope |
|---|---|---|---|
| CrosswalkStripe | 222,235,233 | 170,185,184 | Eight existing noncolliding paint strips at X52-94. |
| Lit OfficeGlass | 91,124,153 | 70,96,119 | Existing randomly selected lit panes in the six authored city buildings; unchanged random sequence/count. |

These are modest cool gray/blue color reductions, approximately one fifth per RGB channel, not measured luminance or screen contrast. City-local constants avoid changing the shared palette used by other districts. Unlit glass, signs/text, lamps and all light properties, global lighting, materials, part positions/sizes, transparency, collision/touch/query behavior, world bounds, heroes, VFX and telegraphs are unchanged. No station/factory changes accompany this pass.

**Implemented in branch source; visual improvement unverified.** Root has not rebuilt, synchronized or captured the changed world for this note. Compare a matching normal-camera city view and short combat sequence against the frozen image after the trial baseline finishes, checking hero separation, warning dominance, crossing identity and sign legibility. Do not infer better motion comfort, device performance, fairness or reference-quality parity from darker source RGB values. The bright original is preserved above and remains the baseline.
