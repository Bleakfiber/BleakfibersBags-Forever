local addonName, BFB = ...

-- Inherit AceAddon, AceEvent, and AceHook
LibStub("AceAddon-3.0"):NewAddon(BFB, "BleakfibersBags", "AceEvent-3.0", "AceHook-3.0")

_G["BleakfibersBagsForever"] = BFB

local function GetItemInfo(item)
    if not item then return nil end
    if C_Item and C_Item.GetItemInfo then
        return C_Item.GetItemInfo(item)
    elseif _G.GetItemInfo then
        return _G.GetItemInfo(item)
    end
    return nil
end

function BFB:GetItemQualityColor(quality)
    if not quality then return 1, 1, 1, "|cffffffff" end
    if C_Item and C_Item.GetItemQualityColor then
        local r, g, b, hex = C_Item.GetItemQualityColor(quality)
        if r then return r, g, b, hex or "|cffffffff" end
    end
    if _G.GetItemQualityColor then
        local r, g, b, hex = _G.GetItemQualityColor(quality)
        if r then return r, g, b, hex or "|cffffffff" end
    end
    if ITEM_QUALITY_COLORS and ITEM_QUALITY_COLORS[quality] then
        local qc = ITEM_QUALITY_COLORS[quality]
        return qc.r or 1, qc.g or 1, qc.b or 1, qc.hex or "|cffffffff"
    end
    return 1, 1, 1, "|cffffffff"
end

local updatePending = false
local function TriggerBagUpdate()
    if updatePending then return end
    updatePending = true
    C_Timer.After(0.05, function()
        updatePending = false
        if BFB.BagFrame and BFB.BagFrame.IsShown and BFB.BagFrame:IsShown() then
            BFB.BagFrame:UpdateLayout()
        end
    end)
end

function BFB:OnInitialize()
    -- Initialize Configuration & SavedVariables
    self:InitConfig()

    -- Initialize Bag Window
    if self.BagFrame and self.BagFrame.Init then
        self.BagFrame:Init()
    end

    -- Initialize Bank Window
    if self.BankFrame and self.BankFrame.Init then
        self.BankFrame:Init()
    end

    -- Initialize Bank Cache Tooltip Hook
    if self.BankCache and self.BankCache.InitTooltipHook then
        self.BankCache:InitTooltipHook()
    end
end

-- Safe Event Registration Wrapper (Validates against client engine)
local function SafeRegisterEvent(addon, event, handler)
    if C_EventUtils and C_EventUtils.IsEventValid then
        if not C_EventUtils.IsEventValid(event) then
            return false
        end
    end
    local ok = pcall(function()
        addon:RegisterEvent(event, handler)
    end)
    return ok
end

function BFB:OnEnable()
    -- Register Inventory & Currency Events
    SafeRegisterEvent(self, "BAG_UPDATE", "OnBagUpdate")
    SafeRegisterEvent(self, "BAG_UPDATE_DELAYED", "OnBagUpdate")
    SafeRegisterEvent(self, "ITEM_LOCK_CHANGED", "OnItemLockChanged")
    SafeRegisterEvent(self, "PLAYER_MONEY", "OnPlayerMoney")

    -- Register Bank Events (PLAYERBANKSLOTS_CHANGED handles both generic slots and bank bags)
    SafeRegisterEvent(self, "BANKFRAME_OPENED", "OnBankOpened")
    SafeRegisterEvent(self, "BANKFRAME_CLOSED", "OnBankClosed")
    SafeRegisterEvent(self, "PLAYERBANKSLOTS_CHANGED", "OnBankSlotsChanged")

    -- Register Interaction & Merchant Automation Events
    SafeRegisterEvent(self, "MERCHANT_SHOW", "OnMerchantShow")
    SafeRegisterEvent(self, "MERCHANT_CLOSED", "OnMerchantClosed")
    SafeRegisterEvent(self, "MAIL_SHOW", "OnMailShow")
    SafeRegisterEvent(self, "MAIL_CLOSED", "OnMailClosed")
    SafeRegisterEvent(self, "AUCTION_HOUSE_SHOW", "OnAuctionShow")
    SafeRegisterEvent(self, "AUCTION_HOUSE_CLOSED", "OnAuctionClosed")
    SafeRegisterEvent(self, "TRADE_SHOW", "OnTradeShow")
    SafeRegisterEvent(self, "TRADE_CLOSED", "OnTradeClosed")
    SafeRegisterEvent(self, "CHAT_MSG_LOOT", "OnChatMsgLoot")
    SafeRegisterEvent(self, "BAG_NEW_ITEMS_UPDATED", "OnBagNewItemsUpdated")
    SafeRegisterEvent(self, "PLAYER_ENTERING_WORLD", "OnPlayerEnteringWorld")

    -- Hook Default Blizzard Bag Functions
    self:HookBlizzardBagFrames()
end

-- Engine New Item Clear Utility (Ensures client engine does not keep all slots flagged as new)
function BFB:ClearNewItems()
    if C_NewItems then
        if C_NewItems.ClearAll then
            pcall(C_NewItems.ClearAll)
        elseif C_NewItems.RemoveNewItem then
            for bagID = 0, 4 do
                local numSlots = BFB.GetNumSlots and BFB.GetNumSlots(bagID) or 0
                for slotID = 1, numSlots do
                    pcall(C_NewItems.RemoveNewItem, bagID, slotID)
                end
            end
        end
    end
end

-- Event Callbacks
function BFB:OnBagNewItemsUpdated(event)
    self:ClearNewItems()
end

function BFB:OnPlayerEnteringWorld(event)
    self:ClearNewItems()
end

function BFB:OnChatMsgLoot(event, msg)
    if not msg then return end
    local itemID = msg:match("|Hitem:(%d+)")
    if itemID and self.CategoryEngine and self.CategoryEngine.MarkRecent then
        self.CategoryEngine:MarkRecent(tonumber(itemID))
        TriggerBagUpdate()
    end
end

function BFB:OnBagUpdate(event, bagID)
    TriggerBagUpdate()
end

function BFB:OnItemLockChanged(event, bagID, slotID)
    TriggerBagUpdate()
end

function BFB:OnPlayerMoney()
    if self.BagFrame and self.BagFrame.UpdateMoney then
        self.BagFrame:UpdateMoney()
    end
end

function BFB:OnMerchantShow()
    if self.db and self.db.autoOpenOnMerchant ~= false then
        if self.BagFrame then self.BagFrame:Show() end
    end

    -- Shift-key bypass check
    if IsShiftKeyDown and IsShiftKeyDown() then
        return
    end

    -- Auto-Sell Vendor Junk
    if self.db and self.db.autoSellJunk then
        local soldCount = 0
        local totalGain = 0

        for bag = 0, 4 do
            local numSlots = BFB.GetNumSlots(bag)
            for slot = 1, numSlots do
                local info = BFB.GetItemInfo(bag, slot)
                if info and info.quality == 0 and info.hyperlink and not info.isLocked then
                    local _, _, _, _, _, _, _, _, _, _, sellPrice = GetItemInfo(info.hyperlink)
                    if sellPrice and sellPrice > 0 then
                        local stackGain = sellPrice * (info.stackCount or 1)
                        if C_Container and C_Container.UseContainerItem then
                            C_Container.UseContainerItem(bag, slot)
                        elseif UseContainerItem then
                            UseContainerItem(bag, slot)
                        end
                        soldCount = soldCount + 1
                        totalGain = totalGain + stackGain
                    end
                end
            end
        end

        if soldCount > 0 and totalGain > 0 then
            local gold = math.floor(totalGain / 10000)
            local silver = math.floor((totalGain % 10000) / 100)
            local copper = totalGain % 100
            print(string.format("|cff00c0ffBleakfiber's Bags:|r Sold %d junk item(s) for |cffffd100%dg|r |cffe6e6e6%ds|r |cffc87d32%dc|r.", soldCount, gold, silver, copper))
        end
    end

    -- Auto-Repair Equipment
    if self.db and self.db.autoRepair and CanMerchantRepair and CanMerchantRepair() then
        local repairCost, canRepair = GetRepairAllCost()
        if canRepair and repairCost > 0 then
            local playerMoney = GetMoney()
            if playerMoney >= repairCost then
                RepairAllItems()
                local gold = math.floor(repairCost / 10000)
                local silver = math.floor((repairCost % 10000) / 100)
                local copper = repairCost % 100
                print(string.format("|cff00c0ffBleakfiber's Bags:|r Repaired all items for |cffffd100%dg|r |cffe6e6e6%ds|r |cffc87d32%dc|r.", gold, silver, copper))
            else
                print("|cff00c0ffBleakfiber's Bags:|r Insufficient funds for auto-repair.")
            end
        end
    end
end

function BFB:OnMerchantClosed()
    if self.db and self.db.autoCloseOnMerchant ~= false then
        if self.BagFrame then self.BagFrame:Hide() end
    end
end

function BFB:OnBankOpened()
    if self.BankFrame then
        self.BankFrame:OnBankOpened()
    end
    if self.db and self.db.autoOpenOnBank ~= false then
        if self.BagFrame then self.BagFrame:Show() end
    end
end

function BFB:OnBankClosed()
    if self.BankFrame then
        self.BankFrame:OnBankClosed()
    end
    if self.db and self.db.autoCloseOnBank ~= false then
        if self.BagFrame then self.BagFrame:Hide() end
    end
end

function BFB:OnBankSlotsChanged()
    if self.BankFrame and self.BankFrame.IsShown and self.BankFrame:IsShown() then
        if self.BankFrame.UpdateBankBagSlotBar then
            self.BankFrame:UpdateBankBagSlotBar()
        end
        self.BankFrame:UpdateLayout()
    end
    if self.BankCache then
        self.BankCache:ScanBank()
    end
end

function BFB:OnBankBagSlotsChanged()
    self:OnBankSlotsChanged()
end

function BFB:OnMailShow()
    if self.db and self.db.autoOpenOnMail ~= false then
        if self.BagFrame then self.BagFrame:Show() end
    end
end

function BFB:OnMailClosed()
    if self.db and self.db.autoCloseOnMail ~= false then
        if self.BagFrame then self.BagFrame:Hide() end
    end
end

function BFB:OnAuctionShow()
    if self.db and self.db.autoOpenOnAuction ~= false then
        if self.BagFrame then self.BagFrame:Show() end
    end
end

function BFB:OnAuctionClosed()
    if self.db and self.db.autoCloseOnAuction ~= false then
        if self.BagFrame then self.BagFrame:Hide() end
    end
end

function BFB:OnTradeShow()
    if self.db and self.db.autoOpenOnTrade ~= false then
        if self.BagFrame then self.BagFrame:Show() end
    end
end

function BFB:OnTradeClosed()
    -- Optional trade close hook
end

-- Intercept and Replace Default Blizzard Bag Frame Open/Close Triggers
function BFB:HookBlizzardBagFrames()
    local function ToggleBags()
        if BFB.BagFrame then
            BFB.BagFrame:Toggle()
        end
    end

    local function OpenBags()
        if BFB.BagFrame then
            BFB.BagFrame:Show()
        end
    end

    local function CloseBags()
        if BFB.BagFrame then
            BFB.BagFrame:Hide()
        end
    end

    -- Replace classic global functions
    if ToggleBackpack then
        self:RawHook("ToggleBackpack", ToggleBags, true)
    end
    if ToggleAllBags then
        self:RawHook("ToggleAllBags", ToggleBags, true)
    end
    if OpenAllBags then
        self:RawHook("OpenAllBags", OpenBags, true)
    end
    if CloseAllBags then
        self:RawHook("CloseAllBags", CloseBags, true)
    end
    if OpenBackpack then
        self:RawHook("OpenBackpack", OpenBags, true)
    end
    if CloseBackpack then
        self:RawHook("CloseBackpack", CloseBags, true)
    end

    -- Suppress default Blizzard ContainerFrames from popping up
    for i = 1, (NUM_CONTAINER_FRAMES or 13) do
        local frame = _G["ContainerFrame" .. i]
        if frame then
            self:HookScript(frame, "OnShow", function(selfFrame)
                selfFrame:Hide()
            end)
        end
    end

    -- Suppress default Blizzard BankFrame from popping up
    if BankFrame then
        self:HookScript(BankFrame, "OnShow", function(selfFrame)
            selfFrame:Hide()
        end)
    end
end

-- Dynamically update fonts across all active windows
function BFB:UpdateFonts()
    if self.BagFrame and self.BagFrame.UpdateFonts then
        self.BagFrame:UpdateFonts()
    end
    if self.BankFrame and self.BankFrame.UpdateFonts then
        self.BankFrame:UpdateFonts()
    end
    local db = self.db or {}
    local font = self:FetchFont(db.font or BFB.DEFAULT_FONT_NAME)
    local outline = db.fontOutline or "OUTLINE"
    if outline == "None" or outline == "NONE" then outline = "" end
    local countSize = db.countFontSize or 9

    if self.BagFrame and self.BagFrame.itemButtons then
        for _, btn in pairs(self.BagFrame.itemButtons) do
            if btn.Count then
                btn.Count:SetFont(font, countSize, outline)
            end
        end
    end
    if self.BankFrame and self.BankFrame.itemButtons then
        for _, btn in pairs(self.BankFrame.itemButtons) do
            if btn.Count then
                btn.Count:SetFont(font, countSize, outline)
            end
        end
    end
end

