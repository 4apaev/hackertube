import SwiftUI

struct LibraryView: View {
    @Environment(Library.self) private var library

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 40) {
                section("Watch later", library.later, empty: "Videos you save for later show here.")
                section("Liked", library.liked, empty: "Videos you like show here. They also steer Picked for you.")
                section("History", library.history, empty: "Videos you play show here.")
                HStack(spacing: 40) {
                    if !library.history.isEmpty {
                        Button("Clear history", role: .destructive) { library.clearHistory() }
                    }
                    NavigationLink("About HackerTube", value: Route.about)
                }
            }
        }
    }

    @ViewBuilder
    private func section(_ title: String, _ videos: [Video], empty: String) -> some View {
        if videos.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                Text(title).font(.title3).fontWeight(.semibold)
                Text(empty).foregroundStyle(.secondary)
            }
        } else {
            VideoShelf(title: title, videos: videos)
        }
    }
}

struct AboutView: View {
    var body: some View {
        HStack(alignment: .top, spacing: 80) {
            VStack(alignment: .leading, spacing: 24) {
                Text("HackerTube for Apple TV is an unofficial app for hackertube.org: the YouTube videos that Hacker News keeps telling each other to watch.")
                    .font(.title3)
                Text("Video lists, summaries and labels come from HackerTube (hackertube.org) and the open-index/hacker-news dataset, under the ODC-By 1.0 license. Comments remain the work of their authors. Claude wrote the labels and summaries, so a few can be wrong.")
                Text("Videos play in the YouTube app. Your Liked, Watch later and History lists stay on this Apple TV.")
                Text("Not affiliated with YouTube, Google, Hacker News or Y Combinator.")
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: 1000, alignment: .leading)
            VStack(spacing: 16) {
                QRCode(url: URL(string: "https://hackertube.org/about")!)
                    .frame(width: 280, height: 280)
                Text("hackertube.org").font(.caption).foregroundStyle(.secondary)
            }
        }
        .navigationTitle("About")
    }
}
