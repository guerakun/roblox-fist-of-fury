# Economy and monetization — After the Last Train

## Player promise
All three stages, all three heroes, retries and cooperative play are free. Coins are earned by playing; coins are not sold. No paid revives, randomized purchases, energy meters, streak penalties, expiring rewards or purchased combat advantages.

## Implemented economy
Server-owned rewards per participating player:
| Encounter | Coins | Chapter XP |
|---|---:|---:|
| Street / station / factory skirmish | 25 | 35 |
| Miniboss | 60 | 75 |
| Boss | 120 | 120 |

Each stage contains two skirmishes, a miniboss and a boss. A full campaign therefore earns **690 coins and 795 XP** when the player participates in every encounter. Damage dealt, damage taken and blocking count toward participation. Stable reward keys prevent checkpoint retries from repeatedly paying the same cleared encounter within a campaign. A fresh campaign pays normally.

The evergreen chapter has 12 tiers at 150 XP each: 1,800 XP total, approximately 2.3 complete campaigns at the current reward rate. This is a tuning starting point, not a measured human retention target. Free tiers provide 825 coins, two shop cosmetics and two exclusive earned cosmetics. Previously purchased shop cosmetics refund their coin price when the matching free tier is claimed, once.

The coin shop has three trails (150 / 250 / 350 coins) and two titles (200 / 350 coins). Preview names and prices are visible before a deliberate purchase. No rotating scarcity or countdown timer.

## Power buffs
One earned boon can be equipped in safe states:
- Guardian: available immediately; 8% less incoming damage.
- Focus: 200 lifetime chapter XP; 8% more outgoing damage.
- Haste: 400 lifetime chapter XP; +2 movement speed.

Boons are permanent unlocks with no consumable cost. They cannot stack, cannot be bought with Robux, and cannot be switched during an encounter. These modest choices need human balance testing across solo and four-player parties.

## Optional paid offer
One evergreen Chapter Pass would unlock six cosmetic rewards alongside the same free XP track. Buying after earning XP should permit claiming already reached premium tiers. It does not accelerate XP or increase power. Suggested initial price for later testing: **149 Robux**, subject to owner configuration and player feedback; this is a proposal, not an active sale.

**SalesEnabled is false and ChapterPassId is 0.** No live sales or purchase prompts are enabled in this build. When configured, ownership is checked on the server, displayed price comes from Roblox product information, and purchase entry should only appear in non-expiring safe states. A successful prompt alone never grants ownership.

## Persistence and launch gates
Studio defaults to visibly labeled practice progress that resets after the session. Live profiles use UpdateAsync, per-load session leases, serialized saves, revision checks and read-only behavior after failed loading. Fake-adapter tests cover contention and delayed saves; live DataStore outage/rejoin tests are still required in the final published test universe before sales.

Configure an experience-owned pass, test dynamic/regional price display and entitlement recovery, verify persistent claims and refunds, and review the offer on touch/controller before enabling the sales flag. Do not sell a pass whose cosmetics or saves are unavailable.

## Official implementation references
- [Roblox passes](https://create.roblox.com/docs/production/monetization/passes): one-time ownership and server ownership checks.
- [Developer products](https://create.roblox.com/docs/production/monetization/developer-products): repeatable purchases require receipt handling if such products are added later; this build sells no coin products.
- [Player data and purchasing](https://create.roblox.com/docs/cloud-services/data-stores/player-data-purchasing): persistent data failure and session consistency.

Future additions should preserve the player promise above. Cosmetic outfits, emotes and finishers are better expansion candidates than numerical power.
