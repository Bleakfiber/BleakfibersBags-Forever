local addonName, BFB = ...

BFB.CategoryEngine = {}
local CategoryEngine = BFB.CategoryEngine

-- Standard Category Definitions in display priority order
CategoryEngine.CATEGORIES = {
    { id = "recent",      name = "Recent Items",        order = 1,  color = { r = 0.20, g = 0.85, b = 1.00 } },
    { id = "quest",       name = "Quest Items",         order = 2,  color = { r = 1.00, g = 0.82, b = 0.00 } },
    { id = "gear",        name = "Equipment & Gear",    order = 3,  color = { r = 0.60, g = 0.40, b = 1.00 } },
    { id = "consumables", name = "Consumables",         order = 4,  color = { r = 0.20, g = 1.00, b = 0.40 } },
    { id = "tradegoods",  name = "Trade Goods & Craft", order = 5,  color = { r = 0.90, g = 0.70, b = 0.30 } },
    { id = "recipes",     name = "Recipes & Plans",     order = 6,  color = { r = 1.00, g = 0.60, b = 0.20 } },
    { id = "misc",        name = "Miscellaneous",       order = 7,  color = { r = 0.75, g = 0.75, b = 0.80 } },
    { id = "junk",        name = "Junk / Trash",        order = 8,  color = { r = 0.60, g = 0.60, b = 0.60 } },
    { id = "empty",       name = "Free Slots",          order = 9,  color = { r = 0.40, g = 0.45, b = 0.50 } },
}

local categoryMap = {}
for _, cat in ipairs(CategoryEngine.CATEGORIES) do
    categoryMap[cat.id] = cat
end

function CategoryEngine:GetCategoryInfo(categoryID)
    return categoryMap[categoryID] or { id = categoryID, name = categoryID, order = 99, color = { r = 1, g = 1, b = 1 } }
end

-- Determine an item's category based on link, itemID, and quality
function CategoryEngine:ClassifyItem(bagID, slotID, itemInfo)
    if not itemInfo or not itemInfo.iconFileID then
        return "empty"
    end

    local quality = itemInfo.quality or 1
    if quality == 0 then
        return "junk"
    end

    local link = itemInfo.hyperlink
    if not link then
        return "misc"
    end

    local itemName, _, itemQuality, itemLevel, itemMinLevel, itemType, itemSubType, itemStackCount, itemEquipLoc, itemTexture, itemSellPrice, classID, subclassID = GetItemInfo(link)
    
    -- 1. Quest Items
    if classID == 12 or itemType == "Quest" or itemInfo.isQuestItem then
        return "quest"
    end

    -- 2. Equipment / Gear (Armor & Weapons)
    if classID == 2 or classID == 4 or itemType == "Armor" or itemType == "Weapon" or (itemEquipLoc and itemEquipLoc ~= "" and itemEquipLoc ~= "INVTYPE_NON_EQUIP") then
        return "gear"
    end

    -- 3. Consumables (Food, Drink, Potions, Bandages, Scrolls)
    if classID == 0 or itemType == "Consumable" then
        return "consumables"
    end

    -- 4. Trade Goods & Crafting Reagents
    if classID == 7 or itemType == "Trade Goods" or itemType == "Reagent" then
        return "tradegoods"
    end

    -- 5. Recipes & Schematics
    if classID == 9 or itemType == "Recipe" then
        return "recipes"
    end

    -- 6. Fallback / Miscellaneous
    return "misc"
end

-- Group a list of bag slots into categorized buckets
function CategoryEngine:GroupSlots(slotList)
    local buckets = {}
    for _, cat in ipairs(self.CATEGORIES) do
        buckets[cat.id] = {
            id = cat.id,
            name = cat.name,
            order = cat.order,
            color = cat.color,
            slots = {},
        }
    end

    for _, slotData in ipairs(slotList) do
        local info = BFB.GetItemInfo(slotData.bag, slotData.slot)
        local catID = self:ClassifyItem(slotData.bag, slotData.slot, info)
        if not buckets[catID] then
            buckets[catID] = {
                id = catID,
                name = catID,
                order = 99,
                color = { r = 0.8, g = 0.8, b = 0.8 },
                slots = {},
            }
        end
        table.insert(buckets[catID].slots, slotData)
    end

    -- Return only non-empty categories sorted by order
    local result = {}
    for _, catDef in ipairs(self.CATEGORIES) do
        local bucket = buckets[catDef.id]
        if bucket and #bucket.slots > 0 then
            table.insert(result, bucket)
        end
    end

    return result
end

