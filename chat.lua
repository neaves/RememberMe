-- Tracks positive social behavior in party chat: general participation ("chatty") and
-- upbeat responses ("happy chatter" -- lol/rofl/haha/smileys). Both are cooldown-gated
-- per player (reusing RememberMe_InteractionCooldown) so one chatty burst doesn't rack
-- up dozens of badge instances in a single conversation.

local HAPPY_WORDS = { "lol", "rofl", "lmao", "haha", "hehe" }

local function IsHappyChat(msg)
    local lower = msg:lower()
    for _, word in ipairs(HAPPY_WORDS) do
        if lower:find(word, 1, true) then return true end
    end
    return msg:find(":%)") or msg:find(":D") or msg:find("=%)") or msg:find("xD")
end

local lastChatty = {}
local lastHappy  = {}

local frame = CreateFrame("Frame", "RememberMeChatFrame")
frame:RegisterEvent("CHAT_MSG_PARTY")
frame:RegisterEvent("CHAT_MSG_PARTY_LEADER")
frame:RegisterEvent("CHAT_MSG_INSTANCE_CHAT")
frame:RegisterEvent("CHAT_MSG_INSTANCE_CHAT_LEADER")

frame:SetScript("OnEvent", function(self, event, msg, sender)
    if not sender or sender == "" or sender == UnitName("player") then return end

    local now = time()

    if (lastChatty[sender] or 0) + RememberMe_InteractionCooldown < now then
        lastChatty[sender] = now
        RememberMe_AdvanceProgress(sender, "chat_sessions")
    end

    if IsHappyChat(msg) and (lastHappy[sender] or 0) + RememberMe_InteractionCooldown < now then
        lastHappy[sender] = now
        RememberMe_AddBadge(sender, "happy_chatter", nil, "Brought the vibes in party chat")
    end
end)
