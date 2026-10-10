local addonName, BFB = ...

BFB.BagFrame = {}
local BagFrame = BFB.BagFrame

local function GetItemInfo(item)
    if not item then return nil end
    if C_Item and C_Item.GetItemInfo then
        return C_Item.GetItemInfo(item)
    elseif _G.GetItemInfo then
        return _G.GetItemInfo(item)
    end
    return nil
end

local mainFrame = nil
local moverOverlay = nil
local activeGridButtons = {}
local bagSlotButtons = {}
local categoryHeaders = {}
local categoryHeaderPool = {}

local BACKDROP_PANEL = {
    bgFile = "Interface\\Buttons\\WHITE8x8",
    edgeFile = "Interface\\Buttons\\WHITE8x8",
    tile = false,
    tileSize = 0,
    edgeSize = 1,
    insets = { left = 1, right = 1, top = 1, bottom = 1 },
}

-- Acquire Category Header
local function AcquireCategoryHeader(parent, categoryID, titleText, count, color, isCollapsed, onToggle)
    local header = table.remove(categoryHeaderPool)
    if not header then
        header = CreateFrame("Button", nil, parent, "BackdropTemplate")
        if not header.SetBackdrop and BackdropTemplateMixin then
            Mixin(header, BackdropTemplateMixin)
        end
        header:SetHeight(18)
        header:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8x8",
            edgeFile = "Interface\\Buttons\\WHITE8x8",
            edgeSize = 1,
        })
        header:SetBackdropColor(0.05, 0.06, 0.09, 0.85)
        header:SetBackdropBorderColor(0.25, 0.30, 0.40, 0.70)

        local arrow = header:CreateFontString(nil, "OVERLAY")
        arrow:SetPoint("LEFT", header, "LEFT", 3, 0)
        header.Arrow = arrow

        local countFs = header:CreateFontString(nil, "OVERLAY")
        countFs:SetPoint("RIGHT", header, "RIGHT", -4, 0)
        header.Count = countFs

        local title = header:CreateFontString(nil, "OVERLAY")
        title:SetPoint("LEFT", arrow, "RIGHT", 3, 0)
        title:SetPoint("RIGHT", countFs, "LEFT", -2, 0)
        title:SetJustifyH("LEFT")
        title:SetWordWrap(false)
        header.Title = title
    end

    local db = BFB.db or {}
    local fFamily = BFB:FetchFont(db.font or BFB.DEFAULT_FONT_NAME)
    local hFamily = BFB:FetchFont(db.headerFont or BFB.DEFAULT_HEADER_FONT_NAME)
    local outline = db.fontOutline or "OUTLINE"
    if outline == "None" or outline == "NONE" then outline = "" end
    local hSize = db.headerFontSize or 12
    local cSize = db.countFontSize or 9

    if header.Arrow then header.Arrow:SetFont(hFamily, math.max(8, hSize - 3), outline) end
    if header.Title then header.Title:SetFont(hFamily, math.max(8, hSize - 2), outline) end
    if header.Count then header.Count:SetFont(fFamily, cSize, outline) end

    header:SetParent(parent)
    header.categoryID = categoryID
    header.Arrow:SetText(isCollapsed and "|cffffd100[+]|r" or "|cffffd100[-]|r")
    
    local r = (color and color.r) or 1
    local g = (color and color.g) or 1
    local b = (color and color.b) or 1
    header.Title:SetTextColor(r, g, b, 1.0)
    header.Title:SetText(titleText or categoryID)

    header.Count:SetText(string.format("|cffaaaaaa(%d)|r", count or 0))
    header:SetScript("OnClick", function()
        if onToggle then onToggle(categoryID) end
    end)
    header:Show()

    table.insert(categoryHeaders, header)
    return header
end

local function ReleaseCategoryHeaders()
    for _, h in ipairs(categoryHeaders) do
        h:Hide()
        h:ClearAllPoints()
        table.insert(categoryHeaderPool, h)
    end
    wipe(categoryHeaders)
end

-- Initialize Main Bag Container Frame
function BagFrame:Init()
    if mainFrame then return mainFrame end

    mainFrame = CreateFrame("Frame", "BleakfibersBags_MainFrame", UIParent, "BackdropTemplate")
    if not mainFrame.SetBackdrop and BackdropTemplateMixin then
        Mixin(mainFrame, BackdropTemplateMixin)
    end

    mainFrame:SetFrameStrata("HIGH")
    mainFrame:SetToplevel(true)
    mainFrame:SetClampedToScreen(true)
    mainFrame:EnableMouse(true)
    mainFrame:SetMovable(true)
    mainFrame:RegisterForDrag("LeftButton")

    -- Backdrop & Theme
    mainFrame:SetBackdrop(BACKDROP_PANEL)
    mainFrame:SetBackdropColor(0.08, 0.09, 0.12, 0.94)
    mainFrame:SetBackdropBorderColor(0.85, 0.65, 0.15, 1.0)

    -- Dragging & Position Management
    mainFrame:SetScript("OnDragStart", function(self)
        if self:IsMovable() then
            self:StartMoving()
        end
    end)
    mainFrame:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        BagFrame:SavePosition()
    end)

    -- Header Bar
    local header = CreateFrame("Frame", nil, mainFrame)
    header:SetHeight(30)
    header:SetPoint("TOPLEFT", 8, -6)
    header:SetPoint("TOPRIGHT", -8, -6)
    mainFrame.Header = header

    -- Title FontString
    local title = header:CreateFontString(nil, "OVERLAY")
    title:SetFont(BFB:FetchFont(BFB.DEFAULT_HEADER_FONT_NAME), 12, "OUTLINE")
    title:SetTextColor(1.0, 0.82, 0.0, 1.0)
    title:SetText("Bleakfiber's Bags")
    title:SetPoint("LEFT", header, "LEFT", 4, 0)
    mainFrame.Title = title

    -- Close Button
    local closeBtn = CreateFrame("Button", nil, header)
    closeBtn:SetSize(18, 18)
    closeBtn:SetPoint("RIGHT", header, "RIGHT", -2, 0)
    local closeText = closeBtn:CreateFontString(nil, "OVERLAY")
    closeText:SetFont(BFB:FetchFont(BFB.DEFAULT_HEADER_FONT_NAME), 13, "OUTLINE")
    closeText:SetText("|cffff4444✕|r")
    closeText:SetPoint("CENTER")
    mainFrame.CloseText = closeText
    closeBtn:SetScript("OnClick", function()
        BagFrame:Hide()
    end)
    closeBtn:SetScript("OnEnter", function() closeText:SetText("|cffffffff✕|r") end)
    closeBtn:SetScript("OnLeave", function() closeText:SetText("|cffff4444✕|r") end)

    -- Bag Slot Drawer Toggle Button
    local bagSlotToggle = CreateFrame("Button", nil, header)
    bagSlotToggle:SetSize(18, 18)
    bagSlotToggle:SetPoint("RIGHT", closeBtn, "LEFT", -6, 0)
    local bagIcon = bagSlotToggle:CreateTexture(nil, "ARTWORK")
    bagIcon:SetAllPoints()
    bagIcon:SetTexture("Interface\\Buttons\\Button-Backpack-Up")
    bagSlotToggle:SetScript("OnClick", function()
        local db = BFB.db or {}
        db.showBagSlotBar = not db.showBagSlotBar
        BagFrame:UpdateBagSlotBar()
        BagFrame:UpdateLayout()
    end)
    bagSlotToggle:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_TOP")
        GameTooltip:AddLine("Equipped Bags Drawer", 1, 0.82, 0)
        GameTooltip:AddLine("Click to show or hide equipped bag containers.", 1, 1, 1, true)
        GameTooltip:Show()
    end)
    bagSlotToggle:SetScript("OnLeave", function() GameTooltip:Hide() end)

    -- Keyring Toggle Button (Native Keyring support in Classic Forever)
    local keyringBtn = CreateFrame("Button", nil, header)
    keyringBtn:SetSize(18, 18)
    keyringBtn:SetPoint("RIGHT", bagSlotToggle, "LEFT", -6, 0)
    local keyIcon = keyringBtn:CreateTexture(nil, "ARTWORK")
    keyIcon:SetAllPoints()
    keyIcon:SetTexture("Interface\\ContainerFrame\\KeyRing-Bag-Icon")
    keyringBtn:SetScript("OnClick", function()
        if ToggleKeyRing then
            ToggleKeyRing()
        end
    end)
    keyringBtn:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_TOP")
        GameTooltip:AddLine("Keyring", 1, 0.82, 0)
        GameTooltip:AddLine("Click to open or close the keyring.", 1, 1, 1, true)
        GameTooltip:Show()
    end)
    keyringBtn:SetScript("OnLeave", function() GameTooltip:Hide() end)

    -- View Mode Toggle Button (Grid vs Categorized)
    local viewToggle = CreateFrame("Button", nil, header)
    viewToggle:SetSize(18, 18)
    viewToggle:SetPoint("RIGHT", keyringBtn, "LEFT", -6, 0)
    local viewIcon = viewToggle:CreateTexture(nil, "ARTWORK")
    viewIcon:SetAllPoints()
    viewIcon:SetTexture("Interface\\Buttons\\UI-Guild-Log")
    viewToggle:SetScript("OnClick", function()
        local db = BFB.db or {}
        if db.viewMode == "category" then
            db.viewMode = "grid"
        else
            db.viewMode = "category"
        end
        BagFrame:UpdateLayout()
    end)
    viewToggle:SetScript("OnEnter", function(self)
        local db = BFB.db or {}
        local currentMode = (db.viewMode == "category") and "Categorized" or "All-in-One Grid"
        GameTooltip:SetOwner(self, "ANCHOR_TOP")
        GameTooltip:AddLine("Toggle View Mode", 1, 0.82, 0)
        GameTooltip:AddDoubleLine("Current Mode:", currentMode, 1, 1, 1, 0.2, 0.8, 1)
        GameTooltip:AddLine("Switch between All-in-One Grid and Intelligent Categorized sections.", 0.8, 0.8, 0.8, true)
        GameTooltip:Show()
    end)
    viewToggle:SetScript("OnLeave", function() GameTooltip:Hide() end)

    -- Sort & Consolidate Button
    local sortBtn = CreateFrame("Button", nil, header)
    sortBtn:SetSize(18, 18)
    sortBtn:SetPoint("RIGHT", viewToggle, "LEFT", -6, 0)
    local sortIcon = sortBtn:CreateTexture(nil, "ARTWORK")
    sortIcon:SetAllPoints()
    sortIcon:SetTexture("Interface\\Buttons\\UI-GroupLoot-Dice-Up")
    sortBtn:SetScript("OnClick", function()
        if BFB.Sorting then
            BFB.Sorting:StartSort()
        end
    end)
    sortBtn:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_TOP")
        GameTooltip:AddLine("Sort & Consolidate Bags", 1, 0.82, 0)
        GameTooltip:AddLine("Consolidates partial stacks and sorts items by category, quality, and level.", 1, 1, 1, true)
        GameTooltip:Show()
    end)
    sortBtn:SetScript("OnLeave", function() GameTooltip:Hide() end)

    -- Live Search EditBox
    local searchBox = CreateFrame("EditBox", "BleakfibersBagsSearchBox", header, "BackdropTemplate")
    if not searchBox.SetBackdrop and BackdropTemplateMixin then
        Mixin(searchBox, BackdropTemplateMixin)
    end
    searchBox:SetHeight(18)
    searchBox:SetWidth(95)
    searchBox:SetPoint("RIGHT", sortBtn, "LEFT", -8, 0)
    searchBox:SetAutoFocus(false)
    searchBox:SetFont(BFB:FetchFont(BFB.DEFAULT_FONT_NAME), 10, "")
    searchBox:SetTextColor(0.9, 0.9, 0.9, 1.0)
    searchBox:SetTextInsets(6, 16, 0, 0)

    searchBox:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
    })
    searchBox:SetBackdropColor(0.04, 0.04, 0.06, 0.85)
    searchBox:SetBackdropBorderColor(0.3, 0.3, 0.35, 0.9)

    -- Search Placeholder
    local searchPlaceholder = searchBox:CreateFontString(nil, "OVERLAY")
    searchPlaceholder:SetFont(BFB:FetchFont(BFB.DEFAULT_FONT_NAME), 9, "")
    searchPlaceholder:SetTextColor(0.5, 0.5, 0.5, 0.8)
    searchPlaceholder:SetText("Search...")
    searchPlaceholder:SetPoint("LEFT", 6, 0)

    -- Search Clear (X) Button
    local clearSearchBtn = CreateFrame("Button", nil, searchBox)
    clearSearchBtn:SetSize(14, 14)
    clearSearchBtn:SetPoint("RIGHT", searchBox, "RIGHT", -2, 0)
    local clearText = clearSearchBtn:CreateFontString(nil, "OVERLAY")
    clearText:SetFont(BFB:FetchFont(BFB.DEFAULT_FONT_NAME), 9, "OUTLINE")
    clearText:SetText("|cff888888✕|r")
    clearText:SetPoint("CENTER")
    clearSearchBtn:Hide()

    mainFrame.SearchBox = searchBox
    mainFrame.SearchPlaceholder = searchPlaceholder
    mainFrame.ClearText = clearText

    clearSearchBtn:SetScript("OnClick", function()
        searchBox:SetText("")
        searchBox:ClearFocus()
    end)

    searchBox:SetScript("OnTextChanged", function(self)
        local text = self:GetText()
        if text and text ~= "" then
            searchPlaceholder:Hide()
            clearSearchBtn:Show()
        else
            searchPlaceholder:Show()
            clearSearchBtn:Hide()
        end
        BagFrame:UpdateSearchFilter(text)
    end)
    searchBox:SetScript("OnEscapePressed", function(self)
        self:SetText("")
        self:ClearFocus()
    end)
    searchBox:SetScript("OnEnterPressed", function(self)
        self:ClearFocus()
    end)
    mainFrame.SearchBox = searchBox

    -- Bag Slots Drawer (Equipped Bags 0..4)
    local bagSlotBar = CreateFrame("Frame", nil, mainFrame, "BackdropTemplate")
    if not bagSlotBar.SetBackdrop and BackdropTemplateMixin then
        Mixin(bagSlotBar, BackdropTemplateMixin)
    end
    bagSlotBar:SetHeight(32)
    bagSlotBar:SetPoint("TOPLEFT", header, "BOTTOMLEFT", 0, -2)
    bagSlotBar:SetPoint("TOPRIGHT", header, "BOTTOMRIGHT", 0, -2)
    bagSlotBar:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
    })
    bagSlotBar:SetBackdropColor(0.04, 0.05, 0.07, 0.90)
    bagSlotBar:SetBackdropBorderColor(0.2, 0.25, 0.35, 0.6)
    bagSlotBar:Hide()
    mainFrame.BagSlotBar = bagSlotBar

    -- Create 5 Bag Slot Buttons (Backpack + 4 Bags)
    local bagIDs = { 0, 1, 2, 3, 4 }
    for i, bagID in ipairs(bagIDs) do
        local bSlot = CreateFrame("Button", "BleakfibersBagSlot" .. bagID, bagSlotBar, "BackdropTemplate")
        if not bSlot.SetBackdrop and BackdropTemplateMixin then
            Mixin(bSlot, BackdropTemplateMixin)
        end
        bSlot:SetSize(26, 26)
        bSlot:SetPoint("LEFT", bagSlotBar, "LEFT", 6 + (i - 1) * 32, 0)
        bSlot:SetBackdrop(BACKDROP_PANEL)
        bSlot:SetBackdropColor(0.08, 0.09, 0.12, 1.0)
        bSlot:SetBackdropBorderColor(0.5, 0.5, 0.5, 0.8)

        local icon = bSlot:CreateTexture(nil, "ARTWORK")
        icon:SetAllPoints()
        bSlot.Icon = icon

        local count = bSlot:CreateFontString(nil, "OVERLAY")
        count:SetFont(BFB:FetchFont(BFB.DEFAULT_FONT_NAME), 8, "OUTLINE")
        count:SetPoint("BOTTOMRIGHT", bSlot, "BOTTOMRIGHT", -1, 1)
        count:SetTextColor(1, 1, 1, 1)
        bSlot.Count = count

        bSlot:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            if bagID == 0 then
                GameTooltip:AddLine("Backpack (16 Slots)", 1, 0.82, 0)
            else
                local invID = ContainerIDToInventoryID and ContainerIDToInventoryID(bagID)
                if invID and GameTooltip.SetInventoryItem then
                    GameTooltip:SetInventoryItem("player", invID)
                else
                    GameTooltip:AddLine("Bag " .. bagID, 1, 0.82, 0)
                end
            end
            GameTooltip:Show()
        end)
        bSlot:SetScript("OnLeave", function() GameTooltip:Hide() end)
        bSlot:SetScript("OnClick", function(self)
            if bagID > 0 then
                local invID = ContainerIDToInventoryID and ContainerIDToInventoryID(bagID)
                if invID and PickupInventoryItem then
                    PickupInventoryItem(invID)
                end
            end
        end)

        bagSlotButtons[bagID] = bSlot
    end

    -- Item Grid Container
    local gridContainer = CreateFrame("Frame", nil, mainFrame)
    gridContainer:SetPoint("TOPLEFT", mainFrame, "TOPLEFT", 10, -38)
    gridContainer:SetFrameStrata(mainFrame:GetFrameStrata() or "HIGH")
    gridContainer:SetFrameLevel(mainFrame:GetFrameLevel() + 1)
    mainFrame.GridContainer = gridContainer

    -- Footer Bar
    local footer = CreateFrame("Frame", nil, mainFrame)
    footer:SetHeight(26)
    footer:SetPoint("BOTTOMLEFT", 8, 4)
    footer:SetPoint("BOTTOMRIGHT", -8, 4)
    mainFrame.Footer = footer

    -- Free Slots Display FontString
    local freeSlotsText = footer:CreateFontString(nil, "OVERLAY")
    freeSlotsText:SetFont(BFB:FetchFont(BFB.DEFAULT_FONT_NAME), 10, "OUTLINE")
    freeSlotsText:SetTextColor(0.85, 0.85, 0.85, 1.0)
    freeSlotsText:SetPoint("LEFT", footer, "LEFT", 4, 0)
    mainFrame.FreeSlotsText = freeSlotsText

    -- Interactive Tooltip on Free Slots Text
    local freeSlotsHit = CreateFrame("Button", nil, footer)
    freeSlotsHit:SetAllPoints(freeSlotsText)
    freeSlotsHit:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_TOPLEFT")
        GameTooltip:AddLine("Bag Capacity Breakdown", 1, 0.82, 0)
        local totalFree, totalSlots = 0, 0
        for bag = 0, 4 do
            local numSlots = BFB.GetNumSlots(bag)
            if numSlots and numSlots > 0 then
                local free = 0
                for slot = 1, numSlots do
                    local info = BFB.GetItemInfo(bag, slot)
                    if not info or not info.iconFileID then
                        free = free + 1
                    end
                end
                totalFree = totalFree + free
                totalSlots = totalSlots + numSlots
                local bagName = (bag == 0) and "Backpack" or ("Bag " .. bag)
                GameTooltip:AddDoubleLine(bagName, string.format("%d / %d free", free, numSlots), 1, 1, 1, 0.2, 1, 0.2)
            end
        end
        GameTooltip:AddLine(" ")
        GameTooltip:AddDoubleLine("Total Capacity", string.format("%d / %d free", totalFree, totalSlots), 1, 0.82, 0, 1, 1, 1)
        GameTooltip:Show()
    end)
    freeSlotsHit:SetScript("OnLeave", function() GameTooltip:Hide() end)

    -- Money Counter FontString
    local moneyText = footer:CreateFontString(nil, "OVERLAY")
    moneyText:SetFont(BFB:FetchFont(BFB.DEFAULT_FONT_NAME), 10, "OUTLINE")
    moneyText:SetPoint("RIGHT", footer, "RIGHT", -4, 0)
    mainFrame.MoneyText = moneyText

    -- Mover Frame Overlay
    moverOverlay = CreateFrame("Frame", nil, mainFrame, "BackdropTemplate")
    if not moverOverlay.SetBackdrop and BackdropTemplateMixin then
        Mixin(moverOverlay, BackdropTemplateMixin)
    end
    moverOverlay:SetAllPoints()
    moverOverlay:SetFrameStrata("TOOLTIP")
    moverOverlay:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 2,
    })
    moverOverlay:SetBackdropColor(0.1, 0.1, 0.15, 0.85)
    moverOverlay:SetBackdropBorderColor(0.2, 0.8, 1.0, 1.0)
    moverOverlay:EnableMouse(true)
    moverOverlay:RegisterForDrag("LeftButton")
    moverOverlay:Hide()

    local moverLabel = moverOverlay:CreateFontString(nil, "OVERLAY")
    moverLabel:SetFont(BFB:FetchFont(BFB.DEFAULT_HEADER_FONT_NAME), 12, "OUTLINE")
    moverLabel:SetTextColor(0.2, 0.8, 1.0, 1.0)
    moverLabel:SetText("Bleakfiber's Bags Mover\n|cffffffffDrag to reposition|r\n|cffaaaaaaRight-Click to Lock|r")
    moverLabel:SetPoint("CENTER")
    moverOverlay.Label = moverLabel
    mainFrame.MoverOverlay = moverOverlay

    moverOverlay:SetScript("OnDragStart", function()
        if mainFrame:IsMovable() then
            mainFrame:StartMoving()
        end
    end)
    moverOverlay:SetScript("OnDragStop", function()
        mainFrame:StopMovingOrSizing()
        BagFrame:SavePosition()
    end)
    moverOverlay:SetScript("OnMouseUp", function(self, button)
        if button == "RightButton" then
            BFB:ToggleMovers(false)
        end
    end)

    -- Apply Saved Coordinates
    self:LoadPosition()

    mainFrame:HookScript("OnShow", function()
        if BFB.ClearNewItems then
            BFB:ClearNewItems()
        end
    end)

    -- Initial Update
    self:UpdateBagSlotBar()
    self:UpdateLayout()
    self:UpdateMoney()

    mainFrame:Hide()
    return mainFrame
end

-- Dynamically update all text typography on BagFrame
function BagFrame:UpdateFonts()
    if not mainFrame then return end
    local db = BFB.db or {}
    local font = BFB:FetchFont(db.font or BFB.DEFAULT_FONT_NAME)
    local headerFont = BFB:FetchFont(db.headerFont or BFB.DEFAULT_HEADER_FONT_NAME)
    local outline = db.fontOutline or "OUTLINE"
    if outline == "None" or outline == "NONE" then outline = "" end
    local hSize = db.headerFontSize or 12
    local cSize = db.countFontSize or 9

    if mainFrame.Title then mainFrame.Title:SetFont(headerFont, hSize, outline) end
    if mainFrame.CloseText then mainFrame.CloseText:SetFont(headerFont, hSize + 1, outline) end
    if mainFrame.SearchBox then mainFrame.SearchBox:SetFont(font, 10, "") end
    if mainFrame.SearchPlaceholder then mainFrame.SearchPlaceholder:SetFont(font, 9, "") end
    if mainFrame.ClearText then mainFrame.ClearText:SetFont(font, 9, outline) end
    if mainFrame.FreeSlotsText then mainFrame.FreeSlotsText:SetFont(font, cSize + 1, outline) end
    if mainFrame.MoneyText then mainFrame.MoneyText:SetFont(font, cSize + 1, outline) end
    if moverOverlay and moverOverlay.Label then moverOverlay.Label:SetFont(headerFont, hSize, outline) end

    for _, header in pairs(categoryHeaders) do
        if header.Arrow then header.Arrow:SetFont(headerFont, math.max(8, hSize - 3), outline) end
        if header.Title then header.Title:SetFont(headerFont, math.max(8, hSize - 2), outline) end
        if header.Count then header.Count:SetFont(font, cSize, outline) end
    end
end

-- Save Frame Position
function BagFrame:SavePosition()
    if not mainFrame then return end
    local db = BFB.db or {}
    db.bagPosition = db.bagPosition or {}

    local point, _, relPoint, x, y = mainFrame:GetPoint()
    db.bagPosition.point = point or "BOTTOMRIGHT"
    db.bagPosition.relativePoint = relPoint or "BOTTOMRIGHT"
    db.bagPosition.x = x or -45
    db.bagPosition.y = y or 180
end

-- Load Frame Position
function BagFrame:LoadPosition()
    if not mainFrame then return end
    local db = BFB.db or {}
    local pos = db.bagPosition or {}
    local point = pos.point or "BOTTOMRIGHT"
    local relPoint = pos.relativePoint or "BOTTOMRIGHT"
    local x = pos.x or -45
    local y = pos.y or 180

    mainFrame:ClearAllPoints()
    mainFrame:SetPoint(point, UIParent, relPoint, x, y)
end

-- Set Mover State
function BagFrame:SetMoverActive(active)
    if not mainFrame then return end
    if active then
        mainFrame:Show()
        if moverOverlay then moverOverlay:Show() end
    else
        if moverOverlay then moverOverlay:Hide() end
    end
end

-- Update Bag Slot Drawer Icons & Status
function BagFrame:UpdateBagSlotBar()
    local db = BFB.db or {}
    if not mainFrame or not mainFrame.BagSlotBar then return end

    mainFrame.GridContainer:ClearAllPoints()
    if db.showBagSlotBar then
        mainFrame.BagSlotBar:Show()
        mainFrame.GridContainer:SetPoint("TOPLEFT", mainFrame, "TOPLEFT", 10, -74)
    else
        mainFrame.BagSlotBar:Hide()
        mainFrame.GridContainer:SetPoint("TOPLEFT", mainFrame, "TOPLEFT", 10, -38)
    end

    for bagID, btn in pairs(bagSlotButtons) do
        if bagID == 0 then
            btn.Icon:SetTexture("Interface\\Buttons\\Button-Backpack-Up")
            btn.Count:SetText("16")
        else
            local invID = ContainerIDToInventoryID and ContainerIDToInventoryID(bagID)
            local itemLink = invID and GetInventoryItemLink and GetInventoryItemLink("player", invID)
            local numSlots = BFB.GetNumSlots(bagID)

            if itemLink then
                local icon = GetInventoryItemTexture("player", invID)
                btn.Icon:SetTexture(icon or "Interface\\Icons\\INV_Misc_Bag_08")
                btn.Count:SetText(numSlots and tostring(numSlots) or "")
                local _, _, quality = GetItemInfo(itemLink)
                if quality and quality > 1 then
                    local r, g, b = BFB:GetItemQualityColor(quality)
                    btn:SetBackdropBorderColor(r, g, b, 1.0)
                else
                    btn:SetBackdropBorderColor(0.5, 0.5, 0.5, 0.8)
                end
            else
                btn.Icon:SetTexture("Interface\\PaperDoll\\UI-PaperDoll-Slot-Bag")
                btn.Count:SetText("")
                btn:SetBackdropBorderColor(0.25, 0.25, 0.3, 0.6)
            end
        end
    end
end

-- Update Main Inventory Layout (All-in-One Grid or Categorized)
function BagFrame:UpdateLayout()
    if not mainFrame then return end
    local db = BFB.db or {}
    local cols = db.columns or 10
    local btnSize = db.buttonSize or 37
    local spacing = db.buttonSpacing or 4
    local isCategoryView = (db.viewMode == "category")
    db.collapsedCategories = db.collapsedCategories or {}

    if BFB.ItemButtons.ReleaseButtons then
        BFB.ItemButtons:ReleaseButtons(activeGridButtons)
    else
        BFB.ItemButtons:ReleaseAll()
        wipe(activeGridButtons)
    end
    ReleaseCategoryHeaders()

    if not mainFrame.bagContainers then
        mainFrame.bagContainers = {}
    end
    local function GetBagContainer(bagID)
        local c = mainFrame.bagContainers[bagID]
        if not c then
            c = CreateFrame("Frame", nil, mainFrame.GridContainer)
            c:SetID(bagID)
            c:SetAllPoints(mainFrame.GridContainer)
            c:Show()
            mainFrame.bagContainers[bagID] = c
        end
        return c
    end

    if BFB.ClearNewItems then
        BFB:ClearNewItems()
    end

    local totalSlots = 0
    local freeSlots = 0

    -- Gather all slots from bags 0 to 4
    local slotList = {}
    for bagID = 0, 4 do
        local numSlots = BFB.GetNumSlots(bagID)
        if numSlots and numSlots > 0 then
            totalSlots = totalSlots + numSlots
            for slotID = 1, numSlots do
                local info = BFB.GetItemInfo(bagID, slotID)
                if not info or not (info.iconFileID or info.icon or info.texture) then
                    freeSlots = freeSlots + 1
                end
                table.insert(slotList, { bag = bagID, slot = slotID })
            end
        end
    end

    local searchTerm = mainFrame.SearchBox and mainFrame.SearchBox:GetText()
    local totalContentH = 0

    if not isCategoryView then
        -- 1. All-in-One Grid Mode
        local numItems = #slotList
        local rows = math.ceil(numItems / cols)
        if rows < 1 then rows = 1 end

        for idx, slotData in ipairs(slotList) do
            local bagContainer = GetBagContainer(slotData.bag)
            local btn = BFB.ItemButtons:Acquire(bagContainer)
            btn:ClearAllPoints()
            btn:SetSize(btnSize, btnSize)

            local row = math.floor((idx - 1) / cols)
            local col = (idx - 1) % cols

            local x = col * (btnSize + spacing)
            local y = -row * (btnSize + spacing)

            btn:SetPoint("TOPLEFT", mainFrame.GridContainer, "TOPLEFT", x, y)
            BFB.ItemButtons:UpdateButton(btn, slotData.bag, slotData.slot, searchTerm)
            table.insert(activeGridButtons, btn)
        end

        totalContentH = rows * btnSize + (rows - 1) * spacing
    else
        -- 2. Intelligent Categorized Sections Mode (Space-Consolidating Layout)
        local categories = BFB.CategoryEngine and BFB.CategoryEngine:GroupSlots(slotList) or {}
        local currentY = 0
        local compactMode = (db.compactCategories ~= false)
        local headerH = 18
        local catGap = 4

        if not compactMode then
            -- Traditional Stacked View (Full Width per category with tight padding)
            for _, catGroup in ipairs(categories) do
                local catID = catGroup.id
                local isCollapsed = db.collapsedCategories[catID]
                local numItemsInCat = #catGroup.slots

                local header = AcquireCategoryHeader(
                    mainFrame.GridContainer,
                    catID,
                    catGroup.name,
                    numItemsInCat,
                    catGroup.color,
                    isCollapsed,
                    function(toggledCatID)
                        db.collapsedCategories[toggledCatID] = not db.collapsedCategories[toggledCatID]
                        BagFrame:UpdateLayout()
                    end
                )

                local gridW = cols * btnSize + (cols - 1) * spacing
                header:SetWidth(gridW)
                header:SetPoint("TOPLEFT", mainFrame.GridContainer, "TOPLEFT", 0, currentY)
                currentY = currentY - headerH - spacing

                if not isCollapsed then
                    local catRows = math.ceil(numItemsInCat / cols)
                    if catRows < 1 then catRows = 1 end

                    for idx, slotData in ipairs(catGroup.slots) do
                        local bagContainer = GetBagContainer(slotData.bag)
                        local btn = BFB.ItemButtons:Acquire(bagContainer)
                        btn:ClearAllPoints()
                        btn:SetSize(btnSize, btnSize)

                        local row = math.floor((idx - 1) / cols)
                        local col = (idx - 1) % cols

                        local x = col * (btnSize + spacing)
                        local y = currentY - (row * (btnSize + spacing))

                        btn:SetPoint("TOPLEFT", mainFrame.GridContainer, "TOPLEFT", x, y)
                        BFB.ItemButtons:UpdateButton(btn, slotData.bag, slotData.slot, searchTerm)
                        table.insert(activeGridButtons, btn)
                    end

                    local catBlockH = catRows * btnSize + (catRows - 1) * spacing
                    currentY = currentY - catBlockH - catGap
                else
                    currentY = currentY - catGap
                end
            end
        else
            -- Consolidated Space-Saving Shelf Flow Mode (packs multiple small categories into single rows)
            local shelfX = 0
            local shelfRemainingCols = cols
            local shelfMaxH = 0
            local shelfCategories = {}

            local function FlushShelf()
                if #shelfCategories == 0 then return end
                for _, item in ipairs(shelfCategories) do
                    local header = item.header
                    local catWidth = item.catCols * btnSize + (item.catCols - 1) * spacing
                    header:SetWidth(catWidth)
                    header:SetPoint("TOPLEFT", mainFrame.GridContainer, "TOPLEFT", item.startX, currentY)

                    if not item.isCollapsed then
                        for idx, slotData in ipairs(item.slots) do
                            local bagContainer = GetBagContainer(slotData.bag)
                            local btn = BFB.ItemButtons:Acquire(bagContainer)
                            btn:ClearAllPoints()
                            btn:SetSize(btnSize, btnSize)

                            local row = math.floor((idx - 1) / item.catCols)
                            local col = (idx - 1) % item.catCols

                            local bx = item.startX + col * (btnSize + spacing)
                            local by = currentY - headerH - spacing - row * (btnSize + spacing)

                            btn:SetPoint("TOPLEFT", mainFrame.GridContainer, "TOPLEFT", bx, by)
                            BFB.ItemButtons:UpdateButton(btn, slotData.bag, slotData.slot, searchTerm)
                            table.insert(activeGridButtons, btn)
                        end
                    end
                end

                currentY = currentY - shelfMaxH - catGap
                shelfX = 0
                shelfRemainingCols = cols
                shelfMaxH = 0
                wipe(shelfCategories)
            end

            for _, catGroup in ipairs(categories) do
                local catID = catGroup.id
                local isCollapsed = db.collapsedCategories[catID]
                local numItemsInCat = #catGroup.slots

                local header = AcquireCategoryHeader(
                    mainFrame.GridContainer,
                    catID,
                    catGroup.name,
                    numItemsInCat,
                    catGroup.color,
                    isCollapsed,
                    function(toggledCatID)
                        db.collapsedCategories[toggledCatID] = not db.collapsedCategories[toggledCatID]
                        BagFrame:UpdateLayout()
                    end
                )

                local catCols
                if isCollapsed then
                    catCols = math.min(cols, 2)
                else
                    catCols = math.min(cols, math.max(numItemsInCat, 2))
                end

                local catRows = isCollapsed and 0 or math.ceil(numItemsInCat / catCols)
                local thisH = headerH + ((catRows > 0) and (spacing + catRows * btnSize + (catRows - 1) * spacing) or 0)

                if catCols > shelfRemainingCols and #shelfCategories > 0 then
                    FlushShelf()
                end

                table.insert(shelfCategories, {
                    header = header,
                    catCols = catCols,
                    startX = shelfX,
                    slots = catGroup.slots,
                    isCollapsed = isCollapsed,
                    height = thisH,
                })

                shelfX = shelfX + catCols * (btnSize + spacing)
                shelfRemainingCols = shelfRemainingCols - catCols
                shelfMaxH = math.max(shelfMaxH, thisH)
            end

            if #shelfCategories > 0 then
                FlushShelf()
            end
        end

        totalContentH = math.abs(currentY)
    end

    -- Dynamic Window Sizing
    local gridW = cols * btnSize + (cols - 1) * spacing
    local totalW = gridW + 20
    local headerH = 34 + (db.showBagSlotBar and 36 or 0)
    local footerH = 30
    local totalH = totalContentH + headerH + footerH

    if mainFrame.GridContainer then
        mainFrame.GridContainer:SetSize(gridW, math.max(totalContentH, 37))
    end

    mainFrame:SetSize(math.max(totalW, 260), math.max(totalH, 120))

    -- Update Free Slots Counter
    if mainFrame.FreeSlotsText then
        local ratio = (totalSlots > 0) and (freeSlots / totalSlots) or 0
        local colorCode = "|cff00ff00" -- green
        if ratio <= 0.10 then
            colorCode = "|cffff2020" -- red
        elseif ratio <= 0.25 then
            colorCode = "|cffffaa00" -- orange
        end
        mainFrame.FreeSlotsText:SetText(string.format("Free: %s%d|r / |cffffffff%d|r", colorCode, freeSlots, totalSlots))
    end
end

-- Live Search Filtering
function BagFrame:UpdateSearchFilter(term)
    if not activeGridButtons then return end
    for _, btn in ipairs(activeGridButtons) do
        if btn.bagID and btn.slotID then
            BFB.ItemButtons:UpdateButton(btn, btn.bagID, btn.slotID, term)
        end
    end
end

-- Update Money Counter
function BagFrame:UpdateMoney()
    if not mainFrame or not mainFrame.MoneyText then return end
    local money = GetMoney and GetMoney() or 0

    local gold = math.floor(money / 10000)
    local silver = math.floor((money % 10000) / 100)
    local copper = money % 100

    local formatted = string.format("|cffffd100%d|r|TInterface\\MoneyFrame\\UI-GoldIcon:12:12:1:0|t |cffe6e6e6%d|r|TInterface\\MoneyFrame\\UI-SilverIcon:12:12:1:0|t |cffc87d32%d|r|TInterface\\MoneyFrame\\UI-CopperIcon:12:12:1:0|t", gold, silver, copper)
    mainFrame.MoneyText:SetText(formatted)
end

-- Refresh and Reapply Profile Settings
function BagFrame:ApplySettings()
    self:LoadPosition()
    self:UpdateBagSlotBar()
    self:UpdateLayout()
    self:UpdateMoney()
end

-- Visibility Controls
function BagFrame:Show()
    local frame = self:Init()
    frame:Show()
    self:UpdateBagSlotBar()
    self:UpdateLayout()
    self:UpdateMoney()
end

function BagFrame:Hide()
    if mainFrame then
        mainFrame:Hide()
    end
end

function BagFrame:Toggle()
    local frame = self:Init()
    if frame:IsShown() then
        self:Hide()
    else
        self:Show()
    end
end

function BagFrame:IsShown()
    return mainFrame and mainFrame:IsShown()
end
