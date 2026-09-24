# Toolbox asset register

Imported and inspected in Roblox Studio on 2026-09-23. Toolbox/Creator Store is used for the actual animation poses, movement animation, impact particles and the basis of the hitbox adapter.

| Category | Source / creator | Use | Review |
|---|---|---|---|
| Combat animation | [14578890309](https://create.roblox.com/store/asset/14578890309), Combat Animations, PixellDaZuera | Exact R6 Idle, Walk, Hit 1, Hit 2, M2, Block keyframe poses exported to `ToolboxAnimations.lua` | No scripts in imported pack; 11 original sequences |
| Movement | [109267687059124](https://create.roblox.com/store/asset/109267687059124), R6 Dash Animation Speed Run Parkour Movement, z0efx63 | Exact 86-frame Dash sequence sampled by client | No scripts; motion/authority adapted to lane game |
| Hitbox | [117986110024473](https://create.roblox.com/store/asset/117986110024473), Hitbox Module, oSkyz_25 | Spatial overlap query technique adapted into `ToolboxHitbox.lua` | Original preserved in `vendor/SkyzHitbox.lua`; one-shot bounds query, exclusions and server validation added |
| Impact VFX | [92765511929343](https://create.roblox.com/store/asset/92765511929343), Vfx Block Magic Particle Effect Anime Glow Hit, le0_y2015 | Three particle textures/configurations reconstructed in `AssetInstaller.lua`; burst rates tuned | REJECTED all five embedded scripts and unrelated GUI/constraint objects. Source scripts included disguised texture utilities and unwanted GUI changes; never activated |

Animations are sampled from pose data instead of relying on private animation upload permissions. This preserves the actual Toolbox motion for the R6 prototype. Production should publish reviewed animations to the final experience owner and migrate to Animator tracks. Particle texture availability must be rechecked in the published experience.

No anime video or soundtrack is bundled. Toolbox character hair meshes are included as listed below. Naruto, Luffy and Tanjiro are prototype fan-theme kits; final publication rights remain outstanding. Source attribution does not imply ownership of the anime franchises.

Quarantine workflow: import only into ServerStorage.ToolboxReview in Edit mode; inspect every LuaSourceContainer without requiring it; export only reviewed data; remove raw imported objects before Play/save. The build contains no external numeric require, loadstring or HTTP runtime dependency.

## Audio imported and wired
- [Punch Impact 1, 132504023010884](https://create.roblox.com/store/asset/132504023010884), NickySergal — hit sound.
- [Sword swing whoosh, 135315310485417](https://create.roblox.com/store/asset/135315310485417), Akin_TR — attacks/dash.
- [City Night Ambience 3, 9112759731](https://create.roblox.com/store/asset/9112759731), ProSoundEffects — quiet environment loop.
Actual Sound instances inserted in Studio; client source recreates the same IDs for reproducible builds. Final published-universe audio permission testing remains required.

## Overnight character mesh imports
All three free Creator Store models were inserted into Edit-mode quarantine and inspected; no LuaSourceContainer was present. Only the following mesh/texture data is reconstructed by CharacterArt.lua. Raw models, welds and unrelated objects are discarded.

| Source | Creator | Retained data |
|---|---|---|
| [Naruto PTS Hair Free — 1453913561](https://create.roblox.com/store/asset/1453913561) | meshuploader213 | Hair/headband mesh 1453909835; texture 1453912288 |
| [Luffy's Straw Hat (includes hair) — 13178556114](https://create.roblox.com/store/asset/13178556114) | MonkeyWizard_OOA | Hair mesh 943796917; hat mesh 5063791566 / texture 5063791598 |
| [Tanjiro Hair — 16580641649](https://create.roblox.com/store/asset/16580641649) | uchirratobi1438 | Hair meshes 3657762884 and 3828742380; texture 3828765577 |

Meshes are normalized to the custom R6 rigs. Cosmetic geometry does not participate in combat queries. Original authored eyes, face marks and clothing details supplement the imported hair. Marketplace attribution is not franchise publication permission.

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
