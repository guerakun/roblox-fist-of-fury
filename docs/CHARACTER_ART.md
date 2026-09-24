# Character art implementation notes

`CharacterFactory.lua` builds canonical R6 body parts and joints, original native face/clothing details, and the reviewed mesh references in `Shared/CharacterArt.lua`. The face art is drawn from native SurfaceGui shapes, not downloaded face decals or imported whole-character scripts.

## Identity details

- Naruto: blue iris/pupil/glint eyes, three whisker marks per cheek, layered orange/navy sleeves and cuffs, raised collar and zipper pull, jacket back seam/crest, and rear headband ribbons.
- Luffy: warm dark eyes, grin and under-eye stitches, chest scar, vest buttons/back/side seams, skin shins and simple sandals beneath the existing reviewed hair/straw-hat meshes.
- Tanjiro: burgundy irises, forehead scar, native earring sun/ray motifs, checked haori front/back and sleeve front/back/outer surfaces, white collar, cuffs/hands, leg wraps, and sword binding/guard.

The reviewed mesh IDs, texture IDs, native mesh scales, and attachment offsets in `CharacterArt.lua` were preserved. World mesh/material installation was reviewed without modification.

## Rig and combat invariants

All seven body parts and six canonical Motor6D joints retain their original sizes and C0/C1 transforms. Imported meshes and authored cosmetic parts are massless, unanchored, welded to their owning body part, and `CanCollide=false`, `CanTouch=false`, `CanQuery=false`. The core body parts remain queryable. This prevents extended scabbards, hats, hair, or sleeve ornaments from enlarging the combat target. Cosmetic SurfaceGuis die with the parent part/model during respawn or hero replacement.

Expected live BasePart counts with current mesh definitions: Naruto **26**, Luffy **26**, Tanjiro **52**. The factory records the actual total as `CharacterPartCount` for Studio verification. Fallback geometry also remains below the 80-part target. No per-frame scripts run inside the face or clothing art. SurfaceGuis have a 110-stud maximum render distance.

## Verification still required in Studio

Check front/side/back screenshots under actual stage lighting, hair and hat occlusion, seams during imported R6 motion, sword attachment during attacks, and respawn cleanup. Confirm three actual `CharacterPartCount` values and exactly seven queryable rig parts per hero. Four-player/mobile rendering of the extra face/clothing SurfaceGuis still needs a device pass; the part count alone does not prove frame-time quality.