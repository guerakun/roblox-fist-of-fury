# Original character art contract

Launch work orders WO-1.1–1.3 replace the retired hero identity, external mesh set and recognizable outfit motifs. This document records the approved design direction; source completion and runtime evidence are tracked in PROGRESS.md. Candidate display names remain pending owner approval.

| Stable ID | Candidate display name | Original silhouette | Special language |
|---|---|---|---|
| Gale | Rook Calder | Silver-teal undercut; cropped charcoal track jacket with amber piping; fingerless wraps; forearm wind ribbons | CYCLONE DRIVE: corkscrew kick, ribbons and directional gust |
| Piston | Bo Marlowe | Curly dark hair; welding goggles; teal mechanic overalls; red work gloves; oversized brass/steel gauntlet | RECOIL CANNON: mechanical fist, chain/piston extension, steam and recoil |
| Tide | Isla Veyra | Long navy ponytail; coral clip; deep-sea blue coat with white foam trim; glaive | UNDERTOW ARC: rotating blade and water crescent |

Native authored parts are the first choice. No external character meshes are approved for the new cast. Any future generated asset must be recorded in ASSET_REGISTER.md with its actual ID and provenance. Per-hero labels, tips, colors and move names come from Config.Characters; stable IDs do not change when a display name changes.

## Rig and combat invariants
Seven body parts and six canonical Motor6D joints preserve compatible R6 transforms. Cosmetic geometry is massless, welded, unanchored, non-colliding, non-touchable and non-queryable. The core body parts remain queryable. Hair, coat, gauntlet and glaive must not enlarge the combat target. Cosmetic SurfaceGuis die with their owning character; no per-frame art scripts are placed inside a rig.

## Acceptance evidence still required
- Root captures one silent gameplay screenshot per hero, plus front/side/back inspection under stage lighting.
- A reviewer who did not author the art checks each silhouette for recognizable external likeness.
- Record actual CharacterPartCount and queryable-body count; old prototype counts are not measurements of these replacements.
- Inspect seams, weapon attachment, pose transitions, special footprint coverage, respawn cleanup and four-player overlap.
- Test real-device frame time and mobile readability. Native parts alone do not prove low rendering cost.
- Owner approves names and art before M1 closes.

## Preserved (retired) ideas
The earlier cast used imported character hair/accessories with recognizable face and outfit motifs. Those assets and identifying motifs are retired completely. Keep the readable three-role silhouette, native face-expression workflow and cosmetic/query separation. Historical asset details remain in Git history; they are not current inventory or publication candidates.


## Actual capture review and OriginalCast2 readability pass

Root restored Studio rendering and saved actual OriginalCast1 player-rig inspection images: [Gale](launch/evidence/hero-gale-actual.jpg), [Piston](launch/evidence/hero-piston-actual.jpg) and [Tide](launch/evidence/hero-tide-actual.jpg). These deliberately use a close inspection camera with hidden HUD; they are not silent screenshots at the ordinary gameplay camera distance. Independent world review found no obvious prohibited signature in those visible angles, without treating one angle as exhaustive likeness clearance. Piston has the strongest brass/goggle versus teal contrast. Gale's torso and flat hair cap lose depth; Tide's dark coat and unclear glaive head lose definition. Guard poses obscure some face/torso details. Owner art approval and a claim of peer-quality polish remain open.

Presentation's OriginalCast2 source increases side-visible values: Gale gains a broad lighter courier yoke and rounded, staggered swept hair; Piston's teal/brass palette lifts modestly; Tide gains a lighter mantle, brighter blue coat, larger coral tie/clip and a thicker, wider angled glaive head. These target the actual side-camera observations rather than adding tiny front-only detail. Expected part counts are Gale36/Piston44/Tide40, from one additional cosmetic each for Gale and Tide. Independent source review confirms the same seven queryable core parts and six motors, with additions using the existing welded/massless/noninteractive detail helper and no external assets. Root subsequently measured36/44/40 parts, seven queryable core parts and six motors per hero with zero external meshes, and captured all nine views recorded below. Front/back/neutral and ordinary gameplay/action inspection must still check clipping, attachment and distant readability.

OriginalCast1's dark palettes, flatter hair arrangement and thinner blade remain a preserved iteration in Git and the linked captures; OriginalCast2 supersedes their current source geometry without changing hero identity or combat dimensions.


### OriginalCast2 actual image review

World independently viewed all nine root Studio captures on2026-09-24. Front/back use the actual selected player rig, a close camera and a neutral motor pose override solely for inspection. Normal views preserve production camera and idle pose with HUD hidden in the Waiting street; they are not combat captures. [The evidence index](launch/ORIGINAL_ART_EVIDENCE.md) links every view.

The broader shoulder values improve Gale and Tide against the dark road. Gale's brighter rounded crest and amber details are visible in neutral views, though the hair still reads as a shallow cap from some angles. Piston retains the clearest goggles/brass-gauntlet contrast and distinct warm accent. Tide's ponytail/coral tie, split coat and larger blade are clearly separable front/back; the blade remains a broad rectangular, somewhat paddle-like silhouette rather than a finely shaped glaive. These are visible improvements, not a final-quality claim.

At the supplied775px-wide normal-camera images, heroes occupy roughly45px in height. Large palette and weapon/gauntlet cues survive; face, trim and material details largely disappear. Bright cyan windows and the crossing dominate scene contrast. Combat movement, hit flashes, multiplayer crowding and physical mobile viewing may change that balance and remain untested by these stills. No obvious prohibited signature appears across the reviewed angles. Owner names/art approval and exhaustive likeness, pose-clipping and gameplay readability acceptance remain open.
