# Reference ledger

Researched 2026-09-23. Sources below inform design; they are not bundled game assets or permission grants. Distinguish observations, our interpretation and unverified references.

## Jujutsu Kaisen — primary source

[Official Shibuya Incident timeline](https://jujutsukaisen.jp/shibuyaincidentnow/timetable.php)

The official timeline locates a curtain around the Shibuya department-store area, teams near Exit 13, the restaurant avenue and the station's new south entrance. Later entries use station platforms, connecting passages and Dōgenzaka locations. Those named spatial transitions support the crossing-to-shopping-street-to-station route. The game compresses geography into three adjacent combat stages; it is not a geographically accurate recreation. Names and incident context are canon references. The relay-seal evacuation mission is authored fiction.

Design interpretation: preserve commercial density, readable transit markers, nighttime threat and the everyday-city/supernatural-barrier contrast. Use original signs and geometry instead of embedding anime frames or reproducing a scene shot for shot.

## Bare Knuckle / Streets of Rage — primary sources

[Streets of Rage 4 official site](https://www.streets4rage.com/)

The official site links the game's platform releases, gameplay/art development diaries and credits. Its Japanese listing uses the Bare Knuckle IV title, grounding the Bare Knuckle / Streets of Rage naming connection. It serves as a route to developer materials, not proof that every requested “Fist of Fury” title is the same game.

[Streets of Rage 4 publisher storefront](https://store.steampowered.com/app/985890/Streets_of_Rage_4/)

The publisher describes cooperative street fighting and advertises online/local co-op support. The reference informs a compact, authored stage campaign and repeated cooperative encounters. The game combines this stage structure with Smash-style launching; it is not a copy of Streets of Rage's exact combat rules.

Research limitation: the title “Fist of Fury” can refer to multiple games. No unsupported claim about a specific matching title or exact level was used. The user's explicit description—left-to-right beat-em-up—is the controlling design direction.

## User-provided experiential benchmarks

- **Super Smash Bros.**: user's requested core combat inspiration. Design interpretation: directional attacks, launch pressure, recovery and readable hit feedback within PvE encounters. Do not silently interpret it as competitive stock matches replacing the requested cooperative campaign.
- **Jujutsu Shenanigans**: user's requested Roblox quality benchmark. This ledger does not claim a live build review, asset extraction or a verified parity assessment. Comparative playtesting is a required quality step.
- **Naruto, One Piece, Demon Slayer**: requested crossover roster sources. Preserve distinct character combat identities and story personalities. The reference list is not an asset inventory; actual game character names and implementation status belong in the roster configuration and release notes.

## Implementation provenance

The city in `src/server/WorldBuilder.lua` is original procedural geometry and authored typography using Roblox Parts, SurfaceGuis, lights and post-processing. There are no downloaded anime background images, commercial soundtrack files or imported map models in that module. Toolbox adoption for combat/VFX/animation/movement is tracked separately by the integration owner so evidence of insertion, creator attribution and actual use remains auditable.

## Jujutsu Shenanigans — current primary listing check
[Official Roblox experience listing](https://www.roblox.com/games/9391468976/Jujutsu-Shenanigans), checked 2026-09-23, advertises a melee combo, four skills, dash/stun escape, block, special, sprint/obstacle avoidance and awakening, and identifies destruction as a design focus. This is evidence of advertised controls/features, not a hands-on feel assessment. The present slice has a smaller action set and a directed PvE route; awakening and parkour are not claimed implemented. Our quality criteria remain control response, readable attack identities, layered feedback and meaningful destruction.
