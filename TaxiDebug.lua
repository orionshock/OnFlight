-- Opt-in live-client probe. /oftaxi on, off, snap [mapID], status, clear
-- No taxi actions are invoked here; secure post-hooks only observe user/UI actions.
-- Compact captures persist in SavedVariables; chat shows concise summaries.
local addonName = ...
local L = LibStub("AceLocale-3.0"):GetLocale(addonName)
local frame = CreateFrame("Frame")
local enabled, lastMapID = false, nil
local hooks = {}
local MAX_NODES, MAX_HOPS = 500, 100
local mapSession = 0
local lastOnTaxi

local function database()
    if type(OnFlightTaxiDebugDB) ~= "table" then OnFlightTaxiDebugDB = {} end
    local db = OnFlightTaxiDebugDB
    db.version = 2
    db.records = db.records or {}
    return db
end

local function text(value)
    if value == nil then return "?" end
    return tostring(value):gsub("|", "||"):gsub("[\r\n]", " ")
end

local function pack(...)
    return { n = select("#", ...), ... }
end

-- Copy API-owned tables now; preserve nil return positions via pack.n.
-- Expand vector objects into coordinates for readable chat output.
local function copy(value, seen, depth)
    local kind = type(value)
    if kind ~= "table" and kind ~= "userdata" then
        if kind == "function" or kind == "thread" then return tostring(value) end
        return value
    end
    if depth > 12 then return "<depth limit>" end
    if seen[value] then return "<cycle>" end
    seen[value] = true
    local result = {}
    local ok, x, y = pcall(function() return value:GetXY() end)
    if ok then
        seen[value] = nil
        return { x = x, y = y }
    end
    if kind == "table" then
        for k, v in pairs(value) do
            if type(k) == "string" or type(k) == "number" then
                if type(v) ~= "function" then result[k] = copy(v, seen, depth + 1) end
            end
        end
    elseif not ok then
        result.opaque = tostring(value)
    end
    seen[value] = nil
    return result
end

local function call(fn, ...)
    if type(fn) ~= "function" then return { missing = true } end
    local values = pack(pcall(fn, ...))
    if not values[1] then return { error = tostring(values[2]) } end
    local result = { n = values.n - 1 }
    for i = 2, values.n do result[i - 1] = copy(values[i], {}, 0) end
    return { values = result }
end

local function first(result)
    return result.values and result.values[1]
end

local function value(result)
    if result.missing then return "unavailable" end
    if result.error then return "ERROR: " .. text(result.error) end
    return text(first(result))
end

local function listCount(result)
    local list = first(result)
    if type(list) ~= "table" then return value(result) end
    local total = 0
    for _ in pairs(list) do total = total + 1 end
    return tostring(total)
end

local function arguments(args)
    local parts = {}
    for i = 1, args.n do parts[i] = text(args[i]) end
    return table.concat(parts, ", ")
end

local function compactSnapshot(data)
    local identity = data.identity
    local current = #identity.currentSlots == 1 and identity.slots[identity.currentSlots[1]]
    local result = { reason = data.reason, mapID = first(data.mapID), playerMapID = first(data.playerMapID),
        mapOpen = data.mapOpen, onTaxi = first(data.onTaxi), npc = first(data.npcName),
        npcGUID = first(data.npcGUID), sourceID = current and current.nodeID,
        selectedSlot = identity.selectedSlot, destinationID = identity.selectedNodeID,
        nodeCount = first(data.numNodes), issues = identity.issues, maps = {}, errors = {} }
    local function nodeSummary(slot, node)
        local legacy = data.nodes[slot]
        local route = {}
        for hop, edge in ipairs(node.routeIDs or {}) do
            if hop == 1 then route[1] = edge.sourceID or "unresolved" end
            route[#route + 1] = edge.destinationID or "unresolved"
        end
        return { slot = slot, id = node.nodeID, name = node.legacyName, type = node.legacyType,
            state = node.state, direct = first(legacy.direct), cost = first(legacy.cost),
            route = #route > 0 and route or nil, startsAtCurrent = node.routeStartsAtCurrent,
            endsAtDestination = node.routeEndsAtDestination }
    end
    -- Record the full slot directory only on open/manual capture, not on every action.
    if data.reason == "TAXIMAP_OPENED" or data.reason == "manual" then
        result.nodes = {}
        for slot, node in ipairs(identity.slots) do result.nodes[slot] = nodeSummary(slot, node) end
    end
    local selected = identity.slots[identity.selectedSlot]
    if selected then result.selection = nodeSummary(identity.selectedSlot, selected) end
    for id, map in pairs(data.maps) do
        result.maps[id] = { allCount = listCount(map.all), forMapCount = listCount(map.forMap) }
    end
    local function errors(item, path)
        if type(item) ~= "table" then return end
        if item.error or item.missing then
            result.errors[#result.errors + 1] = path .. ": " .. (item.error or "unavailable")
        else
            for key, child in pairs(item) do errors(child, path .. "/" .. key) end
        end
    end
    errors(data, "snapshot")
    if #result.errors == 0 then result.errors = nil end
    return result
end

local function record(kind, data)
    local db = database()
    db.sequence = (db.sequence or 0) + 1
    local saved = kind == "snapshot" and compactSnapshot(data) or data
    saved.kind, saved.sequence, saved.time = kind, db.sequence, GetTime()
    saved.run, saved.mapSession = db.run or 0, mapSession
    db.records[#db.records + 1] = saved
    local prefix = "|cff66ccff" .. L["[Taxi %d]"]:format(db.sequence) .. "|r "
    local function line(message) print(prefix .. message) end
    if kind == "snapshot" and not db.verbose then
        local identity = data.identity
        local resolved = 0
        for _, node in ipairs(identity.slots) do if node.resolved then resolved = resolved + 1 end end
        line(L["%s: map=%s; %s; IDs=%d/%d; checks=%d"]:format(data.reason, value(data.mapID),
            data.mapOpen and L["OPEN"] or L["CLOSED"], resolved, #data.nodes, #identity.issues))
        if identity.selectedSlot then
            line(L["Selected slot %d -> ID %s"]:format(identity.selectedSlot, text(identity.selectedNodeID)))
        end
        local current = #identity.currentSlots == 1 and identity.slots[identity.currentSlots[1]]
        if current then line(L["At %s (ID %s)"]:format(text(current.legacyName), text(current.nodeID))) end
        if #identity.issues > 0 then line(L["CHECK: %s; full details saved"]:format(identity.issues[1])) end
        return
    end
    if kind == "snapshot" then
        local identity = data.identity
        line(L["%s — session %d; map %s; %s; flying=%s"]:format(data.reason, data.mapSession,
            value(data.mapID), data.mapOpen and L["OPEN"] or L["CLOSED"], value(data.onTaxi)))
        line(L["Context: %s; player map=%s; %s; %s"]:format(value(data.npcName), value(data.playerMapID),
            value(data.faction), value(data.locale)))
        local mapIDs = {}
        for id in pairs(data.maps) do mapIDs[#mapIDs + 1] = id end
        table.sort(mapIDs)
        for _, id in ipairs(mapIDs) do
            local map = data.maps[id]
            line(L["Map %d: GetAllTaxiNodes=%s; GetTaxiNodesForMap=%s"]:format(id, listCount(map.all), listCount(map.forMap)))
        end
        local resolved = 0
        for _, node in ipairs(identity.slots) do if node.resolved then resolved = resolved + 1 end end
        line(L["IDs resolved: %d/%d slots; legacy nodes=%s"]:format(resolved, #data.nodes, value(data.numNodes)))
        for slot, legacy in ipairs(data.nodes) do
            local node = identity.slots[slot] or {}
            local marker = first(legacy.type) == "CURRENT" and " " .. L["[HERE]"] or ""
            if slot == identity.selectedSlot then marker = marker .. " " .. L["[SELECTED]"] end
            line(L["Slot %d -> ID %s%s | %s | %s | direct=%s | cost=%s"]:format(slot, text(node.nodeID),
                marker, value(legacy.name), value(legacy.type), value(legacy.direct), value(legacy.cost)))
            if node.nameMatches == false then line(L["CHECK slot %d: API names differ"]:format(slot)) end
            if node.routeIDs and #node.routeIDs > 0 then
                local path = { text(node.routeIDs[1].sourceID) }
                for _, edge in ipairs(node.routeIDs) do path[#path + 1] = text(edge.destinationID) end
                -- Keep long routes readable without dumping the individual API calls.
                for start = 1, #path, 12 do
                    local heading = start > 1 and L["Route to ID %s (continued): %s"] or L["Route to ID %s: %s"]
                    line(heading:format(text(node.nodeID), table.concat(path, " -> ", start, math.min(start + 11, #path))))
                end
                if not node.routeStartsAtCurrent or not node.routeEndsAtDestination then
                    line(L["CHECK slot %d: route endpoints do not match current/destination IDs"]:format(slot))
                end
            elseif legacy.numRoutes.error or legacy.numRoutes.missing then
                line(L["CHECK slot %d: GetNumRoutes=%s"]:format(slot, value(legacy.numRoutes)))
            end
            if legacy.routesTruncated then line(L["CHECK slot %d: route limit reached"]:format(slot)) end
        end
        if identity.selectedSlot then
            line(L["Selection: slot %d -> ID %s"]:format(identity.selectedSlot, text(identity.selectedNodeID)))
        end
        if data.nodesTruncated then line(L["CHECK: node limit reached"]) end
        for _, issue in ipairs(identity.issues) do line(L["CHECK: %s"]:format(issue)) end
    elseif kind == "client" then
        line(L["Client: %s"]:format(data.build.values and arguments(data.build.values) or value(data.build)))
    elseif kind == "hook" then
        line(L["Observe %s: %s"]:format(data.name, data.ok and L["ready"] or text(data.error)))
    elseif kind == "event" or kind == "action" then
        line(kind:upper() .. " " .. data.name .. "(" .. arguments(data.args) .. ")")
    elseif kind == "selection" then
        line(L["SELECT slot %d (%s, before click)"]:format(data.slot, text(data.mouseButton)))
    elseif kind == "flight-state" then
        line(L["FLIGHT %s -> %s; session %d"]:format(text(data.previous), text(data.onTaxi), data.mapSession))
    end
end

local function count(total, limit)
    if type(total) ~= "number" or total ~= total or total < 0 then return 0 end
    return math.min(math.floor(total), limit)
end

-- Join only on explicit IDs/slotIndex. Names and positions are evidence, never keys.
local function correlate(data, mapID, selectedSlot)
    local result = { mapID = mapID, slots = {}, issues = {}, currentSlots = {} }
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
                else ids[id] = true end
                if type(slot) == "number" and slot > 0 and slot == math.floor(slot) then
                    if bySlot[slot] then duplicateSlots[slot] = true end
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
        local row = { slotIndex = slot, legacyName = first(legacy.name),
            legacyType = first(legacy.type), legacyPosition = legacy.position,
            resolved = false }
        result.slots[slot] = row
        if modern and not duplicateSlots[slot] and not duplicateIDs[modern.nodeID]
            and type(modern.nodeID) == "number" and modern.nodeID > 0 then
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
        if row.legacyType == "CURRENT" then table.insert(result.currentSlots, slot) end
    end
    for slot, legacy in ipairs(data.nodes) do
        local row = result.slots[slot]
        row.routeIDs = {}
        local previousID
        for hop, route in ipairs(legacy.routes) do
            local source = result.slots[first(route.sourceSlot)]
            local destination = result.slots[first(route.destinationSlot)]
            local edge = { sourceSlot = first(route.sourceSlot), destinationSlot = first(route.destinationSlot),
                sourceID = source and source.nodeID, destinationID = destination and destination.nodeID }
            edge.resolved = edge.sourceID ~= nil and edge.destinationID ~= nil
            if not edge.resolved then table.insert(result.issues, "Unresolved route hop: " .. slot .. "/" .. hop) end
            if hop > 1 and previousID ~= edge.sourceID then
                table.insert(result.issues, "Route discontinuity: " .. slot .. "/" .. hop)
            end
            previousID = edge.destinationID
            row.routeIDs[hop] = edge
        end
        if #row.routeIDs > 0 then
            row.routeEndsAtDestination = previousID ~= nil and previousID == row.nodeID
            local current = #result.currentSlots == 1 and result.slots[result.currentSlots[1]]
            row.routeStartsAtCurrent = current and current.nodeID ~= nil
                and row.routeIDs[1].sourceID == current.nodeID or false
        end
    end
    if #result.currentSlots ~= 1 then table.insert(result.issues, "Expected exactly one CURRENT legacy slot") end
    result.selectedSlot = selectedSlot
    result.selectedNodeID = result.slots[selectedSlot] and result.slots[selectedSlot].nodeID
    return result
end

local snapshot
local observedButtons = setmetatable({}, { __mode = "k" })
local function observeButtons(nodeCount)
    for slot = 1, nodeCount do
        local button = _G["TaxiButton" .. slot]
        if button and not observedButtons[button] then
            observedButtons[button] = true
            button:HookScript("PreClick", function(self, mouseButton)
                if enabled then
                    record("selection", { slot = self:GetID(), mouseButton = mouseButton, phase = "PreClick" })
                    snapshot("TaxiButton PreClick", nil, self:GetID())
                end
            end)
        end
    end
end

snapshot = function(reason, requestedMapID, selectedSlot)
    local data = { reason = reason, mapOpen = frame.mapOpen, mapSession = mapSession,
        mapID = call(GetTaxiMapID), numNodes = call(NumTaxiNodes),
        onTaxi = call(UnitOnTaxi, "player"), nodes = {}, maps = {},
        playerMapID = call(C_Map and C_Map.GetBestMapForUnit, "player"),
        faction = call(UnitFactionGroup, "player"), locale = call(GetLocale),
        npcGUID = call(UnitGUID, "npc"), npcName = call(UnitName, "npc") }
    local currentMapID = first(data.mapID)
    if type(currentMapID) == "number" and currentMapID > 0 then lastMapID = currentMapID end
    data.lastMapID = lastMapID
    local maps = {}
    for _, id in pairs({ current = currentMapID, previous = lastMapID, requested = requestedMapID,
        player = first(data.playerMapID) }) do
        if type(id) == "number" and id > 0 then maps[id] = true end
    end
    for id in pairs(maps) do
        data.maps[id] = {
            all = call(C_TaxiMap and C_TaxiMap.GetAllTaxiNodes, id),
            forMap = call(C_TaxiMap and C_TaxiMap.GetTaxiNodesForMap, id),
        }
    end
    data.noMapID = next(maps) == nil
    local nodeCount = count(first(data.numNodes), MAX_NODES)
    data.nodesTruncated = type(first(data.numNodes)) == "number" and first(data.numNodes) > MAX_NODES
    for slot = 1, nodeCount do
        local node = { name = call(TaxiNodeName, slot), type = call(TaxiNodeGetType, slot),
            position = call(TaxiNodePosition, slot), cost = call(TaxiNodeCost, slot),
            direct = call(TaxiIsDirectFlight, slot), numRoutes = call(GetNumRoutes, slot), routes = {} }
        data.nodes[slot] = node
        -- Probe the optional destination-only coordinate form separately from each hop.
        node.coordinates = {}
        for _, name in ipairs({ "TaxiGetSrcX", "TaxiGetSrcY", "TaxiGetDestX", "TaxiGetDestY" }) do
            node.coordinates[name] = call(_G[name], slot)
        end
        local routeCount = first(node.numRoutes)
        node.routesTruncated = type(routeCount) == "number" and routeCount > MAX_HOPS
        for hop = 1, count(routeCount, MAX_HOPS) do
            local route = { sourceSlot = call(TaxiGetNodeSlot, slot, hop, true),
                destinationSlot = call(TaxiGetNodeSlot, slot, hop, false) }
            for _, name in ipairs({ "TaxiGetSrcX", "TaxiGetSrcY", "TaxiGetDestX", "TaxiGetDestY" }) do
                route[name] = call(_G[name], slot, hop)
            end
            node.routes[hop] = route
        end
    end
    -- Only the current taxi map is authoritative for slot joins. A retained map ID
    -- is probed after close but must not silently resolve a later session's slots.
    data.identity = correlate(data, currentMapID, selectedSlot)
    if frame.mapOpen then observeButtons(nodeCount) end
    record("snapshot", data)
end

local function installHooks()
    for _, name in ipairs({ "CloseTaxiMap", "SetTaxiMap", "TakeTaxiNode", "TaxiRequestEarlyLanding" }) do
        if not hooks[name] and type(_G[name]) == "function" then
            local action = name
            local ok, err = pcall(hooksecurefunc, action, function(...)
                if not enabled then return end
                record("action", { name = action, args = copy(pack(...), {}, 0) })
                if action == "TakeTaxiNode" then snapshot("TakeTaxiNode post-call", nil, (...)) end
            end)
            hooks[name] = ok
            record("hook", { name = name, ok = ok, error = not ok and tostring(err) or nil })
        end
    end
end

frame:RegisterEvent("TAXIMAP_OPENED")
frame:RegisterEvent("TAXIMAP_CLOSED")
frame:RegisterEvent("PLAYER_LOGIN")
frame:SetScript("OnEvent", function(_, event, ...)
    if event == "PLAYER_LOGIN" then
        local db = database()
        db.run = (db.run or 0) + 1
        if db.enabled then SlashCmdList.ONFLIGHTTAXIDEBUG("on") end
        return
    end
    if event == "TAXIMAP_OPENED" then mapSession = mapSession + 1 end
    frame.mapOpen = event == "TAXIMAP_OPENED"
    if not enabled then return end
    record("event", { name = event, args = copy(pack(...), {}, 0) })
    snapshot(event)
end)
frame:SetScript("OnUpdate", function()
    if not enabled then return end
    local onTaxi = first(call(UnitOnTaxi, "player"))
    if onTaxi ~= lastOnTaxi then
        record("flight-state", { mapSession = mapSession, previous = lastOnTaxi, onTaxi = onTaxi })
        lastOnTaxi = onTaxi
        snapshot("UnitOnTaxi changed")
    end
end)

SLASH_ONFLIGHTTAXIDEBUG1 = "/oftaxi"
SlashCmdList.ONFLIGHTTAXIDEBUG = function(input)
    local command, argument = (input or ""):match("^%s*(%S*)%s*(.-)%s*$")
    command = command:lower()
    if command == "on" then
        enabled = true
        database().enabled = true
        lastOnTaxi = first(call(UnitOnTaxi, "player"))
        record("client", { build = call(GetBuildInfo) })
        installHooks()
        snapshot("enabled")
    elseif command == "off" then
        enabled = false
        database().enabled = false
    elseif command == "clear" then
        local db = database()
        db.records, db.dropped = {}, 0
        print(L["OnFlight taxi debug: saved captures cleared."])
    elseif command == "verbose" then
        database().verbose = argument:lower() == "on"
        print(L["OnFlight taxi debug: detailed chat %s"]:format(database().verbose and L["ON"] or L["OFF"]))
    elseif command == "snap" then
        local mapID = tonumber(argument)
        if argument ~= "" and (not mapID or mapID <= 0 or mapID ~= math.floor(mapID)) then
            print(L["OnFlight taxi debug: mapID must be a positive integer."])
            return
        end
        snapshot("manual", mapID)
    elseif command ~= "status" then
        print(L["OnFlight taxi debug: /oftaxi on | off | snap [mapID] | status | clear | verbose on/off"])
        return
    end
    print(L["OnFlight taxi debug: %s; %d captures; /reload flushes SavedVariables."]:format(
        enabled and L["ON"] or L["OFF"], #database().records))
end
