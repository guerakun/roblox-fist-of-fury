# Camera motion regression

## Diagnosed defect

The former camera recomputed its look target in the 0.1-second actor-discovery block. The camera eye interpolated each render, but `lookAt` used the unsmoothed stepped target. A walking player therefore caused repeated yaw snaps followed by easing, even with camera shake disabled. This was a view-direction defect rather than animation bobbing.

## Correction

`Main.client.lua` has one Camera+1 render owner. It samples living-party positions every render, exponentially smooths center and distance with `1-exp(-6*dt)`, and offsets the eye from that same center at a constant angle. Eye and focus receive the same optional impact-shake translation. Facing, walking, jumping, and depth motion cannot rotate the camera. Actor discovery and HUD timers remain 10 Hz. Input runs separately at Input+1 and never writes camera state or character transforms.

Outward walking input is suppressed within 0.4 studs of the authoritative forward walking limit, district minimum +4, and lane Z +/-14. Inward input remains available. This avoids continued Humanoid input into server correction boundaries. The client does not cancel velocity, clamp root transforms, or replace server enforcement; knockback and recovery physics remain server-owned.

## Deterministic numeric evidence

PowerShell simulated four seconds of 20-stud/second walking with a 52-stud camera offset, comparing the former 10 Hz target/eye-only interpolation against the new shared-center interpolation. Measurements exclude the first second of startup.

| Frames/s | Old peak-to-peak yaw | Old largest frame yaw step | New yaw variation | New steady follow lag |
| --- | --- | --- | --- | --- |
| 30 | 1.97 degrees | 1.97 degrees | 0 degrees | 3.01 studs |
| 60 | 2.09 degrees | 2.08 degrees | 0 degrees | 3.17 studs |
| 144 | 2.09 degrees | 2.09 degrees | 0 degrees | 3.26 studs |

A stationary target step from X60 to X120 evaluated after exactly one second produced X119.8512748694 at 30, 60, and 144 frames/s, matching `120-60*exp(-6)` within floating-point rounding. Moving-input sampling naturally differs slightly with frame rate; no orientation oscillation remains. A source search found exactly one camera CFrame assignment and one NightfallPresentation binding.

## Actual Studio runtime evidence

The root agent recorded the following in Studio after syncing the corrected client. These are observed runtime measurements, separate from the numerical simulation above.

- Before the fix: 76 forward-walk frames showed 2.4461789 degrees peak-to-peak yaw and a 1.695949-degree maximum single-frame yaw step.
- After the fix: 301 frames showed zero yaw range and zero maximum yaw step. Holding D for four seconds moved the character from X40 to X132.33757.
- An eight-second edge/depth/jump run recorded 481 frames with a zero LookVector.X range. A forward limit of X170 briefly overshot to X171.014, then settled; while outward movement remained held from 2.1 to 2.7 seconds, the measured X range was zero.
- The same run reached lane Z13.89579 and jump Y13.3619. Subsequent inward movement ended at X151.3738, Z2.3899, confirming that inward movement and jumping still operated.

The brief 1.014-stud boundary overshoot is retained honestly: the filter prevents continued outward walking input, but does not erase existing velocity or replace authoritative correction. The observed settled edge hold was stable; this is not a claim that every network condition will produce zero positional correction.

## Final source review and remaining validation

Read-only review confirmed one camera CFrame writer, one Camera+1 binding, separate Input+1 movement resolution, and frame-dependent smoothing replaced by exponential smoothing. Fixed-angle eye/focus construction prevents facing, depth walking, jumps, party zoom, and target changes from producing camera yaw. No new root CFrame or AssemblyLinearVelocity assignments were added. Each boundary filter checks the sign of input, so inward steering remains available even when outside a bound. Outward air steering near a bound is also filtered, but launch velocity and recovery impulses are not canceled.

`characterReady` clears the camera center, so initial spawn and character replacement snap to the currently computed party framing on the next render. This avoids a long pan from the prior life, but the visual comfort of a distant respawn or mid-run hero replacement has not been measured. The camera's existing stage X clamp and party fit remain unchanged. Normal stage target changes ease the center without yaw; a major teleport can still cause rapid translation. A new forward-limit snapshot releases the outward walking filter immediately, subject to snapshot arrival latency.

Remaining runtime coverage: two-to-four-player separation and reunion; downed spectating and stock-share revival; distant checkpoint respawn; chapter-transition translation; the left district boundary; phone/touch and physical gamepad movement; phone safe-area/aspect changes; actual low/high-frame-rate Studio runs; and latency-induced correction. Camera shake is still an optional impact translation controlled by settings and should be assessed separately for motion-sensitive players. The measured solo desktop tests establish the walking-yaw fix and one settled boundary case; they do not establish universal subjective comfort or complete co-op/mobile validation.

## Frozen M3 observation, 2026-09-24

Presentation independently compared the camera solve and Input+1 movement block with tested M2 source9f29012: both are unchanged, with one Camera+1 production camera writer, common translated eye/focus,44-degree FOV and exponential smoothing. New risk/boon/art code adds no camera writer or shake impulse. Per-frame UI/render work can still affect frame pacing; source identity alone does not establish comfort.

Root installed the passive `tests/CameraMotionAudit.client.lua` before final M3 Normal1102. Actual startup smoke collected1114 valid camera frames,1115 dt samples and167 hero-bound samples at749x361; histogram/angular arithmetic self-checks passed. [Scope and evidence](launch/evidence/m3-camera-audit-smoke.json). Normal1101 has no motion observer; it retains the separate100-hit frustum audit. Later trials include this observer's unmeasured overhead and unchanged bot actions.

The bounded observer reports dt histogram upper-bound quantiles, look/up angle changes, focus displacement projected through the current camera, axial zoom and six core-part bounds. It separates quiet samples from recent potential impact/lifecycle changes and annotates the largest steps. It never writes camera/settings/input. These are desktop diagnostics, not nausea or physical-device certification. Full trial measurements remain pending at this entry.

Remaining checks include character-replacement framing snaps, stage/downed target changes, the170-stud party cutoff, group reunion and portrait zoom, crowded effects, and human comfort. The current shake0 hint overstates its effect as turning off camera movement; it only disables impact shake. Correct that wording after the frozen campaign series, without changing camera math. [Actual live city frame](launch/evidence/m3-live-city-combat.jpg) documents one short-landscape view, not motion/crowd/device acceptance.

The first full observer export, [Normal1102](launch/evidence/m3-final-normal-1102.json), spans631.48s including8243 post-defeat frames; its pooled frame-time values are not combat-only. It contains37798 valid camera frames and5708 hero-bound samples. Two samples put the root/core outside the viewport; those hero events have no transition annotations, so their cause is unresolved. The largest recorded focus steps are transition-tagged. Preserve these observations when comparing future trials; they do not close the camera/comfort gate. World independently reconciled this scope and the input-readability proposal. See [the deferred M6 implementation plan](launch/M6_INPUT_READABILITY_PLAN.md).
