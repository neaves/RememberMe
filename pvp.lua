-- Awards "Battle Buddy" progress to party members when a battleground/arena match
-- finishes while we're grouped and inside it.
--
-- 3.3.5 has no discrete "match complete" event -- GetBattlefieldWinner() returns nil
-- until the match ends and a truthy winner value once it does. This is not a guess:
-- Blizzard's own BattlefieldFrame.lua polls this exact function on a timer to decide
-- when to start its post-match shutdown countdown, so polling it here follows the
-- same confirmed pattern.

local POLL_INTERVAL = 2

local frame = CreateFrame("Frame", "RememberMePvPFrame")
frame:RegisterEvent("PLAYER_ENTERING_WORLD")

local polling      = false
local elapsedAccum = 0

local function OnPollTick()
    if GetBattlefieldWinner() then
        for name in pairs(RememberMe_GetCurrentPartyNames()) do
            RememberMe_AdvanceProgress(name, "battles_together")
        end
        frame:SetScript("OnUpdate", nil)
        polling = false
    end
end

frame:SetScript("OnEvent", function(self, event)
    local inInstance, instanceType = IsInInstance()
    local inBattle = inInstance and (instanceType == "pvp" or instanceType == "arena")

    if inBattle and not polling then
        polling      = true
        elapsedAccum = 0
        self:SetScript("OnUpdate", function(_, elapsed)
            elapsedAccum = elapsedAccum + elapsed
            if elapsedAccum >= POLL_INTERVAL then
                elapsedAccum = 0
                OnPollTick()
            end
        end)
    elseif not inBattle and polling then
        polling = false
        self:SetScript("OnUpdate", nil)
    end
end)
