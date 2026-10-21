local KELAPADUI_ENTRIES = {
    SETS     = 1,
    SETTINGS = 2,
}

local KELAPADUI_TEXT_COLOR = "|cC64CFF"
local KELAPADUI_ICON_COLOR = ZO_ColorDef:New("C64CFF")

local KELAPADUI_MENU_ENTRY_DATA =
{
    customTemplate = "ZO_GamepadMenuEntryTemplateWithArrow",
    name = KELAPADUI_TEXT_COLOR .. GetString(KELA_MAINMENU_TITLE) .. "|r",
    icon = "EsoUI/Art/MenuBar/Gamepad/gp_playerMenu_icon_champion.dds",
    iconColor = KELAPADUI_ICON_COLOR,
    subMenu =
    {
        [KELAPADUI_ENTRIES.SETS] =
        {
            scene = "kelaSets",
            name = GetString(KELA_MAINMENU_SETS),
            icon = "esoui/art/treeicons/gamepad/gp_collectionicon_weapona+armor.dds",
            isVisibleCallback = function()
                return KelaGetSetting_Bool(SETTING_TYPE_KELA, KELA_SETTING_PANEL_SETS_ENABLED)
            end,
        },
        [KELAPADUI_ENTRIES.SETTINGS] =
        {
            prePadding = 150,
            scene = "kela_options_root",
            name = GetString(SI_GAME_MENU_SETTINGS),
            icon = "EsoUI/Art/MenuBar/Gamepad/gp_playerMenu_icon_settings.dds",
        },
    }
}

local function CreateEntry(data)
    local name = data.name
    if type(name) == "function" then
        name = "" --will be updated whenever the list is generated
    end

    local entry = ZO_GamepadEntryData:New(name, data.icon, nil, nil, data.isNewCallback)
    entry:SetIconTintOnSelection(true)
    if data.iconColor then
        entry:SetIconTint(data.iconColor, data.iconColor)
    end
    entry:SetIconDisabledTintOnSelection(true)

    local header = data.header
    if header then
        entry:SetHeader(header)
    end

    entry.canLevel = data.canLevel

    entry.data = data
    return entry
end

-- Create the Kela Menu
local kelaEntry = CreateEntry(KELAPADUI_MENU_ENTRY_DATA)

-- Add the Sub Menu
if KELAPADUI_MENU_ENTRY_DATA.subMenu then
    kelaEntry.subMenu = {}
    for submenuEntryId, subMenuData in ipairs(KELAPADUI_MENU_ENTRY_DATA.subMenu) do
        local newSubMenuEntry = CreateEntry(subMenuData)
        newSubMenuEntry.id = submenuEntryId
        table.insert(kelaEntry.subMenu, newSubMenuEntry)
    end
end

-- Append the Kela Menu Entry without re-indexing existing menu entries.
kelaEntry.id = #ZO_MENU_ENTRIES + 1
table.insert(ZO_MENU_ENTRIES, kelaEntry)


