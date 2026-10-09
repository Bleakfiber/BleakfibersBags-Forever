local addonName, BFB = ...

BFB.BankFrame = {}
local BankFrame = BFB.BankFrame

local function GetItemInfo(item)
    if not item then return nil end
    if C_Item and C_Item.GetItemInfo then
        return C_Item.GetItemInfo(item)
    elseif _G.GetItemInfo then
        return _G.GetItemInfo(item)
    end
    return nil
end

local bankFrame = nil
local bankMoverOverlay = nil
local activeBankButtons = {}
local bankBagSlotButtons = {}
local bankCategoryHeaders = {}
local bankCategoryHeaderPool = {}
local isBankOpen = false

local BACKDROP_PANEL = {
    bgFile = "Interface\\Buttons\\WHITE8x8",
    edgeFile = "Interface\\Buttons\\WHITE8x8",
    tile = false,
    tileSize = 0,
    edgeSize = 1,
    insets = { left = 1, right = 1, top = 1, bottom = 1 },
}

-- Acquire Category Header for Bank
local function AcquireBankCategoryHeader(parent, categoryID, titleText, count, color, isCollapsed, onToggle)
    local header = table.remove(bankCategoryHeaderPool)
    if not header then
        header = CreateFrame("Button", nil, parent, "BackdropTemplate")
        if not header.SetBackdrop and BackdropTemplateMixin then
            Mixin(header, BackdropTemplateMixin)
        end
        header:SetHeight(20)
        header:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8x8",
            edgeFile = "Interface\\Buttons\\WHITE8x8",
            edgeSize = 1,
        })
        header:SetBackdropColor(0.05, 0.06, 0.09, 0.85)
        header:SetBackdropBorderColor(0.25, 0.30, 0.40, 0.70)

        local arrow = header:CreateFontString(nil, "OVERLAY")
        arrow:SetPoint("LEFT", header, "LEFT", 4, 0)
        header.Arrow = arrow

        local title = header:CreateFontString(nil, "OVERLAY")
        title:SetPoint("LEFT", arrow, "RIGHT", 4, 0)
        header.Title = title

        local countFs = header:CreateFontString(nil, "OVERLAY")
        countFs:SetPoint("RIGHT", header, "RIGHT", -6, 0)
        header.Count = countFs
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
    header.Arrow:SetText(isCollapsed and "|cffffd100▶|r" or "|cffffd100▼|r")

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

    table.insert(bankCategoryHeaders, header)
    return header
end

local function ReleaseBankCategoryHeaders()
    for _, h in ipairs(bankCategoryHeaders) do
        h:Hide()
        h:ClearAllPoints()
        table.insert(bankCategoryHeaderPool, h)
    end
    wipe(bankCategoryHeaders)
end

-- Initialize Bank Container Frame
function BankFrame:Init()
    if bankFrame then return bankFrame end

    bankFrame = CreateFrame("Frame", "BleakfibersBags_BankFrame", UIParent, "BackdropTemplate")
    if not bankFrame.SetBackdrop and BackdropTemplateMixin then
        Mixin(bankFrame, BackdropTemplateMixin)
    end

    bankFrame:SetFrameStrata("HIGH")
    bankFrame:SetToplevel(true)
    bankFrame:SetClampedToScreen(true)
    bankFrame:EnableMouse(true)
    bankFrame:SetMovable(true)
    bankFrame:RegisterForDrag("LeftButton")

    -- Backdrop & Theme
    bankFrame:SetBackdrop(BACKDROP_PANEL)
    bankFrame:SetBackdropColor(0.08, 0.09, 0.12, 0.94)
    bankFrame:SetBackdropBorderColor(0.85, 0.65, 0.15, 1.0)

    -- Dragging & Position Management
    bankFrame:SetScript("OnDragStart", function(self)
        if self:IsMovable() then
            self:StartMoving()
        end
    end)
    bankFrame:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        BankFrame:SavePosition()
    end)

    -- Header Bar
    local header = CreateFrame("Frame", nil, bankFrame)
    header:SetHeight(30)
    header:SetPoint("TOPLEFT", 8, -6)
    header:SetPoint("TOPRIGHT", -8, -6)
    bankFrame.Header = header

    -- Title FontString
    local title = header:CreateFontString(nil, "OVERLAY")
    title:SetFont(BFB:FetchFont(BFB.DEFAULT_HEADER_FONT_NAME), 12, "OUTLINE")
    title:SetTextColor(1.0, 0.82, 0.0, 1.0)
    title:SetText("Bleakfiber's Bank")
    title:SetPoint("LEFT", header, "LEFT", 4, 0)
    bankFrame.Title = title

    -- Close Button
    local closeBtn = CreateFrame("Button", nil, header)
    closeBtn:SetSize(18, 18)
    closeBtn:SetPoint("RIGHT", header, "RIGHT", -2, 0)
    local closeText = closeBtn:CreateFontString(nil, "OVERLAY")
    closeText:SetFont(BFB:FetchFont(BFB.DEFAULT_HEADER_FONT_NAME), 13, "OUTLINE")
    closeText:SetText("|cffff4444✕|r")
    closeText:SetPoint("CENTER")
    bankFrame.CloseText = closeText
    closeBtn:SetScript("OnClick", function()
        BankFrame:Hide()
    end)
    closeBtn:SetScript("OnEnter", function() closeText:SetText("|cffffffff✕|r") end)
    closeBtn:SetScript("OnLeave", function() closeText:SetText("|cffff4444✕|r") end)

    -- Bank Bags Drawer Toggle Button
    local bagSlotToggle = CreateFrame("Button", nil, header)
    bagSlotToggle:SetSize(18, 18)
    bagSlotToggle:SetPoint("RIGHT", closeBtn, "LEFT", -6, 0)
    local bagIcon = bagSlotToggle:CreateTexture(nil, "ARTWORK")
    bagIcon:SetAllPoints()
    bagIcon:SetTexture("Interface\\Buttons\\Button-Backpack-Up")
    bagSlotToggle:SetScript("OnClick", function()
        local db = BFB.db or {}
        db.showBankBagSlotBar = not db.showBankBagSlotBar
        BankFrame:UpdateBankBagSlotBar()
        BankFrame:UpdateLayout()
    end)
    bagSlotToggle:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_TOP")
        GameTooltip:AddLine("Bank Bags Drawer", 1, 0.82, 0)
        GameTooltip:AddLine("Click to view equipped and purchasable bank bag containers.", 1, 1, 1, true)
        GameTooltip:Show()
    end)
    bagSlotToggle:SetScript("OnLeave", function() GameTooltip:Hide() end)

    -- Deposit Reagents Button
    local depositReagentsBtn = CreateFrame("Button", nil, header)
    depositReagentsBtn:SetSize(18, 18)
    depositReagentsBtn:SetPoint("RIGHT", bagSlotToggle, "LEFT", -6, 0)
    local depIcon = depositReagentsBtn:CreateTexture(nil, "ARTWORK")
    depIcon:SetAllPoints()
    depIcon:SetTexture("Interface\\Icons\\INV_Misc_Herb_01")
    depositReagentsBtn:SetScript("OnClick", function()
        BankFrame:DepositReagents()
    end)
    depositReagentsBtn:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_TOP")
        GameTooltip:AddLine("Deposit All Trade Goods", 1, 0.82, 0)
        GameTooltip:AddLine("Transfers all crafting reagents and trade goods from your bags into free bank slots.", 1, 1, 1, true)
        GameTooltip:Show()
    end)
    depositReagentsBtn:SetScript("OnLeave", function() GameTooltip:Hide() end)

    -- Stack to Bank Button
    local stackToBankBtn = CreateFrame("Button", nil, header)
    stackToBankBtn:SetSize(18, 18)
    stackToBankBtn:SetPoint("RIGHT", depositReagentsBtn, "LEFT", -6, 0)
    local stackIcon = stackToBankBtn:CreateTexture(nil, "ARTWORK")
    stackIcon:SetAllPoints()
    stackIcon:SetTexture("Interface\\Buttons\\UI-SpellbookIcon-NextPage-Up")
    stackToBankBtn:SetScript("OnClick", function()
        BankFrame:StackToBank()
    end)
    stackToBankBtn:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_TOP")
        GameTooltip:AddLine("Stack Matching Items to Bank", 1, 0.82, 0)
        GameTooltip:AddLine("Moves items from your bags into existing matching stacks in the bank.", 1, 1, 1, true)
        GameTooltip:Show()
    end)
    stackToBankBtn:SetScript("OnLeave", function() GameTooltip:Hide() end)

    -- Bank Search EditBox
    local searchBox = CreateFrame("EditBox", "BleakfibersBankSearchBox", header, "BackdropTemplate")
    if not searchBox.SetBackdrop and BackdropTemplateMixin then
        Mixin(searchBox, BackdropTemplateMixin)
    end
    searchBox:SetHeight(18)
    searchBox:SetWidth(95)
    searchBox:SetPoint("RIGHT", stackToBankBtn, "LEFT", -8, 0)
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

    local searchPlaceholder = searchBox:CreateFontString(nil, "OVERLAY")
    searchPlaceholder:SetFont(BFB:FetchFont(BFB.DEFAULT_FONT_NAME), 9, "")
    searchPlaceholder:SetTextColor(0.5, 0.5, 0.5, 0.8)
    searchPlaceholder:SetText("Search...")
    searchPlaceholder:SetPoint("LEFT", 6, 0)
    bankFrame.SearchPlaceholder = searchPlaceholder

    local clearSearchBtn = CreateFrame("Button", nil, searchBox)
    clearSearchBtn:SetSize(14, 14)
    clearSearchBtn:SetPoint("RIGHT", searchBox, "RIGHT", -2, 0)
    local clearText = clearSearchBtn:CreateFontString(nil, "OVERLAY")
    clearText:SetFont(BFB:FetchFont(BFB.DEFAULT_FONT_NAME), 9, "OUTLINE")
    clearText:SetText("|cff888888✕|r")
    clearText:SetPoint("CENTER")
    clearSearchBtn:Hide()
    bankFrame.ClearText = clearText
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
        BankFrame:UpdateSearchFilter(text)
    end)
    searchBox:SetScript("OnEscapePressed", function(self)
        self:SetText("")
        self:ClearFocus()
    end)
    searchBox:SetScript("OnEnterPressed", function(self)
        self:ClearFocus()
    end)
    bankFrame.SearchBox = searchBox

    -- Bank Bags Drawer (Equipped Bank Bags 5..10)
    local bagSlotBar = CreateFrame("Frame", nil, bankFrame, "BackdropTemplate")
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
    bankFrame.BagSlotBar = bagSlotBar

    -- 6 Bank Bag Slots
    local numBankBags = NUM_BANKBAGSLOTS or 6
    for i = 1, numBankBags do
        local bagID = 4 + i
        local bSlot = CreateFrame("Button", "BleakfibersBankBagSlot" .. i, bagSlotBar, "BackdropTemplate")
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
            local numPurchased = GetNumBankSlots and GetNumBankSlots() or 0
            if i > numPurchased then
                GameTooltip:AddLine("Unpurchased Bank Bag Slot", 1, 0.2, 0.2)
                local cost = GetBankSlotCost and GetBankSlotCost(numPurchased) or 0
                if cost > 0 then
                    local gold = math.floor(cost / 10000)
                    local silver = math.floor((cost % 10000) / 100)
                    local copper = cost % 100
                    GameTooltip:AddLine(string.format("Cost: |cffffd100%dg|r |cffe6e6e6%ds|r |cffc87d32%dc|r", gold, silver, copper), 1, 1, 1)
                end
                GameTooltip:AddLine("Click to purchase next bank slot.", 0.8, 0.8, 0.8, true)
            else
                local invID = (ContainerIDToInventoryID and ContainerIDToInventoryID(bagID)) or (BankButtonIDToInvSlotID and BankButtonIDToInvSlotID(i, 1))
                if invID and GameTooltip.SetInventoryItem then
                    GameTooltip:SetInventoryItem("player", invID)
                else
                    GameTooltip:AddLine("Bank Bag " .. i, 1, 0.82, 0)
                end
            end
            GameTooltip:Show()
        end)
        bSlot:SetScript("OnLeave", function() GameTooltip:Hide() end)
        bSlot:SetScript("OnClick", function(self)
            local numPurchased = GetNumBankSlots and GetNumBankSlots() or 0
            if i > numPurchased then
                if StaticPopup_Show then
                    StaticPopup_Show("CONFIRM_BUY_BANK_SLOT")
                elseif PurchaseSlot then
                    PurchaseSlot()
                end
            else
                local invID = (ContainerIDToInventoryID and ContainerIDToInventoryID(bagID)) or (BankButtonIDToInvSlotID and BankButtonIDToInvSlotID(i, 1))
                if invID and PickupInventoryItem then
                    PickupInventoryItem(invID)
                end
            end
        end)

        bankBagSlotButtons[bagID] = bSlot
    end

    -- Bank Grid Container
    local gridContainer = CreateFrame("Frame", nil, bankFrame)
    gridContainer:SetPoint("TOPLEFT", bankFrame, "TOPLEFT", 10, -38)
    gridContainer:SetFrameStrata(bankFrame:GetFrameStrata() or "HIGH")
    gridContainer:SetFrameLevel(bankFrame:GetFrameLevel() + 1)
    bankFrame.GridContainer = gridContainer

    -- Footer Bar
    local footer = CreateFrame("Frame", nil, bankFrame)
    footer:SetHeight(26)
    footer:SetPoint("BOTTOMLEFT", 8, 4)
    footer:SetPoint("BOTTOMRIGHT", -8, 4)
    bankFrame.Footer = footer

    local freeSlotsText = footer:CreateFontString(nil, "OVERLAY")
    freeSlotsText:SetFont(BFB:FetchFont(BFB.DEFAULT_FONT_NAME), 10, "OUTLINE")
    freeSlotsText:SetTextColor(0.85, 0.85, 0.85, 1.0)
    freeSlotsText:SetPoint("LEFT", footer, "LEFT", 4, 0)
    bankFrame.FreeSlotsText = freeSlotsText

    -- Mover Frame Overlay
    bankMoverOverlay = CreateFrame("Frame", nil, bankFrame, "BackdropTemplate")
    if not bankMoverOverlay.SetBackdrop and BackdropTemplateMixin then
        Mixin(bankMoverOverlay, BackdropTemplateMixin)
    end
    bankMoverOverlay:SetAllPoints()
    bankMoverOverlay:SetFrameStrata("TOOLTIP")
    bankMoverOverlay:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 2,
    })
    bankMoverOverlay:SetBackdropColor(0.1, 0.1, 0.15, 0.85)
    bankMoverOverlay:SetBackdropBorderColor(0.2, 0.8, 1.0, 1.0)
    bankMoverOverlay:EnableMouse(true)
    bankMoverOverlay:RegisterForDrag("LeftButton")
    bankMoverOverlay:Hide()

    local moverLabel = bankMoverOverlay:CreateFontString(nil, "OVERLAY")
    moverLabel:SetFont(BFB:FetchFont(BFB.DEFAULT_HEADER_FONT_NAME), 12, "OUTLINE")
    moverLabel:SetTextColor(0.2, 0.8, 1.0, 1.0)
    moverLabel:SetText("Bleakfiber's Bank Mover\n|cffffffffDrag to reposition|r\n|cffaaaaaaRight-Click to Lock|r")
    moverLabel:SetPoint("CENTER")
    bankMoverOverlay.Label = moverLabel
    bankFrame.MoverOverlay = bankMoverOverlay

    bankMoverOverlay:SetScript("OnDragStart", function()
        if bankFrame:IsMovable() then
            bankFrame:StartMoving()
        end
    end)
    bankMoverOverlay:SetScript("OnDragStop", function()
        bankFrame:StopMovingOrSizing()
        BankFrame:SavePosition()
    end)
    bankMoverOverlay:SetScript("OnMouseUp", function(self, button)
        if button == "RightButton" then
            BFB:ToggleMovers(false)
        end
    end)

    self:LoadPosition()
    self:UpdateBankBagSlotBar()
    self:UpdateLayout()

    bankFrame:Hide()
    return bankFrame
end

-- Dynamically update all text typography on BankFrame
function BankFrame:UpdateFonts()
    if not bankFrame then return end
    local db = BFB.db or {}
    local font = BFB:FetchFont(db.font or BFB.DEFAULT_FONT_NAME)
    local headerFont = BFB:FetchFont(db.headerFont or BFB.DEFAULT_HEADER_FONT_NAME)
    local outline = db.fontOutline or "OUTLINE"
    if outline == "None" or outline == "NONE" then outline = "" end
    local hSize = db.headerFontSize or 12
    local cSize = db.countFontSize or 9

    if bankFrame.Title then bankFrame.Title:SetFont(headerFont, hSize, outline) end
    if bankFrame.CloseText then bankFrame.CloseText:SetFont(headerFont, hSize + 1, outline) end
    if bankFrame.SearchBox then bankFrame.SearchBox:SetFont(font, 10, "") end
    if bankFrame.SearchPlaceholder then bankFrame.SearchPlaceholder:SetFont(font, 9, "") end
    if bankFrame.ClearText then bankFrame.ClearText:SetFont(font, 9, outline) end
    if bankFrame.FreeSlotsText then bankFrame.FreeSlotsText:SetFont(font, cSize + 1, outline) end
    if bankMoverOverlay and bankMoverOverlay.Label then bankMoverOverlay.Label:SetFont(headerFont, hSize, outline) end

    for _, header in pairs(bankCategoryHeaders) do
        if header.Arrow then header.Arrow:SetFont(headerFont, math.max(8, hSize - 3), outline) end
        if header.Title then header.Title:SetFont(headerFont, math.max(8, hSize - 2), outline) end
        if header.Count then header.Count:SetFont(font, cSize, outline) end
    end
end

-- Save Bank Position
function BankFrame:SavePosition()
    if not bankFrame then return end
    local db = BFB.db or {}
    db.bankPosition = db.bankPosition or {}

    local point, _, relPoint, x, y = bankFrame:GetPoint()
    db.bankPosition.point = point or "TOPLEFT"
    db.bankPosition.relativePoint = relPoint or "TOPLEFT"
    db.bankPosition.x = x or 60
    db.bankPosition.y = y or -80
end

-- Load Bank Position
function BankFrame:LoadPosition()
    if not bankFrame then return end
    local db = BFB.db or {}
    local pos = db.bankPosition or {}
    local point = pos.point or "TOPLEFT"
    local relPoint = pos.relativePoint or "TOPLEFT"
    local x = pos.x or 60
    local y = pos.y or -80

    bankFrame:ClearAllPoints()
    bankFrame:SetPoint(point, UIParent, relPoint, x, y)
end

-- Set Mover Active
function BankFrame:SetMoverActive(active)
    if not bankFrame then return end
    if active then
        bankFrame:Show()
        if bankMoverOverlay then bankMoverOverlay:Show() end
    else
        if bankMoverOverlay then bankMoverOverlay:Hide() end
    end
end

-- Update Bank Bag Slot Drawer
function BankFrame:UpdateBankBagSlotBar()
    local db = BFB.db or {}
    if not bankFrame or not bankFrame.BagSlotBar then return end

    bankFrame.GridContainer:ClearAllPoints()
    if db.showBankBagSlotBar then
        bankFrame.BagSlotBar:Show()
        bankFrame.GridContainer:SetPoint("TOPLEFT", bankFrame, "TOPLEFT", 10, -74)
    else
        bankFrame.BagSlotBar:Hide()
        bankFrame.GridContainer:SetPoint("TOPLEFT", bankFrame, "TOPLEFT", 10, -38)
    end

    local numPurchased = GetNumBankSlots and GetNumBankSlots() or 0
    local numBankBags = NUM_BANKBAGSLOTS or 6

    for i = 1, numBankBags do
        local bagID = 4 + i
        local btn = bankBagSlotButtons[bagID]
        if btn then
            if i > numPurchased then
                btn.Icon:SetTexture("Interface\\Buttons\\UI-GroupLoot-Pass-Up")
                btn.Count:SetText("LOCKED")
                btn:SetBackdropBorderColor(0.8, 0.2, 0.2, 0.8)
            else
                local invID = (ContainerIDToInventoryID and ContainerIDToInventoryID(bagID)) or (BankButtonIDToInvSlotID and BankButtonIDToInvSlotID(i, 1))
                local itemLink = invID and GetInventoryItemLink and GetInventoryItemLink("player", invID)
                local numSlots = BFB.GetNumSlots(bagID)

                if itemLink then
                    local icon = GetInventoryItemTexture("player", invID)
                    btn.Icon:SetTexture(icon or "Interface\\Icons\\INV_Misc_Bag_08")
                    btn.Count:SetText(numSlots and tostring(numSlots) or "")
                    btn:SetBackdropBorderColor(0.5, 0.8, 0.5, 0.8)
                else
                    btn.Icon:SetTexture("Interface\\PaperDoll\\UI-PaperDoll-Slot-Bag")
                    btn.Count:SetText("")
                    btn:SetBackdropBorderColor(0.3, 0.3, 0.35, 0.6)
                end
            end
        end
    end
end

-- Update Bank Inventory Layout
function BankFrame:UpdateLayout()
    if not bankFrame then return end
    local db = BFB.db or {}
    local cols = db.bankColumns or 12
    local btnSize = db.buttonSize or 37
    local spacing = db.buttonSpacing or 4
    local isCategoryView = (db.bankViewMode == "category")
    db.collapsedBankCategories = db.collapsedBankCategories or {}

    if BFB.ItemButtons.ReleaseButtons then
        BFB.ItemButtons:ReleaseButtons(activeBankButtons)
    else
        wipe(activeBankButtons)
    end
    ReleaseBankCategoryHeaders()

    if not bankFrame.bagContainers then
        bankFrame.bagContainers = {}
    end
    local function GetBankBagContainer(bagID)
        local c = bankFrame.bagContainers[bagID]
        if not c then
            c = CreateFrame("Frame", nil, bankFrame.GridContainer)
            c:SetID(bagID)
            c:SetAllPoints(bankFrame.GridContainer)
            c:Show()
            bankFrame.bagContainers[bagID] = c
        end
        return c
    end

    local totalSlots = 0
    local freeSlots = 0
    local slotList = {}

    -- 1. Main Bank Container (Bag -1)
    local mainSlots = BFB.GetNumSlots(-1) or 0
    if mainSlots > 0 then
        totalSlots = totalSlots + mainSlots
        for slot = 1, mainSlots do
            local info = BFB.GetItemInfo(-1, slot)
            if not info or not (info.iconFileID or info.icon or info.texture) then
                freeSlots = freeSlots + 1
            end
            table.insert(slotList, { bag = -1, slot = slot })
        end
    end

    -- 2. Bank Bags (5 to 10 in Classic)
    local numBankBags = NUM_BANKBAGSLOTS or 6
    for i = 1, numBankBags do
        local bagID = 4 + i
        local bagSlots = BFB.GetNumSlots(bagID) or 0
        if bagSlots > 0 then
            totalSlots = totalSlots + bagSlots
            for slot = 1, bagSlots do
                local info = BFB.GetItemInfo(bagID, slot)
                if not info or not (info.iconFileID or info.icon or info.texture) then
                    freeSlots = freeSlots + 1
                end
                table.insert(slotList, { bag = bagID, slot = slot })
            end
        end
    end

    local searchTerm = bankFrame.SearchBox and bankFrame.SearchBox:GetText()
    local totalContentH = 0

    if not isCategoryView then
        local numItems = #slotList
        local rows = math.ceil(numItems / cols)
        if rows < 1 then rows = 1 end

        for idx, slotData in ipairs(slotList) do
            local bagContainer = GetBankBagContainer(slotData.bag)
            local btn = BFB.ItemButtons:Acquire(bagContainer)
            btn:ClearAllPoints()
            btn:SetSize(btnSize, btnSize)

            local row = math.floor((idx - 1) / cols)
            local col = (idx - 1) % cols

            local x = col * (btnSize + spacing)
            local y = -row * (btnSize + spacing)

            btn:SetPoint("TOPLEFT", bankFrame.GridContainer, "TOPLEFT", x, y)
            BFB.ItemButtons:UpdateButton(btn, slotData.bag, slotData.slot, searchTerm)
            table.insert(activeBankButtons, btn)
        end

        totalContentH = rows * btnSize + (rows - 1) * spacing
    else
        local categories = BFB.CategoryEngine and BFB.CategoryEngine:GroupSlots(slotList) or {}
        local currentY = 0

        for _, catGroup in ipairs(categories) do
            local catID = catGroup.id
            local isCollapsed = db.collapsedBankCategories[catID]
            local numItemsInCat = #catGroup.slots

            local header = AcquireBankCategoryHeader(
                bankFrame.GridContainer,
                catID,
                catGroup.name,
                numItemsInCat,
                catGroup.color,
                isCollapsed,
                function(toggledCatID)
                    db.collapsedBankCategories[toggledCatID] = not db.collapsedBankCategories[toggledCatID]
                    BankFrame:UpdateLayout()
                end
            )

            local gridW = cols * btnSize + (cols - 1) * spacing
            header:SetWidth(gridW)
            header:SetPoint("TOPLEFT", bankFrame.GridContainer, "TOPLEFT", 0, currentY)
            currentY = currentY - 24

            if not isCollapsed then
                local catRows = math.ceil(numItemsInCat / cols)
                if catRows < 1 then catRows = 1 end

                for idx, slotData in ipairs(catGroup.slots) do
                    local bagContainer = GetBankBagContainer(slotData.bag)
                    local btn = BFB.ItemButtons:Acquire(bagContainer)
                    btn:ClearAllPoints()
                    btn:SetSize(btnSize, btnSize)

                    local row = math.floor((idx - 1) / cols)
                    local col = (idx - 1) % cols

                    local x = col * (btnSize + spacing)
                    local y = currentY - (row * (btnSize + spacing))

                    btn:SetPoint("TOPLEFT", bankFrame.GridContainer, "TOPLEFT", x, y)
                    BFB.ItemButtons:UpdateButton(btn, slotData.bag, slotData.slot, searchTerm)
                    table.insert(activeBankButtons, btn)
                end

                local catBlockH = catRows * btnSize + (catRows - 1) * spacing
                currentY = currentY - catBlockH - 10
            else
                currentY = currentY - 4
            end
        end

        totalContentH = math.abs(currentY)
    end

    local gridW = cols * btnSize + (cols - 1) * spacing
    local totalW = gridW + 20
    local headerH = 34 + (db.showBankBagSlotBar and 36 or 0)
    local footerH = 30
    local totalH = totalContentH + headerH + footerH

    if bankFrame.GridContainer then
        bankFrame.GridContainer:SetSize(gridW, math.max(totalContentH, 37))
    end

    bankFrame:SetSize(math.max(totalW, 300), math.max(totalH, 140))

    if bankFrame.FreeSlotsText then
        bankFrame.FreeSlotsText:SetText(string.format("Bank Free: |cff00ff00%d|r / |cffffffff%d|r", freeSlots, totalSlots))
    end

    -- Update title with Cached indicator if not actively at a banker
    if bankFrame.Title then
        if isBankOpen then
            bankFrame.Title:SetText("Bleakfiber's Bank")
        else
            bankFrame.Title:SetText("Bleakfiber's Bank |cffffaa00[Cached]|r")
        end
    end
end

-- Deposit All Trade Goods into Bank
function BankFrame:DepositReagents()
    if not isBankOpen then
        print("|cff00c0ffBleakfiber's Bags:|r You must be at a bank to deposit items.")
        return
    end

    local transferred = 0
    for bag = 0, 4 do
        local numSlots = BFB.GetNumSlots(bag)
        for slot = 1, numSlots do
            local info = BFB.GetItemInfo(bag, slot)
            if info and info.hyperlink and not info.isLocked then
                local cat = BFB.CategoryEngine:ClassifyItem(bag, slot, info)
                if cat == "tradegoods" or cat == "consumables" then
                    if C_Container and C_Container.UseContainerItem then
                        C_Container.UseContainerItem(bag, slot)
                        transferred = transferred + 1
                    elseif UseContainerItem then
                        UseContainerItem(bag, slot)
                        transferred = transferred + 1
                    end
                end
            end
        end
    end
    if transferred > 0 then
        print(string.format("|cff00c0ffBleakfiber's Bags:|r Deposited %d trade goods into bank.", transferred))
    else
        print("|cff00c0ffBleakfiber's Bags:|r No trade goods found to deposit.")
    end
end

-- Stack Matching Items from Bags into Bank
function BankFrame:StackToBank()
    if not isBankOpen then
        print("|cff00c0ffBleakfiber's Bags:|r You must be at a bank to stack items.")
        return
    end

    local stacked = 0
    for bag = 0, 4 do
        local numSlots = BFB.GetNumSlots(bag)
        for slot = 1, numSlots do
            local info = BFB.GetItemInfo(bag, slot)
            if info and info.hyperlink and not info.isLocked then
                local itemID = info.itemID or info.hyperlink
                local _, _, _, _, _, _, _, maxStack = GetItemInfo(info.hyperlink)
                if maxStack and maxStack > 1 then
                    -- Check if bank contains this item
                    local bankTargetBag, bankTargetSlot = nil, nil
                    for b = -1, 10 do
                        if b == -1 or b >= 5 then
                            local bSlots = BFB.GetNumSlots(b)
                            for s = 1, bSlots do
                                local bInfo = BFB.GetItemInfo(b, s)
                                if bInfo and bInfo.itemID == itemID and (bInfo.stackCount or 1) < maxStack and not bInfo.isLocked then
                                    bankTargetBag = b
                                    bankTargetSlot = s
                                    break
                                end
                            end
                        end
                        if bankTargetBag then break end
                    end

                    if bankTargetBag and bankTargetSlot then
                        if C_Container and C_Container.PickupContainerItem then
                            C_Container.PickupContainerItem(bag, slot)
                            C_Container.PickupContainerItem(bankTargetBag, bankTargetSlot)
                            stacked = stacked + 1
                        elseif PickupContainerItem then
                            PickupContainerItem(bag, slot)
                            PickupContainerItem(bankTargetBag, bankTargetSlot)
                            stacked = stacked + 1
                        end
                    end
                end
            end
        end
    end
    if stacked > 0 then
        print(string.format("|cff00c0ffBleakfiber's Bags:|r Stacked %d matching item(s) to bank.", stacked))
    else
        print("|cff00c0ffBleakfiber's Bags:|r No stackable items found to transfer.")
    end
end

-- Live Search Filtering
function BankFrame:UpdateSearchFilter(term)
    if not activeBankButtons then return end
    for _, btn in ipairs(activeBankButtons) do
        if btn.bagID and btn.slotID then
            BFB.ItemButtons:UpdateButton(btn, btn.bagID, btn.slotID, term)
        end
    end
end

-- Bank Event Hooks
function BankFrame:OnBankOpened()
    isBankOpen = true
    local frame = self:Init()
    frame:Show()
    self:UpdateBankBagSlotBar()
    self:UpdateLayout()

    -- Also scan and cache bank contents
    if BFB.BankCache then
        BFB.BankCache:ScanBank()
    end

    -- Automatically open main bag frame side-by-side
    if BFB.BagFrame then
        BFB.BagFrame:Show()
    end
end

function BankFrame:OnBankClosed()
    isBankOpen = false
    if bankFrame then
        bankFrame:Hide()
    end
    if BFB.BankCache then
        BFB.BankCache:ScanBank()
    end
end

function BankFrame:Show()
    local frame = self:Init()
    frame:Show()
    self:UpdateBankBagSlotBar()
    self:UpdateLayout()
end

function BankFrame:Hide()
    if bankFrame then
        bankFrame:Hide()
    end
end

function BankFrame:Toggle()
    local frame = self:Init()
    if frame:IsShown() then
        self:Hide()
    else
        self:Show()
    end
end

function BankFrame:IsShown()
    return bankFrame and bankFrame:IsShown()
end

