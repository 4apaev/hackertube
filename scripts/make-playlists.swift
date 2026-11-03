// Writes an HTML page of YouTube playlist links from the HackerTube data export.
// Each link opens a temporary YouTube playlist of up to 50 videos, in a browser or the YouTube app.
// Usage: swift scripts/make-playlists.swift [data-dir] [out.html]
import Foundation

let dataDir = URL(fileURLWithPath: CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : "data")
let outFile = URL(fileURLWithPath: CommandLine.arguments.count > 2 ? CommandLine.arguments[2] : "playlists.html")
let maxVideos = 50  // YouTube ignores more ids in one watch_videos link

struct Video: Decodable {
    let vid: String
    let title: String
    let channel: String?
    let categories: [CategoryRef]
}

struct CategoryRef: Decodable {
    let id: String
    let area: String
}

struct Taxonomy: Decodable {
    struct Area: Decodable { let id, name: String; let categories: [Category] }
    struct Category: Decodable { let id, name: String }
    let areas: [Area]
}

/// The site's curated playlists. They are not in the export, so they come from the API.
struct CuratedSummary: Decodable { let slug: String }
struct Curated: Decodable {
    struct Item: Decodable { let vid: String; let title: String; let channel: String? }
    let title: String
    let pitch: String?
    let tier: String?
    let videos: [Item]
}

struct Playlist {
    let name: String
    let note: String?
    let total: Int
    let videos: [(vid: String, title: String, channel: String?)]
}

func fetch<T: Decodable>(_ path: String) async throws -> T {
    let (data, _) = try await URLSession.shared.data(from: URL(string: "https://hackertube.org/\(path)")!)
    return try JSONDecoder().decode(T.self, from: data)
}

// Videos are stored best-scored first, so a prefix is the best of any group.
let videos = try String(contentsOf: dataDir.appending(path: "videos.jsonl"), encoding: .utf8)
    .split(separator: "\n")
    .map { try JSONDecoder().decode(Video.self, from: Data($0.utf8)) }
let taxonomy = try JSONDecoder().decode(Taxonomy.self, from: Data(contentsOf: dataDir.appending(path: "taxonomy.json")))

func playlist(_ name: String, note: String? = nil, _ members: [Video]) -> Playlist {
    Playlist(name: name, note: note, total: members.count,
             videos: members.prefix(maxVideos).map { ($0.vid, $0.title, $0.channel) })
}

var curated: [Playlist] = []
do {
    let summaries: [CuratedSummary] = try await fetch("api/playlists")
    for summary in summaries {
        let p: Curated = try await fetch("api/playlist?slug=\(summary.slug)")
        curated.append(Playlist(name: p.title, note: p.pitch, total: p.videos.count,
                                videos: p.videos.prefix(maxVideos).map { ($0.vid, $0.title, $0.channel) }))
    }
} catch {
    FileHandle.standardError.write(Data("Skipped curated playlists: \(error.localizedDescription)\n".utf8))
}

let areaLists = taxonomy.areas.map { area in
    playlist(area.name, videos.filter { $0.categories.contains { $0.area == area.id } })
}
let categoryLists = taxonomy.areas.map { area in
    (area.name, area.categories.map { category in
        playlist(category.name, videos.filter { $0.categories.contains { $0.id == category.id } })
    })
}

// MARK: - HTML

func esc(_ s: String) -> String {
    s.replacingOccurrences(of: "&", with: "&amp;").replacingOccurrences(of: "<", with: "&lt;")
        .replacingOccurrences(of: ">", with: "&gt;").replacingOccurrences(of: "\"", with: "&quot;")
}

func link(_ p: Playlist) -> String {
    "https://www.youtube.com/watch_videos?video_ids=" + p.videos.map(\.vid).joined(separator: ",")
}

func row(_ p: Playlist) -> String {
    let count = p.total > p.videos.count ? "best \(p.videos.count) of \(p.total)" : "\(p.videos.count) videos"
    let items = p.videos.map { v in
        "<li><a href=\"https://www.youtube.com/watch?v=\(v.vid)\">\(esc(v.title))</a>"
            + (v.channel.map { " <span>\(esc($0))</span>" } ?? "") + "</li>"
    }.joined()
    return """
    <div class="pl">
      <a class="play" href="\(esc(link(p)))" target="_blank" rel="noopener" aria-label="Play \(esc(p.name))">▶</a>
      <details><summary><b>\(esc(p.name))</b> <small>\(count)</small>\(p.note.map { "<p>\(esc($0))</p>" } ?? "")</summary>
      <ol>\(items)</ol></details>
    </div>
    """
}

func section(_ title: String, _ intro: String, _ lists: [Playlist]) -> String {
    "<section><h2>\(esc(title))</h2><p class=\"intro\">\(intro)</p>\(lists.map(row).joined(separator: "\n"))</section>"
}

let generated = ISO8601DateFormatter.string(from: Date(), timeZone: .current, formatOptions: [.withFullDate])
let html = """
<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>HackerTube Playlists</title>
<style>
  :root { --bg: #fff; --card: #f4f4f4; --text: #0f0f0f; --muted: #606060; --line: #e3e3e3; --accent: #ff6600; }
  @media (prefers-color-scheme: dark) {
    :root:not([data-theme="light"]) { --bg: #0f0f0f; --card: #1d1d1d; --text: #f1f1f1; --muted: #aaa; --line: #303030; }
  }
  :root[data-theme="dark"] { --bg: #0f0f0f; --card: #1d1d1d; --text: #f1f1f1; --muted: #aaa; --line: #303030; }
  * { box-sizing: border-box; }
  body { margin: 0; background: var(--bg); color: var(--text);
         font: 16px/1.45 -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif; }
  main { max-width: 860px; margin: 0 auto; padding: 24px 16px 64px; }
  h1 { font-size: 28px; margin: 0 0 4px; } h1 b { color: var(--accent); }
  h2 { font-size: 21px; margin: 40px 0 4px; } h3 { font-size: 17px; margin: 28px 0 8px; color: var(--muted); }
  a { color: inherit; }
  .intro, .how, small, footer { color: var(--muted); }
  .how { background: var(--card); border-radius: 12px; padding: 12px 16px; margin: 16px 0; }
  .how ol { margin: 6px 0 0; padding-left: 20px; }
  .pl { display: flex; gap: 12px; align-items: flex-start; padding: 10px 0; border-bottom: 1px solid var(--line); }
  .play { flex: none; width: 40px; height: 40px; border-radius: 50%; background: var(--accent); color: #fff;
          display: grid; place-items: center; text-decoration: none; font-size: 15px; }
  details { flex: 1; min-width: 0; }
  summary { cursor: pointer; padding-top: 8px; }
  summary p { margin: 4px 0 0; color: var(--muted); font-size: 14px; }
  ol { margin: 8px 0 4px; padding-left: 24px; font-size: 14px; }
  li { margin: 2px 0; overflow-wrap: anywhere; } li a { text-decoration: none; } li a:hover { text-decoration: underline; }
  li span { color: var(--muted); }
  footer { margin-top: 48px; font-size: 13px; }
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
\(curated.isEmpty ? "" : section("Curated", "The site's own playlists, in their order.", curated))
\(section("Top 50", "The 50 videos with the best HN score.", [playlist("Top 50 overall", videos)]))
\(section("Areas", "The best 50 videos in each of the \(taxonomy.areas.count) topic areas.", areaLists))
<section><h2>Categories</h2><p class="intro">The best 50 videos in each category, by area.</p>
\(categoryLists.map { "<h3>\(esc($0.0))</h3>" + $0.1.map(row).joined(separator: "\n") }.joined(separator: "\n"))
</section>
<footer>
  Generated \(generated) from <a href="https://hackertube.org/data">the HackerTube data export</a>
  (\(videos.count) videos), <a href="https://opendatacommons.org/licenses/by/1-0/">ODC-By 1.0</a>.
  Data: HackerTube and the <a href="https://huggingface.co/datasets/open-index/hacker-news">open-index/hacker-news</a> dataset.
  Not affiliated with YouTube, Google, Hacker News or Y Combinator.
</footer>
</main>
</body>
</html>
"""
try html.write(to: outFile, atomically: true, encoding: .utf8)
print("Wrote \(outFile.path): \(curated.count) curated, \(areaLists.count) areas, \(categoryLists.reduce(0) { $0 + $1.1.count }) categories")
