local addonName, BFB = ...

BFB.ItemButtons = {}
local ItemButtons = BFB.ItemButtons

local buttonPool = {}
local activeButtons = {}
local buttonCounter = 0

-- Safe API Wrappers for Classic & Modern Container Functions
local function GetNumSlots(bagID)
    if C_Container and C_Container.GetContainerNumSlots then
        return C_Container.GetContainerNumSlots(bagID)
    elseif GetContainerNumSlots then
        return GetContainerNumSlots(bagID)
    end
    return 0
end

local function GetItemInfo(bagID, slotID)
    if C_Container and C_Container.GetContainerItemInfo then
        return C_Container.GetContainerItemInfo(bagID, slotID)
    elseif GetContainerItemInfo then
        local texture, count, locked, quality, readable, lootable, link, isFiltered, noValue, itemID = GetContainerItemInfo(bagID, slotID)
        if texture then
            return {
                iconFileID = texture,
                stackCount = count or 1,
                isLocked = locked,
                quality = quality,
                isReadable = readable,
                hasLoot = lootable,
                hyperlink = link,
                isFiltered = isFiltered,
                hasNoValue = noValue,
                itemID = itemID,
            }
        end
    end
    return nil
end

local function GetItemCooldown(bagID, slotID)
    if C_Container and C_Container.GetContainerItemCooldown then
        return C_Container.GetContainerItemCooldown(bagID, slotID)
    elseif GetContainerItemCooldown then
        return GetContainerItemCooldown(bagID, slotID)
    end
    return 0, 0, 0
end

BFB.GetNumSlots = GetNumSlots
BFB.GetItemInfo = GetItemInfo
BFB.GetItemCooldown = GetItemCooldown

-- Create or Acquire an Item Button
function ItemButtons:Acquire(parent)
    local button = table.remove(buttonPool)
    if not button then
        buttonCounter = buttonCounter + 1
        local btnName = "BleakfibersBagItemBtn" .. buttonCounter
        button = CreateFrame("Button", btnName, parent, "ContainerFrameItemButtonTemplate")
        
        -- Fallback elements if template is incomplete
        if not button.icon then
            button.icon = _G[btnName .. "IconTexture"] or button:CreateTexture(nil, "BORDER")
            button.icon:SetAllPoints()
        end
        if not button.Count then
            button.Count = _G[btnName .. "Count"] or button:CreateFontString(nil, "OVERLAY", "NumberFontNormal")
            button.Count:SetPoint("BOTTOMRIGHT", -2, 2)
        end
        if not button.Cooldown then
            button.Cooldown = _G[btnName .. "Cooldown"] or CreateFrame("Cooldown", btnName .. "Cooldown", button, "CooldownFrameTemplate")
            button.Cooldown:SetAllPoints()
        end

        -- Quality Border Overlay (Signature Crisp Border)
        local qualityBorder = button:CreateTexture(nil, "OVERLAY", nil, 1)
        qualityBorder:SetTexture("Interface\\Buttons\\WHITE8x8")
        qualityBorder:SetPoint("TOPLEFT", button, "TOPLEFT", 0, 0)
        qualityBorder:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", 0, 0)
        qualityBorder:SetBlendMode("BLEND")
        qualityBorder:Hide()
        button.QualityBorder = qualityBorder

        -- Inner Mask to create crisp 1.5px border
        local innerBg = button:CreateTexture(nil, "OVERLAY", nil, 2)
        innerBg:SetTexture("Interface\\Buttons\\WHITE8x8")
        innerBg:SetPoint("TOPLEFT", button, "TOPLEFT", 1.5, -1.5)
        innerBg:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", -1.5, 1.5)
        innerBg:SetColorTexture(0, 0, 0, 0) -- Transparent, used for clipping effect if needed

        -- Junk Indicator Coin Icon
        local junkIcon = button:CreateTexture(nil, "OVERLAY", nil, 3)
        junkIcon:SetSize(14, 14)
        junkIcon:SetPoint("TOPLEFT", button, "TOPLEFT", 1, -1)
        junkIcon:SetTexture("Interface\\MoneyFrame\\UI-GoldIcon")
        junkIcon:Hide()
        button.JunkIcon = junkIcon

        -- Quest Item Indicator Texture
        local questIcon = button:CreateTexture(nil, "OVERLAY", nil, 3)
        questIcon:SetSize(16, 16)
        questIcon:SetPoint("BOTTOMLEFT", button, "BOTTOMLEFT", 1, 1)
        questIcon:SetTexture("Interface\\GossipFrame\\AvailableQuestIcon")
        questIcon:Hide()
        button.QuestIcon = questIcon

        -- Dark Empty Slot Background
        local slotBg = button:CreateTexture(nil, "BACKGROUND")
        slotBg:SetAllPoints()
        slotBg:SetColorTexture(0.04, 0.04, 0.06, 0.65)
        button.SlotBg = slotBg

        -- Helper method to bind bag and slot
        function button:SetBagSlot(bagID, slotID)
            self.bagID = bagID
            self.slotID = slotID
            self:SetID(slotID)
        end
    end

    button:SetParent(parent)
    button:Show()
    table.insert(activeButtons, button)
    return button
end

-- Release All Active Buttons back to Pool
function ItemButtons:ReleaseAll()
    for _, btn in ipairs(activeButtons) do
        btn:Hide()
        btn:ClearAllPoints()
        btn.bagID = nil
        btn.slotID = nil
        btn.itemName = nil
        btn.itemQuality = nil
        if btn.QualityBorder then btn.QualityBorder:Hide() end
        if btn.JunkIcon then btn.JunkIcon:Hide() end
        if btn.QuestIcon then btn.QuestIcon:Hide() end
        btn:SetAlpha(1.0)
        table.insert(buttonPool, btn)
    end
    wipe(activeButtons)
end

-- Update an Item Button with Current Inventory Data
function ItemButtons:UpdateButton(button, bagID, slotID, searchTerm)
    button:SetBagSlot(bagID, slotID)
    local db = BFB.db or {}
    
    local info = GetItemInfo(bagID, slotID)
    if not info or not info.iconFileID then
        -- Empty Slot
        button.icon:Hide()
        button.Count:Hide()
        if button.Cooldown then button.Cooldown:Hide() end
        if button.QualityBorder then button.QualityBorder:Hide() end
        if button.JunkIcon then button.JunkIcon:Hide() end
        if button.QuestIcon then button.QuestIcon:Hide() end
        button.itemName = nil
        button.itemQuality = nil
        button:SetAlpha(1.0)
        return
    end

    -- Has Item
    button.icon:Show()
    button.icon:SetTexture(info.iconFileID)

    -- Stack Count
    local count = info.stackCount or 1
    if count > 1 then
        button.Count:SetText(tostring(count))
        button.Count:Show()
    else
        button.Count:Hide()
    end

    -- Cooldown Sweep
    if button.Cooldown then
        local start, duration, enable = GetItemCooldown(bagID, slotID)
        if start and duration and duration > 0 and enable == 1 then
            if CooldownFrame_SetTimer then
                CooldownFrame_SetTimer(button.Cooldown, start, duration, enable)
            elseif button.Cooldown.SetCooldown then
                button.Cooldown:SetCooldown(start, duration)
            end
            button.Cooldown:Show()
        else
            button.Cooldown:Hide()
        end
    end

    -- Item Hyperlink & Quality Details
    local quality = info.quality or 1
    local link = info.hyperlink
    local isQuestItem = false
    local itemName = ""

    if link then
        local rawName, _, q, _, _, _, _, _, _, _, _, classID = GetItemInfo(link)
        if rawName then itemName = rawName end
        if q then quality = q end
        if classID == 12 or (info.isQuestItem) then
            isQuestItem = true
        end
    end
    button.itemName = itemName
    button.itemQuality = quality

    -- Quality Glow Border
    if db.showQualityGlow ~= false and quality and quality > 1 and button.QualityBorder then
        local r, g, b = GetItemQualityColor(quality)
        button.QualityBorder:SetColorTexture(r, g, b, 0.95)
        button.QualityBorder:Show()
    else
        if button.QualityBorder then button.QualityBorder:Hide() end
    end

    -- Vendor Junk Coin Indicator
    if db.showJunkIcon ~= false and quality == 0 and button.JunkIcon then
        button.JunkIcon:Show()
    else
        if button.JunkIcon then button.JunkIcon:Hide() end
    end

    -- Quest Item Indicator
    if db.showQuestGlow ~= false and isQuestItem and button.QuestIcon then
        button.QuestIcon:Show()
        if button.QualityBorder then
            button.QualityBorder:SetColorTexture(1.0, 0.82, 0.0, 1.0) -- Gold glow for quest items
            button.QualityBorder:Show()
        end
    else
        if button.QuestIcon then button.QuestIcon:Hide() end
    end

    -- Search Filtering Dimming
    if searchTerm and searchTerm ~= "" then
        local match = false
        local termLower = searchTerm:lower()
        if itemName and itemName:lower():find(termLower, 1, true) then
            match = true
        end
        if not match and link then
            -- Check tooltip text or type
            local _, _, _, _, _, itemType, itemSubType = GetItemInfo(link)
            if (itemType and itemType:lower():find(termLower, 1, true)) or (itemSubType and itemSubType:lower():find(termLower, 1, true)) then
                match = true
            end
        end

        if match then
            button:SetAlpha(1.0)
        else
            button:SetAlpha(0.20) -- Dim non-matching items
        end
    else
        button:SetAlpha(1.0)
    end
end

