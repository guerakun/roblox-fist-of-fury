# Controlled 3D arena conversion

Owner-directed scope change, 2026-10-02. Source implemented and scoped Studio checks executed; playable save is produced by root after the final action check. This is a prototype, not launch acceptance. Root owns Config/camera and all Studio runs; combat owns XZ hit logic, AI and encounter transitions; world owns geometry; presentation owns camera application, controls and visible tells.

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
