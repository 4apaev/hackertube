import SwiftUI

@main
struct HackerTubeApp: App {
    @State private var library = Library()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(library)
        }
    }
}

struct RootView: View {
    @State private var tab = "home"
    @State private var homePath: [Route] = []

    var body: some View {
        TabView(selection: $tab) {
            Tab("Home", systemImage: "house", value: "home") {
                NavigationStack(path: $homePath) { HomeView().withRoutes() }
            }
            Tab("Playlists", systemImage: "list.bullet.rectangle", value: "playlists") {
                NavigationStack { PlaylistsView().withRoutes() }
            }
            Tab("Browse", systemImage: "square.grid.2x2", value: "browse") {
                NavigationStack { BrowseView().withRoutes() }
            }
            Tab("Library", systemImage: "heart", value: "library") {
                NavigationStack { LibraryView().withRoutes() }
            }
            Tab(value: "search", role: .search) {
                NavigationStack { SearchView().withRoutes() }
            }
        }
        #if DEBUG
        .task { await openDebugScreen() }
        #endif
    }

    #if DEBUG
    /// Opens a screen from a launch argument, for screenshots in the simulator:
    /// `-screen playlists`, `-screen video:<id>`, `-screen playlist:<slug>`, `-screen list:sort=recent`.
    private func openDebugScreen() async {
        guard let screen = UserDefaults.standard.string(forKey: "screen") else { return }
        let parts = screen.split(separator: ":", maxSplits: 1).map(String.init)
        switch (parts.first, parts.count > 1 ? parts[1] : nil) {
        case ("video", let vid?):
            if let detail = try? await API.video(vid) { homePath = [.video(detail.video)] }
        case ("playlist", let slug?):
            homePath = [.playlist(slug: slug, title: slug)]
        case ("list", let filter?):
            let pair = filter.split(separator: "=").map(String.init)
            if pair.count == 2 { homePath = [.list(title: filter, filters: [pair[0]: pair[1]])] }
        case (let name?, nil):
            tab = name
        default:
            break
        }
    }
    #endif
}
