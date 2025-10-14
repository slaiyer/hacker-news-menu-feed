import SwiftUI

@available(macOS 26.0, *)
@main
struct ContentView: App {
  private static let numPosts = 100

  @State private var isFetching = false
  @State private var showHeadline = LocalDataSource.getShowHeadline()
  @State private var sortKey = LocalDataSource.getSortKey()
  @State private var truncatedTitle: String = "Reading HN…"
  @State private var originalPostIDs: [Int] = []
  @State private var posts: [StoryFetchResponse] = []
  @State private var reloadRate = 3600.0

  var timer = Timer()

  var body: some Scene {
    MenuBarExtra {
      VStack(alignment: .center) {
        Actions(
          onReload: reloadData,
          onSort: applySort,
          showHeadline: $showHeadline,
          sortKey: $sortKey,
          isFetching: $isFetching,
        )

        ScrollView {
          AppMenu(
            posts: $posts,
            onReloadTapped: reloadData,
          )
        }
      }
      .padding()
      .frame(width: 500)
    } label: {
      if showHeadline {
        Text(truncatedTitle)
          .onAppear {
            startApp()
          }
      } else {
        Image(.icon)
          .onAppear {
            startApp()
          }
      }
    }
    .menuBarExtraStyle(.window)
    .onChange(of: isFetching) {
      if !isFetching && posts.count > 0 {
        adjustTitleForMenuBar()
      }
    }
    .onChange(of: showHeadline) {
      LocalDataSource.saveShowHeadline(value: showHeadline)
      adjustTitleForMenuBar()
    }
    .onChange(of: sortKey) { _, newKey in
      LocalDataSource.saveSortKey(value: newKey)
      applySort()
      adjustTitleForMenuBar()
    }
  }

  func startApp() {
    if posts.count == 0 {
      reloadData()
      Timer
        .scheduledTimer(
          withTimeInterval: reloadRate, repeats: true,
          block: { _ in
            reloadData()
          })
    }
  }

  func adjustTitleForMenuBar() {
    guard !posts.isEmpty else {
      return
    }

    Task { @MainActor in
      truncatedTitle = posts[0].title!
      let maxMenuBarWidth: CGFloat = 250
      truncatedTitle = truncateStringToFit(
        truncatedTitle,
        maxWidth: maxMenuBarWidth
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
      await Task.withTimeout(.seconds(10.0)) {
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
        originalPostIDs: originalPostIDs,
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
          originalPostIDs: originalPostIDs,
        )
      }
    }
  }

  func sortPosts(
    _ posts: [StoryFetchResponse],
    by key: SortKey,
    originalPostIDs: [Int],
  ) -> [StoryFetchResponse] {
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
    }
  }
}

enum SortKey: String, Codable, CaseIterable, Identifiable {
  case original
  case time
  case score
  case comments

  var id: String { rawValue }

  var label: String {
    switch self {
      case .original: return "Original"
      case .time: return "Time"
      case .score: return "Score"
      case .comments: return "Comments"
    }
  }
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
