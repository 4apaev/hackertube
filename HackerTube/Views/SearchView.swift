import SwiftUI

struct SearchView: View {
    @State private var query = ""
    @State private var results: SearchResults?
    @State private var failed = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 30) {
                if failed {
                    Text("Search failed. Check the network and try again.").foregroundStyle(.secondary)
                } else if let results {
                    if results.results.isEmpty {
                        Text("No videos found.").foregroundStyle(.secondary)
                    } else {
                        if results.weak == true {
                            Text("No close matches. These are the nearest.").foregroundStyle(.secondary)
                        }
                        VideoCardGrid(videos: results.results)
                    }
                }
            }
        }
        .searchable(text: $query, prompt: "Talks, topics, channels")
        .task(id: query) {
            let q = query.trimmingCharacters(in: .whitespaces)
            guard q.count >= 2 else {
                results = nil
                return
            }
            try? await Task.sleep(for: .milliseconds(400))
            guard !Task.isCancelled else { return }
            do {
                let found = try await API.search(q)
                guard !Task.isCancelled else { return }
                results = found
                failed = false
            } catch {
                if !Task.isCancelled { failed = true }
            }
        }
    }
}
