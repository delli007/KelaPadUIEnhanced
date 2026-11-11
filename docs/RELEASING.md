# Releasing

Two things get published per release: the add-on zip and, optionally, an update
to the ESOUI listing. Both are automated from a version tag.

## Version rules

- `## Version` in `KelaPadUIEnhanced.txt` is `major.minor.patch`.
- `## AddOnVersion` is `major*10000 + minor*100 + patch`.
- The newest `changelog.txt` entry must use the same version.
- The release tag is `v<version>`, for example `v2.8.0`. The release workflow
  fails when the tag and the manifest disagree.

The audit (`python _tools\audit_addon.py`) checks the first three; the workflow
checks the tag.

## Building the zip

```powershell
python _tools\package_addon.py
```

This writes `dist\KelaPadUIEnhanced-<version>.zip` containing a single top-level
`KelaPadUIEnhanced/` folder with the manifest and every file it lists. The
archive is deterministic: sorted entries and fixed timestamps, so the same tree
always produces the same bytes.

Useful flags:

| Flag | Effect |
| --- | --- |
| `--check` | Build into a temporary file, verify it, and discard it. |
| `--notes <path>` | Also write the current changelog section to `<path>`. |
| `--out <dir>` | Write the zip somewhere other than `dist\`. |

The script verifies its own output and fails when:

- the manifest is not at the archive root of the add-on folder;
- a manifest-listed file is missing;
- a development path (`_tools`, `docs`, `.git`, `.github`, `dist`,
  `__pycache__`) or file (`*.py`, `AGENTS.md`, `TODO.md`, `.gitignore` or a
  build artifact) leaked into the archive.

Everything else in the tree ships, so new textures and data files need no
change to the script. `changelog.txt` and `README.md` ship as well; ESO ignores
files the manifest does not list.

## ESOUI listing

ESOUI numbers add-ons and only accepts API updates to an add-on that already
exists. The first upload has to be done by hand:

1. Upload `dist\KelaPadUIEnhanced-<version>.zip` once through
   <https://www.esoui.com/downloads/upload-update.php>.
2. Open <https://www.esoui.com/downloads/filecpl.php?action=apitokens> and
   generate an API token.
3. Note the numeric add-on ID from the page URL (`.../info<ID>-...`).

ESOUI accepts zip archives only; the script already produces one.

### API request

```text
POST https://api.esoui.com/addons/update
x-api-token: <token>

id=<add-on id>
version=<manifest version>
compatible=<manifest APIVersion>
changelog=<release notes text>
updatefile=<the zip>
```

`https://api.esoui.com/addons/updatetest` is the equivalent test endpoint.

## GitHub Actions

Two workflows live in `.github/workflows/`:

| Workflow | Trigger | Does |
| --- | --- | --- |
| `ci.yml` | push and pull request | Audit, package, upload the zip as an artifact. |
| `release.yml` | tag `v*`, or manual run | Audit, package, GitHub release, optional ESOUI upload. |

Set these once in the repository:

- **Secret** `ESOUI_API_KEY` - the token from the ESOUI API token page.
- **Variable** `ESOUI_ADDON_ID` - the numeric ESOUI add-on ID.

With both present, pushing a `v<version>` tag builds the zip, creates the GitHub
release with the changelog section as its body, and uploads the same zip to
ESOUI. Without them the ESOUI step is skipped with a notice and the GitHub
release still happens.

To re-upload without a new tag, run `release.yml` manually with the `deploy`
input enabled. ESOUI rejects a duplicate version, so bump the version first.

The token is only read from the secret. Never commit it, paste it into an
issue, or add it to a workflow file.
