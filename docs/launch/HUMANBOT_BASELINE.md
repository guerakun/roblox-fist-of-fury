# HumanBot baseline and measurement contract

2026-09-24. Baseline gameplay: tag `v0-overnight` (`ca00266`), with observational telemetry only. WO-0.1 is saved as `ebd49d4`. No live services or published places are used.

## Fixed policy

- Five independent solo Studio sessions, seeds 1101–1105, default first hero and practice profile. No retries after defeat. Start the timer at the first Combat snapshot; also retain total wall time. Timeout after 1,200 seconds counts as a non-clear and is labeled Timeout.
- Perceived attack tells are recognized with probability 0.75. Multiple volumes from one attack are grouped by sender within 50 ms. Reaction deadlines are uniformly 170–330 ms after receipt and execute at the next render frame. Output records actual observed reaction delay, not merely requested delay; rendering stalls can exceed 330 ms.
- Offensive attempts select light 60%, heavy 25%, special 15%; a special attempt fires only when the replicated cooldown is ready and the target is in range. Other actions also require range. Actual accepted attack distribution can differ due to range, cooldown and server validation.
- Recognized threatening melee tells choose block with probability 0.40; AOEs choose dash with probability 0.30. AOEs mean multi-volume, circular or >18-stud-wide warnings. Other recognized low sweeps may be jumped; remaining reactions shift a lane for 0.35 seconds. This is deliberately imperfect and does not search every danger zone for an optimal escape.
- Think intervals are 170–330 ms; attack attempts are 280–440 ms apart. A random wrong movement lasting 0.6 seconds occurs every 5–7 seconds while engaged. No character teleport, damage mutation, forced KO, perfect server-state reading, reward writes or automatic retry.
- Record source and bot revisions with each series. Reuse these seeds and policy for M2/M3. Five runs provide coarse 20-percentage-point clear-rate resolution; they are not a human difficulty certification.

## Server telemetry

`CombatTelemetry` is Studio-only and observational. Accepted hits include blocked chip, after invulnerability rejection. It records per-player damage/hits and per-district/per-encounter stock losses, attack names, windup minima/peak/cap breaches, and active nonempty-combat AI timing. AI timing wraps the existing step and excludes telemetry collection; it is not a MicroProfiler capture or a 12-enemy/four-player benchmark.

Idle ratio uses living grunt ticks outside stun, launch, recovery and attack, with horizontal velocity <0.5 and MoveDirection <0.05. Flank windows require at least two grunts within 28 studs continuously for five seconds; success means grunts occupied both X sides (>1 stud offset) at some point. Raw numerator/denominator are retained. Shorter engagements do not contribute a window. Camera-frustum measurement and rank are explicitly unsupported in the baseline, never reported as zero.

At a terminal state the server prints `COMBAT_TELEMETRY` JSON and writes a Studio workspace attribute. The bot prints `HUMANBOT_RESULT` and exposes the same report as a local Player attribute for root's collector. Test drivers are excluded from production Rojo trees.

## Review corrections before measurement

Independent combat review caught an extra perception think-delay, an early wave-attribution hook, timing samples outside active combat, and multi-volume defensive duplication. Root corrected these before the first recorded run. The telemetry spec checks hit/damage counters, stock attribution, caps/action diversity, active idle counts, five-second flank qualification, stunned/recovery exclusions and unavailable metrics. It passed in Studio.

## Additional measurement limits

Independent world review confirmed these limits before the series completed: snapshot damage is floored, whereas server damage counters retain fractions. Reaction mean measures scheduling of all recognized tells, including tells that are no longer threatening; it is not the latency of successful defense. Target selection sees all replicated enemy roots and does not model a human camera visibility limit. Terminal duration includes a 0.3-second report delay. Windup action counts do not measure every AI state or a per-30-second diversity window. Timeout can lack terminal telemetry because only Victory/Defeat invokes the server finish hook; such a result must retain unavailable fields rather than zeros. None of these were changed mid-series.

Public evidence replaces numeric account keys with run-local Player labels. Unredacted originals stay under ignored build/private-qa; all measured values are preserved.

## Results

All five fresh solo sessions completed on the unchanged baseline gameplay. Client stock accounting matched server stock counters on every run; floored snapshot damage matched fractional server totals within one point. All windup cap violation counts were zero.

| Seed | Outcome | Seconds | Stocks lost D1/D2/D3 | Damage (snapshot) | Eligible idle | Flank windows | Peak windups |
|---|---|---:|---|---:|---|---|---:|
| 1101 | Victory | 273.32 | 0/0/1 | 497 | 106/624 (17.0%) | 3/5 (60.0%) | 2 |
| 1102 | Victory | 275.36 | 0/0/0 | 495 | 159/913 (17.4%) | 5/9 (55.6%) | 2 |
| 1103 | Victory | 273.95 | 0/0/1 | 487 | 100/654 (15.3%) | 3/5 (60.0%) | 2 |
| 1104 | Victory | 293.85 | 0/0/1 | 676 | 101/760 (13.3%) | 1/7 (14.3%) | 2 |
| 1105 | Victory | 274.85 | 0/0/1 | 560 | 127/733 (17.3%) | 3/7 (42.9%) | 2 |

Clear rate: 5/5. Mean stocks lost: 0.80. Mean duration: 278.27 s. Mean snapshot damage: 543.00.
Pooled eligible idle: 593/3684 = 16.10%.
Pooled qualified flank windows: 15/33 = 45.45%.
Rank and frustum unsupported in baseline. Five runs are a coarse engineering comparison, not human certification.


The retained ToolboxAnimations source matched the repository after normalized line endings (170397 bytes, DJB2 1294375898). No gameplay tuning or AI changes occurred during collection.
