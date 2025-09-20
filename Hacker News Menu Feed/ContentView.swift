import SwiftUI

@available(macOS 26.0, *)
@main
struct ContentView: App {
  private static let numPosts = 100

  @State private var isFetching = false
  @State private var showHeadline = LocalDataSource.getShowHeadline()
  @State private var truncatedTitle: String = "Reading HN…"
  @State private var posts: [StoryFetchResponse] = []
  @State private var reloadRate = 3600.0

  var timer = Timer()

  var body: some Scene {
    MenuBarExtra {
      VStack(alignment: .leading) {
        Actions(
          onReload: reloadData,
          onQuit: { NSApplication.shared.terminate(nil) },
          showHeadline: $showHeadline
        )

        ScrollView {
          AppMenu(
            posts: $posts,
            isFetching: $isFetching,
            onReloadTapped: reloadData
          )
        }
      }
      .padding()
      .frame(width: 500.0)
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
        truncatedTitle = posts[0].title!.trimmingCharacters(in: .whitespacesAndNewlines).filter{!$0.isNewline}
        adjustTitleForMenuBar()
      } else {
        truncatedTitle = "Reading HN…"
      }
    }
    .onChange(of: showHeadline) {
      LocalDataSource.saveShowHeadline(value: showHeadline)
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
    let maxMenuBarWidth: CGFloat = 250
    truncatedTitle = truncateStringToFit(
      truncatedTitle,
      maxWidth: maxMenuBarWidth
    )
  }

  func truncateStringToFit(_ string: String, maxWidth: CGFloat) -> String {
    // Create a temporary label to measure the string width
    let label = NSTextField(labelWithString: string)
    label.sizeToFit()

    if label.frame.width <= maxWidth {
      return string
    }

    var truncatedString = string
    while label.frame.width > maxWidth && truncatedString.count > 0 {
      truncatedString.removeLast()
      label.stringValue = truncatedString + "…"
      label.sizeToFit()
    }

    return truncatedString + "…"
  }

  func reloadData() {
    isFetching = true

    Task {
      await fetchFeed()

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

    guard postIds.count > 0 else {
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

    guard newPosts.count > 0 else {
      return
    }

    posts = newPosts
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
}
