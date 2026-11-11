-- Opt-in live-client probe, controlled by the current OnFlight profile.
-- No taxi actions are invoked here; secure post-hooks only observe user/UI actions.
-- Timestamped log lines persist in SavedVariables; chat shows concise summaries.
local addonName, addonCore = ...
local L = LibStub("AceLocale-3.0"):GetLocale(addonName)
local frame = CreateFrame("Frame")
local messages = {}
LibStub("AceEvent-3.0"):Embed(messages)
local enabled, lastMapID = false, nil
local hooks = {}
local MAX_NODES, MAX_HOPS = 500, 100
local mapSession = 0
local lastOnTaxi

local function database()
    if type(OnFlightTaxiDebugDB) ~= "table" then
        OnFlightTaxiDebugDB = {}
    end
    local db = OnFlightTaxiDebugDB
    db.version = 3
    db.records = db.records or {}
    return db
end

local function text(value)
    if value == nil then
        return "?"
    end
    return tostring(value):gsub("|", "||"):gsub("[\r\n]", " ")
end

local function pack(...)
    return {
        n = select("#", ...),
        ...
    }
end

-- API results are inspected synchronously; only formatted strings enter SavedVariables.
local function call(fn, ...)
    if type(fn) ~= "function" then
        return {
            missing = true
        }
    end
    local values = pack(pcall(fn, ...))
    if not values[1] then
        return {
            error = tostring(values[2])
        }
    end
    local result = {
        n = values.n - 1
    }
    for i = 2, values.n do
        result[i - 1] = values[i]
    end
    return {
        values = result
    }
end

local function first(result)
    return result.values and result.values[1]
end

local function value(result)
    if result.missing then
        return "unavailable"
    end
    if result.error then
        return "ERROR: " .. text(result.error)
    end
    return text(first(result))
end

local function listCount(result)
    local list = first(result)
    if type(list) ~= "table" then
        return value(result)
    end
    local total = 0
    for _ in pairs(list) do
        total = total + 1
    end
    return tostring(total)
end

local function arguments(args)
    local parts = {}
    for i = 1, args.n do
        parts[i] = text(args[i])
    end
    return table.concat(parts, ", ")
end

local function record(kind, data)
    local db = database()
    local function save(message)
        db.sequence = (db.sequence or 0) + 1
        db.records[#db.records + 1] = ("%.3f [run %d, session %d, #%d] %s"):format(
            GetTime(), db.run or 0, mapSession, db.sequence, message)
    end
    local function line(message, detail)
        save(message)
        if not detail then
            print("|cff66ccff" .. L["[Taxi %d]"]:format(db.sequence) .. "|r " .. message)
        end
    end
    local function route(ids)
        local path = {}
        for _, id in ipairs(ids) do
            path[#path + 1] = text(id)
        end
        line(L["Route: %s"]:format(table.concat(path, " -> ")))
    end
    if kind == "snapshot" then
        local identity = data.identity
        local resolved = 0
        for _, node in ipairs(identity.slots) do
            if node.resolved then resolved = resolved + 1 end
        end
        line(L["%s: map=%s; %s; IDs=%d/%d; checks=%d"]:format(data.reason, value(data.mapID),
            data.mapOpen and L["OPEN"] or L["CLOSED"], resolved, #data.nodes,
            data.mapOpen and #identity.issues or 0))
        if data.mapOpen then
            line(L["Context: %s; player map=%s; %s; %s"]:format(value(data.npcName), value(data.playerMapID),
                value(data.faction), value(data.locale)), true)
            local mapIDs = {}
            for id in pairs(data.maps) do mapIDs[#mapIDs + 1] = id end
            table.sort(mapIDs)
            for _, id in ipairs(mapIDs) do
                local map = data.maps[id]
                line(L["Map %d: GetAllTaxiNodes=%s; GetTaxiNodesForMap=%s"]:format(id, listCount(map.all),
                    listCount(map.forMap)), true)
            end
        end
        local current = #identity.currentSlots == 1 and identity.slots[identity.currentSlots[1]]
        if current then
            line(L["At %s (ID %s)"]:format(text(current.legacyName), text(current.nodeID)))
        end
        for slot, node in ipairs(identity.slots) do
            local selected = slot == identity.selectedSlot
            -- Keep the directory once on open, not every event.
            if selected or data.reason == "TAXIMAP_OPENED" then
                local legacy = data.nodes[slot]
                line(L["Slot %d -> ID %s%s | %s | %s | direct=%s | cost=%s"]:format(slot, text(node.nodeID),
                    selected and " " .. L["[SELECTED]"] or "", text(node.legacyName), text(node.legacyType),
                    value(legacy.direct), value(legacy.cost)), not selected)
                if selected then
                    line(L["Slot %d position: %s"]:format(slot,
                        legacy.position.values and arguments(legacy.position.values) or value(legacy.position)), true)
                end
                if node.routeIDs and #node.routeIDs > 0 then
                    local ids = {node.routeIDs[1].sourceID or "unresolved"}
                    for _, edge in ipairs(node.routeIDs) do
                        ids[#ids + 1] = edge.destinationID or "unresolved"
                    end
                    -- Route details are useful for the selection or an explicit capture.
                    route(ids)
                    if not node.routeStartsAtCurrent or not node.routeEndsAtDestination then
                        line(L["CHECK slot %d: route endpoints do not match current/destination IDs"]:format(slot))
                    end
                end
            end
        end
        if data.nodesTruncated then line(L["CHECK: node limit reached"]) end
        -- Empty API results after closing are expected, not mapping failures.
        if data.mapOpen then
            for index, issue in ipairs(identity.issues) do
                line(L["CHECK: %s"]:format(issue), index > 1)
            end
        end
        local function errors(result, label)
            if result.error or result.missing then
                line(L["%s: %s"]:format(label, value(result)))
            end
        end
        errors(data.mapID, "GetTaxiMapID")
        errors(data.numNodes, "NumTaxiNodes")
        for id, map in pairs(data.maps) do
            errors(map.all, "GetAllTaxiNodes(" .. id .. ")")
            errors(map.forMap, "GetTaxiNodesForMap(" .. id .. ")")
        end
        local selected = identity.selectedSlot and data.nodes[identity.selectedSlot]
        if selected then
            errors(selected.numRoutes, "GetNumRoutes")
            if selected.routesTruncated then
                line(L["CHECK slot %d: route limit reached"]:format(identity.selectedSlot))
            end
        end
    elseif kind == "client" then
        line(L["Client: %s"]:format(data.build.values and arguments(data.build.values) or value(data.build)))
    elseif kind == "hook" then
        line(L["Observe %s: %s"]:format(data.name, data.ok and L["ready"] or text(data.error)), data.ok)
    elseif kind == "event" or kind == "action" or kind == "tracking" then
        line(kind:upper() .. " " .. data.name .. "(" .. arguments(data.args) .. ")")
        if kind == "action" and data.name == "TakeTaxiNode" then
            -- The core captured these IDs before Blizzard closed the taxi map.
            local flight = addonCore:GetCurrentFlight()
            if flight then
                line(L["Flight selected: %s (ID %s) -> %s (ID %s)"]:format(text(flight.sourceName),
                    text(flight.sourceID), text(flight.destinationName), text(flight.destinationID)))
                route(flight.route)
            end
        elseif kind == "action" and data.name == "TaxiRequestEarlyLanding" then
            line(L["Early landing requested; waiting for the actual taxi exit."])
        end
    elseif kind == "selection" then
        line(L["SELECT slot %d (%s, before click)"]:format(data.slot, text(data.mouseButton)))
    elseif kind == "flight-state" then
        line(L["FLIGHT %s -> %s; session %d"]:format(text(data.previous), text(data.onTaxi), data.mapSession))
    end
end

local function count(total, limit)
    if type(total) ~= "number" or total ~= total or total < 0 then
        return 0
    end
    return math.min(math.floor(total), limit)
end

-- Join only on explicit IDs/slotIndex. Names and positions are evidence, never keys.
local function correlate(data, mapID, selectedSlot)
    local result = {
        mapID = mapID,
        slots = {},
        issues = {},
        currentSlots = {}
    }
    local map = data.maps[mapID]
    if not map then
        result.issues[1] = "No taxi-map API results for the current map ID"
        return result
    end
    local all, forMap = first(map.all), first(map.forMap)
    local byID, bySlot, duplicateSlots, duplicateIDs = {}, {}, {}, {}
    if type(forMap) == "table" then
        for _, node in pairs(forMap) do
            if type(node) == "table" and type(node.nodeID) == "number" then
                byID[node.nodeID] = byID[node.nodeID] or {}
                table.insert(byID[node.nodeID], node)
            end
        end
    end
    if type(all) == "table" then
        local ids = {}
        for _, node in pairs(all) do
            if type(node) == "table" then
                local slot, id = node.slotIndex, node.nodeID
                if type(id) ~= "number" or id <= 0 then
                    table.insert(result.issues, "GetAllTaxiNodes entry has no valid nodeID")
                elseif ids[id] then
                    duplicateIDs[id] = true
                    table.insert(result.issues, "Repeated GetAllTaxiNodes nodeID: " .. id)
                else
                    ids[id] = true
                end
                if type(slot) == "number" and slot > 0 and slot == math.floor(slot) then
                    if bySlot[slot] then
                        duplicateSlots[slot] = true
                    end
                    bySlot[slot] = node
                    if not data.nodes[slot] then
                        table.insert(result.issues, "API slot absent from legacy snapshot: " .. slot)
                    end
                else
                    table.insert(result.issues, "GetAllTaxiNodes entry has no usable slotIndex")
                end
            end
        end
    else
        table.insert(result.issues, "GetAllTaxiNodes did not return a node table")
    end
    for slot, legacy in ipairs(data.nodes) do
        local modern = bySlot[slot]
        local row = {
            slotIndex = slot,
            legacyName = first(legacy.name),
            legacyType = first(legacy.type),
            legacyPosition = legacy.position,
            resolved = false
        }
        result.slots[slot] = row
        if modern and not duplicateSlots[slot] and not duplicateIDs[modern.nodeID] and type(modern.nodeID) == "number" and
            modern.nodeID > 0 then
            row.resolved, row.nodeID = true, modern.nodeID
            row.state, row.position = modern.state, modern.position
            row.nameMatches = row.legacyName == modern.name
            row.mapEntries = byID[modern.nodeID]
            row.mapEntryCount = row.mapEntries and #row.mapEntries or 0
            if row.mapEntryCount ~= 1 then
                table.insert(result.issues, "Map-list ID match count for slot " .. slot .. ": " .. row.mapEntryCount)
            end
        else
            table.insert(result.issues, "Unresolved/ambiguous legacy slot: " .. slot)
        end
        if row.legacyType == "CURRENT" then
            table.insert(result.currentSlots, slot)
        end
    end
    for slot, legacy in ipairs(data.nodes) do
        local row = result.slots[slot]
        row.routeIDs = {}
        local previousID
        for hop, route in ipairs(legacy.routes) do
            local source = result.slots[first(route.sourceSlot)]
            local destination = result.slots[first(route.destinationSlot)]
            local edge = {
                sourceSlot = first(route.sourceSlot),
                destinationSlot = first(route.destinationSlot),
                sourceID = source and source.nodeID,
                destinationID = destination and destination.nodeID
            }
            edge.resolved = edge.sourceID ~= nil and edge.destinationID ~= nil
            if not edge.resolved then
                table.insert(result.issues, "Unresolved route hop: " .. slot .. "/" .. hop)
            end
            if hop > 1 and previousID ~= edge.sourceID then
                table.insert(result.issues, "Route discontinuity: " .. slot .. "/" .. hop)
            end
            previousID = edge.destinationID
            row.routeIDs[hop] = edge
        end
        if #row.routeIDs > 0 then
            row.routeEndsAtDestination = previousID ~= nil and previousID == row.nodeID
            local current = #result.currentSlots == 1 and result.slots[result.currentSlots[1]]
            row.routeStartsAtCurrent =
                current and current.nodeID ~= nil and row.routeIDs[1].sourceID == current.nodeID or false
        end
    end
    if #result.currentSlots ~= 1 then
        table.insert(result.issues, "Expected exactly one CURRENT legacy slot")
    end
    result.selectedSlot = selectedSlot
    result.selectedNodeID = result.slots[selectedSlot] and result.slots[selectedSlot].nodeID
    return result
end

local snapshot
local observedButtons = setmetatable({}, {
    __mode = "k"
})
local function observeButtons(nodeCount)
    for slot = 1, nodeCount do
        local button = _G["TaxiButton" .. slot]
        if button and not observedButtons[button] then
            observedButtons[button] = true
            button:HookScript("PreClick", function(self, mouseButton)
                if enabled then
                    record("selection", {
                        slot = self:GetID(),
                        mouseButton = mouseButton,
                        phase = "PreClick"
                    })
                    snapshot("TaxiButton PreClick", self:GetID())
                end
            end)
        end
    end
end

snapshot = function(reason, selectedSlot)
    local data = {
        reason = reason,
        mapOpen = frame.mapOpen,
        mapSession = mapSession,
        mapID = call(GetTaxiMapID),
        numNodes = call(NumTaxiNodes),
        onTaxi = call(UnitOnTaxi, "player"),
        nodes = {},
        maps = {},
        playerMapID = call(C_Map and C_Map.GetBestMapForUnit, "player"),
        faction = call(UnitFactionGroup, "player"),
        locale = call(GetLocale),
        npcGUID = call(UnitGUID, "npc"),
        npcName = call(UnitName, "npc")
    }
    local currentMapID = first(data.mapID)
    if type(currentMapID) == "number" and currentMapID > 0 then
        lastMapID = currentMapID
    end
    data.lastMapID = lastMapID
    local maps = {}
    for _, id in pairs({
        current = currentMapID,
        previous = lastMapID,
        player = first(data.playerMapID)
    }) do
        if type(id) == "number" and id > 0 then
            maps[id] = true
        end
    end
    for id in pairs(maps) do
        data.maps[id] = {
            all = call(C_TaxiMap and C_TaxiMap.GetAllTaxiNodes, id),
            forMap = call(C_TaxiMap and C_TaxiMap.GetTaxiNodesForMap, id)
        }
    end
    data.noMapID = next(maps) == nil
    local nodeCount = count(first(data.numNodes), MAX_NODES)
    data.nodesTruncated = type(first(data.numNodes)) == "number" and first(data.numNodes) > MAX_NODES
    for slot = 1, nodeCount do
        local node = {
            name = call(TaxiNodeName, slot),
            type = call(TaxiNodeGetType, slot),
            position = call(TaxiNodePosition, slot),
            cost = call(TaxiNodeCost, slot),
            direct = call(TaxiIsDirectFlight, slot),
            numRoutes = call(GetNumRoutes, slot),
            routes = {}
        }
        data.nodes[slot] = node
        local routeCount = first(node.numRoutes)
        node.routesTruncated = type(routeCount) == "number" and routeCount > MAX_HOPS
        local captureRoute = slot == selectedSlot
        for hop = 1, captureRoute and count(routeCount, MAX_HOPS) or 0 do
            local route = {
                sourceSlot = call(TaxiGetNodeSlot, slot, hop, true),
                destinationSlot = call(TaxiGetNodeSlot, slot, hop, false)
            }
            node.routes[hop] = route
        end
    end
    -- Only the current taxi map is authoritative for slot joins. A retained map ID
    -- is probed after close but must not silently resolve a later session's slots.
    data.identity = correlate(data, currentMapID, selectedSlot)
    if frame.mapOpen then
        observeButtons(nodeCount)
    end
    record("snapshot", data)
end

local function installHooks()
    for _, name in ipairs({"CloseTaxiMap", "SetTaxiMap", "TakeTaxiNode", "TaxiRequestEarlyLanding"}) do
        if not hooks[name] and type(_G[name]) == "function" then
            local action = name
            local ok, err = pcall(hooksecurefunc, action, function(...)
                if not enabled then
                    return
                end
                record("action", {
                    name = action,
                    args = pack(...)
                })
                if action == "TakeTaxiNode" then
                    snapshot("TakeTaxiNode post-call", (...))
                end
            end)
            hooks[name] = ok
            record("hook", {
                name = name,
                ok = ok,
                error = not ok and tostring(err) or nil
            })
        end
    end
end

frame:SetScript("OnEvent", function(_, event, ...)
    if event == "TAXIMAP_OPENED" then
        mapSession = mapSession + 1
    end
    frame.mapOpen = event == "TAXIMAP_OPENED"
    record("event", {
        name = event,
        args = pack(...)
    })
    snapshot(event)
end)

local function OnUpdate()
    local onTaxi = first(call(UnitOnTaxi, "player"))
    if onTaxi ~= lastOnTaxi then
        record("flight-state", {
            mapSession = mapSession,
            previous = lastOnTaxi,
            onTaxi = onTaxi
        })
        lastOnTaxi = onTaxi
    end
end

function addonCore:UpdateTaxiDebug()
    local active = self.db.profile.taxiDebug == true
    if active == enabled then return end
    enabled = active
    if not enabled then
        frame:UnregisterAllEvents()
        frame:SetScript("OnUpdate", nil)
        messages:UnregisterAllMessages()
        frame.mapOpen, lastOnTaxi = nil, nil
        return
    end

    local db = database()
    db.run = (db.run or 0) + 1
    frame.mapOpen = TaxiFrame:IsShown()
    if frame.mapOpen then mapSession = mapSession + 1 end
    frame:RegisterEvent("TAXIMAP_OPENED")
    frame:RegisterEvent("TAXIMAP_CLOSED")
    frame:SetScript("OnUpdate", OnUpdate)
    for _, message in ipairs({"OnFlight_Taxi_Start", "OnFlight_Taxi_RESUME", "OnFlight_Taxi_Suspend",
                              "OnFlight_Taxi_Stop", "OnFlight_Taxi_EarlyExit", "OnFlight_Taxi_FAILED_ENTRY"}) do
        messages:RegisterMessage(message, function(event, ...)
            record("tracking", {name = event, args = pack(...)})
        end)
    end
    lastOnTaxi = first(call(UnitOnTaxi, "player"))
    record("client", {build = call(GetBuildInfo)})
    installHooks()
    snapshot("enabled")
end

function addonCore:ClearTaxiDebugLog()
    local db = database()
    db.records = {}
    db.sequence = 0
end
