import SwiftUI

struct VideoDetailView: View {
    let video: Video

    @Environment(Library.self) private var library
    @Environment(\.openURL) private var openURL
    @State private var detail: VideoDetail?
    @State private var related: [Video]?
    @State private var showPhoneLink = false

    /// The full record when it has loaded; the card's record until then.
    private var current: Video { detail?.video ?? video }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 50) {
                header
                if let why = current.whyHn {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Why Hacker News likes it").font(.title3).fontWeight(.semibold)
                        Text(why)
                        if let stats = hnLine { Text(stats).font(.caption).foregroundStyle(.secondary) }
                    }
                    .frame(maxWidth: 1400, alignment: .leading)
                }
                if let comments = detail?.comments, !comments.isEmpty {
                    commentsShelf(comments)
                }
                if let related, !related.isEmpty {
                    VideoShelf(title: "Related", videos: related)
                }
            }
        }
        .task {
            if detail == nil { detail = try? await API.video(video.vid) }
        }
        .task {
            if related == nil { related = try? await API.related(video.vid) }
        }
        .sheet(isPresented: $showPhoneLink) {
            OpenOnPhoneView(video: current)
        }
    }

    private var header: some View {
        HStack(alignment: .top, spacing: 60) {
            Thumbnail(vid: current.vid, quality: "maxresdefault")
                .frame(width: 760)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            VStack(alignment: .leading, spacing: 20) {
                Text(current.title)
                    .font(.title2)
                    .fontWeight(.bold)
                    .lineLimit(3)
                    .fixedSize(horizontal: false, vertical: true)
                Text(Format.meta(current))
                    .foregroundStyle(.secondary)
                if let summary = current.summary {
                    Text(summary).lineLimit(5)
                }
                HStack(spacing: 30) {
                    Button(action: play) {
                        Label("Play on YouTube", systemImage: "play.fill")
                    }
                    Button { library.toggleLike(current) } label: {
                        Label(library.isLiked(current) ? "Liked" : "Like",
                              systemImage: library.isLiked(current) ? "heart.fill" : "heart")
                    }
                    Button { library.toggleLater(current) } label: {
                        Label(library.isLater(current) ? "Saved" : "Watch later",
                              systemImage: library.isLater(current) ? "clock.fill" : "clock")
                    }
                }
            }
        }
    }

    /// "Recommended by 17 HN commenters, 2018–2026"
    private var hnLine: String? {
        guard let hn = current.hn, let people = hn.recommenders else { return nil }
        var line = "Recommended by \(people) HN commenter\(people == 1 ? "" : "s")"
        if let first = hn.first, let last = hn.last {
            line += first == last ? ", \(first)" : ", \(first)–\(last)"
        }
        return line
    }

    private func commentsShelf(_ comments: [Comment]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("What HN said").font(.title3).fontWeight(.semibold)
            ScrollView(.horizontal) {
                LazyHStack(alignment: .top, spacing: 40) {
                    ForEach(comments.prefix(20)) { comment in
                        // A card only so the remote can focus it and scroll the row.
                        Button {} label: {
                            VStack(alignment: .leading, spacing: 10) {
                                if let why = comment.why {
                                    Text(why).font(.callout).fontWeight(.semibold).lineLimit(2)
                                }
                                if let quote = comment.quote {
                                    Text("“\(quote)”").font(.caption).lineLimit(6)
                                }
                                Spacer(minLength: 0)
                                Text([comment.author, comment.ym].compactMap { $0 }.joined(separator: " · "))
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                            .padding(24)
                            .frame(width: 560, height: 320, alignment: .topLeading)
                        }
                    }
                }
                .padding(.vertical, 30)
            }
            .scrollClipDisabled()
            .buttonStyle(.card)
        }
    }

    private func play() {
        openURL(YouTube.appURL(current.vid)) { accepted in
            if accepted {
                library.watched(current)
            } else {
                showPhoneLink = true
            }
        }
    }
}

/// Shown when the YouTube app does not open the link, for example when it is not installed.
struct OpenOnPhoneView: View {
    let video: Video

    var body: some View {
        VStack(spacing: 40) {
            Text("Could not open the YouTube app")
                .font(.title2)
                .fontWeight(.bold)
            Text("Install YouTube from the App Store on this Apple TV, or scan the code to watch on your phone.")
                .multilineTextAlignment(.center)
                .frame(maxWidth: 1000)
            QRCode(url: YouTube.webURL(video.vid))
                .frame(width: 360, height: 360)
            Text(video.title).font(.caption).foregroundStyle(.secondary)
        }
        .padding(60)
    }
}
