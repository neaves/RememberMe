RememberMe_Weights = {
    buff_given     = 5,
    buff_received  = 5,
    party_join     = 10,
    quest_complete = 10,
    boss_kill      = 20,
}

-- Badges: recorded as individually-timestamped instances (see db.lua), and each
-- occurrence stacks against the character's score. `weight` sign determines polarity
-- (positive/neutral/negative), which drives the tooltip color-coding. `label` and
-- `subLabel` are for display -- modeled loosely on WotLK's in-game Achievements UI
-- (top-level categories: Quests, Dungeons & Raids, PvP, plus the "Life"/social-style
-- counters under Statistics), reworked here as tiered badges for playing well with
-- specific people rather than solo milestones.
RememberMe_Badges = {
    -- Loot etiquette (negative)
    leaver = { weight = -15, label = "Leaver",
        subLabel = "Bailed on an LFG dungeon before the reward popped" },
    ninja  = { weight = -25, label = "Ninja",
        subLabel = "Needed a BoE item you Greeded" },
    needy  = { weight = -10, label = "Needy",
        subLabel = "Won a Need roll you also Needed on" },
    lucky  = { weight = 0, label = "Lucky",
        subLabel = "Won a Need roll over you in an LFG group" },

    -- Quests
    questy_1 = { weight = 10, label = "Questy",
        subLabel = "Turned in a handful of quests together" },
    questy_2 = { weight = 25, label = "Questy II: Quest Buddy",
        subLabel = "Turned in a solid stack of quests side-by-side" },
    questy_3 = { weight = 60, label = "Questy III: Completionist Duo",
        subLabel = "Basically quest-married at this point" },

    -- Dungeons & Raids
    dungeon_crew_1 = { weight = 15, label = "Dungeon Crew",
        subLabel = "Cleared an LFG dungeon together" },
    dungeon_crew_2 = { weight = 40, label = "Dungeon Crew II: Regulars",
        subLabel = "The bartender at the dungeon entrance knows your order" },
    dungeon_crew_3 = { weight = 100, label = "Dungeon Crew III: Ride or Die",
        subLabel = "Would tank a pull gone wrong for this person" },

    -- PvP
    battle_buddy_1 = { weight = 15, label = "Battle Buddy",
        subLabel = "Fought through a battleground together" },
    battle_buddy_2 = { weight = 40, label = "Battle Buddy II: Battle-Hardened",
        subLabel = "Bled together in enough BGs to have opinions about each other's keybinds" },
    battle_buddy_3 = { weight = 100, label = "Battle Buddy III: War Council",
        subLabel = "Coordinated enough kills to make the enemy team salty" },

    -- Social
    chatty_1 = { weight = 5, label = "Chatty",
        subLabel = "Actually said something in party chat" },
    chatty_2 = { weight = 15, label = "Chatty II: Motormouth",
        subLabel = "Can't stop talking in party chat" },
    chatty_3 = { weight = 35, label = "Chatty III: Town Crier",
        subLabel = "Never met a silence they didn't fill" },
    happy_chatter = { weight = 5, label = "Happy Chatter",
        subLabel = "Brings the lol/rofl/:) energy to party chat" },

    -- Damage meters (Details! integration -- see damage.lua). Awarded once per LFG
    -- dungeon completion, based on the player's share of the group's overall damage
    -- for that run; only the single highest tier reached is awarded.
    big_pumper_1 = { weight = 15, label = "Big Pumper",
        subLabel = "Dealt 30%+ of the group's damage this dungeon" },
    big_pumper_2 = { weight = 30, label = "Big Pumper II",
        subLabel = "Dealt 40%+ of the group's damage this dungeon" },
    big_pumper_3 = { weight = 50, label = "Big Pumper III",
        subLabel = "Dealt 50%+ of the group's damage this dungeon" },
    thats_not_normal = { weight = 75, label = "That's Not Normal",
        subLabel = "Dealt 60%+ of the group's damage -- might want to get that checked" },
}

-- Damage-share thresholds for the Big Pumper badge line, highest first so a single
-- dungeon completion only awards the top tier actually reached (see damage.lua).
RememberMe_DamageShareTiers = {
    { 60, "thats_not_normal" },
    { 50, "big_pumper_3" },
    { 40, "big_pumper_2" },
    { 30, "big_pumper_1" },
}

-- Milestone thresholds that award a tiered badge the moment a progress counter
-- (see RememberMe_AdvanceProgress in db.lua) first reaches them. Counts are exact
-- because progress only ever increases by 1, so `==` is a safe one-shot trigger.
RememberMe_ProgressTiers = {
    quests_together   = { { 10, "questy_1" },         { 25, "questy_2" },         { 60, "questy_3" } },
    dungeons_together = { { 3,  "dungeon_crew_1" },   { 10, "dungeon_crew_2" },   { 25, "dungeon_crew_3" } },
    battles_together  = { { 3,  "battle_buddy_1" },   { 10, "battle_buddy_2" },   { 25, "battle_buddy_3" } },
    chat_sessions     = { { 5,  "chatty_1" },         { 20, "chatty_2" },        { 50, "chatty_3" } },
}

-- Minimum familiarity score to trigger a party-join announcement
RememberMe_AnnounceThreshold = 10

-- Seconds before the same interaction type can be recorded again for the same character
RememberMe_InteractionCooldown = 300
