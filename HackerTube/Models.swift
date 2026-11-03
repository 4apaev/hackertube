import Foundation

/// One video as the HackerTube API returns it. Equality is by YouTube id.
struct Video: Codable, Identifiable, Hashable {
    let vid: String
    let title: String
    let channel: String?
    let published: String?
    let durationS: Int?
    let views: Int?
    let summary: String?
    let whyHn: String?
    let contentType: String?
    let primaryTopic: String?
    let quote: Quote?
    let hn: HNStats?
    let whys: [String]?

    var id: String { vid }

    static func == (a: Video, b: Video) -> Bool { a.vid == b.vid }
    func hash(into hasher: inout Hasher) { hasher.combine(vid) }
}

struct Quote: Codable {
    let text: String
    let year: String?
}

struct HNStats: Codable {
    let mentions: Int?
    let recommenders: Int?
    let first: String?
    let last: String?
}

struct Comment: Codable, Identifiable {
    let id: Int
    let author: String?
    let ym: String?
    let story: String?
    let why: String?
    let quote: String?
}

struct VideoDetail: Codable {
    let video: Video
    let comments: [Comment]?
}

struct Area: Codable, Identifiable {
    let id: String
    let name: String
    let count: Int
    let categories: [Category]
}

struct Category: Codable, Identifiable {
    let id: String
    let name: String
    let count: Int
}

struct PlaylistSummary: Codable, Identifiable {
    let slug: String
    let title: String
    let pitch: String?
    let tier: String?
    let minutes: Int?
    let count: Int?
    let cover: [String]

    var id: String { slug }
}

struct Playlist: Codable {
    let slug: String
    let title: String
    let pitch: String?
    let intro: String?
    let minutes: Int?
    let videos: [Video]
}

struct SearchResults: Codable {
    /// True when nothing matched well and the results are the nearest guesses.
    let weak: Bool?
    let results: [Video]
}
