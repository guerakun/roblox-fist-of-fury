# Codex prompts: paste these in order

Copy `AGENTS.md` to the repo root and `docs/launch/` into `docs/`, commit, then start Codex in the repo. Paste one prompt per session. Wait for its PROGRESS.md evidence before pasting the next. Prompts marked **parallel** can run in separate Codex sessions at the same time.

---

## Prompt 0: kickoff and baseline

```
Read AGENTS.md and docs/launch/LAUNCH_PLAN.md fully before doing anything.

You are the root integrator. Execute milestone M0 only (WO-0.1, WO-0.2, WO-0.3).
- Tag the current HEAD as v0-overnight and run every existing spec; record results.
- Build tests/HumanBot.client.lua exactly as described in LAUNCH_PLAN section 9.
- Build src/server/CombatTelemetry.lua and wire it in without changing gameplay.
- Run the current campaign 5 times solo with HumanBot in Studio and record clear rate,
  stocks lost per district, damage taken, time and the telemetry summary (especially
  grunt idle ratio and flank rate) in docs/PROGRESS.md under "Launch baseline".
Do not change combat numbers or AI in this session. Commit as WO-0.x. Stop and report
the baseline table when done.
```

## Prompt 1: original heroes and IP scrub (parallel with Prompt 2)

```
Read AGENTS.md and LAUNCH_PLAN section 3. Run the presentation and world roles.

Goal: zero franchise IP in the game and repo, with three original heroes that keep the
existing move archetypes. Use hero IDs Gale, Piston, Tide and the candidate names, titles,
specials and look directions in the section 3 table. Respect every "Must NOT have" item.

Do WO-1.1 through WO-1.5 in order. Specifically:
- Remove the eight anime mesh/texture asset IDs from CharacterArt.lua and ASSET_REGISTER.md.
- Build new hair and outfits from authored parts, using Roblox Studio mesh generation where
  parts can't carry the silhouette; record every generated asset ID.
- Delete the whisker-mark and forehead-scar face shapes.
- Drive all hero names, colours, move names and tips from Config.Characters; remove every
  hard-coded hero check in client and server code.
- Rename stage 1 to ASHGATE CROSSING and scrub docs (including benchmark references to
  other Roblox games in public docs) so the WO-1.5 grep gate returns zero hits.
- Add the grep gate as a test that fails the build.

Evidence: grep gate output, one silent gameplay screenshot per hero, and a review note
from the world role (who did not author the art) confirming no franchise likeness.
Leave the names flagged "pending owner approval" in PROGRESS.md.
```

## Prompt 2: enemy AI rework (parallel with Prompt 1)

```
Read AGENTS.md and LAUNCH_PLAN section 4. Run the combat role, with presentation for
animations only.

Do WO-2.1 first: extract enemy AI from CombatService.aiStep/beginEnemyAttack into
src/server/EnemyAI.lua and src/server/AttackDirector.lua with NO behaviour change, and
prove it with a HumanBot run matching the M0 baseline.

Then WO-2.2 to WO-2.6:
- AttackDirector engagement slots that prefer the side opposite current attackers, and
  per-player attack tokens (solo 2, +1 per extra player on Normal).
- Hold state that never idles: strafe, shuffle, feint, taunt.
- Grunt tells become body anticipation + flash (>=0.30 s); floor markers stay for elites
  and AOEs.
- Six archetypes from the table: Husk, Strider, Grappler, Pitcher, Warden, Leaper, plus
  Brute. Moves are data in EnemyMoves; archetype data in src/shared/EnemyArchetypes.lua.
- Elites: weighted, condition-based move selection; phase 2 summons, desperation move,
  feints.
- Wave Entries (left, right, door, drop) and 2-3 spawn pulses per wave.
- Difficulty profiles (Aggression, TokenBonus, ReactionDelay, EvadeChance, WindupScale).

Acceptance is the telemetry list at the end of section 4, measured over 5 HumanBot runs.
Record before/after numbers side by side in PROGRESS.md. Keep the fairness contract in
AGENTS.md.
```

## Prompt 3: hub and matchmaking (parallel with Prompts 1 and 2)

```
Read AGENTS.md and LAUNCH_PLAN section 7. Run the root role, with presentation for hub UI.

First do WO-5.5: execute tests/MultiplayerCampaign.server.lua at 2, 3 and 4 clients and
every case in tests/MultiplayerLifecycle.md, plus stock-share conservation. Fix what fails.
Then the latency pass at 150 ms and 250 ms incoming replication lag.

Then WO-5.1 to WO-5.4: a hub start place in the Rojo project, MatchmakingService built on
MemoryStore queues/hash maps and TeleportService reserved servers, behind a fake adapter
with specs for every case listed in WO-5.2. TeleportData carries only matchId; the
campaign server validates members against the MemoryStore match record. Implement the
return-to-hub flow and failure handling exactly as in section 7.

Studio cannot teleport between places. Stop after specs and in-Studio parts pass, and
write the WO-5.6 published-test-universe checklist for the owner to run with you.
```

## Prompt 4: challenge and risk/reward (after Prompt 2 closes; after Prompt 3 too if the same root agent runs both)

```
Read AGENTS.md and LAUNCH_PLAN sections 5 and 9. Run the combat and root roles.

Do WO-3.1 to WO-3.7:
- Table A numbers behind the difficulty profile, combo breaker, Burst cost for
  dash-out-of-hitstun.
- Percent carries across districts (no reset at district start); stocks don't refill at district start (+1 on clear,
  max 3); retry restores 2 stocks and resets the multiplier; downed + revive.
- Style meter, score, D-S rank, rank reward multipliers (never below 1.0) with reward-key
  deduplication intact.
- Desperation special, perfect block, bounty enemy, greed drops.
- Heat contracts (data, match record field, hub picker, badges) and trade-off boons. If
  Prompt 3's hub isn't merged yet, put a temporary picker in the campaign ready lobby.
- Normal / Hard / Nightmare tiers.
Update tests/MultiplayerLifecycle.md for the new stock rules and re-run it.

Tune until HumanBot hits the section 5 acceptance curve. Record final numbers and why in
docs/COMBAT.md. Money must never buy power.
```

## Prompt 5: launch features (after Prompt 4 closes)

```
Read AGENTS.md and LAUNCH_PLAN section 6. Do WO-4.1 to WO-4.6 only (the "Launch" rows):
grabs and throws, breakable pickups (food, coins, weapons), three weapons with durability
that enemies can also use, air attack + juggle finisher, leaderboards and badges, and the
onboarding dojo in the hub. Every new action must work on keyboard, touch and gamepad.
Leave v1.1+ rows as backlog in ROADMAP.md.
```

## Prompt 6: publish gates

```
Read AGENTS.md and LAUNCH_PLAN section 8. Go through every gate. Do the ones you can do
from source and Studio; for the ones that need the Creator Dashboard or real devices
(questionnaire, published test universe, phone performance, audio permissions), write an
exact step-by-step checklist for the owner and pair with them. Produce docs/LAUNCH_REPORT.md
listing each gate as Verified (with evidence), Owner action required, or Blocked.
Monetization stays disabled.
```

---

## Reviewing each Codex session (for Faisal)
Ask these four questions before approving the next prompt:
1. Did PROGRESS.md get real numbers, a date and a commit hash, or only "implemented"?
2. Did the before/after telemetry move in the right direction?
3. Did someone other than the author review it?
4. Play 5 minutes yourself. Does it feel better? Your feel beats the bot.
