import SwiftUI

@available(macOS 26.0, *)
struct AppMenu: View {
    @Binding var posts: [StoryFetchResponse]
    
    var body: some View {
        if !posts.isEmpty {
            LazyVStack {
                PostsListing(posts: posts)
            }
            .animation(.default, value: posts)
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
