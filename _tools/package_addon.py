#!/usr/bin/env python3
"""Build the ESOUI-ready add-on zip.

ESOUI expects the archive to contain a single top-level folder named after the
add-on, holding the manifest and the files it lists. This script produces
`dist/<ADDON_NAME>-<version>.zip` from the working tree, verifies the result,
and can also emit the release notes for the current version.

The output is deterministic: entries are sorted and stamped with a fixed
timestamp, so the same tree always produces the same bytes.

Usage:
    python _tools/package_addon.py
    python _tools/package_addon.py --out dist --notes dist/notes.md
    python _tools/package_addon.py --check
This is a build helper only; ESO does not load it.
"""

import argparse
import re
import sys
import tempfile
import zipfile
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
ADDON_NAME = "KelaPadUIEnhanced"
MANIFEST = ROOT / (ADDON_NAME + ".txt")
CHANGELOG = ROOT / "changelog.txt"

# Never shipped. Everything else in the tree is included, so new textures or
# data files are picked up without editing this list.
EXCLUDE_DIRS = {".git", ".github", "_tools", "docs", "dist", "__pycache__"}
EXCLUDE_SUFFIXES = {".py", ".pyc", ".pyo", ".bak", ".tmp", ".log", ".zip", ".bbcode"}
EXCLUDE_FILES = {"AGENTS.md", "TODO.md", ".gitignore"}

ZIP_DATE = (1980, 1, 1, 0, 0, 0)
ZIP_MODE = 0o644 << 16


def read_text(path):
    return path.read_text(encoding="utf-8", errors="replace")


def manifest_metadata():
    metadata = {}
    for line in read_text(MANIFEST).splitlines():
        stripped = line.strip()
        if not stripped.startswith("##") or ":" not in stripped:
            continue
        key, value = stripped[2:].split(":", 1)
        metadata[key.strip()] = value.strip()
    return metadata


def manifest_entries():
    """Return manifest file entries, with $(language) expanded."""
    entries = []
    for line in read_text(MANIFEST).splitlines():
        stripped = line.strip()
        if not stripped or stripped.startswith(("#", ";")):
            continue
        if "$(language)" in stripped:
            entries.extend(
                path.relative_to(ROOT).as_posix()
                for path in sorted((ROOT / "kpui_lang").glob("*.lua"))
            )
            continue
        entries.append(stripped.replace("\\", "/"))
    return entries


def collect_files():
    files = []
    for path in sorted(ROOT.rglob("*")):
        if not path.is_file():
            continue
        relative = path.relative_to(ROOT)
        if any(part in EXCLUDE_DIRS for part in relative.parts[:-1]):
            continue
        if path.name in EXCLUDE_FILES:
            continue
        if path.suffix.lower() in EXCLUDE_SUFFIXES:
            continue
        files.append(relative.as_posix())
    return files


def version():
    metadata = manifest_metadata()
    match = re.fullmatch(r"(\d+\.\d+\.\d+)", metadata.get("Version", ""))
    if not match:
        raise SystemExit(
            "manifest ## Version is not major.minor.patch: {!r}".format(
                metadata.get("Version")
            )
        )
    return match.group(1)


def changelog_section(ver):
    """Return the changelog body for one version, without the version line."""
    lines = read_text(CHANGELOG).splitlines()
    body = []
    collecting = False
    for line in lines:
        if re.match(r"^{}\b".format(re.escape(ver)), line.strip()):
            collecting = True
            continue
        if collecting:
            if re.match(r"^\d+\.\d+\.\d+\b", line.strip()):
                break
            body.append(line)
    while body and not body[-1].strip():
        body.pop()
    return "\n".join(body).strip()


def build_zip(destination, files):
    ver = version()
    with zipfile.ZipFile(destination, "w", zipfile.ZIP_DEFLATED) as archive:
        for relative in files:
            info = zipfile.ZipInfo("{}/{}".format(ADDON_NAME, relative), date_time=ZIP_DATE)
            info.compress_type = zipfile.ZIP_DEFLATED
            info.external_attr = ZIP_MODE
            archive.writestr(info, (ROOT / relative).read_bytes())
    return ver


def verify_zip(path, files):
    """Fail loudly if the archive is not what ESOUI and ESO expect."""
    errors = []
    listed = set(files)
    with zipfile.ZipFile(path) as archive:
        names = archive.namelist()
        for name in names:
            if not name.startswith(ADDON_NAME + "/"):
                errors.append("archive entry outside {}: {}".format(ADDON_NAME, name))
                continue
            relative = name[len(ADDON_NAME) + 1:]
            if any(part in EXCLUDE_DIRS for part in relative.split("/")[:-1]):
                errors.append("development path in archive: {}".format(relative))
            if relative in EXCLUDE_FILES or Path(relative).suffix.lower() in EXCLUDE_SUFFIXES:
                errors.append("development file in archive: {}".format(relative))

        manifest_name = "{}/{}".format(ADDON_NAME, MANIFEST.name)
        if manifest_name not in names:
            errors.append("archive is missing the manifest at {}".format(manifest_name))

        for entry in manifest_entries():
            if entry not in listed:
                errors.append("manifest entry missing from archive: {}".format(entry))

        if len(names) != len(listed):
            errors.append(
                "archive entry count {} does not match {} source file(s)".format(
                    len(names), len(listed)
                )
            )
    return errors


def main():
    sys.stdout.reconfigure(encoding="utf-8", errors="replace")
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--out", type=Path, default=ROOT / "dist",
                        help="output directory (default: dist/)")
    parser.add_argument("--notes", type=Path,
                        help="write the current version's changelog section here")
    parser.add_argument("--check", action="store_true",
                        help="build into a temporary file, verify, and discard")
    args = parser.parse_args()

    if not MANIFEST.exists():
        raise SystemExit("manifest not found: {}".format(MANIFEST))
    ver = version()
    files = collect_files()
    if MANIFEST.name not in files:
        raise SystemExit("manifest is excluded from the archive: {}".format(MANIFEST.name))

    if args.check:
        with tempfile.TemporaryDirectory() as folder:
            target = Path(folder) / "check.zip"
            build_zip(target, files)
            errors = verify_zip(target, files)
            size = target.stat().st_size
    else:
        args.out.mkdir(parents=True, exist_ok=True)
        target = args.out / "{}-{}.zip".format(ADDON_NAME, ver)
        build_zip(target, files)
        errors = verify_zip(target, files)
        size = target.stat().st_size

    if errors:
        print("PACKAGE FAILED ({} issue(s))".format(len(errors)))
        for error in errors:
            print(" -", error)
        return 1

    print("Add-on: {} {}".format(ADDON_NAME, ver))
    print("Files: {}".format(len(files)))
    print("Zip size: {} bytes".format(size))
    if not args.check:
        print("Archive: {}".format(target))

    if args.notes:
        body = changelog_section(ver)
        if not body:
            print("WARNING: no changelog section for {}".format(ver))
        args.notes.parent.mkdir(parents=True, exist_ok=True)
        args.notes.write_text(body + "\n", encoding="utf-8", newline="\n")
        print("Release notes: {}".format(args.notes))

    return 0


if __name__ == "__main__":
    sys.exit(main())
