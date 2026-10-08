local addonName, BFB = ...

BFB.addonName = addonName
BFB.version = "1.3.0"

local DB_DEFAULTS = {
    profile = {
        -- Layout & Grid
        columns = 10,
        buttonSize = 37,
        buttonSpacing = 4,
        viewMode = "grid", -- "grid" or "category"
        collapsedCategories = {},
        
        -- Bank Settings
        bankColumns = 12,
        bankViewMode = "grid", -- "grid" or "category"
        showBankBagSlotBar = false,
        collapsedBankCategories = {},
        enableBankCache = true,
        showBankTooltip = true,
        
        -- Visual Indicators
        showJunkIcon = true,
        showQualityGlow = true,
        showQuestGlow = true,
        showItemLevel = false,
        
        -- Automation & Merchant
        autoSellJunk = true,
        autoRepair = true,
        
        -- Header & Bag Bar
        showBagSlotBar = false,
        showSearchBar = true,
        
        -- Frame Positioning
        bagPosition = {
            point = "BOTTOMRIGHT",
            relativePoint = "BOTTOMRIGHT",
            x = -45,
            y = 180,
        },
        bankPosition = {
            point = "TOPLEFT",
            relativePoint = "TOPLEFT",
            x = 60,
            y = -80,
        },
        
        -- Automation & Interaction
        autoOpenOnMerchant = true,
        autoOpenOnBank = true,
        autoOpenOnMail = true,
        autoOpenOnAuction = true,
        autoOpenOnTrade = true,
        autoCloseOnMerchant = true,
        autoCloseOnBank = true,
        autoCloseOnMail = true,
        autoCloseOnAuction = true,
        
        -- Theme & Styling
        theme = {
            bgR = 0.08,
            bgG = 0.09,
            bgB = 0.12,
            bgA = 0.94,
            borderR = 0.85,
            borderG = 0.65,
            borderB = 0.15,
            borderA = 1.0,
        },
    },
}

BFB.DB_DEFAULTS = DB_DEFAULTS

-- Initialize Database via AceDB-3.0
function BFB:InitConfig()
    if self.db then return self.db end

    local AceDB = LibStub and LibStub("AceDB-3.0", true)
    if AceDB then
        self.dbObject = AceDB:New("BleakfibersBagsDB", DB_DEFAULTS, true)
        self.db = self.dbObject.profile
        
        -- Hook Profile callbacks
        self.dbObject.RegisterCallback(self, "OnProfileChanged", "OnProfileChanged")
        self.dbObject.RegisterCallback(self, "OnProfileCopied", "OnProfileChanged")
        self.dbObject.RegisterCallback(self, "OnProfileReset", "OnProfileChanged")
    else
        _G["BleakfibersBagsDB"] = _G["BleakfibersBagsDB"] or {}
        local raw = _G["BleakfibersBagsDB"]
        for k, v in pairs(DB_DEFAULTS.profile) do
            if raw[k] == nil then
                if type(v) == "table" then
                    raw[k] = CopyTable and CopyTable(v) or v
                else
                    raw[k] = v
                end
            end
        end
        self.db = raw
    end

    -- Register with Bleakfiber Master Config Suite
    self:RegisterWithMasterConfig()

    return self.db
end

function BFB:OnProfileChanged()
    if self.dbObject then
        self.db = self.dbObject.profile
    end
    if self.BagFrame and self.BagFrame.ApplySettings then
        self.BagFrame:ApplySettings()
    end
    if self.BankFrame and self.BankFrame.UpdateLayout then
        self.BankFrame:UpdateLayout()
    end
    if self.UI and self.UI.Refresh then
        self.UI:Refresh()
    end
end

-- Profile Management Helpers (Non-Destructive)
function BFB:GetActiveProfile()
    return (self.dbObject and self.dbObject.GetCurrentProfile and self.dbObject:GetCurrentProfile()) or "Default"
end

function BFB:GetProfileList()
    if self.dbObject and self.dbObject.GetProfiles then
        return self.dbObject:GetProfiles()
    end
    return { "Default" }
end

function BFB:SetProfile(profileKey)
    if not profileKey or profileKey == "" then return end
    if self.dbObject and self.dbObject.SetProfile then
        self.dbObject:SetProfile(profileKey)
    end
end

function BFB:CreateProfile(profileKey)
    if not profileKey or profileKey == "" then return end
    if self.dbObject and self.dbObject.SetProfile then
        local current = self:GetActiveProfile()
        self.dbObject:SetProfile(profileKey)
        -- NON-DESTRUCTIVE: Clone current active settings into the new profile!
        if current and current ~= profileKey and self.dbObject.CopyProfile then
            self.dbObject:CopyProfile(current)
        end
    end
end

function BFB:CopyProfile(fromKey)
    if not fromKey or fromKey == "" then return end
    if self.dbObject and self.dbObject.CopyProfile then
        self.dbObject:CopyProfile(fromKey)
    end
end

function BFB:ResetProfile()
    if self.dbObject and self.dbObject.ResetProfile then
        self.dbObject:ResetProfile()
    end
end

function BFB:DeleteProfile(profileKey)
    if not profileKey or profileKey == "Default" then return end
    if self.dbObject and self.dbObject.DeleteProfile then
        self.dbObject:DeleteProfile(profileKey)
    end
end

-- Mover Unlock/Lock State
local isMoverActive = false

function BFB:ToggleMovers(forceState)
    if forceState ~= nil then
        isMoverActive = forceState
    else
        isMoverActive = not isMoverActive
    end

    if self.BagFrame and self.BagFrame.SetMoverActive then
        self.BagFrame:SetMoverActive(isMoverActive)
    end
    if self.BankFrame and self.BankFrame.SetMoverActive then
        self.BankFrame:SetMoverActive(isMoverActive)
    end

    local statusMsg = isMoverActive and "|cff00ff00unlocked|r (Drag frame to position, right-click to lock)" or "|cffff6666locked|r."
    print(string.format("|cff00c0ffBleakfiber's Bags:|r Frames are %s", statusMsg))
    return isMoverActive
end

function BFB:IsMoversUnlocked()
    return isMoverActive
end

-- Reset Position to Default
function BFB:ResetPosition()
    if self.db and self.db.bagPosition then
        self.db.bagPosition.point = "BOTTOMRIGHT"
        self.db.bagPosition.relativePoint = "BOTTOMRIGHT"
        self.db.bagPosition.x = -45
        self.db.bagPosition.y = 180
    end
    if self.db and self.db.bankPosition then
        self.db.bankPosition.point = "TOPLEFT"
        self.db.bankPosition.relativePoint = "TOPLEFT"
        self.db.bankPosition.x = 60
        self.db.bankPosition.y = -80
    end
    if self.BagFrame and self.BagFrame.LoadPosition then
        self.BagFrame:LoadPosition()
    end
    if self.BankFrame and self.BankFrame.LoadPosition then
        self.BankFrame:LoadPosition()
    end
    print("|cff00c0ffBleakfiber's Bags:|r Bag and Bank positions have been reset to default.")
end

-- Soft Register with BleakfibersAddonConfigForever
function BFB:RegisterWithMasterConfig()
    if not (BleakfibersAddonConfigForever and BleakfibersAddonConfigForever.RegisterModule) then
        return
    end

    BleakfibersAddonConfigForever:RegisterModule("BleakfibersBags", {
        id = "BleakfibersBags",
        name = "Bags",
        sidebarName = "Bags",
        version = self.version,
        author = "Bleakfiber",
        isBleakfiber = true,
        db = self.db,
        getDB = function() return BFB.db end,
        buildUI = function(container, isMasterHub)
            if BFB.UI and BFB.UI.BuildOptions then
                BFB.UI:BuildOptions(container, isMasterHub)
            end
        end,
        refresh = function()
            if BFB.UI and BFB.UI.Refresh then
                BFB.UI:Refresh()
            end
            if BFB.BagFrame and BFB.BagFrame.UpdateLayout then
                BFB.BagFrame:UpdateLayout()
            end
            if BFB.BankFrame and BFB.BankFrame.UpdateLayout then
                BFB.BankFrame:UpdateLayout()
            end
        end,
        profiles = {
            GetCurrent = function()
                return BFB:GetActiveProfile()
            end,
            SetCurrent = function(profileKey)
                BFB:SetProfile(profileKey)
            end,
            GetList = function()
                return BFB:GetProfileList()
            end,
            Create = function(profileKey)
                BFB:CreateProfile(profileKey)
            end,
            Delete = function(profileKey)
                BFB:DeleteProfile(profileKey)
            end,
            Copy = function(fromKey, toKey)
                BFB:CopyProfile(fromKey)
            end,
            Reset = function(profileKey)
                BFB:ResetProfile()
            end,
        },
        toggleMovers = function(enable)
            return BFB:ToggleMovers(enable)
        end,
        isMoversUnlocked = function()
            return BFB:IsMoversUnlocked()
        end,
        openConfig = function()
            BFB:OpenSettings()
        end,
    })
end

function BFB:OpenSettings()
    if BleakfibersAddonConfigForever and BleakfibersAddonConfigForever.OpenToModule then
        BleakfibersAddonConfigForever:OpenToModule("BleakfibersBags")
    elseif self.UI and self.UI.ToggleStandaloneWindow then
        self.UI:ToggleStandaloneWindow()
    else
        print("|cff00c0ffBleakfiber's Bags:|r Settings UI is loading...")
    end
end

-- Slash Commands Handler
SLASH_BLEAKFIBERSBAGS1 = "/bfb"
SLASH_BLEAKFIBERSBAGS2 = "/bags"
SlashCmdList["BLEAKFIBERSBAGS"] = function(msg)
    local cmd = msg and msg:trim():lower() or ""
    if cmd == "mover" or cmd == "unlock" or cmd == "lock" then
        BFB:ToggleMovers()
    elseif cmd == "reset" then
        BFB:ResetPosition()
    elseif cmd == "sort" or cmd == "compress" then
        if BFB.Sorting then BFB.Sorting:StartSort() end
    elseif cmd == "bank" or cmd == "vault" then
        if BFB.BankFrame then BFB.BankFrame:Toggle() end
    elseif cmd == "view" or cmd == "mode" then
        local db = BFB.db or {}
        db.viewMode = (db.viewMode == "category") and "grid" or "category"
        if BFB.BagFrame and BFB.BagFrame.UpdateLayout then BFB.BagFrame:UpdateLayout() end
        print(string.format("|cff00c0ffBleakfiber's Bags:|r View mode set to |cffffd100%s|r.", db.viewMode))
    elseif cmd == "config" or cmd == "settings" or cmd == "options" then
        BFB:OpenSettings()
    else
        if BFB.BagFrame and BFB.BagFrame.Toggle then
            BFB.BagFrame:Toggle()
        else
            print("|cff00c0ffBleakfiber's Bags:|r Use |cffffd100/bfb mover|r to unlock/lock, |cffffd100/bfb sort|r to sort, |cffffd100/bfb view|r to toggle mode.")
        end
    end
end

