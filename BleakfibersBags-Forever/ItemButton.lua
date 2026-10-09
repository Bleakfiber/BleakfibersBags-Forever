local addonName, BFB = ...

BFB.ItemButtons = {}
local ItemButtons = BFB.ItemButtons

local buttonPool = {}
local activeButtons = {}
local buttonCounter = 0

-- Hidden Tooltip for Usability and Keyword Scanning
local scanTooltip = CreateFrame("GameTooltip", "BFB_ScanTooltip", UIParent, "GameTooltipTemplate")
scanTooltip:SetOwner(UIParent, "ANCHOR_NONE")

-- Safe API Wrappers for Classic & Modern Container Functions
local function GetNumSlots(bagID)
    if C_Container and C_Container.GetContainerNumSlots then
        return C_Container.GetContainerNumSlots(bagID)
    elseif GetContainerNumSlots then
        return GetContainerNumSlots(bagID)
    end
    return 0
end

local function GetContainerItemInfoCompat(bagID, slotID)
    if not bagID or not slotID then return nil end
    local info
    if C_Container and C_Container.GetContainerItemInfo then
        info = C_Container.GetContainerItemInfo(bagID, slotID)
    elseif GetContainerItemInfo then
        local texture, count, locked, quality, readable, lootable, link, isFiltered, noValue, itemID = GetContainerItemInfo(bagID, slotID)
        if texture then
            info = {
                iconFileID = texture,
                texture = texture,
                icon = texture,
                stackCount = count or 1,
                count = count or 1,
                isLocked = locked,
                quality = quality,
                isReadable = readable,
                hasLoot = lootable,
                hyperlink = link,
                link = link,
                isFiltered = isFiltered,
                hasNoValue = noValue,
                itemID = itemID,
            }
        end
    end

    if info then
        local icon = info.iconFileID or info.icon or info.texture
        if icon then
            info.iconFileID = icon
            info.icon = icon
            info.texture = icon
        end
        local cnt = info.stackCount or info.count
        if cnt then
            info.stackCount = cnt
            info.count = cnt
        end
        local l = info.hyperlink or info.link
        if l then
            info.hyperlink = l
            info.link = l
        end
        local id = info.itemID or info.id
        if id then
            info.itemID = id
            info.id = id
        end
        return info
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

local function GetItemInfoCompat(item)
    if not item then return nil end
    if _G.GetItemInfo then
        return _G.GetItemInfo(item)
    elseif C_Item and C_Item.GetItemInfo then
        return C_Item.GetItemInfo(item)
    end
    return nil
end

BFB.GetNumSlots = GetNumSlots
BFB.GetItemInfo = GetContainerItemInfoCompat
BFB.GetContainerItemInfo = GetContainerItemInfoCompat
BFB.GetItemCooldown = GetItemCooldown
BFB.GetItemInfoCompat = GetItemInfoCompat

-- Check if an item is equippable and cannot be used by the character
function BFB:IsItemUnusable(bagID, slotID, itemLink)
    if not itemLink then return false end
    local _, _, _, _, _, _, _, _, equipLoc = GetItemInfoCompat(itemLink)
    if not equipLoc or equipLoc == "" or equipLoc == "INVTYPE_NON_EQUIP" then
        return false
    end

    scanTooltip:ClearLines()
    if bagID and slotID then
        scanTooltip:SetBagItem(bagID, slotID)
    else
        scanTooltip:SetHyperlink(itemLink)
    end

    local numLines = scanTooltip:NumLines()
    for i = 2, numLines do
        local leftLine = _G["BFB_ScanTooltipTextLeft" .. i]
        if leftLine and leftLine:IsShown() then
            local r, g, b = leftLine:GetTextColor()
            -- Bright red requirement text (Requires Level, Class, Armor proficiency)
            if r > 0.85 and g < 0.25 and b < 0.25 then
                return true
            end
        end
        local rightLine = _G["BFB_ScanTooltipTextRight" .. i]
        if rightLine and rightLine:IsShown() then
            local r, g, b = rightLine:GetTextColor()
            if r > 0.85 and g < 0.25 and b < 0.25 then
                return true
            end
        end
    end
    return false
end

-- Specialty Container Types & Colors
local SPECIALTY_BAG_FAMILIES = {
    soul    = { name = "Soul",        r = 0.70, g = 0.30, b = 0.90 },
    herb    = { name = "Herb",        r = 0.20, g = 0.85, b = 0.30 },
    mining  = { name = "Mining",      r = 0.95, g = 0.55, b = 0.20 },
    enchant = { name = "Enchanting",  r = 0.25, g = 0.55, b = 0.95 },
    ammo    = { name = "Ammo/Quiver", r = 0.95, g = 0.85, b = 0.20 },
}

function BFB:GetBagSpecialty(bagID)
    if not bagID or bagID == 0 or bagID == -1 then return nil end
    local bagName = GetBagName(bagID)
    if not bagName then return nil end
    bagName = bagName:lower()

    if bagName:find("soul") or bagName:find("felcloth") or bagName:find("core felcloth") then
        return SPECIALTY_BAG_FAMILIES.soul
    elseif bagName:find("herb") or bagName:find("cenarion") then
        return SPECIALTY_BAG_FAMILIES.herb
    elseif bagName:find("mining") or bagName:find("miner") or bagName:find("mammoth") then
        return SPECIALTY_BAG_FAMILIES.mining
    elseif bagName:find("enchant") then
        return SPECIALTY_BAG_FAMILIES.enchant
    elseif bagName:find("quiver") or bagName:find("ammo") or bagName:find("shot") or bagName:find("bandolier") then
        return SPECIALTY_BAG_FAMILIES.ammo
    end
    return nil
end

-- Advanced Search Keyword Matching
local function MatchesAdvancedSearch(itemName, link, itemQuality, classID, equipLoc, termLower)
    if not termLower or termLower == "" then return true end

    -- 1. Direct Name Match
    if itemName and itemName:lower():find(termLower, 1, true) then
        return true
    end

    if not link then return false end
    local _, _, _, itemLevel, _, itemType, itemSubType = GetItemInfoCompat(link)

    -- 2. Item Type / Subtype Match
    if itemType and itemType:lower():find(termLower, 1, true) then return true end
    if itemSubType and itemSubType:lower():find(termLower, 1, true) then return true end

    -- 3. Rarity Keywords
    if (termLower == "poor" or termLower == "grey" or termLower == "gray") and itemQuality == 0 then return true end
    if (termLower == "common" or termLower == "white") and itemQuality == 1 then return true end
    if (termLower == "uncommon" or termLower == "green") and itemQuality == 2 then return true end
    if (termLower == "rare" or termLower == "blue") and itemQuality == 3 then return true end
    if (termLower == "epic" or termLower == "purple") and itemQuality == 4 then return true end
    if (termLower == "legendary" or termLower == "orange") and itemQuality == 5 then return true end

    -- 4. Category Keywords
    if (termLower == "quest") and (classID == 12 or itemType == "Quest") then return true end
    if (termLower == "junk" or termLower == "trash") and itemQuality == 0 then return true end
    if (termLower == "gear" or termLower == "equipment" or termLower == "armor" or termLower == "weapon") and (classID == 2 or classID == 4 or (equipLoc and equipLoc ~= "")) then return true end
    if (termLower == "consumable" or termLower == "food" or termLower == "potion") and (classID == 0 or itemType == "Consumable") then return true end
    if (termLower == "tradegoods" or termLower == "trade" or termLower == "reagent" or termLower == "craft") and (classID == 7 or itemType == "Trade Goods" or itemType == "Reagent") then return true end
    if (termLower == "recipe" or termLower == "plan" or termLower == "schematic") and (classID == 9 or itemType == "Recipe") then return true end

    -- 5. Level Comparisons (>N, <N, =N)
    local op, reqLvl = termLower:match("^([><=])%s*(%d+)$")
    if not op then
        op, reqLvl = termLower:match("^lvl%s*([><=])%s*(%d+)$")
    end
    if op and reqLvl and itemLevel then
        local targetLvl = tonumber(reqLvl)
        if op == ">" and itemLevel > targetLvl then return true end
        if op == "<" and itemLevel < targetLvl then return true end
        if op == "=" and itemLevel == targetLvl then return true end
    end

    -- 6. Binding Keywords (boe, bop, soulbound)
    if termLower == "boe" or termLower == "bop" or termLower == "soulbound" then
        scanTooltip:ClearLines()
        scanTooltip:SetHyperlink(link)
        for i = 1, math.min(scanTooltip:NumLines(), 4) do
            local lineText = _G["BFB_ScanTooltipTextLeft" .. i] and _G["BFB_ScanTooltipTextLeft" .. i]:GetText()
            if lineText then
                lineText = lineText:lower()
                if termLower == "boe" and lineText:find("binds when equipped") then return true end
                if (termLower == "bop" or termLower == "soulbound") and (lineText:find("binds when picked up") or lineText:find("soulbound")) then return true end
            end
        end
    end

    return false
end

-- Category Assignment Context Menu (Alt+Right Click)
local contextMenuFrame
local function CreateContextMenu()
    if contextMenuFrame then return contextMenuFrame end

    local BACKDROP_TEMPLATE = BackdropTemplateMixin and "BackdropTemplate" or nil
    local menu = CreateFrame("Frame", "BFB_ItemContextMenu", UIParent, BACKDROP_TEMPLATE)
    menu:SetSize(170, 220)
    menu:SetFrameStrata("DIALOG")
    menu:SetClampedToScreen(true)
    menu:EnableMouse(true)
    menu:Hide()

    menu:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 12, edgeSize = 12,
        insets = { left = 3, right = 3, top = 3, bottom = 3 }
    })
    menu:SetBackdropColor(0.08, 0.10, 0.13, 0.98)
    menu:SetBackdropBorderColor(0.82, 0.68, 0.28, 1.0)

    local title = menu:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    title:SetPoint("TOPLEFT", menu, "TOPLEFT", 10, -8)
    title:SetText("|cffffd100Assign Category|r")

    local options = {
        { id = "quest",       text = "Quest Items" },
        { id = "gear",        text = "Equipment & Gear" },
        { id = "consumables", text = "Consumables" },
        { id = "tradegoods",  text = "Trade Goods & Craft" },
        { id = "recipes",     text = "Recipes & Plans" },
        { id = "misc",        text = "Miscellaneous" },
        { id = "junk",        text = "Junk / Trash" },
        { id = nil,           text = "|cff888888Reset to Default|r" },
    }

    local y = -26
    for _, opt in ipairs(options) do
        local btn = CreateFrame("Button", nil, menu)
        btn:SetSize(150, 20)
        btn:SetPoint("TOPLEFT", menu, "TOPLEFT", 10, y)

        local hl = btn:CreateTexture(nil, "HIGHLIGHT")
        hl:SetAllPoints()
        hl:SetColorTexture(1.0, 0.82, 0.0, 0.20)

        local label = btn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        label:SetPoint("LEFT", btn, "LEFT", 4, 0)
        label:SetText(opt.text)

        btn:SetScript("OnClick", function()
            if menu.targetItemID and BFB.CategoryEngine and BFB.CategoryEngine.SetItemCategory then
                BFB.CategoryEngine:SetItemCategory(menu.targetItemID, opt.id)
                print(string.format("|cff00c0ffBleakfiber's Bags:|r Category set for item."))
            end
            menu:Hide()
        end)
        y = y - 22
    end

    -- Close on click outside or escape
    menu:SetScript("OnLeave", function(self)
        if not MouseIsOver(self) then
            self:Hide()
        end
    end)

    contextMenuFrame = menu
    return menu
end

function BFB:ShowCategoryContextMenu(anchorButton, itemID, itemLink)
    if not itemID then return end
    local menu = CreateContextMenu()
    menu.targetItemID = itemID
    menu.targetItemLink = itemLink
    menu:ClearAllPoints()
    menu:SetPoint("TOPLEFT", anchorButton, "TOPRIGHT", 4, 0)
    menu:Show()
end

-- Create or Acquire an Item Button
function ItemButtons:Acquire(parent)
    local button = table.remove(buttonPool)
    if not button then
        buttonCounter = buttonCounter + 1
        local btnName = "BleakfibersBagItemBtn" .. buttonCounter
        
        -- Safely instantiate item button with fallback templates
        local ok
        if pcall(function() button = CreateFrame("Button", btnName, parent, "ContainerFrameItemButtonTemplate") end) and button then
            ok = true
        elseif pcall(function() button = CreateFrame("Button", btnName, parent, "ItemButtonTemplate") end) and button then
            ok = true
        else
            button = CreateFrame("Button", btnName, parent)
        end

        button:ClearAllPoints()
        button:RegisterForClicks("LeftButtonUp", "RightButtonUp")
        button:RegisterForDrag("LeftButton")
        
        -- Suppress Blizzard template default glowing overlays, Battlepay highlights, and animations
        button.UpdateNewItem = function() end
        if button.NewItemTexture then
            button.NewItemTexture:Hide()
            button.NewItemTexture:SetAlpha(0)
        end
        if button.newitemglowAnim then
            button.newitemglowAnim:Stop()
        end
        if button.flashAnim then
            button.flashAnim:Stop()
        end
        if button.flash then
            button.flash:Hide()
            button.flash:SetAlpha(0)
        end
        if button.BattlepayItemTexture then
            button.BattlepayItemTexture:Hide()
        end
        if button.UpgradeIcon then
            button.UpgradeIcon:Hide()
        end
        if button.ExtendedSlot then
            button.ExtendedSlot:Hide()
        end
        if button.BagIndicator then
            button.BagIndicator:Hide()
        end
        
        -- Ensure icon texture is properly bound and anchored
        if not button.icon then
            button.icon = _G[btnName .. "IconTexture"] or button:CreateTexture(nil, "BORDER")
        end
        button.icon:ClearAllPoints()
        button.icon:SetAllPoints(button)
        if button.icon.SetTexCoord then
            button.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
        end

        -- Ensure stack count FontString
        if not button.Count then
            button.Count = _G[btnName .. "Count"] or button:CreateFontString(nil, "OVERLAY", "NumberFontNormal")
        end
        button.Count:ClearAllPoints()
        button.Count:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", -2, 2)

        local db = BFB.db or {}
        local fFamily = BFB:FetchFont(db.font or BFB.DEFAULT_FONT_NAME)
        local outline = db.fontOutline or "OUTLINE"
        if outline == "None" or outline == "NONE" then outline = "" end
        local cSize = db.countFontSize or 9
        button.Count:SetFont(fFamily, cSize, outline)

        -- Cooldown Frame
        if not button.Cooldown then
            button.Cooldown = _G[btnName .. "Cooldown"] or CreateFrame("Cooldown", btnName .. "Cooldown", button, "CooldownFrameTemplate")
        end
        button.Cooldown:ClearAllPoints()
        button.Cooldown:SetAllPoints(button)

        -- Dark Empty Slot Background and Slate Border
        local slotBg = button:CreateTexture(nil, "BACKGROUND", nil, -2)
        slotBg:ClearAllPoints()
        slotBg:SetAllPoints(button)
        slotBg:SetColorTexture(0.05, 0.06, 0.08, 0.85)
        button.SlotBg = slotBg

        local slotBorder = button:CreateTexture(nil, "BACKGROUND", nil, -1)
        slotBorder:ClearAllPoints()
        slotBorder:SetPoint("TOPLEFT", button, "TOPLEFT", 0, 0)
        slotBorder:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", 0, 0)
        slotBorder:SetTexture("Interface\\Buttons\\WHITE8x8")
        slotBorder:SetColorTexture(0.18, 0.22, 0.28, 0.70)
        button.SlotBorder = slotBorder

        local slotInner = button:CreateTexture(nil, "BACKGROUND", nil, 0)
        slotInner:ClearAllPoints()
        slotInner:SetPoint("TOPLEFT", button, "TOPLEFT", 1, -1)
        slotInner:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", -1, 1)
        slotInner:SetColorTexture(0.06, 0.07, 0.10, 0.92)
        button.SlotInner = slotInner

        -- Quality Border Overlay (Signature Crisp Border)
        local qualityBorder = button:CreateTexture(nil, "OVERLAY", nil, 1)
        qualityBorder:SetTexture("Interface\\Buttons\\WHITE8x8")
        qualityBorder:SetPoint("TOPLEFT", button, "TOPLEFT", 0, 0)
        qualityBorder:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", 0, 0)
        qualityBorder:SetBlendMode("BLEND")
        qualityBorder:Hide()
        button.QualityBorder = qualityBorder

        -- Specialty Container Slot Border (Soul, Herb, Mining, Enchanting, Ammo)
        local specialtyBorder = button:CreateTexture(nil, "OVERLAY", nil, 1)
        specialtyBorder:SetTexture("Interface\\Buttons\\WHITE8x8")
        specialtyBorder:SetPoint("TOPLEFT", button, "TOPLEFT", 0, 0)
        specialtyBorder:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", 0, 0)
        specialtyBorder:SetBlendMode("BLEND")
        specialtyBorder:Hide()
        button.SpecialtyBorder = specialtyBorder

        -- Unusable Equipment Red Tint Overlay
        local unusableOverlay = button:CreateTexture(nil, "OVERLAY", nil, 2)
        unusableOverlay:SetAllPoints()
        unusableOverlay:SetColorTexture(0.9, 0.1, 0.1, 0.35)
        unusableOverlay:Hide()
        button.UnusableOverlay = unusableOverlay

        -- Recent Item Glow Indicator (Cyan Diamond / Star)
        local recentGlow = button:CreateTexture(nil, "OVERLAY", nil, 3)
        recentGlow:SetSize(10, 10)
        recentGlow:SetPoint("TOPRIGHT", button, "TOPRIGHT", -1, -1)
        recentGlow:SetTexture("Interface\\Buttons\\UI-GroupLoot-Pass-Up")
        recentGlow:SetVertexColor(0.20, 0.85, 1.0, 0.95)
        recentGlow:Hide()
        button.RecentGlow = recentGlow

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

        -- Fallback tooltip and hover handlers if not provided by template
        if not button:GetScript("OnEnter") then
            button:SetScript("OnEnter", function(self)
                local bID = self._bfbBagID or (self.GetBagID and self:GetBagID()) or (self:GetParent() and self:GetParent():GetID())
                local sID = self._bfbSlotID or self:GetID()
                if bID and sID then
                    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
                    if C_Container and C_Container.UseContainerItem then
                        GameTooltip:SetBagItem(bID, sID)
                    elseif GameTooltip.SetBagItem then
                        GameTooltip:SetBagItem(bID, sID)
                    elseif self.itemLink or self._bfbItemLink then
                        GameTooltip:SetHyperlink(self.itemLink or self._bfbItemLink)
                    end
                    GameTooltip:Show()
                end
            end)
            button:SetScript("OnLeave", function()
                GameTooltip:Hide()
            end)
        end

        -- Handle Alt + Right Click for Category Assignment without tainting Blizzard's OnClick
        button:HookScript("OnMouseDown", function(self, mouseBtn)
            if mouseBtn == "RightButton" and IsAltKeyDown() and (self.itemID or self._bfbItemID) then
                BFB:ShowCategoryContextMenu(self, self.itemID or self._bfbItemID, self.itemLink or self._bfbItemLink)
            end
        end)

        -- Fallback click and drag handlers if template does not implement them
        if not button:GetScript("OnClick") then
            button:SetScript("OnClick", function(self, mouseBtn)
                if mouseBtn == "RightButton" and IsAltKeyDown() and (self.itemID or self._bfbItemID) then
                    BFB:ShowCategoryContextMenu(self, self.itemID or self._bfbItemID, self.itemLink or self._bfbItemLink)
                    return
                end
                local bID = self._bfbBagID or (self.GetBagID and self:GetBagID()) or (self:GetParent() and self:GetParent():GetID())
                local sID = self._bfbSlotID or self:GetID()
                if not bID or not sID then return end
                if mouseBtn == "LeftButton" then
                    if C_Container and C_Container.PickupContainerItem then
                        C_Container.PickupContainerItem(bID, sID)
                    elseif PickupContainerItem then
                        PickupContainerItem(bID, sID)
                    end
                elseif mouseBtn == "RightButton" then
                    if C_Container and C_Container.UseContainerItem then
                        C_Container.UseContainerItem(bID, sID)
                    elseif UseContainerItem then
                        UseContainerItem(bID, sID)
                    end
                end
            end)
        end

        if not button:GetScript("OnDragStart") then
            button:SetScript("OnDragStart", function(self)
                local bID = self._bfbBagID or (self.GetBagID and self:GetBagID()) or (self:GetParent() and self:GetParent():GetID())
                local sID = self._bfbSlotID or self:GetID()
                if not bID or not sID then return end
                if C_Container and C_Container.PickupContainerItem then
                    C_Container.PickupContainerItem(bID, sID)
                elseif PickupContainerItem then
                    PickupContainerItem(bID, sID)
                end
            end)
            button:SetScript("OnReceiveDrag", function(self)
                local bID = self._bfbBagID or (self.GetBagID and self:GetBagID()) or (self:GetParent() and self:GetParent():GetID())
                local sID = self._bfbSlotID or self:GetID()
                if not bID or not sID then return end
                if C_Container and C_Container.PickupContainerItem then
                    C_Container.PickupContainerItem(bID, sID)
                elseif PickupContainerItem then
                    PickupContainerItem(bID, sID)
                end
            end)
        end

        -- Helper method to bind bag and slot without tainting Blizzard container frame
        function button:SetBagSlot(bagID, slotID)
            self._bfbBagID = bagID
            self._bfbSlotID = slotID
            self:SetID(slotID)
            -- Crucial: self.bagID is left nil so Blizzard's ContainerFrameItemButtonMixin:GetBagID()
            -- queries self:GetParent():GetID() (clean C frame ID) without addon taint.
            self.bagID = nil
            self.slotID = nil
        end
    end

    button:SetParent(parent)
    button:ClearAllPoints()
    if parent and parent.GetFrameStrata then
        button:SetFrameStrata(parent:GetFrameStrata())
    end
    if parent and parent.GetFrameLevel then
        button:SetFrameLevel(parent:GetFrameLevel() + 2)
    end
    button:Show()
    table.insert(activeButtons, button)
    return button
end

local function ResetPooledButton(btn)
    btn:Hide()
    btn:ClearAllPoints()
    btn.bagID = nil
    btn.slotID = nil
    btn._bfbBagID = nil
    btn._bfbSlotID = nil
    btn.itemID = nil
    btn._bfbItemID = nil
    btn.itemLink = nil
    btn._bfbItemLink = nil
    btn.itemName = nil
    btn.itemQuality = nil
    if btn.NewItemTexture then
        btn.NewItemTexture:Hide()
        btn.NewItemTexture:SetAlpha(0)
    end
    if btn.newitemglowAnim then
        btn.newitemglowAnim:Stop()
    end
    if btn.flashAnim then
        btn.flashAnim:Stop()
    end
    if btn.flash then
        btn.flash:Hide()
        btn.flash:SetAlpha(0)
    end
    if btn.BattlepayItemTexture then
        btn.BattlepayItemTexture:Hide()
    end
    if btn.UpgradeIcon then btn.UpgradeIcon:Hide() end
    if btn.ExtendedSlot then btn.ExtendedSlot:Hide() end
    if btn.BagIndicator then btn.BagIndicator:Hide() end
    if btn.QualityBorder then btn.QualityBorder:Hide() end
    if btn.SpecialtyBorder then btn.SpecialtyBorder:Hide() end
    if btn.UnusableOverlay then btn.UnusableOverlay:Hide() end
    if btn.RecentGlow then btn.RecentGlow:Hide() end
    if btn.JunkIcon then btn.JunkIcon:Hide() end
    if btn.QuestIcon then btn.QuestIcon:Hide() end
    if btn.icon then btn.icon:SetVertexColor(1.0, 1.0, 1.0) end
    btn:SetAlpha(1.0)
    table.insert(buttonPool, btn)
end

-- Release a specific list of buttons back to Pool
function ItemButtons:ReleaseButtons(buttonList)
    if not buttonList then return end
    for _, btn in ipairs(buttonList) do
        ResetPooledButton(btn)
    end
    wipe(buttonList)
end

-- Release All Active Buttons back to Pool
function ItemButtons:ReleaseAll()
    for _, btn in ipairs(activeButtons) do
        ResetPooledButton(btn)
    end
    wipe(activeButtons)
end

-- Update an Item Button with Current Inventory Data
function ItemButtons:UpdateButton(button, bagID, slotID, searchTerm)
    button:SetBagSlot(bagID, slotID)
    local db = BFB.db or {}
    
    local info = GetContainerItemInfoCompat(bagID, slotID)
    local icon = info and (info.iconFileID or info.icon or info.texture)
    if not info or not icon then
        -- Empty Slot
        button.icon:Hide()
        button.Count:Hide()
        if button.Cooldown then button.Cooldown:Hide() end
        if button.QualityBorder then button.QualityBorder:Hide() end
        if button.JunkIcon then button.JunkIcon:Hide() end
        if button.QuestIcon then button.QuestIcon:Hide() end
        if button.RecentGlow then button.RecentGlow:Hide() end
        if button.UnusableOverlay then button.UnusableOverlay:Hide() end
        if button.NewItemTexture then button.NewItemTexture:Hide(); button.NewItemTexture:SetAlpha(0) end
        if button.newitemglowAnim then button.newitemglowAnim:Stop() end
        if button.flashAnim then button.flashAnim:Stop() end
        if button.flash then button.flash:Hide(); button.flash:SetAlpha(0) end
        if button.BattlepayItemTexture then button.BattlepayItemTexture:Hide() end
        if button.UpgradeIcon then button.UpgradeIcon:Hide() end
        if button.ExtendedSlot then button.ExtendedSlot:Hide() end
        if button.BagIndicator then button.BagIndicator:Hide() end
        button.icon:SetVertexColor(1.0, 1.0, 1.0)
        button.itemID = nil
        button.itemLink = nil
        button.itemName = nil
        button.itemQuality = nil
        button:SetAlpha(1.0)

        -- Specialty Container Slot Tint (Soul, Herb, Mining, Enchanting, Ammo)
        local specialty = (db.highlightSpecialtyBags ~= false) and BFB:GetBagSpecialty(bagID)
        if specialty and button.SpecialtyBorder then
            button.SpecialtyBorder:SetColorTexture(specialty.r, specialty.g, specialty.b, 0.50)
            button.SpecialtyBorder:Show()
        else
            if button.SpecialtyBorder then button.SpecialtyBorder:Hide() end
        end
        return
    else
        if button.SpecialtyBorder then button.SpecialtyBorder:Hide() end
    end

    -- Has Item
    if button.NewItemTexture then button.NewItemTexture:Hide(); button.NewItemTexture:SetAlpha(0) end
    if button.newitemglowAnim then button.newitemglowAnim:Stop() end
    if button.flashAnim then button.flashAnim:Stop() end
    if button.flash then button.flash:Hide(); button.flash:SetAlpha(0) end
    if button.BattlepayItemTexture then button.BattlepayItemTexture:Hide() end
    if button.UpgradeIcon then button.UpgradeIcon:Hide() end
    if button.ExtendedSlot then button.ExtendedSlot:Hide() end
    if button.BagIndicator then button.BagIndicator:Hide() end

    button.icon:Show()
    button.icon:SetTexture(icon)

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
    local itemID = info.itemID
    if not itemID and link then
        local match = link:match("item:(%d+)")
        if match then itemID = tonumber(match) end
    end
    button.itemID = itemID
    button._bfbItemID = itemID
    button.itemLink = link
    button._bfbItemLink = link

    local isQuestItem = false
    local itemName = ""
    local classID, equipLoc

    if link then
        local rawName, _, q, _, _, _, _, _, el, _, _, cID = GetItemInfoCompat(link)
        if rawName then itemName = rawName end
        if q then quality = q end
        if cID then classID = cID end
        if el then equipLoc = el end
        if classID == 12 or (info.isQuestItem) then
            isQuestItem = true
        end
    end
    button.itemName = itemName
    button.itemQuality = quality

    -- Unusable Equipment Red Tint
    local isUnusable = (db.tintUnusable ~= false) and BFB:IsItemUnusable(bagID, slotID, link)
    if isUnusable then
        button.icon:SetVertexColor(1.0, 0.25, 0.25)
        if button.UnusableOverlay then button.UnusableOverlay:Show() end
    else
        button.icon:SetVertexColor(1.0, 1.0, 1.0)
        if button.UnusableOverlay then button.UnusableOverlay:Hide() end
    end

    -- Recent Item Indicator
    local isRecent = itemID and BFB.CategoryEngine and BFB.CategoryEngine:IsRecent(itemID)
    if isRecent and button.RecentGlow then
        button.RecentGlow:Show()
    else
        if button.RecentGlow then button.RecentGlow:Hide() end
    end

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

    -- Search Filtering Dimming (Supports Advanced Keywords)
    if searchTerm and searchTerm ~= "" then
        local termLower = searchTerm:lower():trim()
        local match = MatchesAdvancedSearch(itemName, link, quality, classID, equipLoc, termLower)

        if match then
            button:SetAlpha(1.0)
        else
            button:SetAlpha(0.20) -- Dim non-matching items
        end
    else
        button:SetAlpha(1.0)
    end
end
