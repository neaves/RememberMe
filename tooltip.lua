-- Badge polarity color: positive weight = green, negative = red, 0 = neutral yellow
local function BadgeColor(weight)
    if weight > 0 then return "|cff00ff00"
    elseif weight < 0 then return "|cffff4444"
    else return "|cffffff00" end
end

-- For each tiered badge family (see RememberMe_BadgeTierGroups), returns the set of
-- lower tiers to hide so only the highest tier actually reached gets displayed.
local function GetSuppressedTierBadges(name)
    local suppressed = {}
    for _, tierList in pairs(RememberMe_BadgeTierGroups) do
        local highest
        for _, badgeType in ipairs(tierList) do
            if RememberMe_GetBadgeCount(name, badgeType) > 0 then
                highest = badgeType
            end
        end
        for _, badgeType in ipairs(tierList) do
            if badgeType ~= highest then
                suppressed[badgeType] = true
            end
        end
    end
    return suppressed
end

local MAX_TOOLTIP_BADGES = 3

GameTooltip:HookScript("OnTooltipSetUnit", function(self)
    if InCombatLockdown() then return end

    local _, unit = self:GetUnit()
    if not unit then return end

    local name = UnitName(unit)
    if not name or name == "Unknown" then return end
    if name == UnitName("player") then return end

    local score = RememberMe_GetScore(name)
    if score and score ~= 0 then
        local color = score > 0 and "|cff00ff00" or "|cffff4444"
        self:AddLine(color .. "Remember Me: Familiarity " .. score .. "|r")
    end

    local suppressed = GetSuppressedTierBadges(name)
    local badges = {}
    for badgeType, info in pairs(RememberMe_Badges) do
        if not suppressed[badgeType] then
            local count = RememberMe_GetBadgeCount(name, badgeType)
            if count > 0 then
                table.insert(badges, { weight = info.weight, label = info.label, count = count })
            end
        end
    end
    -- Most notable (highest weight) badges first, so overflow trims the least
    -- interesting ones rather than an arbitrary iteration order.
    table.sort(badges, function(a, b) return a.weight > b.weight end)

    local badgeParts = {}
    local shown = math.min(#badges, MAX_TOOLTIP_BADGES)
    for i = 1, shown do
        local b = badges[i]
        table.insert(badgeParts, BadgeColor(b.weight) .. b.label .. " x" .. b.count .. "|r")
    end
    local overflow = #badges - shown
    if overflow > 0 then
        table.insert(badgeParts, "|cffffffff+" .. overflow .. "|r")
    end

    if #badgeParts > 0 then
        self:AddLine(table.concat(badgeParts, "|cffffffff, |r"))
    end

    if (score and score ~= 0) or #badgeParts > 0 then
        self:Show()
    end
end)
