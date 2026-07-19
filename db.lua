function RememberMe_InitDB()
    RememberMeDB = RememberMeDB or {}
end

function RememberMe_GetRecord(name)
    RememberMeDB[name] = RememberMeDB[name] or {
        score        = 0,
        interactions = {},
        lastSeen     = {},
        badges       = {},
        progress     = {},
    }
    -- Upgrade records saved before badges/progress existed
    local record = RememberMeDB[name]
    record.badges   = record.badges or {}
    record.progress = record.progress or {}
    return record
end

function RememberMe_GetScore(name)
    if not RememberMeDB or not name then return 0 end
    local record = RememberMeDB[name]
    return record and record.score or 0
end

-- Records one instance of a badge (positive, neutral, or negative weight -- e.g.
-- "leaver", "ninja", "needy") against a character, with the item involved (if any)
-- and a human-readable cause.
function RememberMe_AddBadge(name, badgeType, item, cause)
    if not RememberMeDB or not name or name == "" then return end
    if name == UnitName("player") then return end

    local record = RememberMe_GetRecord(name)
    local info   = RememberMe_Badges[badgeType]
    local weight = info and info.weight or 0

    record.score = record.score + weight
    record.badges[badgeType] = record.badges[badgeType] or { count = 0, instances = {} }
    record.badges[badgeType].count = record.badges[badgeType].count + 1
    table.insert(record.badges[badgeType].instances, {
        item      = item,
        cause     = cause,
        timestamp = time(),
    })
end

function RememberMe_GetBadgeCount(name, badgeType)
    if not RememberMeDB or not name then return 0 end
    local record = RememberMeDB[name]
    if not record or not record.badges or not record.badges[badgeType] then return 0 end
    return record.badges[badgeType].count
end

-- Increments a named progress counter (e.g. "quests_together") for a character and
-- awards the corresponding tiered badge (see RememberMe_ProgressTiers) the moment the
-- counter first reaches a tier's threshold.
function RememberMe_AdvanceProgress(name, progressKey)
    if not RememberMeDB or not name or name == "" then return end
    if name == UnitName("player") then return end

    local record = RememberMe_GetRecord(name)
    record.progress[progressKey] = (record.progress[progressKey] or 0) + 1
    local count = record.progress[progressKey]

    local tiers = RememberMe_ProgressTiers[progressKey]
    if not tiers then return end

    for _, tier in ipairs(tiers) do
        local threshold, badgeType = tier[1], tier[2]
        if count == threshold then
            RememberMe_AddBadge(name, badgeType, nil, "Reached " .. threshold .. " " .. progressKey:gsub("_", " "))
        end
    end
end

function RememberMe_AddInteraction(name, interactionType, weight)
    if not RememberMeDB or not name or name == "" then return end
    if name == UnitName("player") then return end

    local record = RememberMe_GetRecord(name)
    local now    = time()

    -- Rate limit: don't record the same interaction type more than once per cooldown window
    local last = record.lastSeen[interactionType] or 0
    if (now - last) < RememberMe_InteractionCooldown then return end
    record.lastSeen[interactionType] = now

    record.score = record.score + weight
    table.insert(record.interactions, {
        type      = interactionType,
        timestamp = now,
        weight    = weight,
    })
end
