# Toolbox asset register

Imported and inspected in Roblox Studio on 2026-09-23. Toolbox/Creator Store is used for the actual animation poses, movement animation, impact particles and the basis of the hitbox adapter.

| Category | Source / creator | Use | Review |
|---|---|---|---|
| Combat animation | [14578890309](https://create.roblox.com/store/asset/14578890309), Combat Animations, PixellDaZuera | Exact R6 Idle, Walk, Hit 1, Hit 2, M2, Block keyframe poses exported to `ToolboxAnimations.lua` | No scripts in imported pack; 11 original sequences |
| Movement | [109267687059124](https://create.roblox.com/store/asset/109267687059124), R6 Dash Animation Speed Run Parkour Movement, z0efx63 | Exact 86-frame Dash sequence sampled by client | No scripts; motion/authority adapted to lane game |
| Hitbox | [117986110024473](https://create.roblox.com/store/asset/117986110024473), Hitbox Module, oSkyz_25 | Spatial overlap query technique adapted into `ToolboxHitbox.lua` | Original preserved in `vendor/SkyzHitbox.lua`; one-shot bounds query, exclusions and server validation added |
| Impact VFX | [92765511929343](https://create.roblox.com/store/asset/92765511929343), Vfx Block Magic Particle Effect Anime Glow Hit, le0_y2015 | Three particle textures/configurations reconstructed in `AssetInstaller.lua`; burst rates tuned | REJECTED all five embedded scripts and unrelated GUI/constraint objects. Source scripts included disguised texture utilities and unwanted GUI changes; never activated |

Animations are sampled from pose data instead of relying on private animation upload permissions. This preserves the actual Toolbox motion for the R6 prototype. Production should publish reviewed animations to the final experience owner and migrate to Animator tracks. Particle texture availability must be rechecked in the published experience.

No downloaded anime video, audio or character mesh is bundled. Naruto, Luffy and Tanjiro are prototype kit names with authored styling; final recognizable character assets, music and publication rights are outstanding production tasks. Source attribution does not imply ownership of the anime franchises.

Quarantine workflow: import only into ServerStorage.ToolboxReview in Edit mode; inspect every LuaSourceContainer without requiring it; export only reviewed data; remove raw imported objects before Play/save. The build contains no external numeric require, loadstring or HTTP runtime dependency.

## Audio imported and wired
- [Punch Impact 1, 132504023010884](https://create.roblox.com/store/asset/132504023010884), NickySergal — hit sound.
- [Sword swing whoosh, 135315310485417](https://create.roblox.com/store/asset/135315310485417), Akin_TR — attacks/dash.
- [City Night Ambience 3, 9112759731](https://create.roblox.com/store/asset/9112759731), ProSoundEffects — quiet environment loop.
Actual Sound instances inserted in Studio; client source recreates the same IDs for reproducible builds. Final published-universe audio permission testing remains required.
