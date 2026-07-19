-- Tracks group loot rolls to detect "ninja" (Need on a BoE item someone else Greeded),
-- "needy" (won a Need roll that we also rolled Need on), and its neutral LFG-only
-- counterpart "lucky" (same trigger, no judgment -- just acknowledges the roll).
--
-- 3.3.5 has no structured "who rolled what" API for other players' choices, so this
-- relies on parsing the same CHAT_MSG_SYSTEM text the client already prints, built
-- from the live GlobalStrings (locale-safe, and safe if the strings are ever patched).
-- Item identity is keyed by the literal item-link text, which is expected to be
-- byte-identical whether it comes from GetLootRollItemInfo() or from the chat line
-- describing the same roll.

local function ToPattern(fmt)
    return "^" .. fmt:gsub("%%s", "(.+)") .. "$"
end

local PATTERN_NEED_SELF  = ToPattern(LOOT_ROLL_NEED_SELF)  -- "You have selected Need for: %s"
local PATTERN_GREED_SELF = ToPattern(LOOT_ROLL_GREED_SELF) -- "You have selected Greed for: %s"
local PATTERN_NEED       = ToPattern(LOOT_ROLL_NEED)       -- "%s has selected Need for: %s"
local PATTERN_WON        = ToPattern(LOOT_ROLL_WON)        -- "%s won: %s"

-- [itemLink] = { bindOnPickUp = bool/nil, myChoice = "need"/"greed"/nil, otherNeeds = { [name]=true } }
local activeRolls = {}

local function GetRoll(itemLink)
    activeRolls[itemLink] = activeRolls[itemLink] or { otherNeeds = {} }
    return activeRolls[itemLink]
end

local frame = CreateFrame("Frame", "RememberMeLootRollFrame")
frame:RegisterEvent("START_LOOT_ROLL")
frame:RegisterEvent("CHAT_MSG_SYSTEM")

frame:SetScript("OnEvent", function(self, event, ...)
    if event == "START_LOOT_ROLL" then
        local rollID = ...
        local _, itemLink, _, _, bindOnPickUp = GetLootRollItemInfo(rollID)
        if itemLink then
            GetRoll(itemLink).bindOnPickUp = bindOnPickUp
        end
        return
    end

    -- CHAT_MSG_SYSTEM
    local msg = ...

    local item = msg:match(PATTERN_NEED_SELF)
    if item then
        GetRoll(item).myChoice = "need"
        return
    end

    item = msg:match(PATTERN_GREED_SELF)
    if item then
        GetRoll(item).myChoice = "greed"
        return
    end

    local player, needItem = msg:match(PATTERN_NEED)
    if player and needItem and player ~= UnitName("player") then
        GetRoll(needItem).otherNeeds[player] = true
        return
    end

    local winner, wonItem = msg:match(PATTERN_WON)
    if winner and wonItem then
        local roll = activeRolls[wonItem]
        if roll and winner ~= UnitName("player") and roll.otherNeeds[winner] then
            if roll.bindOnPickUp == false and roll.myChoice == "greed" then
                RememberMe_AddBadge(winner, "ninja", wonItem, "Needed a BoE item you Greeded")
            end
            if roll.myChoice == "need" then
                RememberMe_AddBadge(winner, "needy", wonItem, "Won a Need roll you also Needed on")
                if IsPartyLFG() then
                    RememberMe_AddBadge(winner, "lucky", wonItem, "Won a Need roll over you in an LFG group")
                end
            end
        end
        activeRolls[wonItem] = nil
    end
end)
