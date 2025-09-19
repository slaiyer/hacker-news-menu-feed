import Foundation
import SwiftUI

@available(macOS 26.0, *)
struct AppMenu: View {
  @Binding var posts: [StoryFetchResponse]
  @Binding var isFetching: Bool

  var onReloadTapped: () -> Void

  var body: some View {
    VStack(alignment: .leading) {
      if isFetching {
        Text("Loading feed…")
          .foregroundStyle(.tertiary)
          .padding()
      } else {
        PostsListing(posts: posts)
      }
    }
  }
}
