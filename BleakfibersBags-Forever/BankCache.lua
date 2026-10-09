local addonName, BFB = ...

BFB.BankCache = {}
local BankCache = BFB.BankCache

local playerRealm = GetRealmName and GetRealmName() or "DefaultRealm"
local playerName = UnitName and UnitName("player") or "Player"

-- Initialize or Get Bank Cache Table in SavedVariables
local function GetCacheDB()
    local db = BFB.db or {}
    db.bankCache = db.bankCache or {}
    db.bankCache[playerRealm] = db.bankCache[playerRealm] or {}
    return db.bankCache[playerRealm]
end

-- Scan and Record Current Bank Contents
function BankCache:ScanBank()
    local realmDB = GetCacheDB()
    local charData = {
        name = playerName,
        lastUpdated = time and time() or 0,
        totalSlots = 0,
        freeSlots = 0,
        items = {},
        itemCounts = {},
    }

    -- 1. Main Bank Container (Bag -1)
    local mainBankSlots = BFB.GetNumSlots(-1) or 0
    if mainBankSlots > 0 then
        charData.totalSlots = charData.totalSlots + mainBankSlots
        for slot = 1, mainBankSlots do
            local info = BFB.GetItemInfo(-1, slot)
            if info and info.iconFileID then
                local link = info.hyperlink
                local itemID = info.itemID
                if not itemID and link then
                    itemID = tonumber(link:match("item:(%d+)"))
                end

                local entry = {
                    bag = -1,
                    slot = slot,
                    icon = info.iconFileID,
                    count = info.stackCount or 1,
                    quality = info.quality or 1,
                    link = link,
                    itemID = itemID,
                }
                table.insert(charData.items, entry)

                if itemID then
                    charData.itemCounts[itemID] = (charData.itemCounts[itemID] or 0) + (info.stackCount or 1)
                end
            else
                charData.freeSlots = charData.freeSlots + 1
            end
        end
    end

    -- 2. Bank Bags (Bags 5 to 10 in Classic)
    local numBankBags = NUM_BANKBAGSLOTS or 6
    for i = 1, numBankBags do
        local bagID = 4 + i
        local numSlots = BFB.GetNumSlots(bagID) or 0
        if numSlots > 0 then
            charData.totalSlots = charData.totalSlots + numSlots
            for slot = 1, numSlots do
                local info = BFB.GetItemInfo(bagID, slot)
                if info and info.iconFileID then
                    local link = info.hyperlink
                    local itemID = info.itemID
                    if not itemID and link then
                        itemID = tonumber(link:match("item:(%d+)"))
                    end

                    local entry = {
                        bag = bagID,
                        slot = slot,
                        icon = info.iconFileID,
                        count = info.stackCount or 1,
                        quality = info.quality or 1,
                        link = link,
                        itemID = itemID,
                    }
                    table.insert(charData.items, entry)

                    if itemID then
                        charData.itemCounts[itemID] = (charData.itemCounts[itemID] or 0) + (info.stackCount or 1)
                    end
                else
                    charData.freeSlots = charData.freeSlots + 1
                end
            end
        end
    end

    realmDB[playerName] = charData
end

-- Retrieve Cached Bank Data for a Character
function BankCache:GetCachedBank(targetName)
    local realmDB = GetCacheDB()
    local name = targetName or playerName
    return realmDB[name]
end

-- Get Total Quantity of an Item in the Bank across Current Character and Alts
function BankCache:GetBankItemCount(itemID)
    if not itemID then return 0, {} end
    local realmDB = GetCacheDB()
    local total = 0
    local breakdown = {}

    for char, data in pairs(realmDB) do
        if data.itemCounts and data.itemCounts[itemID] then
            local count = data.itemCounts[itemID]
            total = total + count
            table.insert(breakdown, { char = char, count = count })
        end
    end

    return total, breakdown
end

-- Hook Tooltips to Display Bank Count
function BankCache:InitTooltipHook()
    local function AddBankInfoToTooltip(tooltip, data)
        local db = BFB.db or {}
        if db.showBankTooltip == false then return end
        if not tooltip or not tooltip.AddLine or not tooltip.AddDoubleLine then return end

        local link
        if data and data.hyperlink then
            link = data.hyperlink
        elseif tooltip.GetItem then
            local _, l = tooltip:GetItem()
            link = l
        end

        local itemID
        if data and data.id then
            itemID = data.id
        elseif link then
            local match = link:match("item:(%d+)")
            if match then itemID = tonumber(match) end
        end
        if not itemID then return end

        local total, breakdown = BankCache:GetBankItemCount(itemID)
        if total > 0 then
            if #breakdown == 1 and breakdown[1].char == playerName then
                tooltip:AddDoubleLine("|cff00c0ffBank Stock:|r", string.format("|cffffffff%d|r", total))
            else
                tooltip:AddLine(string.format("|cff00c0ffBank Stock:|r |cffffffff%d total|r", total))
                for _, entry in ipairs(breakdown) do
                    local charLabel = (entry.char == playerName) and (entry.char .. " (You)") or entry.char
                    tooltip:AddDoubleLine("  " .. charLabel, tostring(entry.count), 0.7, 0.7, 0.7, 1, 1, 1)
                end
            end
        end
    end

    if TooltipDataProcessor and TooltipDataProcessor.AddTooltipPostCall then
        TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Item, AddBankInfoToTooltip)
    else
        GameTooltip:HookScript("OnTooltipSetItem", AddBankInfoToTooltip)
    end
end

