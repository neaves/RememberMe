local ADDON_NAME = "RememberMe"

-- Flag bits for COMBAT_LOG_EVENT_UNFILTERED destFlags
local CLEU_FLAG_PLAYER = 0x00000400

local frame = CreateFrame("Frame", "RememberMeFrame")
frame:RegisterEvent("ADDON_LOADED")
frame:RegisterEvent("PARTY_MEMBERS_CHANGED")
frame:RegisterEvent("QUEST_COMPLETE")
frame:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
frame:RegisterEvent("LFG_COMPLETION_REWARD")

local prevPartyMembers = {}

-- Set true when the Dungeon Finder grants its completion reward, meaning the current
-- LFG-queued dungeon run finished properly. Reset whenever we're not in an LFG-queued
-- dungeon, so it starts false again for the next run.
local lfgRunComplete = false

-- Exposed globally (not local) so other modules -- pvp.lua, chat.lua -- can enumerate
-- the current party without duplicating this loop.
function RememberMe_GetCurrentPartyNames()
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
    local score = RememberMe_GetScore(name)
    if score >= RememberMe_AnnounceThreshold then
        DEFAULT_CHAT_FRAME:AddMessage(
            "|cff00ccff[Remember Me]|r You've adventured with " ..
            "|cffffff00" .. name .. "|r before! (Familiarity: " .. score .. ")"
        )
    end
end

frame:SetScript("OnEvent", function(self, event, ...)
    if event == "ADDON_LOADED" then
        local name = ...
        if name == ADDON_NAME then
            RememberMe_InitDB()
            prevPartyMembers = RememberMe_GetCurrentPartyNames()
            DEFAULT_CHAT_FRAME:AddMessage("|cff00ccff[Remember Me]|r loaded.")
        end

    elseif event == "PARTY_MEMBERS_CHANGED" then
        local current = RememberMe_GetCurrentPartyNames()
        for name in pairs(current) do
            if not prevPartyMembers[name] then
                AnnounceJoin(name)
                RememberMe_AddInteraction(name, "party_join", RememberMe_Weights.party_join)
            end
        end

        -- Someone dropped off the roster. There's no general "dungeon complete" signal
        -- for a manually-formed group, so leaver detection is restricted to dungeons
        -- entered via the Dungeon Finder queue, where LFG_COMPLETION_REWARD tells us
        -- for certain whether the run had already finished.
        local inLFGRun = IsPartyLFG() and IsInLFGDungeon()
        if not inLFGRun then
            lfgRunComplete = false
        end

        -- Only treat it as a "leaver" if we're still grouped with at least one other
        -- person afterward -- if `current` is empty, we can't tell whether they left or
        -- we did (both look identical from here), so we skip the badge to avoid
        -- mislabeling the whole group when we're the one who left.
        if next(current) and inLFGRun and not lfgRunComplete then
            for name in pairs(prevPartyMembers) do
                if not current[name] then
                    RememberMe_AddBadge(name, "leaver", nil, "Left the LFG dungeon before the completion reward was granted")
                end
            end
        end

        prevPartyMembers = current

    elseif event == "LFG_COMPLETION_REWARD" then
        lfgRunComplete = true
        -- The dungeon we queued for just finished -- credit everyone still grouped
        -- with us toward the "Dungeon Crew" badge line.
        for name in pairs(RememberMe_GetCurrentPartyNames()) do
            RememberMe_AdvanceProgress(name, "dungeons_together")
        end

    elseif event == "QUEST_COMPLETE" then
        -- Quest completion screen opened; record for all party members
        local current = RememberMe_GetCurrentPartyNames()
        for name in pairs(current) do
            RememberMe_AddInteraction(name, "quest_complete", RememberMe_Weights.quest_complete)
            RememberMe_AdvanceProgress(name, "quests_together")
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
                RememberMe_AddInteraction(destName, "buff_given", RememberMe_Weights.buff_given)

            elseif destGUID == playerGUID and sourceName and sourceName ~= playerName then
                -- Someone applied a buff to us
                RememberMe_AddInteraction(sourceName, "buff_received", RememberMe_Weights.buff_received)
            end

        elseif eventType == "UNIT_DIED" then
            -- Record boss/elite kills in instances for all party members
            local isPlayer = bit.band(destFlags or 0, CLEU_FLAG_PLAYER) ~= 0
            if not isPlayer then
                local inInstance, instanceType = IsInInstance()
                if inInstance and (instanceType == "party" or instanceType == "raid") then
                    local current = RememberMe_GetCurrentPartyNames()
                    for name in pairs(current) do
                        RememberMe_AddInteraction(name, "boss_kill", RememberMe_Weights.boss_kill)
                    end
                end
            end
        end
    end
end)
