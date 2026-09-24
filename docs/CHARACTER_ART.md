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
