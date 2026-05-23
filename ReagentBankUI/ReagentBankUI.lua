-- ReagentBankUI custom skin v19
-- WotLK 3.3.5a-safe: no Retail APIs, no Blizzard button templates in the main window.
local ADDON_NAME = ...
if not ADDON_NAME or ADDON_NAME == "" then
    ADDON_NAME = "ReagentBankUI"
end

local RB = CreateFrame("Frame", "ReagentBankUIController")
_G.ReagentBankUI = RB

local COMMAND_PREFIX = ".rbank"

local CATEGORY_ORDER = {
    { id = 5,  name = "Cloth",             sample = 2589  },
    { id = 8,  name = "Meat",              sample = 12208 },
    { id = 7,  name = "Metal & Stone",     sample = 2772  },
    { id = 12, name = "Enchanting",        sample = 10940 },
    { id = 10, name = "Elemental",         sample = 7068  },
    { id = 1,  name = "Parts",             sample = 4359  },
    { id = 11, name = "Other Trade Goods", sample = 2604  },
    { id = 9,  name = "Herb",              sample = 2453  },
    { id = 6,  name = "Leather",           sample = 2318  },
    { id = 4,  name = "Jewelcrafting",     sample = 1206  },
    { id = 2,  name = "Explosives",        sample = 4358  },
    { id = 3,  name = "Devices",           sample = 4388  },
    { id = 13, name = "Nether Material",   sample = 23572 },
    { id = 14, name = "Armor Vellum",      sample = 38682 },
    { id = 15, name = "Weapon Vellum",     sample = 39349 },
}

local CATEGORY_BY_ID = {}
for _, category in ipairs(CATEGORY_ORDER) do
    CATEGORY_BY_ID[category.id] = category
end

local BACKDROP = {
    bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    tile = true,
    tileSize = 16,
    edgeSize = 14,
    insets = { left = 4, right = 4, top = 4, bottom = 4 },
}

local PANEL_BACKDROP = {
    bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
    edgeFile = "Interface\\Buttons\\WHITE8X8",
    tile = true,
    tileSize = 16,
    edgeSize = 1,
    insets = { left = 1, right = 1, top = 1, bottom = 1 },
}

local BUTTON_BACKDROP = {
    bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
    edgeFile = "Interface\\Buttons\\WHITE8X8",
    tile = true,
    tileSize = 16,
    edgeSize = 1,
    insets = { left = 1, right = 1, top = 1, bottom = 1 },
}

local SKIN = {
    windowBg = { 0.025, 0.028, 0.040, 0.98 },
    windowBorder = { 0.72, 0.52, 0.24, 0.95 },
    panelBg = { 0.045, 0.050, 0.070, 0.86 },
    panelBorder = { 0.23, 0.26, 0.31, 1.00 },
    headerBg = { 0.10, 0.075, 0.035, 0.95 },
    headerLine = { 0.95, 0.72, 0.28, 0.82 },
    buttonBg = { 0.105, 0.085, 0.050, 0.94 },
    buttonBorder = { 0.58, 0.42, 0.18, 0.95 },
    buttonHover = { 1.00, 0.78, 0.28, 0.18 },
    buttonDown = { 0.045, 0.036, 0.025, 0.98 },
    closeBg = { 0.22, 0.045, 0.035, 0.95 },
    closeBorder = { 0.86, 0.30, 0.18, 0.95 },
    rowOdd = { 0.070, 0.075, 0.095, 0.35 },
    rowEven = { 0.030, 0.034, 0.048, 0.18 },
    rowHover = { 1.00, 0.82, 0.32, 0.13 },
    blueText = { 0.62, 0.78, 1.00 },
    titleText = { 1.00, 0.82, 0.28 },
    buttonText = { 1.00, 0.86, 0.46 },
    mutedText = { 0.78, 0.82, 0.88 },
    disabledText = { 0.55, 0.55, 0.55 },
    disabledBorder = { 0.22, 0.22, 0.24, 0.90 },
    inputBg = { 0.035, 0.038, 0.052, 0.96 },
    inputText = { 1.00, 0.92, 0.70 },
    rowFill = { 1.00, 0.72, 0.22, 0.12 },
    listHeaderBg = { 0.11, 0.085, 0.045, 0.72 },
    paperIcon = { 1.00, 1.00, 1.00, 1.00 },
}

local DEFAULT_COLOR_THEME = "gold"

local SKIN_THEME_ORDER = {
    "gold",
    "arcane",
    "emerald",
    "ruby",
    "violet",
    "slate",
}

local SKIN_THEMES = {
    gold = {
        label = "Classic Gold",
        windowBg = { 0.025, 0.028, 0.040, 0.98 },
        windowBorder = { 0.72, 0.52, 0.24, 0.95 },
        panelBg = { 0.045, 0.050, 0.070, 0.86 },
        panelBorder = { 0.23, 0.26, 0.31, 1.00 },
        headerBg = { 0.10, 0.075, 0.035, 0.95 },
        headerLine = { 0.95, 0.72, 0.28, 0.82 },
        buttonBg = { 0.105, 0.085, 0.050, 0.94 },
        buttonBorder = { 0.58, 0.42, 0.18, 0.95 },
        buttonHover = { 1.00, 0.78, 0.28, 0.18 },
        buttonDown = { 0.045, 0.036, 0.025, 0.98 },
        closeBg = { 0.22, 0.045, 0.035, 0.95 },
        closeBorder = { 0.86, 0.30, 0.18, 0.95 },
        rowOdd = { 0.070, 0.075, 0.095, 0.35 },
        rowEven = { 0.030, 0.034, 0.048, 0.18 },
        rowHover = { 1.00, 0.82, 0.32, 0.13 },
        blueText = { 0.62, 0.78, 1.00 },
        titleText = { 1.00, 0.82, 0.28 },
        buttonText = { 1.00, 0.86, 0.46 },
        mutedText = { 0.78, 0.82, 0.88 },
        disabledText = { 0.55, 0.55, 0.55 },
        disabledBorder = { 0.22, 0.22, 0.24, 0.90 },
        inputBg = { 0.035, 0.038, 0.052, 0.96 },
        inputText = { 1.00, 0.92, 0.70 },
        rowFill = { 1.00, 0.72, 0.22, 0.12 },
        listHeaderBg = { 0.11, 0.085, 0.045, 0.72 },
        paperIcon = { 1.00, 1.00, 1.00, 1.00 },
    },
    arcane = {
        label = "Arcane Blue",
        windowBg = { 0.018, 0.026, 0.050, 0.98 },
        windowBorder = { 0.28, 0.56, 0.96, 0.95 },
        panelBg = { 0.030, 0.052, 0.090, 0.86 },
        panelBorder = { 0.16, 0.28, 0.44, 1.00 },
        headerBg = { 0.025, 0.055, 0.100, 0.95 },
        headerLine = { 0.38, 0.72, 1.00, 0.82 },
        buttonBg = { 0.035, 0.070, 0.120, 0.94 },
        buttonBorder = { 0.26, 0.56, 0.98, 0.95 },
        buttonHover = { 0.35, 0.75, 1.00, 0.20 },
        buttonDown = { 0.016, 0.033, 0.060, 0.98 },
        closeBg = { 0.18, 0.040, 0.060, 0.95 },
        closeBorder = { 0.88, 0.24, 0.34, 0.95 },
        rowOdd = { 0.045, 0.065, 0.105, 0.36 },
        rowEven = { 0.020, 0.034, 0.062, 0.20 },
        rowHover = { 0.35, 0.75, 1.00, 0.14 },
        blueText = { 0.62, 0.84, 1.00 },
        titleText = { 0.66, 0.86, 1.00 },
        buttonText = { 0.78, 0.91, 1.00 },
        mutedText = { 0.72, 0.82, 0.92 },
        disabledText = { 0.48, 0.55, 0.62 },
        disabledBorder = { 0.16, 0.20, 0.28, 0.90 },
        inputBg = { 0.018, 0.032, 0.058, 0.96 },
        inputText = { 0.80, 0.93, 1.00 },
        rowFill = { 0.35, 0.75, 1.00, 0.13 },
        listHeaderBg = { 0.025, 0.060, 0.105, 0.72 },
        paperIcon = { 0.70, 0.88, 1.00, 1.00 },
    },
    emerald = {
        label = "Emerald",
        windowBg = { 0.018, 0.040, 0.030, 0.98 },
        windowBorder = { 0.30, 0.82, 0.48, 0.95 },
        panelBg = { 0.028, 0.066, 0.048, 0.86 },
        panelBorder = { 0.14, 0.32, 0.22, 1.00 },
        headerBg = { 0.025, 0.080, 0.048, 0.95 },
        headerLine = { 0.42, 0.96, 0.58, 0.82 },
        buttonBg = { 0.032, 0.088, 0.050, 0.94 },
        buttonBorder = { 0.28, 0.74, 0.42, 0.95 },
        buttonHover = { 0.40, 1.00, 0.58, 0.18 },
        buttonDown = { 0.014, 0.044, 0.026, 0.98 },
        closeBg = { 0.20, 0.045, 0.035, 0.95 },
        closeBorder = { 0.86, 0.30, 0.18, 0.95 },
        rowOdd = { 0.042, 0.082, 0.058, 0.36 },
        rowEven = { 0.020, 0.044, 0.032, 0.20 },
        rowHover = { 0.40, 1.00, 0.58, 0.13 },
        blueText = { 0.66, 1.00, 0.78 },
        titleText = { 0.66, 1.00, 0.62 },
        buttonText = { 0.82, 1.00, 0.72 },
        mutedText = { 0.72, 0.88, 0.78 },
        disabledText = { 0.48, 0.58, 0.50 },
        disabledBorder = { 0.16, 0.24, 0.18, 0.90 },
        inputBg = { 0.018, 0.040, 0.028, 0.96 },
        inputText = { 0.84, 1.00, 0.76 },
        rowFill = { 0.42, 1.00, 0.58, 0.12 },
        listHeaderBg = { 0.030, 0.080, 0.050, 0.72 },
        paperIcon = { 0.74, 1.00, 0.78, 1.00 },
    },
    ruby = {
        label = "Ruby",
        windowBg = { 0.048, 0.018, 0.024, 0.98 },
        windowBorder = { 0.92, 0.30, 0.30, 0.95 },
        panelBg = { 0.078, 0.030, 0.038, 0.86 },
        panelBorder = { 0.36, 0.16, 0.18, 1.00 },
        headerBg = { 0.105, 0.030, 0.036, 0.95 },
        headerLine = { 1.00, 0.42, 0.36, 0.82 },
        buttonBg = { 0.112, 0.038, 0.044, 0.94 },
        buttonBorder = { 0.86, 0.30, 0.26, 0.95 },
        buttonHover = { 1.00, 0.40, 0.34, 0.18 },
        buttonDown = { 0.058, 0.018, 0.022, 0.98 },
        closeBg = { 0.28, 0.040, 0.034, 0.95 },
        closeBorder = { 1.00, 0.42, 0.34, 0.95 },
        rowOdd = { 0.090, 0.045, 0.050, 0.36 },
        rowEven = { 0.050, 0.022, 0.028, 0.20 },
        rowHover = { 1.00, 0.38, 0.34, 0.13 },
        blueText = { 1.00, 0.62, 0.62 },
        titleText = { 1.00, 0.64, 0.54 },
        buttonText = { 1.00, 0.78, 0.66 },
        mutedText = { 0.92, 0.72, 0.72 },
        disabledText = { 0.62, 0.48, 0.48 },
        disabledBorder = { 0.28, 0.16, 0.16, 0.90 },
        inputBg = { 0.052, 0.022, 0.028, 0.96 },
        inputText = { 1.00, 0.82, 0.72 },
        rowFill = { 1.00, 0.42, 0.36, 0.12 },
        listHeaderBg = { 0.105, 0.034, 0.038, 0.72 },
        paperIcon = { 1.00, 0.72, 0.66, 1.00 },
    },
    violet = {
        label = "Violet",
        windowBg = { 0.036, 0.024, 0.056, 0.98 },
        windowBorder = { 0.68, 0.42, 1.00, 0.95 },
        panelBg = { 0.058, 0.040, 0.086, 0.86 },
        panelBorder = { 0.28, 0.20, 0.40, 1.00 },
        headerBg = { 0.075, 0.040, 0.115, 0.95 },
        headerLine = { 0.78, 0.52, 1.00, 0.82 },
        buttonBg = { 0.078, 0.046, 0.120, 0.94 },
        buttonBorder = { 0.62, 0.36, 0.98, 0.95 },
        buttonHover = { 0.78, 0.52, 1.00, 0.18 },
        buttonDown = { 0.038, 0.022, 0.064, 0.98 },
        closeBg = { 0.22, 0.045, 0.035, 0.95 },
        closeBorder = { 0.86, 0.30, 0.18, 0.95 },
        rowOdd = { 0.070, 0.052, 0.104, 0.36 },
        rowEven = { 0.036, 0.026, 0.060, 0.20 },
        rowHover = { 0.78, 0.52, 1.00, 0.13 },
        blueText = { 0.86, 0.72, 1.00 },
        titleText = { 0.86, 0.70, 1.00 },
        buttonText = { 0.93, 0.84, 1.00 },
        mutedText = { 0.82, 0.74, 0.90 },
        disabledText = { 0.54, 0.48, 0.60 },
        disabledBorder = { 0.22, 0.18, 0.28, 0.90 },
        inputBg = { 0.038, 0.026, 0.060, 0.96 },
        inputText = { 0.94, 0.86, 1.00 },
        rowFill = { 0.78, 0.52, 1.00, 0.12 },
        listHeaderBg = { 0.075, 0.045, 0.110, 0.72 },
        paperIcon = { 0.90, 0.78, 1.00, 1.00 },
    },
    slate = {
        label = "Dark Slate",
        windowBg = { 0.026, 0.030, 0.034, 0.98 },
        windowBorder = { 0.52, 0.62, 0.68, 0.95 },
        panelBg = { 0.044, 0.050, 0.056, 0.86 },
        panelBorder = { 0.24, 0.28, 0.32, 1.00 },
        headerBg = { 0.048, 0.056, 0.064, 0.95 },
        headerLine = { 0.68, 0.78, 0.84, 0.82 },
        buttonBg = { 0.060, 0.068, 0.078, 0.94 },
        buttonBorder = { 0.48, 0.58, 0.66, 0.95 },
        buttonHover = { 0.72, 0.84, 0.92, 0.16 },
        buttonDown = { 0.030, 0.034, 0.040, 0.98 },
        closeBg = { 0.20, 0.045, 0.040, 0.95 },
        closeBorder = { 0.84, 0.32, 0.22, 0.95 },
        rowOdd = { 0.065, 0.072, 0.080, 0.35 },
        rowEven = { 0.034, 0.038, 0.044, 0.18 },
        rowHover = { 0.72, 0.84, 0.92, 0.12 },
        blueText = { 0.78, 0.88, 0.94 },
        titleText = { 0.84, 0.92, 0.96 },
        buttonText = { 0.90, 0.95, 0.98 },
        mutedText = { 0.74, 0.80, 0.84 },
        disabledText = { 0.48, 0.52, 0.56 },
        disabledBorder = { 0.20, 0.22, 0.24, 0.90 },
        inputBg = { 0.034, 0.038, 0.044, 0.96 },
        inputText = { 0.92, 0.96, 0.98 },
        rowFill = { 0.72, 0.84, 0.92, 0.10 },
        listHeaderBg = { 0.052, 0.060, 0.070, 0.72 },
        paperIcon = { 0.88, 0.94, 0.98, 1.00 },
    },
}

local function CopyColor(color)
    if type(color) ~= "table" then
        return color
    end

    return { color[1], color[2], color[3], color[4] }
end

local function NormalizeColorThemeKey(themeKey)
    themeKey = string.lower(tostring(themeKey or DEFAULT_COLOR_THEME))

    if SKIN_THEMES[themeKey] then
        return themeKey
    end

    return DEFAULT_COLOR_THEME
end

local function ApplyColorThemeToSkin(themeKey)
    themeKey = NormalizeColorThemeKey(themeKey)

    local theme = SKIN_THEMES[themeKey] or SKIN_THEMES[DEFAULT_COLOR_THEME]
    for key, value in pairs(theme) do
        if key ~= "label" then
            SKIN[key] = CopyColor(value)
        end
    end

    return themeKey
end

local DEFAULT_SCALE = 0.92
local MAIN_FRAME_WIDTH = 740
local MAIN_FRAME_HEIGHT = 600
local QUICK_WITHDRAW_WIDTH = 470
local ROW_COUNT = 15
local ROW_HEIGHT = 24
local ROW_SPACING = 2
local REQUEST_TIMEOUT_SECONDS = 8.0
local MUTATION_REFRESH_DELAY = 0.85
local ITEM_CACHE_REFRESH_INTERVAL = 0.35
local ITEM_CACHE_REFRESH_TIMEOUT = 8.0
local AUTO_DEPOSIT_AFTER_CLOSE_DELAY = 0.80
local AUTO_DEPOSIT_PREP_EXPIRE_SECONDS = 300
local AUTO_DEPOSIT_TICKER_DEFAULT_SECONDS = 0
local AUTO_DEPOSIT_TICKER_MIN_SECONDS = 30
local AUTO_DEPOSIT_TICKER_MAX_SECONDS = 3600
local AUTO_DEPOSIT_TICKER_RETRY_DELAY = 10
local TRANSACTION_MAX_PAIRS_PER_COMMAND = 10
local TRANSACTION_CHAT_ITEM_LIMIT = 6
local TRADE_SKILL_PREPARE_COUNT_MIN = 1
local TRADE_SKILL_PREPARE_COUNT_MAX = 999
local DEPOSIT_PREVIEW_ROW_COUNT = 10
local TRADE_SKILL_CHECK_TIMEOUT = 2.0

-- Main window top action button placement.
-- Change these to move/resize Deposit All, Withdraw All, and Refresh.
local ROOT_BUTTON_ROW_X = 18
local ROOT_BUTTON_ROW_Y = -60
local ROOT_ACTION_BUTTON_WIDTH = 118
local ROOT_REFRESH_BUTTON_WIDTH = 96
local ROOT_SORT_BUTTON_WIDTH = 98
local ROOT_PREVIEW_TOGGLE_BUTTON_WIDTH = 112
local ROOT_BUTTON_HEIGHT = 24
local ROOT_BUTTON_GAP = 8
local ROOT_HELP_TEXT_GAP = 12
local UNDO_BUTTON_WIDTH = 128

-- Category/detail navigation button placement.
-- Change these to move/resize Categories, Deposit Category, Withdraw Category, Prev, and Next.
local CATEGORY_BUTTON_ROW_X = 18
local CATEGORY_BUTTON_ROW_Y = -90
local CATEGORY_BACK_BUTTON_WIDTH = 96
local CATEGORY_ACTION_BUTTON_WIDTH = 148
local CATEGORY_PAGE_BUTTON_WIDTH = 72
local CATEGORY_BUTTON_HEIGHT = 24
local CATEGORY_BUTTON_GAP = 8
local CATEGORY_PAGE_TEXT_GAP = 10

-- PaperDoll toggle button placement/style.
-- Uses the same round minimap-style art as the PaperDollAHButton example.
-- Primary position: immediately to the right of PaperDollAHButton.
-- Fallback position is used if PaperDollAHButton is not loaded yet.
local PAPERDOLL_BUTTON_ENABLED = true
local PAPERDOLL_BUTTON_PARENT = "PaperDollFrame"
local PAPERDOLL_ANCHOR_BUTTON_NAME = "PaperDollAHButton"
local PAPERDOLL_BUTTON_GAP = 2

-- Fallback: this matches the AH button's sample position and places this button
-- directly to the right of it: AH TOPRIGHT is -324, -474; this TOPLEFT is -322, -474.
local PAPERDOLL_BUTTON_FALLBACK_POINT = "TOPLEFT"
local PAPERDOLL_BUTTON_FALLBACK_RELATIVE_POINT = "TOPRIGHT"
local PAPERDOLL_BUTTON_FALLBACK_X = -322
local PAPERDOLL_BUTTON_FALLBACK_Y = -474

local PAPERDOLL_BUTTON_SIZE = 32
local PAPERDOLL_BUTTON_ICON = "Interface\\Icons\\INV_Misc_Bag_10"
local PAPERDOLL_BUTTON_ICON_SIZE = 17
local PAPERDOLL_BUTTON_ICON_CROP = 0.08

local PAPERDOLL_BUTTON_BG_TEXTURE = "Interface\\Minimap\\MiniMap-TrackingBackground"
local PAPERDOLL_BUTTON_BG_SIZE = 20
local PAPERDOLL_BUTTON_BG_R = 0.15
local PAPERDOLL_BUTTON_BG_G = 0.15
local PAPERDOLL_BUTTON_BG_B = 0.15
local PAPERDOLL_BUTTON_BG_A = 0.95

local PAPERDOLL_BUTTON_BORDER_TEXTURE = "Interface\\Minimap\\MiniMap-TrackingBorder"
local PAPERDOLL_BUTTON_BORDER_SIZE = 54

local PAPERDOLL_BUTTON_HIGHLIGHT_TEXTURE = "Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight"
local PAPERDOLL_BUTTON_HIGHLIGHT_SIZE = 52

local PAPERDOLL_LAUNCHER_DOCK_VERSION = 20260518

local function EnsurePaperDollLauncherDock()
    local dock = _G.PaperDollLauncherDock
    if type(dock) ~= "table" then
        dock = {}
        _G.PaperDollLauncherDock = dock
    end

    dock.entries = dock.entries or {}

    if (tonumber(dock.version) or 0) >= PAPERDOLL_LAUNCHER_DOCK_VERSION and dock.Register and dock.Layout then
        return dock
    end

    dock.version = PAPERDOLL_LAUNCHER_DOCK_VERSION
    dock.startPoint = "TOPRIGHT"
    dock.startRelativePoint = "TOPRIGHT"
    dock.startX = -324
    dock.startY = -464
    dock.gap = 2

    function dock:GetParentFrame()
        return _G.PaperDollFrame or _G.CharacterFrame or UIParent
    end

    function dock:InstallHooks()
        self.hookedParents = self.hookedParents or {}

        local candidates = { _G.PaperDollFrame, _G.CharacterFrame }
        for _, parent in ipairs(candidates) do
            if parent and parent.HookScript and not self.hookedParents[parent] then
                parent:HookScript("OnShow", function()
                    if _G.PaperDollLauncherDock and _G.PaperDollLauncherDock.Layout then
                        _G.PaperDollLauncherDock:Layout()
                    end
                end)
                self.hookedParents[parent] = true
            end
        end

        if not self.eventFrame then
            self.eventFrame = CreateFrame("Frame")
            self.eventFrame:RegisterEvent("PLAYER_LOGIN")
            self.eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
            self.eventFrame:RegisterEvent("ADDON_LOADED")
            self.eventFrame:SetScript("OnEvent", function()
                if _G.PaperDollLauncherDock and _G.PaperDollLauncherDock.Layout then
                    _G.PaperDollLauncherDock:Layout()
                end
            end)
        end
    end

    function dock:Register(id, button, order)
        if not id or not button then
            return
        end

        self.entries = self.entries or {}
        self.entries[id] = self.entries[id] or {}
        self.entries[id].button = button
        self.entries[id].order = tonumber(order) or 1000

        button.PaperDollLauncherDockID = id

        self:InstallHooks()
        self:Layout()
    end

    function dock:Unregister(id)
        if self.entries then
            self.entries[id] = nil
        end

        self:Layout()
    end

    function dock:Layout()
        self:InstallHooks()

        local parent = self:GetParentFrame()
        local buttons = {}

        for id, entry in pairs(self.entries or {}) do
            if entry and entry.button then
                table.insert(buttons, {
                    id = id,
                    button = entry.button,
                    order = tonumber(entry.order) or 1000,
                })
            end
        end

        table.sort(buttons, function(a, b)
            if a.order == b.order then
                return tostring(a.id) < tostring(b.id)
            end

            return a.order < b.order
        end)

        local previousButton = nil

        for _, entry in ipairs(buttons) do
            local button = entry.button

            if button.SetParent and button:GetParent() ~= parent then
                button:SetParent(parent)
            end

            if button.SetMovable then
                button:SetMovable(false)
            end

            if button.SetClampedToScreen then
                button:SetClampedToScreen(false)
            end

            if button.SetFrameLevel and parent and parent.GetFrameLevel then
                button:SetFrameLevel((parent:GetFrameLevel() or 1) + 12)
            end

            button:ClearAllPoints()

            if previousButton then
                button:SetPoint("LEFT", previousButton, "RIGHT", self.gap, 0)
            else
                button:SetPoint(self.startPoint, parent, self.startRelativePoint, self.startX, self.startY)
            end

            button:Show()
            previousButton = button
        end
    end

    dock:InstallHooks()
    return dock
end

local function Trim(text)
    if not text then
        return ""
    end

    text = tostring(text)
    text = string.gsub(text, "^%s+", "")
    text = string.gsub(text, "%s+$", "")
    return text
end

local function Clamp(value, minValue, maxValue)
    value = tonumber(value) or minValue

    if value < minValue then
        return minValue
    end

    if value > maxValue then
        return maxValue
    end

    return value
end

local function SplitColon(text)
    local parts = {}

    for part in string.gmatch(text or "", "([^:]+)") do
        table.insert(parts, part)
    end

    return parts
end

local function FormatCount(value)
    value = tonumber(value) or 0

    if value >= 1000000 then
        return string.format("%.1fm", value / 1000000)
    end

    if value >= 10000 then
        return string.format("%.1fk", value / 1000)
    end

    return tostring(value)
end

local function GetItemDisplay(itemEntry)
    itemEntry = tonumber(itemEntry)
    if not itemEntry then
        return "Interface\\Icons\\INV_Misc_QuestionMark", "Unknown item", nil, 1, false
    end

    local name, link, quality, itemLevel, minLevel, itemType, itemSubType, stackCount, equipLoc, icon = GetItemInfo(itemEntry)
    local missingInfo = name == nil or link == nil

    if not icon then
        icon = GetItemIcon(itemEntry)
    end

    if not name then
        name = "Item #" .. tostring(itemEntry)
    end

    stackCount = tonumber(stackCount) or 1
    if stackCount < 1 then
        stackCount = 1
    end

    return icon or "Interface\\Icons\\INV_Misc_QuestionMark", name, link, stackCount, missingInfo
end

local function HideTooltip()
    if GameTooltip and GameTooltip:IsShown() then
        GameTooltip:Hide()
    end
end

local function SetTooltipItem(itemEntry)
    itemEntry = tonumber(itemEntry)
    if not itemEntry then
        return
    end

    GameTooltip:SetOwner(UIParent, "ANCHOR_CURSOR")
    GameTooltip:SetHyperlink("item:" .. tostring(itemEntry) .. ":0:0:0:0:0:0:0")
    GameTooltip:Show()
end

local function ParseItemIdFromLink(link)
    if not link then
        return nil
    end

    local itemId = string.match(link, "item:(%d+):")
    return tonumber(itemId)
end

local function AddAmountToMap(map, itemEntry, amount)
    if type(map) ~= "table" then
        return false
    end

    itemEntry = tonumber(itemEntry)
    amount = math.floor(tonumber(amount) or 0)

    if not itemEntry or itemEntry <= 0 or amount <= 0 then
        return false
    end

    itemEntry = math.floor(itemEntry)
    map[itemEntry] = (tonumber(map[itemEntry]) or 0) + amount
    return true
end

local function AmountMapHasItems(map)
    if type(map) ~= "table" then
        return false
    end

    for itemEntry, amount in pairs(map) do
        if tonumber(itemEntry) and (tonumber(amount) or 0) > 0 then
            return true
        end
    end

    return false
end

local function AmountMapTotal(map)
    local total = 0

    if type(map) ~= "table" then
        return total
    end

    for _, amount in pairs(map) do
        total = total + math.max(0, math.floor(tonumber(amount) or 0))
    end

    return total
end

local function BuildSortedItemsFromAmountMap(map)
    local items = {}

    if type(map) ~= "table" then
        return items
    end

    for itemEntry, amount in pairs(map) do
        itemEntry = tonumber(itemEntry)
        amount = math.floor(tonumber(amount) or 0)

        if itemEntry and itemEntry > 0 and amount > 0 then
            table.insert(items, {
                entry = math.floor(itemEntry),
                amount = amount,
            })
        end
    end

    table.sort(items, function(a, b)
        return (tonumber(a.entry) or 0) < (tonumber(b.entry) or 0)
    end)

    return items
end

local function PrintAddon(message)
    if DEFAULT_CHAT_FRAME then
        DEFAULT_CHAT_FRAME:AddMessage("|cff33ff99ReagentBankUI|r " .. tostring(message or ""))
    end
end

local function GetItemChatText(itemEntry)
    local icon, name, link = GetItemDisplay(itemEntry)

    if link and link ~= "" then
        return link
    end

    return name or ("Item #" .. tostring(itemEntry or 0))
end

local function BuildItemAmountChatText(itemEntry, amount)
    amount = math.floor(tonumber(amount) or 0)
    return tostring(amount) .. "x " .. GetItemChatText(itemEntry)
end

local function SafeTransactionSource(source)
    source = string.lower(tostring(source or "manual"))

    if source == "profession" or source == "reverse" or source == "manual" or source == "auto" then
        return source
    end

    return "manual"
end

local function SafeTransactionLabel(label)
    label = Trim(label or "")

    if label == "" then
        return nil
    end

    return label
end

local function SafeDate()
    if date then
        return date("%H:%M:%S")
    end

    return "now"
end

local function NormalizeItemSortMode(mode)
    mode = string.lower(tostring(mode or "id"))

    if mode == "name" or mode == "alpha" or mode == "alphabetical" then
        return "name"
    end

    if mode == "amount" or mode == "amount_desc" or mode == "count" or mode == "count_desc" then
        return "amount"
    end

    if mode == "amount_asc" or mode == "count_asc" then
        return "amount_asc"
    end

    return "id"
end

local function NormalizeCategorySortMode(mode)
    mode = string.lower(tostring(mode or "order"))

    if mode == "name" then
        return "name"
    end

    if mode == "amount" or mode == "amount_desc" or mode == "total" then
        return "amount"
    end

    if mode == "types" or mode == "types_desc" then
        return "types"
    end

    return "order"
end

local function ItemSortLabel(mode)
    mode = NormalizeItemSortMode(mode)

    if mode == "name" then
        return "Sort: Name"
    elseif mode == "amount" then
        return "Sort: Most"
    elseif mode == "amount_asc" then
        return "Sort: Least"
    end

    return "Sort: ID"
end

local function CategorySortLabel(mode)
    mode = NormalizeCategorySortMode(mode)

    if mode == "name" then
        return "Sort: Name"
    elseif mode == "amount" then
        return "Sort: Total"
    elseif mode == "types" then
        return "Sort: Types"
    end

    return "Sort: Default"
end

local function CycleItemSortMode(mode)
    mode = NormalizeItemSortMode(mode)

    if mode == "id" then
        return "name"
    elseif mode == "name" then
        return "amount"
    elseif mode == "amount" then
        return "amount_asc"
    end

    return "id"
end

local function CycleCategorySortMode(mode)
    mode = NormalizeCategorySortMode(mode)

    if mode == "order" then
        return "amount"
    elseif mode == "amount" then
        return "types"
    elseif mode == "types" then
        return "name"
    end

    return "order"
end

local function TableValueCount(tbl)
    local count = 0
    for _ in pairs(tbl or {}) do
        count = count + 1
    end
    return count
end

local function SetTextureColor(texture, color, alphaOverride)
    if not texture or type(color) ~= "table" then
        return
    end

    texture:SetVertexColor(color[1] or 1, color[2] or 1, color[3] or 1, alphaOverride or color[4] or 1)
end

local function SetFontColor(fontString, color)
    if not fontString or type(color) ~= "table" then
        return
    end

    fontString:SetTextColor(color[1] or 1, color[2] or 1, color[3] or 1, color[4] or 1)
end

local function SetFrameBackdropColors(frame, bgColor, borderColor, alphaOverride)
    if not frame then
        return
    end

    if frame.SetBackdropColor and type(bgColor) == "table" then
        frame:SetBackdropColor(bgColor[1] or 0, bgColor[2] or 0, bgColor[3] or 0, alphaOverride or bgColor[4] or 1)
    end

    if frame.SetBackdropBorderColor and type(borderColor) == "table" then
        frame:SetBackdropBorderColor(borderColor[1] or 1, borderColor[2] or 1, borderColor[3] or 1, borderColor[4] or 1)
    end
end

function RB:GetColorThemeKey()
    ReagentBankUIDB = ReagentBankUIDB or {}
    ReagentBankUIDB.colorTheme = NormalizeColorThemeKey(ReagentBankUIDB.colorTheme)
    return ReagentBankUIDB.colorTheme
end

function RB:GetColorThemeLabel(themeKey)
    themeKey = NormalizeColorThemeKey(themeKey)
    local theme = SKIN_THEMES[themeKey]
    return theme and theme.label or "Classic Gold"
end

function RB:ApplySavedColorTheme()
    ReagentBankUIDB = ReagentBankUIDB or {}
    ReagentBankUIDB.colorTheme = ApplyColorThemeToSkin(ReagentBankUIDB.colorTheme)
    return ReagentBankUIDB.colorTheme
end

function RB:SetColorTheme(themeKey, silent)
    ReagentBankUIDB = ReagentBankUIDB or {}
    themeKey = ApplyColorThemeToSkin(themeKey)
    ReagentBankUIDB.colorTheme = themeKey

    self:ApplySkin()
    self:UpdateColorSettingsFrame()

    if not silent then
        local label = self:GetColorThemeLabel(themeKey)
        PrintAddon("color schema set to " .. label .. ".")
        self:Status("Color schema set to " .. label .. ".", 0.82, 0.82, 0.82)
    end
end

function RB:CycleColorTheme()
    local current = self:GetColorThemeKey()
    local nextKey = SKIN_THEME_ORDER[1] or DEFAULT_COLOR_THEME

    for index, themeKey in ipairs(SKIN_THEME_ORDER) do
        if themeKey == current then
            nextKey = SKIN_THEME_ORDER[index + 1] or SKIN_THEME_ORDER[1] or DEFAULT_COLOR_THEME
            break
        end
    end

    self:SetColorTheme(nextKey)
end

function RB:StyleButton(button)
    if not button then
        return
    end

    SetFrameBackdropColors(button, SKIN.buttonBg, SKIN.buttonBorder)

    if button.shine then
        SetTextureColor(button.shine, SKIN.headerLine, 0.15)
    end

    if button.hover then
        SetTextureColor(button.hover, SKIN.buttonHover)
    end

    if button.label then
        SetFontColor(button.label, SKIN.buttonText)
    end
end

function RB:StyleCloseButton(button)
    if not button then
        return
    end

    SetFrameBackdropColors(button, SKIN.closeBg, SKIN.closeBorder)

    if button.hover then
        button.hover:SetVertexColor(1.00, 0.18, 0.12, 0.25)
    end

    if button.label then
        button.label:SetTextColor(1.00, 0.76, 0.58)
    end
end

function RB:StyleEditBox(box)
    if not box then
        return
    end

    SetFrameBackdropColors(box, SKIN.inputBg, SKIN.buttonBorder)
    if box.SetTextColor then
        box:SetTextColor(SKIN.inputText[1], SKIN.inputText[2], SKIN.inputText[3], SKIN.inputText[4] or 1)
    end
end

function RB:StylePaperDollButton()
    local button = self.paperDollButton
    if not button then
        return
    end

    if button.bg then
        button.bg:SetVertexColor(SKIN.buttonBg[1], SKIN.buttonBg[2], SKIN.buttonBg[3], 0.95)
    end

    if button.icon then
        SetTextureColor(button.icon, SKIN.paperIcon or { 1, 1, 1, 1 })
    end

    if button.border then
        SetTextureColor(button.border, SKIN.windowBorder)
    end

    local highlight = button.GetHighlightTexture and button:GetHighlightTexture()
    if highlight then
        SetTextureColor(highlight, SKIN.buttonHover)
    end
end

function RB:ApplySkin()
    local f = self.frame

    if f then
        self:MakeBackdrop(f, 0.98)

        SetFrameBackdropColors(f.header, SKIN.headerBg, SKIN.windowBorder)
        SetTextureColor(f.headerGlow, SKIN.headerLine, 0.10)
        SetTextureColor(f.headerLine, SKIN.headerLine)
        SetFontColor(f.title, SKIN.titleText)
        SetFontColor(f.modeText, SKIN.mutedText)

        self:StyleCloseButton(f.close)

        local buttons = {
            f.rootDeposit, f.rootWithdraw, f.refresh, f.sortMode, f.previewToggle,
            f.back, f.catDeposit, f.catWithdraw, f.prev, f.next,
            f.withdrawOne, f.withdrawStack, f.withdrawItemAll, f.withdrawExact, f.detailBack,
            f.undoLast, f.quickWithdrawButton, f.quickWithdrawAll, f.quickWithdrawCancel,
        }

        if f.depositPreview then
            table.insert(buttons, f.depositPreview.confirm)
            table.insert(buttons, f.depositPreview.cancel)
        end

        for _, button in ipairs(buttons) do
            self:StyleButton(button)
        end

        self:StyleCloseButton(f.quickWithdrawClose)
        if f.depositPreview then
            self:StyleCloseButton(f.depositPreview.close)
        end

        self:StyleEditBox(f.exactBox)
        self:StyleEditBox(f.quickWithdrawBox)

        self:MakeBackdrop(f.list, 0.78, true)
        self:MakeBackdrop(f.detail, 0.78, true)
        self:MakeBackdrop(f.footer, 0.58, true)
        self:MakeBackdrop(f.quickWithdraw, 0.98, true)
        if f.depositPreview then
            self:MakeBackdrop(f.depositPreview, 0.98, true)
        end

        SetFrameBackdropColors(f.detailIconBorder, { 0.02, 0.02, 0.03, 0.90 }, SKIN.buttonBorder)

        if f.listHeader then
            SetTextureColor(f.listHeader.bg, SKIN.listHeaderBg)
            SetTextureColor(f.listHeader.line, SKIN.headerLine, 0.70)
        end

        SetFontColor(f.headerName, SKIN.buttonText)
        SetFontColor(f.headerCount, SKIN.buttonText)
        SetFontColor(f.pageText, SKIN.mutedText)
        SetFontColor(f.helpText, SKIN.mutedText)
        SetFontColor(f.status, SKIN.mutedText)
        SetFontColor(f.detailName, SKIN.titleText)
        SetFontColor(f.detailHint, SKIN.mutedText)
        SetFontColor(f.exactLabel, SKIN.buttonText)
        SetFontColor(f.quickWithdrawTitle, SKIN.titleText)
        SetFontColor(f.quickWithdrawName, SKIN.buttonText)
        SetFontColor(f.quickWithdrawStored, SKIN.mutedText)
        SetFontColor(f.quickWithdrawLabel, SKIN.buttonText)
        SetFontColor(f.quickWithdrawHint, SKIN.mutedText)

        if f.depositPreview then
            SetFontColor(f.depositPreview.title, SKIN.titleText)
            SetFontColor(f.depositPreview.summary, SKIN.mutedText)
            if f.depositPreview.rows then
                for _, row in ipairs(f.depositPreview.rows) do
                    SetFontColor(row.name or row.text, SKIN.buttonText)
                    SetFontColor(row.count, SKIN.blueText)
                end
            end
        end

        if f.rows then
            for index, row in ipairs(f.rows) do
                if (index % 2) == 0 then
                    SetTextureColor(row.bg, SKIN.rowEven)
                else
                    SetTextureColor(row.bg, SKIN.rowOdd)
                end
                SetTextureColor(row.fill, SKIN.rowFill)
                SetTextureColor(row.hover, SKIN.rowHover)
                SetFontColor(row.count, SKIN.blueText)
            end
        end
    end

    self:StylePaperDollButton()

    if self.tradeSkillButton then
        self:StyleButton(self.tradeSkillButton)
    end

    if self.tradeSkillMinusButton then
        self:StyleButton(self.tradeSkillMinusButton)
    end

    if self.tradeSkillPlusButton then
        self:StyleButton(self.tradeSkillPlusButton)
    end

    if self.tradeSkillQuantityBox then
        self:StyleEditBox(self.tradeSkillQuantityBox)
    end

    SetFontColor(self.tradeSkillQuantityLabel, SKIN.buttonText)
    SetFontColor(self.tradeSkillStatsText, SKIN.mutedText)

    if self.colorSettingsFrame then
        local settings = self.colorSettingsFrame
        self:MakeBackdrop(settings, 0.98, true)
        SetFontColor(settings.title, SKIN.titleText)
        SetFontColor(settings.note, SKIN.mutedText)
        self:StyleCloseButton(settings.close)
        if settings.themeButtons then
            for _, button in ipairs(settings.themeButtons) do
                self:StyleButton(button)
            end
        end
        self:StyleButton(settings.cycle)
        self:StyleButton(settings.reset)
        self:StyleButton(settings.autoDepositApply)
        self:StyleButton(settings.autoDepositOff)
        self:StyleEditBox(settings.autoDepositIntervalBox)
        SetFontColor(settings.themeHeader, SKIN.titleText)
        SetFontColor(settings.autoDepositHeader, SKIN.titleText)
        SetFontColor(settings.autoDepositNote, SKIN.mutedText)
        SetFontColor(settings.autoDepositLabel, SKIN.mutedText)
        SetFontColor(settings.autoDepositStatus, SKIN.mutedText)
    end
end

function RB:MakeBackdrop(frame, alpha, panel)
    if panel then
        frame:SetBackdrop(PANEL_BACKDROP)
        frame:SetBackdropColor(SKIN.panelBg[1], SKIN.panelBg[2], SKIN.panelBg[3], alpha or SKIN.panelBg[4])
        frame:SetBackdropBorderColor(SKIN.panelBorder[1], SKIN.panelBorder[2], SKIN.panelBorder[3], SKIN.panelBorder[4])
        return
    end

    frame:SetBackdrop(BACKDROP)
    frame:SetBackdropColor(SKIN.windowBg[1], SKIN.windowBg[2], SKIN.windowBg[3], alpha or SKIN.windowBg[4])
    frame:SetBackdropBorderColor(SKIN.windowBorder[1], SKIN.windowBorder[2], SKIN.windowBorder[3], SKIN.windowBorder[4])
end

function RB:SetButtonEnabled(button, enabled)
    if not button then
        return
    end

    if enabled then
        button:Enable()
        button:SetAlpha(1.0)
        if button.label then
            SetFontColor(button.label, SKIN.buttonText)
        end
        if button.SetBackdropBorderColor then
            button:SetBackdropBorderColor(SKIN.buttonBorder[1], SKIN.buttonBorder[2], SKIN.buttonBorder[3], SKIN.buttonBorder[4])
        end
    else
        button:Disable()
        button:SetAlpha(0.48)
        if button.label then
            SetFontColor(button.label, SKIN.disabledText)
        end
        if button.SetBackdropBorderColor then
            button:SetBackdropBorderColor(SKIN.disabledBorder[1], SKIN.disabledBorder[2], SKIN.disabledBorder[3], SKIN.disabledBorder[4])
        end
    end
end

function RB:Status(text, r, g, b)
    self.lastStatus = text

    if self.frame and self.frame.status then
        self.frame.status:SetText(text or "")
        self.frame.status:SetTextColor(r or 0.70, g or 0.70, b or 0.70)
    end
end

function RB:EnsureOnUpdate()
    self:SetScript("OnUpdate", function(frame, elapsed)
        frame:OnUpdate(elapsed)
    end)
end

function RB:BeginBusy(kind, text)
    self.busyKind = kind or "request"
    self.busyText = text or "Working..."
    self.busyStartedAt = GetTime()

    self:Status(self.busyText, 0.82, 0.82, 0.82)
    self:UpdateControls()
    self:EnsureOnUpdate()
end

function RB:ClearBusy(text, r, g, b)
    self.busyKind = nil
    self.busyText = nil
    self.busyStartedAt = nil

    self:UpdateControls()

    if text then
        self:Status(text, r or 0.45, g or 1.00, b or 0.45)
    end
end

function RB:ScheduleRefresh(delay, view, categoryId, page)
    delay = tonumber(delay) or MUTATION_REFRESH_DELAY

    self.pendingRefresh = {
        at = GetTime() + delay,
        view = view or self.currentView or "root",
        categoryId = categoryId or self.currentCategoryId,
        page = page or self.currentPage or 0,
    }

    self:EnsureOnUpdate()
end

function RB:ScheduleCurrentRefresh(delay)
    if self.currentView == "category" or self.currentView == "detail" then
        if self.currentCategoryId then
            self:ScheduleRefresh(delay, "category", self.currentCategoryId, self.currentPage or 0)
            return
        end
    end

    self:ScheduleRefresh(delay, "root", nil, 0)
end

function RB:QueueItemInfoRefresh()
    local now = GetTime()

    if not self.itemInfoRefreshStartedAt then
        self.itemInfoRefreshStartedAt = now
    end

    self.nextItemInfoRefreshAt = now + ITEM_CACHE_REFRESH_INTERVAL
    self:EnsureOnUpdate()
end

function RB:ClearItemInfoRefresh()
    self.itemInfoRefreshStartedAt = nil
    self.nextItemInfoRefreshAt = nil
end

function RB:RefreshItemInfoIfNeeded()
    self.nextItemInfoRefreshAt = nil

    if not self.frame or not self.frame:IsShown() then
        self:ClearItemInfoRefresh()
        return
    end

    if self.itemInfoRefreshStartedAt and GetTime() - self.itemInfoRefreshStartedAt >= ITEM_CACHE_REFRESH_TIMEOUT then
        self:ClearItemInfoRefresh()
        return
    end

    if self.depositPreview and self.frame.depositPreview and self.frame.depositPreview:IsShown() then
        self:ShowDepositPreview(self.depositPreview)
        return
    end

    if self.currentView == "category" and self.currentCategoryId then
        self:RenderCategory(true)
        return
    end

    if self.currentView == "detail" and self.detailItem then
        self:ShowDetail(self.detailItem, true)
        return
    end

    self:ClearItemInfoRefresh()
end

function RB:OnUpdate(elapsed)
    local now = GetTime()

    if self.pendingAutoDepositAt and now >= self.pendingAutoDepositAt then
        self.pendingAutoDepositAt = nil
        self:DepositPreparedLeftovers()
    end

    self:RunAutoDepositTicker(now)

    if self.pendingRefresh and now >= self.pendingRefresh.at then
        local refresh = self.pendingRefresh
        self.pendingRefresh = nil

        if refresh.view == "category" and refresh.categoryId then
            self:RequestCategory(refresh.categoryId, refresh.page or 0)
        else
            self:RequestRoot()
        end

        return
    end

    if self.nextItemInfoRefreshAt and now >= self.nextItemInfoRefreshAt then
        self:RefreshItemInfoIfNeeded()
    end

    if self.busyStartedAt and now - self.busyStartedAt >= REQUEST_TIMEOUT_SECONDS then
        self:ClearBusy("No server data yet. Press Refresh to try again.", 1.00, 0.82, 0.32)
    end

    if not self.pendingRefresh and not self.busyStartedAt and not self.pendingAutoDepositAt and not self.nextItemInfoRefreshAt and not self.nextAutoDepositTickerAt then
        self:SetScript("OnUpdate", nil)
    end
end

function RB:QueueTransactionContext(action, source, label)
    action = self:NormalizeTransactionAction(action)
    if not action then
        return
    end

    self.pendingTransactionContexts = self.pendingTransactionContexts or {}
    table.insert(self.pendingTransactionContexts, {
        action = action,
        source = SafeTransactionSource(source),
        label = SafeTransactionLabel(label),
        queuedAt = GetTime(),
    })

    while #self.pendingTransactionContexts > 20 do
        table.remove(self.pendingTransactionContexts, 1)
    end
end

function RB:TakeTransactionContext(action)
    action = self:NormalizeTransactionAction(action)
    if not action or not self.pendingTransactionContexts then
        return nil
    end

    local now = GetTime()
    local index = 1
    while index <= #self.pendingTransactionContexts do
        local context = self.pendingTransactionContexts[index]

        if context and context.queuedAt and now - context.queuedAt > 12.0 then
            table.remove(self.pendingTransactionContexts, index)
        elseif context and context.action == action then
            table.remove(self.pendingTransactionContexts, index)
            return context
        else
            index = index + 1
        end
    end

    return nil
end

function RB:SendServerCommand(command, transactionContext)
    command = Trim(command or "")

    if command == "" then
        command = "open"
    end

    if transactionContext then
        self:QueueTransactionContext(
            transactionContext.action,
            transactionContext.source,
            transactionContext.label
        )
    end

    SendChatMessage(COMMAND_PREFIX .. " " .. command, "SAY")
end

function RB:GetItemSortMode()
    ReagentBankUIDB = ReagentBankUIDB or {}
    ReagentBankUIDB.sortMode = NormalizeItemSortMode(ReagentBankUIDB.sortMode)
    return ReagentBankUIDB.sortMode
end

function RB:GetCategorySortMode()
    ReagentBankUIDB = ReagentBankUIDB or {}
    ReagentBankUIDB.categorySortMode = NormalizeCategorySortMode(ReagentBankUIDB.categorySortMode)
    return ReagentBankUIDB.categorySortMode
end

function RB:IsDepositPreviewEnabled()
    ReagentBankUIDB = ReagentBankUIDB or {}

    if ReagentBankUIDB.depositPreviewEnabled == nil then
        ReagentBankUIDB.depositPreviewEnabled = true
    end

    return ReagentBankUIDB.depositPreviewEnabled ~= false
end

function RB:SetDepositPreviewEnabled(enabled, silent)
    ReagentBankUIDB = ReagentBankUIDB or {}
    ReagentBankUIDB.depositPreviewEnabled = enabled and true or false

    if not ReagentBankUIDB.depositPreviewEnabled then
        self:HideDepositPreview()
    end

    self:UpdatePreviewToggleButton()

    if not silent then
        PrintAddon("deposit preview confirmation " .. (ReagentBankUIDB.depositPreviewEnabled and "enabled." or "disabled."))
        self:Status("Deposit preview confirmation " .. (ReagentBankUIDB.depositPreviewEnabled and "enabled." or "disabled."), 0.82, 0.82, 0.82)
    end
end

function RB:ToggleDepositPreviewEnabled()
    self:SetDepositPreviewEnabled(not self:IsDepositPreviewEnabled())
end

function RB:ClampAutoDepositTickerSeconds(seconds)
    seconds = math.floor(tonumber(seconds) or AUTO_DEPOSIT_TICKER_DEFAULT_SECONDS)

    if seconds <= 0 then
        return 0
    end

    return Clamp(seconds, AUTO_DEPOSIT_TICKER_MIN_SECONDS, AUTO_DEPOSIT_TICKER_MAX_SECONDS)
end

function RB:GetAutoDepositTickerSeconds()
    ReagentBankUIDB = ReagentBankUIDB or {}
    ReagentBankUIDB.autoDepositTickerSeconds = self:ClampAutoDepositTickerSeconds(ReagentBankUIDB.autoDepositTickerSeconds)
    return ReagentBankUIDB.autoDepositTickerSeconds
end

function RB:IsAutoDepositTickerEnabled()
    return self:GetAutoDepositTickerSeconds() > 0
end

function RB:RestartAutoDepositTicker()
    local seconds = self:GetAutoDepositTickerSeconds()

    if seconds > 0 then
        self.nextAutoDepositTickerAt = GetTime() + seconds
        self:EnsureOnUpdate()
    else
        self.nextAutoDepositTickerAt = nil
        self.autoDepositQuietUntil = nil
        self.autoDepositSuppressViewUntil = nil
    end
end

function RB:SetAutoDepositTickerSeconds(seconds, silent)
    ReagentBankUIDB = ReagentBankUIDB or {}
    seconds = self:ClampAutoDepositTickerSeconds(seconds)
    ReagentBankUIDB.autoDepositTickerSeconds = seconds

    self:RestartAutoDepositTicker()
    self:UpdateAutoDepositTickerControls()

    if not silent then
        if seconds > 0 then
            PrintAddon("periodic auto-deposit enabled every " .. tostring(seconds) .. " second(s).")
            self:Status("Periodic auto-deposit every " .. tostring(seconds) .. " second(s).", 0.82, 0.82, 0.82)
        else
            PrintAddon("periodic auto-deposit disabled.")
            self:Status("Periodic auto-deposit disabled.", 0.82, 0.82, 0.82)
        end
    end
end


function RB:DisableAutoDepositTickerForProfessionWithdraw()
    if not self:IsAutoDepositTickerEnabled() then
        return
    end

    self:SetAutoDepositTickerSeconds(0, true)
    PrintAddon("periodic auto-deposit disabled because you withdrew reagents for a profession recipe.")

    if self.frame and self.frame:IsShown() then
        self:Status("Periodic auto-deposit disabled for profession reagent prep.", 1.00, 0.82, 0.32)
    end
end

function RB:ApplyAutoDepositTickerBox(silent)
    if not self.colorSettingsFrame or not self.colorSettingsFrame.autoDepositIntervalBox then
        return
    end

    local text = Trim(self.colorSettingsFrame.autoDepositIntervalBox:GetText() or "")
    local seconds = tonumber(text) or 0
    self:SetAutoDepositTickerSeconds(seconds, silent)
end

function RB:UpdateAutoDepositTickerControls()
    local frame = self.colorSettingsFrame
    if not frame then
        return
    end

    local seconds = self:GetAutoDepositTickerSeconds()

    if frame.autoDepositIntervalBox then
        local desiredText = tostring(seconds)
        if frame.autoDepositIntervalBox:GetText() ~= desiredText then
            frame.autoDepositIntervalBox:SetText(desiredText)
        end
    end

    if frame.autoDepositStatus then
        if seconds > 0 then
            frame.autoDepositStatus:SetText("Enabled: Deposit All runs every " .. tostring(seconds) .. " second(s).")
        else
            frame.autoDepositStatus:SetText("Disabled. Enter 0 to keep it off, or 30-3600 seconds to enable.")
        end
    end
end

function RB:IsAutoDepositQuietActive()
    return self.autoDepositQuietUntil and GetTime() <= self.autoDepositQuietUntil
end

function RB:IsAutoDepositViewSuppressed()
    if not self.autoDepositSuppressViewUntil or GetTime() > self.autoDepositSuppressViewUntil then
        return false
    end

    return not (self.frame and self.frame:IsShown())
end

function RB:RunAutoDepositTicker(now)
    local seconds = self:GetAutoDepositTickerSeconds()

    if seconds <= 0 then
        self.nextAutoDepositTickerAt = nil
        return
    end

    if not self.nextAutoDepositTickerAt then
        self.nextAutoDepositTickerAt = now + seconds
        return
    end

    if now < self.nextAutoDepositTickerAt then
        return
    end

    if self.busyKind or self.pendingRefresh or self.pendingAutoDepositAt or self.pendingDepositPreview or self.pendingTransaction then
        self.nextAutoDepositTickerAt = now + AUTO_DEPOSIT_TICKER_RETRY_DELAY
        return
    end

    if UnitAffectingCombat and UnitAffectingCombat("player") then
        self.nextAutoDepositTickerAt = now + AUTO_DEPOSIT_TICKER_RETRY_DELAY
        return
    end

    self.nextAutoDepositTickerAt = now + seconds
    self.autoDepositQuietUntil = now + REQUEST_TIMEOUT_SECONDS
    self.autoDepositSuppressViewUntil = now + REQUEST_TIMEOUT_SECONDS
    self:SendServerCommand("deposit all", { action = "deposit", source = "auto" })

    if self.frame and self.frame:IsShown() then
        self.autoDepositSuppressViewUntil = nil
        self:ScheduleCurrentRefresh(MUTATION_REFRESH_DELAY)
    end
end

function RB:UpdatePreviewToggleButton()
    if not self.frame or not self.frame.previewToggle then
        return
    end

    if self:IsDepositPreviewEnabled() then
        self.frame.previewToggle:SetText("Preview: On")
        self.frame.previewToggle.tooltipText = "Deposit All and Deposit Category will show a confirmation preview first."
    else
        self.frame.previewToggle:SetText("Preview: Off")
        self.frame.previewToggle.tooltipText = "Deposit All and Deposit Category will deposit immediately."
    end
end

function RB:UpdateSortButton()
    if not self.frame or not self.frame.sortMode then
        return
    end

    if self.currentView == "root" then
        self.frame.sortMode:SetText(CategorySortLabel(self:GetCategorySortMode()))
        self.frame.sortMode.tooltipText = "Cycle category sorting: default order, total amount, type count, or name."
    else
        self.frame.sortMode:SetText(ItemSortLabel(self:GetItemSortMode()))
        self.frame.sortMode.tooltipText = "Cycle item sorting: item ID, name, most stored, or least stored."
    end
end

function RB:CycleSortMode()
    ReagentBankUIDB = ReagentBankUIDB or {}

    if self.currentView == "root" or not self.currentCategoryId then
        ReagentBankUIDB.categorySortMode = CycleCategorySortMode(ReagentBankUIDB.categorySortMode)
        self:RenderRoot()
        return
    end

    ReagentBankUIDB.sortMode = CycleItemSortMode(ReagentBankUIDB.sortMode)
    self:RequestCategory(self.currentCategoryId, 0)
end

function RB:BuildItemAmountCommands(prefix, items, maxPairs)
    local commands = {}
    local current = prefix
    local pairsInCurrent = 0
    maxPairs = math.max(1, tonumber(maxPairs) or TRANSACTION_MAX_PAIRS_PER_COMMAND)

    for _, item in ipairs(items or {}) do
        local itemEntry = tonumber(item.itemEntry or item.entry)
        local amount = tonumber(item.amount) or 0

        if itemEntry and itemEntry > 0 and amount > 0 then
            if pairsInCurrent >= maxPairs then
                table.insert(commands, current)
                current = prefix
                pairsInCurrent = 0
            end

            current = current .. " " .. tostring(math.floor(itemEntry)) .. " " .. tostring(math.floor(amount))
            pairsInCurrent = pairsInCurrent + 1
        end
    end

    if pairsInCurrent > 0 then
        table.insert(commands, current)
    end

    return commands
end

function RB:SendItemAmountCommands(prefix, items, maxPairs, transactionContext)
    local commands = self:BuildItemAmountCommands(prefix, items, maxPairs)
    for _, command in ipairs(commands) do
        self:SendServerCommand(command, transactionContext)
    end
    return #commands
end

function RB:RequestRoot()
    self:HideDepositPreview()
    self.pendingRefresh = nil
    self.awaitingView = "root"

    self:BeginBusy("request", "Refreshing categories...")
    self:SendServerCommand("open")
end

function RB:RequestCategory(categoryId, page)
    self:HideWithdrawPrompt()
    self:HideDepositPreview()
    categoryId = tonumber(categoryId)
    page = tonumber(page) or 0

    if not categoryId then
        self:RequestRoot()
        return
    end

    self.pendingRefresh = nil
    self.awaitingView = "category"

    local category = CATEGORY_BY_ID[categoryId]
    local categoryName = category and category.name or "category"

    self:BeginBusy("request", "Loading " .. categoryName .. "...")
    self:SendServerCommand("list " .. tostring(categoryId) .. " " .. tostring(page) .. " " .. self:GetItemSortMode())
end

function RB:HideDepositPreview()
    if self.frame and self.frame.depositPreview then
        self.frame.depositPreview:Hide()
    end

    self.pendingDepositPreview = nil
    self.depositPreview = nil
    self:UpdateControls()
end

function RB:BuildDepositPreviewTitle(preview)
    local scope = tostring(preview and preview.scope or "all")

    if scope == "category" then
        local category = CATEGORY_BY_ID[tonumber(preview and preview.categoryId)]
        return "Deposit Preview: " .. tostring(category and category.name or "Category")
    end

    return "Deposit Preview: All Bags"
end

function RB:RequestDepositPreview(scope, categoryId)
    self:HideWithdrawPrompt()
    self:HideDepositPreview()

    scope = tostring(scope or "all")

    if scope == "category" then
        categoryId = tonumber(categoryId or self.currentCategoryId)
        if not categoryId then
            return
        end

        self:BeginBusy("request", "Building deposit preview...")
        self:SendServerCommand("preview deposit category " .. tostring(categoryId))
        return
    end

    self:BeginBusy("request", "Building deposit preview...")
    self:SendServerCommand("preview deposit all")
end

function RB:ShowDepositPreview(preview)
    self:CreateFrame()
    self:HideWithdrawPrompt()

    if not preview or not preview.items or #preview.items == 0 then
        self:HideDepositPreview()
        self:ClearBusy("No matching reagents were found in your bags.", 1.00, 0.82, 0.32)
        return
    end

    table.sort(preview.items, function(a, b)
        local _, an = GetItemDisplay(a.entry)
        local _, bn = GetItemDisplay(b.entry)
        an = string.lower(tostring(an or ""))
        bn = string.lower(tostring(bn or ""))
        if an == bn then
            return (tonumber(a.entry) or 0) < (tonumber(b.entry) or 0)
        end
        return an < bn
    end)

    self.depositPreview = preview

    local f = self.frame
    local panel = f.depositPreview
    panel:Show()
    panel.title:SetText(self:BuildDepositPreviewTitle(preview))
    panel.summary:SetText("This will deposit " .. FormatCount(preview.total or 0) .. " reagent(s) across " .. tostring(#preview.items) .. " item type(s).")

    local missingItemInfo = false
    for index = 1, DEPOSIT_PREVIEW_ROW_COUNT do
        local row = panel.rows[index]
        local item = preview.items[index]

        if item then
            local icon, name, link, stackCount, missingInfo = GetItemDisplay(item.entry)
            if missingInfo then
                missingItemInfo = true
            end

            row.icon:SetTexture(icon)
            row.name:SetText(link or name)
            row.count:SetText("x" .. FormatCount(item.amount))
            row:Show()
        else
            row:Hide()
        end
    end

    local remaining = #preview.items - DEPOSIT_PREVIEW_ROW_COUNT
    if remaining > 0 then
        panel.more:SetText("+" .. tostring(remaining) .. " more item type(s).")
        panel.more:Show()
    else
        panel.more:SetText("")
        panel.more:Hide()
    end

    self:SetButtonEnabled(panel.confirm, self.busyKind == nil)
    self:ClearBusy("Review the deposit preview, then confirm or cancel.", 0.82, 0.82, 0.82)

    if missingItemInfo then
        self:QueueItemInfoRefresh()
    end
end

function RB:RunDeposit(scope, categoryId)
    self:HideWithdrawPrompt()
    self:HideDepositPreview()

    scope = tostring(scope or "all")

    if scope == "category" then
        categoryId = tonumber(categoryId or self.currentCategoryId)
        if not categoryId then
            return
        end

        self.mutationNeedsRefresh = "category"
        self:BeginBusy("mutation", "Depositing this category...")
        self:SendServerCommand("deposit category " .. tostring(categoryId), { action = "deposit", source = "manual" })
        self:ScheduleRefresh(MUTATION_REFRESH_DELAY, "category", categoryId, self.currentPage or 0)
        return
    end

    self.mutationNeedsRefresh = "root"
    self:BeginBusy("mutation", "Depositing all reagents...")
    self:SendServerCommand("deposit all", { action = "deposit", source = "manual" })
    self:ScheduleRefresh(MUTATION_REFRESH_DELAY, "root", nil, 0)
end

function RB:ConfirmDepositPreview()
    local preview = self.depositPreview
    if not preview then
        self:HideDepositPreview()
        return
    end

    self:RunDeposit(preview.scope, preview.categoryId)
end

function RB:DepositAll()
    if self:IsDepositPreviewEnabled() then
        self:RequestDepositPreview("all")
    else
        self:RunDeposit("all")
    end
end

function RB:WithdrawAll()
    self:HideWithdrawPrompt()
    self.mutationNeedsRefresh = "root"
    self:BeginBusy("mutation", "Withdrawing all reagents...")
    self:SendServerCommand("withdraw all")
    self:ScheduleRefresh(MUTATION_REFRESH_DELAY, "root", nil, 0)
end

function RB:DepositCategory()
    if not self.currentCategoryId then
        return
    end

    if self:IsDepositPreviewEnabled() then
        self:RequestDepositPreview("category", self.currentCategoryId)
    else
        self:RunDeposit("category", self.currentCategoryId)
    end
end

function RB:WithdrawCategory()
    self:HideWithdrawPrompt()
    if not self.currentCategoryId then
        return
    end

    self.mutationNeedsRefresh = "category"
    self:BeginBusy("mutation", "Withdrawing this category...")
    self:SendServerCommand("withdraw category " .. tostring(self.currentCategoryId))
    self:ScheduleRefresh(MUTATION_REFRESH_DELAY, "category", self.currentCategoryId, self.currentPage or 0)
end

function RB:GetOptimisticWithdrawAmount(item, mode, exactAmount)
    if not item then
        return 0
    end

    local stored = tonumber(item.amount) or 0
    if stored <= 0 then
        return 0
    end

    if mode == "one" then
        return math.min(stored, 1)
    end

    if mode == "stack" then
        local icon, name, link, stackCount = GetItemDisplay(item.entry)
        return math.min(stored, stackCount or 1)
    end

    if mode == "all" then
        return stored
    end

    if mode == "exact" then
        return math.min(stored, math.max(tonumber(exactAmount) or 0, 0))
    end

    return 0
end

function RB:ApplyOptimisticWithdraw(itemEntry, amount)
    itemEntry = tonumber(itemEntry)
    amount = tonumber(amount) or 0

    if not itemEntry or amount <= 0 then
        return
    end

    local removedType = false

    if self.items then
        local index = 1
        while index <= #self.items do
            local item = self.items[index]
            if item and tonumber(item.entry) == itemEntry then
                local newAmount = math.max((tonumber(item.amount) or 0) - amount, 0)
                item.amount = newAmount

                if newAmount <= 0 then
                    table.remove(self.items, index)
                    removedType = true
                end

                break
            end

            index = index + 1
        end
    end

    if self.detailItem and tonumber(self.detailItem.entry) == itemEntry then
        self.detailItem.amount = math.max((tonumber(self.detailItem.amount) or 0) - amount, 0)
    end

    if self.currentCategoryId then
        self.categoryAmount = math.max((tonumber(self.categoryAmount) or 0) - amount, 0)

        if removedType then
            self.categoryTypeCount = math.max((tonumber(self.categoryTypeCount) or 0) - 1, 0)
        end

        if self.categories and self.categories[self.currentCategoryId] then
            local category = self.categories[self.currentCategoryId]
            category.amount = math.max((tonumber(category.amount) or 0) - amount, 0)

            if removedType then
                category.types = math.max((tonumber(category.types) or 0) - 1, 0)
            end
        end
    end

    if self.currentView == "detail" then
        if self.detailItem and (tonumber(self.detailItem.amount) or 0) > 0 then
            self:ShowDetail(self.detailItem, true)
        else
            self:RenderCategory(true)
        end
    elseif self.currentView == "category" then
        self:RenderCategory(true)
    end
end

function RB:GetExactWithdrawAmount()
    if not self.frame or not self.frame.exactBox then
        return 0
    end

    local amount = tonumber(self.frame.exactBox:GetText() or "") or 0
    amount = math.floor(amount)

    if amount < 0 then
        amount = 0
    end

    return amount
end

function RB:WithdrawItem(mode)
    self:HideWithdrawPrompt()
    if not self.detailItem or not self.detailItem.entry then
        return
    end

    mode = mode or "one"

    local categoryId = self.currentCategoryId or 0
    local page = self.currentPage or 0
    local itemEntry = self.detailItem.entry
    local optimisticAmount = self:GetOptimisticWithdrawAmount(self.detailItem, mode)

    self.mutationNeedsRefresh = "category"
    self:BeginBusy("mutation", "Withdrawing item...")
    self:SendServerCommand("withdraw item " .. tostring(itemEntry) .. " " .. tostring(mode) .. " " .. tostring(categoryId) .. " " .. tostring(page))

    if optimisticAmount > 0 then
        self:ApplyOptimisticWithdraw(itemEntry, optimisticAmount)
        self:Status("Withdraw sent. Count updated locally; synchronizing...", 0.82, 0.82, 0.82)
    end

    self:ScheduleRefresh(MUTATION_REFRESH_DELAY, "category", categoryId, page)
end

function RB:WithdrawItemExact()
    self:HideWithdrawPrompt()
    if not self.detailItem or not self.detailItem.entry then
        return
    end

    local amount = self:GetExactWithdrawAmount()
    if amount <= 0 then
        self:Status("Enter an exact amount first.", 1.00, 0.82, 0.32)
        return
    end

    local categoryId = self.currentCategoryId or 0
    local page = self.currentPage or 0
    local itemEntry = self.detailItem.entry
    local optimisticAmount = self:GetOptimisticWithdrawAmount(self.detailItem, "exact", amount)

    self.mutationNeedsRefresh = "category"
    self:BeginBusy("mutation", "Withdrawing exact amount...")
    self:SendServerCommand("withdraw item " .. tostring(itemEntry) .. " exact " .. tostring(amount) .. " " .. tostring(categoryId) .. " " .. tostring(page))

    if optimisticAmount > 0 then
        self:ApplyOptimisticWithdraw(itemEntry, optimisticAmount)
        self:Status("Exact withdraw sent. Count updated locally; synchronizing...", 0.82, 0.82, 0.82)
    end

    if self.frame and self.frame.exactBox then
        self.frame.exactBox:SetText("")
        self.frame.exactBox:ClearFocus()
    end

    self:ScheduleRefresh(MUTATION_REFRESH_DELAY, "category", categoryId, page)
end

function RB:GetWithdrawPromptAmount()
    if not self.frame or not self.frame.quickWithdrawBox then
        return 0
    end

    local amount = tonumber(self.frame.quickWithdrawBox:GetText() or "") or 0
    amount = math.floor(amount)

    if amount < 0 then
        amount = 0
    end

    return amount
end

function RB:HideWithdrawPrompt()
    self.promptItem = nil

    if self.frame and self.frame.quickWithdraw then
        self.frame.quickWithdraw:Hide()
    end

    if self.frame and self.frame.quickWithdrawBox then
        self.frame.quickWithdrawBox:SetText("")
        self.frame.quickWithdrawBox:ClearFocus()
    end

    self:UpdateControls()
end

function RB:UpdateQuickWithdrawControls()
    if not self.frame or not self.frame.quickWithdraw then
        return
    end

    local item = self.promptItem
    local stored = item and (tonumber(item.amount) or 0) or 0
    local amount = self:GetWithdrawPromptAmount()
    local enabled = self.busyKind == nil and item ~= nil and stored > 0 and amount > 0 and amount <= stored

    if amount > stored and stored > 0 then
        self.frame.quickWithdrawHint:SetText("Amount is higher than stored. Enter " .. FormatCount(stored) .. " or less.")
        self.frame.quickWithdrawHint:SetTextColor(1.00, 0.50, 0.35)
    else
        self.frame.quickWithdrawHint:SetText("")
        self.frame.quickWithdrawHint:SetTextColor(0.50, 0.50, 0.50)
    end

    self:SetButtonEnabled(self.frame.quickWithdrawButton, enabled)
    self:SetButtonEnabled(self.frame.quickWithdrawAll, self.busyKind == nil and item ~= nil and stored > 0)
    self:SetButtonEnabled(self.frame.quickWithdrawCancel, true)
end

function RB:SetWithdrawPromptAmountToAll()
    if not self.promptItem or not self.frame or not self.frame.quickWithdrawBox then
        return
    end

    local stored = math.max(tonumber(self.promptItem.amount) or 0, 0)
    self.frame.quickWithdrawBox:SetText(tostring(math.floor(stored)))
    self.frame.quickWithdrawBox:HighlightText()
    self:UpdateQuickWithdrawControls()
end

function RB:ShowWithdrawPrompt(item)
    if not item or not item.entry then
        return
    end

    self:CreateFrame()

    local stored = math.max(tonumber(item.amount) or 0, 0)
    if stored <= 0 then
        self:Status("That item is no longer stored.", 1.00, 0.82, 0.32)
        return
    end

    self.promptItem = item
    HideTooltip()

    local f = self.frame
    local icon, name, link, stackCount = GetItemDisplay(item.entry)

    f.quickWithdrawIcon:SetTexture(icon)
    f.quickWithdrawName:SetText(link or name)
    f.quickWithdrawStored:SetText("Stored: " .. FormatCount(stored))
    f.quickWithdrawBox:SetText("")
    f.quickWithdrawBox:SetFocus()
    f.quickWithdrawBox:HighlightText()
    f.quickWithdraw:Show()
    f.quickWithdraw:SetFrameLevel((f:GetFrameLevel() or 1) + 80)

    self:UpdateQuickWithdrawControls()
    self:Status("Enter amount to withdraw for " .. tostring(name or ("Item #" .. tostring(item.entry))) .. ".", 0.82, 0.82, 0.82)
end

function RB:WithdrawItemExactFromPrompt(item, amount)
    if not item or not item.entry then
        return
    end

    amount = math.floor(tonumber(amount) or 0)

    if amount <= 0 then
        self:Status("Enter an amount first.", 1.00, 0.82, 0.32)
        return
    end

    local stored = tonumber(item.amount) or 0
    if amount > stored then
        self:Status("You only have " .. FormatCount(stored) .. " stored.", 1.00, 0.82, 0.32)
        return
    end

    local categoryId = self.currentCategoryId or 0
    local page = self.currentPage or 0
    local itemEntry = item.entry
    local optimisticAmount = self:GetOptimisticWithdrawAmount(item, "exact", amount)

    self.mutationNeedsRefresh = "category"
    self:BeginBusy("mutation", "Withdrawing exact amount...")
    self:SendServerCommand("withdraw item " .. tostring(itemEntry) .. " exact " .. tostring(amount) .. " " .. tostring(categoryId) .. " " .. tostring(page))

    if optimisticAmount > 0 then
        self:ApplyOptimisticWithdraw(itemEntry, optimisticAmount)
        self:Status("Exact withdraw sent. Count updated locally; synchronizing...", 0.82, 0.82, 0.82)
    end

    self:HideWithdrawPrompt()
    self:ScheduleRefresh(MUTATION_REFRESH_DELAY, "category", categoryId, page)
end

function RB:ConfirmWithdrawPrompt()
    if not self.promptItem then
        self:HideWithdrawPrompt()
        return
    end

    local amount = self:GetWithdrawPromptAmount()
    self:WithdrawItemExactFromPrompt(self.promptItem, amount)
end

function RB:ClampTradeSkillPrepareCount(value)
    value = math.floor(tonumber(value) or 1)

    if value < TRADE_SKILL_PREPARE_COUNT_MIN then
        value = TRADE_SKILL_PREPARE_COUNT_MIN
    end

    if value > TRADE_SKILL_PREPARE_COUNT_MAX then
        value = TRADE_SKILL_PREPARE_COUNT_MAX
    end

    return value
end

function RB:GetNativeTradeSkillRepeatCount()
    local input = _G.TradeSkillInputBox
    if input and input.GetNumber then
        local value = tonumber(input:GetNumber())
        if value and value > 0 then
            return self:ClampTradeSkillPrepareCount(value)
        end
    end

    if input and input.GetText then
        local value = tonumber(input:GetText())
        if value and value > 0 then
            return self:ClampTradeSkillPrepareCount(value)
        end
    end

    return 1
end

function RB:GetTradeSkillRepeatCount()
    if self.tradeSkillQuantityBox and self.tradeSkillQuantityBox.GetText then
        local value = tonumber(self.tradeSkillQuantityBox:GetText())
        if value and value > 0 then
            return self:ClampTradeSkillPrepareCount(value)
        end
    end

    ReagentBankUIDB = ReagentBankUIDB or {}
    local saved = tonumber(ReagentBankUIDB.tradeSkillPrepareCount)
    if saved and saved > 0 then
        return self:ClampTradeSkillPrepareCount(saved)
    end

    return self:GetNativeTradeSkillRepeatCount()
end

function RB:SetTradeSkillPrepareCount(value, updateNative)
    value = self:ClampTradeSkillPrepareCount(value)

    ReagentBankUIDB = ReagentBankUIDB or {}
    ReagentBankUIDB.tradeSkillPrepareCount = value

    if self.tradeSkillQuantityBox and self.tradeSkillQuantityBox.GetText then
        local textValue = tostring(value)
        if self.tradeSkillQuantityBox:GetText() ~= textValue then
            self.suppressTradeSkillQuantityChanged = true
            self.tradeSkillQuantityBox:SetText(textValue)
            self.suppressTradeSkillQuantityChanged = nil
        end
    end

    if updateNative then
        self:SyncNativeTradeSkillRepeatCount(value)
    end

    self:UpdateTradeSkillControls()
    return value
end

function RB:NormalizeTradeSkillQuantityBox(updateNative)
    return self:SetTradeSkillPrepareCount(self:GetTradeSkillRepeatCount(), updateNative)
end

function RB:SyncNativeTradeSkillRepeatCount(value)
    value = self:ClampTradeSkillPrepareCount(value)

    local input = _G.TradeSkillInputBox
    if not input then
        return
    end

    self.suppressNativeTradeSkillQuantityChanged = true

    if input.SetNumber then
        input:SetNumber(value)
    elseif input.SetText then
        input:SetText(tostring(value))
    end

    self.suppressNativeTradeSkillQuantityChanged = nil
end

function RB:GetSelectedTradeSkillReagents()
    if not GetTradeSkillSelectionIndex or not GetTradeSkillInfo or not GetTradeSkillNumReagents or not GetTradeSkillReagentInfo then
        return nil, "The trade skill API is not available.", nil, nil
    end

    local index = GetTradeSkillSelectionIndex()
    if not index or index <= 0 then
        return nil, "Select a recipe first.", nil, nil
    end

    local recipeName, recipeType, numAvailable, isExpanded = GetTradeSkillInfo(index)
    if isExpanded or recipeType == "header" then
        return nil, "Select a craftable recipe, not a category header.", nil, nil
    end

    local reagentCount = GetTradeSkillNumReagents(index) or 0
    if reagentCount <= 0 then
        return {}, nil, recipeName, self:GetTradeSkillRepeatCount()
    end

    local repeatCount = self:GetTradeSkillRepeatCount()
    local byItem = {}
    local order = {}

    for reagentIndex = 1, reagentCount do
        local reagentName, reagentTexture, requiredCount, playerCount = GetTradeSkillReagentInfo(index, reagentIndex)
        requiredCount = tonumber(requiredCount) or 0

        local link = nil
        if GetTradeSkillReagentItemLink then
            link = GetTradeSkillReagentItemLink(index, reagentIndex)
        end

        local itemEntry = ParseItemIdFromLink(link)
        if itemEntry and requiredCount > 0 then
            local inBags = 0

            if GetItemCount then
                inBags = tonumber(GetItemCount(itemEntry, false)) or 0
            end

            if inBags <= 0 and playerCount then
                inBags = tonumber(playerCount) or 0
            end

            if not byItem[itemEntry] then
                byItem[itemEntry] = {
                    itemEntry = itemEntry,
                    entry = itemEntry,
                    requiredPerCraft = 0,
                    bagCount = 0,
                    name = reagentName or ("Item #" .. tostring(itemEntry)),
                }
                table.insert(order, itemEntry)
            end

            byItem[itemEntry].requiredPerCraft = byItem[itemEntry].requiredPerCraft + requiredCount
            byItem[itemEntry].bagCount = math.max(tonumber(byItem[itemEntry].bagCount) or 0, inBags)
        end
    end

    local reagents = {}
    for _, itemEntry in ipairs(order) do
        local reagent = byItem[itemEntry]
        if reagent and (tonumber(reagent.requiredPerCraft) or 0) > 0 then
            table.insert(reagents, reagent)
        end
    end

    return reagents, nil, recipeName, repeatCount
end

function RB:BuildTradeSkillReagentKey(reagents)
    local parts = {}

    for _, reagent in ipairs(reagents or {}) do
        local itemEntry = tonumber(reagent.itemEntry or reagent.entry)
        local requiredPerCraft = math.floor(tonumber(reagent.requiredPerCraft or reagent.amount) or 0)

        if itemEntry and itemEntry > 0 and requiredPerCraft > 0 then
            table.insert(parts, tostring(math.floor(itemEntry)) .. "x" .. tostring(requiredPerCraft))
        end
    end

    table.sort(parts)
    return table.concat(parts, ";")
end

function RB:RequestTradeSkillBankCounts(reagents)
    if not reagents or #reagents == 0 then
        return
    end

    local key = self:BuildTradeSkillReagentKey(reagents)
    if key == "" then
        return
    end

    if self.tradeSkillBankCountsKey == key then
        return
    end

    if self.pendingTradeSkillCheckKey == key and self.pendingTradeSkillCheckUntil and GetTime() < self.pendingTradeSkillCheckUntil then
        return
    end

    self.tradeSkillCheckRequestId = (tonumber(self.tradeSkillCheckRequestId) or 0) + 1
    if self.tradeSkillCheckRequestId > 100000000 then
        self.tradeSkillCheckRequestId = 1
    end

    local requestId = self.tradeSkillCheckRequestId
    self.pendingTradeSkillChecks = self.pendingTradeSkillChecks or {}
    self.pendingTradeSkillChecks[requestId] = {
        key = key,
        createdAt = GetTime(),
    }
    self.pendingTradeSkillCheckKey = key
    self.pendingTradeSkillCheckUntil = GetTime() + TRADE_SKILL_CHECK_TIMEOUT

    local items = {}
    for _, reagent in ipairs(reagents) do
        local itemEntry = tonumber(reagent.itemEntry or reagent.entry)
        local requiredPerCraft = math.floor(tonumber(reagent.requiredPerCraft) or 0)

        if itemEntry and itemEntry > 0 and requiredPerCraft > 0 then
            table.insert(items, {
                entry = math.floor(itemEntry),
                amount = requiredPerCraft,
            })
        end
    end

    if #items > 0 then
        self:SendServerCommand(self:BuildItemAmountCommand("check recipe " .. tostring(requestId), items))
    end
end

function RB:GetTradeSkillCraftability(reagents, repeatCount)
    local key = self:BuildTradeSkillReagentKey(reagents)
    local bankCountsReady = key ~= "" and self.tradeSkillBankCountsKey == key
    local bankCounts = bankCountsReady and self.tradeSkillBankCounts or {}

    local bagCrafts = nil
    local bankCrafts = nil
    local missingTypes = 0

    repeatCount = self:ClampTradeSkillPrepareCount(repeatCount or 1)

    for _, reagent in ipairs(reagents or {}) do
        local itemEntry = tonumber(reagent.itemEntry or reagent.entry)
        local requiredPerCraft = math.floor(tonumber(reagent.requiredPerCraft) or 0)

        if itemEntry and itemEntry > 0 and requiredPerCraft > 0 then
            local bagCount = 0
            if GetItemCount then
                bagCount = tonumber(GetItemCount(itemEntry, false)) or 0
            end

            if (not bagCount or bagCount <= 0) and reagent.bagCount then
                bagCount = tonumber(reagent.bagCount) or 0
            end

            local bankCount = tonumber(bankCounts and bankCounts[itemEntry]) or 0
            local fromBags = math.floor(bagCount / requiredPerCraft)
            local fromBank = math.floor(bankCount / requiredPerCraft)

            if bagCrafts == nil or fromBags < bagCrafts then
                bagCrafts = fromBags
            end

            if bankCountsReady then
                if bankCrafts == nil or fromBank < bankCrafts then
                    bankCrafts = fromBank
                end

                if bagCount + bankCount < requiredPerCraft * repeatCount then
                    missingTypes = missingTypes + 1
                end
            end
        end
    end

    if bagCrafts == nil then
        bagCrafts = 0
    end

    if bankCountsReady and bankCrafts == nil then
        bankCrafts = 0
    end

    return {
        bankReady = bankCountsReady,
        bankCrafts = bankCrafts,
        bagCrafts = bagCrafts,
        missingTypes = missingTypes,
    }
end

function RB:UpdateTradeSkillStatsText()
    if not self.tradeSkillStatsText then
        return
    end

    -- Disabled intentionally: this stats line queried bank craftability on every
    -- trade-skill update/search and could cause heavy blanket scans.
    self.tradeSkillStatsText:SetText("")
    self.tradeSkillStatsText:Hide()
end

function RB:GetSelectedTradeSkillNeeds()
    local reagents, errText, recipeName, repeatCount = self:GetSelectedTradeSkillReagents()
    if errText then
        return nil, errText, recipeName, repeatCount
    end

    repeatCount = self:ClampTradeSkillPrepareCount(repeatCount or 1)

    if not reagents or #reagents == 0 then
        return {}, nil, recipeName, repeatCount
    end

    local needs = {}
    for _, reagent in ipairs(reagents) do
        local itemEntry = tonumber(reagent.itemEntry or reagent.entry)
        local requiredPerCraft = tonumber(reagent.requiredPerCraft) or 0
        local bagCount = 0

        if itemEntry and GetItemCount then
            bagCount = tonumber(GetItemCount(itemEntry, false)) or 0
        end

        if bagCount <= 0 and reagent.bagCount then
            bagCount = tonumber(reagent.bagCount) or 0
        end

        local missing = (requiredPerCraft * repeatCount) - bagCount
        if itemEntry and itemEntry > 0 and missing > 0 then
            table.insert(needs, {
                itemEntry = itemEntry,
                entry = itemEntry,
                amount = math.floor(missing),
                name = reagent.name or ("Item #" .. tostring(itemEntry)),
            })
        end
    end

    return needs, nil, recipeName, repeatCount
end

function RB:BuildItemAmountCommand(prefix, items)
    local commands = self:BuildItemAmountCommands(prefix, items, 999)
    return commands[1] or prefix
end

function RB:NormalizeTransactionAction(action)
    action = string.lower(tostring(action or ""))

    if action == "deposit" or action == "withdraw" then
        return action
    end

    return nil
end

function RB:BuildTransactionSummary(transaction)
    if not transaction or not transaction.action or not transaction.items or #transaction.items == 0 then
        return "No reversible transaction is available."
    end

    local total = tonumber(transaction.total) or 0
    if total <= 0 then
        for _, item in ipairs(transaction.items) do
            total = total + (tonumber(item.amount) or 0)
        end
    end

    local verb = transaction.action == "deposit" and "Deposited" or "Withdrew"
    return "Last: " .. verb .. " " .. FormatCount(total) .. " reagent(s) across " .. tostring(#transaction.items) .. " item type(s)."
end

function RB:GetTransactionTotal(transaction)
    local total = tonumber(transaction and transaction.total) or 0

    if total > 0 then
        return total
    end

    for _, item in ipairs((transaction and transaction.items) or {}) do
        total = total + (tonumber(item.amount) or 0)
    end

    return total
end

function RB:BuildTransactionItemChatList(transaction, limit)
    if not transaction or not transaction.items or #transaction.items == 0 then
        return ""
    end

    limit = math.max(1, tonumber(limit) or TRANSACTION_CHAT_ITEM_LIMIT)

    local items = {}
    for _, item in ipairs(transaction.items) do
        local itemEntry = tonumber(item.entry)
        local amount = tonumber(item.amount) or 0

        if itemEntry and itemEntry > 0 and amount > 0 then
            local icon, name, link = GetItemDisplay(itemEntry)
            table.insert(items, {
                entry = itemEntry,
                amount = math.floor(amount),
                name = name or ("Item #" .. tostring(itemEntry)),
                text = BuildItemAmountChatText(itemEntry, amount),
            })
        end
    end

    table.sort(items, function(a, b)
        local an = string.lower(tostring(a.name or ""))
        local bn = string.lower(tostring(b.name or ""))
        if an == bn then
            return (tonumber(a.entry) or 0) < (tonumber(b.entry) or 0)
        end
        return an < bn
    end)

    local pieces = {}
    local shown = math.min(#items, limit)
    for index = 1, shown do
        table.insert(pieces, items[index].text)
    end

    if #items > shown then
        table.insert(pieces, "+" .. tostring(#items - shown) .. " more")
    end

    return table.concat(pieces, ", ")
end

function RB:GetDepositChatPrefix(transaction)
    local source = SafeTransactionSource(transaction and transaction.source)

    if source == "profession" then
        return "Profession leftovers auto-deposited"
    elseif source == "auto" then
        return "Auto-deposited"
    elseif source == "reverse" then
        return "Undo deposited"
    end

    return "Deposited"
end

function RB:PrintDepositTransactionMessage(transaction)
    if not transaction or transaction.action ~= "deposit" or not transaction.items or #transaction.items == 0 then
        return
    end

    local total = self:GetTransactionTotal(transaction)
    if total <= 0 then
        return
    end

    local detailText = self:BuildTransactionItemChatList(transaction, TRANSACTION_CHAT_ITEM_LIMIT)
    local prefix = self:GetDepositChatPrefix(transaction)
    local message = prefix .. " " .. FormatCount(total) .. " reagent(s)"

    if detailText ~= "" then
        message = message .. ": " .. detailText
    end

    message = message .. "."
    PrintAddon(message)

    if self.frame and self.frame:IsShown() then
        self:Status(message, 0.45, 1.00, 0.45)
    end
end

function RB:GetReverseTransactionLabel(transaction)
    if not transaction or not transaction.action then
        return "Reverse Last"
    end

    if transaction.action == "deposit" then
        return "Undo Deposit"
    elseif transaction.action == "withdraw" then
        return "Undo Withdraw"
    end

    return "Reverse Last"
end

function RB:UpdateUndoButton()
    if not self.frame or not self.frame.undoLast then
        return
    end

    local transaction = self.lastTransaction
    local canReverse = transaction and transaction.items and #transaction.items > 0

    self.frame.undoLast:SetText(self:GetReverseTransactionLabel(transaction))
    self.frame.undoLast.tooltipText = canReverse and self:BuildTransactionSummary(transaction) or "No reversible deposit or withdraw transaction has been seen yet."
    self:SetButtonEnabled(self.frame.undoLast, canReverse and self.busyKind == nil)
end

function RB:MergeTransactionIntoCollector(transaction)
    if not transaction or not self.reverseCollector then
        return false
    end

    local collector = self.reverseCollector
    collector.action = transaction.action
    collector.itemsByEntry = collector.itemsByEntry or {}

    for _, item in ipairs(transaction.items or {}) do
        local itemEntry = tonumber(item.entry)
        local amount = tonumber(item.amount) or 0
        if itemEntry and itemEntry > 0 and amount > 0 then
            collector.itemsByEntry[itemEntry] = (collector.itemsByEntry[itemEntry] or 0) + amount
            collector.total = (collector.total or 0) + amount
        end
    end

    collector.remaining = math.max((collector.remaining or 1) - 1, 0)

    if collector.remaining <= 0 then
        local items = {}
        for itemEntry, amount in pairs(collector.itemsByEntry) do
            table.insert(items, {
                entry = tonumber(itemEntry),
                amount = tonumber(amount) or 0,
            })
        end

        table.sort(items, function(a, b)
            return (tonumber(a.entry) or 0) < (tonumber(b.entry) or 0)
        end)

        self.lastTransaction = {
            action = collector.action,
            source = "reverse",
            total = collector.total or 0,
            items = items,
            updatedAt = GetTime(),
        }
        self.reverseCollector = nil
        self:PrintDepositTransactionMessage(self.lastTransaction)
        self:UpdateUndoButton()
        return true
    end

    return true
end

function RB:FinalizeTransaction(transaction)
    if not transaction or not transaction.action or not transaction.items or #transaction.items == 0 then
        return
    end

    if self.reverseCollector and self:MergeTransactionIntoCollector(transaction) then
        return
    end

    transaction.updatedAt = GetTime()
    self.lastTransaction = transaction
    self:PrintDepositTransactionMessage(transaction)
    self:UpdateUndoButton()
end

function RB:ReverseLastTransaction()
    local transaction = self.lastTransaction
    if not transaction or not transaction.items or #transaction.items == 0 then
        self:Status("No reversible transaction is available.", 1.00, 0.82, 0.32)
        return
    end

    local prefix = nil
    local reverseAction = nil

    if transaction.action == "deposit" then
        prefix = "withdraw needed"
        reverseAction = "withdraw"
    elseif transaction.action == "withdraw" then
        prefix = "deposit items"
        reverseAction = "deposit"
    end

    if not prefix then
        self:Status("This transaction cannot be reversed.", 1.00, 0.82, 0.32)
        return
    end

    local commands = self:BuildItemAmountCommands(prefix, transaction.items, TRANSACTION_MAX_PAIRS_PER_COMMAND)
    if #commands == 0 then
        self:Status("No reversible item amounts were found.", 1.00, 0.82, 0.32)
        return
    end

    self.reverseCollector = {
        action = reverseAction,
        remaining = #commands,
        total = 0,
        itemsByEntry = {},
    }

    if reverseAction == "withdraw" then
        end

    self.mutationNeedsRefresh = self.currentView == "category" and "category" or "root"
    self:BeginBusy("mutation", "Reversing last reagent bank action...")

    for _, command in ipairs(commands) do
        self:SendServerCommand(command, { action = reverseAction, source = "reverse" })
    end

    self:ScheduleCurrentRefresh(MUTATION_REFRESH_DELAY)
end

function RB:ArmAutoDepositLeftovers(needs, recipeName, repeatCount)
    ReagentBankUIDB = ReagentBankUIDB or {}

    if not ReagentBankUIDB.autoDepositLeftovers then
        self.pendingAutoDepositLeftovers = nil
        self.pendingAutoDepositAt = nil
        return
    end

    if not needs or #needs == 0 then
        return
    end

    local pending = self.pendingAutoDepositLeftovers
    if not pending then
        pending = {
            itemsByEntry = {},
            recipeNames = {},
            firstArmedAt = GetTime(),
        }
        self.pendingAutoDepositLeftovers = pending
    end

    pending.expiresAt = GetTime() + AUTO_DEPOSIT_PREP_EXPIRE_SECONDS

    if recipeName and recipeName ~= "" then
        pending.recipeNames[tostring(recipeName)] = true
    end

    for _, need in ipairs(needs) do
        local itemEntry = tonumber(need.itemEntry or need.entry)
        if itemEntry and itemEntry > 0 then
            local key = tostring(itemEntry)
            if not pending.itemsByEntry[key] then
                pending.itemsByEntry[key] = {
                    itemEntry = itemEntry,
                    baseline = GetItemCount(itemEntry, false) or 0,
                }
            end
        end
    end

    PrintAddon(
        "Auto-deposit armed for profession window close" ..
        " (" .. tostring(repeatCount or 1) .. " prepared craft(s))."
    )
end

function RB:BuildPreparedLeftoverItems(pending)
    local items = {}

    if not pending or not pending.itemsByEntry then
        return items
    end

    for _, info in pairs(pending.itemsByEntry) do
        local itemEntry = tonumber(info.itemEntry)
        local baseline = tonumber(info.baseline) or 0

        if itemEntry and itemEntry > 0 then
            local current = GetItemCount(itemEntry, false) or 0
            local leftover = current - baseline

            if leftover > 0 then
                table.insert(items, {
                    entry = itemEntry,
                    amount = math.floor(leftover),
                })
            end
        end
    end

    table.sort(items, function(a, b)
        return (tonumber(a.entry) or 0) < (tonumber(b.entry) or 0)
    end)

    return items
end

function RB:WithdrawNeededForSelectedRecipe()
    local needs, errText, recipeName, repeatCount = self:GetSelectedTradeSkillNeeds()
    repeatCount = self:ClampTradeSkillPrepareCount(repeatCount or 1)

    if errText then
        PrintAddon(errText)
        self:Status(errText, 1.00, 0.82, 0.32)
        return
    end

    self:SetTradeSkillPrepareCount(repeatCount, true)

    if not needs or #needs == 0 then
        local message = "You already have the selected recipe reagents in your bags for " .. tostring(repeatCount) .. " craft(s)."
        PrintAddon(message)
        self:Status(message, 0.45, 1.00, 0.45)
        return
    end

    self:DisableAutoDepositTickerForProfessionWithdraw()
    self:ArmAutoDepositLeftovers(needs, recipeName, repeatCount)

    self:SendItemAmountCommands("withdraw needed", needs, TRANSACTION_MAX_PAIRS_PER_COMMAND)

    local total = 0
    for _, need in ipairs(needs) do
        total = total + (tonumber(need.amount) or 0)
    end

    PrintAddon(
        "Requested " .. tostring(total) .. " reagent(s) for " ..
        tostring(repeatCount) .. " craft(s) of " .. tostring(recipeName or "selected recipe") .. "."
    )

    self:UpdateTradeSkillControls()
end

function RB:DepositPreparedLeftovers()
    local pending = self.pendingAutoDepositLeftovers
    self.pendingAutoDepositLeftovers = nil
    self.pendingAutoDepositAt = nil

    local items = self:BuildPreparedLeftoverItems(pending)
    if not items or #items == 0 then
        if pending then
            PrintAddon("No prepared reagent leftovers to auto-deposit.")
        end
        return
    end

    self:SendItemAmountCommands(
        "deposit items",
        items,
        TRANSACTION_MAX_PAIRS_PER_COMMAND,
        { action = "deposit", source = "profession" }
    )

    PrintAddon("Auto-depositing prepared reagent leftovers after closing the profession window.")
end

function RB:HandleTradeSkillClosed()
    self:UpdateTradeSkillControls()

    local pending = self.pendingAutoDepositLeftovers
    if not pending then
        return
    end

    if pending.expiresAt and GetTime() > pending.expiresAt then
        self.pendingAutoDepositLeftovers = nil
        self.pendingAutoDepositAt = nil
        PrintAddon("Prepared reagent auto-deposit expired.")
        return
    end

    self.pendingAutoDepositAt = GetTime() + AUTO_DEPOSIT_AFTER_CLOSE_DELAY
    self:EnsureOnUpdate()
end

function RB:Toggle()
    self:CreateFrame()

    if self.frame:IsShown() then
        self:Close()
        return
    end

    self.frame:Show()
    self:RequestRoot()
end

function RB:PositionPaperDollButton()
    if not self.paperDollButton then
        return
    end

    local dock = EnsurePaperDollLauncherDock()
    dock:Register("ReagentBankUI", self.paperDollButton, 20)
end

function RB:CreateColorSettingsFrame()
    if self.colorSettingsFrame then
        return
    end

    local frame = CreateFrame("Frame", "ReagentBankUIColorSettingsFrame", UIParent)
    frame:SetWidth(430)
    frame:SetHeight(350)
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:SetClampedToScreen(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetFrameStrata("DIALOG")
    frame:SetScript("OnDragStart", function(selfFrame)
        selfFrame:StartMoving()
    end)
    frame:SetScript("OnDragStop", function(selfFrame)
        selfFrame:StopMovingOrSizing()
    end)

    self:MakeBackdrop(frame, 0.98, true)

    frame.title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    frame.title:SetPoint("TOPLEFT", 16, -14)
    frame.title:SetPoint("RIGHT", -46, 0)
    frame.title:SetJustifyH("LEFT")
    frame.title:SetText("Reagent Bank Settings")
    frame.title:SetTextColor(SKIN.titleText[1], SKIN.titleText[2], SKIN.titleText[3], SKIN.titleText[4] or 1)

    frame.close = self:CreateCloseButton(frame)
    frame.close:SetPoint("TOPRIGHT", -8, -8)
    frame.close:SetScript("OnClick", function()
        RB:HideColorSettings()
    end)

    frame.note = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    frame.note:SetPoint("TOPLEFT", 16, -44)
    frame.note:SetPoint("RIGHT", -16, 0)
    frame.note:SetJustifyH("LEFT")
    frame.note:SetText("Settings are saved per account.")
    frame.note:SetTextColor(SKIN.mutedText[1], SKIN.mutedText[2], SKIN.mutedText[3], SKIN.mutedText[4] or 1)

    frame.themeHeader = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    frame.themeHeader:SetPoint("TOPLEFT", 18, -66)
    frame.themeHeader:SetJustifyH("LEFT")
    frame.themeHeader:SetText("Color schema")
    frame.themeHeader:SetTextColor(SKIN.titleText[1], SKIN.titleText[2], SKIN.titleText[3], SKIN.titleText[4] or 1)

    frame.themeButtons = {}

    local firstColumnX = 18
    local secondColumnX = 218
    local firstRowY = -88
    local rowGap = 34
    local buttonWidth = 158
    local buttonHeight = 26

    for index, themeKey in ipairs(SKIN_THEME_ORDER) do
        local columnX = firstColumnX
        local rowIndex = index

        if index > 3 then
            columnX = secondColumnX
            rowIndex = index - 3
        end

        local theme = SKIN_THEMES[themeKey]
        local button = self:CreateButton(frame, buttonWidth, buttonHeight, theme and theme.label or themeKey)
        button.themeKey = themeKey
        button:SetPoint("TOPLEFT", columnX, firstRowY - ((rowIndex - 1) * rowGap))
        button:SetScript("OnClick", function(selfButton)
            RB:SetColorTheme(selfButton.themeKey)
        end)
        button:SetScript("OnEnter", function(selfButton)
            GameTooltip:SetOwner(selfButton, "ANCHOR_RIGHT")
            GameTooltip:SetText("Color Schema", 1, 0.82, 0)
            GameTooltip:AddLine("Apply " .. RB:GetColorThemeLabel(selfButton.themeKey) .. ".", 1, 1, 1, true)
            GameTooltip:Show()
        end)
        button:SetScript("OnLeave", HideTooltip)

        table.insert(frame.themeButtons, button)
    end

    frame.autoDepositHeader = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    frame.autoDepositHeader:SetPoint("TOPLEFT", 18, -198)
    frame.autoDepositHeader:SetJustifyH("LEFT")
    frame.autoDepositHeader:SetText("Periodic auto-deposit")
    frame.autoDepositHeader:SetTextColor(SKIN.titleText[1], SKIN.titleText[2], SKIN.titleText[3], SKIN.titleText[4] or 1)

    frame.autoDepositNote = frame:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    frame.autoDepositNote:SetPoint("TOPLEFT", 18, -218)
    frame.autoDepositNote:SetPoint("RIGHT", -18, 0)
    frame.autoDepositNote:SetJustifyH("LEFT")
    frame.autoDepositNote:SetText("Runs Deposit All on a timer while you are online. Enter 0 to disable. Minimum: 30 seconds.")
    frame.autoDepositNote:SetTextColor(SKIN.mutedText[1], SKIN.mutedText[2], SKIN.mutedText[3], SKIN.mutedText[4] or 1)

    frame.autoDepositLabel = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    frame.autoDepositLabel:SetPoint("TOPLEFT", 20, -248)
    frame.autoDepositLabel:SetText("Every")
    frame.autoDepositLabel:SetJustifyH("LEFT")
    frame.autoDepositLabel:SetTextColor(SKIN.mutedText[1], SKIN.mutedText[2], SKIN.mutedText[3], SKIN.mutedText[4] or 1)

    frame.autoDepositIntervalBox = self:CreateEditBox(frame, 66, 24)
    frame.autoDepositIntervalBox:SetPoint("LEFT", frame.autoDepositLabel, "RIGHT", 10, 0)
    frame.autoDepositIntervalBox:SetScript("OnEnterPressed", function(selfBox)
        RB:ApplyAutoDepositTickerBox()
        selfBox:ClearFocus()
    end)
    frame.autoDepositIntervalBox:SetScript("OnEscapePressed", function(selfBox)
        RB:UpdateAutoDepositTickerControls()
        selfBox:ClearFocus()
    end)
    frame.autoDepositIntervalBox:SetScript("OnTextChanged", nil)

    frame.autoDepositSecondsText = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    frame.autoDepositSecondsText:SetPoint("LEFT", frame.autoDepositIntervalBox, "RIGHT", 7, 0)
    frame.autoDepositSecondsText:SetText("seconds")
    frame.autoDepositSecondsText:SetJustifyH("LEFT")
    frame.autoDepositSecondsText:SetTextColor(SKIN.mutedText[1], SKIN.mutedText[2], SKIN.mutedText[3], SKIN.mutedText[4] or 1)

    frame.autoDepositApply = self:CreateButton(frame, 72, 24, "Apply")
    frame.autoDepositApply:SetPoint("LEFT", frame.autoDepositSecondsText, "RIGHT", 12, 0)
    frame.autoDepositApply:SetScript("OnClick", function()
        RB:ApplyAutoDepositTickerBox()
    end)

    frame.autoDepositOff = self:CreateButton(frame, 72, 24, "Off")
    frame.autoDepositOff:SetPoint("LEFT", frame.autoDepositApply, "RIGHT", 8, 0)
    frame.autoDepositOff:SetScript("OnClick", function()
        RB:SetAutoDepositTickerSeconds(0)
    end)

    frame.autoDepositStatus = frame:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    frame.autoDepositStatus:SetPoint("TOPLEFT", 20, -278)
    frame.autoDepositStatus:SetPoint("RIGHT", -18, 0)
    frame.autoDepositStatus:SetJustifyH("LEFT")
    frame.autoDepositStatus:SetText("")
    frame.autoDepositStatus:SetTextColor(SKIN.mutedText[1], SKIN.mutedText[2], SKIN.mutedText[3], SKIN.mutedText[4] or 1)

    frame.cycle = self:CreateButton(frame, 188, 26, "Cycle Theme")
    frame.cycle:SetPoint("BOTTOMLEFT", 18, 16)
    frame.cycle:SetScript("OnClick", function()
        RB:CycleColorTheme()
    end)

    frame.reset = self:CreateButton(frame, 188, 26, "Reset to Gold")
    frame.reset:SetPoint("LEFT", frame.cycle, "RIGHT", 12, 0)
    frame.reset:SetScript("OnClick", function()
        RB:SetColorTheme(DEFAULT_COLOR_THEME)
    end)

    self.colorSettingsFrame = frame
    self:ApplySkin()
    self:UpdateColorSettingsFrame()

    frame:Hide()
end

function RB:UpdateColorSettingsFrame()
    local frame = self.colorSettingsFrame
    if not frame then
        return
    end

    local selected = self:GetColorThemeKey()

    if frame.themeButtons then
        for _, button in ipairs(frame.themeButtons) do
            local themeKey = button.themeKey
            local label = self:GetColorThemeLabel(themeKey)

            if themeKey == selected then
                button:SetText("✓ " .. label)
                if button.SetBackdropBorderColor then
                    button:SetBackdropBorderColor(SKIN.headerLine[1], SKIN.headerLine[2], SKIN.headerLine[3], SKIN.headerLine[4])
                end
            else
                button:SetText(label)
                if button.SetBackdropBorderColor then
                    button:SetBackdropBorderColor(SKIN.buttonBorder[1], SKIN.buttonBorder[2], SKIN.buttonBorder[3], SKIN.buttonBorder[4])
                end
            end
        end
    end

    if frame.cycle then
        frame.cycle:SetText("Cycle Theme")
    end

    if frame.reset then
        frame.reset:SetText("Reset to Gold")
    end

    self:UpdateAutoDepositTickerControls()
end

function RB:ShowColorSettings()
    self:ApplySavedColorTheme()
    self:CreateColorSettingsFrame()

    local frame = self.colorSettingsFrame
    frame:ClearAllPoints()

    if self.paperDollButton and self.paperDollButton:IsShown() then
        frame:SetPoint("TOPLEFT", self.paperDollButton, "BOTTOMLEFT", -14, -10)
    else
        frame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    end

    frame:Show()
    frame:SetFrameLevel(200)
    self:UpdateColorSettingsFrame()
end

function RB:HideColorSettings()
    if self.colorSettingsFrame then
        self.colorSettingsFrame:Hide()
    end
end

function RB:ToggleColorSettings()
    self:CreateColorSettingsFrame()

    if self.colorSettingsFrame:IsShown() then
        self:HideColorSettings()
    else
        self:ShowColorSettings()
    end
end

function RB:CreatePaperDollButton()
    if self.paperDollButton or not PAPERDOLL_BUTTON_ENABLED then
        return
    end

    local dock = EnsurePaperDollLauncherDock()
    local parent = dock:GetParentFrame()

    local button = CreateFrame("Button", "ReagentBankUIPaperDollButton", parent)
    button:SetWidth(PAPERDOLL_BUTTON_SIZE)
    button:SetHeight(PAPERDOLL_BUTTON_SIZE)
    button:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    button:SetFrameLevel((parent:GetFrameLevel() or 1) + 12)

    -- Dark circular background, matching the AH button style.
    local bg = button:CreateTexture(nil, "BACKGROUND")
    bg:SetTexture(PAPERDOLL_BUTTON_BG_TEXTURE)
    bg:SetWidth(PAPERDOLL_BUTTON_BG_SIZE)
    bg:SetHeight(PAPERDOLL_BUTTON_BG_SIZE)
    bg:SetPoint("CENTER", button, "CENTER", 0, 0)
    bg:SetVertexColor(
        PAPERDOLL_BUTTON_BG_R,
        PAPERDOLL_BUTTON_BG_G,
        PAPERDOLL_BUTTON_BG_B,
        PAPERDOLL_BUTTON_BG_A
    )
    button.bg = bg

    -- Inner icon.
    local icon = button:CreateTexture(nil, "ARTWORK")
    icon:SetTexture(PAPERDOLL_BUTTON_ICON)
    icon:SetWidth(PAPERDOLL_BUTTON_ICON_SIZE)
    icon:SetHeight(PAPERDOLL_BUTTON_ICON_SIZE)
    icon:SetPoint("CENTER", button, "CENTER", 0, 0)
    icon:SetTexCoord(
        PAPERDOLL_BUTTON_ICON_CROP,
        1 - PAPERDOLL_BUTTON_ICON_CROP,
        PAPERDOLL_BUTTON_ICON_CROP,
        1 - PAPERDOLL_BUTTON_ICON_CROP
    )
    button.icon = icon

    -- Circular border ring.
    local border = button:CreateTexture(nil, "OVERLAY")
    border:SetTexture(PAPERDOLL_BUTTON_BORDER_TEXTURE)
    border:SetWidth(PAPERDOLL_BUTTON_BORDER_SIZE)
    border:SetHeight(PAPERDOLL_BUTTON_BORDER_SIZE)
    border:SetPoint("TOPLEFT", button, "TOPLEFT", 0, 0)
    button.border = border

    -- Mouseover glow.
    button:SetHighlightTexture(PAPERDOLL_BUTTON_HIGHLIGHT_TEXTURE)
    local highlight = button:GetHighlightTexture()
    if highlight then
        highlight:SetBlendMode("ADD")
        highlight:SetWidth(PAPERDOLL_BUTTON_HIGHLIGHT_SIZE)
        highlight:SetHeight(PAPERDOLL_BUTTON_HIGHLIGHT_SIZE)
        highlight:ClearAllPoints()
        highlight:SetPoint("CENTER", button, "CENTER", 0, 0)
    end

    button:SetScript("OnMouseDown", function(selfButton)
        selfButton.bg:ClearAllPoints()
        selfButton.bg:SetPoint("CENTER", selfButton, "CENTER", 1, -1)

        selfButton.icon:ClearAllPoints()
        selfButton.icon:SetPoint("CENTER", selfButton, "CENTER", 1, -1)
    end)

    button:SetScript("OnMouseUp", function(selfButton)
        selfButton.bg:ClearAllPoints()
        selfButton.bg:SetPoint("CENTER", selfButton, "CENTER", 0, 0)

        selfButton.icon:ClearAllPoints()
        selfButton.icon:SetPoint("CENTER", selfButton, "CENTER", 0, 0)
    end)

    button:SetScript("OnClick", function(selfButton, mouseButton)
        if IsControlKeyDown and IsControlKeyDown() then
            RB:ToggleColorSettings()
            return
        end

        if mouseButton == "RightButton" then
            RB:CreateFrame()
            RB.frame:Show()
            RB:RequestRoot()
            return
        end

        RB:Toggle()
    end)

    button:SetScript("OnEnter", function(selfButton)
        GameTooltip:SetOwner(selfButton, "ANCHOR_RIGHT")
        GameTooltip:SetText("Reagent Bank", 1, 0.82, 0)
        GameTooltip:AddLine("Left-click: open or close.", 1, 1, 1)
        GameTooltip:AddLine("Right-click: refresh categories.", 0.82, 0.82, 0.82)
        GameTooltip:AddLine("Ctrl-click: color schema settings.", 0.62, 0.88, 1.00)
        GameTooltip:Show()
    end)

    button:SetScript("OnLeave", HideTooltip)

    self.paperDollButton = button
    self:StylePaperDollButton()
    self:PositionPaperDollButton()

    -- If the AH button addon loads after this addon, retry for a few seconds
    -- and then snap to the right of PaperDollAHButton as soon as it exists.
    button.positionElapsed = 0
    button.positionAttempts = 0
    button:SetScript("OnUpdate", function(selfButton, elapsed)
        selfButton.positionElapsed = (selfButton.positionElapsed or 0) + elapsed
        if selfButton.positionElapsed < 0.25 then
            return
        end

        selfButton.positionElapsed = 0
        selfButton.positionAttempts = (selfButton.positionAttempts or 0) + 1

        RB:PositionPaperDollButton()

        if _G[PAPERDOLL_ANCHOR_BUTTON_NAME] or selfButton.positionAttempts >= 40 then
            selfButton:SetScript("OnUpdate", nil)
        end
    end)

    if parent.HookScript and not parent.ReagentBankUIPositionHooked then
        parent:HookScript("OnShow", function()
            RB:CreatePaperDollButton()
            RB:PositionPaperDollButton()
        end)
        parent.ReagentBankUIPositionHooked = true
    end
end

function RB:UpdateTradeSkillControls()
    if not self.tradeSkillButton then
        return
    end

    ReagentBankUIDB = ReagentBankUIDB or {}

    local needs, errText, recipeName, repeatCount = self:GetSelectedTradeSkillNeeds()
    repeatCount = self:ClampTradeSkillPrepareCount(repeatCount or 1)

    local enabled = errText == nil

    self:SetButtonEnabled(self.tradeSkillButton, enabled)
    self:SetButtonEnabled(self.tradeSkillMinusButton, repeatCount > TRADE_SKILL_PREPARE_COUNT_MIN)
    self:SetButtonEnabled(self.tradeSkillPlusButton, repeatCount < TRADE_SKILL_PREPARE_COUNT_MAX)

    if self.tradeSkillQuantityBox and not self.tradeSkillQuantityBox:HasFocus() then
        local textValue = tostring(repeatCount)
        if self.tradeSkillQuantityBox:GetText() ~= textValue then
            self.suppressTradeSkillQuantityChanged = true
            self.tradeSkillQuantityBox:SetText(textValue)
            self.suppressTradeSkillQuantityChanged = nil
        end
    end

    if needs and #needs > 0 then
        local total = 0
        for _, need in ipairs(needs) do
            total = total + (tonumber(need.amount) or 0)
        end

        if repeatCount > 1 then
            self.tradeSkillButton:SetText("Withdraw x" .. tostring(repeatCount))
            self.tradeSkillButton.tooltipText =
                "Prepare " .. tostring(repeatCount) .. " craft(s) of " .. tostring(recipeName or "selected recipe") ..
                " by withdrawing " .. tostring(total) .. " missing reagent(s)."
        else
            self.tradeSkillButton:SetText("Withdraw Needed")
            self.tradeSkillButton.tooltipText =
                "Withdraw " .. tostring(total) .. " missing reagent(s) for " .. tostring(recipeName or "selected recipe") .. "."
        end
    else
        if repeatCount > 1 then
            self.tradeSkillButton:SetText("Ready x" .. tostring(repeatCount))
        else
            self.tradeSkillButton:SetText("Withdraw Needed")
        end

        if errText then
            self.tradeSkillButton.tooltipText = errText
        else
            self.tradeSkillButton.tooltipText =
                "You already have the selected recipe reagents in your bags for " .. tostring(repeatCount) .. " craft(s)."
        end
    end

    if self.tradeSkillAutoDepositCheck then
        self.tradeSkillAutoDepositCheck:SetChecked(ReagentBankUIDB.autoDepositLeftovers and true or false)
    end

    self:UpdateTradeSkillStatsText()
end

function RB:CreateTradeSkillControls()
    if self.tradeSkillButton then
        self:UpdateTradeSkillControls()
        return
    end

    local parent = _G.TradeSkillFrame
    if not parent then
        return
    end

    local button = self:CreateButton(parent, 132, 22, "Withdraw Needed")
    button:SetFrameLevel((parent:GetFrameLevel() or 1) + 20)

    local createButton = _G.TradeSkillCreateButton
    if createButton then
        button:SetPoint("LEFT", createButton, "RIGHT", 8, 0)
    else
        button:SetPoint("BOTTOMLEFT", parent, "BOTTOMLEFT", 80, 40)
    end

    button:SetScript("OnClick", function()
        RB:WithdrawNeededForSelectedRecipe()
    end)
    button:SetScript("OnEnter", function(selfButton)
        GameTooltip:SetOwner(selfButton, "ANCHOR_RIGHT")
        GameTooltip:SetText("Reagent Bank", 1, 0.82, 0)
        GameTooltip:AddLine(selfButton.tooltipText or "Withdraw missing reagents for the selected recipe.", 1, 1, 1, true)
        GameTooltip:AddLine("Set the count box beside this button to prepare multiple crafts in one click.", 0.82, 0.82, 0.82, true)
        GameTooltip:Show()
    end)
    button:SetScript("OnLeave", HideTooltip)

    self.tradeSkillButton = button

    local quantityLabel = parent:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    quantityLabel:SetPoint("LEFT", button, "RIGHT", 8, 0)
    quantityLabel:SetText("x")
    quantityLabel:SetTextColor(1.00, 0.86, 0.46)
    self.tradeSkillQuantityLabel = quantityLabel

    local quantityBox = CreateFrame("EditBox", "ReagentBankUIPrepareCountBox", parent)
    quantityBox:SetWidth(42)
    quantityBox:SetHeight(22)
    quantityBox:SetAutoFocus(false)
    quantityBox:SetNumeric(true)
    quantityBox:SetFontObject(ChatFontNormal)
    quantityBox:SetTextInsets(6, 6, 0, 0)
    quantityBox:SetBackdrop(BUTTON_BACKDROP)
    quantityBox:SetBackdropColor(SKIN.inputBg[1], SKIN.inputBg[2], SKIN.inputBg[3], SKIN.inputBg[4])
    quantityBox:SetBackdropBorderColor(SKIN.buttonBorder[1], SKIN.buttonBorder[2], SKIN.buttonBorder[3], SKIN.buttonBorder[4])
    quantityBox:SetTextColor(SKIN.inputText[1], SKIN.inputText[2], SKIN.inputText[3], SKIN.inputText[4] or 1)
    quantityBox:SetPoint("LEFT", quantityLabel, "RIGHT", 4, 0)
    quantityBox:SetScript("OnEscapePressed", function(selfBox)
        RB:NormalizeTradeSkillQuantityBox(false)
        selfBox:ClearFocus()
    end)
    quantityBox:SetScript("OnEnterPressed", function(selfBox)
        RB:NormalizeTradeSkillQuantityBox(true)
        selfBox:ClearFocus()
        RB:WithdrawNeededForSelectedRecipe()
    end)
    quantityBox:SetScript("OnEditFocusLost", function()
        RB:NormalizeTradeSkillQuantityBox(false)
    end)
    quantityBox:SetScript("OnTextChanged", function(selfBox)
        if RB.suppressTradeSkillQuantityChanged then
            return
        end

        local value = tonumber(selfBox:GetText())
        if value and value > 0 then
            ReagentBankUIDB = ReagentBankUIDB or {}
            ReagentBankUIDB.tradeSkillPrepareCount = RB:ClampTradeSkillPrepareCount(value)
        end

        RB:UpdateTradeSkillControls()
    end)
    quantityBox:SetScript("OnEnter", function(selfBox)
        GameTooltip:SetOwner(selfBox, "ANCHOR_RIGHT")
        GameTooltip:SetText("Prepare count", 1, 0.82, 0)
        GameTooltip:AddLine("Number of times to prepare the selected recipe's reagents. Press Enter here to withdraw needed reagents.", 1, 1, 1, true)
        GameTooltip:Show()
    end)
    quantityBox:SetScript("OnLeave", HideTooltip)

    self.tradeSkillQuantityBox = quantityBox

    ReagentBankUIDB = ReagentBankUIDB or {}
    local initialCount = tonumber(ReagentBankUIDB.tradeSkillPrepareCount) or self:GetNativeTradeSkillRepeatCount() or 1
    self:SetTradeSkillPrepareCount(initialCount, false)

    if hooksecurefunc and TradeSkillFrame_SetSelection and not self.tradeSkillSelectionHooked then
        hooksecurefunc("TradeSkillFrame_SetSelection", function()
            RB:UpdateTradeSkillControls()
        end)
        self.tradeSkillSelectionHooked = true
    end

    local nativeInput = _G.TradeSkillInputBox
    if nativeInput and nativeInput.HookScript and not self.tradeSkillNativeInputHooked then
        nativeInput:HookScript("OnTextChanged", function(inputBox)
            if RB.suppressNativeTradeSkillQuantityChanged then
                return
            end

            local value = nil
            if inputBox.GetNumber then
                value = tonumber(inputBox:GetNumber())
            end
            if (not value or value <= 0) and inputBox.GetText then
                value = tonumber(inputBox:GetText())
            end

            if value and value > 0 then
                RB:SetTradeSkillPrepareCount(value, false)
            end
        end)
        self.tradeSkillNativeInputHooked = true
    end

    local minusButton = self:CreateButton(parent, 22, 22, "-")
    minusButton:SetFrameLevel((parent:GetFrameLevel() or 1) + 20)
    minusButton:SetPoint("LEFT", quantityBox, "RIGHT", 3, 0)
    minusButton:SetScript("OnClick", function()
        RB:SetTradeSkillPrepareCount(RB:GetTradeSkillRepeatCount() - 1, true)
    end)
    minusButton:SetScript("OnEnter", function(selfButton)
        GameTooltip:SetOwner(selfButton, "ANCHOR_RIGHT")
        GameTooltip:SetText("Decrease prepare count", 1, 0.82, 0)
        GameTooltip:Show()
    end)
    minusButton:SetScript("OnLeave", HideTooltip)
    self.tradeSkillMinusButton = minusButton

    local plusButton = self:CreateButton(parent, 22, 22, "+")
    plusButton:SetFrameLevel((parent:GetFrameLevel() or 1) + 20)
    plusButton:SetPoint("LEFT", minusButton, "RIGHT", 3, 0)
    plusButton:SetScript("OnClick", function()
        RB:SetTradeSkillPrepareCount(RB:GetTradeSkillRepeatCount() + 1, true)
    end)
    plusButton:SetScript("OnEnter", function(selfButton)
        GameTooltip:SetOwner(selfButton, "ANCHOR_RIGHT")
        GameTooltip:SetText("Increase prepare count", 1, 0.82, 0)
        GameTooltip:Show()
    end)
    plusButton:SetScript("OnLeave", HideTooltip)
    self.tradeSkillPlusButton = plusButton

    local check = CreateFrame("CheckButton", "ReagentBankUIAutoDepositLeftoversCheck", parent, "UICheckButtonTemplate")
    check:SetWidth(24)
    check:SetHeight(24)
    check:SetFrameLevel((parent:GetFrameLevel() or 1) + 20)
    check:SetPoint("LEFT", plusButton, "RIGHT", 8, 0)
    check:SetScript("OnClick", function(selfCheck)
        ReagentBankUIDB = ReagentBankUIDB or {}
        ReagentBankUIDB.autoDepositLeftovers = selfCheck:GetChecked() and true or false
        if not ReagentBankUIDB.autoDepositLeftovers then
            RB.pendingAutoDepositLeftovers = nil
            RB.pendingAutoDepositAt = nil
        end
        RB:UpdateTradeSkillControls()
    end)
    check:SetScript("OnEnter", function(selfCheck)
        GameTooltip:SetOwner(selfCheck, "ANCHOR_RIGHT")
        GameTooltip:SetText("Auto-deposit leftovers", 1, 0.82, 0)
        GameTooltip:AddLine("When you close the profession window, deposit prepared reagent leftovers back into the reagent bank. It preserves the bag counts you had before Withdraw Needed.", 1, 1, 1, true)
        GameTooltip:Show()
    end)
    check:SetScript("OnLeave", HideTooltip)

    local checkText = _G[check:GetName() .. "Text"]
    if checkText then
        checkText:SetText("Auto-deposit leftovers")
        checkText:SetTextColor(1.00, 0.86, 0.46)
    end

    local statsText = parent:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    statsText:SetPoint("TOPLEFT", button, "BOTTOMLEFT", 0, -6)
    statsText:SetPoint("RIGHT", parent, "RIGHT", -28, 0)
    statsText:SetJustifyH("LEFT")
    statsText:SetTextColor(0.82, 0.82, 0.82)
    statsText:SetText("")
    statsText:Hide()
    self.tradeSkillStatsText = statsText

    self.tradeSkillAutoDepositCheck = check
    self:UpdateTradeSkillControls()
end

function RB:ApplyScale()
    if not self.frame then
        return
    end

    ReagentBankUIDB = ReagentBankUIDB or {}
    local scale = Clamp(ReagentBankUIDB.scale or DEFAULT_SCALE, 0.75, 1.20)

    ReagentBankUIDB.scale = scale
    self.frame:SetScale(scale)
end

function RB:CreateButton(parent, width, height, label)
    local button = CreateFrame("Button", nil, parent, "ReagentBankUIButtonTemplate")
    button:SetWidth(width)
    button:SetHeight(height)
    button:SetBackdrop(BUTTON_BACKDROP)
    button:SetBackdropColor(SKIN.buttonBg[1], SKIN.buttonBg[2], SKIN.buttonBg[3], SKIN.buttonBg[4])
    button:SetBackdropBorderColor(SKIN.buttonBorder[1], SKIN.buttonBorder[2], SKIN.buttonBorder[3], SKIN.buttonBorder[4])

    if button.hover then
        button:SetHighlightTexture(button.hover)
    end

    if button.label then
        button.label:SetText(label or "")
        button:SetFontString(button.label)
    end

    button:SetText(label or "")
    self:StyleButton(button)

    button:SetScript("OnMouseDown", function(selfButton)
        if not selfButton:IsEnabled() then
            return
        end

        selfButton:SetBackdropColor(SKIN.buttonDown[1], SKIN.buttonDown[2], SKIN.buttonDown[3], SKIN.buttonDown[4])
        if selfButton.label then
            selfButton.label:ClearAllPoints()
            selfButton.label:SetPoint("CENTER", selfButton, "CENTER", 1, -1)
        end
    end)

    button:SetScript("OnMouseUp", function(selfButton)
        selfButton:SetBackdropColor(SKIN.buttonBg[1], SKIN.buttonBg[2], SKIN.buttonBg[3], SKIN.buttonBg[4])
        if selfButton.label then
            selfButton.label:ClearAllPoints()
            selfButton.label:SetPoint("CENTER", selfButton, "CENTER", 0, 0)
        end
    end)

    return button
end

function RB:CreateEditBox(parent, width, height)
    local box = CreateFrame("EditBox", nil, parent, "ReagentBankUIEditBoxTemplate")
    box:SetWidth(width)
    box:SetHeight(height)
    box:SetAutoFocus(false)
    box:SetNumeric(true)
    box:SetFontObject(ChatFontNormal)
    box:SetTextInsets(6, 6, 0, 0)
    box:SetBackdrop(BUTTON_BACKDROP)
    box:SetBackdropColor(SKIN.inputBg[1], SKIN.inputBg[2], SKIN.inputBg[3], SKIN.inputBg[4])
    box:SetBackdropBorderColor(SKIN.buttonBorder[1], SKIN.buttonBorder[2], SKIN.buttonBorder[3], SKIN.buttonBorder[4])
    box:SetTextColor(SKIN.inputText[1], SKIN.inputText[2], SKIN.inputText[3], SKIN.inputText[4] or 1)
    box:SetScript("OnEscapePressed", function(selfBox)
        selfBox:ClearFocus()
    end)
    box:SetScript("OnEnterPressed", function(selfBox)
        selfBox:ClearFocus()
        RB:WithdrawItemExact()
    end)
    box:SetScript("OnTextChanged", function()
        RB:UpdateControls()
    end)

    return box
end

function RB:CreateCloseButton(parent)
    local button = CreateFrame("Button", nil, parent, "ReagentBankUICloseButtonTemplate")
    button:SetWidth(24)
    button:SetHeight(24)
    button:SetBackdrop(BUTTON_BACKDROP)
    button:SetBackdropColor(SKIN.closeBg[1], SKIN.closeBg[2], SKIN.closeBg[3], SKIN.closeBg[4])
    button:SetBackdropBorderColor(SKIN.closeBorder[1], SKIN.closeBorder[2], SKIN.closeBorder[3], SKIN.closeBorder[4])

    if button.hover then
        button:SetHighlightTexture(button.hover)
    end

    if button.label then
        button.label:SetText("X")
    end

    self:StyleCloseButton(button)

    button:SetScript("OnMouseDown", function(selfButton)
        if selfButton.label then
            selfButton.label:ClearAllPoints()
            selfButton.label:SetPoint("CENTER", selfButton, "CENTER", 1, 0)
        end
    end)

    button:SetScript("OnMouseUp", function(selfButton)
        if selfButton.label then
            selfButton.label:ClearAllPoints()
            selfButton.label:SetPoint("CENTER", selfButton, "CENTER", 0, 1)
        end
    end)

    return button
end

function RB:CreateLabel(parent, text, template)
    local label = parent:CreateFontString(nil, "OVERLAY", template or "GameFontHighlightSmall")
    label:SetText(text or "")
    label:SetJustifyH("LEFT")
    return label
end

function RB:CreateFrame()
    if self.frame then
        return
    end

    local f = CreateFrame("Frame", "ReagentBankUIFrame", UIParent)
    f:SetWidth(MAIN_FRAME_WIDTH)
    f:SetHeight(MAIN_FRAME_HEIGHT)
    f:SetPoint("CENTER")
    f:SetMovable(true)
    f:EnableMouse(true)
    f:SetClampedToScreen(true)
    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", function(selfFrame)
        selfFrame:StartMoving()
    end)
    f:SetScript("OnDragStop", function(selfFrame)
        selfFrame:StopMovingOrSizing()

        ReagentBankUIDB = ReagentBankUIDB or {}
        local point, relativeTo, relativePoint, xOfs, yOfs = selfFrame:GetPoint(1)

        ReagentBankUIDB.point = point
        ReagentBankUIDB.relativePoint = relativePoint
        ReagentBankUIDB.xOfs = xOfs
        ReagentBankUIDB.yOfs = yOfs
    end)

    f.shadow = f:CreateTexture(nil, "BACKGROUND")
    f.shadow:SetTexture("Interface\\ChatFrame\\ChatFrameBackground")
    f.shadow:SetPoint("TOPLEFT", -6, 6)
    f.shadow:SetPoint("BOTTOMRIGHT", 6, -6)
    f.shadow:SetVertexColor(0.00, 0.00, 0.00, 0.50)

    self:MakeBackdrop(f, 0.98)

    f.header = CreateFrame("Frame", nil, f)
    f.header:SetPoint("TOPLEFT", 8, -8)
    f.header:SetPoint("TOPRIGHT", -8, -8)
    f.header:SetHeight(42)
    f.header:SetBackdrop(PANEL_BACKDROP)
    f.header:SetBackdropColor(SKIN.headerBg[1], SKIN.headerBg[2], SKIN.headerBg[3], SKIN.headerBg[4])
    f.header:SetBackdropBorderColor(SKIN.windowBorder[1], SKIN.windowBorder[2], SKIN.windowBorder[3], SKIN.windowBorder[4])

    f.headerGlow = f.header:CreateTexture(nil, "ARTWORK")
    f.headerGlow:SetTexture("Interface\\ChatFrame\\ChatFrameBackground")
    f.headerGlow:SetPoint("TOPLEFT", 2, -2)
    f.headerGlow:SetPoint("TOPRIGHT", -2, -2)
    f.headerGlow:SetHeight(15)
    f.headerGlow:SetVertexColor(1.00, 0.74, 0.22, 0.10)

    f.headerLine = f:CreateTexture(nil, "ARTWORK")
    f.headerLine:SetTexture("Interface\\ChatFrame\\ChatFrameBackground")
    f.headerLine:SetPoint("TOPLEFT", f.header, "BOTTOMLEFT", 0, -4)
    f.headerLine:SetPoint("TOPRIGHT", f.header, "BOTTOMRIGHT", 0, -4)
    f.headerLine:SetHeight(1)
    f.headerLine:SetVertexColor(SKIN.headerLine[1], SKIN.headerLine[2], SKIN.headerLine[3], SKIN.headerLine[4])

    f.title = f.header:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    f.title:SetPoint("LEFT", 12, 1)
    f.title:SetText("Reagent Bank")
    f.title:SetJustifyH("LEFT")
    f.title:SetTextColor(1.00, 0.82, 0.28)

    f.modeText = f.header:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    f.modeText:SetPoint("LEFT", f.title, "RIGHT", 14, -1)
    f.modeText:SetPoint("RIGHT", -44, 0)
    f.modeText:SetJustifyH("LEFT")
    f.modeText:SetTextColor(0.78, 0.82, 0.88)
    f.modeText:SetText("")

    f.close = self:CreateCloseButton(f.header)
    f.close:SetPoint("RIGHT", -9, 0)
    f.close:SetScript("OnClick", function()
        RB:Close()
    end)

    f.rootDeposit = self:CreateButton(f, ROOT_ACTION_BUTTON_WIDTH, ROOT_BUTTON_HEIGHT, "Deposit All")
    f.rootDeposit:SetPoint("TOPLEFT", ROOT_BUTTON_ROW_X, ROOT_BUTTON_ROW_Y)
    f.rootDeposit:SetScript("OnClick", function()
        RB:DepositAll()
    end)

    f.rootWithdraw = self:CreateButton(f, ROOT_ACTION_BUTTON_WIDTH, ROOT_BUTTON_HEIGHT, "Withdraw All")
    f.rootWithdraw:SetPoint("LEFT", f.rootDeposit, "RIGHT", ROOT_BUTTON_GAP, 0)
    f.rootWithdraw:SetScript("OnClick", function()
        RB:WithdrawAll()
    end)

    f.refresh = self:CreateButton(f, ROOT_REFRESH_BUTTON_WIDTH, ROOT_BUTTON_HEIGHT, "Refresh")
    f.refresh:SetPoint("LEFT", f.rootWithdraw, "RIGHT", ROOT_BUTTON_GAP, 0)
    f.refresh:SetScript("OnClick", function()
        if RB.currentView == "category" and RB.currentCategoryId then
            RB:RequestCategory(RB.currentCategoryId, RB.currentPage or 0)
        elseif RB.currentView == "detail" and RB.currentCategoryId then
            RB:RequestCategory(RB.currentCategoryId, RB.currentPage or 0)
        else
            RB:RequestRoot()
        end
    end)

    f.sortMode = self:CreateButton(f, ROOT_SORT_BUTTON_WIDTH, ROOT_BUTTON_HEIGHT, "Sort: ID")
    f.sortMode:SetPoint("LEFT", f.refresh, "RIGHT", ROOT_BUTTON_GAP, 0)
    f.sortMode:SetScript("OnClick", function()
        RB:CycleSortMode()
    end)
    f.sortMode:SetScript("OnEnter", function(selfButton)
        GameTooltip:SetOwner(selfButton, "ANCHOR_RIGHT")
        GameTooltip:SetText("Reagent Bank Sorting", 1, 0.82, 0)
        GameTooltip:AddLine(selfButton.tooltipText or "Cycle sorting.", 1, 1, 1, true)
        GameTooltip:Show()
    end)
    f.sortMode:SetScript("OnLeave", HideTooltip)

    f.previewToggle = self:CreateButton(f, ROOT_PREVIEW_TOGGLE_BUTTON_WIDTH, ROOT_BUTTON_HEIGHT, "Preview: On")
    f.previewToggle:SetPoint("LEFT", f.sortMode, "RIGHT", ROOT_BUTTON_GAP, 0)
    f.previewToggle:SetScript("OnClick", function()
        RB:ToggleDepositPreviewEnabled()
    end)
    f.previewToggle:SetScript("OnEnter", function(selfButton)
        GameTooltip:SetOwner(selfButton, "ANCHOR_RIGHT")
        GameTooltip:SetText("Deposit Preview Confirmation", 1, 0.82, 0)
        GameTooltip:AddLine(selfButton.tooltipText or "Toggle deposit confirmation previews.", 1, 1, 1, true)
        GameTooltip:Show()
    end)
    f.previewToggle:SetScript("OnLeave", HideTooltip)

    f.helpText = f:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    f.helpText:SetPoint("LEFT", f.previewToggle, "RIGHT", ROOT_HELP_TEXT_GAP, 0)
    f.helpText:SetPoint("RIGHT", -18, 0)
    f.helpText:SetJustifyH("LEFT")
    f.helpText:SetTextColor(0.55, 0.58, 0.64)
    f.helpText:SetText("")
    f.helpText:Hide()

    f.back = self:CreateButton(f, CATEGORY_BACK_BUTTON_WIDTH, CATEGORY_BUTTON_HEIGHT, "Categories")
    f.back:SetPoint("TOPLEFT", CATEGORY_BUTTON_ROW_X, CATEGORY_BUTTON_ROW_Y)
    f.back:SetScript("OnClick", function()
        RB:RequestRoot()
    end)

    f.catDeposit = self:CreateButton(f, CATEGORY_ACTION_BUTTON_WIDTH, CATEGORY_BUTTON_HEIGHT, "Deposit Category")
    f.catDeposit:SetPoint("LEFT", f.back, "RIGHT", CATEGORY_BUTTON_GAP, 0)
    f.catDeposit:SetScript("OnClick", function()
        RB:DepositCategory()
    end)

    f.catWithdraw = self:CreateButton(f, CATEGORY_ACTION_BUTTON_WIDTH, CATEGORY_BUTTON_HEIGHT, "Withdraw Category")
    f.catWithdraw:SetPoint("LEFT", f.catDeposit, "RIGHT", CATEGORY_BUTTON_GAP, 0)
    f.catWithdraw:SetScript("OnClick", function()
        RB:WithdrawCategory()
    end)

    f.prev = self:CreateButton(f, CATEGORY_PAGE_BUTTON_WIDTH, CATEGORY_BUTTON_HEIGHT, "Prev")
    f.prev:SetPoint("LEFT", f.catWithdraw, "RIGHT", CATEGORY_BUTTON_GAP, 0)
    f.prev:SetScript("OnClick", function()
        if RB.currentCategoryId and RB.currentPage and RB.currentPage > 0 then
            RB:RequestCategory(RB.currentCategoryId, RB.currentPage - 1)
        end
    end)

    f.next = self:CreateButton(f, CATEGORY_PAGE_BUTTON_WIDTH, CATEGORY_BUTTON_HEIGHT, "Next")
    f.next:SetPoint("LEFT", f.prev, "RIGHT", CATEGORY_BUTTON_GAP, 0)
    f.next:SetScript("OnClick", function()
        if RB.currentCategoryId and RB.currentPage and RB.totalPages and RB.currentPage + 1 < RB.totalPages then
            RB:RequestCategory(RB.currentCategoryId, RB.currentPage + 1)
        end
    end)

    f.pageText = f:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    f.pageText:SetPoint("LEFT", f.next, "RIGHT", CATEGORY_PAGE_TEXT_GAP, 0)
    f.pageText:SetPoint("RIGHT", -18, 0)
    f.pageText:SetJustifyH("RIGHT")
    f.pageText:SetText("")

    f.list = CreateFrame("Frame", nil, f)
    f.list:SetPoint("TOPLEFT", 18, -118)
    f.list:SetPoint("BOTTOMRIGHT", -18, 54)
    self:MakeBackdrop(f.list, 0.78, true)

    f.listHeader = CreateFrame("Frame", nil, f.list)
    f.listHeader:SetHeight(24)
    f.listHeader:SetPoint("TOPLEFT", 8, -7)
    f.listHeader:SetPoint("RIGHT", -8, 0)

    f.listHeader.bg = f.listHeader:CreateTexture(nil, "BACKGROUND")
    f.listHeader.bg:SetTexture("Interface\\ChatFrame\\ChatFrameBackground")
    f.listHeader.bg:SetAllPoints(f.listHeader)
    f.listHeader.bg:SetVertexColor(0.11, 0.085, 0.045, 0.72)

    f.listHeader.line = f.listHeader:CreateTexture(nil, "ARTWORK")
    f.listHeader.line:SetTexture("Interface\\ChatFrame\\ChatFrameBackground")
    f.listHeader.line:SetPoint("BOTTOMLEFT", 0, 0)
    f.listHeader.line:SetPoint("BOTTOMRIGHT", 0, 0)
    f.listHeader.line:SetHeight(1)
    f.listHeader.line:SetVertexColor(SKIN.headerLine[1], SKIN.headerLine[2], SKIN.headerLine[3], 0.70)

    f.headerName = f.listHeader:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    f.headerName:SetPoint("LEFT", 32, 0)
    f.headerName:SetJustifyH("LEFT")
    f.headerName:SetText("Name")

    f.headerCount = f.listHeader:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    f.headerCount:SetPoint("RIGHT", -8, 0)
    f.headerCount:SetJustifyH("RIGHT")
    f.headerCount:SetText("Stored")

    f.rows = {}
    for i = 1, ROW_COUNT do
        local row = CreateFrame("Button", nil, f.list, "ReagentBankUIListRowTemplate")
        row:SetHeight(ROW_HEIGHT)
        row:SetPoint("LEFT", 8, 0)
        row:SetPoint("RIGHT", -8, 0)

        if i == 1 then
            row:SetPoint("TOP", f.listHeader, "BOTTOM", 0, -2)
        else
            row:SetPoint("TOP", f.rows[i - 1], "BOTTOM", 0, -ROW_SPACING)
        end

        if row.fill then
            row.fill:SetHeight(ROW_HEIGHT)
            row.fill:SetWidth(1)
            row.fill:Hide()
        end

        if row.hover then
            row:SetHighlightTexture(row.hover)
        end

        if (i % 2) == 0 then
            SetTextureColor(row.bg, SKIN.rowEven)
        else
            SetTextureColor(row.bg, SKIN.rowOdd)
        end
        SetTextureColor(row.fill, SKIN.rowFill)
        SetTextureColor(row.hover, SKIN.rowHover)
        SetFontColor(row.count, SKIN.blueText)

        row:RegisterForClicks("LeftButtonUp", "RightButtonUp")
        row:SetScript("OnClick", function(selfRow, mouseButton)
            if selfRow.kind == "category" and selfRow.categoryId then
                RB:HideWithdrawPrompt()
                RB:RequestCategory(selfRow.categoryId, 0)
            elseif selfRow.kind == "item" and selfRow.item then
                if mouseButton == "RightButton" then
                    RB:ShowWithdrawPrompt(selfRow.item)
                else
                    RB:HideWithdrawPrompt()
                    RB:ShowDetail(selfRow.item)
                end
            end
        end)

        row:SetScript("OnEnter", function(selfRow)
            if selfRow.kind == "item" and selfRow.item and selfRow.item.entry then
                SetTooltipItem(selfRow.item.entry)
            end
        end)

        row:SetScript("OnLeave", HideTooltip)

        f.rows[i] = row
    end

    f.detail = CreateFrame("Frame", nil, f)
    f.detail:SetPoint("TOPLEFT", 18, -118)
    f.detail:SetPoint("BOTTOMRIGHT", -18, 54)
    self:MakeBackdrop(f.detail, 0.78, true)

    f.detailIconBorder = CreateFrame("Frame", nil, f.detail)
    f.detailIconBorder:SetWidth(62)
    f.detailIconBorder:SetHeight(62)
    f.detailIconBorder:SetPoint("TOPLEFT", 16, -16)
    f.detailIconBorder:SetBackdrop(BUTTON_BACKDROP)
    f.detailIconBorder:SetBackdropColor(0.02, 0.02, 0.03, 0.90)
    f.detailIconBorder:SetBackdropBorderColor(SKIN.buttonBorder[1], SKIN.buttonBorder[2], SKIN.buttonBorder[3], SKIN.buttonBorder[4])

    f.detailIcon = f.detailIconBorder:CreateTexture(nil, "ARTWORK")
    f.detailIcon:SetWidth(54)
    f.detailIcon:SetHeight(54)
    f.detailIcon:SetPoint("CENTER", 0, 0)

    f.detailName = f.detail:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    f.detailName:SetPoint("TOPLEFT", f.detailIconBorder, "TOPRIGHT", 14, -2)
    f.detailName:SetPoint("RIGHT", -18, 0)
    f.detailName:SetJustifyH("LEFT")

    f.detailStored = f.detail:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    f.detailStored:SetPoint("TOPLEFT", f.detailName, "BOTTOMLEFT", 0, -8)
    f.detailStored:SetJustifyH("LEFT")

    f.detailHint = f.detail:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    f.detailHint:SetPoint("TOPLEFT", f.detailStored, "BOTTOMLEFT", 0, -8)
    f.detailHint:SetPoint("RIGHT", -18, 0)
    f.detailHint:SetJustifyH("LEFT")
    f.detailHint:SetText("Withdraw one stack, all, or type an exact amount. Counts refresh from the server after each action.")

    f.withdrawOne = self:CreateButton(f.detail, 132, 28, "Withdraw 1")
    f.withdrawOne:SetPoint("TOPLEFT", 18, -112)
    f.withdrawOne:SetScript("OnClick", function()
        RB:WithdrawItem("one")
    end)

    f.withdrawStack = self:CreateButton(f.detail, 132, 28, "Withdraw Stack")
    f.withdrawStack:SetPoint("LEFT", f.withdrawOne, "RIGHT", 10, 0)
    f.withdrawStack:SetScript("OnClick", function()
        RB:WithdrawItem("stack")
    end)

    f.withdrawItemAll = self:CreateButton(f.detail, 132, 28, "Withdraw All")
    f.withdrawItemAll:SetPoint("LEFT", f.withdrawStack, "RIGHT", 10, 0)
    f.withdrawItemAll:SetScript("OnClick", function()
        RB:WithdrawItem("all")
    end)

    f.exactLabel = f.detail:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    f.exactLabel:SetPoint("TOPLEFT", 20, -154)
    f.exactLabel:SetText("Exact amount:")
    f.exactLabel:SetJustifyH("LEFT")

    f.exactBox = self:CreateEditBox(f.detail, 82, 24)
    f.exactBox:SetPoint("LEFT", f.exactLabel, "RIGHT", 10, 0)

    f.withdrawExact = self:CreateButton(f.detail, 132, 28, "Withdraw Exact")
    f.withdrawExact:SetPoint("LEFT", f.exactBox, "RIGHT", 10, 0)
    f.withdrawExact:SetScript("OnClick", function()
        RB:WithdrawItemExact()
    end)

    f.detailBack = self:CreateButton(f.detail, 132, 28, "Back to List")
    f.detailBack:SetPoint("LEFT", f.withdrawItemAll, "RIGHT", 10, 0)
    f.detailBack:SetScript("OnClick", function()
        if RB.currentCategoryId then
            RB:RenderCategory()
        else
            RB:RequestRoot()
        end
    end)

    f.detail:SetScript("OnEnter", function()
        if RB.detailItem and RB.detailItem.entry then
            SetTooltipItem(RB.detailItem.entry)
        end
    end)
    f.detail:SetScript("OnLeave", HideTooltip)

    f.quickWithdraw = CreateFrame("Frame", nil, f)
    f.quickWithdraw:SetWidth(QUICK_WITHDRAW_WIDTH)
    f.quickWithdraw:SetHeight(154)
    f.quickWithdraw:SetPoint("CENTER", f, "CENTER", 0, 18)
    f.quickWithdraw:SetFrameLevel((f:GetFrameLevel() or 1) + 80)
    f.quickWithdraw:EnableMouse(true)
    self:MakeBackdrop(f.quickWithdraw, 0.98, true)
    f.quickWithdraw:Hide()

    f.quickWithdrawTitle = f.quickWithdraw:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    f.quickWithdrawTitle:SetPoint("TOPLEFT", 16, -13)
    f.quickWithdrawTitle:SetText("Withdraw Item")
    f.quickWithdrawTitle:SetTextColor(1.00, 0.82, 0.28)

    f.quickWithdrawClose = self:CreateCloseButton(f.quickWithdraw)
    f.quickWithdrawClose:SetPoint("TOPRIGHT", -8, -8)
    f.quickWithdrawClose:SetScript("OnClick", function()
        RB:HideWithdrawPrompt()
    end)

    f.quickWithdrawIcon = f.quickWithdraw:CreateTexture(nil, "ARTWORK")
    f.quickWithdrawIcon:SetWidth(38)
    f.quickWithdrawIcon:SetHeight(38)
    f.quickWithdrawIcon:SetPoint("TOPLEFT", 18, -44)

    f.quickWithdrawName = f.quickWithdraw:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    f.quickWithdrawName:SetPoint("TOPLEFT", f.quickWithdrawIcon, "TOPRIGHT", 10, -1)
    f.quickWithdrawName:SetPoint("RIGHT", -18, 0)
    f.quickWithdrawName:SetJustifyH("LEFT")

    f.quickWithdrawStored = f.quickWithdraw:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    f.quickWithdrawStored:SetPoint("TOPLEFT", f.quickWithdrawName, "BOTTOMLEFT", 0, -5)
    f.quickWithdrawStored:SetJustifyH("LEFT")

    f.quickWithdrawLabel = f.quickWithdraw:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    f.quickWithdrawLabel:SetPoint("TOPLEFT", 18, -94)
    f.quickWithdrawLabel:SetText("Amount:")
    f.quickWithdrawLabel:SetJustifyH("LEFT")

    f.quickWithdrawBox = self:CreateEditBox(f.quickWithdraw, 82, 24)
    f.quickWithdrawBox:SetPoint("LEFT", f.quickWithdrawLabel, "RIGHT", 10, 0)
    f.quickWithdrawBox:SetScript("OnEnterPressed", function(selfBox)
        selfBox:ClearFocus()
        RB:ConfirmWithdrawPrompt()
    end)
    f.quickWithdrawBox:SetScript("OnEscapePressed", function(selfBox)
        selfBox:ClearFocus()
        RB:HideWithdrawPrompt()
    end)
    f.quickWithdrawBox:SetScript("OnTextChanged", function()
        RB:UpdateQuickWithdrawControls()
    end)

    f.quickWithdrawButton = self:CreateButton(f.quickWithdraw, 112, 26, "Withdraw")
    f.quickWithdrawButton:SetPoint("LEFT", f.quickWithdrawBox, "RIGHT", 10, 0)
    f.quickWithdrawButton:SetScript("OnClick", function()
        RB:ConfirmWithdrawPrompt()
    end)

    f.quickWithdrawAll = self:CreateButton(f.quickWithdraw, 82, 26, "All")
    f.quickWithdrawAll:SetPoint("LEFT", f.quickWithdrawButton, "RIGHT", 8, 0)
    f.quickWithdrawAll:SetScript("OnClick", function()
        RB:SetWithdrawPromptAmountToAll()
    end)

    f.quickWithdrawCancel = self:CreateButton(f.quickWithdraw, 82, 26, "Cancel")
    f.quickWithdrawCancel:SetPoint("LEFT", f.quickWithdrawAll, "RIGHT", 8, 0)
    f.quickWithdrawCancel:SetScript("OnClick", function()
        RB:HideWithdrawPrompt()
    end)

    f.quickWithdrawHint = f.quickWithdraw:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    f.quickWithdrawHint:SetPoint("TOPLEFT", 18, -126)
    f.quickWithdrawHint:SetPoint("RIGHT", -18, 0)
    f.quickWithdrawHint:SetJustifyH("LEFT")
    f.quickWithdrawHint:SetText("")

    f.depositPreview = CreateFrame("Frame", nil, f)
    f.depositPreview:SetWidth(520)
    f.depositPreview:SetHeight(370)
    f.depositPreview:SetPoint("CENTER", f, "CENTER", 0, 8)
    f.depositPreview:SetFrameLevel((f:GetFrameLevel() or 1) + 90)
    f.depositPreview:EnableMouse(true)
    self:MakeBackdrop(f.depositPreview, 0.98, true)
    f.depositPreview:Hide()

    f.depositPreview.title = f.depositPreview:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    f.depositPreview.title:SetPoint("TOPLEFT", 16, -13)
    f.depositPreview.title:SetPoint("RIGHT", -48, 0)
    f.depositPreview.title:SetJustifyH("LEFT")
    f.depositPreview.title:SetTextColor(1.00, 0.82, 0.28)
    f.depositPreview.title:SetText("Deposit Preview")

    f.depositPreview.close = self:CreateCloseButton(f.depositPreview)
    f.depositPreview.close:SetPoint("TOPRIGHT", -8, -8)
    f.depositPreview.close:SetScript("OnClick", function()
        RB:HideDepositPreview()
    end)

    f.depositPreview.summary = f.depositPreview:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    f.depositPreview.summary:SetPoint("TOPLEFT", 18, -42)
    f.depositPreview.summary:SetPoint("RIGHT", -18, 0)
    f.depositPreview.summary:SetJustifyH("LEFT")
    f.depositPreview.summary:SetTextColor(0.82, 0.82, 0.82)
    f.depositPreview.summary:SetText("")

    f.depositPreview.rows = {}
    for previewIndex = 1, DEPOSIT_PREVIEW_ROW_COUNT do
        local previewRow = CreateFrame("Frame", nil, f.depositPreview, "ReagentBankUIPreviewRowTemplate")
        previewRow:SetHeight(22)
        previewRow:SetPoint("LEFT", 18, 0)
        previewRow:SetPoint("RIGHT", -18, 0)

        if previewIndex == 1 then
            previewRow:SetPoint("TOP", f.depositPreview.summary, "BOTTOM", 0, -12)
        else
            previewRow:SetPoint("TOP", f.depositPreview.rows[previewIndex - 1], "BOTTOM", 0, -3)
        end

        if (previewIndex % 2) == 0 then
            SetTextureColor(previewRow.bg, SKIN.rowEven, 0.28)
        else
            SetTextureColor(previewRow.bg, SKIN.rowOdd, 0.38)
        end
        if previewRow.name then
            previewRow.name:ClearAllPoints()
            previewRow.name:SetPoint("LEFT", previewRow.icon, "RIGHT", 8, 0)
            previewRow.name:SetPoint("RIGHT", -110, 0)
            previewRow.name:SetJustifyH("LEFT")
        end

        SetFontColor(previewRow.name, SKIN.buttonText)
        SetFontColor(previewRow.count, SKIN.blueText)

        f.depositPreview.rows[previewIndex] = previewRow
    end

    f.depositPreview.more = f.depositPreview:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    f.depositPreview.more:SetPoint("TOPLEFT", f.depositPreview.rows[DEPOSIT_PREVIEW_ROW_COUNT], "BOTTOMLEFT", 2, -7)
    f.depositPreview.more:SetPoint("RIGHT", -18, 0)
    f.depositPreview.more:SetJustifyH("LEFT")
    f.depositPreview.more:SetText("")

    f.depositPreview.confirm = self:CreateButton(f.depositPreview, 132, 28, "Confirm")
    f.depositPreview.confirm:SetPoint("BOTTOMRIGHT", -154, 16)
    f.depositPreview.confirm:SetScript("OnClick", function()
        RB:ConfirmDepositPreview()
    end)

    f.depositPreview.cancel = self:CreateButton(f.depositPreview, 112, 28, "Cancel")
    f.depositPreview.cancel:SetPoint("LEFT", f.depositPreview.confirm, "RIGHT", 10, 0)
    f.depositPreview.cancel:SetScript("OnClick", function()
        RB:HideDepositPreview()
    end)

    f.footer = CreateFrame("Frame", nil, f)
    f.footer:SetPoint("BOTTOMLEFT", 18, 18)
    f.footer:SetPoint("BOTTOMRIGHT", -18, 18)
    f.footer:SetHeight(24)
    self:MakeBackdrop(f.footer, 0.58, true)

    f.undoLast = self:CreateButton(f.footer, UNDO_BUTTON_WIDTH, 20, "Reverse Last")
    f.undoLast:SetPoint("RIGHT", -3, 0)
    f.undoLast:SetScript("OnClick", function()
        RB:ReverseLastTransaction()
    end)
    f.undoLast:SetScript("OnEnter", function(selfButton)
        GameTooltip:SetOwner(selfButton, "ANCHOR_RIGHT")
        GameTooltip:SetText("Reverse last reagent bank action", 1, 0.82, 0)
        GameTooltip:AddLine(selfButton.tooltipText or "No reversible transaction is available.", 1, 1, 1, true)
        GameTooltip:Show()
    end)
    f.undoLast:SetScript("OnLeave", HideTooltip)

    f.status = f.footer:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    f.status:SetPoint("LEFT", 8, 0)
    f.status:SetPoint("RIGHT", f.undoLast, "LEFT", -8, 0)
    f.status:SetJustifyH("LEFT")
    f.status:SetText("")

    f:Hide()

    self.frame = f
    self:ApplyScale()
    self:ApplySkin()
    self:UpdateControls()
end

function RB:ApplySavedPosition()
    self:CreateFrame()

    ReagentBankUIDB = ReagentBankUIDB or {}
    if ReagentBankUIDB.point and ReagentBankUIDB.relativePoint and ReagentBankUIDB.xOfs and ReagentBankUIDB.yOfs then
        self.frame:ClearAllPoints()
        self.frame:SetPoint(ReagentBankUIDB.point, UIParent, ReagentBankUIDB.relativePoint, ReagentBankUIDB.xOfs, ReagentBankUIDB.yOfs)
    end
end

function RB:SetCommonVisibility(view)
    self:CreateFrame()

    local f = self.frame
    local rootView = view == "root"
    local categoryView = view == "category"
    local detailView = view == "detail"

    f.rootDeposit:Show()
    f.rootWithdraw:Show()
    f.refresh:Show()

    if categoryView or detailView then
        f.back:Show()
    else
        f.back:Hide()
    end

    if categoryView then
        f.catDeposit:Show()
        f.catWithdraw:Show()
        f.prev:Show()
        f.next:Show()
        f.pageText:Show()
    else
        f.catDeposit:Hide()
        f.catWithdraw:Hide()
        f.prev:Hide()
        f.next:Hide()
        f.pageText:Hide()
    end

    if rootView or categoryView then
        f.list:Show()
    else
        f.list:Hide()
    end

    if detailView then
        f.detail:Show()
    else
        f.detail:Hide()
    end
end

function RB:UpdateControls()
    if not self.frame then
        return
    end

    local f = self.frame
    local busy = self.busyKind ~= nil
    local page = tonumber(self.currentPage) or 0
    local totalPages = math.max(tonumber(self.totalPages) or 1, 1)
    local inCategory = self.currentView == "category"
    local inDetail = self.currentView == "detail"
    local hasCategory = self.currentCategoryId ~= nil

    if self.busyKind == "request" then
        f.refresh:SetText("Refreshing")
    else
        f.refresh:SetText("Refresh")
    end

    self:SetButtonEnabled(f.refresh, not busy)
    self:SetButtonEnabled(f.rootDeposit, not busy)
    self:SetButtonEnabled(f.rootWithdraw, not busy)
    self:SetButtonEnabled(f.sortMode, not busy)
    self:SetButtonEnabled(f.previewToggle, not busy)
    self:SetButtonEnabled(f.back, not busy)
    self:SetButtonEnabled(f.catDeposit, not busy and inCategory and hasCategory)
    self:SetButtonEnabled(f.catWithdraw, not busy and inCategory and hasCategory)
    self:SetButtonEnabled(f.prev, not busy and inCategory and page > 0)
    self:SetButtonEnabled(f.next, not busy and inCategory and page + 1 < totalPages)

    local stored = 0
    if self.detailItem then
        stored = tonumber(self.detailItem.amount) or 0
    end

    local exactAmount = self:GetExactWithdrawAmount()

    self:SetButtonEnabled(f.withdrawOne, not busy and inDetail and stored >= 1)
    self:SetButtonEnabled(f.withdrawStack, not busy and inDetail and stored >= 1)
    self:SetButtonEnabled(f.withdrawItemAll, not busy and inDetail and stored >= 1)
    self:SetButtonEnabled(f.withdrawExact, not busy and inDetail and stored >= 1 and exactAmount >= 1)
    self:SetButtonEnabled(f.detailBack, not busy)

    if f.depositPreview then
        self:SetButtonEnabled(f.depositPreview.confirm, not busy and self.depositPreview ~= nil)
        self:SetButtonEnabled(f.depositPreview.cancel, true)
    end

    self:UpdateSortButton()
    self:UpdatePreviewToggleButton()
    self:UpdateQuickWithdrawControls()
    self:UpdateUndoButton()
end

function RB:ClearRows()
    local f = self.frame

    for _, row in ipairs(f.rows) do
        row.kind = nil
        row.categoryId = nil
        row.item = nil
        if row.fill then
            row.fill:SetWidth(1)
            row.fill:Hide()
        end
        row.icon:Show()
        row.icon:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")
        row.text:ClearAllPoints()
        row.text:SetPoint("LEFT", row.icon, "RIGHT", 9, 0)
        row.text:SetPoint("RIGHT", -170, 0)
        row.text:SetText("")
        row.count:SetText("")
        row:Hide()
    end
end

function RB:SetRowFill(row, value, maxValue)
    if not row or not row.fill then
        return
    end

    value = tonumber(value) or 0
    maxValue = tonumber(maxValue) or 0

    if value <= 0 or maxValue <= 0 then
        row.fill:SetWidth(1)
        row.fill:Hide()
        return
    end

    local width = row:GetWidth() or 0
    if width <= 0 then
        width = 640
    end

    local pct = value / maxValue
    if pct < 0.04 then
        pct = 0.04
    elseif pct > 1.0 then
        pct = 1.0
    end

    row.fill:SetWidth(math.floor(width * pct))
    row.fill:Show()
end

function RB:SetEmptyRow(text)
    local f = self.frame
    local row = f.rows[1]

    row.kind = nil
    row.categoryId = nil
    row.item = nil
    if row.fill then
        row.fill:SetWidth(1)
        row.fill:Hide()
    end
    row.icon:Show()
    row.icon:SetTexture("Interface\\Icons\\INV_Misc_Bag_10")
    row.text:ClearAllPoints()
    row.text:SetPoint("LEFT", row.icon, "RIGHT", 9, 0)
    row.text:SetPoint("RIGHT", -170, 0)
    row.text:SetText(text or "Nothing to show.")
    row.count:SetText("")
    row:Show()
end

function RB:RenderRoot(preserveStatus)
    self:HideWithdrawPrompt()
    self:CreateFrame()

    self.currentView = "root"
    self.currentCategoryId = nil
    self.currentPage = 0
    self.totalPages = 1
    self.detailItem = nil

    local f = self.frame
    f:Show()
    local grandTypes = 0
    local grandAmount = 0
    for _, info in pairs(self.categories or {}) do
        grandTypes = grandTypes + (tonumber(info.types) or 0)
        grandAmount = grandAmount + (tonumber(info.amount) or 0)
    end

    f.title:SetText("Reagent Bank")
    f.modeText:SetText((self.accountWide and "|cff80ff80Account-wide|r" or "|cffffcc80Character-only|r") ..
        "  |  " .. FormatCount(grandTypes) .. " types / " .. FormatCount(grandAmount) .. " reagents")
    f.pageText:SetText("")
    f.headerName:ClearAllPoints()
    f.headerName:SetPoint("LEFT", 32, 0)
    f.headerName:SetText("Category")
    f.headerCount:SetText("Types / Total")

    self:SetCommonVisibility("root")
    self:ClearRows()

    local categories = {}
    local maxCategoryAmount = 0

    for index, category in ipairs(CATEGORY_ORDER) do
        local info = self.categories and self.categories[category.id] or nil
        local types = info and info.types or 0
        local amount = info and info.amount or 0

        table.insert(categories, {
            id = category.id,
            name = category.name,
            sample = category.sample,
            order = index,
            types = types,
            amount = amount,
        })

        if amount > maxCategoryAmount then
            maxCategoryAmount = amount
        end
    end

    local categorySortMode = self:GetCategorySortMode()
    if categorySortMode ~= "order" then
        table.sort(categories, function(a, b)
            if categorySortMode == "name" then
                if a.name ~= b.name then
                    return a.name < b.name
                end
            elseif categorySortMode == "types" then
                if a.types ~= b.types then
                    return a.types > b.types
                end
            elseif categorySortMode == "amount" then
                if a.amount ~= b.amount then
                    return a.amount > b.amount
                end
            end

            return a.order < b.order
        end)
    end

    for index, category in ipairs(categories) do
        local row = f.rows[index]
        if row then
            local icon = GetItemIcon(category.sample) or "Interface\\Icons\\INV_Misc_QuestionMark"

            row.kind = "category"
            row.categoryId = category.id
            row.item = nil
            row.icon:Show()
            row.icon:SetTexture(icon)
            row.text:ClearAllPoints()
            row.text:SetPoint("LEFT", row.icon, "RIGHT", 9, 0)
            row.text:SetPoint("RIGHT", -170, 0)
            row.text:SetText(category.name)
            row.count:SetText(FormatCount(category.types) .. " types / " .. FormatCount(category.amount))
            self:SetRowFill(row, category.amount, maxCategoryAmount)
            row:Show()
        end
    end

    self:UpdateControls()

    if not preserveStatus and not self.busyKind then
        self:Status("Updated " .. SafeDate() .. ".", 0.45, 1.00, 0.45)
    end
end

function RB:RenderCategory(preserveStatus)
    self:CreateFrame()

    self.currentView = "category"
    self.detailItem = nil

    local f = self.frame
    local category = CATEGORY_BY_ID[self.currentCategoryId]
    local categoryName = category and category.name or "Category"
    local typeCount = tonumber(self.categoryTypeCount) or 0
    local amount = tonumber(self.categoryAmount) or 0
    local page = tonumber(self.currentPage) or 0
    local totalPages = math.max(tonumber(self.totalPages) or 1, 1)

    f:Show()
    f.title:SetText(categoryName)
    f.modeText:SetText(FormatCount(typeCount) .. " types / " .. FormatCount(amount) .. " reagents")
    f.pageText:SetText("Page " .. tostring(page + 1) .. "/" .. tostring(totalPages))
    f.headerName:ClearAllPoints()
    f.headerName:SetPoint("LEFT", 32, 0)
    f.headerName:SetText("Item")
    f.headerCount:SetText("Stored")

    self:SetCommonVisibility("category")
    self:ClearRows()

    local missingItemInfo = false
    local maxItemAmount = 0

    for _, item in ipairs(self.items or {}) do
        local amountValue = tonumber(item.amount) or 0
        if amountValue > maxItemAmount then
            maxItemAmount = amountValue
        end
    end

    for index, item in ipairs(self.items or {}) do
        local row = f.rows[index]
        if row then
            local icon, name, link, stackCount, missingInfo = GetItemDisplay(item.entry)

            if missingInfo then
                missingItemInfo = true
            end

            row.kind = "item"
            row.item = item
            row.icon:Show()
            row.icon:SetTexture(icon)
            row.text:ClearAllPoints()
            row.text:SetPoint("LEFT", row.icon, "RIGHT", 9, 0)
            row.text:SetPoint("RIGHT", -170, 0)
            row.text:SetText(link or name)
            row.count:SetText("x" .. FormatCount(item.amount))
            self:SetRowFill(row, item.amount, maxItemAmount)
            row:Show()
        end
    end

    if not self.items or #self.items == 0 then
        self:SetEmptyRow("No stored reagents in this category.")
        missingItemInfo = false
    end

    if missingItemInfo then
        self:QueueItemInfoRefresh()
    else
        self:ClearItemInfoRefresh()
    end

    self:UpdateControls()

    if not preserveStatus and not self.busyKind then
        self:Status("Updated " .. SafeDate() .. ".", 0.45, 1.00, 0.45)
    end
end

function RB:ShowDetail(item, preserveStatus)
    self:HideWithdrawPrompt()
    if not item or not item.entry then
        return
    end

    self:CreateFrame()

    self.detailItem = item
    self.currentView = "detail"

    local f = self.frame
    local icon, name, link, stackCount, missingInfo = GetItemDisplay(item.entry)
    local stored = tonumber(item.amount) or 0

    f:Show()
    f.title:SetText("Withdraw")
    f.modeText:SetText("")
    self:SetCommonVisibility("detail")

    f.detailIcon:SetTexture(icon)
    f.detailName:SetText(link or name)
    f.detailStored:SetText("Stored: " .. FormatCount(stored))

    if f.exactBox then
        f.exactBox:SetText("")
        f.exactBox:ClearFocus()
    end

    if missingInfo then
        self:QueueItemInfoRefresh()
    else
        self:ClearItemInfoRefresh()
    end

    self:UpdateControls()

    if not preserveStatus and not self.busyKind then
        self:Status("Choose a withdraw amount.", 0.82, 0.82, 0.82)
    end
end

function RB:Close()
    self:HideWithdrawPrompt()
    self:HideDepositPreview()
    self.awaitingView = nil
    self.busyKind = nil
    self.busyText = nil
    self.busyStartedAt = nil
    self.pendingRefresh = nil
    self.mutationNeedsRefresh = nil
    self:ClearItemInfoRefresh()

    HideTooltip()

    if self.frame then
        self:UpdateControls()
        self.frame:Hide()
    end
end

function RB:HandleOK(okText)
    okText = Trim(okText or "")

    local lowerText = string.lower(okText)
    if string.find(lowerText, "refresh") then
        okText = "Refresh acknowledged. Waiting for server data..."
    end

    if okText == "" then
        okText = "Server acknowledged."
    end

    if self.lastTransaction and self.lastTransaction.updatedAt and GetTime() - self.lastTransaction.updatedAt <= 2.0 then
        okText = okText .. " " .. self:BuildTransactionSummary(self.lastTransaction)
    end

    -- Do not clear autoDepositQuietUntil here. Some server responses send OK first
    -- and then follow up with ROOT/CATEGORY data. Keeping the quiet window alive
    -- prevents the hidden main frame from being created and shown by that follow-up data.
    self:ClearBusy(okText, 0.45, 1.00, 0.45)
    self:UpdateUndoButton()

    if self.mutationNeedsRefresh then
        local refreshTarget = self.mutationNeedsRefresh
        self.mutationNeedsRefresh = nil

        if refreshTarget == "category" and self.currentCategoryId then
            self:ScheduleRefresh(0.25, "category", self.currentCategoryId, self.currentPage or 0)
        else
            self:ScheduleRefresh(0.25, "root", nil, 0)
        end
    end
end

function RB:HandleError(errText)
    errText = Trim(errText or "Server error.")

    if self:IsAutoDepositQuietActive() then
        self.autoDepositQuietUntil = nil
        self.autoDepositSuppressViewUntil = nil
        PrintAddon("periodic auto-deposit skipped: " .. errText)
        return
    end

    self.mutationNeedsRefresh = nil
    self:CreateFrame()
    self.frame:Show()
    self:ClearBusy(errText, 1.00, 0.35, 0.35)
end

function RB:HandleProtocol(message)
    if type(message) ~= "string" or string.sub(message, 1, 6) ~= "RBANK:" then
        return false
    end

    local okText = string.match(message, "^RBANK:OK:(.*)$")
    if okText then
        self:HandleOK(okText)
        return true
    end

    local errText = string.match(message, "^RBANK:ERR:(.*)$")
    if errText then
        self:HandleError(errText)
        return true
    end

    local parts = SplitColon(message)
    local recordType = parts[2]

    if not recordType then
        return true
    end

    if recordType == "PREVIEW" then
        local previewKind = parts[3]

        if previewKind == "BEGIN" then
            self.pendingDepositPreview = {
                scope = tostring(parts[4] or "all"),
                categoryId = tonumber(parts[5]) or 0,
                total = tonumber(parts[6]) or 0,
                expected = tonumber(parts[7]) or 0,
                items = {},
            }
            return true
        elseif previewKind == "ITEM" then
            if self.pendingDepositPreview then
                local itemEntry = tonumber(parts[4])
                local amount = tonumber(parts[5]) or 0

                if itemEntry and itemEntry > 0 and amount > 0 then
                    table.insert(self.pendingDepositPreview.items, {
                        entry = math.floor(itemEntry),
                        amount = math.floor(amount),
                    })
                end
            end
            return true
        elseif previewKind == "END" then
            local preview = self.pendingDepositPreview
            self.pendingDepositPreview = nil

            if preview then
                preview.scope = tostring(parts[4] or preview.scope or "all")
                preview.categoryId = tonumber(parts[5]) or preview.categoryId or 0
                preview.total = tonumber(parts[6]) or preview.total or 0
                self:ShowDepositPreview(preview)
            end

            return true
        end

        return true
    end

    if recordType == "CHECK" then
        local checkKind = parts[3]

        if checkKind == "BEGIN" then
            self.pendingBankCheck = {
                requestId = tonumber(parts[4]) or 0,
                expected = tonumber(parts[5]) or 0,
                counts = {},
            }
            return true
        elseif checkKind == "ITEM" then
            if self.pendingBankCheck then
                local itemEntry = tonumber(parts[4])
                local amount = tonumber(parts[5]) or 0

                if itemEntry and itemEntry > 0 then
                    self.pendingBankCheck.counts[math.floor(itemEntry)] = math.max(0, math.floor(amount))
                end
            end
            return true
        elseif checkKind == "END" then
            local check = self.pendingBankCheck
            self.pendingBankCheck = nil

            if check then
                local requestId = tonumber(parts[4]) or check.requestId or 0
                local pending = self.pendingTradeSkillChecks and self.pendingTradeSkillChecks[requestId] or nil

                if pending then
                    self.tradeSkillBankCounts = check.counts or {}
                    self.tradeSkillBankCountsKey = pending.key
                    self.pendingTradeSkillChecks[requestId] = nil
                    if self.pendingTradeSkillCheckKey == pending.key then
                        self.pendingTradeSkillCheckKey = nil
                        self.pendingTradeSkillCheckUntil = nil
                    end

                    self:UpdateTradeSkillControls()
                end
            end

            return true
        end

        return true
    end

    if recordType == "TX" then
        local txKind = parts[3]

        if txKind == "BEGIN" then
            local action = self:NormalizeTransactionAction(parts[4])
            if action then
                local context = self:TakeTransactionContext(action)
                self.pendingTransaction = {
                    action = action,
                    source = SafeTransactionSource(parts[7] or (context and context.source) or "manual"),
                    label = context and context.label or nil,
                    total = tonumber(parts[5]) or 0,
                    expected = tonumber(parts[6]) or 0,
                    items = {},
                }
            else
                self.pendingTransaction = nil
            end

            return true
        elseif txKind == "ITEM" then
            if self.pendingTransaction then
                local itemEntry = tonumber(parts[4])
                local amount = tonumber(parts[5]) or 0

                if itemEntry and itemEntry > 0 and amount > 0 then
                    table.insert(self.pendingTransaction.items, {
                        entry = math.floor(itemEntry),
                        amount = math.floor(amount),
                    })
                end
            end

            return true
        elseif txKind == "SOURCE" then
            if self.pendingTransaction then
                self.pendingTransaction.source = SafeTransactionSource(parts[4] or self.pendingTransaction.source)
            end

            return true
        elseif txKind == "END" then
            local transaction = self.pendingTransaction
            self.pendingTransaction = nil

            if transaction then
                local action = self:NormalizeTransactionAction(parts[4])
                if action and action == transaction.action then
                    transaction.total = tonumber(parts[5]) or transaction.total or 0
                    self:FinalizeTransaction(transaction)
                end
            end

            return true
        end

        return true
    end

    if recordType == "BEGIN" then
        local view = parts[3]

        if view == "ROOT" then
            self.pendingView = "root"
            self.pendingCategories = {}
            self.accountWide = tonumber(parts[4]) == 1
        elseif view == "CATEGORY" then
            local categoryId = tonumber(parts[4])
            if categoryId then
                self.pendingView = "category"
                self.pendingItems = {}
                self.pendingCategoryId = categoryId
                self.pendingPage = tonumber(parts[5]) or 0
                self.pendingTotalPages = tonumber(parts[6]) or 1
                self.pendingTypeCount = tonumber(parts[7]) or 0
                self.pendingAmount = tonumber(parts[8]) or 0
                self.pendingSortMode = NormalizeItemSortMode(parts[9] or self:GetItemSortMode())
            end
        end

        return true
    end

    if recordType == "CAT" and self.pendingView == "root" then
        local categoryId = tonumber(parts[3])
        local sample = tonumber(parts[4]) or 0
        local types = tonumber(parts[5]) or 0
        local amount = tonumber(parts[6]) or 0

        if categoryId and CATEGORY_BY_ID[categoryId] then
            self.pendingCategories[categoryId] = {
                sample = sample,
                types = math.max(0, math.floor(types)),
                amount = math.max(0, math.floor(amount)),
            }
        end

        return true
    end

    if recordType == "ITEM" and self.pendingView == "category" then
        local itemEntry = tonumber(parts[3])
        local amount = tonumber(parts[4]) or 0

        if itemEntry and itemEntry > 0 and amount > 0 then
            table.insert(self.pendingItems, {
                entry = math.floor(itemEntry),
                amount = math.floor(amount),
            })
        end

        return true
    end

    if recordType == "END" then
        local view = parts[3]

        if view == "ROOT" and self.pendingView == "root" then
            self.categories = self.pendingCategories or {}
            self.pendingCategories = nil
            self.pendingView = nil
            self.awaitingView = nil
            self.mutationNeedsRefresh = nil

            self:ClearBusy()

            if self:IsAutoDepositViewSuppressed() then
                self.autoDepositSuppressViewUntil = nil
                return true
            end

            self:RenderRoot(true)
            self:Status("Updated " .. SafeDate() .. ".", 0.45, 1.00, 0.45)
        elseif view == "CATEGORY" and self.pendingView == "category" then
            self.currentCategoryId = self.pendingCategoryId
            self.currentPage = self.pendingPage or 0
            self.totalPages = self.pendingTotalPages or 1
            self.categoryTypeCount = self.pendingTypeCount or 0
            self.categoryAmount = self.pendingAmount or 0
            self.currentSortMode = NormalizeItemSortMode(self.pendingSortMode or self:GetItemSortMode())
            self.items = self.pendingItems or {}
            self.pendingItems = nil
            self.pendingView = nil
            self.awaitingView = nil
            self.mutationNeedsRefresh = nil

            self:ClearBusy()

            if self:IsAutoDepositViewSuppressed() then
                self.autoDepositSuppressViewUntil = nil
                return true
            end

            self:RenderCategory(true)
            self:Status("Updated " .. SafeDate() .. ".", 0.45, 1.00, 0.45)
        end

        return true
    end

    return true
end

local function SystemMessageFilter(chatFrame, event, message, ...)
    if RB:HandleProtocol(message) then
        return true
    end

    return false
end

if ChatFrame_AddMessageEventFilter then
    ChatFrame_AddMessageEventFilter("CHAT_MSG_SYSTEM", SystemMessageFilter)
else
    RB:RegisterEvent("CHAT_MSG_SYSTEM")
end

SLASH_REAGENTBANKUI1 = "/rbank"
SLASH_REAGENTBANKUI2 = "/reagentbank"
SLASH_REAGENTBANKUI3 = "/rbankui"
SlashCmdList["REAGENTBANKUI"] = function(msg)
    msg = Trim(msg or "")

    local command, value = string.match(msg, "^(%S+)%s*(.-)$")
    command = string.lower(command or "")

    if command == "" or command == "open" or command == "show" then
        RB:CreateFrame()
        RB.frame:Show()
        RB:RequestRoot()
        return
    end

    if command == "hide" or command == "close" then
        RB:Close()
        return
    end

    if command == "refresh" then
        if RB.currentView == "category" and RB.currentCategoryId then
            RB:RequestCategory(RB.currentCategoryId, RB.currentPage or 0)
        elseif RB.currentView == "detail" and RB.currentCategoryId then
            RB:RequestCategory(RB.currentCategoryId, RB.currentPage or 0)
        else
            RB:RequestRoot()
        end
        return
    end

    if command == "sort" then
        ReagentBankUIDB = ReagentBankUIDB or {}
        local lowerValue = string.lower(value or "")

        if lowerValue == "" or lowerValue == "cycle" then
            if RB.currentView == "root" or not RB.currentCategoryId then
                ReagentBankUIDB.categorySortMode = CycleCategorySortMode(ReagentBankUIDB.categorySortMode)
                RB:RenderRoot()
                PrintAddon("category sort set to " .. CategorySortLabel(ReagentBankUIDB.categorySortMode) .. ".")
            else
                ReagentBankUIDB.sortMode = CycleItemSortMode(ReagentBankUIDB.sortMode)
                RB:RequestCategory(RB.currentCategoryId, 0)
                PrintAddon("item sort set to " .. ItemSortLabel(ReagentBankUIDB.sortMode) .. ".")
            end
        else
            ReagentBankUIDB.sortMode = NormalizeItemSortMode(lowerValue)
            if RB.currentCategoryId then
                RB:RequestCategory(RB.currentCategoryId, 0)
            end
            PrintAddon("item sort set to " .. ItemSortLabel(ReagentBankUIDB.sortMode) .. ".")
        end

        return
    end

    if command == "preview" or command == "confirm" or command == "confirmation" then
        local lowerValue = string.lower(value or "")

        if lowerValue == "on" or lowerValue == "1" or lowerValue == "true" or lowerValue == "yes" then
            RB:SetDepositPreviewEnabled(true)
        elseif lowerValue == "off" or lowerValue == "0" or lowerValue == "false" or lowerValue == "no" then
            RB:SetDepositPreviewEnabled(false)
        else
            RB:ToggleDepositPreviewEnabled()
        end

        return
    end

    if command == "settings" or command == "options" or command == "colors" or command == "color" then
        RB:ToggleColorSettings()
        return
    end

    if command == "theme" or command == "schema" or command == "scheme" then
        local lowerValue = string.lower(Trim(value or ""))

        if lowerValue == "" or lowerValue == "settings" or lowerValue == "options" then
            RB:ToggleColorSettings()
        elseif lowerValue == "cycle" or lowerValue == "next" then
            RB:CycleColorTheme()
        else
            RB:SetColorTheme(lowerValue)
        end

        return
    end

    if command == "ticker" or command == "autoticker" or command == "periodic" then
        local lowerValue = string.lower(Trim(value or ""))

        if lowerValue == "" or lowerValue == "settings" or lowerValue == "options" then
            RB:ToggleColorSettings()
        elseif lowerValue == "off" or lowerValue == "0" or lowerValue == "false" then
            RB:SetAutoDepositTickerSeconds(0)
        else
            local seconds = tonumber(lowerValue)
            if seconds then
                RB:SetAutoDepositTickerSeconds(seconds)
            else
                PrintAddon("usage: /rbank ticker 0|30-3600")
            end
        end

        return
    end

    if command == "autodeposit" then
        ReagentBankUIDB = ReagentBankUIDB or {}
        local lowerValue = string.lower(value or "")

        if lowerValue == "on" or lowerValue == "1" or lowerValue == "true" then
            ReagentBankUIDB.autoDepositLeftovers = true
        elseif lowerValue == "off" or lowerValue == "0" or lowerValue == "false" then
            ReagentBankUIDB.autoDepositLeftovers = false
        else
            ReagentBankUIDB.autoDepositLeftovers = not ReagentBankUIDB.autoDepositLeftovers
        end

        if not ReagentBankUIDB.autoDepositLeftovers then
            RB.pendingAutoDepositLeftovers = nil
            RB.pendingAutoDepositAt = nil
        end

        RB:UpdateTradeSkillControls()
        PrintAddon("auto-deposit leftovers on profession close " .. (ReagentBankUIDB.autoDepositLeftovers and "enabled." or "disabled."))
        return
    end

    if command == "undo" or command == "reverse" then
        RB:ReverseLastTransaction()
        return
    end

    if command == "scale" then
        local numberValue = tonumber(value)

        if numberValue then
            ReagentBankUIDB = ReagentBankUIDB or {}
            ReagentBankUIDB.scale = Clamp(numberValue, 0.75, 1.20)
            RB:ApplyScale()
            DEFAULT_CHAT_FRAME:AddMessage(string.format("|cff33ff99ReagentBankUI|r scale set to %.2f", ReagentBankUIDB.scale))
            return
        end

        DEFAULT_CHAT_FRAME:AddMessage("|cff33ff99ReagentBankUI|r usage: /rbank scale 0.90")
        return
    end

    DEFAULT_CHAT_FRAME:AddMessage("|cff33ff99ReagentBankUI|r commands:")
    DEFAULT_CHAT_FRAME:AddMessage("  /rbank")
    DEFAULT_CHAT_FRAME:AddMessage("  /rbank refresh")
    DEFAULT_CHAT_FRAME:AddMessage("  /rbank hide")
    DEFAULT_CHAT_FRAME:AddMessage("  /rbank sort id|name|amount|amount_asc")
    DEFAULT_CHAT_FRAME:AddMessage("  /rbank preview on|off")
    DEFAULT_CHAT_FRAME:AddMessage("  /rbank undo")
    DEFAULT_CHAT_FRAME:AddMessage("  /rbank scale 0.75 - 1.20")
    DEFAULT_CHAT_FRAME:AddMessage("  /rbank ticker 0|30-3600")
    DEFAULT_CHAT_FRAME:AddMessage("  /rbank autodeposit on|off")
end

RB:SetScript("OnEvent", function(self, event, ...)
    if event == "ADDON_LOADED" then
        local addonName = ...

        if addonName == ADDON_NAME then
            ReagentBankUIDB = ReagentBankUIDB or {}
            if ReagentBankUIDB.autoDepositLeftovers == nil then
                ReagentBankUIDB.autoDepositLeftovers = false
            end
            ReagentBankUIDB.autoDepositTickerSeconds = self:ClampAutoDepositTickerSeconds(ReagentBankUIDB.autoDepositTickerSeconds)
            self:RestartAutoDepositTicker()
            ReagentBankUIDB.sortMode = NormalizeItemSortMode(ReagentBankUIDB.sortMode)
            ReagentBankUIDB.categorySortMode = NormalizeCategorySortMode(ReagentBankUIDB.categorySortMode)
            self:ApplySavedColorTheme()
            if ReagentBankUIDB.tradeSkillPrepareCount == nil then
                ReagentBankUIDB.tradeSkillPrepareCount = 1
            else
                ReagentBankUIDB.tradeSkillPrepareCount = self:ClampTradeSkillPrepareCount(ReagentBankUIDB.tradeSkillPrepareCount)
            end
            self:ApplySavedPosition()
            self:ApplyScale()
            self:CreatePaperDollButton()
            self:CreateTradeSkillControls()
        elseif addonName == "Blizzard_TradeSkillUI" then
            self:CreateTradeSkillControls()
        end
    elseif event == "PLAYER_LOGIN" then
        self:ApplySavedColorTheme()
        self:RestartAutoDepositTicker()
        self:CreatePaperDollButton()
        self:ApplySkin()
        self:CreateTradeSkillControls()
    elseif event == "TRADE_SKILL_SHOW" then
        self:CreateTradeSkillControls()
        self:UpdateTradeSkillControls()
    elseif event == "TRADE_SKILL_UPDATE" then
        self:CreateTradeSkillControls()
        self:UpdateTradeSkillControls()
    elseif event == "TRADE_SKILL_CLOSE" then
        self:HandleTradeSkillClosed()
    elseif event == "CHAT_MSG_SYSTEM" then
        local message = ...
        self:HandleProtocol(message)
    end
end)

RB:RegisterEvent("ADDON_LOADED")
RB:RegisterEvent("PLAYER_LOGIN")
RB:RegisterEvent("TRADE_SKILL_SHOW")
RB:RegisterEvent("TRADE_SKILL_UPDATE")
RB:RegisterEvent("TRADE_SKILL_CLOSE")