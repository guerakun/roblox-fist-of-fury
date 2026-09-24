# Progression integration contract

Root owns `ProgressionService.lua`, `ProgressionConfig.lua`, `ProgressionUI.lua` and Bootstrap integration. No dependency from progression back into combat.

- `ProgressionService.Init()` before Combat.Init.
- `GetCombatModifiers(player)` returns damageMultiplier, knockbackMultiplier, moveSpeedBonus, damageReduction. Safe defaults until profile loaded.
- `AwardEncounterClear(players, stageIndex, encounterKind, rewardKey)` grants server-authorized rewards. Stable reward key per campaign/stage/wave prevents repeated grants on checkpoint retry. Types: Wave, Miniboss, Boss.
- `AwardEnemyDefeat(player, enemyKind, encounterKind)` optional small earned rewards; encounter rewards are preferred so support play is not penalized.
- `SetRunState(status, stageIndex)` restricts boon changes to safe intermissions.
- Client `require(script.Parent.ProgressionUI).Init()` once. Separate ScreenGui order30; P/menu opens. MenuOpen player attribute suppresses movement/actions; SettingsOpen remains owned by Main.
- Menu button at anchor(.5,0), position(.5,+54,0,20),96x32; narrow viewport<650 y100.
- `Remotes.Progression` RemoteEvent created by service. Client actions Request, ClaimTier, BuyCosmetic, EquipCosmetic, EquipBoon, PurchasePass. Server packet Snapshot or Notice. Never accept client currency/XP/modifier values.
- Coins can buy fixed-price cosmetic trails/titles. Chapter XP rewards fixed free tiers; premium cosmetics require server-verified pass ownership. Sales disabled with passId0 until experience configuration is complete.
- Guardian: free,8% incoming-damage reduction. Focus:200XP,+8%damage. Haste:400XP,+2movement speed. One boon equipped; no paid upgrades/stacking.
