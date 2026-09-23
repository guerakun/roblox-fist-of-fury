# Combat and encounter implementation

The playable prototype is a controlled 2.5D cooperative stage brawler. Damage accumulates as percent; growing knockback makes later hits launch harder. Every hero has three stocks. Cross the stage blast margin or reach 200% and lose a stock, with a brief checkpoint respawn. Running out of stocks makes that player a spectator until the next stage. All players recover stocks at stage checkpoints. Defeat restarts the current stage; victory restarts the run. Enemy defeat occurs by blast-zone launch or a tuned percent threshold to keep PvE waves moving.

## Module mapping and initialization

Map src/shared to ReplicatedStorage.Nightfall.Shared, and place Action, State, FX RemoteEvents under ReplicatedStorage.Nightfall.Remotes. Build the world and workspace.Enemies, then call CombatService.Init() and EncounterService.Init(CombatService). Config.Stages defines three 180-stud arenas, totaling 540 studs. Movement stays in z = -14 through 14. Server walking clamps stage edges, while temporary launch windows allow ringouts beyond a 24-stud blast margin. The floor top is y = 0. Veil gates are visual, non-solid curtains: server bounds stop walking while launch windows permit ringouts. Keeping solid gate collision would block right-side knockouts. CharacterFactory.Create(hero) supplies the player R6 rigs.

## Network contract

Client calls Action:FireServer(action, payload). Valid actions: Light, Heavy, Special, Dash, Block, Recovery, Jump, SelectCharacter, Restart. Payload uses direction = -1 or 1, held = true/false for block, and hero = Naruto/Luffy/Tanjiro for selection. Ordinary ground jump may be handled by Roblox; airborne Recovery is server-limited to once per landing.

Server State packets: {kind="Snapshot",hero,percent,stocks,stage,stageName,wave,waves,enemiesRemaining,status,blocking,downed,cooldowns={Special,Dash}}. Cooldown values are absolute workspace:GetServerTimeNow() timestamps. Status is Waiting, Combat, Intermission, Advance, Defeat, or Victory. Between waves the encounter uses Intermission. After all stage waves, the veil gate disappears and Advance requires every living player to rally within the final 12 studs before the next checkpoint. Snapshots are broadcast at 5 Hz and on transitions.

Server FX packets: {kind,position,direction?,hero?,action?,playerUserId?,damage?,heavy?,combo?,enemy?,duration?,radius?}. Kinds include Attack, Hit, Dash, Recovery, Spawn, KO, Wave, StageClear, Victory, Telegraph, GuardBreak, BossPhase. Telegraph duration is an actual pre-hit windup and dodge opportunity.

## Combat rules

- Three-hit light chain, delayed heavy launcher, directional guard with guard break, invulnerable dash, one aerial recovery.
- Naruto has a medium-range spiral strike; Luffy has the longest-reaching narrow special; Tanjiro has a wide, faster tidal sweep. Character switching preserves cooldowns and damage.
- Grunts advance steadily; runners close quickly; brutes resist knockback; the final boss gains speed and a wider two-sided slam below half remaining resilience.
- Host controls damage, cooldowns, stun, hitboxes, team filtering, percent, stocks, waves, bounds, and AI. Remote requests are allowlisted, type checked, and limited to 30 per player per second. Clients never provide targets or damage.
- Query hitboxes call the adapted, audited Toolbox spatial-query module. External asset scripts are not executed automatically. Custom fallback enemy rigs use original primitive geometry and procedural joint motion.

## Server API

Combat.SetArena(stage,index), ResetPlayers(Vector3), SpawnEnemy(kind,Vector3,healthScale), ClearEnemies(), GetEnemies(), GetAlivePlayers(), GetPlayerCount(), ApplyHit(attacker,target,attack,direction), SetEncounterState(fields), BroadcastState(), GetSnapshot(player), SetRestartCallback(callback). The encounter service exposes Init(combat) and Restart().

## Verification and remaining multiplayer testing

Test in Studio with one and then two players: each action, directional block, guard break, cooldown spam, aerial recovery, enemy telegraphs, three stocks, ringouts, wave completion, checkpoint restoration, party wipe, retry, late join, player departure, and full-run victory. Physics and visual quality require live playtesting; source review does not establish shipping quality or parity with Jujutsu Shenanigans. A production pass should add persistence, matchmaking, validated movement anti-cheat, latency compensation, and broader device playtesting.

Implementation references: [WorldRoot spatial queries](https://create.roblox.com/docs/reference/engine/classes/WorldRoot), [Humanoid movement](https://create.roblox.com/docs/reference/engine/classes/Humanoid), [network ownership](https://create.roblox.com/docs/physics/network-ownership).
