import SwiftUI

@available(macOS 26.0, *)
struct AppMenu: View {
    @Binding var posts: [StoryFetchResponse]
    
    var body: some View {
        if posts.count > 0 {
            LazyVStack {
                PostsListing(posts: posts)
            }
            .padding(.leading, 1)
            .padding(.trailing, 14)
        } else {
            Text("…")
                .frame(maxWidth: .infinity, alignment: .center)
                .padding()
                .foregroundStyle(.tertiary)
        }
    }
}
