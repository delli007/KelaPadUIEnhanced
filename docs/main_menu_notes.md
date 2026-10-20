# Removed main-menu travel notes

The gamepad pause-menu travel-notes panel was removed because it caused
instability in the current UI. The associated settings and runtime code are no
longer loaded.

## What was removed

- Settings category `KELA_SETTING_PANEL_MAINMENU` (`7100`).
- Settings:
  - `KELA_SETTING_PANEL_MAININFO_ENABLED` (`7101`) - travel notes.
  - `KELA_SETTING_PANEL_MAININFO_NOTES` (`7102`) - notes block.
  - `KELA_SETTING_PANEL_MAININFO_QUEST` (`7104`) - focused quest block.
- `kelaAddInfoTooltipMain()` in `kpui_features/kpui_info_tooltip.lua`.
- The corresponding `KELA_SETTINGS_MAININFO_*` localization strings.

The general tooltip replacement code in `kpui_info_tooltip.lua` is still used by
`KelaSetupTooltips()` and was intentionally kept.

## Restoration notes

The old panel was built as a KelaPadUI tooltip that was inserted into the pause
menu. It read inventory, research, soul-gem, and quest data. If this feature is
restored, prefer a separate scene or fragment instead of adding another tooltip
to the pause menu, and gate it behind a feature toggle in the `Features`
category. Avoid reusing the old setting IDs unless the old values are migrated.

The archived implementation can be recovered from the Git history before the
commit that removed it.
