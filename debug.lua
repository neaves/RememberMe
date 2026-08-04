-- Diagnostic logging, off by default. Toggle with /rmdebug in-game, then /reload
-- after a session to flush RememberMeDebugDB.log to disk for review.

function RememberMe_InitDebugDB()
    RememberMeDebugDB = RememberMeDebugDB or { enabled = false, log = {} }
end

function RememberMe_Debug(msg)
    if not RememberMeDebugDB or not RememberMeDebugDB.enabled then return end
    DEFAULT_CHAT_FRAME:AddMessage("|cff888888[RememberMe Debug]|r " .. tostring(msg))
    local log = RememberMeDebugDB.log
    table.insert(log, date("%H:%M:%S") .. "  " .. tostring(msg))
    if #log > 500 then table.remove(log, 1) end
end

SLASH_RMDEBUG1 = "/rmdebug"
SlashCmdList["RMDEBUG"] = function()
    RememberMeDebugDB.enabled = not RememberMeDebugDB.enabled
    DEFAULT_CHAT_FRAME:AddMessage("|cff00ccff[Remember Me]|r Debug logging " ..
        (RememberMeDebugDB.enabled and "|cff00ff00ON|r" or "|cffff0000OFF|r"))
end
