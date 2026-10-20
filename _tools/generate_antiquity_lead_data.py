#!/usr/bin/env python3
"""Regenerate the UESP-derived antiquity lead table in KelaPadUI.

Fetches the UESP "Antiquities by Zone" pages, reads every {{ESO Antiquity}}
template, extracts the numeric ESO antiquity id and the ``lead=`` text, cleans
the wiki markup, and rewrites the block between the two markers in
kpui_features/antiquities/kpui_antiquityleads_gamepad.lua.

The generated data is derived from the UESP Wiki and remains under CC BY-SA 2.5:
https://en.uesp.net/wiki/UESPWiki:Copyright

This is a build helper only. ESO does not load or execute this file.
"""

import html
import json
import re
import sys
import time
import urllib.error
import urllib.parse
import urllib.request
from concurrent.futures import ThreadPoolExecutor, as_completed
from datetime import date
from pathlib import Path

API = "https://en.uesp.net/w/api.php"
INDEX_PAGE = "Online:Antiquities by Zone"
USER_AGENT = "KelaPadUI-antiquity-lead-data/1.0 (addon build helper)"
FETCH_WORKERS = 5
TARGET_FILE = Path(__file__).resolve().parent.parent / "kpui_features" / "antiquities" / "kpui_antiquityleads_gamepad.lua"
BEGIN_MARKER = "-- BEGIN KELA GENERATED ANTIQUITY LEAD DATA"
END_MARKER = "-- END KELA GENERATED ANTIQUITY LEAD DATA"

SAMPLE_IDS = (183, 184, 342, 112, 310)


def fetch_wikitext(page_title):
    params = {
        "action": "parse",
        "page": page_title,
        "prop": "wikitext",
        "format": "json",
        "formatversion": "2",
    }
    url = API + "?" + urllib.parse.urlencode(params)
    request = urllib.request.Request(url, headers={"User-Agent": USER_AGENT})
    last_error = None
    for attempt in range(3):
        try:
            with urllib.request.urlopen(request, timeout=45) as response:
                return json.load(response)["parse"]["wikitext"]
        except Exception as exc:  # noqa: BLE001 - report the final failure below
            last_error = exc
            time.sleep(1.5 * (attempt + 1))
    raise RuntimeError("Unable to fetch {}: {}".format(page_title, last_error))


def iter_eso_antiquity_templates(wikitext):
    marker = "{{ESO Antiquity"
    position = 0
    while True:
        start = wikitext.find(marker, position)
        if start < 0:
            return
        depth = 0
        index = start
        while index < len(wikitext):
            if wikitext.startswith("{{", index):
                depth += 1
                index += 2
                continue
            if wikitext.startswith("}}", index):
                depth -= 1
                index += 2
                if depth == 0:
                    break
                continue
            index += 1
        yield wikitext[start:index]
        position = index


def split_top_level_parameters(template_text):
    inner = template_text[2:-2]
    parts = []
    buffer = []
    brace_depth = 0
    link_depth = 0
    index = 0
    while index < len(inner):
        if inner.startswith("{{", index):
            brace_depth += 1
            buffer.append("{{")
            index += 2
        elif inner.startswith("}}", index):
            brace_depth -= 1
            buffer.append("}}")
            index += 2
        elif inner.startswith("[[", index):
            link_depth += 1
            buffer.append("[[")
            index += 2
        elif inner.startswith("]]", index):
            link_depth -= 1
            buffer.append("]]")
            index += 2
        elif inner[index] == "|" and brace_depth == 0 and link_depth == 0:
            parts.append("".join(buffer))
            buffer = []
            index += 1
        else:
            buffer.append(inner[index])
            index += 1
    parts.append("".join(buffer))
    return parts


def parse_template_fields(template_text):
    parts = split_top_level_parameters(template_text)
    fields = {}
    for part in parts[1:]:
        if "=" not in part:
            continue
        key, value = part.split("=", 1)
        fields[key.strip()] = value
    return fields


COMMENT_RE = re.compile(r"<!--.*?-->", re.S)
TEMPLATE_RE = re.compile(r"\{\{([^{}]*)\}\}")
LINK_RE = re.compile(r"\[\[([^\]]+)\]\]")
EXTERNAL_LINK_RE = re.compile(r"\[https?://[^\s\]]+\s+([^\]]+)\]")
HTML_TAG_RE = re.compile(r"<[^>]+>")


def split_template_parts(content):
    parts = []
    buffer = []
    link_depth = 0
    index = 0
    while index < len(content):
        if content.startswith("[[", index):
            link_depth += 1
            buffer.append("[[")
            index += 2
        elif content.startswith("]]", index):
            link_depth -= 1
            buffer.append("]]")
            index += 2
        elif content[index] == "|" and link_depth == 0:
            parts.append("".join(buffer))
            buffer = []
            index += 1
        else:
            buffer.append(content[index])
            index += 1
    parts.append("".join(buffer))
    return parts


def clean_template_content(content):
    parts = split_template_parts(content)
    if not parts:
        return ""

    template_name = parts[0].strip()
    positional = []
    for part in parts[1:]:
        if "=" in part and not part.lstrip().startswith("[["):
            continue
        positional.append(part)

    if template_name == "Item Link":
        return positional[0].strip() if positional else ""
    if template_name == "ESO Quality Color":
        return positional[-1].strip() if positional else ""
    if template_name == "ESO Price":
        value = positional[0].strip() if positional else ""
        return value + " gold" if value else ""
    if template_name in ("Year", "sic", "Nowrap", "Huh", "Lore Link", "ON"):
        return positional[-1].strip() if positional else ""
    if template_name in ("Lang", "Le"):
        return positional[-1].strip() if positional else ""
    if template_name.startswith("#"):
        return positional[-1].strip() if positional else ""

    return " ".join(part.strip() for part in positional if part.strip())


def clean_wikitext(value):
    if not value:
        return ""

    text = COMMENT_RE.sub("", value)
    text = re.sub(r"</?br\s*/?>", "\n", text, flags=re.I)

    for _ in range(20):
        text, replacements = TEMPLATE_RE.subn(
            lambda match: clean_template_content(match.group(1)), text
        )
        if replacements == 0:
            break

    def replace_link(match):
        inner = match.group(1)
        return inner.split("|")[-1]

    text = LINK_RE.sub(replace_link, text)
    text = EXTERNAL_LINK_RE.sub(r"\1", text)
    text = HTML_TAG_RE.sub("", text)
    text = text.replace("'''", "").replace("''", "")
    text = html.unescape(text)

    lines = []
    for raw_line in text.replace("\r\n", "\n").replace("\r", "\n").split("\n"):
        line = raw_line.strip()
        line = re.sub(r"^[*#:;]+\s*", "", line)
        line = re.sub(r"[ \t]+", " ", line)
        if line:
            lines.append(line)

    return "\n".join(lines).strip()


def get_zone_pages(index_wikitext):
    text = COMMENT_RE.sub("", index_wikitext)
    titles = re.findall(r"\[\[(?:ON|Online):([^|\]]+Antiquities)\|", text)
    pages = []
    seen = set()
    for title in titles:
        if title in seen:
            continue
        seen.add(title)
        pages.append("Online:" + title)
    return pages


def escape_lua_string(value):
    value = value.replace("\\", "\\\\")
    value = value.replace('"', '\\"')
    value = value.replace("\r\n", "\n").replace("\r", "\n")

    result = []
    for char in value:
        code = ord(char)
        if char == "\n":
            result.append("\\n")
        elif char == "\t":
            result.append("\\t")
        elif code < 32:
            result.append("\\{:03d}".format(code))
        else:
            result.append(char)
    return "".join(result)


def update_target_file(lead_sources, overrides):
    generated_lines = [
        "-- Generated from UESP by _tools/generate_antiquity_lead_data.py.",
        "-- Generated: " + date.today().isoformat(),
        "KELA_ANTIQUITY_LEAD_SOURCES =",
        "{",
    ]
    for antiquity_id in sorted(lead_sources):
        generated_lines.append(
            '    [{}] = "{}",'.format(
                antiquity_id, escape_lua_string(lead_sources[antiquity_id])
            )
        )
    generated_lines.append("}")

    if overrides:
        generated_lines.extend(
            [
                "",
                "KELA_ANTIQUITY_LEAD_SOURCE_OVERRIDES =",
                "{",
            ]
        )
        for antiquity_id in sorted(overrides):
            generated_lines.append("    [{}] =".format(antiquity_id))
            generated_lines.append("    {")
            for name in sorted(overrides[antiquity_id]):
                generated_lines.append(
                    '        ["{}"] = "{}",'.format(
                        escape_lua_string(name),
                        escape_lua_string(overrides[antiquity_id][name]),
                    )
                )
            generated_lines.append("    },")
        generated_lines.append("}")

    generated_block = "\n".join(generated_lines)

    content = TARGET_FILE.read_text(encoding="utf-8")
    begin = content.find(BEGIN_MARKER)
    end = content.find(END_MARKER)
    if begin < 0 or end < 0 or end < begin:
        raise RuntimeError("Generated-data markers not found in {}".format(TARGET_FILE))

    new_content = (
        content[: begin + len(BEGIN_MARKER)]
        + "\n"
        + generated_block
        + "\n"
        + content[end:]
    )
    TARGET_FILE.write_text(new_content, encoding="utf-8", newline="\n")


def main():
    sys.stdout.reconfigure(encoding="utf-8", errors="replace")

    index_wikitext = fetch_wikitext(INDEX_PAGE)
    pages = get_zone_pages(index_wikitext)
    if not pages:
        raise RuntimeError("No zone pages found on the index page")

    entries_by_id = {}
    missing = []
    template_count = 0

    with ThreadPoolExecutor(max_workers=FETCH_WORKERS) as executor:
        future_to_page = {executor.submit(fetch_wikitext, page): page for page in pages}
        for future in as_completed(future_to_page):
            page = future_to_page[future]
            try:
                wikitext = future.result()
            except Exception as exc:  # noqa: BLE001 - continue with the remaining pages
                print("WARN could not fetch {}: {}".format(page, exc))
                continue

            wikitext = COMMENT_RE.sub("", wikitext)
            for template in iter_eso_antiquity_templates(wikitext):
                template_count += 1
                fields = parse_template_fields(template)
                name = clean_wikitext(fields.get("name", ""))
                id_text = fields.get("id", "").strip()

                if not re.fullmatch(r"\d+", id_text):
                    missing.append((name or "?", id_text or "?", "missing/invalid id"))
                    continue

                antiquity_id = int(id_text)
                lead = clean_wikitext(fields.get("lead", ""))
                if not lead or lead.lower() in ("n/a", "none", "-"):
                    missing.append((antiquity_id, name or "?", "empty lead"))
                    continue

                entries_by_id.setdefault(antiquity_id, []).append((name or "", lead))

    lead_sources = {}
    overrides = {}
    ambiguous = []
    for antiquity_id, entries in entries_by_id.items():
        by_name = {}
        for name, lead in entries:
            if name not in by_name or len(lead) > len(by_name[name]):
                by_name[name] = lead
        if len(by_name) == 1:
            lead_sources[antiquity_id] = next(iter(by_name.values()))
        else:
            overrides[antiquity_id] = by_name
            ambiguous.append((antiquity_id, sorted(by_name)))

    if not lead_sources and not overrides:
        raise RuntimeError("No lead source data was generated")

    update_target_file(lead_sources, overrides)

    print("Pages:", len(pages))
    print("Templates:", template_count)
    print("Single-source antiquity IDs:", len(lead_sources))
    print("Ambiguous IDs (resolved by in-game name):", len(overrides))
    for item in ambiguous:
        print("  AMBIGUOUS", item)
    print("Total antiquity IDs:", len(lead_sources) + len(overrides))
    print("Missing sources:", len(missing))
    for item in missing[:25]:
        print("  MISSING", item)
    print("Samples:")
    for sample_id in SAMPLE_IDS:
        if sample_id in lead_sources:
            sample = lead_sources[sample_id].replace("\n", " | ")
            print("  {}: {}".format(sample_id, sample[:180]))
    print("Wrote:", TARGET_FILE)
    print("Data entries:", len(lead_sources) + len(overrides))
    print("File size:", TARGET_FILE.stat().st_size, "bytes")


if __name__ == "__main__":
    main()


