--[[
    Bleakfiber's Bags - UI.lua
    Presentation Layer: Dark Slate & Gold Theme, Widget Factory,
    Modular Tabbed Options Panel, Responsive Reflow & Standalone Fallback Window
]]

local addonName, BFB = ...
BFB = BFB or {}

local ADDON_NAME = "BleakfibersBags"
local FULL_TITLE = "Bleakfiber's Bags"

local UI = {}
BFB.UI = UI
_G["BleakfibersBagsUI"] = UI

-- Theme Colors: Dark Slate & Gold Bevel
local COLORS = {
    bgSlate      = { 0.08, 0.10, 0.13, 0.96 }, -- Dark iron / slate main backdrop
    contentBg    = { 0.05, 0.06, 0.08, 0.94 }, -- Inset dark container
    sidebarBg    = { 0.06, 0.07, 0.09, 0.92 }, -- Sidebar container
    goldBorder   = { 0.82, 0.68, 0.28, 1.00 }, -- Bright beveled gold border (#D1AE47)
    goldMuted    = { 0.50, 0.42, 0.20, 0.85 }, -- Secondary / inset gold border
    goldText     = { 1.00, 0.82, 0.25 },       -- Bright gold text (#FFD140)
    whiteText    = { 0.90, 0.92, 0.94 },       -- Clean readable white
    dimText      = { 0.55, 0.58, 0.63 },       -- Subtext / descriptions
    tabNormal    = { 0.12, 0.14, 0.17, 0.65 },
    tabActive    = { 0.24, 0.21, 0.13, 0.95 },
    accentGreen  = { 0.20, 0.80, 0.30 },
    accentRed    = { 0.90, 0.25, 0.25 },
}

local BACKDROP_TEMPLATE = BackdropTemplateMixin and "BackdropTemplate" or nil

local WINDOW_BACKDROP = {
    bgFile = "Interface\\Buttons\\WHITE8X8",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    tile = true,
    tileSize = 16,
    edgeSize = 16,
    insets = { left = 4, right = 4, top = 4, bottom = 4 }
}

local INSET_BACKDROP = {
    bgFile = "Interface\\Buttons\\WHITE8X8",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    tile = true,
    tileSize = 12,
    edgeSize = 12,
    insets = { left = 3, right = 3, top = 3, bottom = 3 }
}

-- Registry of UI widgets for live refresh
local registeredWidgets = {}

--[[-----------------------------------------------------------------------------
    Smart Auto-Hiding Scrollbar
-------------------------------------------------------------------------------]]
local function SetupAutoScroll(scrollFrame, scrollChild)
    if not (scrollFrame and scrollChild) then return end
    local scrollBar = _G[scrollFrame:GetName() and (scrollFrame:GetName() .. "ScrollBar")]

    local function UpdateScrollState()
        local frameHeight = scrollFrame:GetHeight()
        local childHeight = scrollChild:GetHeight()
        if not frameHeight or frameHeight <= 0 then return end
        if childHeight <= frameHeight + 2 then
            if scrollBar and scrollBar:IsShown() then
                scrollBar:Hide()
            end
            scrollFrame:EnableMouseWheel(false)
            scrollFrame:SetVerticalScroll(0)
        else
            if scrollBar and not scrollBar:IsShown() then
                scrollBar:Show()
            end
            scrollFrame:EnableMouseWheel(true)
        end
    end

    scrollFrame:EnableMouseWheel(true)
    scrollFrame:SetScript("OnMouseWheel", function(self, delta)
        local frameHeight = self:GetHeight()
        local childHeight = scrollChild:GetHeight()
        if not frameHeight or childHeight <= frameHeight + 2 then return end
        local cur = self:GetVerticalScroll()
        local maxScroll = math.max(0, childHeight - frameHeight)
        local step = 32
        local newScroll = math.max(0, math.min(maxScroll, cur - (delta * step)))
        self:SetVerticalScroll(newScroll)
    end)

    scrollFrame:HookScript("OnSizeChanged", UpdateScrollState)
    scrollChild:HookScript("OnSizeChanged", UpdateScrollState)
    scrollFrame:HookScript("OnShow", UpdateScrollState)
    UpdateScrollState()
    return UpdateScrollState
end

--[[-----------------------------------------------------------------------------
    Widget Factory: Section Header & Divider
-------------------------------------------------------------------------------]]
function UI:CreateSectionHeader(parent, text, x, y)
    local header = parent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    header:SetPoint("TOPLEFT", parent, "TOPLEFT", x or 16, y or 0)
    header:SetText(text)
    header:SetTextColor(COLORS.goldText[1], COLORS.goldText[2], COLORS.goldText[3])
    return header
end

function UI:CreateDivider(parent, y, width)
    local div = parent:CreateTexture(nil, "ARTWORK")
    div:SetHeight(1)
    if width then
        div:SetWidth(width)
        div:SetPoint("TOPLEFT", parent, "TOPLEFT", 16, y)
    else
        div:SetPoint("TOPLEFT", parent, "TOPLEFT", 16, y)
        div:SetPoint("TOPRIGHT", parent, "TOPRIGHT", -16, y)
    end
    div:SetColorTexture(COLORS.goldMuted[1], COLORS.goldMuted[2], COLORS.goldMuted[3], 0.35)
    return div
end

--[[-----------------------------------------------------------------------------
    Widget Factory: Checkbox
-------------------------------------------------------------------------------]]
function UI:CreateCheckbox(parent, name, labelText, x, y, getFunc, setFunc, tooltip)
    local cb = CreateFrame("CheckButton", name, parent, "UICheckButtonTemplate")
    cb:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
    cb.text = _G[name .. "Text"]
    if cb.text then
        cb.text:SetText(labelText)
        cb.text:SetFontObject("GameFontHighlight")
        cb.text:SetWordWrap(true)
        cb.text:SetJustifyH("LEFT")
    end

    cb.getFunc = getFunc
    cb.setFunc = setFunc
    cb:SetChecked(getFunc and getFunc() or false)

    cb:SetScript("OnClick", function(self)
        if self.setFunc then
            self.setFunc(self:GetChecked())
        end
    end)

    if tooltip then
        cb:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:ClearLines()
            GameTooltip:AddLine(labelText, COLORS.goldText[1], COLORS.goldText[2], COLORS.goldText[3])
            GameTooltip:AddLine(tooltip, 1, 1, 1, true)
            GameTooltip:Show()
        end)
        cb:SetScript("OnLeave", function() GameTooltip:Hide() end)
    end

    table.insert(registeredWidgets, {
        type = "checkbox",
        frame = cb,
        update = function()
            if cb.getFunc then
                cb:SetChecked(cb.getFunc())
            end
        end,
    })

    return cb
end

--[[-----------------------------------------------------------------------------
    Widget Factory: Slider
-------------------------------------------------------------------------------]]
function UI:CreateSlider(parent, name, labelText, minVal, maxVal, step, x, y, getFunc, setFunc, formatStr, tooltip)
    formatStr = formatStr or (step < 1 and "%.1f" or "%d")
    local slider = CreateFrame("Slider", name, parent, "OptionsSliderTemplate")
    slider:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
    slider:SetMinMaxValues(minVal, maxVal)
    slider:SetValueStep(step)
    if slider.SetObeyStepNumbers then
        slider:SetObeyStepNumbers(true)
    end
    slider:SetWidth(180)

    local low = _G[name .. "Low"]
    if low then low:SetText(tostring(minVal)) end
    local high = _G[name .. "High"]
    if high then high:SetText(tostring(maxVal)) end

    slider.getFunc = getFunc
    slider.setFunc = setFunc
    slider.formatStr = formatStr
    slider.labelText = labelText

    local curVal = getFunc and getFunc() or minVal
    local titleText = _G[name .. "Text"]
    if titleText then
        titleText:SetText(labelText .. ": " .. string.format(formatStr, curVal))
    end
    slider:SetValue(curVal)

    slider:SetScript("OnValueChanged", function(self, val)
        val = math.floor(val / step + 0.5) * step
        local tt = _G[name .. "Text"]
        if tt then
            tt:SetText(self.labelText .. ": " .. string.format(self.formatStr, val))
        end
        if self.setFunc then
            self.setFunc(val)
        end
    end)

    if tooltip then
        slider:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:ClearLines()
            GameTooltip:AddLine(labelText, COLORS.goldText[1], COLORS.goldText[2], COLORS.goldText[3])
            GameTooltip:AddLine(tooltip, 1, 1, 1, true)
            GameTooltip:Show()
        end)
        slider:SetScript("OnLeave", function() GameTooltip:Hide() end)
    end

    table.insert(registeredWidgets, {
        type = "slider",
        frame = slider,
        update = function()
            if slider.getFunc then
                local v = slider.getFunc()
                slider:SetValue(v)
                local tt = _G[name .. "Text"]
                if tt then
                    tt:SetText(slider.labelText .. ": " .. string.format(slider.formatStr, v))
                end
            end
        end,
    })

    return slider
end

--[[-----------------------------------------------------------------------------
    Widget Factory: Dropdown & Font Dropdown (Custom Dark Slate & Gold Popup)
-------------------------------------------------------------------------------]]
local sharedDropdownMenu = nil
local sharedDropdownCatcher = nil

local function GetOrCreateLocalDropdownMenu()
    if sharedDropdownMenu then return sharedDropdownMenu end

    sharedDropdownCatcher = CreateFrame("Button", "BFB_DropdownCatcher", UIParent)
    sharedDropdownCatcher:SetFrameStrata("FULLSCREEN_DIALOG")
    sharedDropdownCatcher:SetFrameLevel(98)
    sharedDropdownCatcher:SetAllPoints(UIParent)
    sharedDropdownCatcher:EnableMouse(true)
    sharedDropdownCatcher:Hide()
    sharedDropdownCatcher:SetScript("OnClick", function()
        if sharedDropdownMenu then sharedDropdownMenu:Hide() end
    end)

    local menu = CreateFrame("Frame", "BFB_DropdownMenu", UIParent, BACKDROP_TEMPLATE)
    menu:SetFrameStrata("FULLSCREEN_DIALOG")
    menu:SetFrameLevel(99)
    menu:SetClampedToScreen(true)
    menu:SetBackdrop(INSET_BACKDROP)
    menu:SetBackdropColor(0.08, 0.10, 0.13, 0.98)
    menu:SetBackdropBorderColor(unpack(COLORS.goldBorder))
    menu:EnableMouse(true)
    menu:Hide()

    menu:SetScript("OnShow", function()
        sharedDropdownCatcher:Show()
    end)
    menu:SetScript("OnHide", function()
        sharedDropdownCatcher:Hide()
    end)

    local scrollFrame = CreateFrame("ScrollFrame", "BFB_DropdownScrollFrame", menu, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", menu, "TOPLEFT", 4, -4)
    scrollFrame:SetPoint("BOTTOMRIGHT", menu, "BOTTOMRIGHT", -22, 4)
    menu.scrollFrame = scrollFrame

    local scrollChild = CreateFrame("Frame", nil, scrollFrame)
    scrollChild:SetSize(150, 100)
    scrollFrame:SetScrollChild(scrollChild)
    menu.scrollChild = scrollChild

    scrollFrame:EnableMouseWheel(true)
    scrollFrame:SetScript("OnMouseWheel", function(self, delta)
        local cur = self:GetVerticalScroll()
        local maxS = math.max(0, scrollChild:GetHeight() - self:GetHeight())
        local newS = math.min(maxS, math.max(0, cur - (delta * 22)))
        self:SetVerticalScroll(newS)
    end)

    menu.buttons = {}
    sharedDropdownMenu = menu
    return menu
end

local function NormalizeDropdownItems(items)
    local list = {}
    if type(items) == "table" then
        if #items > 0 then
            for _, item in ipairs(items) do
                if type(item) == "table" then
                    local val = (item.value ~= nil) and item.value or ((item.key ~= nil) and item.key or item[1])
                    local text = item.text or item.label or item[2] or tostring(val)
                    table.insert(list, { value = val, text = text })
                else
                    table.insert(list, { value = item, text = tostring(item) })
                end
            end
        else
            for k, v in pairs(items) do
                table.insert(list, { value = k, text = tostring(v) })
            end
            table.sort(list, function(a, b) return a.text:lower() < b.text:lower() end)
        end
    end
    return list
end

function UI:GetAvailableFonts()
    local fonts = {}
    local seen = {}
    local LSM = LibStub and LibStub("LibSharedMedia-3.0", true)
    if LSM and LSM.List then
        local lsmList = LSM:List("font")
        if lsmList then
            for _, f in ipairs(lsmList) do
                if not seen[f] then
                    table.insert(fonts, { value = f, text = f })
                    seen[f] = true
                end
            end
        end
    end
    local standardFonts = {
        "Nata Sans Regular", "Nata Sans Bold", "Nata Sans Medium",
        "BleakUI Regular", "BleakUI Bold",
        "Friz Quadrata TT", "Arial Narrow", "Skurri", "Morpheus"
    }
    for _, f in ipairs(standardFonts) do
        if not seen[f] then
            table.insert(fonts, { value = f, text = f })
            seen[f] = true
        end
    end
    table.sort(fonts, function(a, b) return a.text:lower() < b.text:lower() end)
    return fonts
end

function UI:CreateDropdown(parent, name, labelText, items, x, y, width, getFunc, setFunc, tooltip, isFont)
    width = width or 160
    local container = CreateFrame("Frame", name .. "Container", parent)
    container:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
    container:SetSize(width, 42)

    local label = container:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    label:SetPoint("TOPLEFT", container, "TOPLEFT", 0, 0)
    label:SetText(labelText)
    label:SetTextColor(COLORS.goldText[1], COLORS.goldText[2], COLORS.goldText[3])
    container.label = label

    local btn = CreateFrame("Button", name, container, BACKDROP_TEMPLATE)
    btn:SetPoint("TOPLEFT", label, "BOTTOMLEFT", 0, -3)
    btn:SetSize(width, 22)
    btn:SetBackdrop(INSET_BACKDROP)
    btn:SetBackdropColor(unpack(COLORS.tabNormal))
    btn:SetBackdropBorderColor(unpack(COLORS.goldMuted))
    container.button = btn

    local btnText = btn:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    btnText:SetPoint("LEFT", btn, "LEFT", 8, 0)
    btnText:SetPoint("RIGHT", btn, "RIGHT", -20, 0)
    btnText:SetJustifyH("LEFT")
    btnText:SetWordWrap(false)
    btn.text = btnText

    local arrow = btn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    arrow:SetPoint("RIGHT", btn, "RIGHT", -6, 0)
    arrow:SetText("|cFFFFD100v|r")

    local function GetItemsList()
        if type(items) == "function" then
            return NormalizeDropdownItems(items())
        end
        return NormalizeDropdownItems(items)
    end

    local function GetItemText(val)
        local curItems = GetItemsList()
        for _, itm in ipairs(curItems) do
            if itm.value == val then
                return itm.text
            end
        end
        return tostring(val or "")
    end

    local function UpdateButtonText()
        local curVal = getFunc and getFunc()
        btnText:SetText(GetItemText(curVal))
        if isFont then
            local fontPath = BFB:FetchFont(curVal)
            if fontPath then
                pcall(function() btnText:SetFont(fontPath, 11, "") end)
            end
        end
    end
    UpdateButtonText()

    btn:SetScript("OnEnter", function(self)
        self:SetBackdropColor(0.20, 0.22, 0.28, 0.95)
        self:SetBackdropBorderColor(unpack(COLORS.goldBorder))
        if tooltip then
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:ClearLines()
            GameTooltip:AddLine(labelText, COLORS.goldText[1], COLORS.goldText[2], COLORS.goldText[3])
            GameTooltip:AddLine(tooltip, 1, 1, 1, true)
            GameTooltip:Show()
        end
    end)
    btn:SetScript("OnLeave", function(self)
        self:SetBackdropColor(unpack(COLORS.tabNormal))
        self:SetBackdropBorderColor(unpack(COLORS.goldMuted))
        if tooltip then GameTooltip:Hide() end
    end)

    btn:SetScript("OnClick", function(self)
        PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON or 856)
        local menu = GetOrCreateLocalDropdownMenu()
        if menu:IsShown() and menu.currentButton == self then
            menu:Hide()
            return
        end

        local curItems = GetItemsList()
        local curVal = getFunc and getFunc()
        menu.currentButton = self

        for _, b in ipairs(menu.buttons) do b:Hide() end

        local btnHeight = 22
        local maxVisible = 8
        local visibleCount = math.min(#curItems, maxVisible)
        local menuWidth = math.max(width, 160)
        local totalContentHeight = #curItems * btnHeight

        local hasScroll = (#curItems > maxVisible)
        menu.scrollChild:SetSize(menuWidth - (hasScroll and 28 or 10), totalContentHeight)

        local scrollBar = _G["BFB_DropdownScrollFrameScrollBar"]
        if scrollBar then
            if hasScroll then
                scrollBar:Show()
                menu.scrollFrame:SetPoint("BOTTOMRIGHT", menu, "BOTTOMRIGHT", -22, 4)
            else
                scrollBar:Hide()
                menu.scrollFrame:SetPoint("BOTTOMRIGHT", menu, "BOTTOMRIGHT", -4, 4)
            end
        end

        local selectedIndex = 1

        for i, itm in ipairs(curItems) do
            local b = menu.buttons[i]
            if not b then
                b = CreateFrame("Button", nil, menu.scrollChild, BACKDROP_TEMPLATE)
                b:SetHeight(btnHeight)
                b:SetBackdrop(INSET_BACKDROP)

                b.text = b:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
                b.text:SetPoint("LEFT", b, "LEFT", 8, 0)
                b.text:SetPoint("RIGHT", b, "RIGHT", -8, 0)
                b.text:SetJustifyH("LEFT")

                b:SetScript("OnEnter", function(s)
                    s:SetBackdropColor(0.20, 0.22, 0.28, 0.95)
                    s:SetBackdropBorderColor(unpack(COLORS.goldBorder))
                end)
                b:SetScript("OnLeave", function(s)
                    if s.isActive then
                        s:SetBackdropColor(0.22, 0.19, 0.12, 0.95)
                        s:SetBackdropBorderColor(unpack(COLORS.goldBorder))
                    else
                        s:SetBackdropColor(0.10, 0.12, 0.15, 0.50)
                        s:SetBackdropBorderColor(unpack(COLORS.goldMuted))
                    end
                end)
                menu.buttons[i] = b
            end

            b:ClearAllPoints()
            b:SetPoint("TOPLEFT", menu.scrollChild, "TOPLEFT", 2, -((i - 1) * btnHeight))
            b:SetPoint("RIGHT", menu.scrollChild, "RIGHT", -2, 0)

            local isActive = (itm.value == curVal)
            b.isActive = isActive
            if isActive then
                selectedIndex = i
                b.text:SetText("|cFFFFD100* |r" .. itm.text)
                b:SetBackdropColor(0.22, 0.19, 0.12, 0.95)
                b:SetBackdropBorderColor(unpack(COLORS.goldBorder))
            else
                b.text:SetText("   " .. itm.text)
                b:SetBackdropColor(0.10, 0.12, 0.15, 0.50)
                b:SetBackdropBorderColor(unpack(COLORS.goldMuted))
            end

            if isFont then
                local fPath = BFB:FetchFont(itm.value)
                if fPath then
                    pcall(function() b.text:SetFont(fPath, 11, "") end)
                end
            else
                b.text:SetFontObject("GameFontHighlightSmall")
            end

            local chosenValue = itm.value
            b:SetScript("OnClick", function()
                PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON or 856)
                if setFunc then
                    setFunc(chosenValue)
                end
                UpdateButtonText()
                menu:Hide()
            end)
            b:Show()
        end

        local menuHeight = (visibleCount * btnHeight) + 8
        menu:SetSize(menuWidth, menuHeight)

        local screenHeight = UIParent:GetHeight() or 768
        local btnBottom = self:GetBottom() or (screenHeight / 2)
        menu:ClearAllPoints()
        if btnBottom < (menuHeight + 20) then
            menu:SetPoint("BOTTOMLEFT", self, "TOPLEFT", 0, 2)
        else
            menu:SetPoint("TOPLEFT", self, "BOTTOMLEFT", 0, -2)
        end

        menu:Show()
        menu:Raise()

        if hasScroll then
            local scrollPos = math.max(0, math.min(totalContentHeight - (visibleCount * btnHeight), (selectedIndex - 1) * btnHeight))
            menu.scrollFrame:SetVerticalScroll(scrollPos)
        else
            menu.scrollFrame:SetVerticalScroll(0)
        end
    end)

    container.Sync = UpdateButtonText
    container.SetValue = function(self, val)
        if setFunc then setFunc(val) end
        UpdateButtonText()
    end
    container.GetValue = function() return getFunc and getFunc() end

    table.insert(registeredWidgets, {
        type = "dropdown",
        frame = container,
        update = UpdateButtonText,
    })

    return container
end

function UI:CreateFontDropdown(parent, name, labelText, x, y, width, getFunc, setFunc, tooltip)
    return self:CreateDropdown(parent, name, labelText, function() return self:GetAvailableFonts() end, x, y, width, getFunc, setFunc, tooltip, true)
end

-- Backward compatibility alias
function UI:CreateCycleButton(parent, name, labelText, options, x, y, width, getFunc, setFunc, tooltip)
    return self:CreateDropdown(parent, name, labelText, options, x, y, width, getFunc, setFunc, tooltip)
end

--[[-----------------------------------------------------------------------------
    Widget Factory: Action Button
-------------------------------------------------------------------------------]]
function UI:CreateButton(parent, name, text, x, y, width, height, onClick)
    local btn = CreateFrame("Button", name, parent, BACKDROP_TEMPLATE)
    btn:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
    btn:SetSize(width or 120, height or 24)
    btn:SetBackdrop(INSET_BACKDROP)
    btn:SetBackdropColor(unpack(COLORS.tabNormal))
    btn:SetBackdropBorderColor(unpack(COLORS.goldMuted))

    local label = btn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    label:SetPoint("CENTER", btn, "CENTER", 0, 0)
    label:SetText(text)
    btn.label = label

    btn:SetScript("OnEnter", function(self)
        self:SetBackdropColor(0.20, 0.22, 0.28, 0.95)
        self:SetBackdropBorderColor(unpack(COLORS.goldBorder))
        label:SetTextColor(COLORS.goldText[1], COLORS.goldText[2], COLORS.goldText[3])
    end)

    btn:SetScript("OnLeave", function(self)
        self:SetBackdropColor(unpack(COLORS.tabNormal))
        self:SetBackdropBorderColor(unpack(COLORS.goldMuted))
        label:SetTextColor(COLORS.whiteText[1], COLORS.whiteText[2], COLORS.whiteText[3])
    end)

    if onClick then
        btn:SetScript("OnClick", onClick)
    end

    return btn
end

--[[-----------------------------------------------------------------------------
    Widget Factory: EditBox
-------------------------------------------------------------------------------]]
function UI:CreateEditBox(parent, name, labelText, x, y, width, getFunc, setFunc)
    width = width or 200
    local label = parent:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    label:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
    label:SetText(labelText)
    label:SetTextColor(COLORS.goldText[1], COLORS.goldText[2], COLORS.goldText[3])

    local eb = CreateFrame("EditBox", name, parent, BACKDROP_TEMPLATE)
    eb:SetPoint("TOPLEFT", label, "BOTTOMLEFT", 0, -4)
    eb:SetSize(width, 22)
    eb:SetAutoFocus(false)
    eb:SetFontObject("ChatFontNormal")
    eb:SetBackdrop(INSET_BACKDROP)
    eb:SetBackdropColor(unpack(COLORS.contentBg))
    eb:SetBackdropBorderColor(unpack(COLORS.goldMuted))
    eb:SetTextInsets(6, 6, 0, 0)

    local cur = getFunc and getFunc() or ""
    eb:SetText(cur)

    eb:SetScript("OnEnterPressed", function(self)
        self:ClearFocus()
        if setFunc then setFunc(self:GetText()) end
    end)
    eb:SetScript("OnEditFocusLost", function(self)
        if setFunc then setFunc(self:GetText()) end
    end)
    eb:SetScript("OnEscapePressed", function(self)
        self:ClearFocus()
        self:SetText(getFunc and getFunc() or "")
    end)

    table.insert(registeredWidgets, {
        type = "editbox",
        frame = eb,
        update = function()
            local v = getFunc and getFunc() or ""
            eb:SetText(v)
        end,
    })

    return eb
end

--[[-----------------------------------------------------------------------------
    Options Panel Layout (Tabbed & Responsive Reflow)
-------------------------------------------------------------------------------]]
function UI:BuildOptions(parentContainer, isMasterHub)
    isMasterHub = isMasterHub or (parentContainer and parentContainer.isMasterHub) or false

    local db = BFB.db or (BFB.InitConfig and BFB:InitConfig()) or {}
    registeredWidgets = {}

    -- Subtitle / description
    local subtext = parentContainer:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    subtext:SetText("Configure bag grids, categorized inventory, bank storage, merchant automation, and profiles.")
    subtext:SetTextColor(COLORS.dimText[1], COLORS.dimText[2], COLORS.dimText[3])

    local btnMoversStandalone
    if not isMasterHub then
        -- Standalone mode: Render full header title and local Mover toggle button
        local header = parentContainer:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
        header:SetPoint("TOPLEFT", parentContainer, "TOPLEFT", 16, -14)
        header:SetText(FULL_TITLE)
        header:SetTextColor(COLORS.goldText[1], COLORS.goldText[2], COLORS.goldText[3])

        btnMoversStandalone = self:CreateButton(parentContainer, "BFB_HeaderMovers", "Toggle Movers", 0, 0, 110, 22, function()
            BFB:ToggleMovers()
        end)
        btnMoversStandalone:SetPoint("TOPRIGHT", parentContainer, "TOPRIGHT", -16, -12)

        subtext:SetPoint("TOPLEFT", header, "BOTTOMLEFT", 0, -4)
    else
        -- Master Hub mode: Omit local header and mover buttons (handled by Master Hub)
        subtext:SetPoint("TOPLEFT", parentContainer, "TOPLEFT", 16, -12)
    end

    -- Sub-Tab Navigation Bar
    local tabsContainer = CreateFrame("Frame", nil, parentContainer)
    tabsContainer:SetHeight(28)
    tabsContainer:SetPoint("TOPLEFT", subtext, "BOTTOMLEFT", 0, -8)
    tabsContainer:SetPoint("RIGHT", parentContainer, "RIGHT", -16, 0)

    -- Inset Content Pane for Active Tab
    local tabContent = CreateFrame("Frame", nil, parentContainer, BACKDROP_TEMPLATE)
    tabContent:SetPoint("TOPLEFT", tabsContainer, "BOTTOMLEFT", 0, -6)
    tabContent:SetPoint("BOTTOMRIGHT", parentContainer, "BOTTOMRIGHT", -16, 12)
    tabContent:SetBackdrop(INSET_BACKDROP)
    tabContent:SetBackdropColor(unpack(COLORS.contentBg))
    tabContent:SetBackdropBorderColor(unpack(COLORS.goldMuted))

    -- ScrollFrame for Tab Content
    local scrollFrame = CreateFrame("ScrollFrame", "BleakBagsOptionsScrollFrame", tabContent, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", tabContent, "TOPLEFT", 8, -8)
    scrollFrame:SetPoint("BOTTOMRIGHT", tabContent, "BOTTOMRIGHT", -26, 8)

    local pWidth = parentContainer:GetWidth()
    local contentWidth = (pWidth and pWidth > 150) and (pWidth - 48) or 540
    local scrollChild = CreateFrame("Frame", nil, scrollFrame)
    scrollChild:SetSize(contentWidth, 650)
    scrollFrame:SetScrollChild(scrollChild)

    local updateScroll = SetupAutoScroll(scrollFrame, scrollChild)

    -- Tab definitions
    local tabs = {
        { id = "general",    title = "General" },
        { id = "display",    title = "Display" },
        { id = "bank",       title = "Bank & Vault" },
        { id = "automation", title = "Automation" },
        { id = "profiles",   title = "Profiles" },
    }

    local tabButtons = {}
    local tabPanes = {}
    local activeTab = "general"

    --[[-------------------------------------------------------------------------
        Tab 1: General & Layout
    ---------------------------------------------------------------------------]]
    local pGeneral = CreateFrame("Frame", nil, scrollChild)
    pGeneral:SetAllPoints(scrollChild)
    tabPanes["general"] = pGeneral

    local hBagLayout = self:CreateSectionHeader(pGeneral, "Bag Window Layout", 16, 0)
    
    local slBagCols = self:CreateSlider(pGeneral, "BFB_SlBagCols", "Columns", 6, 20, 1, 16, 0,
        function() return db.columns or 10 end,
        function(v)
            db.columns = v
            if BFB.BagFrame and BFB.BagFrame.UpdateLayout then BFB.BagFrame:UpdateLayout() end
        end,
        "%d",
        "Number of item slot columns in the main bag window."
    )

    local slBtnSize = self:CreateSlider(pGeneral, "BFB_SlBtnSize", "Button Size", 24, 52, 1, 16, 0,
        function() return db.buttonSize or 37 end,
        function(v)
            db.buttonSize = v
            if BFB.BagFrame and BFB.BagFrame.UpdateLayout then BFB.BagFrame:UpdateLayout() end
        end,
        "%d px",
        "Width and height of individual item slots."
    )

    local slBtnSpacing = self:CreateSlider(pGeneral, "BFB_SlBtnSpacing", "Button Spacing", 1, 10, 1, 16, 0,
        function() return db.buttonSpacing or 4 end,
        function(v)
            db.buttonSpacing = v
            if BFB.BagFrame and BFB.BagFrame.UpdateLayout then BFB.BagFrame:UpdateLayout() end
        end,
        "%d px",
        "Padding space between adjacent item slots."
    )

    local ddViewMode = self:CreateDropdown(pGeneral, "BFB_DdViewMode", "Bag Display Mode", {
        { value = "grid", text = "Classic Grid" },
        { value = "category", text = "Categorized" },
    }, 16, 0, 180,
        function() return db.viewMode or "grid" end,
        function(v)
            db.viewMode = v
            if BFB.BagFrame and BFB.BagFrame.UpdateLayout then BFB.BagFrame:UpdateLayout() end
        end,
        "Switch between standard flat grid layout and smart categorized sections."
    )

    local hTypography = self:CreateSectionHeader(pGeneral, "Typography & Fonts", 16, 0)

    local ddFont = self:CreateFontDropdown(pGeneral, "BFB_DdFont", "Body & Text Font", 16, 0, 180,
        function() return db.font or BFB.DEFAULT_FONT_NAME end,
        function(v)
            db.font = v
            BFB:UpdateFonts()
        end,
        "Select the typography used for slot stack counts, search, and footer info."
    )

    local ddHeaderFont = self:CreateFontDropdown(pGeneral, "BFB_DdHeaderFont", "Header Font", 16, 0, 180,
        function() return db.headerFont or BFB.DEFAULT_HEADER_FONT_NAME end,
        function(v)
            db.headerFont = v
            BFB:UpdateFonts()
        end,
        "Select the typography used for frame titles and category headers."
    )

    local ddOutline = self:CreateDropdown(pGeneral, "BFB_DdOutline", "Font Outline", {
        { value = "OUTLINE", text = "Outline" },
        { value = "THICKOUTLINE", text = "Thick Outline" },
        { value = "None", text = "None" },
    }, 16, 0, 180,
        function() return db.fontOutline or "OUTLINE" end,
        function(v)
            db.fontOutline = v
            BFB:UpdateFonts()
        end,
        "Outline thickness applied to text elements."
    )

    local slHeaderSize = self:CreateSlider(pGeneral, "BFB_SlHeaderSize", "Header Font Size", 8, 20, 1, 16, 0,
        function() return db.headerFontSize or 12 end,
        function(v)
            db.headerFontSize = v
            BFB:UpdateFonts()
        end,
        "%d pt",
        "Font size for window title and category headers."
    )

    local slCountSize = self:CreateSlider(pGeneral, "BFB_SlCountSize", "Stack & Detail Font Size", 7, 16, 1, 16, 0,
        function() return db.countFontSize or 9 end,
        function(v)
            db.countFontSize = v
            BFB:UpdateFonts()
        end,
        "%d pt",
        "Font size for slot stack counts and footer details."
    )

    local hAutoOpen = self:CreateSectionHeader(pGeneral, "Automatic Bag Interaction", 16, 0)

    local cbOpenMerchant = self:CreateCheckbox(pGeneral, "BFB_CbOpenMerchant", "Open at Merchant Vendors", 16, 0,
        function() return db.autoOpenOnMerchant ~= false end,
        function(v) db.autoOpenOnMerchant = v end,
        "Automatically open bags when speaking with a merchant."
    )
    local cbOpenBank = self:CreateCheckbox(pGeneral, "BFB_CbOpenBank", "Open at Bank", 16, 0,
        function() return db.autoOpenOnBank ~= false end,
        function(v) db.autoOpenOnBank = v end,
        "Automatically open bags when visiting the bank."
    )
    local cbOpenMail = self:CreateCheckbox(pGeneral, "BFB_CbOpenMail", "Open at Mailbox", 16, 0,
        function() return db.autoOpenOnMail ~= false end,
        function(v) db.autoOpenOnMail = v end,
        "Automatically open bags when checking mail."
    )
    local cbOpenAuction = self:CreateCheckbox(pGeneral, "BFB_CbOpenAuction", "Open at Auction House", 16, 0,
        function() return db.autoOpenOnAuction ~= false end,
        function(v) db.autoOpenOnAuction = v end,
        "Automatically open bags when opening the Auction House."
    )
    local cbOpenTrade = self:CreateCheckbox(pGeneral, "BFB_CbOpenTrade", "Open on Trade Window", 16, 0,
        function() return db.autoOpenOnTrade ~= false end,
        function(v) db.autoOpenOnTrade = v end,
        "Automatically open bags when initiating a trade."
    )

    local cbCloseMerchant = self:CreateCheckbox(pGeneral, "BFB_CbCloseMerchant", "Close when Leaving Merchant", 16, 0,
        function() return db.autoCloseOnMerchant ~= false end,
        function(v) db.autoCloseOnMerchant = v end,
        "Automatically close bags when walking away from a merchant."
    )
    local cbCloseBank = self:CreateCheckbox(pGeneral, "BFB_CbCloseBank", "Close when Leaving Bank", 16, 0,
        function() return db.autoCloseOnBank ~= false end,
        function(v) db.autoCloseOnBank = v end,
        "Automatically close bags when closing the bank."
    )
    local cbCloseMail = self:CreateCheckbox(pGeneral, "BFB_CbCloseMail", "Close when Leaving Mailbox", 16, 0,
        function() return db.autoCloseOnMail ~= false end,
        function(v) db.autoCloseOnMail = v end,
        "Automatically close bags when closing the mailbox."
    )
    local cbCloseAuction = self:CreateCheckbox(pGeneral, "BFB_CbCloseAuction", "Close when Leaving Auction House", 16, 0,
        function() return db.autoCloseOnAuction ~= false end,
        function(v) db.autoCloseOnAuction = v end,
        "Automatically close bags when closing the Auction House."
    )

    -- General Tab Reflow Layout
    local function LayoutGeneral(w)
        local isWide = (w >= 470)
        local colWidth = isWide and math.floor((w - 48) / 2) or (w - 32)
        local col1X = 16
        local col2X = isWide and (col1X + colWidth + 16) or 16

        local y = -12
        hBagLayout:ClearAllPoints()
        hBagLayout:SetPoint("TOPLEFT", pGeneral, "TOPLEFT", col1X, y)
        y = y - 28

        if isWide then
            slBagCols:ClearAllPoints()
            slBagCols:SetPoint("TOPLEFT", pGeneral, "TOPLEFT", col1X, y)
            slBtnSize:ClearAllPoints()
            slBtnSize:SetPoint("TOPLEFT", pGeneral, "TOPLEFT", col2X, y)
            y = y - 48

            slBtnSpacing:ClearAllPoints()
            slBtnSpacing:SetPoint("TOPLEFT", pGeneral, "TOPLEFT", col1X, y)
            ddViewMode:ClearAllPoints()
            ddViewMode:SetPoint("TOPLEFT", pGeneral, "TOPLEFT", col2X, y + 6)
            y = y - 56
        else
            slBagCols:ClearAllPoints()
            slBagCols:SetPoint("TOPLEFT", pGeneral, "TOPLEFT", col1X, y)
            y = y - 48
            slBtnSize:ClearAllPoints()
            slBtnSize:SetPoint("TOPLEFT", pGeneral, "TOPLEFT", col1X, y)
            y = y - 48
            slBtnSpacing:ClearAllPoints()
            slBtnSpacing:SetPoint("TOPLEFT", pGeneral, "TOPLEFT", col1X, y)
            y = y - 48
            ddViewMode:ClearAllPoints()
            ddViewMode:SetPoint("TOPLEFT", pGeneral, "TOPLEFT", col1X, y)
            y = y - 52
        end

        hTypography:ClearAllPoints()
        hTypography:SetPoint("TOPLEFT", pGeneral, "TOPLEFT", col1X, y)
        y = y - 28

        if isWide then
            ddFont:ClearAllPoints()
            ddFont:SetPoint("TOPLEFT", pGeneral, "TOPLEFT", col1X, y)
            ddHeaderFont:ClearAllPoints()
            ddHeaderFont:SetPoint("TOPLEFT", pGeneral, "TOPLEFT", col2X, y)
            y = y - 48

            ddOutline:ClearAllPoints()
            ddOutline:SetPoint("TOPLEFT", pGeneral, "TOPLEFT", col1X, y)
            slHeaderSize:ClearAllPoints()
            slHeaderSize:SetPoint("TOPLEFT", pGeneral, "TOPLEFT", col2X, y - 6)
            y = y - 48

            slCountSize:ClearAllPoints()
            slCountSize:SetPoint("TOPLEFT", pGeneral, "TOPLEFT", col1X, y)
            y = y - 56
        else
            ddFont:ClearAllPoints()
            ddFont:SetPoint("TOPLEFT", pGeneral, "TOPLEFT", col1X, y)
            y = y - 48
            ddHeaderFont:ClearAllPoints()
            ddHeaderFont:SetPoint("TOPLEFT", pGeneral, "TOPLEFT", col1X, y)
            y = y - 48
            ddOutline:ClearAllPoints()
            ddOutline:SetPoint("TOPLEFT", pGeneral, "TOPLEFT", col1X, y)
            y = y - 48
            slHeaderSize:ClearAllPoints()
            slHeaderSize:SetPoint("TOPLEFT", pGeneral, "TOPLEFT", col1X, y)
            y = y - 48
            slCountSize:ClearAllPoints()
            slCountSize:SetPoint("TOPLEFT", pGeneral, "TOPLEFT", col1X, y)
            y = y - 52
        end

        hAutoOpen:ClearAllPoints()
        hAutoOpen:SetPoint("TOPLEFT", pGeneral, "TOPLEFT", col1X, y)
        y = y - 26

        if isWide then
            local y1 = y
            local openList = { cbOpenMerchant, cbOpenBank, cbOpenMail, cbOpenAuction, cbOpenTrade }
            for _, cb in ipairs(openList) do
                cb:ClearAllPoints()
                cb:SetPoint("TOPLEFT", pGeneral, "TOPLEFT", col1X, y1)
                if cb.text then cb.text:SetWidth(colWidth - 32) end
                y1 = y1 - 28
            end

            local y2 = y
            local closeList = { cbCloseMerchant, cbCloseBank, cbCloseMail, cbCloseAuction }
            for _, cb in ipairs(closeList) do
                cb:ClearAllPoints()
                cb:SetPoint("TOPLEFT", pGeneral, "TOPLEFT", col2X, y2)
                if cb.text then cb.text:SetWidth(colWidth - 32) end
                y2 = y2 - 28
            end
            y = math.min(y1, y2)
        else
            local allList = { cbOpenMerchant, cbOpenBank, cbOpenMail, cbOpenAuction, cbOpenTrade, cbCloseMerchant, cbCloseBank, cbCloseMail, cbCloseAuction }
            for _, cb in ipairs(allList) do
                cb:ClearAllPoints()
                cb:SetPoint("TOPLEFT", pGeneral, "TOPLEFT", col1X, y)
                if cb.text then cb.text:SetWidth(colWidth - 32) end
                y = y - 28
            end
        end

        pGeneral.contentHeight = math.abs(y) + 24
    end

    --[[-------------------------------------------------------------------------
        Tab 2: Display & Overlays
    ---------------------------------------------------------------------------]]
    local pDisplay = CreateFrame("Frame", nil, scrollChild)
    pDisplay:SetAllPoints(scrollChild)
    tabPanes["display"] = pDisplay

    local hOverlays = self:CreateSectionHeader(pDisplay, "Item Slot Overlays & Usability", 16, 0)

    local cbQualityGlow = self:CreateCheckbox(pDisplay, "BFB_CbQualityGlow", "Item Quality Border Glow", 16, 0,
        function() return db.showQualityGlow ~= false end,
        function(v)
            db.showQualityGlow = v
            if BFB.BagFrame and BFB.BagFrame.UpdateSlots then BFB.BagFrame:UpdateSlots() end
            if BFB.BankFrame and BFB.BankFrame.UpdateSlots then BFB.BankFrame:UpdateSlots() end
        end,
        "Colorize slot borders matching item rarity (Common, Uncommon, Rare, Epic, Legendary)."
    )

    local cbJunkIcon = self:CreateCheckbox(pDisplay, "BFB_CbJunkIcon", "Vendor Junk Coin Indicator", 16, 0,
        function() return db.showJunkIcon ~= false end,
        function(v)
            db.showJunkIcon = v
            if BFB.BagFrame and BFB.BagFrame.UpdateSlots then BFB.BagFrame:UpdateSlots() end
            if BFB.BankFrame and BFB.BankFrame.UpdateSlots then BFB.BankFrame:UpdateSlots() end
        end,
        "Displays a small gold coin icon in the corner of poor/grey items for quick vendoring recognition."
    )

    local cbQuestGlow = self:CreateCheckbox(pDisplay, "BFB_CbQuestGlow", "Quest Item Golden Border", 16, 0,
        function() return db.showQuestGlow ~= false end,
        function(v)
            db.showQuestGlow = v
            if BFB.BagFrame and BFB.BagFrame.UpdateSlots then BFB.BagFrame:UpdateSlots() end
            if BFB.BankFrame and BFB.BankFrame.UpdateSlots then BFB.BankFrame:UpdateSlots() end
        end,
        "Highlights quest starter and quest objective items with a distinctive golden border."
    )

    local cbItemLevel = self:CreateCheckbox(pDisplay, "BFB_CbItemLevel", "Show Equipment Item Level", 16, 0,
        function() return db.showItemLevel end,
        function(v)
            db.showItemLevel = v
            if BFB.BagFrame and BFB.BagFrame.UpdateSlots then BFB.BagFrame:UpdateSlots() end
            if BFB.BankFrame and BFB.BankFrame.UpdateSlots then BFB.BankFrame:UpdateSlots() end
        end,
        "Displays the item level text overlay on equippable armor and weapons."
    )

    local cbTintUnusable = self:CreateCheckbox(pDisplay, "BFB_CbTintUnusable", "Red Tint Unusable Equipment", 16, 0,
        function() return db.tintUnusable ~= false end,
        function(v)
            db.tintUnusable = v
            if BFB.BagFrame and BFB.BagFrame.UpdateSlots then BFB.BagFrame:UpdateSlots() end
            if BFB.BankFrame and BFB.BankFrame.UpdateSlots then BFB.BankFrame:UpdateSlots() end
        end,
        "Applies a subtle red tint to armor and weapons your character cannot equip due to class, level, or proficiency restrictions."
    )

    local cbSpecialtyBags = self:CreateCheckbox(pDisplay, "BFB_CbSpecialtyBags", "Highlight Specialty Container Slots", 16, 0,
        function() return db.highlightSpecialtyBags ~= false end,
        function(v)
            db.highlightSpecialtyBags = v
            if BFB.BagFrame and BFB.BagFrame.UpdateSlots then BFB.BagFrame:UpdateSlots() end
            if BFB.BankFrame and BFB.BankFrame.UpdateSlots then BFB.BankFrame:UpdateSlots() end
        end,
        "Color-codes empty slots belonging to specialty bags (Soul, Herb, Mining, Enchanting, and Quivers/Ammo pouches)."
    )

    local hRecent = self:CreateSectionHeader(pDisplay, "Recent Items & Smart Categories", 16, 0)

    local cbRecentItems = self:CreateCheckbox(pDisplay, "BFB_CbRecentItems", "Recent Items Smart Category", 16, 0,
        function() return db.enableRecentItems ~= false end,
        function(v)
            db.enableRecentItems = v
            if BFB.BagFrame and BFB.BagFrame.UpdateLayout then BFB.BagFrame:UpdateLayout() end
        end,
        "Automatically places newly looted items into a top-priority 'Recent Items' category with a cyan indicator."
    )

    local slRecentTimeout = self:CreateSlider(pDisplay, "BFB_SlRecentTimeout", "Recent Window (Min)", 1, 15, 1, 16, 0,
        function() return db.recentTimeout or 5 end,
        function(v)
            db.recentTimeout = v
        end,
        "%d min",
        "Number of minutes newly looted items stay categorized in the Recent Items section."
    )

    local cbCompactCats = self:CreateCheckbox(pDisplay, "BFB_CbCompactCats", "Consolidate Category Space", 16, 0,
        function() return db.compactCategories ~= false end,
        function(v)
            db.compactCategories = v
            if BFB.BagFrame and BFB.BagFrame.UpdateLayout then BFB.BagFrame:UpdateLayout() end
            if BFB.BankFrame and BFB.BankFrame.UpdateLayout then BFB.BankFrame:UpdateLayout() end
        end,
        "Packs small categories side-by-side into rows instead of full-width vertical stacks, drastically shrinking window height."
    )

    local cbCategoryFreeSlots = self:CreateCheckbox(pDisplay, "BFB_CbCategoryFreeSlots", "Show Free Slots in Category View", 16, 0,
        function() return db.showCategoryFreeSlots == true end,
        function(v)
            db.showCategoryFreeSlots = v
            if BFB.BagFrame and BFB.BagFrame.UpdateLayout then BFB.BagFrame:UpdateLayout() end
            if BFB.BankFrame and BFB.BankFrame.UpdateLayout then BFB.BankFrame:UpdateLayout() end
        end,
        "When disabled, empty slot grids are omitted in category mode to save space (free slot count remains in the footer)."
    )

    local btnClearRecent = self:CreateButton(pDisplay, "BFB_BtnClearRecent", "Clear Recent Cache", 16, 0, 150, 22, function()
        if BFB.CategoryEngine and BFB.CategoryEngine.ClearRecent then
            BFB.CategoryEngine:ClearRecent()
            if BFB.BagFrame and BFB.BagFrame.UpdateLayout then BFB.BagFrame:UpdateLayout() end
            print("|cff00c0ffBleakfiber's Bags:|r Recent items cache cleared.")
        end
    end)

    local btnClearOverrides = self:CreateButton(pDisplay, "BFB_BtnClearOverrides", "Reset Item Overrides", 16, 0, 160, 22, function()
        if db.customCategoryOverrides then
            wipe(db.customCategoryOverrides)
            if BFB.BagFrame and BFB.BagFrame.UpdateLayout then BFB.BagFrame:UpdateLayout() end
            if BFB.BankFrame and BFB.BankFrame.UpdateLayout then BFB.BankFrame:UpdateLayout() end
            print("|cff00c0ffBleakfiber's Bags:|r Custom item category assignments reset.")
        end
    end)

    local categoryNote = pDisplay:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    categoryNote:SetText("|cff888888Tip: Alt + Right-Click any item in your bags or bank to assign it to a custom category.|r")
    categoryNote:SetWordWrap(true)
    categoryNote:SetJustifyH("LEFT")

    local hFrameElements = self:CreateSectionHeader(pDisplay, "Window Elements & Search", 16, 0)

    local cbBagBar = self:CreateCheckbox(pDisplay, "BFB_CbBagBar", "Show Equipped Bags Drawer", 16, 0,
        function() return db.showBagSlotBar end,
        function(v)
            db.showBagSlotBar = v
            if BFB.BagFrame and BFB.BagFrame.UpdateLayout then BFB.BagFrame:UpdateLayout() end
        end,
        "Shows an expandable drawer below the bag header with equipped bag slot icons."
    )

    local cbSearchBar = self:CreateCheckbox(pDisplay, "BFB_CbSearchBar", "Live Search Filter Bar", 16, 0,
        function() return db.showSearchBar ~= false end,
        function(v)
            db.showSearchBar = v
            if BFB.BagFrame and BFB.BagFrame.UpdateLayout then BFB.BagFrame:UpdateLayout() end
            if BFB.BankFrame and BFB.BankFrame.UpdateLayout then BFB.BankFrame:UpdateLayout() end
        end,
        "Displays the interactive search input bar with advanced keyword syntax support (boe, bop, quest, gear, >lvl)."
    )

    local btnResetPos = self:CreateButton(pDisplay, "BFB_BtnResetPos", "Reset Window Positions", 16, 0, 180, 24, function()
        BFB:ResetPosition()
    end)

    -- Display Tab Reflow Layout
    local function LayoutDisplay(w)
        local isWide = (w >= 470)
        local colWidth = isWide and math.floor((w - 48) / 2) or (w - 32)
        local col1X = 16
        local col2X = isWide and (col1X + colWidth + 16) or 16

        local y = -12
        hOverlays:ClearAllPoints()
        hOverlays:SetPoint("TOPLEFT", pDisplay, "TOPLEFT", col1X, y)
        y = y - 26

        if isWide then
            cbQualityGlow:ClearAllPoints()
            cbQualityGlow:SetPoint("TOPLEFT", pDisplay, "TOPLEFT", col1X, y)
            cbJunkIcon:ClearAllPoints()
            cbJunkIcon:SetPoint("TOPLEFT", pDisplay, "TOPLEFT", col2X, y)
            if cbQualityGlow.text then cbQualityGlow.text:SetWidth(colWidth - 32) end
            if cbJunkIcon.text then cbJunkIcon.text:SetWidth(colWidth - 32) end
            y = y - 30

            cbQuestGlow:ClearAllPoints()
            cbQuestGlow:SetPoint("TOPLEFT", pDisplay, "TOPLEFT", col1X, y)
            cbItemLevel:ClearAllPoints()
            cbItemLevel:SetPoint("TOPLEFT", pDisplay, "TOPLEFT", col2X, y)
            if cbQuestGlow.text then cbQuestGlow.text:SetWidth(colWidth - 32) end
            if cbItemLevel.text then cbItemLevel.text:SetWidth(colWidth - 32) end
            y = y - 30

            cbTintUnusable:ClearAllPoints()
            cbTintUnusable:SetPoint("TOPLEFT", pDisplay, "TOPLEFT", col1X, y)
            cbSpecialtyBags:ClearAllPoints()
            cbSpecialtyBags:SetPoint("TOPLEFT", pDisplay, "TOPLEFT", col2X, y)
            if cbTintUnusable.text then cbTintUnusable.text:SetWidth(colWidth - 32) end
            if cbSpecialtyBags.text then cbSpecialtyBags.text:SetWidth(colWidth - 32) end
            y = y - 40
        else
            local list = { cbQualityGlow, cbJunkIcon, cbQuestGlow, cbItemLevel, cbTintUnusable, cbSpecialtyBags }
            for _, cb in ipairs(list) do
                cb:ClearAllPoints()
                cb:SetPoint("TOPLEFT", pDisplay, "TOPLEFT", col1X, y)
                if cb.text then cb.text:SetWidth(colWidth - 32) end
                y = y - 30
            end
            y = y - 10
        end

        hRecent:ClearAllPoints()
        hRecent:SetPoint("TOPLEFT", pDisplay, "TOPLEFT", col1X, y)
        y = y - 26

        if isWide then
            cbRecentItems:ClearAllPoints()
            cbRecentItems:SetPoint("TOPLEFT", pDisplay, "TOPLEFT", col1X, y)
            slRecentTimeout:ClearAllPoints()
            slRecentTimeout:SetPoint("TOPLEFT", pDisplay, "TOPLEFT", col2X, y)
            if cbRecentItems.text then cbRecentItems.text:SetWidth(colWidth - 32) end
            y = y - 48

            cbCompactCats:ClearAllPoints()
            cbCompactCats:SetPoint("TOPLEFT", pDisplay, "TOPLEFT", col1X, y)
            cbCategoryFreeSlots:ClearAllPoints()
            cbCategoryFreeSlots:SetPoint("TOPLEFT", pDisplay, "TOPLEFT", col2X, y)
            if cbCompactCats.text then cbCompactCats.text:SetWidth(colWidth - 32) end
            if cbCategoryFreeSlots.text then cbCategoryFreeSlots.text:SetWidth(colWidth - 32) end
            y = y - 32

            btnClearRecent:ClearAllPoints()
            btnClearRecent:SetPoint("TOPLEFT", pDisplay, "TOPLEFT", col1X, y)
            btnClearOverrides:ClearAllPoints()
            btnClearOverrides:SetPoint("TOPLEFT", pDisplay, "TOPLEFT", col2X, y)
            y = y - 34
        else
            cbRecentItems:ClearAllPoints()
            cbRecentItems:SetPoint("TOPLEFT", pDisplay, "TOPLEFT", col1X, y)
            if cbRecentItems.text then cbRecentItems.text:SetWidth(colWidth - 32) end
            y = y - 32

            slRecentTimeout:ClearAllPoints()
            slRecentTimeout:SetPoint("TOPLEFT", pDisplay, "TOPLEFT", col1X, y)
            y = y - 48

            cbCompactCats:ClearAllPoints()
            cbCompactCats:SetPoint("TOPLEFT", pDisplay, "TOPLEFT", col1X, y)
            if cbCompactCats.text then cbCompactCats.text:SetWidth(colWidth - 32) end
            y = y - 32

            cbCategoryFreeSlots:ClearAllPoints()
            cbCategoryFreeSlots:SetPoint("TOPLEFT", pDisplay, "TOPLEFT", col1X, y)
            if cbCategoryFreeSlots.text then cbCategoryFreeSlots.text:SetWidth(colWidth - 32) end
            y = y - 32

            btnClearRecent:ClearAllPoints()
            btnClearRecent:SetPoint("TOPLEFT", pDisplay, "TOPLEFT", col1X, y)
            btnClearOverrides:ClearAllPoints()
            btnClearOverrides:SetPoint("TOPLEFT", pDisplay, "TOPLEFT", col1X + 160, y)
            y = y - 34
        end

        categoryNote:ClearAllPoints()
        categoryNote:SetPoint("TOPLEFT", pDisplay, "TOPLEFT", col1X, y)
        categoryNote:SetWidth(w - 32)
        y = y - 36

        hFrameElements:ClearAllPoints()
        hFrameElements:SetPoint("TOPLEFT", pDisplay, "TOPLEFT", col1X, y)
        y = y - 26

        if isWide then
            cbBagBar:ClearAllPoints()
            cbBagBar:SetPoint("TOPLEFT", pDisplay, "TOPLEFT", col1X, y)
            cbSearchBar:ClearAllPoints()
            cbSearchBar:SetPoint("TOPLEFT", pDisplay, "TOPLEFT", col2X, y)
            if cbBagBar.text then cbBagBar.text:SetWidth(colWidth - 32) end
            if cbSearchBar.text then cbSearchBar.text:SetWidth(colWidth - 32) end
            y = y - 40
        else
            cbBagBar:ClearAllPoints()
            cbBagBar:SetPoint("TOPLEFT", pDisplay, "TOPLEFT", col1X, y)
            if cbBagBar.text then cbBagBar.text:SetWidth(colWidth - 32) end
            y = y - 30
            cbSearchBar:ClearAllPoints()
            cbSearchBar:SetPoint("TOPLEFT", pDisplay, "TOPLEFT", col1X, y)
            if cbSearchBar.text then cbSearchBar.text:SetWidth(colWidth - 32) end
            y = y - 36
        end

        btnResetPos:ClearAllPoints()
        btnResetPos:SetPoint("TOPLEFT", pDisplay, "TOPLEFT", col1X, y)
        y = y - 36

        pDisplay.contentHeight = math.abs(y) + 24
    end

    --[[-------------------------------------------------------------------------
        Tab 3: Bank & Vault
    ---------------------------------------------------------------------------]]
    local pBank = CreateFrame("Frame", nil, scrollChild)
    pBank:SetAllPoints(scrollChild)
    tabPanes["bank"] = pBank

    local hBankLayout = self:CreateSectionHeader(pBank, "Bank Layout & Appearance", 16, 0)

    local slBankCols = self:CreateSlider(pBank, "BFB_SlBankCols", "Bank Columns", 8, 24, 1, 16, 0,
        function() return db.bankColumns or 12 end,
        function(v)
            db.bankColumns = v
            if BFB.BankFrame and BFB.BankFrame.UpdateLayout then BFB.BankFrame:UpdateLayout() end
        end,
        "%d",
        "Number of slot columns in the bank window."
    )

    local ddBankViewMode = self:CreateDropdown(pBank, "BFB_DdBankViewMode", "Bank Display Mode", {
        { value = "grid", text = "Classic Grid" },
        { value = "category", text = "Categorized" },
    }, 16, 0, 180,
        function() return db.bankViewMode or "grid" end,
        function(v)
            db.bankViewMode = v
            if BFB.BankFrame and BFB.BankFrame.UpdateLayout then BFB.BankFrame:UpdateLayout() end
        end,
        "Switch between standard flat grid layout and categorized sections in the bank."
    )

    local cbBankBagBar = self:CreateCheckbox(pBank, "BFB_CbBankBagBar", "Show Bank Bag Slots Drawer", 16, 0,
        function() return db.showBankBagSlotBar end,
        function(v)
            db.showBankBagSlotBar = v
            if BFB.BankFrame and BFB.BankFrame.UpdateLayout then BFB.BankFrame:UpdateLayout() end
        end,
        "Shows an expandable drawer below the bank header with purchasable bank bag slots."
    )

    local hBankCache = self:CreateSectionHeader(pBank, "Offline Bank Caching & Tooltips", 16, 0)

    local cbEnableCache = self:CreateCheckbox(pBank, "BFB_CbEnableCache", "Enable Offline Bank Caching", 16, 0,
        function() return db.enableBankCache ~= false end,
        function(v) db.enableBankCache = v end,
        "Automatically saves snapshots of your bank contents for offline reference and tooltips."
    )

    local cbBankTooltip = self:CreateCheckbox(pBank, "BFB_CbBankTooltip", "Cross-Character Bank Tooltips", 16, 0,
        function() return db.showBankTooltip ~= false end,
        function(v) db.showBankTooltip = v end,
        "Appends cached bank counts to item tooltips across all characters on your current realm."
    )

    local btnClearCache = self:CreateButton(pBank, "BFB_BtnClearCache", "Clear Bank Cache", 16, 0, 150, 24, function()
        if BFB.BankCache and BFB.BankCache.ClearCache then
            BFB.BankCache:ClearCache()
            print("|cff00c0ffBleakfiber's Bags:|r Bank cache data has been reset.")
        end
    end)

    -- Bank Tab Reflow Layout
    local function LayoutBank(w)
        local isWide = (w >= 470)
        local colWidth = isWide and math.floor((w - 48) / 2) or (w - 32)
        local col1X = 16
        local col2X = isWide and (col1X + colWidth + 16) or 16

        local y = -12
        hBankLayout:ClearAllPoints()
        hBankLayout:SetPoint("TOPLEFT", pBank, "TOPLEFT", col1X, y)
        y = y - 28

        if isWide then
            slBankCols:ClearAllPoints()
            slBankCols:SetPoint("TOPLEFT", pBank, "TOPLEFT", col1X, y)
            ddBankViewMode:ClearAllPoints()
            ddBankViewMode:SetPoint("TOPLEFT", pBank, "TOPLEFT", col2X, y + 6)
            y = y - 54

            cbBankBagBar:ClearAllPoints()
            cbBankBagBar:SetPoint("TOPLEFT", pBank, "TOPLEFT", col1X, y)
            if cbBankBagBar.text then cbBankBagBar.text:SetWidth(colWidth - 32) end
            y = y - 44
        else
            slBankCols:ClearAllPoints()
            slBankCols:SetPoint("TOPLEFT", pBank, "TOPLEFT", col1X, y)
            y = y - 48
            ddBankViewMode:ClearAllPoints()
            ddBankViewMode:SetPoint("TOPLEFT", pBank, "TOPLEFT", col1X, y)
            y = y - 52
            cbBankBagBar:ClearAllPoints()
            cbBankBagBar:SetPoint("TOPLEFT", pBank, "TOPLEFT", col1X, y)
            if cbBankBagBar.text then cbBankBagBar.text:SetWidth(colWidth - 32) end
            y = y - 36
        end

        hBankCache:ClearAllPoints()
        hBankCache:SetPoint("TOPLEFT", pBank, "TOPLEFT", col1X, y)
        y = y - 26

        if isWide then
            cbEnableCache:ClearAllPoints()
            cbEnableCache:SetPoint("TOPLEFT", pBank, "TOPLEFT", col1X, y)
            cbBankTooltip:ClearAllPoints()
            cbBankTooltip:SetPoint("TOPLEFT", pBank, "TOPLEFT", col2X, y)
            if cbEnableCache.text then cbEnableCache.text:SetWidth(colWidth - 32) end
            if cbBankTooltip.text then cbBankTooltip.text:SetWidth(colWidth - 32) end
            y = y - 44
        else
            cbEnableCache:ClearAllPoints()
            cbEnableCache:SetPoint("TOPLEFT", pBank, "TOPLEFT", col1X, y)
            if cbEnableCache.text then cbEnableCache.text:SetWidth(colWidth - 32) end
            y = y - 30
            cbBankTooltip:ClearAllPoints()
            cbBankTooltip:SetPoint("TOPLEFT", pBank, "TOPLEFT", col1X, y)
            if cbBankTooltip.text then cbBankTooltip.text:SetWidth(colWidth - 32) end
            y = y - 36
        end

        btnClearCache:ClearAllPoints()
        btnClearCache:SetPoint("TOPLEFT", pBank, "TOPLEFT", col1X, y)
        y = y - 36

        pBank.contentHeight = math.abs(y) + 24
    end

    --[[-------------------------------------------------------------------------
        Tab 4: Automation & Sorting
    ---------------------------------------------------------------------------]]
    local pAuto = CreateFrame("Frame", nil, scrollChild)
    pAuto:SetAllPoints(scrollChild)
    tabPanes["automation"] = pAuto

    local hMerchant = self:CreateSectionHeader(pAuto, "Merchant Automation", 16, 0)

    local cbAutoSell = self:CreateCheckbox(pAuto, "BFB_CbAutoSell", "Auto-Sell Poor / Grey Junk", 16, 0,
        function() return db.autoSellJunk ~= false end,
        function(v) db.autoSellJunk = v end,
        "Automatically sells all grey quality items when opening a merchant window."
    )

    local cbAutoRepair = self:CreateCheckbox(pAuto, "BFB_CbAutoRepair", "Auto-Repair Equipment", 16, 0,
        function() return db.autoRepair ~= false end,
        function(v) db.autoRepair = v end,
        "Automatically repairs equipped gear and inventory items using player funds at repair vendors."
    )

    local merchantNote = pAuto:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    merchantNote:SetText("|cff888888Tip: Hold |cffffd100[Shift]|r when opening a merchant window to temporarily bypass auto-sell and auto-repair.|r")
    merchantNote:SetWordWrap(true)
    merchantNote:SetJustifyH("LEFT")

    local hSorting = self:CreateSectionHeader(pAuto, "Inventory Sorting & Organization", 16, 0)

    local btnSortBags = self:CreateButton(pAuto, "BFB_BtnSortBags", "Sort Bags Now", 16, 0, 130, 24, function()
        if BFB.Sorting and BFB.Sorting.StartSort then
            BFB.Sorting:StartSort()
        end
    end)

    local btnSortBank = self:CreateButton(pAuto, "BFB_BtnSortBank", "Sort Bank Now", 16, 0, 130, 24, function()
        if BFB.Sorting and BFB.Sorting.StartSort then
            BFB.Sorting:StartSort(true)
        end
    end)

    local btnDepositTrade = self:CreateButton(pAuto, "BFB_BtnDepositTrade", "Deposit Trade Goods", 16, 0, 150, 24, function()
        if BFB.BankFrame and BFB.BankFrame.DepositTradeGoods then
            BFB.BankFrame:DepositTradeGoods()
        end
    end)

    local sortingNote = pAuto:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    sortingNote:SetText("|cff888888Inventory sorting runs safely in non-blocking steps to avoid client freezes, automatically pauses during combat, and intelligently consolidates partial stacks.|r")
    sortingNote:SetWordWrap(true)
    sortingNote:SetJustifyH("LEFT")

    -- Automation Tab Reflow Layout
    local function LayoutAutomation(w)
        local isWide = (w >= 470)
        local colWidth = isWide and math.floor((w - 48) / 2) or (w - 32)
        local col1X = 16
        local col2X = isWide and (col1X + colWidth + 16) or 16

        local y = -12
        hMerchant:ClearAllPoints()
        hMerchant:SetPoint("TOPLEFT", pAuto, "TOPLEFT", col1X, y)
        y = y - 26

        if isWide then
            cbAutoSell:ClearAllPoints()
            cbAutoSell:SetPoint("TOPLEFT", pAuto, "TOPLEFT", col1X, y)
            cbAutoRepair:ClearAllPoints()
            cbAutoRepair:SetPoint("TOPLEFT", pAuto, "TOPLEFT", col2X, y)
            if cbAutoSell.text then cbAutoSell.text:SetWidth(colWidth - 32) end
            if cbAutoRepair.text then cbAutoRepair.text:SetWidth(colWidth - 32) end
            y = y - 36
        else
            cbAutoSell:ClearAllPoints()
            cbAutoSell:SetPoint("TOPLEFT", pAuto, "TOPLEFT", col1X, y)
            if cbAutoSell.text then cbAutoSell.text:SetWidth(colWidth - 32) end
            y = y - 30
            cbAutoRepair:ClearAllPoints()
            cbAutoRepair:SetPoint("TOPLEFT", pAuto, "TOPLEFT", col1X, y)
            if cbAutoRepair.text then cbAutoRepair.text:SetWidth(colWidth - 32) end
            y = y - 36
        end

        merchantNote:ClearAllPoints()
        merchantNote:SetPoint("TOPLEFT", pAuto, "TOPLEFT", col1X, y)
        merchantNote:SetWidth(w - 32)
        y = y - 36

        hSorting:ClearAllPoints()
        hSorting:SetPoint("TOPLEFT", pAuto, "TOPLEFT", col1X, y)
        y = y - 28

        if isWide then
            btnSortBags:ClearAllPoints()
            btnSortBags:SetPoint("TOPLEFT", pAuto, "TOPLEFT", col1X, y)
            btnSortBank:ClearAllPoints()
            btnSortBank:SetPoint("LEFT", btnSortBags, "RIGHT", 12, 0)
            btnDepositTrade:ClearAllPoints()
            btnDepositTrade:SetPoint("LEFT", btnSortBank, "RIGHT", 12, 0)
            y = y - 38
        else
            btnSortBags:ClearAllPoints()
            btnSortBags:SetPoint("TOPLEFT", pAuto, "TOPLEFT", col1X, y)
            btnSortBank:ClearAllPoints()
            btnSortBank:SetPoint("TOPLEFT", pAuto, "TOPLEFT", col1X + 140, y)
            y = y - 32
            btnDepositTrade:ClearAllPoints()
            btnDepositTrade:SetPoint("TOPLEFT", pAuto, "TOPLEFT", col1X, y)
            y = y - 36
        end

        sortingNote:ClearAllPoints()
        sortingNote:SetPoint("TOPLEFT", pAuto, "TOPLEFT", col1X, y)
        sortingNote:SetWidth(w - 32)
        y = y - 48

        pAuto.contentHeight = math.abs(y) + 24
    end

    --[[-------------------------------------------------------------------------
        Tab 5: Profiles & Positioning
    ---------------------------------------------------------------------------]]
    local pProf = CreateFrame("Frame", nil, scrollChild)
    pProf:SetAllPoints(scrollChild)
    tabPanes["profiles"] = pProf

    local hProfiles = self:CreateSectionHeader(pProf, "Profile Management", 16, 0)

    local activeProfText = pProf:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    activeProfText:SetPoint("TOPLEFT", pProf, "TOPLEFT", 16, -36)

    local function UpdateProfileLabel()
        local cur = (BFB.dbObject and BFB.dbObject.GetCurrentProfile and BFB.dbObject:GetCurrentProfile()) or "Default"
        activeProfText:SetText(string.format("Active Profile: |cffffd100%s|r", cur))
    end
    UpdateProfileLabel()

    local ebNewProfile = self:CreateEditBox(pProf, "BFB_EbNewProfile", "New Profile Name", 16, 0, 180, nil, nil)
    local btnCreateProfile = self:CreateButton(pProf, "BFB_BtnCreateProf", "Create Profile", 16, 0, 120, 22, function()
        local name = ebNewProfile:GetText() and ebNewProfile:GetText():trim()
        if name and name ~= "" then
            if BFB.CreateProfile then
                BFB:CreateProfile(name)
            elseif BFB.dbObject and BFB.dbObject.SetProfile then
                local cur = BFB.dbObject:GetCurrentProfile()
                BFB.dbObject:SetProfile(name)
                if cur and cur ~= name and BFB.dbObject.CopyProfile then
                    BFB.dbObject:CopyProfile(cur)
                end
            end
            ebNewProfile:SetText("")
            UpdateProfileLabel()
            UI:Refresh()
            print(string.format("|cff00c0ffBleakfiber's Bags:|r Created and activated profile '|cffffd100%s|r'.", name))
        end
    end)

    local ddProfileSelect
    local function GetProfileCycleOptions()
        local list = (BFB.dbObject and BFB.dbObject.GetProfiles and BFB.dbObject:GetProfiles()) or { "Default" }
        local opts = {}
        for _, p in ipairs(list) do
            table.insert(opts, { value = p, text = p })
        end
        return opts
    end

    ddProfileSelect = self:CreateDropdown(pProf, "BFB_DdProfiles", "Select Profile", GetProfileCycleOptions, 16, 0, 180,
        function()
            return (BFB.dbObject and BFB.dbObject.GetCurrentProfile and BFB.dbObject:GetCurrentProfile()) or "Default"
        end,
        function(selectedKey)
            if BFB.SetProfile then
                BFB:SetProfile(selectedKey)
            elseif BFB.dbObject and BFB.dbObject.SetProfile then
                BFB.dbObject:SetProfile(selectedKey)
            end
            UpdateProfileLabel()
            UI:Refresh()
            print(string.format("|cff00c0ffBleakfiber's Bags:|r Switched active profile to '|cffffd100%s|r'.", selectedKey))
        end,
        "Select an existing configuration profile."
    )

    local btnResetProfile = self:CreateButton(pProf, "BFB_BtnResetProf", "Reset to Defaults", 16, 0, 130, 22, function()
        if BFB.ResetProfile then
            BFB:ResetProfile()
        elseif BFB.dbObject and BFB.dbObject.ResetProfile then
            BFB.dbObject:ResetProfile()
        end
        UI:Refresh()
        print("|cff00c0ffBleakfiber's Bags:|r Current profile reset to default values.")
    end)

    local hMoversSection = self:CreateSectionHeader(pProf, "Frame Movers & Positioning", 16, 0)

    local btnUnlockMovers = self:CreateButton(pProf, "BFB_BtnUnlockMovers", "Unlock Movers", 16, 0, 120, 24, function()
        BFB:ToggleMovers(true)
    end)

    local btnLockMovers = self:CreateButton(pProf, "BFB_BtnLockMovers", "Lock Movers", 16, 0, 110, 24, function()
        BFB:ToggleMovers(false)
    end)

    local btnResetMovers = self:CreateButton(pProf, "BFB_BtnResetMovers", "Reset Positions", 16, 0, 130, 24, function()
        BFB:ResetPosition()
    end)

    -- Profiles Tab Reflow Layout
    local function LayoutProfiles(w)
        local isWide = (w >= 470)
        local colWidth = isWide and math.floor((w - 48) / 2) or (w - 32)
        local col1X = 16
        local col2X = isWide and (col1X + colWidth + 16) or 16

        local y = -12
        hProfiles:ClearAllPoints()
        hProfiles:SetPoint("TOPLEFT", pProf, "TOPLEFT", col1X, y)
        y = y - 24

        activeProfText:ClearAllPoints()
        activeProfText:SetPoint("TOPLEFT", pProf, "TOPLEFT", col1X, y)
        y = y - 26

        if isWide then
            ebNewProfile:ClearAllPoints()
            ebNewProfile:SetPoint("TOPLEFT", pProf, "TOPLEFT", col1X, y)
            btnCreateProfile:ClearAllPoints()
            btnCreateProfile:SetPoint("TOPLEFT", pProf, "TOPLEFT", col1X + 190, y - 18)
            
            ddProfileSelect:ClearAllPoints()
            ddProfileSelect:SetPoint("TOPLEFT", pProf, "TOPLEFT", col2X, y)
            btnResetProfile:ClearAllPoints()
            btnResetProfile:SetPoint("TOPLEFT", pProf, "TOPLEFT", col2X, y - 50)
            y = y - 88
        else
            ebNewProfile:ClearAllPoints()
            ebNewProfile:SetPoint("TOPLEFT", pProf, "TOPLEFT", col1X, y)
            y = y - 44
            btnCreateProfile:ClearAllPoints()
            btnCreateProfile:SetPoint("TOPLEFT", pProf, "TOPLEFT", col1X, y)
            y = y - 36
            ddProfileSelect:ClearAllPoints()
            ddProfileSelect:SetPoint("TOPLEFT", pProf, "TOPLEFT", col1X, y)
            y = y - 52
            btnResetProfile:ClearAllPoints()
            btnResetProfile:SetPoint("TOPLEFT", pProf, "TOPLEFT", col1X, y)
            y = y - 36
        end

        hMoversSection:ClearAllPoints()
        hMoversSection:SetPoint("TOPLEFT", pProf, "TOPLEFT", col1X, y)
        y = y - 28

        if isWide then
            btnUnlockMovers:ClearAllPoints()
            btnUnlockMovers:SetPoint("TOPLEFT", pProf, "TOPLEFT", col1X, y)
            btnLockMovers:ClearAllPoints()
            btnLockMovers:SetPoint("LEFT", btnUnlockMovers, "RIGHT", 10, 0)
            btnResetMovers:ClearAllPoints()
            btnResetMovers:SetPoint("LEFT", btnLockMovers, "RIGHT", 10, 0)
            y = y - 38
        else
            btnUnlockMovers:ClearAllPoints()
            btnUnlockMovers:SetPoint("TOPLEFT", pProf, "TOPLEFT", col1X, y)
            btnLockMovers:ClearAllPoints()
            btnLockMovers:SetPoint("LEFT", btnUnlockMovers, "RIGHT", 10, 0)
            y = y - 30
            btnResetMovers:ClearAllPoints()
            btnResetMovers:SetPoint("TOPLEFT", pProf, "TOPLEFT", col1X, y)
            y = y - 36
        end

        pProf.contentHeight = math.abs(y) + 24
    end

    -- Tab switching function
    local function ShowTab(tabID)
        activeTab = tabID
        for _, t in ipairs(tabs) do
            local btn = tabButtons[t.id]
            local pane = tabPanes[t.id]
            if t.id == tabID then
                if btn then
                    btn:SetBackdropColor(unpack(COLORS.tabActive))
                    btn:SetBackdropBorderColor(unpack(COLORS.goldBorder))
                    btn.label:SetTextColor(COLORS.goldText[1], COLORS.goldText[2], COLORS.goldText[3])
                end
                if pane then
                    pane:Show()
                    local curW = scrollChild:GetWidth() or 540
                    if t.id == "general" then LayoutGeneral(curW)
                    elseif t.id == "display" then LayoutDisplay(curW)
                    elseif t.id == "bank" then LayoutBank(curW)
                    elseif t.id == "automation" then LayoutAutomation(curW)
                    elseif t.id == "profiles" then LayoutProfiles(curW)
                    end
                    scrollChild:SetHeight(pane.contentHeight or 600)
                end
            else
                if btn then
                    btn:SetBackdropColor(unpack(COLORS.tabNormal))
                    btn:SetBackdropBorderColor(unpack(COLORS.goldMuted))
                    btn.label:SetTextColor(COLORS.whiteText[1], COLORS.whiteText[2], COLORS.whiteText[3])
                end
                if pane then pane:Hide() end
            end
        end
        scrollFrame:SetVerticalScroll(0)
        if updateScroll then updateScroll() end
    end

    -- Tab button creation
    local function LayoutTabButtons()
        local cWidth = tabsContainer:GetWidth()
        if not cWidth or cWidth < 200 then cWidth = 540 end
        local gap = 4
        if cWidth >= 500 then
            tabsContainer:SetHeight(28)
            local btnW = math.floor((cWidth - ((#tabs - 1) * gap)) / #tabs)
            if btnW > 105 then btnW = 105 end
            local curX = 0
            for _, t in ipairs(tabs) do
                local b = tabButtons[t.id]
                if b then
                    b:SetSize(btnW, 24)
                    b:ClearAllPoints()
                    b:SetPoint("TOPLEFT", tabsContainer, "TOPLEFT", curX, 0)
                end
                curX = curX + btnW + gap
            end
        else
            tabsContainer:SetHeight(52)
            local row1Tabs = 3
            local btnW1 = math.floor((cWidth - ((row1Tabs - 1) * gap)) / row1Tabs)
            local curX = 0
            for i = 1, row1Tabs do
                local t = tabs[i]
                local b = tabButtons[t.id]
                if b then
                    b:SetSize(btnW1, 22)
                    b:ClearAllPoints()
                    b:SetPoint("TOPLEFT", tabsContainer, "TOPLEFT", curX, 0)
                end
                curX = curX + btnW1 + gap
            end
            local row2Tabs = #tabs - row1Tabs
            local btnW2 = math.floor((cWidth - ((row2Tabs - 1) * gap)) / row2Tabs)
            curX = 0
            for i = row1Tabs + 1, #tabs do
                local t = tabs[i]
                local b = tabButtons[t.id]
                if b then
                    b:SetSize(btnW2, 22)
                    b:ClearAllPoints()
                    b:SetPoint("TOPLEFT", tabsContainer, "TOPLEFT", curX, -26)
                end
                curX = curX + btnW2 + gap
            end
        end
    end

    for _, t in ipairs(tabs) do
        local b = self:CreateButton(tabsContainer, "BFB_TabBtn_" .. t.id, t.title, 0, 0, 95, 24, function()
            ShowTab(t.id)
        end)
        tabButtons[t.id] = b
    end

    -- Hook resize handlers for responsive reflow
    scrollFrame:SetScript("OnSizeChanged", function(self, width)
        if width and width > 60 then
            local childW = width - 24
            scrollChild:SetWidth(childW)
            if activeTab == "general" then LayoutGeneral(childW)
            elseif activeTab == "display" then LayoutDisplay(childW)
            elseif activeTab == "bank" then LayoutBank(childW)
            elseif activeTab == "automation" then LayoutAutomation(childW)
            elseif activeTab == "profiles" then LayoutProfiles(childW)
            end
            local curPane = tabPanes[activeTab]
            if curPane and curPane.contentHeight then
                scrollChild:SetHeight(curPane.contentHeight)
            end
            LayoutTabButtons()
            if updateScroll then updateScroll() end
        end
    end)

    tabsContainer:SetScript("OnSizeChanged", function()
        LayoutTabButtons()
    end)

    LayoutTabButtons()
    ShowTab("general")
end

--[[-----------------------------------------------------------------------------
    Live Refresh
-------------------------------------------------------------------------------]]
function UI:Refresh()
    for _, widget in ipairs(registeredWidgets) do
        if widget.update then
            widget.update()
        end
    end
end

--[[-----------------------------------------------------------------------------
    Standalone Fallback Window (When Master Hub is not loaded)
-------------------------------------------------------------------------------]]
function UI:CreateStandaloneWindow()
    if self.standaloneFrame then return self.standaloneFrame end

    local f = CreateFrame("Frame", ADDON_NAME .. "StandaloneWindow", UIParent, BACKDROP_TEMPLATE)
    f:SetSize(760, 540)
    f:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    f:SetFrameStrata("HIGH")
    f:SetToplevel(true)
    f:SetClampedToScreen(true)
    f:EnableMouse(true)
    f:SetMovable(true)

    tinsert(UISpecialFrames, ADDON_NAME .. "StandaloneWindow")

    f:SetBackdrop(WINDOW_BACKDROP)
    f:SetBackdropColor(unpack(COLORS.bgSlate))
    f:SetBackdropBorderColor(unpack(COLORS.goldBorder))

    -- Title Bar (Drag Handle)
    local titleBar = CreateFrame("Frame", nil, f)
    titleBar:SetHeight(32)
    titleBar:SetPoint("TOPLEFT", f, "TOPLEFT", 6, -6)
    titleBar:SetPoint("TOPRIGHT", f, "TOPRIGHT", -32, -6)
    titleBar:EnableMouse(true)
    titleBar:RegisterForDrag("LeftButton")
    titleBar:SetScript("OnDragStart", function() f:StartMoving() end)
    titleBar:SetScript("OnDragStop", function() f:StopMovingOrSizing() end)

    local title = titleBar:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    title:SetPoint("LEFT", titleBar, "LEFT", 10, 0)
    title:SetText("|cffffd100" .. FULL_TITLE .. "|r")

    local closeBtn = CreateFrame("Button", nil, f, "UIPanelCloseButton")
    closeBtn:SetSize(28, 28)
    closeBtn:SetPoint("TOPRIGHT", f, "TOPRIGHT", -4, -4)
    closeBtn:SetScript("OnClick", function() f:Hide() end)

    -- Inset Content Container
    local content = CreateFrame("Frame", nil, f, BACKDROP_TEMPLATE)
    content:SetPoint("TOPLEFT", f, "TOPLEFT", 10, -38)
    content:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -10, 10)
    content:SetBackdrop(INSET_BACKDROP)
    content:SetBackdropColor(unpack(COLORS.contentBg))
    content:SetBackdropBorderColor(unpack(COLORS.goldMuted))

    self:BuildOptions(content, false)

    f:Hide()
    self.standaloneFrame = f
    return f
end

function UI:ToggleStandaloneWindow()
    local win = self:CreateStandaloneWindow()
    if win:IsShown() then
        win:Hide()
    else
        win:Show()
    end
end

