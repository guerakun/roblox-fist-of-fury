# Curtain Break — Fist of Fury

An original anime-styled Roblox co-op beat-em-up along the controlled streets of Ashgate. Bare Knuckle / Streets of Rage encounter pacing meets Smash-inspired rising damage, launch strength, recovery and three stocks.

**Status: playable three-stage development campaign.** It has not been certified for public launch. The active launch program, evidence and open gates are in [LAUNCH_PLAN](docs/launch/LAUNCH_PLAN.md) and [PROGRESS](docs/PROGRESS.md). See [validation](docs/VALIDATION.md) and [publication readiness](docs/PUBLISH_READINESS.md).

## Play
Open [places/CurtainBreak.rbxl](places/CurtainBreak.rbxl) in Roblox Studio and press Play to generate the world. Choose a hero, then press Enter / READY. Every connected player must ready up.

- A/D move, W/S lane depth, Space jump / double jump.
- Mouse1 or J light combo, K heavy launcher, L special.
- Q dash, F hold block, E recovery.
- 1 Rook Calder (Gale), 2 Bo Marlowe (Piston), 3 Isla Veyra (Tide) in safe areas. Candidate display names await owner approval.
- P opens chapter rewards, coin cosmetics and earned boons; O opens settings.
- Clear each encounter and move right together to the next rally marker.
- Party wipe offers checkpoint retry. Clear the factory boss to finish.

Touch buttons and gamepad bindings are included; full controls are in [CONTROLS](docs/CONTROLS.md). Intended party size: 1–4.

## Campaign
| Stage | Setting | Miniboss | Boss |
|---|---|---|---|
| 1 | Ashgate Crossing | Crosswalk Executioner | Siren Marshal |
| 2 | Abandoned station | Platform Widow | The Last Conductor |
| 3 | Abandoned factory | Furnace Hound | Kiln Sovereign |

Each stage has four encounters: skirmish, miniboss, skirmish, boss. Gates and rally points keep the play space controlled. Miniboss clears establish checkpoints. Elite attacks have distinct telegraphs, punish windows and second phases.

## Implemented systems
Server-authoritative hit validation, percent knockback, stocks and recovery; three hero kits; party-ready and checkpoint flow; bounded lane camera/movement; boss and party HUD; 34 destructible props; reviewed Toolbox animation, movement, VFX and hitbox ingredients; original generated factory props and station materials.

Original hero-art replacement is underway in the launch program; see its current evidence status before judging the cast.

The chapter journal includes earned coins, a 12-tier evergreen reward track, cosmetic trails/titles and free earned combat boons. Live sales are disabled. Studio progress is practice-only by default. Read the [monetization design](docs/MONETIZATION.md).

## Build from source
Install [Rojo](https://rojo.space/docs/v7/getting-started/installation/) 7.7.0:
```sh
mkdir build
rojo build default.project.json -o build/CurtainBreak.rbxlx
rojo serve default.project.json
```
The committed place is built from the latest source and creates the world on simulation start; its Edit view starts empty. The earlier editable-world milestone is retained in Git history. Connect the Studio Rojo plugin for source editing. No runtime HTTP dependency is required. Toolbox animations are serialized R6 keyframes.

## Latest focused review
[Camera fix and measured regression results](docs/CAMERA_REGRESSION.md) · [Bare Knuckle III timestamped gameplay comparison](docs/research/BARE_KNUCKLE_3_VIDEO_REVIEW.md). The comparison remains a dated baseline audit. Approved v1 work is selected in the launch plan; other reference mechanics remain deferred.

## Project memory
[Design](docs/DESIGN.md) · [World bible](docs/WORLD_BIBLE.md) · [Story](docs/STORY.md) · [References](docs/REFERENCES.md) · [Assets](docs/ASSET_REGISTER.md) · [Combat](docs/COMBAT.md) · [Character art](docs/CHARACTER_ART.md) · [Economy](docs/MONETIZATION.md) · [Progression contract](docs/PROGRESSION_CONTRACT.md) · [Quality review](docs/QUALITY_REVIEW.md) · [Roadmap](docs/ROADMAP.md)

Original names, silhouettes and specials are required for launch. Owner approval of candidate names/art and final-universe asset access remain open gates. No reference-game footage or soundtrack is bundled.

## Historical evidence
Earlier local co-op observations remain in [VALIDATION](docs/VALIDATION.md). Retired-character screenshots were removed from current public materials; the historical revisions remain in Git. Fresh original-cast gameplay captures are required before M1 closes.
