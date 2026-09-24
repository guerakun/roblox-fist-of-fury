# Curtain Break design record

## Active owner direction — 2026-09-23
Build a fully original, anime-styled cooperative Roblox beat-em-up. Keep the wind rushdown, mechanical long-reach bruiser and sweeping blade archetypes. Candidate internal IDs are Gale, Piston and Tide; display names are Rook Calder, Bo Marlowe and Isla Veyra, pending owner approval. The approved launch program is [LAUNCH_PLAN](launch/LAUNCH_PLAN.md), with actual results in [PROGRESS](PROGRESS.md).

The campaign follows three controlled stages: Ashgate Crossing city streets, abandoned station and abandoned factory. Each contains four encounters including a miniboss and boss. The stage structure takes gameplay inspiration from Bare Knuckle; rising damage, launches, recovery and stocks provide the platform-fighter influence. It is a cooperative rescue mission, not a sandbox.

## Implemented foundation and planned launch expansion
The baseline has server-owned fighting, three stages, twelve encounters, six elites, ready/rally/checkpoint flow, cosmetic destruction and earned progression. AI, challenge, matchmaking, pickups, throws and onboarding are launch work orders; presence in the plan does not imply completion. Source, Studio evidence and owner playtests remain separate acceptance levels.

## Decisions
- The repository is public; the launch program develops on its own branch. A public repository is not a published Roblox experience.
- X is forward, narrow Z depth is lane position, Y is jump/launch. Server-owned percent thresholds also finish fights inside closed streets.
- Clients request actions; the server decides damage, rewards, matchmaking and teleports.
- Custom canonical R6 rigs preserve compatibility with reviewed Toolbox motion. New hero art uses original authored geometry.
- Toolbox contributes inspected VFX, idle/walk/combat/dash poses and adapted hitbox logic. Rejected scripts never enter the runtime tree.
- Money never buys power. Coins are earned; paid offers remain disabled. Progression unlocks, difficulty and rewards require server validation.
- Roblox-generated pumps and station material supplement native geometry. Blender is optional, not a required pipeline step.
- Root integrates, builds, tests Studio and pushes. File owners and contracts are governed by AGENTS.md.

## Experience pillars
Readable attacks, purposeful movement, cooperative launch setups, distinct districts, fast retries and preserved design memory. Build success is not feel, balance or production certification.

## Preserved (retired) ideas
The original brief proposed an externally sourced crossover roster and a recognizable existing-fiction city. The owner replaced that direction with original heroes and Ashgate. Preserve the three gameplay archetypes, ensemble rescue motivation, urban density and strong audiovisual combat feedback. Retired names, likenesses and imported character meshes are not carried into current art or public materials. Earlier source remains in Git history.

The earlier shopping-arcade chapter and station escape remain future directed-route ideas. Civilian rescue, paired relays, train departure, team launch finishers and later rooftop routes remain documented proposals, outside tonight's v1 launch work unless the launch plan explicitly includes them.
