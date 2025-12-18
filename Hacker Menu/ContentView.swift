import Combine
import SwiftUI

@main
struct HackerMenu: App {
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
    @StateObject var textObserver = TextFieldObserver()
    @State private var filteredPosts: [StoryFetchResponse] = []
    @State private var filterTask: Task<Void, Never>? = nil
    @State private var isFilterMode: Bool = false
    @FocusState private var isFilterFocused: Bool

    var body: some Scene {
        MenuBarExtra {
            ContentView()
        } label: {
            Text(showHeadline ? truncatedTitle ?? "Reading HN…" : "ℏ")
                .onAppear { startApp() }
        }
        .menuBarExtraStyle(.window)
        .windowLevel(.floating)
        .onChange(of: posts) {
            runFilter(textObserver.debouncedText)
            adjustTitleForMenuBar()
            LocalDataSource.savePosts(value: posts)
            LocalDataSource.saveOriginalPostIDs(value: originalPostIDs)
            LocalDataSource.saveTitle(value: truncatedTitle)
        }
        .onChange(of: textObserver.debouncedText) {
            runFilter(textObserver.debouncedText)
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

    fileprivate func ContentView() -> some View {
        return VStack {
            ZStack {
                HStack {
                    Button(action: startFilterMode) {
                        Text("􀜓")
                    }
                    .keyboardShortcut("/", modifiers: [])

                    Button(action: endFilterMode) {
                        Text("􀆙")
                    }
                    .keyboardShortcut(.escape, modifiers: [])
                }
                .hidden()

                if isFilterMode {
                    TextField("􀜓 Filter", text: $textObserver.searchText)
                        .focused($isFilterFocused)
                        .onSubmit {
                            isFilterFocused = false
                        }
                        .autocorrectionDisabled()
                        .padding(.horizontal, 45)
                } else {
                    Actions(
                        reload: reload,
                        isFetching: $isFetching,
                        showHeadline: $showHeadline,
                        sortKey: $sortKey,
                    )
                }
            }

            // TODO: vim-like j/k navigation
            ScrollView {
                AppMenu(
                    posts: $filteredPosts,
                    isFetching: $isFetching,
                )
            }
        }
        .padding()
        .frame(minWidth: 500, minHeight: 400)
        .allowsTightening(true)
    }

    private func startApp() {
        runFilter(textObserver.searchText)
        reload()

        Timer.scheduledTimer(
            withTimeInterval: reloadRate,
            repeats: true,
            block: { _ in
                Task { @MainActor in
                    reload()
                }
            }
        )
    }

    private func adjustTitleForMenuBar() {
        guard let firstPost = posts.first, let title = firstPost.title else {
            return
        }

        if title.isEmpty {
            truncatedTitle = "ℏ"
        } else {
            truncatedTitle = truncateStringToFit(title)
        }
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

    private func reload() {
        if isFetching {
            return
        }

        isFetching = true

        Task {
            await Task.withTimeout(.seconds(60.0)) {
                await fetch()
            }

            applySort()

            isFetching = false
        }
    }

    private func fetch() async {
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

        return Array(response.prefix(HackerMenu.numPosts))
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

    private func startFilterMode() {
        isFilterMode = true
        isFilterFocused = true
    }

    private func endFilterMode() {
        textObserver.searchText.removeAll(keepingCapacity: true)
        textObserver.debouncedText.removeAll(keepingCapacity: true)
        isFilterFocused = false
        isFilterMode = false
        filterTask?.cancel()
    }

    private func runFilter(_ filterText: String) {
        filterTask?.cancel()

        filterTask = Task.detached(priority: .background) { [posts, filterText] in
            try? Task.checkCancellation()

            let results: [StoryFetchResponse]
            if filterText.isEmpty {
                results = posts
            } else {
                results = posts.filter { post in
                    post.type.localizedCaseInsensitiveContains(filterText) ||
                    (post.title?.localizedCaseInsensitiveContains(filterText) ?? false) ||
                    (post.url?.localizedCaseInsensitiveContains(filterText) ?? false) ||
                    (post.text?.localizedCaseInsensitiveContains(filterText) ?? false)
                }
            }

            try? Task.checkCancellation()

            await MainActor.run {
                self.filteredPosts = results
            }
        }
    }
}

#Preview {
    HackerMenu().ContentView()
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
    static func withTimeout(
        _ duration: Duration,
        operation: @Sendable @escaping () async throws -> Success,
    ) async rethrows -> Success {
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

class TextFieldObserver : ObservableObject {
    @Published var debouncedText = ""
    @Published var searchText = ""

    private var subscriptions = Set<AnyCancellable>()

    init() {
        $searchText
            .debounce(for: .milliseconds(500), scheduler: DispatchQueue.main)
            .sink(receiveValue: { [weak self] t in
                self?.debouncedText = t
            } )
            .store(in: &subscriptions)
    }
}
