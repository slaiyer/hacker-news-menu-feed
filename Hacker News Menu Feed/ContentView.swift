import SwiftUI

@available(macOS 26.0, *)
@main
struct ContentView: App {
    private static let numPosts = 500
    private let maxMenuBarWidth: CGFloat = 250
    private let reloadRate = 3600.0
    private static let timer = Timer()

    @State private var isFetching = false
    @State private var posts: [StoryFetchResponse] = LocalDataSource.getPosts()
    @State private var showHeadline = LocalDataSource.getShowHeadline()
    @State private var sortKey = LocalDataSource.getSortKey()
    @State private var truncatedTitle: String? = LocalDataSource.getTitle()
    @State private var originalPostIDs: [Int] = LocalDataSource.getOriginalPostIDs()
    @State private var searchText: String = ""
    @State private var filteredPosts: [StoryFetchResponse] = []
    @State private var searchTask: Task<Void, Never>? = nil
    @State private var isSearchMode: Bool = false

    @FocusState private var isSearchFocused: Bool

    var body: some Scene {
        MenuBarExtra {
            VStack(alignment: .center) {
                if isSearchMode {
                    ZStack(alignment: .center) {
                        Button(action: hideSearch) {
                            Text("􀆙")
                        }
                        .hidden()
                        .keyboardShortcut(.escape, modifiers: [])

                        TextField("􀊫 Search", text: $searchText)
                            .autocorrectionDisabled()
                            .padding(.horizontal, 45)
                            .focused($isSearchFocused)
                    }
                    .padding(.vertical, 1)
                } else {
                    ZStack(alignment: .center) {
                        Button(action: showSearch) {
                            Text("􀊫")
                        }
                        .hidden()
                        .keyboardShortcut("/", modifiers: [])

                        Actions(
                            onReload: reloadData,
                            showHeadline: $showHeadline,
                            sortKey: $sortKey,
                            isFetching: $isFetching
                        )
                    }
                }

                // TODO: vim-like j/k navigation
                ScrollView {
                    AppMenu(
                        posts: $filteredPosts,
                    )
                }
            }
            .padding()
            .frame(minWidth: 500, minHeight: 400)
        } label: {
            Text(showHeadline ? truncatedTitle ?? "Reading HN…" : "ℏ")
                .onAppear {
                    startApp()
                }
        }
        .menuBarExtraStyle(.window)
        .windowLevel(.floating)
        .onChange(of: posts) {
            adjustTitleForMenuBar()
            LocalDataSource.savePosts(value: posts)
            LocalDataSource.saveOriginalPostIDs(value: originalPostIDs)
            LocalDataSource.saveTitle(value: truncatedTitle)
            runSearch()
        }
        .onChange(of: searchText) {
            runSearch()
        }
        .onChange(of: showHeadline) {
            adjustTitleForMenuBar()
            LocalDataSource.saveShowHeadline(value: showHeadline)
        }
        .onChange(of: sortKey) { _, newKey in
            LocalDataSource.saveSortKey(value: newKey)
            applySort()
        }
        .commands {
            CommandMenu("Sort by…") {
                ForEach(SortKey.allCases) { key in
                    Button(key.label) {
                        if key == sortKey {
                            applySort(reverse: true)
                        } else {
                            sortKey = key
                        }
                    }
                    .keyboardShortcut(KeyEquivalent(key.cut), modifiers: [])
                }
            }
        }
    }

    private func startApp() {
        runSearch()
        reloadData()

        Timer.scheduledTimer(
            withTimeInterval: reloadRate, repeats: true,
            block: { _ in
                Task { @MainActor in
                    reloadData()
                }
            }
        )
    }

    private func adjustTitleForMenuBar() {
        guard let firstPost = posts.first, let title = firstPost.title else {
            return
        }

        truncatedTitle = truncateStringToFit(title)
    }

    private func truncateStringToFit(_ string: String) -> String {
        let tempLabel = NSTextField(labelWithString: string)
        tempLabel.sizeToFit()

        if tempLabel.frame.width <= maxMenuBarWidth {
            return string
        }

        var truncatedString = string
        while tempLabel.frame.width > maxMenuBarWidth && truncatedString.count > 0 {
            truncatedString.removeLast()
            tempLabel.stringValue = truncatedString + "…"
            tempLabel.sizeToFit()
        }

        return truncatedString + "…"
    }

    private func reloadData() {
        if isFetching {
            return
        }

        isFetching = true

        Task {
            await Task.withTimeout(.seconds(60.0)) {
                await fetchFeed()
            }

            applySort()

            isFetching = false
        }
    }

    private func fetchFeed() async {
        let postIds: [Int]
        do {
            postIds = try await fetchTopPostsIDs()
        } catch {
            return
        }

        originalPostIDs = postIds

        guard !postIds.isEmpty else {
            return
        }

        let newPosts = await withTaskGroup(of: (Int, StoryFetchResponse)?.self) { group in
            for (index, postId) in postIds.enumerated() {
                group.addTask {
                    do {
                        let post = try await self.fetchPostById(postId: postId)
                        return (index, post)
                    } catch {
                        return nil
                    }
                }
            }

            var orderedPosts = [StoryFetchResponse?](repeating: nil, count: postIds.count)

            for await result in group {
                if let (index, post) = result {
                    orderedPosts[index] = post
                }
            }

            return orderedPosts.compactMap { $0 }
        }

        guard !newPosts.isEmpty else {
            return
        }

        posts = newPosts
    }

    private func fetchTopPostsIDs() async throws -> [Int] {
        let url = URL(
            string: "https://hacker-news.firebaseio.com/v0/topstories.json"
        )!
        let (data, _) = try await URLSession.shared.data(from: url)
        let response = try JSONDecoder().decode([Int].self, from: data)

        return Array(response.prefix(ContentView.numPosts))
    }

    private func fetchPostById(postId: Int) async throws -> StoryFetchResponse {
        let url = URL(
            string: "https://hacker-news.firebaseio.com/v0/item/\(postId).json"
        )!
        let (data, _) = try await URLSession.shared.data(from: url)

        return try JSONDecoder().decode(StoryFetchResponse.self, from: data)
    }

    private func applySort(reverse: Bool = false) {
        Task {
            withAnimation {
                if reverse {
                    if sortKey == .original {
                        return
                    }

                    posts.reverse()
                    return
                }

                switch sortKey {
                    case .original:
                        let order = Dictionary(
                            uniqueKeysWithValues: originalPostIDs.enumerated().map { ($1, $0) }
                        )
                        posts.sort {
                            (order[$0.id] ?? Int.max) < (order[$1.id] ?? Int.max)
                        }
                    case .time:
                        posts.sort { $0.time > $1.time }
                    case .score:
                        posts.sort { $0.score > $1.score }
                    case .comments:
                        posts.sort { ($0.comments ?? 0) > ($1.comments ?? 0) }
                    case .type:
                        posts.sort { $0.type < $1.type }
                }
            }
        }
    }

    private func showSearch() {
        isSearchMode = true
        isSearchFocused = true
    }

    private func hideSearch() {
        searchText.removeAll(keepingCapacity: true)
        isSearchFocused = false
        isSearchMode = false
    }

    private func runSearch() {
        searchTask?.cancel()

        searchTask = Task.detached(priority: .background) { [posts, searchText] in
            try? await Task.sleep(for: .milliseconds(150))
            try? Task.checkCancellation()

            let results: [StoryFetchResponse]
            if searchText.isEmpty {
                results = posts
            } else {
                results = posts.filter { post in
                    post.type.localizedCaseInsensitiveContains(searchText) ||
                    post.author.localizedCaseInsensitiveContains(searchText) ||
                    (post.title?.localizedCaseInsensitiveContains(searchText) ?? false) ||
                    (post.url?.localizedCaseInsensitiveContains(searchText) ?? false) ||
                    (post.text?.localizedCaseInsensitiveContains(searchText) ?? false)
                }
            }

            try? Task.checkCancellation()

            await MainActor.run {
                withAnimation {
                    self.filteredPosts = results
                }
            }
        }
    }
}

enum SortKey: Int, Codable, CaseIterable, Identifiable {
    case original = 1
    case time
    case score
    case comments
    case type

    var id: Int { rawValue }

    var label: String {
        switch self {
            case .original: return "Original"
            case .time: return "Time"
            case .score: return "Score"
            case .comments: return "Comments"
            case .type: return "Type"
        }
    }

    var cut: Character { String(id).first! }
}

extension Task where Failure == any Error {
    static func withTimeout(_ duration: Duration, operation: @Sendable @escaping () async throws -> Success) async rethrows -> Success {
        let operationTask = Task.detached {
            try await operation()
        }

        let cancelationTask = Task<Void, any Error>.detached {
            try await Task<Never, Never>.sleep(for: duration)
            operationTask.cancel()
        }

        return try await withTaskCancellationHandler {
            defer { cancelationTask.cancel() }
            return try await operationTask.value
        } onCancel: {
            operationTask.cancel()
        }
    }
}
