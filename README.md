# Curtain Break — Fist of Fury

An original anime-styled Roblox co-op beat-em-up across controlled 3D arenas in Ashgate. Bare Knuckle / Streets of Rage encounter pacing meets Smash-inspired rising damage, launch strength, recovery and three stocks.

**Status: three-stage 3D arena prototype; scoped engineering checks, human play validation pending.** It has not been certified for public launch. The active launch program, evidence and open gates are in [LAUNCH_PLAN](docs/launch/LAUNCH_PLAN.md) and [PROGRESS](docs/PROGRESS.md). See [validation](docs/VALIDATION.md) and [publication readiness](docs/PUBLISH_READINESS.md).

## Play
Open [places/CurtainBreak-ThirdPerson.rbxl](places/CurtainBreak-ThirdPerson.rbxl) in Roblox Studio and press Play to generate the world. Choose a hero, then press Enter / READY. Every connected player must ready up.

- Hold the right mouse button and drag to rotate the camera; use the scroll wheel to zoom. A short right-button tap requests Heavy.
- WASD moves relative to the camera across the full arena floor; equal cardinal speed and normalized diagonals. Space jumps / requests air recovery.
- Left mouse button light combo; right mouse tap heavy launcher; E hero special. J / K / L remain Light / Heavy / Special aliases.
- Q dash, F hold block, Space ground jump / air recovery.
- 1 Rook Calder (Gale), 2 Bo Marlowe (Piston), 3 Isla Veyra (Tide) in safe areas. Candidate display names await owner approval.
- P opens chapter rewards, coin cosmetics and earned boons; O opens settings.
- Clear each enclosed area to open its exit, then move right together to the next rally marker. Each district has two enemy groups, a miniboss and a boss.
- Party wipe offers checkpoint retry. Clear the factory boss to finish.

Touch buttons and gamepad bindings are included; full controls are in [CONTROLS](docs/CONTROLS.md). Intended party size: 1–4.

## Campaign
| Stage | Setting | Miniboss | Boss |
|---|---|---|---|
| 1 | Ashgate Crossing | Crosswalk Executioner | Siren Marshal |
| 2 | Abandoned station | Platform Widow | The Last Conductor |
| 3 | Abandoned factory | Furnace Hound | Kiln Sovereign |

Each stage has four enclosed arenas: enemy group, enemy group, miniboss, boss. Physical gates and server bounds control progression. Miniboss clears enable the final-area party retry checkpoint unless No Safety Net is selected; an individual stock respawn uses the current area. Elite attacks have distinct telegraphs, punish windows and second phases.

## Implemented systems
Server-authoritative hit validation, percent knockback, stocks and recovery; three hero kits; party-ready and checkpoint flow; normal rotatable third-person camera and camera-relative XZ movement; boss and party HUD; 34 destructible props; reviewed Toolbox animation, movement, VFX and hitbox ingredients; original generated factory props and station materials.

The original hero rigs and specials are implemented; candidate names/art still require owner approval. The current owner correction uses Roblox's normal rotatable third-person camera and expanded72-stud-deep arenas with scenery on both sides. The 3D conversion changes combat geometry and encounter order. See [conversion scope and evidence](docs/launch/ARENA_3D_CONVERSION.md); earlier side-view tests do not certify this version.

The chapter journal includes earned coins, a 12-tier evergreen reward track, cosmetic trails/titles and free earned combat boons. Live sales are disabled. Studio progress is practice-only by default. Read the [monetization design](docs/MONETIZATION.md).

## Build from source
Install [Rojo](https://rojo.space/docs/v7/getting-started/installation/) 7.7.0:
```sh
mkdir build
rojo build default.project.json -o build/CurtainBreak.rbxlx
rojo serve default.project.json
```
The place creates the world on simulation start; its Edit view starts empty. Confirm its recorded source revision in the latest progress/build evidence before comparing it with source edits. The earlier editable-world milestone is retained in Git history. Connect the Studio Rojo plugin for source editing. No runtime HTTP dependency is required. Toolbox animations are serialized R6 keyframes.

## Latest focused review
[Controlled 3D conversion](docs/launch/ARENA_3D_CONVERSION.md) records the current arena/camera contract and scoped tests. Hardware input, full human combat, co-op rescue/travel, retry and performance remain separate checks.

Historical side-view work: [Camera fix and measured regression results](docs/CAMERA_REGRESSION.md) · [Bare Knuckle III timestamped gameplay comparison](docs/research/BARE_KNUCKLE_3_VIDEO_REVIEW.md). The comparison remains a dated baseline audit. Approved v1 work is selected in the launch plan; other reference mechanics remain deferred.

## Project memory
[Design](docs/DESIGN.md) · [World bible](docs/WORLD_BIBLE.md) · [Story](docs/STORY.md) · [References](docs/REFERENCES.md) · [Assets](docs/ASSET_REGISTER.md) · [Combat](docs/COMBAT.md) · [Character art](docs/CHARACTER_ART.md) · [Economy](docs/MONETIZATION.md) · [Progression contract](docs/PROGRESSION_CONTRACT.md) · [Quality review](docs/QUALITY_REVIEW.md) · [Roadmap](docs/ROADMAP.md)

Original names, silhouettes and specials are required for launch. Owner approval of candidate names/art and final-universe asset access remain open gates. No reference-game footage or soundtrack is bundled.

## Historical evidence
Earlier local co-op observations remain in [VALIDATION](docs/VALIDATION.md). Retired-character screenshots were removed from current public materials; the historical revisions remain in Git. Original-cast captures are documented in [art evidence](docs/launch/ORIGINAL_ART_EVIDENCE.md); owner approval and representative 3D combat readability remain open.

The earlier game used a narrow foreground/background lane, a party-following side-view camera, and skirmish/miniboss/skirmish/boss ordering. Those designs and their measurements remain preserved in the dated notes and Git history. The owner superseded them with full XZ arenas on 2026-10-02.

The initial fixed elevated 3D camera was superseded by the owner's normal rotatable third-person request (WO-3D.2). Its earlier fixed-camera evidence is retained as history, not proof of the native camera or expanded surroundings.

WO-3D.3 changes the primary mouse/keyboard combat layout and attack presentation timing. The current source uses server-accepted action timing, a shorter dash with braking, and slower movement during attacks; see [CONTROLS](docs/CONTROLS.md). These changes still require the root-run checks and hands-on feel review recorded in PROGRESS; this note does not claim that animation smoothness or control feel is verified. The previous E recovery / L special primary layout is retained as history.
