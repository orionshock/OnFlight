--luacheck: globals LibEdrik_GetDebugFunction string tostringall CHAT_FRAMES
--[[
    Standard Debug Function
    "Prefix" to add to the start of every line
    "seperator" for the string.join function. defaults to " " (a non blank space)
    "frameName" to print the debug too. defaults to "Debug"
]]
function LibEdrik_GetDebugFunction(prefix, seperator, frameName, disableDebug)
    prefix = prefix or "Debug:"
    seperator = seperator or " "
    if disableDebug then
        local function emptDebugFunc()
            return
        end
        return emptDebugFunc
    else
        frameName = frameName or "Debug"
        local chatFrame
        local function returnDebugFunc(...)
            local printedDebugString = string.join(seperator, prefix, tostringall(...))
            if not chatFrame then
                for i = 1, #CHAT_FRAMES do
                    local checkFrame = _G[CHAT_FRAMES[i]]
                    if (checkFrame) and (checkFrame.name) and (checkFrame.name == frameName) then
                        chatFrame = checkFrame
                    end
                end
            end
            if chatFrame then
                chatFrame:AddMessage(printedDebugString)
            end
            return printedDebugString
        end

        return returnDebugFunc
    end
end
