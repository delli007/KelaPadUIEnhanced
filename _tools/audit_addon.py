#!/usr/bin/env python3
"""Static audit for KelaPadUI Enhanced.

Checks manifest entries, add-on identity (folder, manifest, runtime name, event
namespaces), Lua syntax, XML well-formedness and the frozen XML allowlist,
Cyrillic text (except localized `kpui_lang` files), removed references,
commented debug lines, TODO markers, direct SI constant assignments, setting ID
allocation, version consistency, BOM/U+FFFD encoding damage, broken quoted
`GetString` calls, optional library dependencies, unused virtual templates,
LibSets API compatibility, and add-on hooks on protected dialog show functions.
This is a build/development helper only; ESO does not load it.
"""

import os
import re
import shutil
import subprocess
import sys
import xml.etree.ElementTree as ET
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
# Add-on managers identify an installed add-on by its folder name and manifest
# filename. Keep ADDON_NAME in sync with both and with KelaPadUI.name.
ADDON_NAME = "KelaPadUIEnhanced"
LEGACY_ADDON_NAME = "KelaPadUI"
MANIFEST = ROOT / (ADDON_NAME + ".txt")
LIBSETS_ROOT = ROOT.parent / "LibSets"


def find_lua53():
    """Locate a Lua 5.3 interpreter for the syntax check.

    LUA53 overrides everything; then the sibling ArkadiusTradeTools copy used
    locally; then lua5.3/lua53 on PATH, which is what CI provides.
    """
    candidates = []
    override = os.environ.get("LUA53")
    if override:
        candidates.append(Path(override))
    candidates.append(
        ROOT.parent / "ArkadiusTradeTools" / "ArkadiusTradeToolsExports" / "lua53.exe"
    )
    for name in ("lua5.3", "lua53", "lua5_3"):
        found = shutil.which(name)
        if found:
            candidates.append(Path(found))
    for candidate in candidates:
        if candidate.is_file():
            return candidate
    return None


LUA53 = find_lua53()
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
SETTINGS_FILE = ROOT / "kpui_core" / "kpui_settings_gamepad.lua"
SETTING_DEF = re.compile(
    r"(?m)^[ \t]*(KELA_SETTING_PANEL_[A-Z0-9_]+|SETTING_TYPE_KELA)[ \t]*=[ \t]*(\d+)\b"
)
SETTING_BLOCKS = (
    (7300, 7399, "core"),
    (7400, 7499, "features"),
    (7500, 7599, "trading"),
    (7600, 7699, "next module family"),
    (7700, 7999, "reserve"),
)
# Legacy XML files, grandfathered. New UI is built in Lua; this allowlist exists
# so the set can only shrink. Adding a file here is a deliberate exception to
# the Lua-first rule in AGENTS.md, not a routine step.
XML_ALLOWLIST = {
    "kpui_core/kpui_templates.xml",
    "kpui_core/kpui_tooltip_gamepad.xml",
    "kpui_core/kpui_settings_gamepad.xml",
    "kpui_features/tradinghouse/kpui_tradinghouse_gamepad.xml",
    "kpui_features/sets/kpui_sets_list_gamepad.xml",
    "kpui_features/sets/kpui_sets_gamepad.xml",
    "kpui_features/mainmenu/kpui_main_menu_dashboard.xml",
}
CHANGELOG = ROOT / "changelog.txt"
QUOTED_KELA_GETSTRING = re.compile(r'GetString\(\s*"(KELA_[A-Z0-9_]+)"\s*\)')
EVENT_NAMESPACE = re.compile(
    r'EVENT_MANAGER:(?:Register|Unregister)ForEvent\(\s*"(KelaPadUI[A-Za-z0-9]*)"'
)
LOCALE_FILES = ("en.lua", "de.lua", "fr.lua", "ru.lua")


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


def check_identity():
    """Keep the folder, manifest, and runtime name in sync.

    Add-on managers match an installed add-on by folder name plus manifest
    filename, and ESO matches the add-on name in EVENT_ADD_ON_LOADED. Renaming
    only one of them leaves a dead add-on or lets the original KelaPadUI and
    this fork load side by side, which corrupts the shared settings file.
    """
    errors = []
    if ROOT.name != ADDON_NAME:
        errors.append(
            "IDENTITY: add-on folder is {!r}; expected {!r}".format(ROOT.name, ADDON_NAME)
        )
    if not MANIFEST.exists():
        return errors + ["IDENTITY: manifest not found: {}".format(MANIFEST.name)]

    metadata = manifest_metadata(MANIFEST)
    if not metadata.get("Title"):
        errors.append("IDENTITY: manifest has no ## Title")
    saved = metadata.get("SavedVariables", "").split()
    for legacy in ("kpuiSavedVariablesBuyingData", "kpuiSavedVariablesListingData"):
        if legacy in saved:
            errors.append(
                "IDENTITY: legacy saved variable {} must not be declared".format(legacy)
            )

    entry_path = ROOT / "KelaPadUI.lua"
    if not entry_path.exists():
        return errors + ["IDENTITY: missing entry file KelaPadUI.lua"]
    entry_text = read_text(entry_path)

    name_match = re.search(
        r'(?s)^KelaPadUI\s*=\s*\{.*?\bname\s*=\s*"([^"]+)"', entry_text
    )
    if not name_match:
        errors.append("IDENTITY: cannot read KelaPadUI.name from KelaPadUI.lua")
    elif name_match.group(1) != ADDON_NAME:
        errors.append(
            "IDENTITY: KelaPadUI.name is {!r}; expected {!r}".format(
                name_match.group(1), ADDON_NAME
            )
        )

    filter_match = re.search(r'addonName\s*~=\s*"([^"]+)"', entry_text)
    if filter_match and filter_match.group(1) != ADDON_NAME:
        errors.append(
            "IDENTITY: EVENT_ADD_ON_LOADED filter is {!r}; expected {!r}".format(
                filter_match.group(1), ADDON_NAME
            )
        )

    for path in iter_files({".lua"}):
        for line_number, line in enumerate(read_text(path).splitlines(), start=1):
            for namespace in EVENT_NAMESPACE.findall(line):
                if namespace != ADDON_NAME:
                    errors.append(
                        "IDENTITY: {}:{}: event namespace {!r} must be {!r}".format(
                            path.relative_to(ROOT), line_number, namespace, ADDON_NAME
                        )
                    )

    titles = {}
    for name in LOCALE_FILES:
        path = ROOT / "kpui_lang" / name
        if not path.exists():
            errors.append("IDENTITY: missing locale file kpui_lang/{}".format(name))
            continue
        found = re.search(
            r'Add\(\s*(?:"KELA_MAINMENU_TITLE"|KELA_MAINMENU_TITLE)\s*,\s*"([^"]*)"',
            read_text(path),
        )
        if not found:
            errors.append(
                "IDENTITY: kpui_lang/{} does not define KELA_MAINMENU_TITLE".format(name)
            )
            continue
        titles[name] = found.group(1)
    if len(set(titles.values())) > 1:
        errors.append(
            "IDENTITY: KELA_MAINMENU_TITLE differs across locales: {}".format(
                ", ".join("{}={!r}".format(key, value) for key, value in sorted(titles.items()))
            )
        )
    return errors


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
    if LUA53 is None or not LUA53.exists():
        return [
            "Lua 5.3 interpreter not found; install lua5.3, add it to PATH, or set "
            "the LUA53 environment variable (Lua syntax check skipped)"
        ], 0
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
        relative = path.relative_to(ROOT).as_posix()
        if relative not in XML_ALLOWLIST:
            errors.append(
                "XML: {} is not in XML_ALLOWLIST; build new UI in Lua "
                "(see AGENTS.md)".format(relative)
            )
        try:
            ET.parse(path)
        except Exception as exc:  # noqa: BLE001 - report parser message
            errors.append("XML: {}: {}".format(relative, exc))
    for relative in sorted(XML_ALLOWLIST - {path.relative_to(ROOT).as_posix() for path in iter_files({".xml"})}):
        errors.append("XML allowlist entry does not exist: {}".format(relative))
    return errors, checked


def check_text_encoding():
    """Reject a BOM or a UTF-8 replacement character in client-loaded files."""
    errors = []
    for path in iter_files({".lua", ".xml", ".txt"}):
        data = path.read_bytes()
        relative = path.relative_to(ROOT).as_posix()
        if data.startswith(b"\xef\xbb\xbf"):
            errors.append("ENCODING: {} starts with a UTF-8 BOM".format(relative))
        if b"\xef\xbf\xbd" in data:
            errors.append(
                "ENCODING: {} contains U+FFFD (a mangled character); "
                "rewrite the text as UTF-8 without BOM".format(relative)
            )
    return errors


def check_quoted_kela_getstring():
    """Reject GetString("KELA_FOO") without a context argument.

    GetString's first argument is a string variable prefix, not an id, so this
    form silently renders nothing. Dynamic lookups pass a second argument and
    are allowed: GetString("KELA_SETSSOURCE", index).
    """
    errors = []
    for path in iter_files({".lua"}):
        for line_number, line in enumerate(read_text(path).splitlines(), start=1):
            for name in QUOTED_KELA_GETSTRING.findall(line):
                errors.append(
                    'GETSTRING: {}:{}: GetString("{}") has no context argument; '
                    "pass the numeric constant instead".format(
                        path.relative_to(ROOT), line_number, name
                    )
                )
    return errors


def check_versions():
    metadata = manifest_metadata(MANIFEST)
    version = metadata.get("Version", "")
    addon_version = metadata.get("AddOnVersion", "")
    errors = []
    match = re.fullmatch(r"(\d+)\.(\d+)\.(\d+)", version)
    if not match:
        errors.append("VERSION: manifest ## Version is not major.minor.patch: {!r}".format(version))
        return errors
    expected = int(match.group(1)) * 10000 + int(match.group(2)) * 100 + int(match.group(3))
    if not addon_version:
        errors.append("VERSION: manifest is missing ## AddOnVersion")
    elif addon_version != str(expected):
        errors.append(
            "VERSION: ## AddOnVersion {} does not match ## Version {} (expected {})".format(
                addon_version, version, expected
            )
        )
    if CHANGELOG.exists():
        for line in read_text(CHANGELOG).splitlines():
            top = re.match(r"(\d+\.\d+\.\d+)\b", line.strip())
            if top:
                if top.group(1) != version:
                    errors.append(
                        "VERSION: changelog top {} does not match manifest {}".format(
                            top.group(1), version
                        )
                    )
                break
    return errors


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


def extract_lua_table(text, name):
    """Return the text between the braces of `name = { ... }`, or None."""
    match = re.search(r"\b{}\s*=\s*\{{".format(re.escape(name)), text)
    if not match:
        return None
    start = text.index("{", match.start())
    depth = 0
    index = start
    quote = None
    while index < len(text):
        char = text[index]
        if quote:
            if char == "\\":
                index += 2
                continue
            if char == quote:
                quote = None
            index += 1
            continue
        if char in ("'", '"'):
            quote = char
        elif char == "{":
            depth += 1
        elif char == "}":
            depth -= 1
            if depth == 0:
                return text[start:index + 1]
        index += 1
    return None


def check_setting_ids():
    """Validate the KelaPadUI setting ID block allocation."""
    if not SETTINGS_FILE.exists():
        return ["settings file missing: {}".format(SETTINGS_FILE)], []

    text = strip_lua_comments(read_text(SETTINGS_FILE))
    errors = []
    defined = {}
    for name, value in SETTING_DEF.findall(text):
        number = int(value)
        if name == "SETTING_TYPE_KELA":
            if number != 7000:
                errors.append("SETTING_TYPE_KELA must be 7000, found {}".format(number))
            continue
        if number in defined.values():
            other = next(key for key, assigned in defined.items() if assigned == number)
            errors.append(
                "duplicate setting ID {}: {} and {}".format(number, other, name)
            )
        defined[name] = number
        if not (7300 <= number <= 7999):
            errors.append(
                "setting ID {} for {} is outside the Kela block (7300-7999)".format(
                    number, name
                )
            )

    retired_text = extract_lua_table(text, "KELA_RETIRED_SETTING_IDS")
    if retired_text is None:
        errors.append("KELA_RETIRED_SETTING_IDS table not found")
        retired = set()
    else:
        retired = {int(value) for value in re.findall(r"\b(\d+)\b", retired_text)}
    for name, number in defined.items():
        if number in retired:
            errors.append(
                "live setting ID {} for {} is marked retired".format(number, name)
            )

    legacy_text = extract_lua_table(text, "KELA_LEGACY_SETTING_IDS")
    legacy = set()
    if legacy_text:
        legacy = {int(value) for value in re.findall(r"\b(\d+)\b", legacy_text)}
    for name, number in defined.items():
        if number in legacy:
            errors.append(
                "setting ID {} for {} collides with KELA_LEGACY_SETTING_IDS".format(
                    number, name
                )
            )

    data_text = extract_lua_table(text, "KELA_SETTINGS_DATA") or ""
    defaults_text = extract_lua_table(text, "KELA_SETTINGS_DEFAULTS") or ""
    category_text = extract_lua_table(text, "KELA_SETTINGS_CATEGORY_ORDER") or ""

    panels = set(re.findall(r"\b(KELA_SETTING_PANEL_[A-Z0-9_]+)\b", category_text))
    data_panels = set(
        re.findall(r"\[\s*(KELA_SETTING_PANEL_[A-Z0-9_]+)\s*\]", data_text)
    )
    data_settings = set(
        re.findall(r"\bsettingId\s*=\s*(KELA_SETTING_PANEL_[A-Z0-9_]+)", data_text)
    )
    default_settings = set(
        re.findall(r"\[\s*(KELA_SETTING_PANEL_[A-Z0-9_]+)\s*\]", defaults_text)
    )

    for name in sorted(panels - data_panels):
        errors.append("panel {} is not a key in KELA_SETTINGS_DATA".format(name))
    for name in sorted(data_panels - panels):
        errors.append(
            "KELA_SETTINGS_DATA key {} is not in KELA_SETTINGS_CATEGORY_ORDER".format(
                name
            )
        )
    for name in sorted(data_settings - set(defined)):
        errors.append(
            "KELA_SETTINGS_DATA uses undefined setting constant {}".format(name)
        )
    for name in sorted(default_settings - set(defined)):
        errors.append(
            "KELA_SETTINGS_DEFAULTS uses undefined setting constant {}".format(name)
        )
    live_settings = set(defined) - panels
    for name in sorted(live_settings - data_settings):
        errors.append("setting {} has no KELA_SETTINGS_DATA entry".format(name))
    for name in sorted(live_settings - default_settings):
        errors.append("setting {} has no KELA_SETTINGS_DEFAULTS entry".format(name))

    blocked = retired | legacy
    info = []
    for low, high, label in SETTING_BLOCKS:
        used = sorted(number for number in defined.values() if low <= number <= high)
        next_free = next(
            (
                candidate
                for candidate in range(low, high + 1)
                if candidate not in used and candidate not in blocked
            ),
            None,
        )
        info.append((label, used, next_free))
    return errors, info


def main():
    sys.stdout.reconfigure(encoding="utf-8", errors="replace")
    errors = []
    manifest_errors, entries = check_manifest()
    errors.extend(manifest_errors)
    errors.extend(check_identity())
    lua_errors, lua_count = check_lua_syntax()
    errors.extend(lua_errors)
    xml_errors, xml_count = check_xml()
    errors.extend(xml_errors)
    errors.extend(check_cyrillic())
    errors.extend(check_removed_references())
    errors.extend(check_todo_markers())
    errors.extend(check_si_global_assignments())
    setting_errors, setting_info = check_setting_ids()
    errors.extend(setting_errors)
    errors.extend(check_text_encoding())
    errors.extend(check_quoted_kela_getstring())
    errors.extend(check_versions())
    errors.extend(check_library_dependencies())
    dialog_hook_errors = check_dialog_hooks()
    errors.extend(dialog_hook_errors)
    unused_virtual, virtual_count = virtual_template_report()
    for name, path in unused_virtual:
        errors.append("UNUSED VIRTUAL: {}: {}".format(path, name))
    libsets_errors, libsets_info = check_libsets()
    errors.extend(libsets_errors)

    print("Manifest entries:", len(entries))
    print("Add-on identity: {} ({})".format(ADDON_NAME, MANIFEST.name))
    print("Lua interpreter:", LUA53 if LUA53 else "not found")
    print("Lua files checked:", lua_count)
    print("XML files checked:", xml_count)
    print("XML allowlist: {} frozen legacy file(s)".format(len(XML_ALLOWLIST)))
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
    print("Setting ID allocation:")
    for label, used, next_free in setting_info:
        highest = max(used) if used else "-"
        print("  {}: highest {}, next free {}".format(label, highest, next_free))
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
