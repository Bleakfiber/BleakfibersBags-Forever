local addonName, BFB = ...

BFB.Sorting = {}
local Sorting = BFB.Sorting

local isSorting = false
local sortTicker = nil
local movesQueue = {}

-- Helper to safely check if any bag slot is currently locked
local function AreBagsLocked()
    for bag = 0, 4 do
        local numSlots = BFB.GetNumSlots(bag)
        for slot = 1, numSlots do
            local info = BFB.GetItemInfo(bag, slot)
            if info and info.isLocked then
                return true
            end
        end
    end
    return false
end

-- Generate a comparison score for sorting items
local function GetItemSortScore(bagID, slotID)
    local info = BFB.GetItemInfo(bagID, slotID)
    if not info or not info.iconFileID then
        return "9_empty"
    end

    local link = info.hyperlink
    local catID = BFB.CategoryEngine and BFB.CategoryEngine:ClassifyItem(bagID, slotID, info) or "misc"
    local catInfo = BFB.CategoryEngine and BFB.CategoryEngine:GetCategoryInfo(catID)
    local catOrder = catInfo and catInfo.order or 50

    local quality = info.quality or 1
    local itemName = ""
    local itemLevel = 0

    if link then
        local name, _, _, iLvl = GetItemInfo(link)
        if name then itemName = name end
        if iLvl then itemLevel = iLvl end
    end

    -- Format sort key: CategoryOrder(2 digits) _ (9 - Quality) _ (999 - iLvl) _ Name
    local invQuality = 9 - quality
    local invLevel = 999 - itemLevel
    return string.format("%02d_%d_%03d_%s", catOrder, invQuality, invLevel, itemName:lower())
end

-- Consolidate Partial Stacks Across Bags
function Sorting:StackItems()
    local partials = {}

    for bag = 0, 4 do
        local numSlots = BFB.GetNumSlots(bag)
        for slot = 1, numSlots do
            local info = BFB.GetItemInfo(bag, slot)
            if info and info.hyperlink and not info.isLocked then
                local _, _, _, _, _, _, _, maxStack = GetItemInfo(info.hyperlink)
                if maxStack and maxStack > 1 and info.stackCount < maxStack then
                    local itemID = info.itemID or info.hyperlink
                    if partials[itemID] then
                        local src = partials[itemID]
                        -- Move src into current slot to stack
                        if C_Container and C_Container.PickupContainerItem then
                            C_Container.PickupContainerItem(src.bag, src.slot)
                            C_Container.PickupContainerItem(bag, slot)
                        elseif PickupContainerItem then
                            PickupContainerItem(src.bag, src.slot)
                            PickupContainerItem(bag, slot)
                        end
                        return true -- Performed a stack move
                    else
                        partials[itemID] = { bag = bag, slot = slot }
                    end
                end
            end
        end
    end
    return false
end

-- Step the sort state machine
local function ProcessNextMove()
    if InCombatLockdown and InCombatLockdown() then
        Sorting:StopSort("Aborted: In Combat")
        return
    end

    if AreBagsLocked() then
        return -- Wait for current move to unlock
    end

    -- First try stacking partial stacks
    if Sorting:StackItems() then
        return
    end

    -- Next, evaluate item sort positions
    local slots = {}
    for bag = 0, 4 do
        local numSlots = BFB.GetNumSlots(bag)
        for slot = 1, numSlots do
            table.insert(slots, { bag = bag, slot = slot, score = GetItemSortScore(bag, slot) })
        end
    end

    -- Find the first out-of-order pair
    local swapped = false
    for i = 1, #slots - 1 do
        for j = i + 1, #slots do
            if slots[i].score > slots[j].score then
                -- slots[j] should come before slots[i], swap them
                local src = slots[j]
                local dest = slots[i]

                if C_Container and C_Container.PickupContainerItem then
                    C_Container.PickupContainerItem(src.bag, src.slot)
                    C_Container.PickupContainerItem(dest.bag, dest.slot)
                elseif PickupContainerItem then
                    PickupContainerItem(src.bag, src.slot)
                    PickupContainerItem(dest.bag, dest.slot)
                end
                swapped = true
                break
            end
        end
        if swapped then break end
    end

    if not swapped then
        -- All items are sorted!
        Sorting:StopSort("Sorting complete!")
    end
end

-- Start Inventory Sort
function Sorting:StartSort()
    if isSorting then return end
    if InCombatLockdown and InCombatLockdown() then
        print("|cff00c0ffBleakfiber's Bags:|r Cannot sort inventory in combat.")
        return
    end

    isSorting = true
    print("|cff00c0ffBleakfiber's Bags:|r Sorting inventory...")

    sortTicker = C_Timer.NewTicker(0.08, function()
        ProcessNextMove()
    end)
end

-- Stop Inventory Sort
function Sorting:StopSort(message)
    if not isSorting then return end
    isSorting = false
    if sortTicker then
        sortTicker:Cancel()
        sortTicker = nil
    end

    if message then
        print(string.format("|cff00c0ffBleakfiber's Bags:|r %s", message))
    end

    if BFB.BagFrame and BFB.BagFrame.UpdateLayout then
        BFB.BagFrame:UpdateLayout()
    end
end

function Sorting:IsSorting()
    return isSorting
end

