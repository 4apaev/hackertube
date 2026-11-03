import Foundation
import Observation

/// Liked, Watch later and History lists. They stay on this Apple TV, like the website keeps them in the browser.
@Observable
final class Library {
    private(set) var liked: [Video] = []
    private(set) var later: [Video] = []
    private(set) var history: [Video] = []

    @ObservationIgnored private let defaults: UserDefaults
    private static let historyLimit = 100

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        liked = load("liked")
        later = load("later")
        history = load("history")
    }

    func isLiked(_ video: Video) -> Bool { liked.contains(video) }
    func isLater(_ video: Video) -> Bool { later.contains(video) }

    func toggleLike(_ video: Video) {
        liked = toggled(liked, video)
        save(liked, "liked")
    }

    func toggleLater(_ video: Video) {
        later = toggled(later, video)
        save(later, "later")
    }

    func watched(_ video: Video) {
        history = Array(([video] + history.filter { $0 != video }).prefix(Self.historyLimit))
        save(history, "history")
    }

    func clearHistory() {
        history = []
        save(history, "history")
    }

    private func toggled(_ list: [Video], _ video: Video) -> [Video] {
        list.contains(video) ? list.filter { $0 != video } : [video] + list
    }

    private func load(_ key: String) -> [Video] {
        guard let data = defaults.data(forKey: key) else { return [] }
        return (try? JSONDecoder().decode([Video].self, from: data)) ?? []
    }

    private func save(_ list: [Video], _ key: String) {
        defaults.set(try? JSONEncoder().encode(list), forKey: key)
    }
}
