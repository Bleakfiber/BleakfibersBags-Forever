local addonName, BFB = ...

BFB.CategoryEngine = {}
local CategoryEngine = BFB.CategoryEngine

-- Recent Items tracking cache (in-memory, indexed by itemID -> timestamp)
BFB.recentItems = BFB.recentItems or {}

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

-- Valid equippable inventory slot keys
local VALID_EQUIP_SLOTS = {
    ["INVTYPE_HEAD"] = true,
    ["INVTYPE_NECK"] = true,
    ["INVTYPE_SHOULDER"] = true,
    ["INVTYPE_BODY"] = true,
    ["INVTYPE_CHEST"] = true,
    ["INVTYPE_ROBE"] = true,
    ["INVTYPE_WAIST"] = true,
    ["INVTYPE_LEGS"] = true,
    ["INVTYPE_FEET"] = true,
    ["INVTYPE_WRIST"] = true,
    ["INVTYPE_HAND"] = true,
    ["INVTYPE_FINGER"] = true,
    ["INVTYPE_TRINKET"] = true,
    ["INVTYPE_CLOAK"] = true,
    ["INVTYPE_WEAPON"] = true,
    ["INVTYPE_SHIELD"] = true,
    ["INVTYPE_2HWEAPON"] = true,
    ["INVTYPE_WEAPONMAINHAND"] = true,
    ["INVTYPE_WEAPONOFFHAND"] = true,
    ["INVTYPE_HOLDABLE"] = true,
    ["INVTYPE_RANGED"] = true,
    ["INVTYPE_THROWN"] = true,
    ["INVTYPE_RANGEDRIGHT"] = true,
    ["INVTYPE_RELIC"] = true,
    ["INVTYPE_TABARD"] = true,
}

-- Built-in Database of standard and common items for instant cold-cache classification
local KNOWN_ITEM_CATEGORIES = {
    -- Miscellaneous / Utility
    [6948]  = "misc", -- Hearthstone
    [5462]  = "misc", -- Dartol's Rod of Transformation
    [40768] = "misc", -- MOLL-E
    [49040] = "misc", -- Jeeves
    
    -- Cloth & Tailoring Materials
    [2589]  = "tradegoods", -- Linen Cloth
    [2592]  = "tradegoods", -- Wool Cloth
    [4306]  = "tradegoods", -- Silk Cloth
    [4338]  = "tradegoods", -- Mageweave Cloth
    [14047] = "tradegoods", -- Runecloth
    [21877] = "tradegoods", -- Netherweave Cloth
    [33470] = "tradegoods", -- Frostweave Cloth
    [53010] = "tradegoods", -- Embersilk Cloth
    [2996]  = "tradegoods", -- Bolt of Linen Cloth
    [2997]  = "tradegoods", -- Bolt of Woolen Cloth
    [4305]  = "tradegoods", -- Bolt of Silk Cloth
    [4337]  = "tradegoods", -- Bolt of Mageweave
    [14048] = "tradegoods", -- Bolt of Runecloth
    [21841] = "tradegoods", -- Bolt of Netherweave
    [41510] = "tradegoods", -- Bolt of Frostweave
    
    -- Basic Drinks
    [159]   = "consumables", -- Refreshing Spring Water
    [1179]  = "consumables", -- Ice Cold Milk
    [1205]  = "consumables", -- Melon Juice
    [1708]  = "consumables", -- Sweet Nectar
    [1645]  = "consumables", -- Moonberry Juice
    [8766]  = "consumables", -- Morning Glory Dew
    [28399] = "consumables", -- Filtered Draenic Water
    [33444] = "consumables", -- Pungent Seal Whey
    [33445] = "consumables", -- Honeymint Tea

    -- Basic Foods (Meat, Bread, Fruit, Fungus)
    [117]   = "consumables", -- Tough Jerky
    [2287]  = "consumables", -- Haunch of Meat
    [3770]  = "consumables", -- Mutton Chop
    [3771]  = "consumables", -- Wild Hog Shank
    [4599]  = "consumables", -- Cured Ham Steak
    [8952]  = "consumables", -- Roasted Quail
    [4536]  = "consumables", -- Shiny Red Apple
    [4540]  = "consumables", -- Tough Hunk of Bread
    [4541]  = "consumables", -- Freshly Baked Bread
    [4542]  = "consumables", -- Moist Cornbread
    [4544]  = "consumables", -- Mulgore Bread
    [4601]  = "consumables", -- Soft Banana Bread
    [4604]  = "consumables", -- Forest Mushroom Cap
    [4605]  = "consumables", -- Red-speckled Mushroom
    [4606]  = "consumables", -- Spongy Morel
    [4607]  = "consumables", -- Delicious Cave Mold
    [4608]  = "consumables", -- Raw Black Truffle

    -- First Aid Bandages
    [1251]  = "consumables", -- Linen Bandage
    [2581]  = "consumables", -- Heavy Linen Bandage
    [3530]  = "consumables", -- Wool Bandage
    [3531]  = "consumables", -- Heavy Wool Bandage
    [6450]  = "consumables", -- Silk Bandage
    [6451]  = "consumables", -- Heavy Silk Bandage
    [8544]  = "consumables", -- Mageweave Bandage
    [8545]  = "consumables", -- Heavy Mageweave Bandage
    [14529] = "consumables", -- Runecloth Bandage
    [14530] = "consumables", -- Heavy Runecloth Bandage
    [21990] = "consumables", -- Netherweave Bandage
    [21991] = "consumables", -- Heavy Netherweave Bandage
    [34721] = "consumables", -- Frostweave Bandage
    [34722] = "consumables", -- Heavy Frostweave Bandage

    -- Potions & Elixirs
    [118]   = "consumables", -- Minor Healing Potion
    [858]   = "consumables", -- Lesser Healing Potion
    [929]   = "consumables", -- Healing Potion
    [1710]  = "consumables", -- Greater Healing Potion
    [3928]  = "consumables", -- Superior Healing Potion
    [13446] = "consumables", -- Major Healing Potion
    [22829] = "consumables", -- Super Healing Potion
    [33447] = "consumables", -- Runic Healing Potion
    [2455]  = "consumables", -- Minor Mana Potion
    [3385]  = "consumables", -- Lesser Mana Potion
    [3827]  = "consumables", -- Mana Potion
    [6149]  = "consumables", -- Greater Mana Potion
    [13443] = "consumables", -- Superior Mana Potion
    [13444] = "consumables", -- Major Mana Potion
    [22832] = "consumables", -- Super Mana Potion
    [33448] = "consumables", -- Runic Mana Potion

    -- Herbs
    [765]   = "tradegoods", -- Silverleaf
    [2447]  = "tradegoods", -- Peacebloom
    [2449]  = "tradegoods", -- Earthroot
    [785]   = "tradegoods", -- Mageroyal
    [2452]  = "tradegoods", -- Briarthorn
    [2453]  = "tradegoods", -- Bruiseweed
    [3355]  = "tradegoods", -- Wild Steelbloom
    [3356]  = "tradegoods", -- Kingsblood
    [3357]  = "tradegoods", -- Liferoot
    [3358]  = "tradegoods", -- Khadgar's Whisker
    [3369]  = "tradegoods", -- Grave Moss
    [3818]  = "tradegoods", -- Fadeleaf
    [3820]  = "tradegoods", -- Stranglekelp
    [3821]  = "tradegoods", -- Goldthorn
    [4625]  = "tradegoods", -- Firebloom
    [8831]  = "tradegoods", -- Purple Lotus
    [8836]  = "tradegoods", -- Arthas' Tears
    [8838]  = "tradegoods", -- Sungrass
    [8839]  = "tradegoods", -- Blindweed
    [8845]  = "tradegoods", -- Ghost Mushroom
    [8846]  = "tradegoods", -- Gromsblood
    [13463] = "tradegoods", -- Golden Sansam
    [13464] = "tradegoods", -- Dreamfoil
    [13465] = "tradegoods", -- Mountain Silversage
    [13466] = "tradegoods", -- Plaguebloom
    [13467] = "tradegoods", -- Icecap
    [13468] = "tradegoods", -- Black Lotus

    -- Ores & Metal Bars
    [2770]  = "tradegoods", -- Copper Ore
    [2771]  = "tradegoods", -- Tin Ore
    [2772]  = "tradegoods", -- Iron Ore
    [3858]  = "tradegoods", -- Mithril Ore
    [10620] = "tradegoods", -- Thorium Ore
    [2840]  = "tradegoods", -- Copper Bar
    [2841]  = "tradegoods", -- Bronze Bar
    [2842]  = "tradegoods", -- Silver Bar
    [3575]  = "tradegoods", -- Iron Bar
    [3576]  = "tradegoods", -- Gold Bar
    [3577]  = "tradegoods", -- Steel Bar
    [3859]  = "tradegoods", -- Mithril Bar
    [3860]  = "tradegoods", -- Truesilver Bar
    [12359] = "tradegoods", -- Thorium Bar
    [12360] = "tradegoods", -- Arcanite Bar

    -- Leather & Hides
    [2318]  = "tradegoods", -- Light Leather
    [2319]  = "tradegoods", -- Medium Leather
    [4234]  = "tradegoods", -- Heavy Leather
    [4304]  = "tradegoods", -- Thick Leather
    [8170]  = "tradegoods", -- Rugged Leather
    [2934]  = "tradegoods", -- Ruined Leather Scraps

    -- Tools
    [2901]  = "tradegoods", -- Mining Pick
    [5956]  = "tradegoods", -- Blacksmith Hammer
    [7005]  = "tradegoods", -- Skinning Knife
    [6219]  = "tradegoods", -- Arclight Spanner
    [6218]  = "tradegoods", -- Flint and Tinder
    [6256]  = "tradegoods", -- Fishing Pole
}

-- Safe Multi-Tier Item Information Retrieval
local function SafeGetItemData(itemID, link)
    local name, itemType, itemSubType, equipLoc, quality, classID, subclassID
    
    if itemID and itemID > 0 then
        if C_Item and C_Item.GetItemInfoInstant then
            local _, it, ist, el, _, cid, scid = C_Item.GetItemInfoInstant(itemID)
            itemType = it
            itemSubType = ist
            equipLoc = el
            classID = cid
            subclassID = scid
        elseif GetItemInfoInstant then
            local _, it, ist, el, _, cid, scid = GetItemInfoInstant(itemID)
            itemType = it
            itemSubType = ist
            equipLoc = el
            classID = cid
            subclassID = scid
        end
    end

    local query = itemID or link
    if query then
        local rawName, _, q, _, _, it2, ist2, _, el2, _, _, cid2, scid2
        if C_Item and C_Item.GetItemInfo then
            rawName, _, q, _, _, it2, ist2, _, el2, _, _, cid2, scid2 = C_Item.GetItemInfo(query)
        elseif _G.GetItemInfo then
            rawName, _, q, _, _, it2, ist2, _, el2, _, _, cid2, scid2 = _G.GetItemInfo(query)
        end

        if rawName then name = rawName end
        if q ~= nil then quality = q end
        if not classID and cid2 then classID = cid2 end
        if not subclassID and scid2 then subclassID = scid2 end
        if not itemType and it2 then itemType = it2 end
        if not itemSubType and ist2 then itemSubType = ist2 end
        if (not equipLoc or equipLoc == "") and el2 and el2 ~= "" then equipLoc = el2 end
    end

    return name, itemType, itemSubType, equipLoc, quality, classID, subclassID
end

-- Recent Items Management
function CategoryEngine:MarkRecent(itemID)
    if not itemID or itemID == 0 then return end
    BFB.recentItems[itemID] = time()
end

function CategoryEngine:IsRecent(itemID)
    if not itemID or itemID == 0 then return false end
    local db = BFB.db or {}
    if db.enableRecentItems == false then return false end
    
    local lootTime = BFB.recentItems[itemID]
    if not lootTime then return false end
    
    local timeout = (db.recentTimeout or 5) * 60
    if (time() - lootTime) <= timeout then
        return true
    else
        BFB.recentItems[itemID] = nil
        return false
    end
end

function CategoryEngine:ClearRecent()
    BFB.recentItems = {}
end

-- Custom Category Overrides
function CategoryEngine:SetItemCategory(itemID, categoryID)
    if not itemID or itemID == 0 then return end
    local db = BFB.db
    if not db then return end
    db.customCategoryOverrides = db.customCategoryOverrides or {}
    if categoryID and categoryMap[categoryID] then
        db.customCategoryOverrides[itemID] = categoryID
    else
        db.customCategoryOverrides[itemID] = nil
    end
    if BFB.BagFrame and BFB.BagFrame.UpdateLayout then BFB.BagFrame:UpdateLayout() end
    if BFB.BankFrame and BFB.BankFrame.UpdateLayout then BFB.BankFrame:UpdateLayout() end
end

function CategoryEngine:GetItemCategoryOverride(itemID)
    if not itemID or itemID == 0 then return nil end
    local db = BFB.db or {}
    local overrides = db.customCategoryOverrides
    return overrides and overrides[itemID]
end

-- Determine an item's category based on link, itemID, quality and user overrides
function CategoryEngine:ClassifyItem(bagID, slotID, itemInfo)
    if not itemInfo or not (itemInfo.iconFileID or itemInfo.icon or itemInfo.texture) then
        return "empty"
    end

    local itemID = itemInfo.itemID or itemInfo.id
    if not itemID and itemInfo.hyperlink then
        local match = itemInfo.hyperlink:match("item:(%d+)")
        if match then itemID = tonumber(match) end
    end
    if not itemID and itemInfo.link then
        local match = itemInfo.link:match("item:(%d+)")
        if match then itemID = tonumber(match) end
    end
    if not itemID and bagID and slotID then
        local link
        if C_Container and C_Container.GetContainerItemLink then
            link = C_Container.GetContainerItemLink(bagID, slotID)
        elseif GetContainerItemLink then
            link = GetContainerItemLink(bagID, slotID)
        end
        if link then
            local match = link:match("item:(%d+)")
            if match then itemID = tonumber(match) end
        end
    end

    -- 1. Custom User Overrides take highest precedence
    if itemID then
        local customCat = self:GetItemCategoryOverride(itemID)
        if customCat and categoryMap[customCat] then
            return customCat
        end
    end

    -- 2. Junk items (Quality 0)
    local quality = itemInfo.quality
    if quality == 0 then
        return "junk"
    end

    -- 3. Recent Items (if enabled and within duration window)
    if itemID and self:IsRecent(itemID) then
        return "recent"
    end

    -- 4. Built-in Database Lookup for instant, infallible classification
    if itemID and KNOWN_ITEM_CATEGORIES[itemID] then
        return KNOWN_ITEM_CATEGORIES[itemID]
    end

    -- 5. Safe multi-tier API extraction
    local link = itemInfo.hyperlink or itemInfo.link
    local name, itemType, itemSubType, equipLoc, q, classID, subclassID = SafeGetItemData(itemID, link)
    if (q and q == 0) or (quality and quality == 0) then
        return "junk"
    end

    -- 6. Quest Items
    if classID == 12 or itemType == "Quest" or (Enum and Enum.ItemClass and classID == Enum.ItemClass.Questitem) or itemInfo.isQuestItem then
        return "quest"
    end

    -- 7. Consumables (Food, Drink, Potions, Bandages, Scrolls, Flasks, Elixirs, Glyphs)
    if classID == 0 or classID == 16 or itemType == "Consumable" or itemType == "Glyph" or
       (itemSubType and (itemSubType:find("Food") or itemSubType:find("Drink") or itemSubType:find("Potion") or itemSubType:find("Elixir") or itemSubType:find("Flask") or itemSubType:find("Bandage") or itemSubType:find("Scroll"))) then
        return "consumables"
    end

    -- 8. Trade Goods & Crafting Reagents (Herbs, Ore, Cloth, Leather, Reagents, Gems, Item Enhancement)
    if classID == 7 or classID == 5 or classID == 3 or classID == 8 or
       itemType == "Trade Goods" or itemType == "Reagent" or itemType == "Gem" or itemType == "Item Enhancement" then
        return "tradegoods"
    end

    -- 9. Recipes & Plans
    if classID == 9 or itemType == "Recipe" then
        return "recipes"
    end

    -- 10. Equipment / Gear (Weapons, Armor, or valid equippable inventory slot)
    local isEquippableSlot = false
    if equipLoc and VALID_EQUIP_SLOTS[equipLoc] then
        isEquippableSlot = true
    end
    if classID == 2 or classID == 4 or itemType == "Weapon" or itemType == "Armor" or isEquippableSlot then
        return "gear"
    end

    -- 11. Fallback / Miscellaneous
    return "misc"
end

-- Group a list of bag slots into categorized buckets
function CategoryEngine:GroupSlots(slotList)
    local db = BFB.db or {}
    local showFreeSlots = (db.showCategoryFreeSlots == true)

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
        
        -- In category view, empty slots are only bucketed if the user enabled free slot display
        if catID ~= "empty" or showFreeSlots then
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
