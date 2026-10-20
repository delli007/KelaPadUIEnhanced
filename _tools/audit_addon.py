#!/usr/bin/env python3
"""Static audit for KelaPadUI.

Checks manifest entries, Lua syntax, XML well-formedness, Cyrillic text,
removed references, and commented debug lines. This is a build/development
helper only; ESO does not load it.
"""

import re
import subprocess
import sys
import xml.etree.ElementTree as ET
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
MANIFEST = ROOT / "KelaPadUI.txt"
LUA53 = Path(r"lua53.exe")
SKIP_DIRS = {"_tools", "docs"}
CYRILLIC = re.compile(r"[\u0400-\u04FF]")
DEBUG_PATTERNS = re.compile(r"(?i)(CHAT_SYSTEM|AddMessage\(|--\s*(print|d|trace|debug)\b|\bDEBUG\b)")
REMOVED_IDENTIFIERS = [
    "KELA_RESEARCH",
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
KELA_STRING = re.compile(r"\b(KELA_[A-Z0-9_]+)\b")
LOCALIZATION_USE = re.compile(
    r"(?:GetString\(\s*[\"']?|(?:text|tooltipText|header|name|stringId)\s*=\s*[\"']?)(KELA_[A-Z0-9_]+)"
)
DYNAMIC_STRING_PREFIXES = (
    "KELA_RESEARCH_TYPE",  # GetString("KELA_RESEARCH_TYPE", index)
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
            if not (ROOT / "kpui_lang" / "ru.lua").exists():
                errors.append("MANIFEST missing file: kpui_lang/ru.lua")
            continue
        path = ROOT / entry
        if not path.exists():
            errors.append("MANIFEST missing file: {}".format(entry))
    return errors, entries


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
        count = len(CYRILLIC.findall(read_text(path)))
        if count:
            errors.append("CYRILLIC: {} ({} characters)".format(path.relative_to(ROOT), count))
    return errors


def check_removed_references():
    errors = []
    for path in iter_files({".lua", ".xml"}):
        text = read_text(path)
        for identifier in REMOVED_IDENTIFIERS:
            # Exact identifier only: KELA_RESEARCH_COMPAT and
            # kelaAddInfoTooltipMain are intentional retained names.
            pattern = r"(?<![A-Za-z0-9_])" + re.escape(identifier) + r"(?![A-Za-z0-9_])"
            if re.search(pattern, text):
                errors.append("REMOVED REF: {}: {}".format(path.relative_to(ROOT), identifier))
    return errors


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
        if path.name in ("en.lua", "ru.lua"):
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

    print("Manifest entries:", len(entries))
    print("Lua files checked:", lua_count)
    print("XML files checked:", xml_count)
    print("Debug comment count:")
    for path, count in debug_line_report().items():
        print("  {}: {}".format(path, count))
    undefined, unused = string_report()
    print("KELA strings used but not defined in en.lua/ru.lua:", len(undefined))
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
