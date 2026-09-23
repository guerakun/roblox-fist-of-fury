# Design record

## User brief, preserved
Create a GitHub for an anime Bare Knuckles / Fist of Fury-style Roblox game. Include characters from Naruto, One Piece and Demon Slayer. Use Roblox Studio capabilities and Blender if useful. Toolbox must contribute VFX, animations, hitbox combat and movement. Core fighting should feel like Super Smash Bros. World settings should reference JJK cities. Make a controlled left-to-right PvE co-op experience, not a sandbox. Fan out agents for production and independent quality critique against Jujutsu Shenanigans. Preserve experience, world and story notes in Markdown.

## Interpretation
Campaign loop: choose hero → enter bounded district → fight three waves → open curtain → group rally → next district → boss → results/retry. Combat loop: position → strike and build percent → launch/juggle → recover or use defensive movement. This reconciles the requested stage beat-em-up structure with Smash's damage/launch identity. Prototype enemies also have a percent defeat threshold to prevent unfinishable encounters in walled streets; document and tune rather than pretending this exactly replicates Smash.

## Implemented scope
One chapter, three street districts, three hero kits, four enemy archetypes including a boss. All content deterministic, source controlled and reproducible. Procedural city architecture avoids dependency on unknown large marketplace maps. Toolbox contributes real combat/walk/idle/dash keyframe poses, impact particles and reviewed hitbox logic; combat authority is adapted to this game's needs.

## Decisions
- Development repository starts private.
- X is forward, narrow Z depth is lane position, Y is jump/launch.
- Player damage and hit results are determined on server; clients request actions only.
- Hero rigs are custom canonical R6 to match the selected Toolbox motion.
- Only safe extracted particle data from the first VFX import is retained.
- Silhouettes and uniforms are authored geometry; no franchise mesh ripping.
- Keep test outcomes, unimplemented ideas and review gaps explicit.
- No Blender asset required for the first slice; use later for hero modeling, organic curse enemies and architectural hero props.

## Team work
Combat agent owns authoritative fighting and encounter flow; city agent owns world/story/references then performs independent critique; presentation agent owns input, camera, HUD and animation/VFX; root integrates Toolbox data, hero rigs, build, GitHub and Studio validation.

## Experience pillars
Readable attacks, purposeful movement, cooperative launch setups, distinct districts, fast retries, persistent design memory. Never equate a successful build with finished feel or production quality.
