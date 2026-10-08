local addonName, BFB = ...

-- Inherit AceAddon, AceEvent, and AceHook
LibStub("AceAddon-3.0"):NewAddon(BFB, "BleakfibersBags", "AceEvent-3.0", "AceHook-3.0")

_G["BleakfibersBagsForever"] = BFB

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

function BFB:OnEnable()
    -- Register Inventory & Currency Events
    self:RegisterEvent("BAG_UPDATE", "OnBagUpdate")
    if C_EventUtils and C_EventUtils.IsEventValid and C_EventUtils.IsEventValid("BAG_UPDATE_DELAYED") then
        self:RegisterEvent("BAG_UPDATE_DELAYED", "OnBagUpdate")
    end
    self:RegisterEvent("ITEM_LOCK_CHANGED", "OnItemLockChanged")
    self:RegisterEvent("PLAYER_MONEY", "OnPlayerMoney")

    -- Register Bank Events
    self:RegisterEvent("BANKFRAME_OPENED", "OnBankOpened")
    self:RegisterEvent("BANKFRAME_CLOSED", "OnBankClosed")
    self:RegisterEvent("PLAYERBANKSLOTS_CHANGED", "OnBankSlotsChanged")
    self:RegisterEvent("PLAYERBANKBAGSLOTS_CHANGED", "OnBankBagSlotsChanged")

    -- Register Interaction & Merchant Automation Events
    self:RegisterEvent("MERCHANT_SHOW", "OnMerchantShow")
    self:RegisterEvent("MERCHANT_CLOSED", "OnMerchantClosed")
    self:RegisterEvent("MAIL_SHOW", "OnMailShow")
    self:RegisterEvent("MAIL_CLOSED", "OnMailClosed")
    self:RegisterEvent("AUCTION_HOUSE_SHOW", "OnAuctionShow")
    self:RegisterEvent("AUCTION_HOUSE_CLOSED", "OnAuctionClosed")
    self:RegisterEvent("TRADE_SHOW", "OnTradeShow")
    self:RegisterEvent("TRADE_CLOSED", "OnTradeClosed")

    -- Hook Default Blizzard Bag Functions
    self:HookBlizzardBagFrames()
end

-- Event Callbacks
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
        self.BankFrame:UpdateLayout()
    end
    if self.BankCache then
        self.BankCache:ScanBank()
    end
end

function BFB:OnBankBagSlotsChanged()
    if self.BankFrame and self.BankFrame.IsShown and self.BankFrame:IsShown() then
        self.BankFrame:UpdateBankBagSlotBar()
        self.BankFrame:UpdateLayout()
    end
    if self.BankCache then
        self.BankCache:ScanBank()
    end
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

