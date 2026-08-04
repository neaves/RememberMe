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

-- Union of everyone who's been in the party at any point during the current LFG run
-- (not just a single-tick snapshot) -- so a mid-run leave-then-backfill doesn't erase
-- the original leaver from consideration once LFG_COMPLETION_REWARD actually fires.
-- Judged only at that moment: whoever's in here but not in the party when the reward
-- pops gets the "leaver" badge. Wiped whenever we're not in an LFG run, so if the run
-- ends any other way (we leave, the group disbands, no reward ever comes) nobody gets
-- flagged -- deliberately conservative, per user direction: incomplete/exploded runs are
-- common enough (deaths, backfill, disbands) that guessing who's "really" a leaver from
-- mid-run roster churn produces too many false positives. Only a confirmed completion
-- with confirmed absences is trustworthy.
local runRoster = {}

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
            RememberMe_InitDebugDB()
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

        -- There's no general "dungeon complete" signal for a manually-formed group, so
        -- leaver tracking is restricted to dungeons entered via the Dungeon Finder queue.
        local isPartyLFG = IsPartyLFG()
        local isInLFGDungeon = IsInLFGDungeon()
        local inLFGRun = isPartyLFG and isInLFGDungeon

        if inLFGRun then
            for name in pairs(current) do
                runRoster[name] = true
            end
        else
            -- Not (or no longer) in an LFG run -- nothing to judge yet, or the run ended
            -- some other way (we left, group disbanded, etc). Wipe so no leftover roster
            -- bleeds into whatever run comes next.
            lfgRunComplete = false
            wipe(runRoster)
        end

        RememberMe_Debug(string.format(
            "PARTY_MEMBERS_CHANGED: IsPartyLFG=%s IsInLFGDungeon=%s lfgRunComplete=%s current=%d prev=%d",
            tostring(isPartyLFG), tostring(isInLFGDungeon), tostring(lfgRunComplete),
            (function() local n=0 for _ in pairs(current) do n=n+1 end return n end)(),
            (function() local n=0 for _ in pairs(prevPartyMembers) do n=n+1 end return n end)()
        ))

        prevPartyMembers = current

    elseif event == "LFG_COMPLETION_REWARD" then
        lfgRunComplete = true
        RememberMe_Debug("LFG_COMPLETION_REWARD fired -- run marked complete")

        local current = RememberMe_GetCurrentPartyNames()
        for name in pairs(current) do
            runRoster[name] = true
            -- The dungeon we queued for just finished -- credit everyone still grouped
            -- with us toward the "Dungeon Crew" badge line.
            RememberMe_AdvanceProgress(name, "dungeons_together")
        end

        -- Judge leavers only now: anyone who was ever part of this run's roster but
        -- isn't in the party at the moment the reward actually pops.
        for name in pairs(runRoster) do
            if not current[name] then
                RememberMe_Debug("Flagging leaver at completion: " .. name)
                RememberMe_AddBadge(name, "leaver", nil, "Wasn't in the party when the LFG dungeon's completion reward was granted")
            end
        end
        wipe(runRoster)

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
