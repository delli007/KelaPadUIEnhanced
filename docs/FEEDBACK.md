# Feedback pipeline

KelaPadUI Enhanced takes bug reports and feature requests in two places: GitHub
issues and the comment section of the ESOUI listing. `_tools/esoui_comments.py`
mirrors the ESOUI comments into GitHub so one tracker holds everything, and
`.github/workflows/esoui-comments.yml` runs it once a day.

The add-on itself never talks to GitHub. This is release and maintenance
tooling, so it is excluded from the packaged zip.

## Routing

A new ESOUI comment is routed by what it contains:

| Comment | Result |
| --- | --- |
| `#bug` | A new issue with the `esoui` and `bug` labels |
| `#enhancement` | A new issue with the `esoui` and `enhancement` labels |
| `#request` | A new issue with the `esoui` and `request` labels |
| `#issue` | A new issue with the `esoui` and `issue` labels |
| Quotes a comment already tracked in an issue | A comment on that issue |
| Contains `#<number>`, for example `#12` | A comment on issue 12 |
| Anything else | A comment on the "ESOUI comments feed" issue |

A tag wins over a quote, so a tagged reply starts a new issue. A quote wins over
the feed, so a follow-up stays next to the report it belongs to.

Tags are matched case-insensitively and anywhere in the comment, so "this is a
#bug, the bank row is wrong" works.

### Reply matching

ESOUI renders a quote as `Originally Posted by <author>` plus the quoted text.
The parent comment id is not in the HTML, so a reply is matched heuristically:
the quoted author must equal the tracked issue author and the first 160
characters of the quoted text must appear in the issue body. The comparison is
case-insensitive and ignores whitespace and URLs. Quotes shorter than 20
characters are ignored because they match too much.

When the match fails, the reply lands in the feed issue. That is intentional:
a duplicate reply is cheaper than a missed one. `#<number>` in the comment is
the reliable way for a user to point at an issue, and it is checked first.

## Feed issue

The feed issue is titled `ESOUI comments feed`, carries the `esoui-feed` label,
and stays open. It collects untagged comments so they do not become issues of
their own.

Its body holds two things: an explanation and a cursor marker:

```text
<!-- esoui-last-seen:200213 -->
```

`esoui-last-seen` is the newest comment id that was processed. The next run
only looks at ids above it. On the very first run the cursor is set to the
newest existing comment, so the pipeline starts clean instead of importing the
whole history.

Delete the marker to re-read the newest page; delete the issue to start from
scratch.

## Duplicate protection

Every issue body and every feed comment ends with a hidden marker:

```text
<!-- esoui-comment:<id> -->
```

A run skips ids that already have a marker, so a failed or re-run job does not
double-file a comment. Issues also carry:

```text
<!-- esoui-author:<name> -->
```

That marker feeds the quote matcher, because the formatted issue body is not a
byte-for-byte copy of the comment.

## Running it

The script needs the `gh` CLI, authenticated with a token that can read and
write issues, plus the network:

```powershell
# Show what would happen without writing anything
python _tools\esoui_comments.py --check

# Process new comments
python _tools\esoui_comments.py

# Read a saved ESOUI page instead of fetching it
python _tools\esoui_comments.py --from-file page.html --check

# Another add-on, for parser testing
python _tools\esoui_comments.py --addon-id 1245 --pages 1 --check
```

Options:

- `--addon-id` defaults to `ESOUI_ADDON_ID` or `5044`.
- `--repo` and `--owner` default to `GITHUB_REPOSITORY` and
  `GITHUB_REPOSITORY_OWNER`, then to `delli007/KelaPadUIEnhanced`.
- `--pages` caps how many comment pages are read (15 comments per page).
- `--max-new` caps how many comments one run files; the rest follow next run.
- `--check` writes nothing and does not move the cursor.

## Workflow

`.github/workflows/esoui-comments.yml` runs daily at 06:00 UTC and on demand.
A manual run takes a `dry_run` input that maps to `--check`.

It needs only:

```yaml
permissions:
  contents: read
  issues: write
```

The feed cursor lives in the issue body rather than in a repository variable,
because `GITHUB_TOKEN` can write issues but cannot write Actions variables.
Nothing else needs to be configured: `ESOUI_ADDON_ID` comes from the repository
variable that the release workflow already uses.

The job is serialized with `concurrency: esoui-comments`, so two runs cannot
race over the cursor.

## Triage loop

1. Read the new `esoui`-labeled issue or the feed issue comment.
2. Reply in the GitHub issue with the diagnosis.
3. Reply on ESOUI too: the reporter may not watch GitHub. Quote the original
   comment so the reply is matched back to the issue.
4. Close the issue when the fix ships and mention the version.

The pipeline only copies comments one way (ESOUI to GitHub). Answers have to be
posted on both sites, because the script never posts to ESOUI.

## Limits

- **One way.** Comments are copied; replies on GitHub are not mirrored back.
- **Heuristic replies.** ESOUI quotes do not carry a parent id, so an unusual
  quote (heavily edited, or quoting only a URL) falls back to the feed.
- **No backfill.** The first run starts at the newest comment.
- **Pagination.** Five pages, 15 comments per page, newest first. A busier
  listing needs a larger `--pages`.
- **Editing this file.** `_tools/esoui_comments.py` is loaded by the audit as
  plain Python source but is not packaged. Keep it Python 3.8 compatible: the
  workflow uses 3.12, but `python _tools\audit_addon.py` should stay runnable on
  an older interpreter.
