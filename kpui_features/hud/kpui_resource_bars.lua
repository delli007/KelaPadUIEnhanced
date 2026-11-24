-- Gamepad resource bar shift.
-- Moves the Magicka and Stamina bars the same distance toward the health bar
-- (a negative value moves them outward). The game anchors Magicka by its RIGHT
-- edge and Stamina by its LEFT edge to their parent, and the base-game HUD
-- manager (Edit HUD) resets those anchors on load, on a gamepad/keyboard mode
-- change, and on screen resize; the shift is re-applied after each reset.

local NAMESPACE = "KelaPadUIEnhanced_ResourceBars"
local KELA_OPTIONS_SCENE_NAME = "kela_options_root"

-- direction: +1 moves right, -1 moves left; both point toward the center.
local BARS =
{
	{ controlName = "ZO_PlayerAttributeMagicka", direction = 1 },
	{ controlName = "ZO_PlayerAttributeStamina", direction = -1 },
}

local baseAnchors = {}
local appliedShift = 0

local function GetShift()
	if not IsInGamepadPreferredMode() then
		return 0
	end
	return KelaGetSetting_Number(SETTING_TYPE_KELA, KELA_SETTING_PANEL_ACTIONBAR_RESOURCE_SHIFT) or 0
end

-- A bar the player positioned in Edit HUD keeps that position.
local function IsMovedInHudEditor(control)
	local element = HUD_MANAGER and HUD_MANAGER:GetGamepadElementForControl(control)
	return element ~= nil and not element:IsUsingDefaultAnchor()
end

local function CaptureBaseAnchor(bar, control)
	if baseAnchors[bar.controlName] then
		return baseAnchors[bar.controlName]
	end
	local isValid, point, relativeTo, relativePoint, offsetX, offsetY = control:GetAnchor(0)
	if not isValid then
		return nil
	end
	local base = { point = point, relativeTo = relativeTo, relativePoint = relativePoint, offsetX = offsetX, offsetY = offsetY }
	baseAnchors[bar.controlName] = base
	return base
end

local function Apply()
	local shift = GetShift()
	-- Nothing to do when no shift is set and none was applied before.
	if shift == 0 and appliedShift == 0 then
		return
	end
	for _, bar in ipairs(BARS) do
		local control = _G[bar.controlName]
		if control and not IsMovedInHudEditor(control) then
			local base = CaptureBaseAnchor(bar, control)
			if base then
				-- One anchor only: the HUD manager asserts a single anchor.
				control:ClearAnchors()
				control:SetAnchor(base.point, base.relativeTo, base.relativePoint, base.offsetX + bar.direction * shift, base.offsetY)
			end
		end
	end
	appliedShift = shift
end

function KelaSetupResourceBars()
	if KelaPadUI.KelaResourceBarsInitialized then
		return
	end
	KelaPadUI.KelaResourceBarsInitialized = true

	-- Capture the game's own anchors before anything moves the bars.
	for _, bar in ipairs(BARS) do
		local control = _G[bar.controlName]
		if control then
			CaptureBaseAnchor(bar, control)
		end
	end

	if HUD_MANAGER then
		HUD_MANAGER:RegisterCallback("PropagateSettings", Apply)
		HUD_MANAGER:RegisterCallback("OffsetsChanged", Apply)
	end
	EVENT_MANAGER:RegisterForEvent(NAMESPACE, EVENT_PLAYER_ACTIVATED, Apply)
	-- Fired by the shift slider, so the bars move while the menu is open.
	CALLBACK_MANAGER:RegisterCallback("KELA_ACTIONBAR_SETTINGS_CHANGED", Apply)

	local optionsScene = SCENE_MANAGER:GetScene(KELA_OPTIONS_SCENE_NAME)
	if optionsScene then
		optionsScene:RegisterCallback("StateChange", function(_, newState)
			if newState == SCENE_HIDDEN then
				Apply()
			end
		end)
	end
end
