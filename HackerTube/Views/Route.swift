import SwiftUI

/// Every screen a NavigationLink can push.
enum Route: Hashable {
    case video(Video)
    case list(title: String, filters: [String: String])
    case playlist(slug: String, title: String)
    case about
}

extension View {
    func withRoutes() -> some View {
        navigationDestination(for: Route.self) { route in
            switch route {
            case .video(let video):
                VideoDetailView(video: video)
            case .list(let title, let filters):
                PagedVideoGrid(title: title) { try await API.list(filters, offset: $0) }
            case .playlist(let slug, let title):
                PlaylistView(slug: slug, title: title)
            case .about:
                AboutView()
            }
        }
    }
}
