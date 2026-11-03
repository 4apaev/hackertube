import Foundation

enum Format {
    static func duration(_ seconds: Int?) -> String {
        guard let seconds, seconds > 0 else { return "" }
        let h = seconds / 3600, m = seconds % 3600 / 60, s = seconds % 60
        return h > 0 ? String(format: "%d:%02d:%02d", h, m, s) : String(format: "%d:%02d", m, s)
    }

    static func views(_ count: Int?) -> String? {
        count.map { $0.formatted(.number.notation(.compactName)) + " views" }
    }

    static func year(_ iso: String?) -> String? {
        iso.map { String($0.prefix(4)) }
    }

    static func minutes(_ minutes: Int?) -> String? {
        minutes.map { Duration.seconds($0 * 60).formatted(.units(allowed: [.hours, .minutes], width: .abbreviated)) }
    }

    /// "3Blue1Brown · 9:52 · 13M views · 2016"
    static func meta(_ video: Video) -> String {
        [video.channel, duration(video.durationS), views(video.views), year(video.published)]
            .compactMap { $0 }.filter { !$0.isEmpty }.joined(separator: " · ")
    }
}
