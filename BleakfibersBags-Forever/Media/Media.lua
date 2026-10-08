local addonName, BFB = ...

local LSM = LibStub and LibStub("LibSharedMedia-3.0", true)

local mediaPath = "Interface\\AddOns\\" .. addonName .. "\\Media\\"
local fontPath = mediaPath .. "Fonts\\"

-- Default Font Constants
BFB.DEFAULT_FONT_NAME = "Nata Sans Regular"
BFB.DEFAULT_FONT_PATH = fontPath .. "NataSans-Regular.ttf"

BFB.DEFAULT_HEADER_FONT_NAME = "Nata Sans Bold"
BFB.DEFAULT_HEADER_FONT_PATH = fontPath .. "NataSans-Bold.ttf"

-- Register Nata Sans Family (Signature Typography)
if LSM then
    LSM:Register("font", "Nata Sans Regular", fontPath .. "NataSans-Regular.ttf")
    LSM:Register("font", "Nata Sans Bold", fontPath .. "NataSans-Bold.ttf")
    LSM:Register("font", "Nata Sans Medium", fontPath .. "NataSans-Medium.ttf")
    LSM:Register("font", "BleakUI Regular", fontPath .. "NataSans-Regular.ttf")
    LSM:Register("font", "BleakUI Bold", fontPath .. "NataSans-Bold.ttf")
end

if LSM then
    -- Register Status Bar Textures
    LSM:Register("statusbar", "BleakFlat", "Interface\\Buttons\\WHITE8x8")
    LSM:Register("statusbar", "Blizzard", "Interface\\TargetingFrame\\UI-StatusBar")
end

-- Media Fetch Helpers with safety fallbacks
function BFB:FetchFont(fontName)
    local fallback = BFB.DEFAULT_FONT_PATH
    if not fontName or fontName == "" then
        fontName = BFB.DEFAULT_FONT_NAME
    end

    if type(fontName) == "string" and (fontName:find("%.ttf$") or fontName:find("%.otf$") or fontName:find("\\") or fontName:find("/")) then
        return fontName
    end

    if LSM then
        local font = LSM:Fetch("font", fontName, true)
        if font and font ~= "" then
            return font
        end

        local def = LSM:Fetch("font", BFB.DEFAULT_FONT_NAME, true)
        if def and def ~= "" then
            return def
        end
    end

    return fallback
end

