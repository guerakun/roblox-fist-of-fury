# Curtain Break launch plan

Prepared 2026-09-23 from a source review of commit `ca00266` (overnight Codex build). Owner decisions: fully original heroes, lobby + matchmaking multiplayer, Bare Knuckle-grade AI, real challenge and risk/reward.

Sections:
1. Where the build stands
2. Milestone map and parallel lanes
3. M1: Original heroes and IP scrub
4. M2: Enemy AI rework
5. M3: Challenge and risk/reward
6. M4: Missing features that fit Roblox
7. M5: Lobby, parties and matchmaking
8. M6: Publish gates
9. Tuning targets and the test bot

---

## 1. Where the build stands

**Solid foundations worth keeping:** server-authoritative combat, percent/launch/stock model, three stages x four encounters, six elites with telegraphed floor mechanics, poise/stagger, co-op ready lobby, stock sharing, reconnect survival cache, session-locked ProfileStore with fake-adapter tests, earned-only economy with sales disabled, 34 destructible props, a documented Toolbox quarantine workflow.

**Launch blockers found in source:**

| Area | Finding | Where |
|---|---|---|
| IP | Hero keys, display names and UI are Naruto / Luffy / Tanjiro. Toolbox meshes are those characters' hair, headband and straw hat. Faces add whisker marks and Tanjiro's forehead scar; outfits copy the orange jacket, open red vest + sash, etc. Stage 1 is "Shibuya", story cites Jujutsu Kaisen. ~80 mentions across docs/src. | `Config.Characters`, `CharacterArt.lua`, `CharacterFactory.lua` L20-200, `Main.client.lua` L24-27 / L414-416 / L491-560, `CombatHUD.lua` L332-334, `docs/STORY.md`, `README.md` |
| AI | Grunts have one move ("CURSE STRIKE"): a floor box painted at windup start that resolves 0.55-1.0 s later. Chase logic walks to `player.X - facing*4` on whatever side the grunt is already on, so enemies conga-line on one side. Enemies without an attack slot call `h:Move(Vector3.zero)` and stand still. Elites cycle a fixed move list regardless of situation. | `CombatService.aiStep` L545-587, `beginEnemyAttack` L495, `EnemyMoves` fallback L93-95 |
| Challenge | Waves are 3-4 enemies (+0.5 per extra player, floored). Max 2-3 enemies may attack at once. Every player hit grants 0.38 s invulnerability, and Dash escapes stun 0.16 s after being hit. Stocks refill to 3 and percent resets to 0 at every district start (`ResetPlayers` -> `resetPosition`). Rewards are flat per encounter. The automated driver cleared all 12 encounters in about 3 minutes and finished the final district on 3 stocks at 50%. | `EncounterService` L141-153, `CombatService` L311, L427, L236-251, L185, `docs/MONETIZATION.md` |
| Multiplayer | Same-server co-op (1-4) exists. No hub, party, matchmaking, teleport, invite flow or return-to-lobby. The 2-4 client campaign harness and stock-sharing conservation tests were written but never executed. | `tests/MultiplayerCampaign.server.lua`, `tests/MultiplayerLifecycle.md`, `docs/PROGRESS.md` |
| Publish | No Maturity & Compliance questionnaire, no badges, no analytics funnel, no onboarding tutorial, live DataStore untested, Chapter Pass not configured. | `docs/PUBLISH_READINESS.md` |

---

## 2. Milestone map and parallel lanes

```
M0 Baseline (root, 0.5 day)
 ├─ M1 Original heroes + IP scrub      (presentation + world)   ── blocks any public test
 ├─ M2 Enemy AI rework                 (combat, presentation for anims)
 │    └─ M3 Challenge + risk/reward    (combat + root)
 │         └─ M4 Launch features       (combat + presentation + world)
 └─ M5 Hub + matchmaking               (root; new files only, runs parallel to M2-M4)
M6 Publish gates (all) after M1-M5
```

### M0: Baseline (root)
- **WO-0.1** Tag `ca00266` as `v0-overnight`. Run every existing spec and record pass/fail in PROGRESS.md.
- **WO-0.2** Build the human-like test bot described in section 9 (`tests/HumanBot.client.lua`). Run the current campaign 5 times solo on it and record clear rate, stocks lost, time, damage taken. This is the "before" number every later milestone compares against.
- **WO-0.3** Add `src/server/CombatTelemetry.lua`: server-side counters for AI idle ratio, flank events, simultaneous windups, hits taken per player, stock losses per encounter. Write a summary JSON at the end of a run in Studio. M2 and M3 acceptance use it.

---

## 3. M1: Original heroes and IP scrub

Renaming alone is not publish-safe. Roblox's [Rights Manager](https://create.roblox.com/docs/production/publishing/rights-manager) lets rights holders find and remove infringing experiences, and franchise-named anime games are the most reported category. We keep the archetypes (rushdown wind fighter, long-reach bruiser, wide-arc swordfighter) and replace everything recognisable.

### Stable internal IDs
Hero keys become `Gale`, `Piston`, `Tide`. Display names live only in `Config.Characters[id].Name` so the owner can rename later without a data migration.

### Candidate heroes (owner must approve names before WO-1.5 closes)

| ID | Name (candidate) | Title | Special | Look direction | Must NOT have |
|---|---|---|---|---|---|
| Gale | **Rook Calder** | GALE RUNNER | CYCLONE DRIVE: a dashing corkscrew kick wrapped in wind ribbons | Silver-teal undercut, cropped charcoal track jacket with amber piping, fingerless wraps, wind ribbons trailing from the forearms | Blond spikes, orange jumpsuit, forehead plate, whisker marks, swirl crest, hand-held sphere |
| Piston | **Bo Marlowe** | PISTON BRAWLER | RECOIL CANNON: an oversized mechanical gauntlet fires its fist forward on a chain and piston | Curly dark hair with welding goggles, one huge brass/steel gauntlet, mechanic overalls in teal with red work gloves | Straw hat, open red vest, yellow sash, sandals, chest X-scar, rubber-limb stretching |
| Tide | **Isla Veyra** | TIDE BLADE | UNDERTOW ARC: a spinning glaive sweep that leaves a water crescent | Long navy ponytail with a coral hair clip, deep-sea blue long coat with white wave-foam trim, a glaive instead of a katana | Checkered haori, hanafuda earrings, forehead scar, black katana, box on back |

Also rename: stage 1 "SHIBUYA STREETS" to **"ASHGATE CROSSING"**; remove every Jujutsu Kaisen citation from STORY/WORLD_BIBLE/README. "Curtain", "curse" and "veil" are generic words and may stay.

### Work orders
- **WO-1.1 (presentation)** Replace hero keys and every hard-coded check (`hero == "Naruto"` etc.) with the new IDs. Move per-hero colours, move names and tips out of `Main.client`/`CombatHUD` and read them from `Config.Characters`. Add a migration so any saved profile or in-memory record with an old key maps to the new one.
- **WO-1.2 (presentation)** Delete the three anime mesh entries in `CharacterArt.lua` and their ASSET_REGISTER rows. Build new hair/outfits: authored parts first, Roblox Studio mesh generation where parts can't carry the silhouette (the pump already proves that workflow). Record every generated asset ID. Remove whisker/scar face shapes; give each hero one original face identifier.
- **WO-1.3 (presentation)** Give each special its own pose and VFX language matching the new fantasy (wind ribbons / piston recoil + steam / water crescent). Server hitbox coverage must match what is drawn.
- **WO-1.4 (world)** Rewrite STORY.md, WORLD_BIBLE.md, README.md, CHARACTER_ART.md, DESIGN.md, QUALITY_REVIEW.md, ASSET_REGISTER.md, PUBLISH_READINESS.md and the Bare Knuckle research note for the original cast. Move old anime-crossover text to a "Preserved (retired) ideas" appendix that names no franchise. Rename stage 1.
- **WO-1.5 (root)** IP grep gate in CI or a test: case-insensitive search across `src/`, `docs/`, `tests/`, `default.project.json`, `README.md` for `naruto|luffy|tanjiro|one piece|demon slayer|jujutsu|shibuya|straw ?hat|hokage|nichirin|haori|gomu`. Must return zero hits outside `docs/launch/**` and `AGENTS.md`. Also reject asset IDs 1453909835, 1453912288, 943796917, 5063791566, 5063791598, 3657762884, 3828742380, 3828765577.

**Acceptance:** grep gate passes; three silent gameplay screenshots, one per hero, attached to PROGRESS.md; a reviewer who did not author the art writes one line per hero confirming no franchise likeness; owner approves names.

---

## 4. M2: Enemy AI rework

### Why it feels dumb (diagnosis)
1. **One grunt move.** Every grunt attack is the same forward box with a floor telegraph. Bare Knuckle grunts have 2-4 behaviours each.
2. **Single-file approach.** Grunts path to the side they already occupy. Nothing assigns positions around the player.
3. **Statues.** Enemies waiting for an attack slot stop moving entirely.
4. **No reading of the player.** Nothing reacts to blocking, heavy windups, airborne players or high-percent players.
5. **Predictable elites.** Fixed move rotation; distance and party layout don't matter.
6. **Static staging.** All enemies appear at once at a landmark. No side entries, no reinforcements.

### Target architecture
New modules (combat owns): `src/server/EnemyAI.lua` (per-enemy state machine), `src/server/AttackDirector.lua` (tokens and slots), `src/shared/EnemyArchetypes.lua` (data). `CombatService.aiStep` becomes a thin loop that calls them.

**AttackDirector (the Bare Knuckle / Streets of Rage 4 trick):**
- Each target player has **engagement slots**: front-near, back-near (flank), front-mid, back-mid, and two lane-offset "waiting" spots 10-14 studs out on the other Z band.
- Enemies request a slot; the director assigns the nearest free one and **prefers filling the side opposite existing attackers**, which produces surrounds.
- **Attack tokens** per target: Normal = 1 per player + 1 (solo 2, quad 5). Only token holders may start a windup. Tokens are returned on attack end, on stagger, or after 3 s.
- Token priority goes to enemies the player isn't facing and to enemies that haven't attacked recently. This is what makes back-attacks happen.

**EnemyAI states:** `Enter -> Approach -> Hold (strafe/feint/taunt) -> Engage (has token) -> Attack -> Recover -> Reposition`, plus reactive interrupts `Evade`, `Block`, `Retreat`, `PickUp`, `Grab`.
- Hold never means idle: strafe in Z, shuffle forward/back 2-4 studs, occasional feint (starts a windup pose, cancels it), taunt when the player is downed.
- Reaction delay per archetype and difficulty (Normal 0.35 s, Hard 0.22 s) before responding to player actions, so reactions feel human, not psychic.

### Archetypes (replace Grunt/Runner/Brute with six behaviours; keep existing models and recolour/re-accessorise)

| Archetype | BK reference | Behaviours | What it teaches the player |
|---|---|---|---|
| **Husk** (brawler) | Galsia | 2-hit jab combo; jump-kick from mid range; picks up dropped weapons | Basic spacing |
| **Strider** (rusher) | Signal slide | Dash-slide across a lane from 12-16 studs, then retreats to mid range; slides under a lane change | Watch the lane, jump the slide |
| **Grappler** | Donovan / Big Ben | Walks through lights with light armor, grabs a blocking player, throws them into other enemies' attacks; an ally hitting the grappler frees you | Don't turtle; co-op rescue |
| **Pitcher** (ranged) | knife-thrower Jack | Keeps 14-20 studs, throws a lane-bound projectile with a 0.4 s shimmer; backpedals when approached; must be on-screen to fire | Priority targeting, chase decisions |
| **Warden** (guard) | kickboxer | Blocks frontal lights, counters the 3rd hit of a light chain; weak to flanks, heavies, grabs | Mix up, use the partner to pincer |
| **Leaper** (acrobat) | Zamza / ninja | Vaults over the player to cross up, attacks from behind; evades 1 in 3 heavies with a backflip | Turn around, bait the evade |
| Brute (keep) | Big Ben | Armored belly-flop AOE, weapon swing | Respect armor, launch after it |

Elites: switch from fixed rotation to **weighted selection** with conditions (distance band, number of players in the danger lane, player airborne, time since last signature). Phase 2 adds: a summon of 2 grunts through a side entry, one new "desperation" move under 20% of threshold, and feint windups.

### Staging
- **Entrances**: every wave definition gets `Entries` (left edge, right edge, background door, drop from above). At least one enemy per wave from behind the party once the player count is 1-2.
- **Pulses**: waves become 2-3 pulses with a spawn budget; the next pulse triggers when alive enemies fall to N or after T seconds.

### Work orders
- **WO-2.1 (combat)** Extract AI to `EnemyAI.lua` + `AttackDirector.lua` with no behaviour change. Existing EnemyMoves spec and a HumanBot run must match baseline within noise.
- **WO-2.2 (combat)** Implement director slots + tokens + non-idle Hold. Grunt telegraphs change from floor boxes to body tells (anticipation pose + short flash); keep floor markers for elites and AOEs only.
- **WO-2.3 (combat + presentation)** Implement the six archetypes and their animations. New moves live in `EnemyMoves` as data. Reuse Toolbox R6 poses where possible; record any new animation source.
- **WO-2.4 (combat)** Elite weighted selection, phase-2 summons, desperation moves, feints.
- **WO-2.5 (combat + world)** Wave entries and pulses; add door/edge spawn markers in `WorldBuilder`.
- **WO-2.6 (combat)** Difficulty profiles in Config: `Aggression`, `TokenBonus`, `ReactionDelay`, `EvadeChance`, `WindupScale`.

**Acceptance (CombatTelemetry over 5 HumanBot runs + 1 human run):**
- Grunt idle ratio (no movement, not attacking/stunned/recovering) under 15% of AI ticks (baseline expected >50%).
- With 2+ grunts on a solo player, at least one grunt on the opposite X side within 5 s in 70%+ of engagements.
- Simultaneous windups never exceed the token cap.
- Each archetype uses 2+ distinct actions per 30 s engaged.
- Zero hits landed by enemies outside the camera frustum; every attack telegraphed 0.30 s+.
- Server heartbeat cost of AI under 1.5 ms average with 12 enemies and 4 players (MicroProfiler capture).

---

## 5. M3: Challenge and risk/reward

### Why there's no tension today
Damage only matters until the next district (stocks refill and percent resets at every district start), nothing rewards playing well (flat coins), and the defensive tools are generous enough that enemies rarely connect. Challenge needs **stakes that persist**, **pressure that's fair**, and **greed that's optional but paid**.

### A. Baseline pressure (Normal difficulty starting points)
| Knob | Now | Proposed start |
|---|---|---|
| Grunt windup | 0.55-1.0 s | 0.38-0.70 s with body tell (Brute keeps 0.9) |
| Grunt cooldown | 1.6-2.3 s | 1.0-1.8 s, gated by tokens |
| Enemies per wave | 3-4 | 5-8 in 2-3 pulses |
| Party scaling | +floor(0.5 x extra players) enemies | +2 enemies per extra player, +1 token per player |
| Post-hit invulnerability | 0.38 s every hit | 0.15 s, plus a **combo breaker**: 3 hits taken in 1.5 s grants 0.8 s invulnerability |
| Dash out of hitstun | free after 0.16 s | costs +8% percent ("Burst"), 4 s cooldown |

### B. Stakes that persist
- **Percent already carries between encounters within a district; make it carry across districts too.** Heals come from food pickups (M4) and a small -15% on district clear instead of the full reset.
- **Stocks don't refill at district start.** District clear gives +1 stock (max 3). Checkpoint retry after a wipe restores 2 stocks each, but resets the score multiplier.
- **Downed and revive** (co-op): at 0 stocks a player is downed for 12 s; a teammate channels 2.5 s beside them (interruptible by hits) to revive at 1 stock, 60%. Keep stock sharing as the instant, costly alternative.

### C. Risk/reward systems (ranked by value for effort)
1. **Style meter and rank.** Consecutive hits without being hit raise a multiplier x1 to x4; getting hit drops one level. Throws into enemies, air juggles, perfect blocks and back-hits add style. End of district: rank D to S from score, par time and damage taken. Rank multiplies coins/XP: C 1.0, B 1.15, A 1.3, S 1.5 (never below 1.0; no punishment for new players).
2. **Heat contracts** (Hades-style, chosen by the party leader in the hub). Each adds reward % and leaderboard score:
   - Frenzy: +1 attack token (+10%)
   - Short Fuse: enemy windups -20% (+15%)
   - Iron Hide: grunts +30% KO threshold (+10%)
   - No Safety Net: no mid-district checkpoint (+20%)
   - One Life: 1 stock, stock sharing disabled, revive still allowed (+35%)
   - Mutated Elites: bosses gain an extra phase-2 move (+15%)
   Heat 5 / 10 / 15 total unlock badges and exclusive cosmetics.
3. **Desperation special** (straight from Bare Knuckle III): if Special is on cooldown, Special + Heavy fires it anyway for +12% self-percent. Clutch power with a real price.
4. **Perfect block**: block within 0.12 s of impact means no chip, a 0.6 s attacker stagger and +1 style level. Rewards reading telegraphs over holding block.
5. **Bounty enemy**: occasionally a Gilded Husk carrying a coin sack appears and flees toward an edge after 8 s. KO it for bonus coins; chasing it drags you away from the group.
6. **Greed drops**: KOs drop score orbs that vanish in 5 s, often in the danger lane.
7. **Trade-off boons** alongside the current pure boons: Glass Cannon (+20% damage dealt, +20% taken), Berserker (double style gain, cannot block), Anchor (+30% weight, no dash).
8. **Difficulty tiers**: Normal, Hard (unlock after first clear), Nightmare (unlock after Hard clear). Tiers change `WindupScale`, tokens, reaction delay and elite HP; Heat stacks on top.

### Work orders
- **WO-3.1 (combat)** Apply table A numbers behind the difficulty profile; add combo breaker and Burst cost.
- **WO-3.2 (combat + root)** Persistent percent/stock rules, downed/revive, retry rules. Update `tests/MultiplayerLifecycle.md` cases 3-5 to the new rules.
- **WO-3.3 (combat + presentation)** Style meter, score, rank screen with multiplier breakdown.
- **WO-3.4 (root)** Rank multipliers in `ProgressionService` with reward-key deduplication intact; tests for forgery and retry farming.
- **WO-3.5 (combat)** Desperation special, perfect block, bounty enemy, greed drops.
- **WO-3.6 (root + presentation)** Heat contracts data, hub selection UI, match record field, badges.
- **WO-3.7 (root)** Trade-off boons.

**Acceptance (HumanBot, section 9):** solo Normal clear rate 60-80% with 2+ stocks lost on average per campaign; Hard 30-50%; Nightmare under 20%. One human playtest per tier recorded. S rank achieved in fewer than 25% of HumanBot district clears. No economy exploit: repeated retries never pay a reward key twice.

---

## 6. M4: Missing features that fit Roblox

Scored from the Bare Knuckle III comparison (`docs/research/BARE_KNUCKLE_3_VIDEO_REVIEW.md`) plus Roblox-specific needs. "Fit" weighs co-op social value, short-session replay, mobile controls, and content cost.

| Feature | Source | Roblox fit | Cost | Verdict |
|---|---|---|---|---|
| **60-second onboarding dojo** | Roblox D1 retention | Very high | S | **Launch** (in hub) |
| **Grabs and throws** (throw enemies into enemies; co-op "toss to partner's launcher") | BK 05:48 | Very high | M | **Launch** |
| **Breakable pickups**: food heals percent, coin bags, weapons | BK 10:11 | Very high | S-M | **Launch** |
| **Weapon pickups** (pipe, blade, bottle) with durability | BK 51:45 | High | M | **Launch** (3 weapons) |
| **Air attack** (directional jump kick) + air juggle finisher | BK 05:41 | High | S | **Launch** |
| **Enemy entrances and pulses** | BK 10:15, 13:30 | High | S | In M2 |
| **Rank, score, global + friends leaderboards** (OrderedDataStore) | BK score pressure | Very high | S | **Launch** |
| **Badges**: district clears, S ranks, Heat tiers, no-hit boss | Roblox discovery | Very high | S | **Launch** |
| **Downed / revive** | Roblox co-op norm | Very high | S | In M3 |
| **Endless survival / boss rush** with leaderboard | Roblox wave-mode staple | Very high | M | **v1.1** (first update) |
| **Team finisher** (two players' meters, shared cinematic hit) | Social spectacle | High | M | v1.1 |
| **Secret unlockable 4th hero** via a hidden challenge | BK kangaroo recruit | High (collection) | M-L | v1.1 |
| **Timed / rescue objectives** (free hostages in 60 s) | BK 51:15, 67:45 | Medium | M | v1.2 |
| **Stage set pieces** (elevator fight, moving train car, conveyor hazard) | BK traversal | Medium | L | v1.2 |
| **PvP versus arena** using percent/stocks | Smash roots | Medium (toxicity, balance) | L | Later, owner decision |
| Branching routes, vehicles, voiced cutscenes | BK | Low for effort | XL | Skip |

### Work orders
- **WO-4.1 (combat + presentation)** Grab/throw: auto-grab on walking into a stunned grunt, directional throw, thrown enemy deals damage to enemies it hits. Elites can't be grabbed. Mobile: grab happens contextually, no new button.
- **WO-4.2 (world + combat)** Breakables drop pickups (server-owned, 10 s lifetime, first touch wins, shared visibility). Food: small -15%, large -35%.
- **WO-4.3 (combat + presentation)** Three weapons with durability, dropped on hit/launch; enemies can pick them up too (Husk).
- **WO-4.4 (combat + presentation)** Air attack and juggle finisher.
- **WO-4.5 (root)** Leaderboards (per district best score, full-run best time, Heat), friends filter, and badges.
- **WO-4.6 (root + presentation)** Onboarding dojo in the hub: move, light chain, heavy launch, block, dash, jump the floor marker, throw. Skippable, remembered in profile.

**Acceptance:** each feature has a spec or scripted Studio test plus a short clip or screenshot in PROGRESS.md; touch and gamepad inputs verified for every new action.

---

## 7. M5: Lobby, parties and matchmaking

### Architecture
Two places in one universe:
- **Hub (start place, ~30 players):** social plaza, hero preview/selection, onboarding dojo, leaderboards, cosmetic shop, and a **Deploy terminal** with: Solo, Quick Match, Party, Private Code. Heat contracts and difficulty chosen here.
- **Campaign (current place, MaxPlayers 4):** only reached by teleport into reserved servers.

Flow:
1. **Party.** In-hub party invites (UI) plus `SocialService:PromptGameInvite` for friends not yet in the game. Party record in `MemoryStoreService` HashMap with 10-minute TTL, refreshed while the party exists.
2. **Quick Match.** Party leader enqueues `{partyId, size, difficulty, heat}` into `MemoryStoreService:GetQueue("QM_<difficulty>")` ([queue docs](https://github.com/Roblox/creator-docs/blob/main/content/en-us/cloud-services/memory-stores/queue.md)). A matchmaker loop in every hub server reads batches under a MemoryStore lease so only one server forms a given match. Groups fill to 4; after 20 s waiting, launch with whoever is there (min 1). Matches never split a party.
3. **Launch.** `TeleportService:ReserveServer(campaignPlaceId)`, write `Match_<matchId>` record (members, difficulty, heat, created time) to MemoryStore, then `TeleportAsync` with `TeleportOptions.ReservedServerAccessCode` and TeleportData `{matchId}` only.
4. **Campaign server** reads `matchId` from join data, loads the match record, rejects players not listed, applies difficulty/heat, and waits up to 30 s for all members before starting (existing ready flow becomes "all arrived or timeout").
5. **Return.** Victory, defeat-quit or "back to hub" teleports the party back together and restores the party record.
6. **Failures.** Retry `TeleportAsync` with backoff on `TeleportInitFailed`; if a member fails 3 times, the match starts without them and they return to hub with a message. Handle MemoryStore throttling by backing off, never by dropping queue entries silently.
7. **Optional backfill**: matches in district 1 with open slots can advertise to Quick Match for 60 s; existing late-join rules (no boss re-heal) apply.

### Work orders
- **WO-5.1 (root)** Create hub place in the Rojo project (`src/hub/**`, second project file), universe layout doc, and a `PlaceIds` config.
- **WO-5.2 (root)** `MatchmakingService` with a fake MemoryStore/Teleport adapter (same pattern as `ProfileStore.spec`). Specs: party never split, no double-matching under two concurrent matchmakers, timeout launch, leader leaves, member leaves mid-queue, throttling.
- **WO-5.3 (presentation)** Hub UI: party panel, deploy terminal, queue timer, cancel, difficulty/heat picker, touch and gamepad layout.
- **WO-5.4 (combat + root)** Campaign join validation, arrival wait, return-to-hub flow.
- **WO-5.5 (root)** **Run the harnesses that were never run**: `tests/MultiplayerCampaign.server.lua` at 2, 3 and 4 clients; every case in `tests/MultiplayerLifecycle.md`; stock-share conservation. Then a latency pass with Studio's incoming replication lag at 150 ms and 250 ms, noting any hit/telegraph desync.
- **WO-5.6 (root)** Published **test universe** run (Studio cannot teleport): 2 real accounts party-up, quick match, finish district 1, return to hub together. Record server IDs and timings.

**Acceptance:** all fake-adapter specs pass; harnesses pass at 2-4 clients; published test universe round-trip succeeds 5 times in a row with no orphaned players; median hub-to-fight time under 25 s.

---

## 8. M6: Publish gates

- [ ] **Maturity & Compliance Questionnaire** completed. Unrated experiences became unplayable after the September 30, 2025 deadline ([Roblox docs](https://create.roblox.com/docs/production/promotion/content-maturity), [announcement](https://devforum.roblox.com/t/important-updates-unrated-experiences-and-changes-to-experience-pages/3899317)). Expect a violence descriptor for melee combat.
- [ ] IP gate (WO-1.5) passes; icon, thumbnails, title, description and search keywords use no franchise names.
- [ ] Live DataStore in the test universe: join, earn, leave, rejoin on another server, forced failure mode shows read-only warning. BindToClose save verified.
- [ ] Audio and asset permissions resolve in the published universe (every Toolbox audio plays for a non-owner account).
- [ ] Analytics: `AnalyticsService` funnel (hub join, tutorial done, district 1/2/3 clear, victory) and economy events.
- [ ] Badges live; leaderboards write and read.
- [ ] Performance: 30+ fps on the chosen minimum-spec phone with 4 players at peak effects; hub memory under budget; MicroProfiler captures attached.
- [ ] Mobile and gamepad: every action reachable, safe areas respected, all new actions (grab, throw, weapons, desperation) mapped.
- [ ] Server security: remote rate limits cover new actions; no client-trusted match, reward or teleport data.
- [ ] Monetization stays **off** for soft launch. Enable Chapter Pass (149 Robux proposal) and private servers only after two weeks of clean persistence data.
- [ ] Soft launch: friends-only for 3 days, then public. Watch D1 retention, tutorial completion, district 1 clear rate and average session length; tune difficulty before any paid promotion.

---

## 9. Tuning targets and the test bot

The overnight Autoplay driver reads telegraphs perfectly, so it can't measure difficulty. `tests/HumanBot.client.lua` must model a decent new player:
- 250 ms reaction delay (+/-80 ms random), reads a telegraph correctly 75% of the time.
- Uses light chains 60%, heavy 25%, special when ready, blocks 40% of telegraphed melee, dashes out of 30% of AOEs.
- Takes one random "mistake" action every ~6 s.
- Outputs per-run JSON: clear/defeat, time, stocks lost per district, damage taken, rank, telemetry summary.

**Target curve (solo, HumanBot):** Normal clear 60-80%, Hard 30-50%, Nightmare under 20%. District 1 should lose a stock rarely; district 3 boss should be the most likely wipe. Real human playtests override the bot; record both.
