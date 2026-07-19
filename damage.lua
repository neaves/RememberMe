-- Awards "Big Pumper" / "That's Not Normal" badges based on each party member's share
-- of the group's damage when an LFG dungeon completes, using the Details! damage meter
-- addon's public API (see Details/API.lua in this AddOns folder).
--
-- Segment choice: DETAILS_SEGMENTID_OVERALL (-1) is Details!'s "Overall" segment. It is
-- not a lifetime total -- Details:CheckForAutoErase() (core/control.lua) resets it every
-- time the player zones into an instance with a different map ID than their last one,
-- so by the time a dungeon's LFG completion reward fires, "Overall" holds exactly that
-- dungeon run's totals. (Caveat: re-entering the *same* dungeon instance within 6 hours
-- does NOT reset it, so damage carries over across repeated clears of one instance in a
-- session -- acceptable for this purpose, just noted here so it isn't a surprise later.)
--
-- combat:GetTotal(DETAILS_ATTRIBUTE_DAMAGE, nil, DETAILS_TOTALS_ONLYGROUP) restricts the
-- total to actual group members (classes/class_combat.lua GetTotal), so damage from
-- enemies or ungrouped bystanders can't dilute the percentage.
--
-- If Details! (or any of its constants) isn't present -- not installed, disabled, or a
-- future version renames something -- this silently does nothing rather than erroring.

local frame = CreateFrame("Frame", "RememberMeDamageFrame")
frame:RegisterEvent("LFG_COMPLETION_REWARD")

frame:SetScript("OnEvent", function()
    if not Details or not Details.GetCombat then return end
    if not DETAILS_SEGMENTID_OVERALL or not DETAILS_ATTRIBUTE_DAMAGE or not DETAILS_TOTALS_ONLYGROUP then return end

    local combat = Details:GetCombat(DETAILS_SEGMENTID_OVERALL)
    if not combat then return end

    local groupTotal = combat:GetTotal(DETAILS_ATTRIBUTE_DAMAGE, DETAILS_SUBATTRIBUTE_DAMAGEDONE, DETAILS_TOTALS_ONLYGROUP)
    if not groupTotal or groupTotal <= 0 then return end

    for name in pairs(RememberMe_GetCurrentPartyNames()) do
        local actor = combat:GetActor(DETAILS_ATTRIBUTE_DAMAGE, name)
        if actor and actor.total and actor.total > 0 then
            local pct = (actor.total / groupTotal) * 100
            for _, tier in ipairs(RememberMe_DamageShareTiers) do
                if pct >= tier[1] then
                    RememberMe_AddBadge(name, tier[2], nil, format("Dealt %.0f%% of the group's damage this dungeon", pct))
                    break
                end
            end
        end
    end
end)
