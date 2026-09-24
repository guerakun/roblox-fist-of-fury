# Toolbox asset register

Imported and inspected in Roblox Studio on 2026-09-23. Toolbox/Creator Store is used for the actual animation poses, movement animation, impact particles and the basis of the hitbox adapter.

| Category | Source / creator | Use | Review |
|---|---|---|---|
| Combat animation | [14578890309](https://create.roblox.com/store/asset/14578890309), Combat Animations, PixellDaZuera | Exact R6 Idle, Walk, Hit 1, Hit 2, M2, Block keyframe poses exported to `ToolboxAnimations.lua` | No scripts in imported pack; 11 original sequences |
| Movement | [109267687059124](https://create.roblox.com/store/asset/109267687059124), R6 Dash Animation Speed Run Parkour Movement, z0efx63 | Exact 86-frame Dash sequence sampled by client | No scripts; motion/authority adapted to lane game |
| Hitbox | [117986110024473](https://create.roblox.com/store/asset/117986110024473), Hitbox Module, oSkyz_25 | Spatial overlap query technique adapted into `ToolboxHitbox.lua` | Original preserved in `vendor/SkyzHitbox.lua`; one-shot bounds query, exclusions and server validation added |
| Impact VFX | [92765511929343](https://create.roblox.com/store/asset/92765511929343), Vfx Block Magic Particle Effect Anime Glow Hit, le0_y2015 | Three particle textures/configurations reconstructed in `AssetInstaller.lua`; burst rates tuned | REJECTED all five embedded scripts and unrelated GUI/constraint objects. Source scripts included disguised texture utilities and unwanted GUI changes; never activated |

Animations are sampled from pose data instead of relying on private animation upload permissions. This preserves the actual Toolbox motion for the R6 prototype. Production should publish reviewed animations to the final experience owner and migrate to Animator tracks. Particle texture availability must be rechecked in the published experience. The reconstructed child textures from the reviewed impact pack `92765511929343` are explicitly registered below; these are existing runtime dependencies, not additional imports:

| Runtime emitter | Texture ID | Provenance and gate |
|---|---|---|
| ImpactCross | 16004095914 | Reviewed impact pack above; reconstructed in AssetInstaller; final-universe availability/permission pending |
| ImpactSparks | 13644087339 | Same reviewed pack and published-universe gate |
| ImpactRing | 7216847656 | Same reviewed pack and published-universe gate |

No reference-game video or soundtrack is bundled. The launch cast uses native-part original candidate geometry in source; retired imported character meshes are not approved for the launch build. Structural runtime checks are recorded in CHARACTER_ART.md and the launch art evidence. Rendered likeness review and owner approval remain pending.

Quarantine workflow: import only into ServerStorage.ToolboxReview in Edit mode; inspect every LuaSourceContainer without requiring it; export only reviewed data; remove raw imported objects before Play/save. The build contains no external numeric require, loadstring or HTTP runtime dependency.

## Audio imported and wired
- [Punch Impact 1, 132504023010884](https://create.roblox.com/store/asset/132504023010884), NickySergal — hit sound.
- [Sword swing whoosh, 135315310485417](https://create.roblox.com/store/asset/135315310485417), Akin_TR — attacks/dash.
- [City Night Ambience 3, 9112759731](https://create.roblox.com/store/asset/9112759731), ProSoundEffects — quiet environment loop.
Actual Sound instances inserted in Studio; client source recreates the same IDs for reproducible builds. Final published-universe audio permission testing remains required.

## Original hero art and retired assets
Gale, Piston and Tide use native-part candidate designs under WO-1.2. No new external character asset IDs are planned. Exact implementation/inspection results belong in CHARACTER_ART.md and PROGRESS.md.

### Preserved (retired) ideas
Earlier prototype hair/accessory imports and identifying face/outfit motifs are removed from the active inventory. Their original records remain in Git history. Preserve the reviewed-import quarantine method, R6 compatibility and cosmetic/query separation, not the retired assets. Toolbox motion, particles and hitbox sources above remain active.

## Original generated environment art
Roblox Studio mesh generation produced an original four-part foundry pump, published asset **130740920499312**, totaling approximately 3,500 triangles. Three static instances dress the factory background. No executable scripts are imported.
- Base: mesh 86636771757111 / texture 109121361954379.
- Gauge: mesh 76795478278087 / texture 107421068394595.
- Pipes: mesh 140159118360520 / texture 101025669073439.
- Motor: mesh 115650030808677 / texture 139561435818528.

Roblox material generation produced NightfallStationTile, a Concrete MaterialVariant with 8-stud tiling:
- Color 114981869241823; normal 133333203349103; roughness 118428319587116; metalness 86148575515928.
- Applied to station background surfaces; the combat floor stays visually simple for telegraph readability.
- MaterialService metadata is serialized in default.project.json because assigning BaseMaterial at runtime requires plugin security.

## Overnight audio additions
Actual Sound instances inserted from Toolbox and preloaded successfully in Edit mode on 2026-09-23:
- [Dock Ambience 3 — 9112772977](https://create.roblox.com/store/asset/9112772977), ProSoundEffects; 45.909 seconds. Watery metal ambience for the abandoned station.
- [Ups Sorting Facility 2 — 9112890492](https://create.roblox.com/store/asset/9112890492), ProSoundEffects; 53.003 seconds. Factory conveyor ambience.
- [Battle Action — 1844978927](https://create.roblox.com/store/asset/1844978927), APMOfficial; 32.261 seconds. Combat music candidate.

Loading success is not an audible mix review or final-universe permission test. Client wiring and settings are tracked in PROGRESS.md.
