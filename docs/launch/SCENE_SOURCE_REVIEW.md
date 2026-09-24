# Scene construction and lifetime review — 2026-09-24

World inspected frozen campaign source `9f29012` while root runs the five-session M2 comparison. This is a read-only source audit. No Studio scene query, renderer capture, device run, memory measurement, place rebuild or gameplay edit was performed. Counts below are derived from explicit source loops or separately attributed prior evidence; they are not a new runtime inventory.

## Construction and cleanup

`WorldBuilder.Build` destroys the previous named `NightfallCity` before constructing its replacement. All authored world folders, architecture, props, signs, markers and ambient emitters belong under that model. The three named Lighting effects are independently replaced before new effects are added. WorldBuilder installs no event connections or persistent update loop. Campaign Bootstrap builds the city once during initialization, then applies the generated scenic dressing.

`ArtAssetsInstaller.DressWorld` destroys the previous `AuthoredMeshDetails` folder before reconstructing three four-piece foundry pumps. Its material installer reuses the named material, and the production project serializes the edit-time material metadata. Calling Build alone removes scenic dressing; the complete Bootstrap sequence also calls DressWorld. These ownership patterns support bounded replacement, but repeated live rebuild behavior has not been measured in this audit.

HubWorld similarly replaces its named `CurtainBreakHub` folder. Its explicit source contains 23 direct BasePart children, five signs (each with SurfaceGui/TextLabel/UIPadding), five PointLights and one ProximityPrompt: 44 descendants, excluding the root folder, before any unrelated service/player objects. Root previously observed 23 direct children during WO-5.1. This source count is not hub memory usage or proof that the dojo/record boards are functional.

EnemyFactory creates each rig as one model with local detail welds and no per-rig event/update loop. Combat owns enemy records; enemy KO removes the record and destroys the model immediately. `ClearEnemies` resets the director, increments the battle epoch, releases grabs, destroys current rigs and clears the registry. Existing delayed combat callbacks validate epoch/model/serial before applying effects. Encounter loops carry a generation token, and an empty server increments that generation and clears enemies. These are source lifetime guards, not proof that all memory categories return to baseline after repeated campaigns.

## Fixed scene quantities and dynamic limits

| Source item | Derived quantity / limit | Practical implication |
|---|---|---|
| Campaign district footprint | Three contiguous 180-stud stages; 540-stud route | All districts are built together |
| Campaign streaming | `StreamingEnabled=false` in production project | Full scene remains replicated; distance render culling is not instance unloading |
| Campaign point lights | 20: four street, six station, one furnace, four factory, three station emergency, two maintenance | All are authored with Shadows=false; no source stage-based enable/disable policy |
| Environmental steam | Three emitters, each Rate=3 and Lifetime=1.5–2.5 seconds | Nine particles/second configured across the world; actual simultaneous particles/GPU cost unmeasured |
| Campaign signs | 22 helper-created sign panels, each with one SurfaceGui and one TextLabel | MaxDistance=320, PixelsPerStud=32; billboard density needs device inspection |
| Entry structures | Twelve groups, 48 invisible markers, 60 doorway parts | Prior WO-2.5 structural runtime check passed; no visual/render certification |
| Destructible assemblies | 34 from current loops: signal1 + luggage4 + drums5 + crates4 + vending5 + utility9 + benches6 | One break query scans the tagged collection and filters to the current city |
| Cosmetic destruction debris | At most four pieces per assembly and 30 globally | Approximately 1.5-second cleanup; fragments cannot collide, touch or enter spatial queries |
| Broken-prop restoration | 20 seconds | Retains restoration state temporarily; no repeated timer for an already broken assembly |
| Pump dressing | Three models × four Parts/SpecialMeshes | Twelve static visual Parts and twelve mesh objects, plus models/folder; asset/render cost remains separate |

Most native scenery is anchored and noncolliding/nontouchable/nonqueryable by default. The explicit collidable route structure is the continuous floor, two curbs, two lane bounds, entrance stop and three gates. The SpawnLocation is configured separately. Enemy detail parts are cosmetic and nonqueryable; prior ordinary-rig structural checks observed seven queryable core parts per rig. These filters protect hit queries but do not eliminate render, replication or instance memory cost.

No full campaign Part/triangle/texture memory total is asserted here. Randomized facade window choices, helper nesting, original mesh payloads, client VFX and active characters all contribute. Source-level `Instance.new` counts are not a substitute for a built-scene inventory.

## Destruction-specific review

Destruction only accepts tagged Models with a PrimaryPart under the current city. It clamps the query radius to 24 studs. Breaking marks the assembly before collecting/restoring state, so repeated calls while broken do not schedule more restore timers. Structural floor and gates are not tagged by WorldBuilder.

Each fragment is cloned from existing visual geometry, then its children and tags are removed before parenting. Fragments receive server network ownership, no collision/touch/query participation and no shadows. The global registry/counter prevents more than 30 active fragments; delayed cleanup removes registry references and destroys the part. The restore callback skips a destroyed old assembly, so a world replacement cannot be restored through an old callback. Old callbacks may retain references until their scheduled expiry; that is bounded delayed retention, not an observed permanent leak.

`BreakNearby` uses a tagged-collection scan and per-model bounding-box distance rather than a spatial index. With 34 source assemblies this is a bounded current-scene workload, but its cost under peak simultaneous heavy/special attacks has not been isolated. It should be profiled before deciding whether indexing is necessary.

Historical [VALIDATION](../VALIDATION.md) records a 21-prop destruction stress pass, 30-fragment cap, zero fragments after two seconds and restoration after 21 seconds. The current source has 34 assemblies. Preserve the older result as historical evidence; it does not certify a new all-34-prop stress run.

## Performance concerns to measure

The main source concern is resident decorative complexity: all districts, repeated small Parts, facade windows, translucent/glass surfaces, signs, lights and mesh dressing coexist. Non-Neon native parts generally retain CastShadow=true, including small details. There is no stage-based scene unload or explicit lower-detail environment tier. These are profiling candidates, not established causes of low FPS. Do not remove visual quality or change streaming during the frozen comparison based on assumptions.

The current AI MicroProfiler captures measure an AI scope; they cannot answer renderer, physics, texture memory or full-scene lifetime questions. Hub's small source count likewise does not certify its memory budget. Current blank/dark Studio 3D screenshots leave composition, lighting and actual occlusion review open.

## Owner/root evidence queue after the freeze

1. On the rebuilt source, inventory descendants by class and owner folder in hub and campaign. Record total BaseParts, meshes, emitters, lights, SurfaceGuis, queryable/collidable parts and current asset loading state; retain source commit and tool output.
2. Measure memory and frame timing after loading, through each district, at four-player peak effects, after enemies/debris expire, after a retry and after a fresh campaign. Capture the chosen minimum-spec phone/resolution, not just Studio desktop CPU.
3. Stress all 34 destructibles, checking the 30-piece cap, nonphysical/query-free fragments, cleanup and restoration. Rebuild during a pending restoration and verify the replacement remains unaffected. Preserve old and new test scopes separately.
4. For a maintenance-only repeated-build test, compare complete Build + DressWorld before/after counts and named Lighting effects. Inspect tagged-instance and pending-resource counts after delayed cleanup. Do not run this concurrently with gameplay tests.
5. Only if measured bottlenecks justify it, propose bounded reductions in tiny shadow casters, repeated decorative instances, distant signs or out-of-stage effects. Keep gameplay geometry, warning readability and original-art approval intact; retest before adoption.

No new runtime/rendering pass is claimed. The launch's 30+ FPS minimum-phone, hub memory, human composition and physical-device requirements remain open.


## Appendix: actual post-Victory client snapshot

After frozen-build HumanBot seed 1101, root ran Studio's scene-analysis APIs and saved [m2-post-run-scene.json](evidence/m2-post-run-scene.json). This is a **single post-Victory client snapshot** for source `9f29012`; it includes test-only scripts plus Studio/core objects. It updates the evidence inventory without converting the preceding source review into a device or renderer certification.

| Query | Observed result | Limit |
|---|---|---|
| Instance composition | 3,427 instances, including 2,570 Parts, 60 Models, 24 SurfaceGuis, 21 PointLights and six ParticleEmitters | Client-wide classified inventory, not a world-folder-only count or bytes-per-instance estimate |
| Unparented instances | 52 total | One observation cannot establish growth, duration or a production leak |
| Audio memory | 3,575,422 bytes | Includes core/character sounds and game channels; not total experience memory |
| Animation memory | 0 reported by this query | Does not imply exported pose tables or procedural animation have no Luau memory cost |
| Script memory | Unavailable: query requires `STUDIOPLAT37936` flag | No flag/settings changes were made; missing value is not zero |
| Triangle composition | One opaque draw call and twelve triangles | Inconsistent with the populated world inventory; not representative world-rendering evidence |

The unparented breakdown attributes 39 Models to the test-only HumanBot script, two Tweens to CombatHUD, one Tween to Main and ten remaining objects to Roblox's PlayerModule paths. HumanBot's source retains per-enemy tell entries keyed by model, consistent with the reported test-only model retention. The driver is excluded from both production project trees. This finding must not be labeled a production model leak. The three game-script Tweens need later timing/ownership observations before claiming either a leak or complete cleanup.

The snapshot also reports two Atmospheres, two BloomEffects, one DepthOfFieldEffect, one SunRaysEffect, one ColorCorrectionEffect and one Sky. The source builder owns only its named effects; this broader inventory includes other scene/core context. Exact ancestry and lifetime of the additional effects were not inspected here. Likewise, client-wide 24 SurfaceGuis and 21 PointLights are not a contradiction of the narrower WorldBuilder-only counts above.

Retain the scene artifact beside the source-derived inventory. Future memory assessment needs comparable before/peak/after snapshots and post-cleanup intervals, ideally without test-driver retention. The one-cube rendering result cannot establish draw-call budget, geometry cost, scene visibility or minimum-phone FPS. The original device, render and growth gates remain open.


### Actual isolated lifetime fixture

Root ran `tests/WorldLifetime.spec.lua` in an isolated Studio server Play session **after the frozen five-bot comparison**, with encounter status Waiting and no enemies. It rebuilds the authored city, stresses all 34 current props without yielding between break calls, checks the immediate 30-fragment cap and nonphysical/server-owned fragments, waits for cleanup and validates every saved part/light/emitter property after restoration. It also checks that repeated breaks do not reschedule already broken props.

The second phase breaks an old-world prop, rebuilds the city, gives its replacement sentinel properties and waits past the old 20-second restore deadline. The replacement must retain its sentinels. Repeated full Build + DressWorld calls must keep class/descendant/prop counts and exactly one of each named Lighting effect. The test leaves an undamaged rebuilt world, including on assertion failure. It does not count unparented objects, measure memory growth or exercise rendering. Actual results below supersede the prior prepared/not-run status; the source-review and device limits remain unchanged.

Root saved [world-lifetime.json](evidence/world-lifetime.json): **PASS** on gameplay source `9f29012`, fixture `8ea45a8`, elapsed 41.1873 seconds. All 34 assemblies were exercised; immediate debris peak was exactly 30, cleanup took 1.5402 seconds and restoration 20.0564 seconds. Saved property restoration, repeated-break rejection and old-world restore isolation all passed. Repeated Build + DressWorld kept 2692 descendants and 34 props: 2531 Parts, one SpawnLocation, 58 Models, 20 Folders, 22 SurfaceGuis, 22 TextLabels, 20 PointLights, three ParticleEmitters, three Attachments and twelve SpecialMeshes. These are fixture world counts, not the broader post-Victory client inventory.

World independently read the saved output, and presentation independently reviewed its scoped result. This establishes the tested structural/property/cleanup behavior for the current 34-prop world. It does not establish absence of memory growth, unparented retention, visible rendering, sustained peak budgets or minimum-phone performance.
