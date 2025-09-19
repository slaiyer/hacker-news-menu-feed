import Foundation
import SwiftUI

@available(macOS 26.0, *)
struct AppMenu: View {
  @Binding var posts: [StoryFetchResponse]
  @Binding var isFetching: Bool

  var onReloadTapped: () -> Void

  var body: some View {
    if isFetching {
      Text("…")
        .frame(maxWidth: .infinity, alignment: .center)
        .padding()
        .foregroundStyle(.tertiary)
    } else {
      VStack(alignment: .leading) {
        PostsListing(posts: posts)
      }
    }
  }
}
