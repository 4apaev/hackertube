import SwiftUI

struct PlaylistsView: View {
    @State private var playlists: [PlaylistSummary]?
    @State private var failed = false

    private let tiers = [("start", "Start here"), ("deep", "Deep dives")]
    private let columns = Array(repeating: GridItem(.fixed(540), spacing: 40, alignment: .top), count: 3)

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 40) {
                ForEach(tiers, id: \.0) { tier, heading in
                    let items = (playlists ?? []).filter { $0.tier == tier }
                    if !items.isEmpty {
                        Text(heading).font(.title3).fontWeight(.semibold)
                        LazyVGrid(columns: columns, alignment: .leading, spacing: 50) {
                            ForEach(items) { playlist in
                                NavigationLink(value: Route.playlist(slug: playlist.slug, title: playlist.title)) {
                                    PlaylistCard(playlist: playlist)
                                }
                            }
                        }
                        .buttonStyle(.card)
                    }
                }
            }
            if playlists == nil {
                if failed { Text("Could not load playlists.").foregroundStyle(.secondary) } else { ProgressView() }
            }
        }
        .task {
            guard playlists == nil else { return }
            do { playlists = try await API.playlists() } catch { failed = true }
        }
    }
}

struct PlaylistCard: View {
    let playlist: PlaylistSummary

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Grid(horizontalSpacing: 2, verticalSpacing: 2) {
                ForEach(0..<2) { row in
                    GridRow {
                        ForEach(0..<2) { col in
                            let index = row * 2 + col
                            if index < playlist.cover.count {
                                Thumbnail(vid: playlist.cover[index])
                            } else {
                                Rectangle().fill(.quaternary).aspectRatio(16 / 9, contentMode: .fit)
                            }
                        }
                    }
                }
            }
            VStack(alignment: .leading, spacing: 6) {
                Text(playlist.title)
                    .font(.headline)
                    .lineLimit(1)
                Text(playlist.pitch ?? "")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2, reservesSpace: true)
                Text([playlist.count.map { "\($0) videos" }, Format.minutes(playlist.minutes)]
                    .compactMap { $0 }.joined(separator: " · "))
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
            .padding(16)
        }
        .frame(width: 540)
    }
}

struct PlaylistView: View {
    let slug: String
    let title: String

    @State private var playlist: Playlist?
    @State private var failed = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 40) {
                if let playlist {
                    VStack(alignment: .leading, spacing: 12) {
                        if let pitch = playlist.pitch { Text(pitch).font(.title3) }
                        if let intro = playlist.intro { Text(intro).foregroundStyle(.secondary) }
                        Text([("\(playlist.videos.count) videos"), Format.minutes(playlist.minutes)]
                            .compactMap { $0 }.joined(separator: " · "))
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                    .frame(maxWidth: 1400, alignment: .leading)
                    VideoCardGrid(videos: playlist.videos)
                } else if failed {
                    Text("Could not load this playlist.").foregroundStyle(.secondary)
                } else {
                    ProgressView()
                }
            }
        }
        .navigationTitle(playlist?.title ?? title)
        .task {
            guard playlist == nil else { return }
            do { playlist = try await API.playlist(slug) } catch { failed = true }
        }
    }
}
