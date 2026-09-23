# Nightfall District — world bible

## Project identity and non-negotiable intent

Build an anime ensemble cooperative PvE brawler in a Jujutsu Kaisen city setting. The user specifically requested characters from Naruto, One Piece and Demon Slayer. Preserve that crossover ambition in the roster plan; do not silently replace it with unrelated generic heroes. This slice uses a Shibuya-inspired district and authored rescue mission. It does not claim its crossover story is anime canon.

The world is a directed left-to-right beat-em-up route, inspired by Bare Knuckle / Streets of Rage stage progression, with Super Smash Bros.-inspired impact and launch combat. It is not a sandbox. Jujutsu Shenanigans is the requested Roblox quality benchmark for responsive abilities, impactful audiovisual feedback and city detail. A procedural slice is a foundation, not evidence that this benchmark has already been reached.

## Geography and implementation contract

`src/server/WorldBuilder.lua` builds `workspace.NightfallCity` deterministically. Its three stages are X=0–180, 180–360 and 360–540. The continuous floor top is Y=0. The playable lateral band is approximately Z=-14–14. Spawn is X=14, Y=3, Z=0. Forward is +X. The camera observes from positive Z; architecture and skyline layers live toward negative Z.

The `Gates` folder contains single BaseParts `Gate1`, `Gate2`, `Gate3` at X=180, 360 and 540. The encounter director owns visibility and collision of these parts. The builder supplies an entrance stop at X=-9 and lateral collision volumes integrated with visible curbs and rails. There is no second invisible forward gate that could stop players after an encounter opens a gate. The final red curtain is background scenery; it does not obstruct the forward route.

### 01 — Scramble crossing

Cold cyan street lighting, tall billboard canyon, cream pedestrian stripes, an interrupted traffic signal and storefront glow. The first frame should contain the district identity, readable route, distant skyline and near curb. Large signs include a 21:31 emergency message, cinema marquee and Japanese/English storefront identifiers. The contrast between an ordinary commercial street and a supernatural lockdown creates the setting.

Gameplay intent: learn light attacks, directional movement, dodge and ally spacing; fight readable small groups; prevent the first encounter from filling the entire screen with effects. An early crossing offers an unmistakable orientation point.

### 02 — Dōgenzaka arcade

Warm amber lantern rhythm, six individually identified shops, awning stripes, blade signs, roof ribs and shutter details. Narrower-looking architecture changes the rhythm without shrinking the combat lane. Rear roof ribs frame the view without covering the camera with a solid roof. The lantern color shift signals progress even when the UI is hidden.

Gameplay intent: mixed enemies force target selection; use launch attacks to create space for allies. A mid-stage rescue or civilian evacuation is a planned story beat, not a feature implied by environment props alone.

### 03 — Last train / station curtain

A broad station apron, Exit 13 signage, stair silhouette, glass clerestory, tactile platform edge, suspended-service board and stopped train establish the terminus. Stair and platform scenery sit behind the lane; players do not have to navigate a decorative stair to progress. Cold white/cyan lighting returns, with crimson/violet concentrated on the boss curtain.

Gameplay intent: telegraphed boss patterns and overlapping cooperative responsibilities; the team earns the final opening. The final curtain is the mission's visual destination from the instant players enter this stage.

## Art direction

Palette: blue-black architecture, desaturated pavement, cyan guidance, amber human activity and crimson threats. Reserve the brightest red for hostile effects and the seal. Keep playable characters readable against the floor and avoid bloom washing out hit telegraphs.

Architecture uses foundation trim, roof cornices, facade pilasters, mullions, office windows, shop canopies, signage, and distinct rooftop heights. Three perceived depth layers are pavement/curb, shopfronts and skyline. No real anime frame, poster or soundtrack is embedded in the builder. All current typography and geometric set dressing are authored locally.

Road joints, crossing stripes, restrained wet reflections, bollards, benches, vending machines and utility boxes support the scale. Decorative objects remain anchored and generally non-colliding to protect combat movement. There are 21 complete destructible Model assemblies: five vending machines, nine utility boxes, six benches and one traffic signal. Each assembly owns all of its decorative pieces and exposes `Destructible`, `Health`, `PropKind` and `Broken` attributes plus a `Destructible` collection tag. `DestructionService.BreakNearby(position, radius, direction)` is a server-only API for accepted heavy/special hits. It hides the complete assembly, disables collision/query, emits up to four harmless fragments, and restores the original state after 20 seconds. There is a hard cap of 30 concurrent debris pieces and each expires in 1.5 seconds. Structural roads, gates, rails and buildings are never tagged. The metadata Health value is descriptive; this API breaks a selected prop immediately rather than implementing gradual prop damage. Root integration and runtime tests must verify the actual heavy/special trigger.

## Toolbox integration and asset policy

The user explicitly requires Toolbox assets for VFX, animations, hitbox combat logic and movement. The procedural environment does not substitute for that request. Keep source asset IDs, creator names, insertion results, script inspection notes, and actual adopted components in the asset inventory maintained by the integration owner. Prefer coherent asset families and measured VFX over miscellaneous visual noise. Do not count an asset as integrated because it appears in a shopping list.

For character additions retain Naruto, Luffy and Tanjiro as the requested thematic references. Distinctive silhouettes, pose language, move timing and readable color accents matter more than copying an outfit onto the same moveset. Document any asset ownership or animation publication requirements before release. The current build's real, playable roster is defined by its actual character configuration, not this future roster ambition.

## Quality acceptance and remaining craft passes

- Play the complete three-stage route with at least two clients and prove players cannot bypass encounter gates or become stranded behind them.
- Inspect from the actual gameplay camera: no dark-on-dark enemy loss, no off-screen telegraphs, no sign or lamp obscuring a player.
- Verify the first 30 seconds communicates attack, dodge, direction and cooperative objective without a wall of tutorial text.
- Playtest moving and attacking simultaneously, launch recovery, enemy collision clusters, simultaneous ability effects and teammate rescue conditions.
- Validate on a representative mobile device; thousands of simple Parts still need measured frame-time and memory budgets. Consider replacing repeated facade details with reusable MeshParts after the composition is approved.
- Add spatial sound, polished animation blending, authored character silhouettes, boss camera beats, civilian story interactions, and a multiplayer-verified destructible response before describing the result as comparable to Jujutsu Shenanigans.
- Preserve ideas that are deferred in this document or the project backlog with status. Do not delete the rescue story or roster intention just because implementation is staged.

## Deferred expansions, preserved

Future missions: rain-soaked service alley, underground interchange, rooftop relay interruption and station escape. These remain separately loaded directed stages, not a free-roam expansion. A train-car fight can reinterpret the enclosed station pressure with a small fixed arena and moving background. Optional score routes should branch into a short combat encounter and return to the controlled route.

Future set pieces: a curtain that retracts in strips, emergency screens updating after victories, a train arriving after seal destruction, and street lights recovering as allies advance. Each should communicate game state, not exist only as decoration.
