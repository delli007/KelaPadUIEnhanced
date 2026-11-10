-- KelaPadUI base-game gamepad UI fixes.
--
-- These mirror fixes that ZOS is preparing for a later game update and are
-- deliberately kept in their own module so they can be deleted in one step:
--   1. L2/R2 did not page battle round recaps on the Battleground scoreboard.
--      The scoreboard scenes do not activate the generic UI-shortcut action
--      layer, and BATTLEGROUND_SCOREBOARD_PREVIOUS_ROUND / ..._NEXT_ROUND
--      inherit from DUMMY actions that have no default binding. This module
--      adds the UI-shortcut layer below the scoreboard's own layer and routes
--      its trigger actions into the game's round paging.
--   2. The 6v6v6 and 9v9 scoreboards drew player rows taller than the panels
--      allocated for them, because the panel height assumed 32 px rows while
--      the score-label font list re-selected ZoFontGamepad34 (~40 px). Team
--      panels were therefore undersized and overlapped.
--   3. The Activity Finder kept the Battleground entry locked when its location
--      data arrived while the root screen was already open, because the gamepad
--      root never subscribes to the manager's "OnUpdateLocationData".
--
-- Remove this file and the KELA_SETTING_PANEL_FEATURES_BASE_GAME_FIXES setting
-- once the official fixes ship.

local KELA_ROW_HEIGHT_GAMEPAD = 40
local KELA_SMALL_ROW_HEIGHT_GAMEPAD = 32
local KELA_ROW_OFFSET_Y = 9

local KELA_BACKGROUND_DEFAULT_OFFSET_X_GAMEPAD = -10
local KELA_BACKGROUND_DEFAULT_OFFSET_Y = -20
local KELA_BACKGROUND_ROUNDS_OFFSET_Y_GAMEPAD = -117
local KELA_BACKGROUND_ROUNDS_OFFSET_Y_KEYBOARD = -60

local KELA_SCORE_FONTS_NORMAL =
{
	{ font = "ZoFontGamepad34", lineLimit = 1 },
	{ font = "ZoFontGamepad27", lineLimit = 1 },
}
local KELA_SCORE_FONTS_SMALL =
{
	{ font = "ZoFontGamepad27", lineLimit = 1 },
}
local KELA_ROW_SCORE_LABEL_NAMES =
{
	"MedalScore",
	"Kills",
	"Deaths",
	"Assists",
	"Damage",
	"Heals",
	"GameTypeScore",
}

local kelaBaseGameFixesEnabled = false

-- Mirrors ZO_Battleground_Scoreboard_Team_Panel_Object.GetPanelHeight as of
-- 12.2.0 (small rows use their own height instead of the large row height).
local function KelaGetPanelHeight(teamSize, useSmallPlayerEntries)
	local DEFAULT_TEAM_SIZE = 4
	if teamSize <= DEFAULT_TEAM_SIZE then
		return ZO_BATTLEGROUND_SCOREBOARD_PANEL_HEIGHT
	end

	local rowHeight = ZO_BATTLEGROUND_SCOREBOARD_PLAYER_ROW_HEIGHT_KEYBOARD
	if IsInGamepadPreferredMode() then
		rowHeight = useSmallPlayerEntries and KELA_SMALL_ROW_HEIGHT_GAMEPAD or ZO_BATTLEGROUND_SCOREBOARD_PLAYER_ROW_HEIGHT_GAMEPAD
	end

	return (teamSize * (rowHeight + ZO_BATTLEGROUND_SCOREBOARD_PLAYER_ROW_OFFSET_Y)) + ZO_BATTLEGROUND_SCOREBOARD_PLAYER_ROW_INITIAL_OFFSET_Y
end

-- Re-applies the container sizes from UpdateAll with the corrected panel
-- height. The background offsets mirror the file-local constants in
-- battlegroundscoreboard.lua.
local function KelaUpdateContainerHeights(fragment)
	if not fragment or not fragment:IsShowing() then
		return
	end
	if not fragment.currentBattlegroundId or fragment.currentBattlegroundId == 0 then
		return
	end

	local numBattlegroundTeams = GetBattlegroundNumTeams(fragment.currentBattlegroundId)
	local teamSize = GetBattlegroundTeamSize(fragment.currentBattlegroundId)
	local hasRounds = DoesBattlegroundHaveRounds(fragment.currentBattlegroundId)

	local teamPanelHeight = KelaGetPanelHeight(teamSize, fragment:ShouldScoreboardUseSmallPlayerEntries())
	local totalTeamPanelsHeight = teamPanelHeight * numBattlegroundTeams + ZO_BATTLEGROUND_SCOREBOARD_PANEL_OFFSET_Y * (numBattlegroundTeams - 1)
	totalTeamPanelsHeight = totalTeamPanelsHeight + 5

	local maxContainerHeight = hasRounds and ZO_BATTLEGROUND_SCOREBOARD_PANEL_CONTAINER_MAX_HEIGHT_WITH_ROUNDS or ZO_BATTLEGROUND_SCOREBOARD_PANEL_CONTAINER_MAX_HEIGHT
	local containerHeight = zo_min(totalTeamPanelsHeight, maxContainerHeight)
	fragment.panelContainer:SetHeight(containerHeight)

	local backgroundsHeight = containerHeight + ZO_BATTLEGROUND_SCOREBOARD_HEADER_HEIGHT + ZO_BATTLEGROUND_SCOREBOARD_PADDING_HEIGHT * 2
	fragment.backgroundsContainer:SetHeight(backgroundsHeight)
	fragment.backgroundsContainer:ClearAnchors()

	local backgroundsContainerOffsetY = KELA_BACKGROUND_DEFAULT_OFFSET_Y
	if hasRounds and containerHeight >= maxContainerHeight then
		if IsInGamepadPreferredMode() then
			backgroundsContainerOffsetY = KELA_BACKGROUND_ROUNDS_OFFSET_Y_GAMEPAD
		else
			backgroundsContainerOffsetY = KELA_BACKGROUND_ROUNDS_OFFSET_Y_KEYBOARD
		end
	end

	local backgroundsContainerOffsetX = 0
	if IsInGamepadPreferredMode() then
		backgroundsContainerOffsetX = KELA_BACKGROUND_DEFAULT_OFFSET_X_GAMEPAD
	end

	fragment.backgroundsContainer:SetAnchor(CENTER, nil, CENTER, backgroundsContainerOffsetX, backgroundsContainerOffsetY)
end

-- Small rows keep the single 27 px font so they stay at the 32 px row height
-- the panel height expects. Normal rows restore the game's 34 -> 27 list.
local function KelaApplyScoreLabelFonts(label, useSmallPlayerEntries)
	if not label or not label.MarkDirty then
		return
	end

	label.fonts = useSmallPlayerEntries and KELA_SCORE_FONTS_SMALL or KELA_SCORE_FONTS_NORMAL
	label.maxLines = 1
	label.dontUseMaxLinesForAdjusting = nil
	label:SetMaxLineCount(1)
	label.forceUpdate = true
	label:MarkDirty()
end

local function KelaApplyRowFonts(row)
	if not row or not row.control then
		return
	end

	-- The keyboard scoreboard keeps the core font list untouched.
	if not IsInGamepadPreferredMode() then
		return
	end

	local panel = row.panel
	if not panel then
		return
	end

	local useSmallPlayerEntries = panel:ShouldUseSmallPlayerEntries()
	for i = 1, #KELA_ROW_SCORE_LABEL_NAMES do
		KelaApplyScoreLabelFonts(row.control:GetNamedChild(KELA_ROW_SCORE_LABEL_NAMES[i]), useSmallPlayerEntries)
	end
end

-- Called by the keybind hook below. Returns true when the scoreboard consumed
-- the press.
function KelaBattlegroundMoveViewedRound(delta)
	if not kelaBaseGameFixesEnabled or not IsInGamepadPreferredMode() then
		return false
	end

	local fragment = BATTLEGROUND_SCOREBOARD_FRAGMENT
	if fragment and fragment:IsShowing() and fragment.roundSummary and fragment.roundSummary:IsVisible() then
		local keybind = delta < 0 and "BATTLEGROUND_SCOREBOARD_PREVIOUS_ROUND" or "BATTLEGROUND_SCOREBOARD_NEXT_ROUND"
		fragment:OnKeybindDown(keybind)
		return true
	end

	return false
end

local function KelaOnKeybindDown(keybind)
	if keybind == "UI_SHORTCUT_LEFT_TRIGGER" then
		KelaBattlegroundMoveViewedRound(-1)
	elseif keybind == "UI_SHORTCUT_RIGHT_TRIGGER" then
		KelaBattlegroundMoveViewedRound(1)
	end
end

-- The scoreboard's own action layer must stay above the generic UI-shortcut
-- layer so its buttons (players, leave, close) keep their bindings. L2/R2 are
-- not bound in the scoreboard layer, so they fall through to the shortcut
-- layer and reach KelaOnKeybindDown. Re-adding the scoreboard layer after the
-- shortcut layer moves it to the top of the scene's layer stack.
local function KelaAddUIShortcutsBelowScoreboardLayer(scene)
	if not scene or not UI_SHORTCUTS_ACTION_LAYER_FRAGMENT or not BATTLEGROUND_SCOREBOARD_ACTION_LAYER_FRAGMENT then
		return
	end

	scene:AddFragment(UI_SHORTCUTS_ACTION_LAYER_FRAGMENT)
	scene:RemoveFragment(BATTLEGROUND_SCOREBOARD_ACTION_LAYER_FRAGMENT)
	scene:AddFragment(BATTLEGROUND_SCOREBOARD_ACTION_LAYER_FRAGMENT)
end

local function KelaRefreshActivityFinderCategories()
	local root = ZO_ACTIVITY_FINDER_ROOT_GAMEPAD
	if not root or not root.scene or not root.scene:IsShowing() then
		return
	end

	local list = root:GetMainList()
	if not list then
		return
	end

	-- Commit rebuilds the rows so CategoryEntrySetup recomputes the cached lock
	-- state from the fresh location data; RefreshList restores the fragment,
	-- tooltip, and keybind strip the same way OnShowing does.
	list:Commit()
	root:RefreshList()
end

function KelaSetupBaseGameFixes()
	kelaBaseGameFixesEnabled = true

	KelaAddUIShortcutsBelowScoreboardLayer(BATTLEGROUND_SCOREBOARD_END_OF_GAME_SCENE)
	KelaAddUIShortcutsBelowScoreboardLayer(BATTLEGROUND_SCOREBOARD_IN_GAME_SCENE)
	SecurePostHook(_G, "ZO_KeybindStrip_HandleKeybindDown", KelaOnKeybindDown)

	-- The official fix defines this constant. Skip the layout patch when it is
	-- already present so both fixes never stack.
	if ZO_BATTLEGROUND_SCOREBOARD_PLAYER_SMALL_ROW_HEIGHT_GAMEPAD == nil then
		ZO_BATTLEGROUND_SCOREBOARD_PLAYER_ROW_HEIGHT_GAMEPAD = KELA_ROW_HEIGHT_GAMEPAD
		ZO_BATTLEGROUND_SCOREBOARD_PLAYER_ROW_OFFSET_Y = KELA_ROW_OFFSET_Y

		SecurePostHook(ZO_Battleground_Scoreboard_Team_Panel_Object, "UpdatePanelHeight", function(panel)
			panel.control:SetHeight(KelaGetPanelHeight(panel.teamSize, panel:ShouldUseSmallPlayerEntries()))
		end)

		-- Core sets the team size before the small-entry flag, so the height has
		-- to be recalculated once the flag changes.
		SecurePostHook(ZO_Battleground_Scoreboard_Team_Panel_Object, "UseSmallPlayerEntries", function(panel)
			panel:UpdatePanelHeight()
		end)

		SecurePostHook(BATTLEGROUND_SCOREBOARD_FRAGMENT, "UpdateAll", function(fragment)
			KelaUpdateContainerHeights(fragment)
		end)

		SecurePostHook(ZO_Battleground_Scoreboard_Player_Row_Object, "SetupOnAcquire", function(row)
			KelaApplyRowFonts(row)
		end)
	end

	ZO_ACTIVITY_FINDER_ROOT_MANAGER:RegisterCallback("OnUpdateLocationData", KelaRefreshActivityFinderCategories)
end
