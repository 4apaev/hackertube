#!/usr/bin/env python3
"""Writes an HTML page of YouTube playlist links from the HackerTube data export.

Each link opens a temporary YouTube playlist of up to 50 videos, in a browser or the YouTube app.
Same output as make-playlists.swift. Standard library only.
Usage: python3 scripts/make-playlists.py [data-dir] [out.html]
"""
import datetime
import json
import sys
import urllib.request
from concurrent.futures import ThreadPoolExecutor
from pathlib import Path

data_dir = Path(sys.argv[1] if len(sys.argv) > 1 else "data")
out_file = Path(sys.argv[2] if len(sys.argv) > 2 else "playlists.html")

MAX_VIDEOS = 50  # YouTube ignores more ids in one watch_videos link


def fetch(path):
    with urllib.request.urlopen(f"https://hackertube.org/{path}", timeout=30) as response:
        return json.load(response)

def playlist(name, members, note=None):
    """members: dicts with vid, title, channel. Keeps the best MAX_VIDEOS."""
    return {"name": name, "note": note, "total": len(members), "videos": members[:MAX_VIDEOS]}


# Videos are stored best-scored first, so a prefix is the best of any group.
videos = [json.loads(line) for line in (data_dir / "videos.jsonl").read_text("utf-8").splitlines() if line]
taxonomy = json.loads((data_dir / "taxonomy.json").read_text("utf-8"))

# The site's curated playlists. They are not in the export, so they come from the API.
curated = []
try:
    slugs = [summary["slug"] for summary in fetch("api/playlists")]
    with ThreadPoolExecutor(max_workers=8) as pool:  # map keeps the site's order
        for p in pool.map(lambda slug: fetch(f"api/playlist?slug={slug}"), slugs):
            curated.append(playlist(p["title"], p["videos"], note=p.get("pitch")))
except (OSError, ValueError, KeyError) as error:
    print(f"Skipped curated playlists: {error}", file=sys.stderr)

area_lists = [
    playlist(area["name"], [v for v in videos if any(c["area"] == area["id"] for c in v["categories"])])
    for area in taxonomy["areas"]
]

category_lists = [
    (area["name"], [
        playlist(category["name"], [v for v in videos if any(c["id"] == category["id"] for c in v["categories"])])
        for category in area["categories"]
    ])
    for area in taxonomy["areas"]
]

# HTML

def esc(s):
    return s.replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;").replace('"', "&quot;")


def link(p):
    return "https://www.youtube.com/watch_videos?video_ids=" + ",".join(v["vid"] for v in p["videos"])


def row(p):
    shown = len(p["videos"])
    count = f"best {shown} of {p['total']}" if p["total"] > shown else f"{shown} videos"
    items = "".join(
        f'<li><a href="https://www.youtube.com/watch?v={v["vid"]}">{esc(v["title"])}</a>'
        + (f" <span>{esc(v['channel'])}</span>" if v.get("channel") is not None else "")
        + "</li>"
        for v in p["videos"]
    )
    note = f"<p>{esc(p['note'])}</p>" if p["note"] is not None else ""
    return (
        '<div class="pl">\n'
        f'  <a class="play" href="{esc(link(p))}" target="_blank" rel="noopener" aria-label="Play {esc(p["name"])}">▶</a>\n'
        f'  <details><summary><b>{esc(p["name"])}</b> <small>{count}</small>{note}</summary>\n'
        f"  <ol>{items}</ol></details>\n"
        "</div>"
    )


def section(title, intro, lists):
    return f'<section><h2>{esc(title)}</h2><p class="intro">{intro}</p>' + "\n".join(map(row, lists)) + "</section>"


generated = datetime.date.today().isoformat()
categories_html = "\n".join(f"<h3>{esc(name)}</h3>" + "\n".join(map(row, lists)) for name, lists in category_lists)
html = f"""<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>HackerTube Playlists</title>
<style>
  :root {{ --bg: #fff; --card: #f4f4f4; --text: #0f0f0f; --muted: #606060; --line: #e3e3e3; --accent: #ff6600; }}
  @media (prefers-color-scheme: dark) {{
    :root:not([data-theme="light"]) {{ --bg: #0f0f0f; --card: #1d1d1d; --text: #f1f1f1; --muted: #aaa; --line: #303030; }}
  }}
  :root[data-theme="dark"] {{ --bg: #0f0f0f; --card: #1d1d1d; --text: #f1f1f1; --muted: #aaa; --line: #303030; }}
  * {{ box-sizing: border-box; }}
  body {{ margin: 0; background: var(--bg); color: var(--text);
         font: 16px/1.45 -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif; }}
  main {{ max-width: 860px; margin: 0 auto; padding: 24px 16px 64px; }}
  h1 {{ font-size: 28px; margin: 0 0 4px; }} h1 b {{ color: var(--accent); }}
  h2 {{ font-size: 21px; margin: 40px 0 4px; }} h3 {{ font-size: 17px; margin: 28px 0 8px; color: var(--muted); }}
  a {{ color: inherit; }}
  .intro, .how, small, footer {{ color: var(--muted); }}
  .how {{ background: var(--card); border-radius: 12px; padding: 12px 16px; margin: 16px 0; }}
  .how ol {{ margin: 6px 0 0; padding-left: 20px; }}
  .pl {{ display: flex; gap: 12px; align-items: flex-start; padding: 10px 0; border-bottom: 1px solid var(--line); }}
  .play {{ flex: none; width: 40px; height: 40px; border-radius: 50%; background: var(--accent); color: #fff;
          display: grid; place-items: center; text-decoration: none; font-size: 15px; }}
  details {{ flex: 1; min-width: 0; }}
  summary {{ cursor: pointer; padding-top: 8px; }}
  summary p {{ margin: 4px 0 0; color: var(--muted); font-size: 14px; }}
  ol {{ margin: 8px 0 4px; padding-left: 24px; font-size: 14px; }}
  li {{ margin: 2px 0; overflow-wrap: anywhere; }} li a {{ text-decoration: none; }} li a:hover {{ text-decoration: underline; }}
  li span {{ color: var(--muted); }}
  footer {{ margin-top: 48px; font-size: 13px; }}
</style>
</head>
<body>
<main>
<h1>Hacker<b>Tube</b> playlists</h1>
<p class="intro">The YouTube videos that Hacker News keeps telling each other to watch, as one-click YouTube playlists.</p>
<div class="how">
  <b>How to use</b>
  <ol>
    <li>Push ▶. YouTube opens a playlist of up to 50 videos. On a phone, the YouTube app opens it.</li>
    <li>The playlist is temporary. To keep it, open the playlist panel in the browser and save it to your library.</li>
    <li>Saved playlists show in the YouTube app's Library on every device, the Apple TV too.</li>
  </ol>
</div>
{section("Curated", "The site's own playlists, in their order.", curated) if curated else ""}
{section("Top 50", "The 50 videos with the best HN score.", [playlist("Top 50 overall", videos)])}
{section("Areas", f"The best 50 videos in each of the {len(taxonomy['areas'])} topic areas.", area_lists)}
<section><h2>Categories</h2><p class="intro">The best 50 videos in each category, by area.</p>
{categories_html}
</section>
<footer>
  Generated {generated} from <a href="https://hackertube.org/data">the HackerTube data export</a>
  ({len(videos)} videos), <a href="https://opendatacommons.org/licenses/by/1-0/">ODC-By 1.0</a>.
  Data: HackerTube and the <a href="https://huggingface.co/datasets/open-index/hacker-news">open-index/hacker-news</a> dataset.
  Not affiliated with YouTube, Google, Hacker News or Y Combinator.
</footer>
</main>
</body>
</html>"""
out_file.write_text(html, "utf-8")
print(f"Wrote {out_file.resolve()}: {len(curated)} curated, {len(area_lists)} areas, "
      f"{sum(len(lists) for _, lists in category_lists)} categories")
