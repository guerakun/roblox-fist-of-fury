# M3 presentation contract — proposed, not implemented

Recorded 2026-09-24 from presentation/combat/root coordination. These notes preserve interface intent while M2 is completed. They do not define a shipped remote schema or claim a tested feature. Combat and root must confirm the final field names, controls and tuning before presentation edits source.

| Feature | Proposed interface | Authority and acceptance |
|---|---|---|
| Style meter | A server snapshot supplies score, multiplier and progress toward the next multiplier step. | The HUD displays the server result; a client never submits score, multiplier or claimed skill events. Exact snapshot keys remain to be agreed. |
| District result | A server result supplies rank, score, duration, par time, damage taken and the coin/XP reward breakdown. | Show how performance and selected difficulty/Heat affect the actual earned reward. Do not independently calculate grants in the UI. |
| Teammate revive | Hold V on keyboard, L3 on controller or a separate touch control beside a downed teammate. | This is distinct from instant stock sharing on R/R3. The server owns distance, the channel duration, interruption and revived state. Final controls still need conflict review and physical device testing. |
| Desperation special | An explicit Special + Heavy gesture communicates the planned +12% self-percent cost. | Do not use an accidental double-tap trigger. Input requests the move; server validation decides cooldown exception, cost and attack. The exact touch/controller gesture must be finalized with the combat contract. |
| Heat selection | Read available contract descriptions and reward values from the final shared configuration. | Do not keep the launch plan's provisional reward values as an independent hardcoded economy. Unsupported contracts remain disabled until implemented. |

The launch plan remains the scope authority. These are M3 interface proposals, not new backlog work. Required evidence includes server specs/runtime checks, readable UI at campaign scale, touch/controller access and the milestone's before/after HumanBot and human results. No proposed field or control should be described as available until its implementation and validation are recorded in `docs/PROGRESS.md`.


## Integration constraints preserved from source review

These are proposed implementation constraints, not shipped features:

- Main merges server snapshots. Optional expired fields must clear explicitly with `false`, and district results need a stable identity so stale results cannot persist or replay.
- Label the existing R/R3 transfer `GIVE 1 STOCK`, distinct from the proposed V/L3 revive channel. Hold input must end on release, cancellation, focus loss, menu transition, death and character replacement.
- Current attacks dispatch immediately. A desperation chord needs centralized input routing so one gesture cannot also send duplicate ordinary attacks.
- Layout must reserve the campaign return-travel strip on results screens, including short landscape views and touch controls.
- Final shared Heat metadata must replace provisional hardcoded descriptions and reward figures. The server remains the reward authority.
