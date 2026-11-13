#!/usr/bin/env python3
"""Sync ESOUI file comments into GitHub issues.

Comments tagged ``#bug``, ``#enhancement``, ``#request`` or ``#issue`` become
GitHub issues. A comment that quotes a comment already tracked in an issue, or
that references an issue number like ``#12``, is appended to that issue.
Everything else is appended to a single "ESOUI comments feed" issue so general
comments stay out of the issue tracker.

The newest synced comment id is stored in the feed issue body, so a run only
looks at comments posted since the previous run. Every issue and comment also
carries a hidden ``<!-- esoui-comment:<id> -->`` marker, which de-duplicates a
re-run after a crash.

Usage:
    python _tools/esoui_comments.py --check
    python _tools/esoui_comments.py
    python _tools/esoui_comments.py --addon-id 1245 --pages 1 --check
    python _tools/esoui_comments.py --from-file page.html --check
This is a maintenance helper only; ESO does not load it.
"""

import argparse
import json
import os
import re
import subprocess
import sys
import urllib.request
from html.parser import HTMLParser
from pathlib import Path

DEFAULT_ADDON_ID = "5044"
DEFAULT_REPO = "delli007/KelaPadUIEnhanced"
DEFAULT_OWNER = "delli007"

PAGE_URL = (
    "https://www.esoui.com/downloads/fileinfo.php"
    "?id={addon_id}&so=DESC&page={page}#comments"
)
CANONICAL_PAGE_URL = (
    "https://www.esoui.com/downloads/info{addon_id}-KelaPadUIEnhanced.html"
)

USER_AGENT = (
    "KelaPadUIEnhanced-feedback-sync/1.0 "
    "(+https://github.com/delli007/KelaPadUIEnhanced)"
)

TAGS = ("bug", "enhancement", "request", "issue")
TAG_LABELS = {
    "bug": "bug",
    "enhancement": "enhancement",
    "request": "request",
    "issue": "issue",
}
LABELS = {
    "esoui": ("5319e7", "Reported on the ESOUI add-on page"),
    "esoui-feed": ("c5def5", "Rolling feed of untagged ESOUI comments"),
    "bug": ("d73a4a", "Something isn't working"),
    "enhancement": ("a2eeef", "New feature or request"),
    "request": ("a2eeef", "Feature request from the ESOUI comments"),
    "issue": ("d4c5f9", "General issue reported in the ESOUI comments"),
}

FEED_TITLE = "ESOUI comments feed"
FEED_MARKER = "<!-- esoui-last-seen:{comment_id} -->"
COMMENT_MARKER = "<!-- esoui-comment:{comment_id} -->"
AUTHOR_MARKER = "<!-- esoui-author:{author} -->"

FEED_ISSUE_BODY = """\
General comments from the [ESOUI add-on page]({addon_url}) that are not bug
reports or feature requests. Comments tagged `#bug`, `#enhancement`, `#request`
or `#issue` get their own issue, and replies to a tracked comment are added to
that issue instead.

Keep this issue open. Its body stores the newest synced comment id; clearing it
makes the next run start from the newest comment without backfilling.

{marker}
"""

ISSUE_TEMPLATE = """\
**{author}** reported this in the [ESOUI comments]({link}) on {date}.

{text}

{quotes}
Tags: {tags}

{marker}
{author_marker}
"""

FEED_COMMENT_TEMPLATE = """\
**{author}** commented on {date}: [view on ESOUI]({link})

{text}

{quotes}
@{owner}

{marker}
"""

REPLY_TEMPLATE = """\
**{author}** replied on {date}: [view on ESOUI]({link})

{text}

{quotes}
{marker}
"""

QUOTE_TEMPLATE = """
> **{author} wrote:**
{text}
"""


# ---------------------------------------------------------------------------
# ESOUI comment parsing
# ---------------------------------------------------------------------------

COMMENT_START = re.compile(r'<a name="cmnt_(\d+)"></a>')
POSTMESSAGE = re.compile(r'<div class="postmessage"[^>]*>', re.IGNORECASE)
POSTMENU = re.compile(
    r'id="postmenu_(\d+)"[^>]*>\s*<a[^>]*>([^<]+)</a>', re.IGNORECASE
)
POSTED = re.compile(r"\d{2}/\d{2}/\d{2}, \d{2}:\d{2} [AP]M")
DIV_TAG = re.compile(r"<(/?)div\b[^>]*>", re.IGNORECASE)


class _BodyParser(HTMLParser):
    """Collect a comment's own text and its quoted blocks.

    Nested quotes are dropped from the outer quote's text, so the text kept for
    an outer quote is the words the quoted author actually wrote. That makes
    reply matching against a stored issue body reliable.
    """

    def __init__(self):
        super().__init__(convert_charrefs=True)
        self.text = []
        self.quotes = []
        self.quote_depth = 0
        self.td_stack = []
        self.skip = 0
        self.in_author = False
        self.header_depth = 0

    def _add(self, value):
        if self.quote_depth == 0:
            self.text.append(value)
        elif self.quote_depth == 1:
            self.quotes[self.quote_depth - 1]["text"].append(value)

    def handle_starttag(self, tag, attrs):
        attributes = dict(attrs)
        if tag in ("script", "style"):
            self.skip += 1
        elif tag == "td":
            quoted = "bbquote" in (attributes.get("class") or "").split()
            self.td_stack.append(quoted)
            if quoted:
                self.quotes.append({"author": "", "text": []})
                self.quote_depth += 1
        elif tag == "strong" and self.quote_depth:
            if not self.quotes[self.quote_depth - 1]["author"]:
                self.in_author = True
        elif tag == "br":
            self._add("\n")
        elif tag == "div":
            # The quoted header ("Originally Posted by X") is skipped: the
            # author is kept separately and the words around it are noise.
            if self.header_depth:
                self.header_depth += 1
            elif self.quote_depth and "font-size:10px" in (attributes.get("style") or ""):
                self.header_depth = 1
            self._add("\n")
        elif tag in ("p", "li", "tr"):
            self._add("\n")

    def handle_endtag(self, tag):
        if tag in ("script", "style"):
            self.skip = max(0, self.skip - 1)
        elif tag == "td":
            if self.td_stack and self.td_stack.pop():
                self.quote_depth = max(0, self.quote_depth - 1)
        elif tag == "strong":
            self.in_author = False
        elif tag == "div":
            if self.header_depth:
                self.header_depth -= 1
            self._add("\n")
        elif tag in ("p", "li", "tr"):
            self._add("\n")

    def handle_data(self, data):
        if self.skip:
            return
        if self.in_author:
            self.quotes[self.quote_depth - 1]["author"] += data
            return
        if self.header_depth:
            return
        self._add(data)


def clean_text(value):
    value = re.sub(r"[ \t\r\f\v]+", " ", value)
    value = re.sub(r" *\n *", "\n", value)
    value = re.sub(r"\n{3,}", "\n\n", value)
    return value.strip()


def extract_div(fragment, opening_match):
    """Return the content of the div that starts at opening_match."""
    start = opening_match.end()
    depth = 1
    position = start
    while depth:
        match = DIV_TAG.search(fragment, position)
        if not match:
            return fragment[start:]
        depth += -1 if match.group(1) else 1
        position = match.end()
    return fragment[start:match.start()]


def parse_comments(html):
    starts = list(COMMENT_START.finditer(html))
    comments = []
    for index, start in enumerate(starts):
        end = starts[index + 1].start() if index + 1 < len(starts) else len(html)
        segment = html[start.end():end]

        author_match = POSTMENU.search(segment)
        date_match = POSTED.search(segment)
        body_match = POSTMESSAGE.search(segment)
        if not (author_match and body_match):
            continue

        body_html = extract_div(segment, body_match)
        parser = _BodyParser()
        parser.feed(body_html)
        parser.close()

        quotes = []
        for quote in parser.quotes:
            text = clean_text("".join(quote["text"]))
            if text:
                quotes.append({"author": clean_text(quote["author"]), "text": text})

        comments.append(
            {
                "id": int(start.group(1)),
                "author": clean_text(author_match.group(2)),
                "date": date_match.group(0) if date_match else "",
                "text": clean_text("".join(parser.text)),
                "quotes": quotes,
            }
        )
    return comments


def fetch_page(addon_id, page):
    url = PAGE_URL.format(addon_id=addon_id, page=page)
    request = urllib.request.Request(url, headers={"User-Agent": USER_AGENT})
    with urllib.request.urlopen(request, timeout=30) as response:
        return response.read().decode("utf-8", "replace")


def collect_comments(addon_id, pages, last_seen, from_file):
    if from_file:
        return parse_comments(Path(from_file).read_text(encoding="utf-8", errors="replace"))

    collected = {}
    for page in range(1, pages + 1):
        page_comments = parse_comments(fetch_page(addon_id, page))
        if not page_comments:
            break
        fresh = [comment for comment in page_comments if comment["id"] > last_seen]
        for comment in fresh:
            collected[comment["id"]] = comment
        if len(fresh) < len(page_comments):
            break
    return [collected[key] for key in sorted(collected)]


# ---------------------------------------------------------------------------
# Classification
# ---------------------------------------------------------------------------

def find_tag(text):
    match = re.search(r"#(bug|enhancement|request|issue)\b", text, re.IGNORECASE)
    return match.group(1).lower() if match else None


def find_issue_reference(text):
    match = re.search(r"(?<![\w/])#(\d+)\b", text)
    return int(match.group(1)) if match else None


def normalize(text):
    text = re.sub(r"https?://\S+", " ", text)
    text = re.sub(r"\s+", " ", text)
    return text.strip().lower()


def match_quote(quotes, tracked):
    for quote in quotes:
        quoted = normalize(quote["text"])
        if len(quoted) < 20:
            continue
        author = quote["author"].strip().lower()
        for issue in tracked:
            if issue["author"] and author and issue["author"] != author:
                continue
            if quoted[:160] in issue["text"]:
                return issue["number"]
    return None


def summarize(text, limit=70):
    first = ""
    for line in text.splitlines():
        line = re.sub(r"#(bug|enhancement|request|issue)\b", "", line, flags=re.IGNORECASE)
        line = line.strip(" \t-*")
        if line:
            first = line
            break
    if not first:
        first = "new ESOUI comment"
    if len(first) > limit:
        first = first[: limit - 1].rstrip() + "\u2026"
    return first


def quote_block(quotes):
    if not quotes:
        return ""
    blocks = []
    for quote in quotes:
        text = "\n".join(
            "> " + line if line.strip() else ">" for line in quote["text"].splitlines()
        )
        blocks.append(
            QUOTE_TEMPLATE.format(author=quote["author"] or "someone", text=text).strip()
        )
    return "\n>\n".join(blocks) + "\n"


def comment_link(addon_id, comment_id):
    return PAGE_URL.format(addon_id=addon_id, page=1).split("#")[0] + "#cmnt%d" % comment_id


def addon_page_url(addon_id):
    if addon_id == DEFAULT_ADDON_ID:
        return CANONICAL_PAGE_URL.format(addon_id=addon_id)
    return PAGE_URL.format(addon_id=addon_id, page=1).split("#")[0]


# ---------------------------------------------------------------------------
# GitHub helpers
# ---------------------------------------------------------------------------

def gh(*args, repo=None, input_text=None):
    command = ["gh"]
    if repo:
        command += ["--repo", repo]
    command += list(args)
    result = subprocess.run(
        command,
        check=True,
        capture_output=True,
        text=True,
        input=input_text,
        encoding="utf-8",
    )
    return result.stdout.strip()


def read_state(repo):
    """Return (feed issue, tracked issues, known comment ids)."""
    feed = None
    tracked = []
    known = set()

    try:
        issues = json.loads(
            gh(
                "issue",
                "list",
                "--state",
                "all",
                "--limit",
                "200",
                "--json",
                "number,title,body,labels,createdAt",
                repo=repo,
            )
        )
    except (subprocess.CalledProcessError, json.JSONDecodeError) as error:
        print("WARNING: cannot read GitHub issues: {}".format(error), file=sys.stderr)
        return None, tracked, known

    for issue in issues:
        body = issue.get("body") or ""
        for match in re.finditer(r"<!-- esoui-comment:(\d+) -->", body):
            known.add(int(match.group(1)))

        labels = {label["name"] for label in issue.get("labels") or []}
        if FEED_TITLE.lower() in (issue.get("title") or "").lower() and "esoui-feed" in labels:
            if feed is None or issue["number"] < feed["number"]:
                feed = issue
            continue

        if "esoui" not in labels:
            continue

        author_match = re.search(r"<!-- esoui-author:([^>]*?) -->", body)
        tracked.append(
            {
                "number": issue["number"],
                "author": (author_match.group(1) if author_match else "").strip().lower(),
                "text": normalize(body),
            }
        )

    return feed, tracked, known


def ensure_labels(repo):
    for name, (color, description) in LABELS.items():
        gh(
            "label",
            "create",
            name,
            "--color",
            color,
            "--description",
            description,
            "--force",
            repo=repo,
        )


def create_issue(repo, title, body, labels):
    args = ["issue", "create", "--title", title, "--body-file", "-"]
    for label in labels:
        args += ["--label", label]
    return gh(*args, repo=repo, input_text=body)


def comment_issue(repo, number, body):
    gh("issue", "comment", str(number), "--body-file", "-", repo=repo, input_text=body)


def edit_issue_body(repo, number, body):
    gh("issue", "edit", str(number), "--body-file", "-", repo=repo, input_text=body)


def read_cursor(feed):
    if not feed:
        return 0
    match = re.search(r"<!-- esoui-last-seen:(\d+) -->", feed.get("body") or "")
    return int(match.group(1)) if match else 0


# ---------------------------------------------------------------------------
# Sync
# ---------------------------------------------------------------------------

def build_issue_body(comment, addon_id, tag):
    return ISSUE_TEMPLATE.format(
        author=comment["author"],
        link=comment_link(addon_id, comment["id"]),
        date=comment["date"] or "an unknown date",
        text=comment["text"],
        quotes=quote_block(comment["quotes"]),
        tags="#{}".format(tag),
        marker=COMMENT_MARKER.format(comment_id=comment["id"]),
        author_marker=AUTHOR_MARKER.format(author=comment["author"].replace("--", "-")),
    ).strip() + "\n"


def build_feed_body(comment, addon_id, owner):
    return FEED_COMMENT_TEMPLATE.format(
        author=comment["author"],
        date=comment["date"] or "an unknown date",
        link=comment_link(addon_id, comment["id"]),
        text=comment["text"],
        quotes=quote_block(comment["quotes"]),
        owner=owner,
        marker=COMMENT_MARKER.format(comment_id=comment["id"]),
    ).strip() + "\n"


def build_reply_body(comment, addon_id):
    return REPLY_TEMPLATE.format(
        author=comment["author"],
        date=comment["date"] or "an unknown date",
        link=comment_link(addon_id, comment["id"]),
        text=comment["text"],
        quotes=quote_block(comment["quotes"]),
        marker=COMMENT_MARKER.format(comment_id=comment["id"]),
    ).strip() + "\n"


def parse_args(argv):
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--addon-id", default=os.environ.get("ESOUI_ADDON_ID") or DEFAULT_ADDON_ID
    )
    parser.add_argument(
        "--repo", default=os.environ.get("GITHUB_REPOSITORY") or DEFAULT_REPO
    )
    parser.add_argument(
        "--owner", default=os.environ.get("GITHUB_REPOSITORY_OWNER") or DEFAULT_OWNER
    )
    parser.add_argument("--pages", type=int, default=5, help="maximum comment pages to fetch")
    parser.add_argument("--max-new", type=int, default=10, help="maximum comments to file per run")
    parser.add_argument("--from-file", help="parse a saved page instead of fetching ESOUI")
    parser.add_argument("--check", action="store_true", help="print the plan without writing")
    return parser.parse_args(argv)


def main(argv=None):
    args = parse_args(argv or sys.argv[1:])

    feed, tracked, known = read_state(args.repo)
    last_seen = read_cursor(feed)

    comments = collect_comments(args.addon_id, args.pages, last_seen, args.from_file)
    if comments:
        newest = max(comment["id"] for comment in comments)
    else:
        newest = last_seen

    if last_seen == 0:
        print("First run: starting after comment {} ({})".format(newest, newest and "no backfill" or "empty page"))
        if not args.check:
            ensure_labels(args.repo)
            if not feed:
                body = FEED_ISSUE_BODY.format(
                    addon_url=addon_page_url(args.addon_id),
                    marker=FEED_MARKER.format(comment_id=newest),
                )
                feed = {"number": int(create_issue(args.repo, FEED_TITLE, body, ["esoui-feed"]).rsplit("/", 1)[-1])}
                print("Created feed issue #{}".format(feed["number"]))
            else:
                update_cursor(args.repo, feed, newest, args.addon_id)
        else:
            print("Would create the feed issue and start after comment {}".format(newest))
        return 0

    pending = [comment for comment in comments if comment["id"] > last_seen and comment["id"] not in known]
    pending.sort(key=lambda comment: comment["id"])
    if len(pending) > args.max_new:
        print(
            "NOTE: {} new comments, filing the oldest {}; the rest follow next run".format(
                len(pending), args.max_new
            )
        )
        pending = pending[: args.max_new]

    if not pending:
        print("No new comments (newest seen: {})".format(last_seen))
        return 0

    if not args.check:
        ensure_labels(args.repo)
        if not feed:
            body = FEED_ISSUE_BODY.format(
                addon_url=addon_page_url(args.addon_id),
                marker=FEED_MARKER.format(comment_id=last_seen),
            )
            feed = {
                "number": int(create_issue(args.repo, FEED_TITLE, body, ["esoui-feed"]).rsplit("/", 1)[-1])
            }
            print("Created feed issue #{}".format(feed["number"]))

    processed = last_seen
    for comment in pending:
        tag = find_tag(comment["text"])
        reference = find_issue_reference(comment["text"])
        target = None
        if reference:
            target = reference
        else:
            target = match_quote(comment["quotes"], tracked)

        if target:
            body = build_reply_body(comment, args.addon_id)
            print("[reply] #{} <- comment {}".format(target, comment["id"]))
            if not args.check:
                try:
                    comment_issue(args.repo, target, body)
                except subprocess.CalledProcessError as error:
                    print("WARNING: reply to #{} failed ({}), using the feed".format(target, error), file=sys.stderr)
                    target = None
        if target:
            processed = comment["id"]
            continue

        if tag:
            title = "[ESOUI #{}] {}".format(tag, summarize(comment["text"]))
            body = build_issue_body(comment, args.addon_id, tag)
            print("[issue] {} (comment {})".format(title, comment["id"]))
            if not args.check:
                create_issue(args.repo, title, body, ["esoui", TAG_LABELS[tag]])
        else:
            body = build_feed_body(comment, args.addon_id, args.owner)
            print("[feed] comment {} by {}".format(comment["id"], comment["author"]))
            if not args.check:
                comment_issue(args.repo, feed["number"], body)
        processed = comment["id"]

    if not args.check:
        update_cursor(args.repo, feed, processed, args.addon_id)

    print("Synced {} comment(s); newest synced id {}".format(len(pending), processed))
    return 0


def update_cursor(repo, feed, comment_id, addon_id):
    if not feed:
        return
    body = feed.get("body") or FEED_ISSUE_BODY.format(
        addon_url=addon_page_url(addon_id),
        marker=FEED_MARKER.format(comment_id=comment_id),
    )
    if re.search(r"<!-- esoui-last-seen:\d+ -->", body):
        body = re.sub(
            r"<!-- esoui-last-seen:\d+ -->",
            FEED_MARKER.format(comment_id=comment_id),
            body,
        )
    else:
        body = body.rstrip() + "\n\n" + FEED_MARKER.format(comment_id=comment_id) + "\n"
    edit_issue_body(repo, feed["number"], body)
    feed["body"] = body


if __name__ == "__main__":
    sys.exit(main())
