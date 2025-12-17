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
            .padding(.top, 1)
            .padding(.leading, 1)
            .padding(.trailing, 14)
        } else {
            ZStack {
                Spacer().containerRelativeFrame([.horizontal, .vertical])

                Image(systemName: "ellipsis")
                    .symbolEffect(
                        .variableColor.iterative.dimInactiveLayers.reversing,
                        options: .repeat(.continuous),
                        isActive: posts.isEmpty
                    )
                    .foregroundStyle(.tertiary)
            }
        }
    }
}
