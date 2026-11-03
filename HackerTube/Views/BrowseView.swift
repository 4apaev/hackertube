import SwiftUI

/// The 16 topic areas, each with a row of its categories.
struct BrowseView: View {
    @State private var areas: [Area]?
    @State private var failed = false

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 30) {
                ForEach(areas ?? []) { area in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(area.name)
                            .font(.title3)
                            .fontWeight(.semibold)
                        ScrollView(.horizontal) {
                            LazyHStack(spacing: 24) {
                                topicLink("All", count: area.count, filters: ["area": area.id], title: area.name)
                                ForEach(area.categories) { category in
                                    topicLink(category.name, count: category.count, filters: ["cat": category.id], title: category.name)
                                }
                            }
                            .padding(.vertical, 20)
                        }
                        .scrollClipDisabled()
                    }
                }
            }
            if areas == nil {
                if failed { Text("Could not load topics.").foregroundStyle(.secondary) } else { ProgressView() }
            }
        }
        .task {
            guard areas == nil else { return }
            do { areas = try await API.areas() } catch { failed = true }
        }
    }

    private func topicLink(_ name: String, count: Int, filters: [String: String], title: String) -> some View {
        NavigationLink(value: Route.list(title: title, filters: filters)) {
            VStack(alignment: .leading, spacing: 4) {
                Text(name).font(.callout).lineLimit(1)
                Text("\(count) videos").font(.caption2).foregroundStyle(.secondary)
            }
        }
    }
}
