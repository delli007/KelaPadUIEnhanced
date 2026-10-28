-- KelaPadUI main-menu quick access
-- Opened with the tertiary (triangle) keybind on the gamepad main menu.

local KELA_QUICK_ACCESS_DIALOG = "KELA_QUICK_ACCESS_DIALOG"
local KELA_QUICK_ACCESS_SETTING = KELA_SETTING_PANEL_FEATURES_MAIN_MENU_SHORTCUTS

local registered = false
local keybindAdded = false

local function IsQuickAccessEnabled()
    return KelaGetSetting_Bool(SETTING_TYPE_KELA, KELA_QUICK_ACCESS_SETTING)
end

local function IsGamepadDialogAvailable()
    return ZO_Dialogs_RegisterCustomDialog ~= nil and ZO_Dialogs_ShowGamepadDialog ~= nil
end

local function ShowGroupFinder()
    if not GROUP_FINDER_GAMEPAD or not ZO_ACTIVITY_FINDER_ROOT_GAMEPAD then
        return
    end

    local categoryData = GROUP_FINDER_GAMEPAD.GetCategoryData and GROUP_FINDER_GAMEPAD:GetCategoryData()
    if not categoryData then
        return
    end

    -- Set the mode before showing so OnShowing consumes it without an overview flash.
    if GROUP_FINDER_GAMEPAD.SetMode and ZO_GROUP_FINDER_MODES then
        GROUP_FINDER_GAMEPAD:SetMode(ZO_GROUP_FINDER_MODES.SEARCH)
    end

    ZO_ACTIVITY_FINDER_ROOT_GAMEPAD:ShowCategory(categoryData)
end

local function ShowDungeonFinder()
    if not DUNGEON_FINDER_MANAGER or not ZO_ACTIVITY_FINDER_ROOT_GAMEPAD then
        return
    end

    local categoryData = DUNGEON_FINDER_MANAGER.GetCategoryData and DUNGEON_FINDER_MANAGER:GetCategoryData()
    if categoryData then
        ZO_ACTIVITY_FINDER_ROOT_GAMEPAD:ShowCategory(categoryData)
    end
end

local function ShowBattlegroundFinder()
    if not BATTLEGROUND_FINDER_MANAGER or not ZO_ACTIVITY_FINDER_ROOT_GAMEPAD then
        return
    end

    local categoryData = BATTLEGROUND_FINDER_MANAGER.GetCategoryData and BATTLEGROUND_FINDER_MANAGER:GetCategoryData()
    if categoryData then
        ZO_ACTIVITY_FINDER_ROOT_GAMEPAD:ShowCategory(categoryData)
    end
end

local function ShowGroupList()
    if MAIN_MENU_GAMEPAD and MAIN_MENU_GAMEPAD.ShowGroupMenu then
        MAIN_MENU_GAMEPAD:ShowGroupMenu()
    end
end

local function ShowMail()
    if SCENE_MANAGER and SCENE_MANAGER.CreateStackFromScratch then
        SCENE_MANAGER:CreateStackFromScratch("mainMenuGamepad", "mailGamepad")
    end
end

local function ShowScryableAntiquities()
    if MAIN_MENU_GAMEPAD and MAIN_MENU_GAMEPAD.ShowScryableAntiquities then
        MAIN_MENU_GAMEPAD:ShowScryableAntiquities()
    end
end

local function ShowStickerBook()
    if SCENE_MANAGER and SCENE_MANAGER.CreateStackFromScratch then
        SCENE_MANAGER:CreateStackFromScratch("mainMenuGamepad", "gamepadItemSetsBook")
    end
end

local function TravelToPrimaryHouse()
    if not GetHousingPrimaryHouse or not RequestJumpToHouse then
        return
    end

    local houseId = GetHousingPrimaryHouse()
    if not houseId or houseId == 0 then
        return
    end

    if CanJumpToHouseFromCurrentLocation and not CanJumpToHouseFromCurrentLocation() then
        return
    end

    SCENE_MANAGER:ShowBaseScene()
    RequestJumpToHouse(houseId, false)
end

local function IsGroupFinderAvailable()
    return GROUP_FINDER_GAMEPAD ~= nil and ZO_ACTIVITY_FINDER_ROOT_GAMEPAD ~= nil
end

local function IsDungeonFinderAvailable()
    return DUNGEON_FINDER_MANAGER ~= nil and ZO_ACTIVITY_FINDER_ROOT_GAMEPAD ~= nil
end

local function IsBattlegroundFinderAvailable()
    return BATTLEGROUND_FINDER_MANAGER ~= nil and ZO_ACTIVITY_FINDER_ROOT_GAMEPAD ~= nil
end

local function ShowTomeChallenges()
    if TIMED_ACTIVITIES_MANAGER and TIMED_ACTIVITIES_MANAGER.ShowTimedActivitiesScene then
        TIMED_ACTIVITIES_MANAGER:ShowTimedActivitiesScene()
    end
end

local function IsTomeChallengesAvailable()
    return TIMED_ACTIVITIES_MANAGER ~= nil and TIMED_ACTIVITIES_MANAGER.ShowTimedActivitiesScene ~= nil
end

local function IsGroupAvailable()
    return MAIN_MENU_GAMEPAD ~= nil and MAIN_MENU_GAMEPAD.ShowGroupMenu ~= nil
end

local function IsMailAvailable()
    return SCENE_MANAGER ~= nil
end

local function IsScryableAntiquitiesAvailable()
    return MAIN_MENU_GAMEPAD ~= nil and MAIN_MENU_GAMEPAD.ShowScryableAntiquities ~= nil
end

local function IsStickerBookAvailable()
    return SCENE_MANAGER ~= nil
end

local function IsPrimaryHouseAvailable()
    if not GetHousingPrimaryHouse then
        return false
    end
    local houseId = GetHousingPrimaryHouse()
    return houseId ~= nil and houseId ~= 0
end

-- The first entry of each group carries the section header text, using the
-- parametric list dialog's built-in header support.
local QUICK_ACCESS_ENTRIES =
{
    { label = KELA_SHORTCUT_GROUP_FINDER, action = ShowGroupFinder, enabled = IsGroupFinderAvailable, header = KELA_SHORTCUT_HEADER_ACTIVITIES },
    { label = KELA_SHORTCUT_DUNGEON_FINDER, action = ShowDungeonFinder, enabled = IsDungeonFinderAvailable },
    { label = KELA_SHORTCUT_BATTLEGROUNDS, action = ShowBattlegroundFinder, enabled = IsBattlegroundFinderAvailable },
    { label = KELA_SHORTCUT_TOME_CHALLENGES, action = ShowTomeChallenges, enabled = IsTomeChallengesAvailable },
    { label = KELA_SHORTCUT_GROUP, action = ShowGroupList, enabled = IsGroupAvailable, header = KELA_SHORTCUT_HEADER_SHORTCUTS },
    { label = KELA_SHORTCUT_MAIL, action = ShowMail, enabled = IsMailAvailable },
    { label = KELA_SHORTCUT_SCRYABLE_ANTIQUITIES, action = ShowScryableAntiquities, enabled = IsScryableAntiquitiesAvailable },
    { label = KELA_SHORTCUT_STICKER_BOOK, action = ShowStickerBook, enabled = IsStickerBookAvailable },
    { label = KELA_SHORTCUT_PRIMARY_HOUSE, action = TravelToPrimaryHouse, enabled = IsPrimaryHouseAvailable, header = KELA_SHORTCUT_HEADER_ACTIONS },
}

local function BuildParametricList()
    local list = {}
    for _, entry in ipairs(QUICK_ACCESS_ENTRIES) do
        table.insert(list,
        {
            template = "ZO_GamepadMenuEntryTemplate",
            header = entry.header and GetString(entry.header) or nil,
            templateData =
            {
                text = GetString(entry.label),
                setup = ZO_SharedGamepadEntry_OnSetup,
                enabled = entry.enabled,
                callback = entry.action,
            },
        })
    end
    return list
end

local function RegisterQuickAccessDialog()
    if registered then
        return
    end
    registered = true

    ZO_Dialogs_RegisterCustomDialog(KELA_QUICK_ACCESS_DIALOG,
    {
        gamepadInfo =
        {
            dialogType = GAMEPAD_DIALOGS.PARAMETRIC,
        },
        setup = function(dialog)
            dialog.info.parametricList = BuildParametricList()
            dialog:setupFunc()
        end,
        title =
        {
            text = KELA_SHORTCUT_TITLE,
        },
        blockDialogReleaseOnPress = true,
        buttons =
        {
            {
                keybind = "DIALOG_PRIMARY",
                text = SI_GAMEPAD_SELECT_OPTION,
                callback = function(dialog)
                    local data = dialog.entryList:GetTargetData()
                    if data and data.callback and data:IsEnabled() then
                        data.callback()
                    end
                    ZO_Dialogs_ReleaseDialogOnButtonPress(KELA_QUICK_ACCESS_DIALOG)
                end,
            },
            {
                keybind = "DIALOG_NEGATIVE",
                text = SI_DIALOG_CANCEL,
                callback = function()
                    ZO_Dialogs_ReleaseDialogOnButtonPress(KELA_QUICK_ACCESS_DIALOG)
                end,
            },
        },
    })
end

local function IsMainMenuRootShowing()
    local manager = MAIN_MENU_GAMEPAD
    if manager and manager.GetCurrentList and manager.mainList then
        return manager:GetCurrentList() == manager.mainList
    end
    return true
end

local function AddQuickAccessKeybind()
    local manager = MAIN_MENU_GAMEPAD
    if keybindAdded or not manager or not manager.keybindStripDescriptor then
        return
    end
    keybindAdded = true

    table.insert(manager.keybindStripDescriptor,
    {
        name = GetString(KELA_SHORTCUT_TITLE),
        keybind = "UI_SHORTCUT_TERTIARY",
        callback = function()
            ZO_Dialogs_ShowGamepadDialog(KELA_QUICK_ACCESS_DIALOG)
        end,
        visible = function()
            -- Add-ons run on PC, where the console voice-chat shortcut is not shown.
            if not IsQuickAccessEnabled() then
                return false
            end
            if ZO_IsConsoleOrGameCoreUI and ZO_IsConsoleOrGameCoreUI() then
                return false
            end
            return IsMainMenuRootShowing()
        end,
    })
end

function KelaSetupMainMenuShortcuts()
    if not IsQuickAccessEnabled() then
        return
    end

    if not IsGamepadDialogAvailable() then
        return
    end

    RegisterQuickAccessDialog()
    AddQuickAccessKeybind()
end
