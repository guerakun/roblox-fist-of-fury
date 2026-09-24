# Nightfall District — world bible

## Project identity and non-negotiable intent

Build a fully original anime-styled ensemble PvE brawler in fictional Ashgate. The owner approved original heroes on 2026-09-23: Gale, Piston and Tide, with candidate names pending owner approval. The rescue mission connects a commercial crossing, abandoned station and industrial relay; it does not reproduce an external story or geography.

The world is a directed left-to-right beat-em-up route, inspired by Bare Knuckle / Streets of Rage stage progression, with Super Smash Bros.-inspired impact and launch combat. It is not a sandbox. The quality target is responsive abilities, impactful audiovisual feedback and readable city detail. A procedural slice is a foundation, not evidence that this benchmark has already been reached.

## Geography and implementation contract

`src/server/WorldBuilder.lua` builds `workspace.NightfallCity` deterministically. Its three stages are X=0–180, 180–360 and 360–540. The continuous floor top is Y=0. The playable lateral band is approximately Z=-14–14. Spawn is X=14, Y=3, Z=0. Forward is +X. The camera observes from positive Z; architecture and skyline layers live toward negative Z.

The `Gates` folder contains single BaseParts `Gate1`, `Gate2`, `Gate3` at X=180, 360 and 540. The encounter director owns visibility and collision of these parts. The builder supplies an entrance stop at X=-9 and lateral collision volumes integrated with visible curbs and rails. There is no second invisible forward gate that could stop players after an encounter opens a gate. The final furnace is background scenery; it does not obstruct the forward route. Each chapter keeps the same floor and gate contract even though its material, lighting and silhouette change.

### 01 — Scramble crossing

Cold cyan street lighting, tall billboard canyon, cream pedestrian stripes, an interrupted traffic signal and storefront glow. The first frame should contain the district identity, readable route, distant skyline and near curb. Large signs include a 21:31 emergency message, cinema marquee and Japanese/English storefront identifiers. The contrast between an ordinary commercial street and a supernatural lockdown creates the setting.

Gameplay intent: learn light attacks, directional movement, dodge and ally spacing; fight readable small groups; prevent the first encounter from filling the entire screen with effects. An early crossing offers an unmistakable orientation point.

### 02 — Abandoned station

The active second chapter is now a cutaway transit hall, X=180–360. Pale tile replaces asphalt. A continuous tactile strip, rear ballast and rail sleepers, abandoned metro cars with recessed doors and cracked glazing, ticket barriers, a shuttered kiosk, suspended-service signs, a stopped clock, roof trusses and leaking steam create the location. The front is intentionally open to the side-view camera; partial rear roof panels imply enclosure without hiding the player.

The Platform Widow landmark at X=255 sits beneath the stopped station clock. The Last Conductor landmark at X=315 is framed by a derailed carriage, rail signal and last-departure board. Foreground abandoned luggage and dropped tickets reinforce human absence; heavy props remain at the lane edges. The maintenance-route sign points toward the factory instead of falsely promising the mission ends here.

Gameplay intent: faster lane repositioning against the Widow, then clear directional response to the Conductor. Neither scenery rails nor the decorative stairs change the shared collision floor. Cyan/white dominates, with desaturated tile and warm emergency guidance distinguishing this chapter from the saturated city.

### 03 — Abandoned factory

The active final chapter is Kurogane Works, X=360–540: an authored industrial setting connected to the transit maintenance line. Rusted corrugated walls, steel I-beams, sawtooth roof trusses and clerestory windows create a broad silhouette. A rear service catwalk and staircase, pressure tanks, banded steam pipes, an overhead crane with hook and roller conveyor give the hall a visible function.

Furnace Hound's arena at X=435 is beside the disabled assembly conveyor. Kiln Sovereign's arena at X=495 is dominated by Furnace 03, a large cylindrical vessel with a barred amber core, pressure warning sign and tall exhaust flue. The factory uses warm metal/concrete surfaces and amber work lights; crimson remains for warnings. The large furnace sits behind the lane and is scenery, not an automatic damage source.

Gameplay intent: machinery-themed charge and slam patterns with readable warning footprints, followed by a final boss whose core-break victory restores the escape route. Scaffolding, pipes and catwalks remain outside the camera's foreground sightline. The player-facing floor is continuous and never punctured by prop destruction.

### Six encounter landmarks

| Chapter | Role | Enemy / landmark key | Spawn X | Visual framing |
| --- | --- | --- | --- | --- |
| City streets | Miniboss | Executioner / CrosswalkExecutioner | 75 | Broken traffic signal and pedestrian crossing |
| City streets | Boss | SirenMarshal | 135 | Abandoned response van and police cordon |
| Abandoned station | Miniboss | PlatformWidow | 255 | Stopped clock, empty platform and tiled lane |
| Abandoned station | Boss | LastConductor | 315 | Derailed metro car and last-departure signal |
| Abandoned factory | Miniboss | FurnaceHound | 435 | Conveyor and suspended crane machinery |
| Abandoned factory | Boss | KilnSovereign | 495 | Barred furnace core and pressure-warning sign |

`NightfallCity.EncounterLandmarks` holds one Model per row with Stage, Role, EnemyKind and SpawnX attributes and an invisible SpawnAnchor. These names and anchors were agreed with the combat owner. Painted corner brackets are muted silver and must not resemble red hostile hit telegraphs. Landmark geometry is not itself a trigger; the encounter director owns progression and enemy spawning.
## Art direction

Palette: blue-black architecture, desaturated pavement, cyan guidance, amber human activity and crimson threats. Reserve the brightest red for hostile effects and the seal. Keep playable characters readable against the floor and avoid bloom washing out hit telegraphs.

Architecture uses foundation trim, roof cornices, facade pilasters, mullions, office windows, shop canopies, signage, and distinct rooftop heights. Three perceived depth layers are pavement/curb, shopfronts and skyline. No real anime frame, poster or soundtrack is embedded in the builder. All current typography and geometric set dressing are authored locally.

Road joints, crossing stripes, restrained wet reflections, bollards, benches, vending machines and utility boxes support the scale. Decorative objects remain anchored and generally non-colliding to protect combat movement. There are 34 complete destructible Model assemblies: five vending machines, nine utility boxes, six benches, one traffic signal, four pieces of lost luggage, five industrial drums and four shipping crates. Each assembly owns all of its decorative pieces and exposes `Destructible`, `Health`, `PropKind` and `Broken` attributes plus a `Destructible` collection tag. `DestructionService.BreakNearby(position, radius, direction)` is a server-only API for accepted heavy/special hits. It hides the complete assembly, disables collision/query, emits up to four harmless fragments, and restores the original state after 20 seconds. There is a hard cap of 30 concurrent debris pieces and each expires in 1.5 seconds. Structural roads, gates, rails and buildings are never tagged. The metadata Health value is descriptive; this API breaks a selected prop immediately rather than implementing gradual prop damage. Root integration and runtime tests must verify the actual heavy/special trigger.

## Toolbox integration and asset policy

The user explicitly requires Toolbox assets for VFX, animations, hitbox combat logic and movement. The procedural environment does not substitute for that request. Keep source asset IDs, creator names, insertion results, script inspection notes, and actual adopted components in the asset inventory maintained by the integration owner. Prefer coherent asset families and measured VFX over miscellaneous visual noise. Do not count an asset as integrated because it appears in a shopping list.

The launch roster uses original Gale, Piston and Tide silhouettes and pose languages: wind courier, mechanical gauntlet mechanic and water-glaive responder. Display names belong only in configuration. Native geometry replaces retired imported character art; current implementation and approval evidence are separate from design intent. Record actual new asset IDs and ownership requirements before release.

## Quality acceptance and remaining craft passes

- Play the complete three-stage route with at least two clients and prove players cannot bypass encounter gates or become stranded behind them.
- Inspect from the actual gameplay camera: no dark-on-dark enemy loss, no off-screen telegraphs, no sign or lamp obscuring a player.
- Verify the first 30 seconds communicates attack, dodge, direction and cooperative objective without a wall of tutorial text.
- Playtest moving and attacking simultaneously, launch recovery, enemy collision clusters, simultaneous ability effects and teammate rescue conditions.
- Validate on a representative mobile device; thousands of simple Parts still need measured frame-time and memory budgets. Consider replacing repeated facade details with reusable MeshParts after the composition is approved.
- Add spatial sound, polished animation blending, authored character silhouettes, boss camera beats, civilian story interactions, and a multiplayer-verified destructible response before describing the result as comparable to the requested Roblox combat-quality benchmark.
- Preserve ideas that are deferred in this document or the project backlog with status. Do not delete the rescue story or roster intention just because implementation is staged.

## Deferred expansions, preserved

Future missions: rain-soaked service alley, underground interchange, rooftop relay interruption and station escape. These remain separately loaded directed stages, not a free-roam expansion. A train-car fight can reinterpret the enclosed station pressure with a small fixed arena and moving background. Optional score routes should branch into a short combat encounter and return to the controlled route.

Future set pieces: a curtain that retracts in strips, emergency screens updating after victories, a train arriving after seal destruction, and street lights recovering as allies advance. Each should communicate game state, not exist only as decoration.

## Preserved (retired) ideas — previous route concepts

The initial slice placed a shopping arcade in chapter two and the station in chapter three. The user subsequently specified exactly city streets, abandoned station and abandoned factory, so those initial compositions are no longer the active three chapters. The arcade remains a future side-route or later campaign chapter. Original design notes follow for reuse:

### 02 — Lantern arcade (retired route)

Warm amber lantern rhythm, six individually identified shops, awning stripes, blade signs, roof ribs and shutter details. Narrower-looking architecture changes the rhythm without shrinking the combat lane. Rear roof ribs frame the view without covering the camera with a solid roof. The lantern color shift signals progress even when the UI is hidden.

Gameplay intent: mixed enemies force target selection; use launch attacks to create space for allies. A mid-stage rescue or civilian evacuation is a planned story beat, not a feature implied by environment props alone.

### 03 — Last train / station curtain

A broad station apron, Exit 13 signage, stair silhouette, glass clerestory, tactile platform edge, suspended-service board and stopped train establish the terminus. Stair and platform scenery sit behind the lane; players do not have to navigate a decorative stair to progress. Cold white/cyan lighting returns, with crimson/violet concentrated on the boss curtain.

Gameplay intent: telegraphed boss patterns and overlapping cooperative responsibilities; the team earns the final opening. The final curtain is the mission's visual destination from the instant players enter this stage.


## Geometry and effect budget notes

Only the city has the dense office-window skyline; the station and factory use their own rear silhouettes. Decorative Parts are non-colliding and non-queryable, so combat spatial queries are not filled by facade trim. Roads, lane boundaries and encounter gates retain their collision contracts. World smoke is limited to three emitters at three particles per second each; there are no per-part frame loops or dynamic shadow lights. The source remains deterministic and uses native geometry rather than remote mesh downloads.

These are design limits, not a measured performance pass. Root must count final runtime Parts/emitters, inspect all three camera views and profile the maximum four-player effect load. Future optimization should preserve the six landmark silhouettes while combining repeated architecture into MeshParts if required.
## Screenshot-driven abandonment and depth pass

The first stage-2/3 preview captures showed empty sky above long repeating wall planes. A second geometry pass adds depth and narrative wear rather than another generic foreground prop row. The station now sits beneath a retaining/service structure and elevated street, with uneven rear service-tower heights, a collapsed roof sheet and broken brace, hanging cable, water scars, wall fractures, ivy, rubble, a maintenance cart and warm emergency lamps. The factory gains distant reinforced smokestacks, a loading tower, twin storage silos, elevated conveyor housing and a control annex, plus repaired wall plates, oil grime, fallen corrugated sheets, rubble and blue maintenance lighting. Foreground drainage aprons sit below the combat floor so they frame the lane without hiding fighters.

All additions remain static, non-colliding and non-queryable scenery; no new dynamic loops, destructible tags or attack-like red ground fills were introduced. Geometry count and visibility should be checked in the regenerated preview and the real gameplay camera. The first screenshots were composition evidence, not the final mobile performance result.
## Hero color fidelity / lighting revision

A retired prototype character preview showed a warm-colored outfit tending yellow and skin approaching white. The previous high blue-white ColorShift_Top (163/192/221) combined with high ambient, direct illumination, specular response and character fill risked washing out material colors. The revised world uses neutral top/bottom color shift, brightness 1.85, exposure 0, shadow ambient 84/90/106, outdoor ambient 96/102/118, diffuse scale 0.55 and specular scale 0.45. Post-processing is nearly neutral (250/251/255 tint, zero saturation adjustment, contrast 0.04), with bloom 0.1 and threshold 1.3. Local cyan/amber practical lights still define the chapters, and the existing reduced character fill remains owned by CharacterFactory.

This is a moderation pass, not a completed color-calibration result. Verify the new charcoal/amber wind outfit, brass/teal mechanical outfit and deep-blue/foam blade outfit in all three chapters at Studio quality 21 and the target mobile quality. Preserve visible lane contrast; if a local section becomes too dark, increase that area's neutral practical light rather than restoring a global color wash. Official lighting behavior reference: https://create.roblox.com/docs/environment/lighting .
