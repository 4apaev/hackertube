import SwiftUI

struct VideoCard: View {
    let video: Video

    static let width: CGFloat = 400
    static let spacing: CGFloat = 40
    static let columns = Array(repeating: GridItem(.fixed(width), spacing: spacing, alignment: .top), count: 4)

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Thumbnail(vid: video.vid)
                .overlay(alignment: .bottomTrailing) {
                    let duration = Format.duration(video.durationS)
                    if !duration.isEmpty {
                        Text(duration)
                            .font(.caption2.monospacedDigit())
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(.black.opacity(0.8), in: RoundedRectangle(cornerRadius: 6))
                            .foregroundStyle(.white)
                            .padding(10)
                    }
                }
            VStack(alignment: .leading, spacing: 4) {
                Text(video.title)
                    .font(.callout)
                    .fontWeight(.medium)
                    .lineLimit(2, reservesSpace: true)
                Text(video.channel ?? " ")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            .padding(16)
        }
        .frame(width: Self.width)
    }
}

/// A YouTube thumbnail cropped to 16:9. Falls back to hqdefault when the asked quality is missing.
struct Thumbnail: View {
    let vid: String
    var quality = "hqdefault"

    var body: some View {
        Color.clear
            .aspectRatio(16 / 9, contentMode: .fit)
            .overlay {
                AsyncImage(url: YouTube.thumbnailURL(vid, quality: quality)) { phase in
                    if let image = phase.image {
                        image.resizable().scaledToFill()
                    } else if phase.error != nil, quality != "hqdefault" {
                        AnyView(Thumbnail(vid: vid))
                    } else {
                        Rectangle().fill(.quaternary)
                    }
                }
            }
            .clipped()
    }
}

/// A fixed grid of video cards.
struct VideoCardGrid: View {
    let videos: [Video]

    var body: some View {
        LazyVGrid(columns: VideoCard.columns, alignment: .leading, spacing: 50) {
            ForEach(videos) { video in
                NavigationLink(value: Route.video(video)) { VideoCard(video: video) }
            }
        }
        .buttonStyle(.card)
    }
}
