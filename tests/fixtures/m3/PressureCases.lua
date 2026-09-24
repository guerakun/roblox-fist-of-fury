-- Planned WO-3.1 fixture data only. Not registered as a test or implemented policy.
return {
    HitProtection = {
        {name="first accepted hit", history={}, now=10, expectedDuration=.15, expectedCount=1},
        {name="second accepted hit", history={9.4}, now=10, expectedDuration=.15, expectedCount=2},
        {name="third within window", history={9,9.5}, now=10, expectedDuration=.8, expectedCount=0},
        {name="inclusive 1.5 second edge", history={8.5,9.5}, now=10, expectedDuration=.8, expectedCount=0},
        {name="expired oldest hit", history={8.499,9.5}, now=10, expectedDuration=.15, expectedCount=2},
        {name="empty old cluster", history={1,2}, now=10, expectedDuration=.15, expectedCount=1},
    },
    Burst = {
        {name="ordinary dash", now=10, stunnedUntil=9, hitAt=0, readyAt=11, allowed=true, cost=0},
        {name="hitstop minimum", now=10, stunnedUntil=11, hitAt=9.85, readyAt=0, allowed=false, cost=0},
        {name="accepted burst", now=10, stunnedUntil=11, hitAt=9.8, readyAt=0, allowed=true, cost=8},
        {name="burst cooldown", now=10, stunnedUntil=11, hitAt=9.8, readyAt=10.01, allowed=false, cost=0},
        {name="cooldown exact boundary", now=10, stunnedUntil=11, hitAt=9.8, readyAt=10, allowed=true, cost=8},
    },
    Integration = {
        "Rejected invulnerable hit leaves hit history unchanged",
        "A new life clears the hit cluster and invalidates old delayed effects",
        "Rejected ordinary dash cooldown does not charge Burst cost",
        "Anchor no-dash restriction blocks both ordinary Dash and Burst",
        "Percent 192 plus Burst 8 reaches KO limit before dash impulse",
        "Four-second Burst lock does not prohibit an otherwise legal normal Dash",
        "Each extra party member adds exactly two total ordinary-wave enemies",
        "Frozen wave party count cannot be changed by a mid-wave late arrival",
    },
}
