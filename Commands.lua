-- AceConfig command descriptions, handlers and embedded AceDBOptions Profiles.
-- luacheck: no max line length
-- luacheck: globals LibStub InCombatLockdown wipe
local addonName, addonCore = ...
local L = LibStub("AceLocale-3.0"):GetLocale(addonName)
local LSM = LibStub("LibSharedMedia-3.0")
local statusBarModuleCore = addonCore:GetModule("StatusBarModule")
local moduleName = "StatusBarModule"

-- Retained command interface and embedded Profiles descriptions.
function addonCore.ChatCommand(_, input)
    if InCombatLockdown() then
        addonCore:Print(L["In Combat"])
        return
    end
    if not input or input:trim() == "" then
        addonCore:OpenSettings()
    else
        LibStub("AceConfigCmd-3.0").HandleCommand(addonCore, "OnFlight", addonName, input)
    end
end

---Ace3 Config Table
function addonCore:GetOption(info)
    if info.type == "color" then
        if addonCore.db.profile[info[#info]] then
            local color = addonCore.db.profile[info[#info]]
            return color.r, color.g, color.b, color.a
        else
            return math.random(0, 100) / 100, math.random(0, 100) / 100, math.random(0, 100) / 100,
                math.random(0, 100) / 100
        end
    else
        return addonCore.db.profile[info[#info]]
    end
end

function addonCore:SetOption(info, ...)
    if info.type == "color" then
        local red, green, blue, alpha = ...
        addonCore.db.profile[info[#info]] = addonCore.db.profile[info[#info]] or {}
        addonCore.db.profile[info[#info]].r = red
        addonCore.db.profile[info[#info]].b = blue
        addonCore.db.profile[info[#info]].g = green
        addonCore.db.profile[info[#info]].a = alpha
    else
        addonCore.db.profile[info[#info]] = ...
    end
    self:RefreshSettings(info[#info])
end

local gossipOptionTemplate = {
    name = "",
    type = "group",
    inline = true,
    order = function(info)
        return tonumber(info[#info])
    end,
    args = {
        name = {
            order = 1,
            name = L["Gossip ID"],
            type = "input",
            get = function(info)
                return info[#info - 1]
            end,
            set = function()
            end,
            disabled = true
        },
        sourceID = {
            order = 2,
            type = "input",
            name = L["Source Node ID"],
            validate = function(_, value)
                local key, message = addonCore:ParseGossipEndpoint(0, value)
                return key ~= nil or message
            end,
            get = function(info)
                local id = tonumber(info[#info - 1])
                local value = addonCore.db.global.gossipTriggered[id][1]
                return type(value) == "number" and tostring(value) or select(2, addonCore:GetGossipEndpoint(id, value))
            end,
            set = function(info, value)
                local id = tonumber(info[#info - 1])
                addonCore.db.global.gossipTriggered[id][1] = addonCore:ParseGossipEndpoint(id, value)
                addonCore:RefreshGossipEditor(id)
            end
        },
        destinationID = {
            order = 3,
            type = "input",
            name = L["Destination Node ID"],
            validate = function(_, value)
                local key, message = addonCore:ParseGossipEndpoint(0, value)
                return key ~= nil or message
            end,
            get = function(info)
                local id = tonumber(info[#info - 1])
                local value = addonCore.db.global.gossipTriggered[id][2]
                return type(value) == "number" and tostring(value) or select(2, addonCore:GetGossipEndpoint(id, value))
            end,
            set = function(info, value)
                local id = tonumber(info[#info - 1])
                addonCore.db.global.gossipTriggered[id][2] = addonCore:ParseGossipEndpoint(id, value)
                addonCore:RefreshGossipEditor(id)
            end
        },
        remove = {
            order = 4,
            name = L["Remove"],
            type = "execute",
            func = function(info)
                local id = tonumber(info[#info - 1])
                ---@diagnostic disable-next-line: need-check-nil
                addonCore.db.global.gossipTriggered[id] = nil
                addonCore:RefreshAdvOptions(id)
            end
        }
    }
}

local addNew_Temp = {}
local addNew_Temp_get = function(info)
    return addNew_Temp[info[#info]]
end
local addNew_Temp_set = function(info, value)
    addNew_Temp[info[#info]] = value
end
local gossipOptionTemplate_AddNew = {
    name = "",
    type = "group",
    inline = true,
    order = -1,
    args = {
        name = {
            order = 1,
            name = L["Gossip ID"],
            type = "input",
            get = addNew_Temp_get,
            set = addNew_Temp_set
        },
        sourceID = {
            order = 2,
            type = "input",
            name = L["Source Node ID"],
            validate = function(_, value)
                local key, message = addonCore:ParseGossipEndpoint(0, value)
                return key ~= nil or message
            end,
            get = addNew_Temp_get,
            set = addNew_Temp_set
        },
        destinationID = {
            order = 3,
            type = "input",
            name = L["Destination Node ID"],
            validate = function(_, value)
                local key, message = addonCore:ParseGossipEndpoint(0, value)
                return key ~= nil or message
            end,
            get = addNew_Temp_get,
            set = addNew_Temp_set
        },
        addNew = {
            order = 4,
            name = L["Add New"],
            type = "execute",
            func = function()
                local id = tonumber(addNew_Temp.name)
                if not id or not addNew_Temp.sourceID or not addNew_Temp.destinationID then
                    return
                end
                local source = addonCore:ParseGossipEndpoint(id, addNew_Temp.sourceID)
                local destination = addonCore:ParseGossipEndpoint(id, addNew_Temp.destinationID)
                if not source or not destination then
                    return
                end
                addonCore.db.global.gossipTriggered[id] = {source, destination}
                wipe(addNew_Temp)
                addonCore:RefreshAdvOptions(id)
            end
        }
    }
}

function addonCore:GetModuleStatus(info)
    return addonCore.db.profile.moduleState[info[#info]]
end

function addonCore:RefreshAdvOptions(optionID)
    local opt = wipe(self.configOptionsTable.args.gossipConfigTab.args)
    for k, _ in pairs(addonCore.db.global.gossipTriggered) do
        opt[tostring(k)] = gossipOptionTemplate
    end
    opt.AddNewGossipID = gossipOptionTemplate_AddNew
    LibStub("AceConfigRegistry-3.0"):NotifyChange(addonName)
    self:RefreshGossipEditor(optionID)
end

-- Keep the existing command paths; only Profiles is rendered by AceConfigDialog.
addonCore.configOptionsTable = {
    type = "group",
    name = L["OnFlight Options"],
    handler = addonCore,
    get = "GetOption",
    set = "SetOption",
    childGroups = "tab",
    args = {
        misc = {
            name = L["Main Options"],
            type = "group",
            order = 10,
            width = "full",
            args = {
                showChat = {
                    name = L["Show Chat Messages"],
                    desc = L["Show Flight Status Messages in Chat Window"],
                    type = "toggle",
                    order = 10
                },
                showGossipConfig = {
                    name = L["Show Diagnostic IDs"],
                    desc = L["Show gossip option IDs and taxi-node IDs."],
                    type = "toggle",
                    order = 20,
                    get = function(info)
                        return addonCore.db.profile.showGossipConfig
                    end,
                    set = function(_, option)
                        addonCore.db.profile.showGossipConfig = option
                        addonCore:RefreshSettings("showGossipConfig")
                        addonCore:RefreshDiagnostics()
                    end
                },
                moduleControl = {
                    name = L["Module Control"],
                    type = "group",
                    inline = true,
                    order = 100,
                    args = {
                        StatusBarModule = {
                            name = L["Flight Timer Bar"],
                            desc = L["The Built in Timer Bar that comes with OnFlight"],
                            type = "toggle",
                            get = "GetModuleStatus",
                            set = "SetModuleStatus"

                        }
                    }
                }
            }
        },
        gossipConfigTab = {
            name = L["Gossip Configuration"],
            type = "group",
            order = 900,
            args = {}
        }
    }
}

local optionsTable_SetPoint_Dictionary = {
    ["TOPLEFT"] = L["TOPLEFT"],
    ["TOP"] = L["TOP"],
    ["TOPRIGHT"] = L["TOPRIGHT"],
    ["LEFT"] = L["LEFT"],
    ["CENTER"] = L["CENTER"],
    ["RIGHT"] = L["RIGHT"],
    ["BOTTOMLEFT"] = L["BOTTOMLEFT"],
    ["BOTTOM"] = L["BOTTOM"],
    ["BOTTOMRIGHT"] = L["BOTTOMRIGHT"]

}
local optionsTable_SetPoint_SortedList = {"TOPLEFT", "TOP", "TOPRIGHT", "LEFT", "CENTER", "RIGHT", "BOTTOMLEFT",
                                          "BOTTOM", "BOTTOMRIGHT"}
---

function statusBarModuleCore:GetOption(info)
    local profile = statusBarModuleCore.db.profile
    if info.type == "color" then
        local t = profile[info[#info]]
        if t then
            return t.r, t.g, t.b, t.a
        else
            return math.random(0, 100) / 100, math.random(0, 100) / 100, math.random(0, 100) / 100,
                math.random(0, 100) / 100
        end
    else
        return profile[info[#info]]
    end
end

function statusBarModuleCore:SetOption(info, ...)
    local profile = statusBarModuleCore.db.profile
    if info.type == "color" then
        local red, green, blue, alpha = ...
        profile[info[#info]] = profile[info[#info]] or {}
        profile[info[#info]].r = red
        profile[info[#info]].g = green
        profile[info[#info]].b = blue
        profile[info[#info]].a = alpha
    else
        profile[info[#info]] = ...
    end
    self:OnProfileUpdated()
    addonCore:RefreshSettings("bar_" .. info[#info])
end

function statusBarModuleCore:GetBarLocation(info, ...)
    return statusBarModuleCore.db.profile.barLocation[info[#info]]
end

function statusBarModuleCore:SetBarLocation(info, value)
    statusBarModuleCore.db.profile.barLocation[info[#info]] = value
    self:OnProfileUpdated()
    addonCore:RefreshSettings("bar_" .. info[#info])
end

-- These descriptions remain for AceConfigCmd, not the native settings page.
addonCore.configOptionsTable.plugins = addonCore.configOptionsTable.plugins or {}
addonCore.configOptionsTable.plugins[moduleName] = {
    barOptions = {
        handler = statusBarModuleCore,
        get = "GetOption",
        set = "SetOption",
        name = L["Flight Timer Bar"],
        type = "group",
        order = 100,
        disabled = function(info)
            return not statusBarModuleCore:IsEnabled()
        end,
        args = {
            desc = {
                type = "description",
                name = L[" Shift Click on the Status Bar to send flight info to chat.\n  Control Click & Drag to Move It."],
                order = 1
            },
            resetToDefaults = {
                type = "execute",
                name = L["Reset All Bar Options to Defaults"],
                width = "full",
                func = function() addonCore:ResetBarSettings() end,
                order = 1000
            },
            barOptions = {
                type = "group",
                name = L["Bar Options"],
                inline = true,
                order = 100,
                args = {
                    barLocation = {
                        name = L["Bar Anchor"],
                        type = "group",
                        order = 9,
                        inline = true,
                        get = "GetBarLocation",
                        set = "SetBarLocation",
                        args = {
                            anchorPoint = {
                                type = "select",
                                name = L["Anchor Point"],
                                order = 20,
                                values = optionsTable_SetPoint_Dictionary,
                                sorting = optionsTable_SetPoint_SortedList
                            },
                            relativePoint = {
                                type = "select",
                                name = L["World Frame Anchor Point"],
                                order = 30,
                                desc = L["Status Bar is Always anchored to World Frame"],
                                values = optionsTable_SetPoint_Dictionary,
                                sorting = optionsTable_SetPoint_SortedList
                            },
                            breakFlow = {
                                type = "description",
                                name = " ",
                                order = 39
                            },
                            offsetX = {
                                type = "range",
                                name = L["X Offset"],
                                order = 40,
                                bigStep = 1,
                                min = -1000,
                                max = 1000,
                                softMin = -300,
                                softMax = 300
                            },
                            offsetY = {
                                type = "range",
                                name = L["Y Offset"],
                                order = 50,
                                bigStep = 1,
                                min = -1000,
                                max = 1000,
                                softMin = -300,
                                softMax = 300
                            }
                        }
                    },
                    size = {
                        name = L["Bar Size"],
                        type = "group",
                        order = 10,
                        inline = true,
                        args = {
                            barHeight = {
                                name = L["Height"],
                                type = "range",
                                order = 10,
                                min = 10,
                                max = 300,
                                step = 1
                            },
                            barWidth = {
                                name = L["Width"],
                                type = "range",
                                order = 20,
                                min = 10,
                                max = 1000,
                                step = 10
                            }
                        }
                    },
                    LookFeel = {
                        name = L["Look and Feel"],
                        type = "group",
                        order = 20,
                        inline = true,
                        width = "normal",
                        args = {
                            barTexture = {
                                name = L["Bar Texture"],
                                type = "select",
                                order = 10,
                                values = function()
                                    return LSM:HashTable("statusbar")
                                end
                            },
                            backgroundColor = {
                                name = L["Background Color"],
                                type = "color",
                                order = 20
                            },
                            barColor = {
                                name = L["Known Flight Color"],
                                type = "color",
                                order = 30
                            },
                            unknownFlightColor = {
                                name = L["Unknown Flight Color"],
                                type = "color",
                                order = 40
                            }
                        }
                    },
                    borderSettings = {
                        name = L["Border Settings"],
                        type = "group",
                        order = 30,
                        inline = true,
                        args = {
                            borderTexture = {
                                name = L["Border Texture"],
                                type = "select",
                                order = 10,
                                values = function()
                                    return LSM:HashTable("border")
                                end
                            },
                            borderColor = {
                                name = L["Border Color"],
                                type = "color",
                                order = 20
                            }
                        }
                    }
                }
            },
            textOptions = {
                name = L["Display"],
                type = "group",
                order = 200,
                inline = true,
                args = {
                    compactMode = {
                        name = L["Compact Mode"],
                        type = "toggle",
                        order = 9
                    },
                    shortNames = {
                        name = L["Short Names"],
                        type = "toggle",
                        order = 10,
                        disabled = function()
                            return statusBarModuleCore.db.profile.compactMode
                        end
                    },
                    fontOptions = {
                        name = L["Font Options"],
                        type = "group",
                        inline = true,
                        args = {
                            fontName = {
                                name = L["Font"],
                                type = "select",
                                values = function()
                                    return LSM:HashTable("font")
                                end,
                                order = 10
                            },
                            fontSize = {
                                name = L["Font Size"],
                                type = "input",
                                order = 20
                            },
                            fontColor = {
                                name = L["Font Color"],
                                type = "color",
                                order = 30
                            }
                        }
                    }
                }
            },
            testButtons = {
                type = "group",
                inline = true,
                name = L["Show/Test Flight Timer Bar"],
                order = 350,
                args = {
                    ["testKnown"] = {
                        type = "execute",
                        name = L["Start Known Flight"],
                        order = 1,
                        func = function()
                            statusBarModuleCore:StartTimerBar(L["City1, Zone1"], L["City2, Zone2"], 300)
                        end
                    },
                    ["testUnknown"] = {
                        type = "execute",
                        name = L["Start Unknown Flight"],
                        order = 2,
                        func = function()
                            statusBarModuleCore:StartTimerBar(L["Unknown1, Zone1"], L["Unknown2, Zone2"], nil, nil, true)
                        end
                    },
                    ["stopTest"] = {
                        type = "execute",
                        name = L["Stop Flight"],
                        order = 3,
                        func = function()
                            statusBarModuleCore:StopTimerBar()
                        end
                    }
                }
            }
        }
    }
}

function addonCore:InitializeConfig()
    self.configOptionsTable.args.profiles = LibStub("AceDBOptions-3.0"):GetOptionsTable(self.db)
    self.configOptionsTable.args.profiles.order = 800

    LibStub("AceConfig-3.0"):RegisterOptionsTable(addonName, self.configOptionsTable)
    self:RegisterChatCommand("OnFlight", "ChatCommand")
end
