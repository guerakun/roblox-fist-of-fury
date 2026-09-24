# Historical extraction evidence

These two fixtures belong to commit `b38e04b` (WO-2.1), when enemy behavior was intentionally unchanged. They were executed there: 25 differential traces and nine cap values passed. The accompanying seeded run is recorded in `docs/PROGRESS.md`.

They are excluded from the current runtime suite because WO-2.2 deliberately changes decisions and token caps. To reproduce, use the server modules at `b38e04b` and install these two modules as siblings. Do not report them as passing on the new AI.

Current scheduler behavior is checked by `tests/AttackDirectorAI.spec.lua` and `tests/EnemyAISlots.spec.lua` plus root's Studio campaign runs.
