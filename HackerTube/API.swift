import Foundation

/// Client for the public JSON API behind hackertube.org.
enum API {
    static let base = URL(string: "https://hackertube.org")!
    static let pageSize = 36

    private static let decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return decoder
    }()

    static func get<T: Decodable>(_ path: String, _ query: [String: String] = [:]) async throws -> T {
        var url = base.appending(path: path)
        if !query.isEmpty {
            url.append(queryItems: query.sorted { $0.key < $1.key }.map { URLQueryItem(name: $0.key, value: $0.value) })
        }
        let (data, response) = try await URLSession.shared.data(from: url)
        if let http = response as? HTTPURLResponse, !(200..<300).contains(http.statusCode) {
            throw URLError(.badServerResponse)
        }
        return try decoder.decode(T.self, from: data)
    }

    /// The home feed. Likes and watched videos steer it, the same way the website does.
    static func feed(seed: Int, like: [String], seen: [String], offset: Int = 0, n: Int = pageSize) async throws -> [Video] {
        try await get("api/feed", [
            "seed": String(seed), "like": like.prefix(50).joined(separator: ","), "dislike": "",
            "seen": seen.prefix(50).joined(separator: ","), "offset": String(offset), "n": String(n),
        ])
    }

    /// All videos, filtered and sorted. Filters: area, cat, sort, dur, gems, type, date.
    static func list(_ filters: [String: String], offset: Int = 0, n: Int = pageSize) async throws -> [Video] {
        try await get(
            "api/list",
            filters.merging([
                "offset": String(offset),
                "n": String(n)
            ])
            { $1 }
        )
    }

    static func areas() async throws -> [Area] { try await get("api/browse") }
    static func playlists() async throws -> [PlaylistSummary] { try await get("api/playlists") }
    static func playlist(_ slug: String) async throws -> Playlist { try await get("api/playlist", ["slug": slug]) }
    static func search(_ q: String) async throws -> SearchResults { try await get("api/search", ["q": q]) }
    static func video(_ vid: String) async throws -> VideoDetail { try await get("api/video", ["vid": vid]) }
    static func related(_ vid: String, n: Int = 20) async throws -> [Video] {
        try await get("api/related", ["vid": vid, "n": String(n)])
    }
}
