#!/usr/bin/env python3
"""Static audit for KelaPadUI.

Checks manifest entries, Lua syntax, XML well-formedness, Cyrillic text
(except localized `kpui_lang` files), removed references, commented debug
lines, TODO markers, direct SI constant assignments, optional library
dependencies, unused virtual templates, LibSets API compatibility, and add-on
hooks on protected dialog show functions.
This is a build/development helper only; ESO does not load it.
"""

import re
import subprocess
import sys
import xml.etree.ElementTree as ET
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
MANIFEST = ROOT / "KelaPadUI.txt"
LIBSETS_ROOT = ROOT.parent / "LibSets"
LUA53 = Path(r"lua53.exe")
SKIP_DIRS = {"_tools", "docs"}
CYRILLIC = re.compile(r"[\u0400-\u04FF]")
DEBUG_PATTERNS = re.compile(r"(?i)(CHAT_SYSTEM|AddMessage\(|--\s*(print|d|trace|debug)\b|\bDEBUG\b)")
TODO_PATTERN = re.compile(r"\b(TODO|FIXME|HACK|XXX)\b")
SI_GLOBAL_ASSIGN = re.compile(r"(?m)^[ \t]*(SI_[A-Z0-9_]+)[ \t]*=(?!=)")
VIRTUAL_TAG = re.compile(r"<[^>]*\bvirtual=\"true\"[^>]*>", re.S)
NAME_ATTR = re.compile(r'\bname="([^"]+)"')
REMOVED_IDENTIFIERS = [
    "KELA_RESEARCH",
    "KELA_RESEARCH_COMPAT",
    "KELA_UNDAUNTED",
    "KELA_QUICKACCESS",
    "Kela_QuickAccess",
    "KELA_SETTING_PANEL_QUICKACCESS_",
    "KELA_SETTING_PANEL_RESEARCHES",
    "KELA_SETTING_PANEL_UPU",
    "AddGamepadRallyPoint",
    "kelaAddInfoTooltip",
    "KELA_SETTING_PANEL_SUPPORT_",
    "KELA_SETTINGS_SUPPORT_",
    "KELA_SETTINGS_MAININFO_ACHIV",
    "KELA_SETTING_PANEL_MAININFO_ACHIVTRACK",
    "KelaPadUI.donations",
]
LIBRARY_GLOBAL_ADDONS = {
    "LIB_ITEM_LINK": "LibItemLink",
}
LIBSETS_USE = re.compile(r"\bLibSets\.([A-Za-z_]\w*)")
LIBSETS_GLOBAL_USE = re.compile(r"\b(LIBSETS_[A-Z0-9_]+)\b")
# Core functions that build the pooled gamepad dialog keybind descriptors.
# Hooking them (even with the Secure variants) creates those closures from an
# add-on callstack, which ESO marks as untrusted for the rest of the session.
# Pressing a button on any later core dialog that calls a private function then
# fails ("Attempt to access a private function ... from insecure code"), for
# example CancelTaskbarWindowFlash when accepting a ready check.
DIALOG_HOOK_TARGETS = (
    "ZO_Dialogs_ShowDialog",
    "ZO_Dialogs_ShowGamepadDialog",
    "ZO_Dialogs_ShowPlatformDialog",
    "ZO_Dialogs_ButtonKeybindPressed",
    "ZO_GamepadTradingHouse_Dialogs_DisplayConfirmationDialog",
)
HOOK_CALLS = ("ZO_PreHook", "ZO_PostHook", "SecurePreHook", "SecurePostHook")
KELA_STRING = re.compile(r"\b(KELA_[A-Z0-9_]+)\b")
LOCALIZATION_USE = re.compile(
    r"(?:GetString\(\s*[\"']?|(?:text|tooltipText|header|name|stringId)\s*=\s*[\"']?)(KELA_[A-Z0-9_]+)"
)
DYNAMIC_STRING_PREFIXES = (
    "KELA_SETTINGSYSTEMPANEL",  # categories build keys with the panel id
    "KELA_SETSBONUSGROUP",
    "KELA_SETSBOUND",
    "KELA_SETSOBTAINABLE",
    "KELA_SETSSOURCE",
    "KELA_SETS_METADATAATTRIBUTE",
    "KELA_TRADING_ITEMTYPE_SALES_BYGUILDS",
    "KELA_TRADING_RESUMEPRICE",
    "KELA_TRADING_RESUMEPRICEDIALOG",
)


def iter_files(suffixes):
    for path in sorted(ROOT.rglob("*")):
        if not path.is_file() or path.suffix.lower() not in suffixes:
            continue
        if any(part in SKIP_DIRS for part in path.relative_to(ROOT).parts):
            continue
        yield path


def read_text(path):
    return path.read_text(encoding="utf-8", errors="replace")


def strip_lua_comments(text):
    result = []
    i = 0
    while i < len(text):
        if text.startswith("--", i):
            if text.startswith("--[[", i):
                end = text.find("]]", i + 4)
                i = len(text) if end < 0 else end + 2
            else:
                end = text.find("\n", i)
                i = len(text) if end < 0 else end
            continue

        char = text[i]
        result.append(char)
        if char in ("'", '"'):
            quote = char
            i += 1
            while i < len(text):
                result.append(text[i])
                if text[i] == "\\" and i + 1 < len(text):
                    result.append(text[i + 1])
                    i += 2
                    continue
                if text[i] == quote:
                    i += 1
                    break
                i += 1
            continue
        i += 1
    return "".join(result)


def manifest_metadata(path):
    metadata = {}
    for line in read_text(path).splitlines():
        stripped = line.strip()
        if not stripped.startswith("##") or ":" not in stripped:
            continue
        key, value = stripped[2:].split(":", 1)
        metadata[key.strip()] = value.strip()
    return metadata


def check_manifest():
    errors = []
    entries = []
    for line in read_text(MANIFEST).splitlines():
        stripped = line.strip()
        if not stripped or stripped.startswith("#") or stripped.startswith(";") or stripped.startswith("##"):
            continue
        if stripped.startswith("kpui_") or stripped.startswith("KelaPadUI"):
            entries.append(stripped)
    for entry in entries:
        if "$(language)" in entry:
            if not (ROOT / "kpui_lang" / "en.lua").exists():
                errors.append("MANIFEST missing file: kpui_lang/en.lua")
            continue
        path = ROOT / entry
        if not path.exists():
            errors.append("MANIFEST missing file: {}".format(entry))
    return errors, entries


def check_library_dependencies():
    metadata = manifest_metadata(MANIFEST)
    declared = set(
        (metadata.get("DependsOn", "") + " " + metadata.get("OptionalDependsOn", "")).split()
    )
    errors = []
    for path in iter_files({".lua"}):
        text = strip_lua_comments(read_text(path))
        for global_name, addon_name in LIBRARY_GLOBAL_ADDONS.items():
            if re.search(r"\b{}\b".format(global_name), text) and addon_name not in declared:
                errors.append(
                    "LIBRARY {} used in {} but {} is not in DependsOn/OptionalDependsOn".format(
                        global_name, path.relative_to(ROOT), addon_name
                    )
                )
    return errors


def check_dialog_hooks():
    errors = []
    for path in iter_files({".lua"}):
        for line_number, line in enumerate(read_text(path).splitlines(), start=1):
            if not any(re.search(r"\b" + re.escape(hook) + r"\s*\(", line) for hook in HOOK_CALLS):
                continue
            for target in DIALOG_HOOK_TARGETS:
                if re.search(r"(?<![A-Za-z0-9_])" + re.escape(target) + r"(?![A-Za-z0-9_])", line):
                    errors.append(
                        "DIALOG HOOK: {}:{}: {} must not be hooked; decorate from a dialog-owned "
                        "setup function instead (see docs/DEVELOPMENT_NOTES.md)".format(
                            path.relative_to(ROOT), line_number, target
                        )
                    )
    return errors


def check_lua_syntax():
    errors = []
    if not LUA53.exists():
        return ["lua53.exe not found; Lua syntax check skipped"], 0
    checked = 0
    for path in iter_files({".lua"}):
        checked += 1
        code = "local f,e=loadfile([[" + str(path) + "]]); if not f then print(e); os.exit(1) end"
        result = subprocess.run([str(LUA53), "-e", code], capture_output=True, text=True)
        if result.returncode != 0:
            errors.append("LUA syntax: {}: {}".format(path.relative_to(ROOT), (result.stdout + result.stderr).strip()))
    return errors, checked


def check_xml():
    errors = []
    checked = 0
    for path in iter_files({".xml"}):
        checked += 1
        try:
            ET.parse(path)
        except Exception as exc:  # noqa: BLE001 - report parser message
            errors.append("XML: {}: {}".format(path.relative_to(ROOT), exc))
    return errors, checked


def check_cyrillic():
    errors = []
    for path in iter_files({".lua", ".xml", ".txt"}):
        # Localized strings legitimately use non-Latin scripts (for example
        # kpui_lang/ru.lua). English source files must stay Latin-only.
        if path.parent == ROOT / "kpui_lang" and path.name != "en.lua":
            continue
        count = len(CYRILLIC.findall(read_text(path)))
        if count:
            errors.append("CYRILLIC: {} ({} characters)".format(path.relative_to(ROOT), count))
    return errors


def check_removed_references():
    errors = []
    for path in iter_files({".lua", ".xml"}):
        text = read_text(path)
        for identifier in REMOVED_IDENTIFIERS:
            # Exact identifier only: kelaAddInfoTooltipMain is an intentional
            # retained name.
            pattern = r"(?<![A-Za-z0-9_])" + re.escape(identifier) + r"(?![A-Za-z0-9_])"
            if re.search(pattern, text):
                errors.append("REMOVED REF: {}: {}".format(path.relative_to(ROOT), identifier))
    return errors


def check_todo_markers():
    errors = []
    for path in iter_files({".lua", ".xml"}):
        text = read_text(path)
        for match in TODO_PATTERN.finditer(text):
            line = text.count("\n", 0, match.start()) + 1
            errors.append(
                "TODO marker: {}:{}: {}".format(
                    path.relative_to(ROOT), line, match.group(1)
                )
            )
    return errors


def check_si_global_assignments():
    errors = []
    for path in iter_files({".lua"}):
        text = strip_lua_comments(read_text(path))
        for match in SI_GLOBAL_ASSIGN.finditer(text):
            line = text.count("\n", 0, match.start()) + 1
            errors.append(
                "SI GLOBAL ASSIGN: {}:{}: {}".format(
                    path.relative_to(ROOT), line, match.group(1)
                )
            )
    return errors


def virtual_template_report():
    definitions = {}
    for path in iter_files({".xml"}):
        for tag in VIRTUAL_TAG.findall(read_text(path)):
            match = NAME_ATTR.search(tag)
            if match:
                definitions.setdefault(match.group(1), path.relative_to(ROOT))

    texts = [read_text(path) for path in iter_files({".lua", ".xml"})]
    unused = []
    for name, path in definitions.items():
        pattern = re.compile(r"(?<![A-Za-z0-9_])" + re.escape(name) + r"(?![A-Za-z0-9_])")
        references = sum(len(pattern.findall(text)) for text in texts)
        if references <= 1:
            unused.append((name, path))
    return unused, len(definitions)


def check_libsets():
    errors = []
    info = {"available": False, "version": None, "api": [], "checked": 0}
    manifest = LIBSETS_ROOT / "LibSets.addon"
    if not manifest.exists():
        return errors, info

    info["available"] = True
    metadata = manifest_metadata(manifest)
    info["version"] = metadata.get("Version", "unknown")
    info["api"] = metadata.get("APIVersion", "").split()

    for api in manifest_metadata(MANIFEST).get("APIVersion", "").split():
        if api not in info["api"]:
            errors.append(
                "LIBSETS API version mismatch: add-on {}, LibSets {}".format(
                    api, " ".join(info["api"]) or "unknown"
                )
            )

    lib_text = "\n".join(
        strip_lua_comments(read_text(path))
        for path in sorted(LIBSETS_ROOT.rglob("*.lua"))
    )
    defined = set(re.findall(r"function\s+(?:lib|LibSets)\.([A-Za-z_]\w*)", lib_text))
    defined.update(re.findall(r"\b(?:lib|LibSets)\.([A-Za-z_]\w*)\s*=", lib_text))

    used = set()
    used_globals = set()
    for path in iter_files({".lua"}):
        text = strip_lua_comments(read_text(path))
        used.update(LIBSETS_USE.findall(text))
        used_globals.update(LIBSETS_GLOBAL_USE.findall(text))

    info["checked"] = len(used)
    for name in sorted(used - defined):
        errors.append("LIBSETS API missing: LibSets.{}".format(name))
    for name in sorted(used_globals):
        if not re.search(r"\b" + re.escape(name) + r"\s*=", lib_text):
            errors.append("LIBSETS constant missing: {}".format(name))

    return errors, info


def debug_line_report():
    report = {}
    for path in iter_files({".lua"}):
        count = 0
        for line in read_text(path).splitlines():
            stripped = line.strip()
            if stripped.startswith("--") and DEBUG_PATTERNS.search(stripped):
                count += 1
        if count:
            report[str(path.relative_to(ROOT))] = count
    return report


def string_report():
    defined = set()
    used = set()
    identifiers = set()
    for path in iter_files({".lua", ".xml"}):
        text = read_text(path)
        if path.name == "en.lua":
            defined.update(re.findall(r"Add\(\"(KELA_[A-Z0-9_]+)\"", text))
            continue
        used.update(LOCALIZATION_USE.findall(text))
        identifiers.update(KELA_STRING.findall(text))
    dynamic_defined = {name for name in defined if name.startswith(DYNAMIC_STRING_PREFIXES)}
    undefined = {
        name
        for name in used - defined
        if not name.startswith(DYNAMIC_STRING_PREFIXES)
    }
    return sorted(undefined), sorted(defined - identifiers - dynamic_defined)


def main():
    sys.stdout.reconfigure(encoding="utf-8", errors="replace")
    errors = []
    manifest_errors, entries = check_manifest()
    errors.extend(manifest_errors)
    lua_errors, lua_count = check_lua_syntax()
    errors.extend(lua_errors)
    xml_errors, xml_count = check_xml()
    errors.extend(xml_errors)
    errors.extend(check_cyrillic())
    errors.extend(check_removed_references())
    errors.extend(check_todo_markers())
    errors.extend(check_si_global_assignments())
    errors.extend(check_library_dependencies())
    dialog_hook_errors = check_dialog_hooks()
    errors.extend(dialog_hook_errors)
    unused_virtual, virtual_count = virtual_template_report()
    for name, path in unused_virtual:
        errors.append("UNUSED VIRTUAL: {}: {}".format(path, name))
    libsets_errors, libsets_info = check_libsets()
    errors.extend(libsets_errors)

    print("Manifest entries:", len(entries))
    print("Lua files checked:", lua_count)
    print("XML files checked:", xml_count)
    print("Virtual templates checked:", virtual_count)
    if dialog_hook_errors:
        print("Dialog hook guard: {} violation(s)".format(len(dialog_hook_errors)))
    else:
        print("Dialog hook guard: clean ({} protected functions)".format(len(DIALOG_HOOK_TARGETS)))
    if libsets_info["available"]:
        print(
            "LibSets version: {} (API {})".format(
                libsets_info["version"], " ".join(libsets_info["api"])
            )
        )
        print("LibSets APIs checked:", libsets_info["checked"])
    else:
        print("LibSets check skipped: sibling LibSets add-on not found")
    for name, path in unused_virtual:
        print("  UNUSED VIRTUAL", name, "({})".format(path))
    print("Debug comment count:")
    for path, count in debug_line_report().items():
        print("  {}: {}".format(path, count))
    undefined, unused = string_report()
    print("KELA strings used but not defined in en.lua:", len(undefined))
    for name in undefined:
        print("  UNDEFINED", name)
    print("KELA strings defined but not used:", len(unused))
    for name in unused:
        print("  UNUSED", name)

    if errors:
        print("")
        print("AUDIT FAILED ({} issue(s))".format(len(errors)))
        for error in errors:
            print(" -", error)
        return 1

    print("")
    print("AUDIT PASSED")
    return 0


if __name__ == "__main__":
    sys.exit(main())
