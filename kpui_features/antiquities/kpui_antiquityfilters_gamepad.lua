-- KelaPadUI: filters for the gamepad Antiquities Journal.
-- Adds quality / status / codex filtering without replacing any ESOUI view or function;
-- everything is extended through ZO_PreHook / ZO_PostHook.

local KELA_QUALITY_ALL = -1
local KELA_STATUS_ALL = 0
local KELA_STATUS_LEAD_ACQUIRED = 1
local KELA_STATUS_NO_LEAD = 2
local KELA_STATUS_RECOVERED = 3
local KELA_STATUS_NOT_RECOVERED = 4
local KELA_CODEX_ALL = 0
local KELA_CODEX_COMPLETED = 1
local KELA_CODEX_NOT_COMPLETED = 2

local KELA_ANTIQUITY_FILTERS_SAVED_KEY = "antiquityFilters"

local kelaFilterDefaults =
{
    quality = KELA_QUALITY_ALL,
    status = KELA_STATUS_ALL,
    codex = KELA_CODEX_ALL,
}

local kelaFilters =
{
    quality = KELA_QUALITY_ALL,
    status = KELA_STATUS_ALL,
    codex = KELA_CODEX_ALL,
}

local kelaAntiquityFiltersSetupDone = false

local function SaveKelaAntiquityFilters()
    if kpuiSavedVariables then
        kpuiSavedVariables[KELA_ANTIQUITY_FILTERS_SAVED_KEY] = kelaFilters
    end
end

function KelaGetAntiquityFilter(filterKey)
    return kelaFilters[filterKey]
end

function KelaSetAntiquityFilter(filterKey, value)
    if kelaFilters[filterKey] == nil then return end
    kelaFilters[filterKey] = value
    SaveKelaAntiquityFilters()
end

function KelaAntiquityFiltersActive()
    return kelaFilters.quality ~= KELA_QUALITY_ALL
        or kelaFilters.status ~= KELA_STATUS_ALL
        or kelaFilters.codex ~= KELA_CODEX_ALL
end

local function ResetKelaAntiquityFilters()
    for key, defaultValue in pairs(kelaFilterDefaults) do
        kelaFilters[key] = defaultValue
    end
    SaveKelaAntiquityFilters()
end

local function GetAvailableAntiquityQualities()
    local qualities = {}
    if ANTIQUITY_DATA_MANAGER then
        for _, antiquityData in ANTIQUITY_DATA_MANAGER:AntiquityIterator() do
            local quality = antiquityData:GetQuality()
            if quality and quality > 0 then
                qualities[quality] = true
            end
        end
    end

    local sortedQualities = {}
    for quality in pairs(qualities) do
        table.insert(sortedQualities, quality)
    end
    table.sort(sortedQualities)
    return sortedQualities
end

local function IsValidAntiquityQuality(quality)
    if quality == KELA_QUALITY_ALL then
        return true
    end
    for _, availableQuality in ipairs(GetAvailableAntiquityQualities()) do
        if quality == availableQuality then
            return true
        end
    end
    return false
end

local function LoadKelaAntiquityFilters()
    local savedFilters = kpuiSavedVariables and kpuiSavedVariables[KELA_ANTIQUITY_FILTERS_SAVED_KEY]
    if type(savedFilters) ~= "table" then
        savedFilters = {}
    end

    for key, defaultValue in pairs(kelaFilterDefaults) do
        kelaFilters[key] = tonumber(savedFilters[key]) or defaultValue
    end

    if not IsValidAntiquityQuality(kelaFilters.quality) then
        kelaFilters.quality = KELA_QUALITY_ALL
    end
    if kelaFilters.status < KELA_STATUS_ALL or kelaFilters.status > KELA_STATUS_NOT_RECOVERED then
        kelaFilters.status = KELA_STATUS_ALL
    end
    if kelaFilters.codex < KELA_CODEX_ALL or kelaFilters.codex > KELA_CODEX_NOT_COMPLETED then
        kelaFilters.codex = KELA_CODEX_ALL
    end

    SaveKelaAntiquityFilters()
end

local function SetHasAnyAntiquityMatching(setData, filterFunction)
    return setData:AntiquityIterator({ filterFunction })() ~= nil
end

function KelaAntiquityMatchesFilters(antiquityData, antiquitySetData)
    if not KelaAntiquityFiltersActive() or not IsInGamepadPreferredMode() then
        return true
    end

    local targetData = antiquitySetData or antiquityData
    if not targetData then
        return true
    end

    if kelaFilters.quality ~= KELA_QUALITY_ALL and targetData:GetQuality() ~= kelaFilters.quality then
        return false
    end

    local status = kelaFilters.status
    if status ~= KELA_STATUS_ALL then
        local hasLead
        local hasRecovered
        if antiquitySetData then
            hasLead = SetHasAnyAntiquityMatching(antiquitySetData, ZO_Antiquity.HasLead)
            hasRecovered = SetHasAnyAntiquityMatching(antiquitySetData, ZO_Antiquity.HasRecovered)
        else
            hasLead = antiquityData:HasLead()
            hasRecovered = antiquityData:HasRecovered()
        end

        if status == KELA_STATUS_LEAD_ACQUIRED and not hasLead then return false end
        if status == KELA_STATUS_NO_LEAD and hasLead then return false end
        if status == KELA_STATUS_RECOVERED and not hasRecovered then return false end
        if status == KELA_STATUS_NOT_RECOVERED and hasRecovered then return false end
    end

    local codex = kelaFilters.codex
    if codex ~= KELA_CODEX_ALL then
        local isCodexComplete = targetData:GetNumUnlockedLoreEntries() >= targetData:GetNumLoreEntries()
        if (codex == KELA_CODEX_COMPLETED) ~= isCodexComplete then
            return false
        end
    end

    return true
end

-- Removes entries that do not match the active filters from the journal's transient
-- scroll data list. Section heading rows are kept only when their section survives.
function KelaFilterAntiquityScrollData(listObject)
    if not KelaAntiquityFiltersActive() or not IsInGamepadPreferredMode() then return end

    local listControl = listObject:GetListControl()
    if not listControl then return end

    local scrollData = ZO_ScrollList_GetDataList(listControl)
    if not scrollData or #scrollData == 0 then return end

    local indicesToRemove = {}
    local currentHeadingIndex
    local headingHasMatchingEntries = false

    local function FinishHeading()
        if currentHeadingIndex and not headingHasMatchingEntries then
            table.insert(indicesToRemove, currentHeadingIndex)
        end
    end

    for i = 1, #scrollData do
        local entryData = scrollData[i].data
        local dataSource = entryData and entryData.dataSource
        if dataSource then
            local matches
            local dataType = dataSource.GetType and dataSource:GetType()
            if dataType == ZO_ANTIQUITY_TYPE_SET then
                matches = KelaAntiquityMatchesFilters(nil, dataSource)
            elseif dataType == ZO_ANTIQUITY_TYPE_INDIVIDUAL then
                matches = KelaAntiquityMatchesFilters(dataSource)
            else
                matches = true
            end

            if matches then
                headingHasMatchingEntries = true
            else
                table.insert(indicesToRemove, i)
            end
        elseif entryData and entryData.label ~= nil then
            -- Section heading row.
            FinishHeading()
            currentHeadingIndex = i
            headingHasMatchingEntries = false
        else
            -- Unknown row type: keep it and treat it as content of the current heading.
            headingHasMatchingEntries = true
        end
    end
    FinishHeading()

    if #indicesToRemove > 0 then
        table.sort(indicesToRemove)
        for i = #indicesToRemove, 1, -1 do
            table.remove(scrollData, indicesToRemove[i])
        end
        ZO_ScrollList_SetAutoSelectToMatchingDataEntry(listObject.list, listObject.lastSelectedData)
    end
end

local function FormatKelaFilterItem(label, value)
    return zo_strformat("<<1>>: <<2>>", label, value)
end

local function BuildKelaFilterItems(label, allValue, entries)
    local items =
    {
        {
            value = allValue,
            text = FormatKelaFilterItem(label, GetString(SI_INVENTORY_WALLET_ALL_FILTER)),
        },
    }

    for _, entry in ipairs(entries) do
        table.insert(items,
        {
            value = entry.value,
            text = FormatKelaFilterItem(label, GetString(entry.stringId)),
        })
    end

    return items
end

local function GetKelaQualityFilterItems()
    local label = GetString(SI_MASTER_WRIT_DESCRIPTION_QUALITY)
    local items = BuildKelaFilterItems(label, KELA_QUALITY_ALL, {})

    for _, quality in ipairs(GetAvailableAntiquityQualities()) do
        local qualityStringId = _G["SI_ITEMDISPLAYQUALITY" .. quality]
        local qualityName = qualityStringId and GetString(qualityStringId) or tostring(quality)
        local qualityColor = GetAntiquityQualityColor(quality)
        if qualityColor then
            qualityName = qualityColor:Colorize(qualityName)
        end

        table.insert(items,
        {
            value = quality,
            text = FormatKelaFilterItem(label, qualityName),
        })
    end

    return items
end

local function GetKelaStatusFilterItems()
    return BuildKelaFilterItems(GetString(SI_GAMEPAD_CONTACTS_LIST_HEADER_STATUS), KELA_STATUS_ALL,
    {
        { value = KELA_STATUS_LEAD_ACQUIRED, stringId = KELA_ANTIQUITY_FILTER_STATUS_LEAD_ACQUIRED },
        { value = KELA_STATUS_NO_LEAD, stringId = KELA_ANTIQUITY_FILTER_STATUS_NO_LEAD },
        { value = KELA_STATUS_RECOVERED, stringId = KELA_ANTIQUITY_FILTER_STATUS_RECOVERED },
        { value = KELA_STATUS_NOT_RECOVERED, stringId = KELA_ANTIQUITY_FILTER_STATUS_NOT_RECOVERED },
    })
end

local function GetKelaCodexFilterItems()
    return BuildKelaFilterItems(GetString(SI_ANTIQUITY_LOG_BOOK), KELA_CODEX_ALL,
    {
        { value = KELA_CODEX_COMPLETED, stringId = SI_ACHIEVEMENTS_TOOLTIP_COMPLETE },
        { value = KELA_CODEX_NOT_COMPLETED, stringId = KELA_ANTIQUITY_FILTER_CODEX_NOT_COMPLETED },
    })
end

local function CreateKelaFilterDropdownEntryData(getItems, filterKey)
    local entryData = ZO_GamepadEntryData:New()
    entryData.dropdownEntry = true
    entryData.setup = function(control, data)
        local dropdown = control.dropdown
        dropdown:SetSortsItems(false)
        dropdown:ClearItems()

        table.insert(data.dialog.dropdowns, dropdown)

        local entries = {}
        for _, item in ipairs(getItems()) do
            local dropdownItem = dropdown:CreateItemEntry(item.text, function()
                KelaSetAntiquityFilter(filterKey, item.value)
                local listFragment = ZO_ANTIQUITY_JOURNAL_LIST_GAMEPAD_FRAGMENT
                if ANTIQUITY_JOURNAL_GAMEPAD and listFragment and not listFragment:IsHidden() then
                    ANTIQUITY_JOURNAL_GAMEPAD:RefreshAntiquityList()
                end
            end)
            entries[item.value] = dropdownItem
            dropdown:AddItem(dropdownItem)
        end

        SCREEN_NARRATION_MANAGER:RegisterDialogDropdown(data.dialog, dropdown)
        dropdown:UpdateItems()

        local selectedEntry = entries[KelaGetAntiquityFilter(filterKey)]
        if selectedEntry then
            local IGNORE_CALLBACK = true
            dropdown:TrySelectItemByData(selectedEntry, IGNORE_CALLBACK)
        end
    end
    entryData.narrationText = ZO_GetDefaultParametricListDropdownNarrationText
    return entryData
end

local kelaQualityDropdownEntryData
local kelaStatusDropdownEntryData
local kelaCodexDropdownEntryData

local function GetKelaQualityDropdownEntryData()
    if not kelaQualityDropdownEntryData then
        kelaQualityDropdownEntryData = CreateKelaFilterDropdownEntryData(GetKelaQualityFilterItems, "quality")
    end
    return kelaQualityDropdownEntryData
end

local function GetKelaStatusDropdownEntryData()
    if not kelaStatusDropdownEntryData then
        kelaStatusDropdownEntryData = CreateKelaFilterDropdownEntryData(GetKelaStatusFilterItems, "status")
    end
    return kelaStatusDropdownEntryData
end

local function GetKelaCodexDropdownEntryData()
    if not kelaCodexDropdownEntryData then
        kelaCodexDropdownEntryData = CreateKelaFilterDropdownEntryData(GetKelaCodexFilterItems, "codex")
    end
    return kelaCodexDropdownEntryData
end

local function RegisterKelaAntiquityFilterDialog()
    local function OnReleaseDialog(dialog)
        if dialog.dropdowns then
            for _, dropdown in pairs(dialog.dropdowns) do
                dropdown:Deactivate()
            end
        end
        dialog.dropdowns = nil
    end

    ZO_Dialogs_RegisterCustomDialog("KELA_ANTIQUITY_FILTERS",
    {
        gamepadInfo =
        {
            dialogType = GAMEPAD_DIALOGS.PARAMETRIC,
        },
        title =
        {
            text = SI_GAMEPAD_CONTACTS_OPTIONS_FILTER,
        },
        setup = function(dialog)
            local parametricListEntries = dialog.info.parametricList
            ZO_ClearNumericallyIndexedTable(parametricListEntries)
            dialog.dropdowns = {}

            table.insert(parametricListEntries, { template = "ZO_GamepadDropdownItem", entryData = GetKelaQualityDropdownEntryData() })
            table.insert(parametricListEntries, { template = "ZO_GamepadDropdownItem", entryData = GetKelaStatusDropdownEntryData() })
            table.insert(parametricListEntries, { template = "ZO_GamepadDropdownItem", entryData = GetKelaCodexDropdownEntryData() })

            dialog.setupFunc(dialog)
        end,
        parametricList = {},
        blockDialogReleaseOnPress = true,
        buttons =
        {
            {
                keybind = "DIALOG_PRIMARY",
                text = SI_GAMEPAD_SELECT_OPTION,
                callback = function(dialog)
                    local targetData = dialog.entryList:GetTargetData()
                    local targetControl = dialog.entryList:GetTargetControl()
                    if targetData.dropdownEntry then
                        targetControl.dropdown:Activate()
                    end
                end,
            },
            {
                keybind = "DIALOG_NEGATIVE",
                text = SI_GAMEPAD_BACK_OPTION,
                callback = function()
                    ZO_Dialogs_ReleaseDialogOnButtonPress("KELA_ANTIQUITY_FILTERS")
                end,
            },
        },
        noChoiceCallback = OnReleaseDialog,
    })
end

local function AddKelaAntiquityFilterKeybind(descriptor)
    if not descriptor or descriptor.kelaAntiquityFilterKeybindAdded then return end

    table.insert(descriptor,
    {
        order = 40,
        keybind = "UI_SHORTCUT_QUATERNARY",
        name = function()
            local name = GetString(SI_GAMEPAD_CONTACTS_OPTIONS_FILTER)
            if KelaAntiquityFiltersActive() then
                return name .. " *"
            end
            return name
        end,
        callback = function()
            ZO_Dialogs_ShowGamepadDialog("KELA_ANTIQUITY_FILTERS")
        end,
    })

    descriptor.kelaAntiquityFilterKeybindAdded = true
end

local function AddKelaAntiquityFilterKeybindsToCategoryScreen(screen)
    if not screen then return end
    AddKelaAntiquityFilterKeybind(screen.categoryList and screen.categoryList.keybindStripDescriptor)
    AddKelaAntiquityFilterKeybind(screen.subcategoryList and screen.subcategoryList.keybindStripDescriptor)
end

function KelaSetupAntiquityFilters()
    if kelaAntiquityFiltersSetupDone then return end
    if not ANTIQUITY_DATA_MANAGER or not ZO_AntiquityJournalGamepad or not ZO_AntiquityJournalListGamepad then return end

    kelaAntiquityFiltersSetupDone = true

    LoadKelaAntiquityFilters()

    ZO_PreHook(ZO_AntiquityJournalListGamepad, "CommitScrollList", KelaFilterAntiquityScrollData)
    ZO_PreHook(ZO_AntiquityJournalGamepad, "ViewCategory", function(self, categoryData, focusAntiquityList, autoSelectAntiquityOrSetData, resetFilters)
        if resetFilters then
            ResetKelaAntiquityFilters()
        end
    end)
    ZO_PostHook(ZO_AntiquityJournalGamepad, "InitializeLists", function(screen)
        AddKelaAntiquityFilterKeybindsToCategoryScreen(screen)
    end)
    ZO_PostHook(ZO_AntiquityJournalListGamepad, "InitializeLists", function(listObject)
        AddKelaAntiquityFilterKeybind(listObject.keybindStripDescriptor)
    end)

    -- The journal screens are created before addons load, so extend the existing instances too.
    AddKelaAntiquityFilterKeybindsToCategoryScreen(ANTIQUITY_JOURNAL_GAMEPAD)
    if ANTIQUITY_JOURNAL_LIST_GAMEPAD then
        AddKelaAntiquityFilterKeybind(ANTIQUITY_JOURNAL_LIST_GAMEPAD.keybindStripDescriptor)
    end

    RegisterKelaAntiquityFilterDialog()
end





