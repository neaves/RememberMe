GameTooltip:HookScript("OnTooltipSetUnit", function(self)
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

    -- Badge polarity color: positive weight = green, negative = red, 0 = neutral yellow
    local function BadgeColor(weight)
        if weight > 0 then return "|cff00ff00"
        elseif weight < 0 then return "|cffff4444"
        else return "|cffffff00" end
    end

    local badgeParts = {}
    for badgeType, info in pairs(RememberMe_Badges) do
        local count = RememberMe_GetBadgeCount(name, badgeType)
        if count > 0 then
            table.insert(badgeParts, BadgeColor(info.weight) .. info.label .. " x" .. count .. "|r")
        end
    end
    if #badgeParts > 0 then
        self:AddLine(table.concat(badgeParts, "|cffffffff, |r"))
    end

    if (score and score ~= 0) or #badgeParts > 0 then
        self:Show()
    end
end)
