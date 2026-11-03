import SwiftUI

/// A titled row of video cards that scrolls sideways.
struct VideoShelf: View {
    let title: String
    let videos: [Video]
    var seeAll: Route?

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.title3)
                .fontWeight(.semibold)
            ScrollView(.horizontal) {
                LazyHStack(alignment: .top, spacing: VideoCard.spacing) {
                    ForEach(videos) { video in
                        NavigationLink(value: Route.video(video)) { VideoCard(video: video) }
                    }
                    if let seeAll {
                        NavigationLink(value: seeAll) {
                            Label("See all", systemImage: "chevron.right")
                                .font(.callout)
                                .frame(width: 240, height: VideoCard.width * 9 / 16)
                        }
                    }
                }
                .padding(.vertical, 30)
            }
            .scrollClipDisabled()
            .buttonStyle(.card)
        }
    }
}

/// A VideoShelf that loads its videos when it first appears.
struct RemoteShelf: View {
    let title: String
    var seeAll: Route?
    let load: () async throws -> [Video]

    @State private var videos: [Video]?
    @State private var failed = false

    var body: some View {
        VStack(alignment: .leading) {
            if let videos {
                if !videos.isEmpty { VideoShelf(title: title, videos: videos, seeAll: seeAll) }
            } else {
                Text(title).font(.title3).fontWeight(.semibold)
                if failed {
                    Text("Could not load this row.").foregroundStyle(.secondary)
                } else {
                    ProgressView().frame(height: VideoCard.width * 9 / 16 + 100)
                }
            }
        }
        .task {
            guard videos == nil else { return }
            do { videos = try await load() } catch { failed = true }
        }
    }
}

/// A grid that loads the next page when the last card appears.
struct PagedVideoGrid: View {
    let title: String
    let load: (_ offset: Int) async throws -> [Video]

    @State private var videos: [Video] = []
    @State private var loading = false
    @State private var done = false
    @State private var failed = false

    var body: some View {
        ScrollView {
            LazyVGrid(columns: VideoCard.columns, alignment: .leading, spacing: 50) {
                ForEach(videos) { video in
                    NavigationLink(value: Route.video(video)) { VideoCard(video: video) }
                        .onAppear {
                            if video == videos.last { Task { await loadMore() } }
                        }
                }
            }
            .buttonStyle(.card)
            if failed {
                Button("Retry") { Task { await loadMore() } }
            } else if loading {
                ProgressView().padding(40)
            } else if done && videos.isEmpty {
                Text("No videos here.").foregroundStyle(.secondary)
            }
        }
        .navigationTitle(title)
        .task { if videos.isEmpty { await loadMore() } }
    }

    private func loadMore() async {
        guard !loading, !done else { return }
        loading = true
        defer { loading = false }
        do {
            let page = try await load(videos.count)
            videos += page.filter { !videos.contains($0) }
            done = page.count < API.pageSize
            failed = false
        } catch {
            failed = true
        }
    }
}
