import SwiftUI

struct HomeView: View {
    @Environment(Library.self) private var library
    @State private var seed = Int.random(in: 1...1_000_000)

    /// The same shelves the website links to from its Browse page.
    private let lists: [(title: String, filters: [String: String])] = [
        ("Recently recommended", ["sort": "recent"]),
        ("Most recommended", ["sort": "hn"]),
        ("Hidden gems", ["gems": "1"]),
        ("Longs", ["dur": "xlong"]),
    ]

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 40) {
                RemoteShelf(title: "Picked for you") {
                    try await API.feed(seed: seed, like: library.liked.map(\.vid), seen: library.history.map(\.vid), n: 20)
                }
                if !library.later.isEmpty {
                    VideoShelf(title: "Watch later", videos: library.later)
                }
                RemoteShelf(title: "The HN canon", seeAll: .playlist(slug: "hn-canon", title: "The HN canon")) {
                    try await API.playlist("hn-canon").videos
                }
                ForEach(lists, id: \.title) { list in
                    RemoteShelf(title: list.title, seeAll: .list(title: list.title, filters: list.filters)) {
                        try await API.list(list.filters, n: 20)
                    }
                }
            }
        }
    }
}
