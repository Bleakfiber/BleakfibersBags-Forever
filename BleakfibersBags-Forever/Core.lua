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
end

function BFB:OnEnable()
    -- Register Inventory & Currency Events
    self:RegisterEvent("BAG_UPDATE", "OnBagUpdate")
    if C_EventUtils and C_EventUtils.IsEventValid and C_EventUtils.IsEventValid("BAG_UPDATE_DELAYED") then
        self:RegisterEvent("BAG_UPDATE_DELAYED", "OnBagUpdate")
    end
    self:RegisterEvent("ITEM_LOCK_CHANGED", "OnItemLockChanged")
    self:RegisterEvent("PLAYER_MONEY", "OnPlayerMoney")

    -- Register Interaction & Merchant Automation Events
    self:RegisterEvent("MERCHANT_SHOW", "OnMerchantShow")
    self:RegisterEvent("MERCHANT_CLOSED", "OnMerchantClosed")
    self:RegisterEvent("BANKFRAME_OPENED", "OnBankOpened")
    self:RegisterEvent("BANKFRAME_CLOSED", "OnBankClosed")
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
end

function BFB:OnMerchantClosed()
    if self.db and self.db.autoCloseOnMerchant ~= false then
        if self.BagFrame then self.BagFrame:Hide() end
    end
end

function BFB:OnBankOpened()
    if self.db and self.db.autoOpenOnBank ~= false then
        if self.BagFrame then self.BagFrame:Show() end
    end
end

function BFB:OnBankClosed()
    if self.db and self.db.autoCloseOnBank ~= false then
        if self.BagFrame then self.BagFrame:Hide() end
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
end
