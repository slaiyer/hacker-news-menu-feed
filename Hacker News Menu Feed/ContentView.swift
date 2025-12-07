import SwiftUI

@available(macOS 26.0, *)
@main
struct ContentView: App {
    private static let numPosts = 500
    private let maxMenuBarWidth: CGFloat = 250
    
    @State private var isFetching = false
    @State private var posts: [StoryFetchResponse] = LocalDataSource.getPosts()
    @State private var showHeadline = LocalDataSource.getShowHeadline()
    @State private var sortKey = LocalDataSource.getSortKey()
    @State private var truncatedTitle: String? = LocalDataSource.getTitle()
    @State private var originalPostIDs: [Int] = LocalDataSource.getOriginalPostIDs()
    @State private var reloadRate = 3600.0
    
    private var timer = Timer()
    
    var body: some Scene {
        MenuBarExtra {
            VStack(alignment: .center) {
                Actions(
                    onReload: reloadData,
                    showHeadline: $showHeadline,
                    sortKey: $sortKey,
                    isFetching: $isFetching,
                )
                
                // TODO: vim-like j/k navigation
                ScrollView {
                    AppMenu(
                        posts: $posts,
                        onReloadTapped: reloadData,
                    )
                }
            }
            .padding()
            .frame(minWidth: 500, minHeight: 500)
        } label: {
            Text(showHeadline ? truncatedTitle ?? "Reading HN…" : "ℏ")
                .onAppear {
                    startApp()
                }
        }
        .menuBarExtraStyle(.window)
        .onChange(of: posts) {
            adjustTitleForMenuBar()
            LocalDataSource.savePosts(value: posts)
            LocalDataSource.saveOriginalPostIDs(value: originalPostIDs)
            LocalDataSource.saveTitle(value: truncatedTitle)
        }
        .onChange(of: showHeadline) {
            adjustTitleForMenuBar()
            LocalDataSource.saveShowHeadline(value: showHeadline)
        }
        .onChange(of: sortKey) { _, newKey in
            applySort()
            LocalDataSource.saveSortKey(value: newKey)
        }
        .commands {
            CommandMenu("Sort by…") {
                ForEach(SortKey.allCases) { key in
                    Button(key.label) {
                        if key == sortKey {
                            posts = sortPosts(posts, by: sortKey, reverse: true)
                        } else {
                            sortKey = key
                        }
                    }
                    .keyboardShortcut(KeyEquivalent(key.cut), modifiers: [])
                }
            }
        }
        .windowLevel(.floating)
    }
    
    func startApp() {
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
    
    func adjustTitleForMenuBar() {
        guard let firstPost = posts.first, let title = firstPost.title else {
            return
        }
        
        Task { @MainActor in
            truncatedTitle = truncateStringToFit(
                title,
                maxWidth: maxMenuBarWidth,
            )
        }
    }
    
    func truncateStringToFit(_ string: String, maxWidth: CGFloat) -> String {
        let tempLabel = NSTextField(labelWithString: string)
        tempLabel.sizeToFit()
        
        if tempLabel.frame.width <= maxWidth {
            return string
        }
        
        var truncatedString = string
        while tempLabel.frame.width > maxWidth && truncatedString.count > 0 {
            truncatedString.removeLast()
            tempLabel.stringValue = truncatedString + "…"
            tempLabel.sizeToFit()
        }
        
        return truncatedString + "…"
    }
    
    func reloadData() {
        isFetching = true
        
        Task {
            await Task.withTimeout(.seconds(60.0)) {
                await fetchFeed()
            }
            
            isFetching = false
        }
    }
    
    func fetchFeed() async {
        let postIds: [Int]
        do {
            postIds = try await fetchTopPostsIDs()
        } catch {
            return
        }
        
        await MainActor.run {
            originalPostIDs = postIds
        }
        
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
            
            return sortPosts(
                orderedPosts.compactMap { $0 },
                by: sortKey,
            )
        }
        
        guard !newPosts.isEmpty else {
            return
        }
        
        await MainActor.run {
            withAnimation {
                posts = newPosts
            }
        }
    }
    
    func fetchTopPostsIDs() async throws -> [Int] {
        let url = URL(
            string: "https://hacker-news.firebaseio.com/v0/topstories.json"
        )!
        let (data, _) = try await URLSession.shared.data(from: url)
        let response = try JSONDecoder().decode([Int].self, from: data)
        
        return Array(response.prefix(ContentView.numPosts))
    }
    
    func fetchPostById(postId: Int) async throws -> StoryFetchResponse {
        let url = URL(
            string: "https://hacker-news.firebaseio.com/v0/item/\(postId).json"
        )!
        let (data, _) = try await URLSession.shared.data(from: url)
        
        return try JSONDecoder().decode(StoryFetchResponse.self, from: data)
    }
    
    func applySort() {
        Task { @MainActor in
            withAnimation {
                posts = sortPosts(
                    posts,
                    by: sortKey,
                )
            }
        }
    }
    
    func sortPosts(
        _ posts: [StoryFetchResponse],
        by key: SortKey,
        reverse: Bool = false,
    ) -> [StoryFetchResponse] {
        if reverse {
            return posts.reversed()
        }

        switch key {
            case .original:
                let order = Dictionary(
                    uniqueKeysWithValues: originalPostIDs.enumerated().map { ($1, $0) }
                )
                return posts.sorted {
                    (order[$0.id] ?? Int.max) < (order[$1.id] ?? Int.max)
                }
            case .time:
                return posts.sorted { $0.time > $1.time }
            case .score:
                return posts.sorted { $0.score > $1.score }
            case .comments:
                return posts.sorted { ($0.comments ?? 0) > ($1.comments ?? 0) }
            case .type:
                return posts.sorted { $0.type < $1.type }
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
