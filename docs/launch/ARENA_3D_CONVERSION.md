# Controlled 3D arena conversion

## Current owner correction: WO-3D.2 (scoped Studio checks passed; human validation open)

The owner clarified that the camera should be the normal rotatable Roblox third-person camera. The fixed elevated camera documented below was an incorrect interpretation and is superseded, not discarded history. Root/presentation own native `CameraType.Custom` / Classic follow configuration; official reference: [Roblox camera documentation](https://create.roblox.com/docs/workspace/camera). None of the previous fixed-camera tests certifies the orbit camera.

World geometry now uses72stud arena depth (Z=-36..36), unchanged44/44/44/40 widths and the same12 controlled gates. The physical floor is80deep with76deep finishes; side boundaries have innerfaces+/-37. New perimeter solids remain beyond legalZ+/-36 and provide visible, queryable camera occluders; invisible high gameplay boundary parts have query disabled. One actual native perimeter-collision probe passed; all-angle and physical device checks remain. No midfloor navigation obstacles were added.

The city gains four volumetric front shop buildings, return walls and rear service alleys; the station gains a full front concourse wall, columns, roof strips, shuttered bays and platform returns opposite the preserved rear trains; the factory gains a front service hall, columns, front/rear pipe runs, outside-floor gantry supports and high cosmetic overhead steel. Signs have readable Front and Back faces. Existing rear art shifts30studs from its original coordinates, foreground apron detail26studs, and34 whole breakable assemblies26studs toward their original edge (~Z+/-38). Three scenic pumps now sit at Z=-51/-50/-54. Existing asset IDs are retained; new surrounds are native parts with no imported scripts.

`WorldArenas.spec.lua` was updated to check expanded depth,12gates/48anchors/34props,12pump proxy boxes, front/rear camera-occluding solids for every district, no new solid inside the legal floor, and a350part upper bound for the new surround folder. Actual isolated Studio execution passed:224surround parts and86camera occluders, plus the listed gate/entry/prop/pump checks. Orbit-angle images, camera wall collision, normal movement/aiming/tells, co-op gate/rescue, device performance and balancing remain root/human validation. Previous775x356 captures also showed the percent/style overlay competing with actor labels and persistent touch controls; that readability issue remains open until a new actual view is checked.

### Reported camera visibility boundary

The client sends its current camera frame/FOV/aspect at5Hz (nominal200ms intervals). The server rate-limits reports to at most10Hz and uses only the last accepted view for up to0.8seconds, tied to the current character life. Validation requires finite orthonormal camera geometry, bounded FOV40-100/aspect0.4-4, camera within40studs of the local character, and that character inside the reported frame. At each check, the NPC root must be inside that frame with a0.5-stud margin and unobstructed by the authored surrounds, closed gates or physical floor. Invisible movement barriers are explicitly excluded from this ray filter.

Visibility is symmetric for player/NPC hits: an NPC hidden from a player's accepted view can neither damage nor be damaged by that player. Light, Heavy, Special and Desperation also require a fresh accepted view before their costs/cooldowns begin; movement and escape remain available. Server hitboxes, cooldowns, damage and reward rules still resolve combat. Missing or stale view data cannot grant unilateral offensive damage.

**This is a bounded last-reported-view policy, not camera attestation or an anticheat certification.** A view can lag a rapid camera turn by sampling/network delay, and the server cannot prove what an untrusted client actually rendered. A client-controlled view still affects combat eligibility, even with symmetric checks. This does not prove zero offscreen hits in every actual rendered frame, latency fairness, or resistance to all client manipulation. Actual native-camera, timing, co-op and visibility fixtures must state their scope separately; the previous fixed-camera frustum results cannot close these gates.

## Current save and actual validation

Saved source: c531638; campaign and hub rebuilt from that committed snapshot.

Open [CurtainBreak-ThirdPerson.rbxl](../../places/CurtainBreak-ThirdPerson.rbxl) after closing the older open copy. Press Play, choose a hero, click the game viewport and Ready. Hold right mouse and drag to rotate; scroll to zoom. WASD follows the camera. The canonical CurtainBreak.rbxl and CurtainBreak3D.rbxl are refreshed aliases. An already-open Studio place does not reload changed disk contents automatically.

Scoped current checks:72camera geometry,12receipt lifecycle,190relative movement,11native configuration. Actual client confirmed Custom camera/Humanoid subject/zoom8-28 and no presentation transform overwrites. Four scripted headings moved10.31-10.69studs with native follow error0.002-0.024studs. A CityCornerShop perimeter probe reduced native distance16to10.555studs at playerZ34, with the near-plane center line unobstructed. Initial fixture incorrectly tested camera origin; corrected to actual near-plane center. This is one wall/angle, not whole-plane or all-angle certification.

The actual Main reporter/server fixture passed front/back visibility swaps after180degree camera rotation, visible/offscreen hit eligibility in both directions, stale incoming/outgoing rejection, stale Special with no cooldown cost, refresh resume and camera cleanup. Its camera orientation is scripted; physical mouse/controller/touch gestures remain unverified. The scripted full route passed12areas/9traverses/2district transfers in74.8969seconds, clearing enemies and relocating the party deliberately. It is not a full human combat/co-op test. All83production campaign sources matched the tested tree with zero compile errors; IP gate261files/zero hits.

See [native-third-person-validation.json](evidence/native-third-person-validation.json) and [native-third-person-build.json](evidence/native-third-person-build.json) for exact scope and saved source provenance. Human combat feel, physical co-op rescue/retry, compactHUD readability, device performance and existing launch gates remain open. The earlier fixed-camera figures below are preserved history.

## Preserved WO-3D.1 fixed-camera prototype


Owner-directed scope change, 2026-10-02. Source implemented and scoped Studio checks executed; playable campaign and hub rebuilt from source commit0ad61cc. This is a prototype, not launch acceptance. Root owns Config/camera and all Studio runs; combat owns XZ hit logic, AI and encounter transitions; world owns geometry; presentation owns camera application, controls and visible tells.

## Play space and progression

Each existing district retains its theme and 180-stud route: Ashgate city, abandoned station, abandoned factory. Its four areas are now **enemy group, enemy group, miniboss, boss**. The old second-area miniboss and third-area escalation swap positions while retaining their enemy identities/budgets. This supersedes the prior side-view route ordering; old reports describe the previous game and are not new arena tuning evidence.

Config owns each `wave.Bounds={MinX,MaxX,MinZ,MaxZ}`. X starts at `stage.MinX+4+(area-1)*44`; its end is `min(start+44,stage.MaxX-4)`. Widths are44/44/44/40, depth48 at Z=-24..24. `Center` is the midpoint at Y4; `SpawnX` is center+6, `EntryX` is left+6, and checkpoint is left+8,Y4,Z0. Combat applies its additional actor inset. Root owns exact camera distance/framing; the world never writes Camera.

The continuous physical floor is56studs deep, with city/station/factory finish layers52deep. Side barriers at Z+/-26 have inner faces+/-25; low rails and bollards identify the perimeter. Three static district entrance walls have their inner face at districtMinX+4. District transitions retain server relocation after rally, so these walls need not open.

`NightfallCity.Gates.Stage{stage}_Area{area}` is one anchored BasePart per exit, X=Bounds.MaxX, thickness1, height48, depth52. Centering the barrier on the shared boundary keeps its faces away from both areas' actor-inset positions; the initial one-sided thickness2 proposal was corrected after the first isolated geometry check and before play validation to avoid clamp/collision overlap. Gates start closed (`CanCollide=true`, `Opened=false`, transparency.82). EncounterService alone opens cleared exits and recloses the prior gate when all living players reach the next area's EntryX. During traversal combat temporarily permits the current/next rectangle union; next combat locks the next cell. Changing visual transparency alone is insufficient: physical collision and authoritative bounds must agree. Gate fixtures must cover retry, empty lobby and district transition.

Enclosure intentionally prevents launches through closed gates and outer walls. Percent-threshold knockouts still work; historical horizontal blast-zone deaths must not be assumed equally available. Validate fights and stocks before describing the conversion as balanced.

## Geometry and preserved art

All48 entry markers retain `EnemyEntries.StageN_WaveN` and Left/Right/Door/Drop names, now inside the specific arena with6stud margins. Left/right span both X and Z; Door is rear-center at MinZ+6; Drop is Y14 with a floor `LandingPosition`. Combat supplies normal rig root height and entry grace. Service-door scenery is beyond the rear perimeter. No new external assets are imported.

Rear authored architecture/details shift16studs farther back; foreground apron detail beyond Z16 moves12studs outward. The wider perimeter rails are exempt. All34 breakable assemblies move together14studs toward their original front/rear side (~Z+/-26), preserving part offsets, names, tags and restore behavior. They and decorative scenery remain noncolliding. Existing floor paint/scuffs remain cosmetic. Six elite landmark anchors now follow Config's new role locations. Original hero art, city palette pass, station trains and industrial structures are retained. The three post-build scenic pumps in ArtAssetsInstaller move from Z=-23/-22/-26 to -37/-36/-40; their mesh IDs, scale, material and nonphysical properties remain unchanged.

The older M4 candidate table's Z positions are historical until reconciled against this layout; stable IDs must survive that move. Drop/weapon features are not implied by moving breakables. Actual ability to reach/break edge props still needs a play check.

## Scoped validation and remaining gates

Actual isolated Studio checks passed: camera/config2113; combat geometry874; client movement policy64; visual geometry42; downed traversal policy10. Built geometry has12 physical gates,48 inset entry anchors,34 preserved props and12 scenic pump parts outside the combat floor. Actual client specials passed15 heading/hero cases,315 cosmetic parts,3 poses, cap and cleanup; a rotated boss train effect passed its rail/carriage alignment and cleanup check.

The scripted route passed all12 areas,9 within-district transitions and2 district transfers in75.73seconds. It clears enemies and relocates the party deliberately; it is not a difficulty, physical traversal, retry, rewards or co-op run. Its initial failure exposed stale Traverse status during the camera settle; the production transition now publishes Intermission and the next wave before waiting. A downed ally with a live rescue window blocks the rear seal if outside the next cell; pure policy passes, actual co-op rescue at the threshold remains unverified.

Actual client locomotion through the production movement helper passed280 sampled frames and four cardinal movements of8.3905studs each, stopped at the closed X46 inset, and recorded zero camera translation with look-direction dot1. This uses scripted Humanoid.Move input; it does not establish Main/CAS keyboard dispatch or comfort. Injected MCP keys reached input events, but the window was unfocused and the intended focus guard blocked gameplay. The native focus helper could not initialize. Physical keyboard/controller/touch checks remain open.

Five actual Light remote cases hit forward targets while leaving rear/lateral targets untouched. The final dash fixture initially failed despite server acceptance; its correction and rerun are recorded in the evidence file. See [arena-3d-validation.json](evidence/arena-3d-validation.json) for exact results and failure history. StudioSmoke and EnemyMoves regressions passed.

Full human fights, physical co-op arrivals/revive/retry, camera transition readability, edge-prop reachability, ordinary enemy tells, device/performance and existing launch gates remain open. No historical side-view bot result certifies this layout. Legacy flank and rear-entry observer labels still use world X and must not be reported as new relative-facing metrics.

## Preserved prior direction

The original controlled side-view beat-em-up route, per-district continuous lane, third-area escalation and broad camera chase remain design history, not deleted ideas. Their saved images, HumanBot difficulty failure reports and tuning notes are preserved. The owner now requested a real3D arena experience; none of those earlier runs certify this new geometry, order or combat model.

## Historical WO-3D.1 save instructions

Open [CurtainBreak3D.rbxl](../../places/CurtainBreak3D.rbxl) in Studio and press Play. The world is generated when simulation starts; Edit mode begins empty. Choose a hero, click into the game viewport, then press Enter or READY. The canonical [CurtainBreak.rbxl](../../places/CurtainBreak.rbxl) is byte-identical. [CurtainBreak-SideView.rbxl](../../places/CurtainBreak-SideView.rbxl) preserves the previous artifact for comparison. Build provenance and SHA256 hashes are in [arena-3d-build.json](evidence/arena-3d-build.json). Both campaign and hub were rebuilt; live teleport validation is still pending.

The current compact Studio viewport still crowds hero space with HUD elements. This is a testable direction, not a visual-polish or launch-ready acceptance. Next work order is WO-3D.2: hands-on Normal fights and physical co-op gate/rescue/retry checks, followed by measured tuning and HUD polish.
