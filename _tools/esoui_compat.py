#!/usr/bin/env python3
"""Resolve the ESOUI ``compatible`` value for a manifest APIVersion.

ESOUI's update API wants the game version (``12.1.0``), not the add-on API
version (``101051``). The add-on manifest only carries ``## APIVersion``, so this
table maps one to the other. The release workflow calls this before publishing
and refuses to continue when the pair is missing, which keeps a new game update
from silently shipping an empty compatibility field.

Usage:
    python _tools/esoui_compat.py 101051
    python _tools/esoui_compat.py 101051 --verify
    python _tools/esoui_compat.py --list

``--verify`` checks the value against https://api.esoui.com/addons/compatible.json
using ``ESOUI_API_KEY``. A version missing from that list is a hard error; a
network failure is only a warning, because the upload itself will surface it.

The list of game versions is on the manual upload page at
https://www.esoui.com/downloads/upload-update.php (Compatibility selector).
This is maintenance tooling only; ESO does not load it.
"""

import argparse
import json
import os
import sys
import urllib.error
import urllib.request

COMPATIBLE_URL = "https://api.esoui.com/addons/compatible.json"
USER_AGENT = (
    "KelaPadUIEnhanced-release/1.0 "
    "(+https://github.com/delli007/KelaPadUIEnhanced)"
)

# APIVersion -> ESOUI game version. Add the new pair when bumping
# ## APIVersion, using the compatibility selector on the ESOUI upload page.
# Only versions that have shipped on live are listed on purpose: adding the
# next one early would claim compatibility with a build the add-on has not run
# against.
COMPATIBLE_VERSIONS = {
    "101037": "8.3.5",  # Scribes of Fate
    "101038": "9.0.0",  # Necrom
    "101039": "9.1.5",  # base-game patch
    "101040": "9.2.5",  # Endless Archive
    "101041": "9.3.0",  # Scions of Ithelia
    "101042": "10.0.0",  # Gold Road
    "101043": "10.1.0",  # Update 43
    "101044": "10.2.0",  # Update 44
    "101045": "10.3.5",  # Fallen Banners
    "101046": "11.0.0",  # Seasons of the Worm Cult Pt1
    "101047": "11.1.0",  # Feast of Shadows
    "101048": "11.2.0",  # Seasons of the Worm Cult Pt2
    "101049": "11.3.0",  # Season Zero
    "101050": "12.0.0",  # Season Zero Pt.2
    "101051": "12.1.0",  # Season One
}


def lookup(api_version):
    value = COMPATIBLE_VERSIONS.get(str(api_version).strip())
    if value:
        return value
    newest = max(COMPATIBLE_VERSIONS)
    raise SystemExit(
        "No ESOUI compatibility mapping for API {}. Add it to "
        "COMPATIBLE_VERSIONS in _tools/esoui_compat.py, using the current live "
        "version from https://www.esoui.com/downloads/upload-update.php "
        "(newest mapped API: {}).".format(api_version, newest)
    )


def available_versions(token):
    request = urllib.request.Request(
        COMPATIBLE_URL,
        headers={"x-api-token": token, "User-Agent": USER_AGENT},
    )
    with urllib.request.urlopen(request, timeout=30) as response:
        payload = json.loads(response.read().decode("utf-8"))
    entries = payload if isinstance(payload, list) else payload.get("compatible", [])
    versions = []
    for entry in entries:
        if isinstance(entry, dict):
            value = entry.get("id") or entry.get("version") or entry.get("value")
        else:
            value = entry
        if value:
            versions.append(str(value))
    return versions


def verify(value):
    token = os.environ.get("ESOUI_API_KEY", "").strip()
    if not token:
        print(
            "NOTICE: ESOUI_API_KEY is not set; skipping the compatibility check.",
            file=sys.stderr,
        )
        return
    try:
        versions = available_versions(token)
    except (urllib.error.URLError, OSError, ValueError) as error:
        print(
            "WARNING: cannot read {} ({}); keeping {}.".format(
                COMPATIBLE_URL, error, value
            ),
            file=sys.stderr,
        )
        return
    if value not in versions:
        raise SystemExit(
            "ESOUI does not list {} as a compatible version. Available: {}. "
            "Check the compatibility selector and update "
            "_tools/esoui_compat.py.".format(value, ", ".join(versions))
        )
    print("ESOUI lists {} as a compatible version.".format(value), file=sys.stderr)


def main(argv=None):
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("api_version", nargs="?", help="manifest APIVersion")
    parser.add_argument(
        "--verify",
        action="store_true",
        help="check the value against the ESOUI compatible version list",
    )
    parser.add_argument(
        "--list", action="store_true", help="print the whole mapping"
    )
    args = parser.parse_args(argv)

    if args.list:
        for api in sorted(COMPATIBLE_VERSIONS):
            print("{} -> {}".format(api, COMPATIBLE_VERSIONS[api]))
        return 0
    if not args.api_version:
        parser.error("api_version is required unless --list is used")

    value = lookup(args.api_version)
    if args.verify:
        verify(value)
    print(value)
    return 0


if __name__ == "__main__":
    sys.exit(main())
