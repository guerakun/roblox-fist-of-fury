# Curtain Break — Fist of Fury

A Roblox anime co-op beat-em-up along a controlled, Shibuya-inspired route. Bare Knuckle / Streets of Rage encounter pacing meets Smash-inspired rising damage, launch strength, recovery and three stocks.

**Status: playable three-stage development campaign.** It has not been certified for public launch or Jujutsu Shenanigans-level polish. See [validation](docs/VALIDATION.md), [publication readiness](docs/PUBLISH_READINESS.md) and [progress](docs/PROGRESS.md).

## Play
Open [places/CurtainBreak.rbxl](places/CurtainBreak.rbxl) in Roblox Studio and press Play to generate the world. Choose a hero, then press Enter / READY. Every connected player must ready up.

- A/D move, W/S lane depth, Space jump / double jump.
- Mouse1 or J light combo, K heavy launcher, L special.
- Q dash, F hold block, E recovery.
- 1 Naruto, 2 Luffy, 3 Tanjiro in safe areas.
- P opens chapter rewards, coin cosmetics and earned boons; O opens settings.
- Clear each encounter and move right together to the next rally marker.
- Party wipe offers checkpoint retry. Clear the factory boss to finish.

Touch buttons and gamepad bindings are included; full controls are in [CONTROLS](docs/CONTROLS.md). Intended party size: 1–4.

## Campaign
| Stage | Setting | Miniboss | Boss |
|---|---|---|---|
| 1 | Shibuya city streets | Crosswalk Executioner | Siren Marshal |
| 2 | Abandoned station | Platform Widow | The Last Conductor |
| 3 | Abandoned factory | Furnace Hound | Kiln Sovereign |

Each stage has four encounters: skirmish, miniboss, skirmish, boss. Gates and rally points keep the play space controlled. Miniboss clears establish checkpoints. Elite attacks have distinct telegraphs, punish windows and second phases.

## Implemented systems
Server-authoritative hit validation, percent knockback, stocks and recovery; three hero kits; party-ready and checkpoint flow; bounded lane camera/movement; boss and party HUD; 34 destructible props; reviewed Toolbox animation, movement, VFX and hitbox ingredients; imported hero hair/hat meshes; original generated factory props and station materials.

The chapter journal includes earned coins, a 12-tier evergreen reward track, cosmetic trails/titles and free earned combat boons. Live sales are disabled. Studio progress is practice-only by default. Read the [monetization design](docs/MONETIZATION.md).

## Build from source
Install [Rojo](https://rojo.space/docs/v7/getting-started/installation/) 7.7.0:
```sh
mkdir build
rojo build default.project.json -o build/CurtainBreak.rbxlx
rojo serve default.project.json
```
The committed place is built from the latest source and creates the world on simulation start; its Edit view starts empty. The earlier editable-world milestone is retained in Git history. Connect the Studio Rojo plugin for source editing. No runtime HTTP dependency is required. Toolbox animations are serialized R6 keyframes.

## Project memory
[Design](docs/DESIGN.md) · [World bible](docs/WORLD_BIBLE.md) · [Story](docs/STORY.md) · [References](docs/REFERENCES.md) · [Assets](docs/ASSET_REGISTER.md) · [Combat](docs/COMBAT.md) · [Character art](docs/CHARACTER_ART.md) · [Economy](docs/MONETIZATION.md) · [Progression contract](docs/PROGRESSION_CONTRACT.md) · [Quality review](docs/QUALITY_REVIEW.md) · [Roadmap](docs/ROADMAP.md)

Anime names and likenesses are prototype fan-theme references. Final franchise permissions and published-universe asset access remain production gates. No anime footage or soundtrack is bundled.

## Earlier local co-op smoke test
![Two actual Studio clients in the city](docs/media/coop-studio.jpg)
