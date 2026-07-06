local ADDON_NAME = "HelloAgain"

-- Flag bits for COMBAT_LOG_EVENT_UNFILTERED destFlags
local CLEU_FLAG_PLAYER = 0x00000400

local frame = CreateFrame("Frame", "HelloAgainFrame")
frame:RegisterEvent("ADDON_LOADED")
frame:RegisterEvent("PARTY_MEMBERS_CHANGED")
frame:RegisterEvent("QUEST_COMPLETE")
frame:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")

local prevPartyMembers = {}

local function GetCurrentPartyNames()
    local names = {}
    local count = GetNumPartyMembers()
    for i = 1, count do
        local name = UnitName("party" .. i)
        if name and name ~= "Unknown" then
            names[name] = true
        end
    end
    return names
end

local function AnnounceJoin(name)
    local score = HelloAgain_GetScore(name)
    if score >= HelloAgain_AnnounceThreshold then
        DEFAULT_CHAT_FRAME:AddMessage(
            "|cff00ccff[Hello Again]|r You've adventured with " ..
            "|cffffff00" .. name .. "|r before! (Familiarity: " .. score .. ")"
        )
    end
end

frame:SetScript("OnEvent", function(self, event, ...)
    if event == "ADDON_LOADED" then
        local name = ...
        if name == ADDON_NAME then
            HelloAgain_InitDB()
            prevPartyMembers = GetCurrentPartyNames()
            DEFAULT_CHAT_FRAME:AddMessage("|cff00ccff[Hello Again]|r loaded.")
        end

    elseif event == "PARTY_MEMBERS_CHANGED" then
        local current = GetCurrentPartyNames()
        for name in pairs(current) do
            if not prevPartyMembers[name] then
                HelloAgain_AddInteraction(name, "party_join", HelloAgain_Weights.party_join)
                AnnounceJoin(name)
            end
        end
        prevPartyMembers = current

    elseif event == "QUEST_COMPLETE" then
        -- Quest completion screen opened; record for all party members
        local current = GetCurrentPartyNames()
        for name in pairs(current) do
            HelloAgain_AddInteraction(name, "quest_complete", HelloAgain_Weights.quest_complete)
        end

    elseif event == "COMBAT_LOG_EVENT_UNFILTERED" then
        local timestamp, eventType, sourceGUID, sourceName, sourceFlags,
              destGUID, destName, destFlags,
              spellId, spellName, spellSchool, auraType = ...

        local playerGUID = UnitGUID("player")
        local playerName = UnitName("player")

        if eventType == "SPELL_AURA_APPLIED" and auraType == "BUFF" then
            if sourceGUID == playerGUID and destName and destName ~= playerName then
                -- We applied a buff to someone else
                HelloAgain_AddInteraction(destName, "buff_given", HelloAgain_Weights.buff_given)

            elseif destGUID == playerGUID and sourceName and sourceName ~= playerName then
                -- Someone applied a buff to us
                HelloAgain_AddInteraction(sourceName, "buff_received", HelloAgain_Weights.buff_received)
            end

        elseif eventType == "UNIT_DIED" then
            -- Record boss/elite kills in instances for all party members
            local isPlayer = bit.band(destFlags or 0, CLEU_FLAG_PLAYER) ~= 0
            if not isPlayer then
                local inInstance, instanceType = IsInInstance()
                if inInstance and (instanceType == "party" or instanceType == "raid") then
                    local current = GetCurrentPartyNames()
                    for name in pairs(current) do
                        HelloAgain_AddInteraction(name, "boss_kill", HelloAgain_Weights.boss_kill)
                    end
                end
            end
        end
    end
end)
