function HelloAgain_InitDB()
    HelloAgainDB = HelloAgainDB or {}
end

function HelloAgain_GetRecord(name)
    HelloAgainDB[name] = HelloAgainDB[name] or {
        score        = 0,
        interactions = {},
        lastSeen     = {},
    }
    return HelloAgainDB[name]
end

function HelloAgain_GetScore(name)
    if not HelloAgainDB or not name then return 0 end
    local record = HelloAgainDB[name]
    return record and record.score or 0
end

function HelloAgain_AddInteraction(name, interactionType, weight)
    if not HelloAgainDB or not name or name == "" then return end
    if name == UnitName("player") then return end

    local record = HelloAgain_GetRecord(name)
    local now    = time()

    -- Rate limit: don't record the same interaction type more than once per cooldown window
    local last = record.lastSeen[interactionType] or 0
    if (now - last) < HelloAgain_InteractionCooldown then return end
    record.lastSeen[interactionType] = now

    record.score = record.score + weight
    table.insert(record.interactions, {
        type      = interactionType,
        timestamp = now,
        weight    = weight,
    })
end
