#!/usr/bin/env python3
"""Generate KelaPadUI locale files from the English source.

Usage:
    python _tools/translate_kpui_lang.py de
    python _tools/translate_kpui_lang.py fr ru
    python _tools/translate_kpui_lang.py --all

The default backend is the free Google NMT endpoint (no API key, stdlib
only). Pass --offline to use argostranslate instead; that path installs the
package and its en-><lang> model on demand.

Strings that exactly match a string in the ESO client's own language files
are taken from those files, so ESO terminology (Group Finder, Infinite
Archive, Tamriel Tomes, ...) stays consistent with the game. Everything else
is machine translated. Placeholders (<<1>>, %d, %s, ...) and newlines are
validated after every translation; a string that fails validation twice is
left in English and reported at the end.

This is a build/development helper only; ESO does not load it.
"""

from __future__ import annotations

import argparse
import json
import re
import subprocess
import sys
import time
import urllib.error
import urllib.parse
import urllib.request
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
EN_PATH = ROOT / "kpui_lang" / "en.lua"
LANG_DIR = ROOT / "kpui_lang"
DEFAULT_CACHE = Path(__file__).resolve().parent / ".translation_cache.json"
DEFAULT_CLIENT_LANG_DIR = ROOT.parents[2] / "esoui-sourcecode" / "esoui" / "lang"
SUPPORTED = ("de", "fr", "ru")
CAMPAIGN = ("de", "fr", "ru")

ADD_LINE = re.compile(
    r'^(?P<indent>[ \t]*)Add\("(?P<id>KELA_[A-Z0-9_]+)"\s*,\s*'
    r'"(?P<text>(?:[^"\\]|\\.)*)"\)\s*$'
)
SAFE_ADD_LINE = re.compile(
    r'^(?P<indent>[ \t]*)Add\((?P<id>KELA_[A-Z0-9_]+)\s*,\s*'
    r'"(?P<text>(?:[^"\\]|\\.)*)"\s*,\s*0\)\s*$'
)
CLIENT_STRING = re.compile(
    r'\bSAS\(\s*(?P<id>SI_[A-Z0-9_]+)\s*,\s*'
    r'"(?P<text>(?:[^"\\]|\\.)*)"\s*,\s*\d+\s*\)'
)
TOKEN = re.compile(
    r"<<(?:(?P<prefix>[A-Za-z]):)?(?P<index>\d+)"
    r"(?:\[(?P<plural>[^\]]*)\])?>>"
)
PLAIN_TOKEN = re.compile(r"<<(?:(?:[A-Za-z]:)?\d+)>>")
PERCENT = re.compile(r"%(?:%|[-+ #0]*\d*(?:\.\d+)?[sdif])")
BRAND_TOKENS = ("KelaPadUI Enhanced", "KelaPadUI", "ESO+", "USPF")

# Hand-checked terminology that is ambiguous as a bare exact match.
OVERRIDES = {
    "Undaunted": {"de": "Unerschrockene", "fr": "Indomptables", "ru": "Неустрашимые"},
}


# --------------------------------------------------------------------------
# Lua string helpers
# --------------------------------------------------------------------------

def unescape_lua(value: str) -> str:
    out = []
    i = 0
    while i < len(value):
        char = value[i]
        if char == "\\" and i + 1 < len(value):
            nxt = value[i + 1]
            if nxt == "n":
                out.append("\n")
            elif nxt == "t":
                out.append("\t")
            elif nxt == "r":
                out.append("\r")
            elif nxt == '"':
                out.append('"')
            elif nxt == "\\":
                out.append("\\")
            else:
                out.append(nxt)
            i += 2
            continue
        out.append(char)
        i += 1
    return "".join(out)


def escape_lua(value: str) -> str:
    return (
        value.replace("\\", "\\\\")
        .replace('"', '\\"')
        .replace("\r", "\\r")
        .replace("\n", "\\n")
        .replace("\t", "\\t")
    )


def token_signature(value: str) -> tuple:
    tokens = []
    for match in TOKEN.finditer(value):
        plural = match.group("plural")
        tokens.append(
            (
                match.group("prefix"),
                int(match.group("index")),
                plural is not None,
                plural.count("$") if plural else 0,
                plural.count("/") if plural else 0,
            )
        )
    return (
        tuple(tokens),
        len(PERCENT.findall(value)),
        value.count("\n"),
    )


# --------------------------------------------------------------------------
# Source parsing / writing
# --------------------------------------------------------------------------

def read_lines(path: Path) -> tuple[list[str], str]:
    with path.open("r", encoding="utf-8-sig", newline="") as handle:
        raw = handle.read()
    newline = "\r\n" if "\r\n" in raw else "\n"
    lines = raw.replace("\r\n", "\n").replace("\r", "\n").split("\n")
    if lines and lines[-1] == "":
        lines.pop()
    return lines, newline


def parse_source(path: Path):
    lines, newline = read_lines(path)
    entries = []
    for line_number, line in enumerate(lines, start=1):
        match = ADD_LINE.match(line)
        if not match:
            if 'Add("KELA_' in line:
                raise SystemExit(
                    "Unhandled Add() line {}: {}".format(line_number, line)
                )
            continue
        entries.append(
            {
                "line": line_number,
                "id": match.group("id"),
                "text": unescape_lua(match.group("text")),
            }
        )
    if not entries:
        raise SystemExit("No KELA Add() entries found in {}".format(path))
    return lines, newline, entries


def render_locale(source_lines, newline, entries, translations, target):
    out = [
        "-- Generated from kpui_lang/en.lua by _tools/translate_kpui_lang.py.",
        "-- Do not edit by hand; regenerate with:",
        "--   python _tools/translate_kpui_lang.py {}".format(target),
        "",
    ]
    entry_by_line = {entry["line"]: entry for entry in entries}
    for line_number, line in enumerate(source_lines, start=1):
        entry = entry_by_line.get(line_number)
        if entry is None:
            if "local Add = ZO_CreateStringId" in line:
                out.append(line.replace("ZO_CreateStringId", "SafeAddString"))
            else:
                out.append(line)
            continue
        indent = ADD_LINE.match(line).group("indent")
        translated = translations[entry["id"]]
        out.append(
            '{}Add({}, "{}", 0)'.format(
                indent, entry["id"], escape_lua(translated)
            )
        )
    return newline.join(out) + newline


def write_locale(path: Path, content: str):
    with path.open("w", encoding="utf-8", newline="") as handle:
        handle.write(content)


# --------------------------------------------------------------------------
# ESO client terminology
# --------------------------------------------------------------------------

def load_client_strings(path: Path) -> dict[str, str]:
    strings = {}
    if not path.exists():
        return strings
    with path.open("r", encoding="utf-8-sig", errors="replace") as handle:
        for line in handle:
            match = CLIENT_STRING.search(line)
            if match:
                strings[match.group("id")] = unescape_lua(match.group("text"))
    return strings


def clean_official_text(value: str) -> str:
    # ESO grammar tags such as ^m, ^f, ^n, ^p are not display text.
    return re.sub(r"\^[A-Za-z]", "", value).strip()


def build_official_map(client_dir: Path, targets):
    result = {}
    if not client_dir.exists():
        print("Client language files not found at {}; skipping official terms.".format(client_dir))
        return result

    english = load_client_strings(client_dir / "en_client.lua")
    localized = {
        lang: load_client_strings(client_dir / "{}_client.lua".format(lang))
        for lang in targets
    }

    reverse = {}
    for string_id, text in english.items():
        reverse.setdefault(text, string_id)

    for text, string_id in reverse.items():
        if text in OVERRIDES:
            official = {
                lang: OVERRIDES[text][lang]
                for lang in targets
                if lang in OVERRIDES[text]
            }
            if len(official) == len(targets):
                result[text] = official
            continue

        official = {}
        valid = True
        for lang in targets:
            value = localized[lang].get(string_id)
            if not value or "|c" in value or "|r" in value:
                valid = False
                break
            value = clean_official_text(value)
            if not value:
                valid = False
                break
            official[lang] = value
        if valid:
            result[text] = official
    return result


# --------------------------------------------------------------------------
# Translation backends
# --------------------------------------------------------------------------

class GoogleBackend:
    name = "google"
    ENDPOINT = "https://translate.googleapis.com/translate_a/single"

    def __init__(self, delay):
        self.delay = delay

    def translate(self, text: str, target: str, retries: int = 4) -> str:
        params = urllib.parse.urlencode(
            {"client": "gtx", "sl": "en", "tl": target, "dt": "t", "q": text}
        )
        request = urllib.request.Request(
            "{}?{}".format(self.ENDPOINT, params),
            headers={"User-Agent": "Mozilla/5.0 (KelaPadUI translator)"},
        )
        wait = 1.0
        for attempt in range(retries + 1):
            try:
                with urllib.request.urlopen(request, timeout=30) as response:
                    data = json.load(response)
                translated = "".join(
                    segment[0]
                    for segment in data[0]
                    if segment and segment[0]
                )
                if not translated:
                    raise ValueError("empty translation")
                time.sleep(self.delay)
                return translated
            except (urllib.error.URLError, urllib.error.HTTPError, TimeoutError,
                    json.JSONDecodeError, ValueError, IndexError) as exc:
                if attempt >= retries:
                    raise RuntimeError(
                        "Google translation failed for {!r}: {}".format(text[:60], exc)
                    )
                time.sleep(wait)
                wait *= 2
        raise RuntimeError("unreachable")


class ArgosBackend:
    name = "argos"

    def __init__(self, targets):
        try:
            import argostranslate.package  # noqa: F401
            import argostranslate.translate  # noqa: F401
        except ImportError:
            print("argostranslate is not installed; installing it...")
            subprocess.check_call(
                [sys.executable, "-m", "pip", "install", "argostranslate"]
            )
            import argostranslate.package  # noqa: F401
            import argostranslate.translate  # noqa: F401

        import argostranslate.package
        import argostranslate.translate

        self.package = argostranslate.package
        self.translate_module = argostranslate.translate
        self.package.update_package_index()
        available = self.package.get_available_packages()
        installed = {
            (package.from_code, package.to_code)
            for package in self.package.get_installed_packages()
        }
        for target in targets:
            if ("en", target) in installed:
                continue
            package = next(
                (
                    candidate
                    for candidate in available
                    if candidate.from_code == "en" and candidate.to_code == target
                ),
                None,
            )
            if package is None:
                raise SystemExit(
                    "No argostranslate en->{} model is available.".format(target)
                )
            print("Downloading argostranslate en->{} model...".format(target))
            self.package.install_from_path(package.download())

    def translate(self, text: str, target: str, retries: int = 0) -> str:
        translation = self.translate_module.get_translation_from_codes("en", target)
        return translation.translate(text)


# --------------------------------------------------------------------------
# Translation orchestration
# --------------------------------------------------------------------------

class Cache:
    def __init__(self, path: Path):
        self.path = path
        try:
            with path.open("r", encoding="utf-8") as handle:
                self.data = json.load(handle)
        except (OSError, json.JSONDecodeError):
            self.data = {}
        self.dirty = False

    def get(self, backend, target, text):
        return self.data.get("{}|{}|{}".format(backend, target, text))

    def put(self, backend, target, text, translated):
        self.data["{}|{}|{}".format(backend, target, text)] = translated
        self.dirty = True
        self.save()

    def save(self):
        if not self.dirty:
            return
        self.path.parent.mkdir(parents=True, exist_ok=True)
        temporary = self.path.with_suffix(".tmp")
        with temporary.open("w", encoding="utf-8") as handle:
            json.dump(self.data, handle, ensure_ascii=False, indent=1)
        temporary.replace(self.path)
        self.dirty = False


def protect_brands(text: str):
    placeholders = {}
    protected = text
    for index, brand in enumerate(BRAND_TOKENS):
        if brand in protected:
            marker = "[[KPUI_BRAND_{}]]".format(index)
            placeholders[marker] = brand
            protected = protected.replace(brand, marker)
    return protected, placeholders


def protect_plain_tokens(text: str):
    placeholders = {}
    protected = text
    index = 0
    while True:
        match = PLAIN_TOKEN.search(protected)
        if not match:
            break
        marker = "[[KPUI_T{}]]".format(index)
        placeholders[marker] = match.group(0)
        protected = protected[: match.start()] + marker + protected[match.end():]
        index += 1
    return protected, placeholders


def restore_placeholders(text: str, placeholders) -> str:
    for marker, value in placeholders.items():
        text = text.replace(marker, value)
    return text


def translate_text(backend, cache, target, text, force):
    if not re.search(r"[A-Za-z]", text):
        return text, "unchanged"

    protected, placeholders = protect_brands(text)
    protected, token_placeholders = protect_plain_tokens(protected)
    placeholders.update(token_placeholders)
    cached = None if force else cache.get(backend.name, target, protected)
    if cached is not None:
        return restore_placeholders(cached, placeholders), "cache"

    last_error = None
    for attempt in range(2):
        try:
            translated_raw = backend.translate(protected, target)
        except RuntimeError as exc:
            last_error = exc
            continue

        missing = [marker for marker in placeholders if marker not in translated_raw]
        if missing:
            last_error = RuntimeError(
                "placeholder lost: {}".format(", ".join(missing))
            )
            continue

        translated = restore_placeholders(translated_raw, placeholders)
        if token_signature(translated) != token_signature(text):
            last_error = RuntimeError("placeholder structure changed")
            continue

        cache.put(backend.name, target, protected, translated_raw)
        return translated, "translated"

    print("  ! falling back to English for {!r}: {}".format(text[:50], last_error))
    return text, "fallback"


def build_translations(entries, targets, official, backend, cache, force):
    unique = []
    seen = set()
    for entry in entries:
        if entry["text"] not in seen:
            seen.add(entry["text"])
            unique.append(entry["text"])

    results = {target: {} for target in targets}
    stats = {target: {"official": 0, "cache": 0, "translated": 0, "fallback": 0}
             for target in targets}

    for index, text in enumerate(unique, start=1):
        if text in official:
            for target in targets:
                results[target][text] = official[text][target]
                stats[target]["official"] += 1
            continue

        for target in targets:
            translated, kind = translate_text(backend, cache, target, text, force)
            results[target][text] = translated
            if kind == "cache":
                stats[target]["cache"] += 1
            elif kind == "fallback":
                stats[target]["fallback"] += 1
            elif kind == "translated":
                stats[target]["translated"] += 1
        if index % 25 == 0:
            print("  {}/{}".format(index, len(unique)))
    return results, stats


# --------------------------------------------------------------------------
# Validation
# --------------------------------------------------------------------------

def validate_locale(path: Path, source_entries, target):
    lines, newline = read_lines(path)
    parsed = []
    for line_number, line in enumerate(lines, start=1):
        if "Add(KELA_" not in line:
            continue
        match = SAFE_ADD_LINE.match(line)
        if not match:
            return ["{}:{}: unparsable localized line".format(path.name, line_number)]
        parsed.append((match.group("id"), unescape_lua(match.group("text"))))

    errors = []
    source_ids = [entry["id"] for entry in source_entries]
    if [entry_id for entry_id, _ in parsed] != source_ids:
        errors.append("{}: ID list/order differs from en.lua".format(path.name))

    source_by_id = {entry["id"]: entry["text"] for entry in source_entries}
    for entry_id, translated in parsed:
        source = source_by_id.get(entry_id)
        if source is None:
            errors.append("{}: unknown ID {}".format(path.name, entry_id))
            continue
        if token_signature(translated) != token_signature(source):
            errors.append(
                "{}: placeholder mismatch in {}".format(path.name, entry_id)
            )
        for brand in BRAND_TOKENS:
            if translated.count(brand) != source.count(brand):
                errors.append(
                    "{}: brand token changed in {}".format(path.name, entry_id)
                )
        for code in ("|c", "|r"):
            if translated.count(code) != source.count(code):
                errors.append(
                    "{}: color code changed in {}".format(path.name, entry_id)
                )
        if "[[KPUI_BRAND_" in translated or "[[KPUI_T" in translated:
            errors.append("{}: leftover placeholder in {}".format(path.name, entry_id))
    if newline != "\r\n":
        errors.append("{}: expected CRLF line endings".format(path.name))
    return errors


def parse_locale_entries(path: Path):
    lines, _ = read_lines(path)
    entries = []
    for line in lines:
        match = SAFE_ADD_LINE.match(line)
        if match:
            entries.append((match.group("id"), unescape_lua(match.group("text"))))
    return entries


# --------------------------------------------------------------------------
# CLI
# --------------------------------------------------------------------------

def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("language", nargs="*", help="target language code(s)")
    parser.add_argument("--all", action="store_true", help="generate de, fr and ru")
    parser.add_argument("--offline", action="store_true",
                        help="use argostranslate instead of the Google endpoint")
    parser.add_argument("--force", action="store_true", help="ignore the cache")
    parser.add_argument("--dry-run", action="store_true", help="parse and report only")
    parser.add_argument("--check", action="store_true",
                        help="validate existing locale files and exit")
    parser.add_argument("--client-lang-dir", type=Path,
                        default=DEFAULT_CLIENT_LANG_DIR,
                        help="path to the ESO esoui/lang folder")
    parser.add_argument("--cache", type=Path, default=DEFAULT_CACHE,
                        help="translation cache path")
    args = parser.parse_args()

    targets = list(args.language)
    if args.all:
        targets.extend(CAMPAIGN)
    targets = list(dict.fromkeys(targets))
    if not targets:
        parser.error("pass at least one language, or --all")

    for target in targets:
        if target == "en":
            parser.error("refusing to overwrite the English source")
        if not re.fullmatch(r"[a-z]{2}", target):
            parser.error("unsupported language code: {}".format(target))

    source_lines, newline, entries = parse_source(EN_PATH)
    print("Source: {} entries, {} unique strings, {} line ending".format(
        len(entries), len({entry["text"] for entry in entries}),
        "CRLF" if newline == "\r\n" else "LF",
    ))

    if args.check:
        errors = []
        for target in targets:
            path = LANG_DIR / "{}.lua".format(target)
            if not path.exists():
                errors.append("{}: missing".format(path.name))
            else:
                errors.extend(validate_locale(path, entries, target))
        for error in errors:
            print("ERROR:", error)
        print("CHECK FAILED" if errors else "CHECK PASSED")
        return 1 if errors else 0

    official = build_official_map(args.client_lang_dir, targets)
    official = {
        text: values
        for text, values in official.items()
        if all(
            token_signature(value) == token_signature(text)
            for value in values.values()
        )
    }
    official_hits = sum(
        1 for entry in entries if entry["text"] in official
    )
    print("Official ESO matches: {} unique strings".format(
        len({entry["text"] for entry in entries if entry["text"] in official})
    ))

    if args.dry_run:
        print("Dry run: would write {} file(s): {}".format(
            len(targets), ", ".join(targets)
        ))
        print("Official entries:", official_hits)
        return 0

    cache = Cache(args.cache)
    if args.offline:
        try:
            backend = ArgosBackend(targets)
        except subprocess.CalledProcessError as exc:
            print("Could not install/import argostranslate: {}".format(exc))
            print("Use the default Google backend, or install argostranslate on "
                  "a Python version with CTranslate2 wheels (3.9-3.13).")
            return 1
    else:
        backend = GoogleBackend(delay=0.1)

    translations, stats = build_translations(
        entries, targets, official, backend, cache, args.force
    )

    for target in targets:
        path = LANG_DIR / "{}.lua".format(target)
        content = render_locale(
            source_lines, newline, entries,
            {entry["id"]: translations[target][entry["text"]] for entry in entries},
            target,
        )
        write_locale(path, content)
        errors = validate_locale(path, entries, target)
        for error in errors:
            print("ERROR:", error)
        print("Wrote {} ({})".format(
            path.relative_to(ROOT),
            ", ".join("{} {}".format(key, value)
                      for key, value in stats[target].items()),
        ))
        if errors:
            return 1

    print("Done. Run python _tools/audit_addon.py to validate the add-on.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
